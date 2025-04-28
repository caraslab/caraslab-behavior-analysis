function caraslab_split_opto_trials(files_path, universal_nogo)
% This file splits the ePsych behavioral .mat file into opto ON vs opto OFF
% blocks. Then, it saves a copy of Session, Info to the output .mat file
% containing a field within Info called Optostatus.
% universal_nogo (0 or 1): if 1, includes all no-go trials in both
% Optostatus blocks. If 0, splits no-go trials depending on opto status

%List the files in the folder (each file = animal)
[files,fileIndex] = listFiles(files_path,'*allSessions.mat');
files = files(fileIndex);

% Depending on the experiment, these might have different names. Simply add
% to the end of this string if your experiment has something different.
optoTagNames = 'JitOnset';

%For each file...
for i = 1:numel(files)

    %Start fresh
    clear Session
    output = [];

    %Load data
    filename=files(i).name;
    data_file= fullfile(files_path, filename);
    load(data_file);

    Session_outputCopy = struct();
    dummy_counter = 1;
    %For each session...
    for j = 1:numel(Session)
        % Skip empty training sessions
        if ~(length(Session(j).Data) > 1)
           continue
        end

        temp_tableSession = struct2table(Session(j).Data);

        % Find opto tag
        field_names = temp_tableSession.Properties.VariableNames;
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

        opto_status = temp_tableSession.(optoTag);
        ttype_tags = temp_tableSession.TrialType;
        if universal_nogo
            opto_Session = temp_tableSession(opto_status == 1 | ttype_tags == 1, :);
            noOpto_Session = temp_tableSession(opto_status == 0 | ttype_tags == 1, :);
        else
            opto_Session = temp_tableSession(opto_status == 1, :);
            noOpto_Session = temp_tableSession(opto_status == 0, :);
        end

        % Save as separate sessions but with same Info (if there are
        % trials in them)
        if height(opto_Session) > 1
            Session_outputCopy(dummy_counter).Data = table2struct(opto_Session);
            Session_outputCopy(dummy_counter).Info = Session(j).Info;
            Session_outputCopy(dummy_counter).Info.Optostim = 1; 
            dummy_counter = dummy_counter + 1;
        end

        if height(noOpto_Session) > 1
            Session_outputCopy(dummy_counter).Data = table2struct(noOpto_Session);
            Session_outputCopy(dummy_counter).Info = Session(j).Info;
            Session_outputCopy(dummy_counter).Info.Optostim = 0;
            dummy_counter = dummy_counter + 1;
        end
    end
    Session = Session_outputCopy;
    %Overwrite previous allSessions file
    save(data_file,'Session')
end
       