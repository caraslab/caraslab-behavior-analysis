function preprocess_optoActiveData(directoryname, assert_five_amdepths, max_trial)
%preprocess(directoryname)
%
%This function goes through each datafile in a directory, and calculates
%hits, misses and dprime values for each behavioral session. Aggregate data
%are compiled into an [1 x M] 'output' structure, where M is equal to the 
%number of behavioral sessions. 'output' has two fields:
%   'trialmat': [N x 3] matrix arranged as follows- 
%       [stimulus value, n_yes_responses, n_trials_delivered]
%
%   'dprimemat': [N x 2] matrix arranged as follows-
%       [stimulus value, dprime]
%
%Within each matrix, stimulus values are dB re:100% depth
%
%Written by ML Caras Jan 29, 2018

if nargin < 2
    assert_five_amdepths = 0;
end

if nargin < 3
    max_trial = 0;
end


%List the files in the folder (each file = animal)
[files,fileIndex] = listFiles(directoryname,'*.mat');
files = files(fileIndex);

%For each file...
for i = 1:numel(files)
    
    %Start fresh
    clear Session
    output = [];
    
    %Load data
    filename=files(i).name;
    data_file=[directoryname,'/',filename];
    load(data_file);
    
    %For each session...
    for j = 1:numel(Session)
        % Skip empty training sessions
       if ~(length(Session(j).Data) > 1)
           continue
       end
       
       % Split session into opto-on and opto-off before processing
       
      %Create trialmat and dprimemat in preparation for psychometric fits  
      output = create_mats(Session, output, j, files.folder, max_trial, assert_five_amdepths);

    end
    
    %Save the file
    save(data_file,'output','-append')
    
end


