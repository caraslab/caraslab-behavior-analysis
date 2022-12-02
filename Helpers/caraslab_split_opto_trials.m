function caraslab_split_opto_trials(directoryname)
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

    Session_outputCopy = struct();
    dummy_counter = 1;
    %For each session...
    for j = 1:numel(Session)
        % Skip empty training sessions
        if ~(length(Session(j).Data) > 1)
           continue
        end

        % For now, keep all NOGO trials with Optostim==0 in both sessions,
        % should we separate NOGO trials in time? Could cause "overfitting"
        % for more complicated opto stimulations that are not in blocks
        temp_tableSession = struct2table(Session(j).Data);
        opto_tags = temp_tableSession.Optostim;
        ttype_tags = temp_tableSession.TrialType;
        opto_Session = temp_tableSession(opto_tags == 1 | ttype_tags == 1, :);
        noOpto_Session = temp_tableSession(opto_tags == 0 | ttype_tags == 1, :);

        % Save as separate sessions but with same Info
        Session_outputCopy(dummy_counter).Data = table2struct(opto_Session);
        Session_outputCopy(dummy_counter).Info = Session(j).Info;
        Session_outputCopy(dummy_counter).Info.Optostim = 1; 
        dummy_counter = dummy_counter + 1;
        
        Session_outputCopy(dummy_counter).Data = table2struct(noOpto_Session);
        Session_outputCopy(dummy_counter).Info = Session(j).Info;
        Session_outputCopy(dummy_counter).Info.Optostim = 0;
        dummy_counter = dummy_counter + 1;
    end
    Session = Session_outputCopy;
    %Overwrite previous allSessions file
    save(data_file,'Session')
end
       