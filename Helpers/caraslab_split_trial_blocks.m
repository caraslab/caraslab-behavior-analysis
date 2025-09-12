function caraslab_split_trial_blocks(files_path, n_trial_blocks)
% This file splits the ePsych behavioral .mat file into opto ON vs opto OFF
% blocks. Then, it saves a copy of behav_sessions, Info to the output .mat file
% containing a field within Info called Optostatus.
% universal_nogo (0 or 1): if 1, includes all no-go trials in both
% Optostatus blocks. If 0, splits no-go trials depending on opto status

%List the files in the folder (each file = animal)
[files,fileIndex] = listFiles(files_path,'*allSessions.mat');
files = files(fileIndex);


%For each file...
for i = 1:numel(files)
    %Start fresh and avoids conflict with OpenEphys pipeline
    clear behav_sessions
    output = [];

    %Load data
    filename=files(i).name;
    data_file= fullfile(files_path, filename);
    behav_files = load(data_file);
    behav_sessions = behav_files.behav_sessions;

    behav_sessions_outputCopy = struct();
    dummy_counter = 1;
    %For each session...
    for j = 1:numel(behav_sessions)
        % Skip empty training sessions
        if ~(length(behav_sessions(j).Data) > 1)
           continue
        end

        temp_table_behav_sessions = struct2table(behav_sessions(j).Data);
        ttype_tags = temp_table_behav_sessions.TrialType;
        reminder_tags = temp_table_behav_sessions.Reminder;
        trial_IDs = temp_table_behav_sessions.TrialID;
        % Grab am_trial IDs (ignoring Reminders)
        amtrial_ID = temp_table_behav_sessions.TrialID(ttype_tags == 0 & reminder_tags == 0);
        block_splits_idx = 1:n_trial_blocks:length(amtrial_ID);
        for block_idx=1:length(block_splits_idx)

            % For fairness, not not include reminders and first no-gos in first
            % block; all blocks start with an AM trial
            % if block_idx == 1
            %     block_start_trial = 0;
            %     start_trial_ID = 1;
            % else
            %     block_start_trial = block_splits_idx(block_idx);
            %     start_trial_ID = amtrial_ID(block_start_trial);
            % end

            block_start_trial = block_splits_idx(block_idx);
            start_trial_ID = amtrial_ID(block_start_trial);

            % Now grab end trial 
            if block_start_trial < max(block_splits_idx)
                block_end_trial = block_splits_idx(block_idx+1)-1;
            else
                block_end_trial = length(amtrial_ID);
            end
            end_trial_ID = amtrial_ID(block_end_trial);

            block_session = temp_table_behav_sessions((trial_IDs >= start_trial_ID) & ...
                (trial_IDs <= end_trial_ID),:);
            % Save as separate sessions but with same Info
            behav_sessions_outputCopy(dummy_counter).Data = table2struct(block_session);
            behav_sessions_outputCopy(dummy_counter).Info = behav_sessions(j).Info;
            behav_sessions_outputCopy(dummy_counter).Info.Trial_block = block_idx; 
            dummy_counter = dummy_counter + 1;
        end

    end
    behav_sessions = behav_sessions_outputCopy;
    
    %Overwrite previous allSessions file
    save(data_file, 'behav_sessions');
end
       