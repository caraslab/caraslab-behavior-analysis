%Create trialmat and dprimemat in preparation for psychometric fitting
function output = Session2mat(Session, trial_subset, assert_five_amdepths)
% output = Session2mat(Session, trial_subset, assert_five_amdepths)
% 
% 
% Extracted from PREPROCESS. Where PREPROCESS works on multiple files
% within a specified directory, SESSION2MAT works on one session.
% 
% Calculates hits, misses and dprime values for each behavioral session.
% Aggregate data are compiled into an [1 x M] 'output' structure, where M 
% is equal to the number of behavioral sessions. 'output' has two fields:
%   'trialmat': [N x 3] matrix arranged as follows- 
%       [stimulus value, n_yes_responses, n_trials_delivered]
%
%   'dprimemat': [N x 2] matrix arranged as follows-
%       [stimulus value, dprime]
%
% Within each matrix, stimulus values are dB re:100% depth% 
% 
% See also, preprocess
% 
% DJS 2/2024



%-------------------------------
%Prepare data
%-------------------------------
%Initialize trial matrix
trialmat = [];

%Stimuli (AM depth in proportion)
stim = [Session.Data.AMdepth]';

%Responses (coded via bitmask in Info.Bits)
resp = [Session.Data.ResponseCode]';

%Trial type (0 = GO; 1 = NOGO)
ttype = [Session.Data.TrialType]';

%Remove reminder trials
rmind = ~logical([Session.Data.Reminder]');

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
    output.trialmat = [];
    output.dprimemat = [];
    return
end

% Remove stimuli that have less than 5 trials
rtrial = find(~ismember(stim,good_stim,'rows'));
stim(rtrial, :) = [];
resp(rtrial, :) = [];
ttype(rtrial, :) = [];

% Subset trials (optional)
if ~isnan(trial_subset)
    go_ind = find(ttype == 0);
    go_trialid = [Session.Data(go_ind).TrialID]';

    if trial_subset(2) == Inf
        last_go_trial = length(go_trialid);
    end

    good_go_trials = [go_trialid(trial_subset(1)), go_trialid(last_go_trial)];

    if trial_subset(1) == 1
        first_trial = 1;
    else
        first_trial = good_go_trials(1);
    end

    if trial_subset(2) == Inf
        last_trial = length(stim);
    else
        last_trial = good_go_trials(2);
    end

    good_trials = [Session.Data(first_trial:last_trial).TrialID]';

    stim = stim(good_trials);
    resp = resp(good_trials);
    ttype = ttype(good_trials);
end

%Pull out bits for decoding responses
fabit = Session.Info.Bits.fa;
hitbit = Session.Info.Bits.hit;

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

% MML edit:  Is this the same as norminv? Yes, it is.
z_fa = norminv(adjusted_fa_rate);

%Append to trialmat
trialmat = [trialmat; stim_val, adjusted_n_fa, n_nogo, n_fa];


%Convert stimulus values to log and sort data so safe stimulus is on top
trialmat(:,1) = make_stim_log(trialmat);
trialmat = sortrows(trialmat,1);

%Calculate dprime
hitrates = trialmat(2:end,2)./trialmat(2:end,3);

% z_hit = sqrt(2)*erfinv(2*(hitrates)-1);
% MML edit: Is this the same as norminv? Yes, it is.
z_hit = norminv(hitrates);

dprime = z_hit - z_fa;
dprimemat = [trialmat(2:end,1),dprime];

output.trialmat = trialmat;
output.dprimemat = dprimemat;