%Create trialmat and dprimemat in preparation for psychometric fitting
function output = create_mats(Session, output, j, output_dir, max_trial, assert_five_amdepths)

    %-------------------------------
    %Prepare data
    %-------------------------------
    %Initialize trial matrix
    trialmat = [];

    %Stimuli (AM depth in proportion)
    stim = [Session(j).Data.AMdepth]';

    %Responses (coded via bitmask in Info.Bits)
    resp = [Session(j).Data.ResponseCode]';

    %Trial type (0 = GO; 1 = NOGO)
    ttype = [Session(j).Data.TrialType]';

    %Remove reminder trials
    rmind = ~logical([Session(j).Data.Reminder]');
    
    stim = stim(rmind);
    resp = resp(rmind);
    ttype = ttype(rmind);

    if assert_five_amdepths
        am_stim = stim(stim > 0);
        if length(unique(am_stim)) > 5
            last_five_amdepth = [];
            % Loop inversely through stim presentations and break loop once
            % 5 different am depths appear
            for dummy_idx=length(am_stim):-1:1
                if ~ismember(am_stim(dummy_idx), last_five_amdepth)
                    last_five_amdepth(end+1) = am_stim(dummy_idx);
                end
                
                if length(last_five_amdepth) == 5
                    break
                end
            end
        
            % Append 0 dB
            last_five_amdepth = [last_five_amdepth 0];

            % only include stim in last_five_amdepths
            [good_stim, ~] = ismember(stim, last_five_amdepth);
            stim = stim(good_stim);
            resp = resp(good_stim);
            ttype = ttype(good_stim);
        end
    end
    
    % Count number of trials _ orig
    [n_trials, unique_stim] = hist(stim,unique(stim));
    n_trials = [n_trials' unique_stim]; 
    good_stim = n_trials(n_trials(:,1) >= 5, 2);
    if length(good_stim) < 2
        output(j).trialmat = [];
        output(j).dprimemat = [];
        return
    end
    
    % Remove stimuli that have less than 5 trials
    rtrial = find(~ismember(stim,good_stim,'rows'));
    stim(rtrial, :) = [];
    resp(rtrial, :) = [];
    ttype(rtrial, :) = [];
    
    %Pull out bits for decoding responses
    fabit = Session(j).Info.Bits.fa;
    hitbit = Session(j).Info.Bits.hit;




    %-------------------------------------
    %Calculate hit rates
    %-------------------------------------
    go_ind = find(ttype == 0);
    go_stim = stim(go_ind);
    go_resp = resp(go_ind);
    
    max_go_trial = 0;
    
    u_go_stim =unique(go_stim);

    %For each go stimulus...
    for m = 1:numel(u_go_stim)

        %Pull out data for just that stimulus
        m_ind = find(go_stim == u_go_stim(m));
        cur_go_ind = go_ind(m_ind);
        
        % Remove trials past a specific trial
        if max_trial > 0
            m_ind = m_ind(1:max_trial);
            cur_go_ind = cur_go_ind(1:max_trial);
            
            if max(cur_go_ind) > max_go_trial
                max_go_trial = max(cur_go_ind);
            end
        end
        
        go_resp_m = go_resp(m_ind); %#ok<*FNDSB>

        %Calculate the hit rate
        n_hit = sum(bitget(go_resp_m,hitbit));

        n_go = numel(go_resp_m);
        
        hit_rate = n_hit/n_go;
        
        %Adjust floor and ceiling
        if hit_rate <0.05
            adjusted_hit_rate = 0.05;
        elseif hit_rate >0.95
            adjusted_hit_rate = 0.95;
        else
            adjusted_hit_rate = hit_rate;
        end
        
        % MML edit: log-linear correction for fa_rate (Hautus 1995) in case of extreme values
%         hit_rate = (n_hit +0.5)/(n_go + 1);

        %Adjust number of hits to match adjusted hit rate (so we can fit
        %data with psignifit later)
        adjusted_n_hit = adjusted_hit_rate*n_go;

        %Append to trial mat
        trialmat = [trialmat; u_go_stim(m), adjusted_n_hit, n_go, n_hit]; %#ok<AGROW>

    end


    %-------------------------------------
    %Calculate fa rate
    %-------------------------------------
    nogo_ind = find(ttype == 1);
    
    if max_go_trial > 0
        nogo_ind = nogo_ind(nogo_ind < max_go_trial);
    end
    
    stim_val = stim(nogo_ind(1));
    nogo_resp = resp(nogo_ind);
    n_fa = sum(bitget(nogo_resp,fabit));
    n_nogo = numel(nogo_resp);

    fa_rate = n_fa/n_nogo;
    
            
    %Adjust floor and ceiling
    if fa_rate <0.05
        adjusted_fa_rate = 0.05;
    elseif fa_rate >0.95
        adjusted_fa_rate = 0.95;
    else
        adjusted_fa_rate = fa_rate;
    end
    
    % MML edit: log-linear correction for fa_rate (Hautus 1995) in case of extreme values
%     fa_rate = (n_fa + 0.5)/(n_nogo + 1);

    %Adjust number of false alarms to match adjusted fa rate (so we can
    %fit data with psignifit later)
    adjusted_n_fa = adjusted_fa_rate*n_nogo;

    %Convert to z score
    % z_fa = sqrt(2)*erfinv(2*fa_rate-1);

    % MML edit:  Is this the same as norminv?
    z_fa = norminv(adjusted_fa_rate);

    %Append to trialmat
    trialmat = [trialmat; stim_val, adjusted_n_fa, n_nogo, n_fa];


    %Convert stimulus values to log and sort data so safe stimulus is on top
    trialmat(:,1) = make_stim_log(trialmat);
    trialmat = sortrows(trialmat,1);

    %Calculate dprime
    hitrates = trialmat(2:end,2)./trialmat(2:end,3);

    % z_hit = sqrt(2)*erfinv(2*(hitrates)-1);
    % MML edit: Is this the same as norminv?
    z_hit = norminv(hitrates);

    dprime = z_hit - z_fa;
    dprimemat = [trialmat(2:end,1),dprime];

    output(j).trialmat = trialmat;
    output(j).dprimemat = dprimemat;
    
    %% Output trialmat and dprimemat into a CSV
    if j == 1
        write_or_append = 'overwrite';
    else
        write_or_append = 'append';
    end
    
    subj_id = Session(j).Info.Name;
    try
        session_id = datestr(datetime(Session(j).Info.StartTime), 'yymmdd-HHMMSS');
    catch ME
        if strcmp(ME.identifier, 'MATLAB:datetime:UnrecognizedDateStringSuggestLocale')
            % Some sessions have weird format because they didn't save properly
            session_id = [datestr(datenum(Session(j).Info.StartDate), 'yymmdd') '-' Session(j).Info.StartTime];

        else
            throw(ME)
        end
    end
    
    %trialmat first
    output_table = array2table(trialmat);
    output_table.Properties.VariableNames = {'Stimulus', 'Adjusted_N_FA_or_Hit', 'N_trials', 'N_FA_or_Hit'};
    output_table.Block_id = repmat(session_id, size(trialmat, 1), 1);
    
    writetable(output_table, fullfile(output_dir, [subj_id '_allSessions_trialMat.csv']), 'WriteMode',write_or_append);
    
    %Now dprimemat
    output_table = array2table(dprimemat);
    output_table.Properties.VariableNames = {'Stimulus', 'd_prime'};
    output_table.Block_id = repmat(session_id, size(dprimemat, 1), 1);
    
    writetable(output_table, fullfile(output_dir, [subj_id '_allSessions_dprimeMat.csv']), 'WriteMode',write_or_append);
    
       