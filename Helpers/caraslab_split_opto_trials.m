function caraslab_split_opto_trials(files_path, universal_nogo)
% This file splits the ePsych behavioral .mat file into opto ON vs opto OFF
% blocks. Then, it saves a copy of behav_sessions, Info to the output .mat file
% containing a field within Info called Optostatus.
% universal_nogo (0 or 1): if 1, includes all no-go trials in both
% Optostatus blocks. If 0, splits no-go trials depending on opto status

%List the files in the folder (each file = animal)
[files,fileIndex] = listFiles(files_path,'*allSessions.mat');
files = files(fileIndex);

% Depending on the experiment, these might have different names. 
optoTagNames = 'JitOnset';

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

        temp_tablebehav_sessions = struct2table(behav_sessions(j).Data);

        % Find opto tag
        field_names = temp_tablebehav_sessions.Properties.VariableNames;
        opto_index = 0;
        for fn_index=1:length(field_names)
            if contains(optoTagNames, field_names{fn_index})
                opto_index = fn_index;
                break
            end
        end

        if opto_index > 0
            optoTag = field_names{opto_index};
        else
            fprintf('Opto tag name not found. Aborting...')
            continue
        end

        opto_status = temp_tablebehav_sessions.(optoTag);
        ttype_tags = temp_tablebehav_sessions.TrialType;
        if universal_nogo
            opto_behav_sessions = temp_tablebehav_sessions(opto_status == 1 | ttype_tags == 1, :);
            noOpto_behav_sessions = temp_tablebehav_sessions(opto_status == 0 | ttype_tags == 1, :);
        else
            opto_behav_sessions = temp_tablebehav_sessions(opto_status == 1, :);
            noOpto_behav_sessions = temp_tablebehav_sessions(opto_status == 0, :);
        end

        % Save as separate sessions but with same Info (if there are
        % trials in them)
        if height(opto_behav_sessions) > 1
            behav_sessions_outputCopy(dummy_counter).Data = table2struct(opto_behav_sessions);
            behav_sessions_outputCopy(dummy_counter).Info = behav_sessions(j).Info;
            behav_sessions_outputCopy(dummy_counter).Info.Optostim = 1; 
            dummy_counter = dummy_counter + 1;
        end

        if height(noOpto_behav_sessions) > 1
            behav_sessions_outputCopy(dummy_counter).Data = table2struct(noOpto_behav_sessions);
            behav_sessions_outputCopy(dummy_counter).Info = behav_sessions(j).Info;
            behav_sessions_outputCopy(dummy_counter).Info.Optostim = 0;
            dummy_counter = dummy_counter + 1;
        end
    end
    behav_sessions = behav_sessions_outputCopy;
    %Overwrite previous allbehav_sessionss file
    save(data_file,'behav_sessions')
end
       