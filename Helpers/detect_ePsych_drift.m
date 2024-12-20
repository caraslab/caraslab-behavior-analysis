function [session_data] = detect_ePsych_drift(session_data, epData, session_name, recording_format, iterations)
    % VERY SPECIAL CASE HANDLING
    % It has happened only twice in my 4 years as a postdoc
    % I noticed that the timestamps of those two recordings became
    % desynchronized between ePsych and the recording platform
    % (once with Synapse, another with Intan)
    % RPvds apparently sent a single phantom non-AM trial TTL causing a
    % drift of about 1 second, I think it coincides with the
    % moment that the AM depths are adjusted in the middle of a
    % trial. 
    % The code below detects this issue, issues a warning and 
    % corrects it by removing the phantom non-AM trial and
    % rechecking for drift

    % Detect the issue using the computer timestamps
    % They are not reliable but large discrepancies indicate an issue
    
    % Author: M Macedo-Lima, Dec 2024
    if nargin < 5
        iterations = 0;
    end
    all_computer_timestamps = datetime(session_data.ComputerTimestamp(:,:));
    recording_timestamps = seconds(session_data.Trial_onset);

    diff_computer = seconds(diff(all_computer_timestamps));
    diff_recording = seconds(diff(recording_timestamps));
    delta_onsets = diff_computer - diff_recording;
    

    % If any of the discrepancies is larger than a single trial duration threshold, issue a
    % warning and change the way onsets are computed
    violation_threshold = 1;  % seconds
    if any(delta_onsets > violation_threshold)
        drift_trials = find(delta_onsets > violation_threshold);

        phantom_trial = drift_trials(1) + 1;
        
        warndlg(sprintf('\nAttention!!\nThere are timestamp discrepancies between ePsych and your recording device.\nThe problematic recording is: %s\nDrift started on trial ID: %d', session_name, phantom_trial))

        if strcmp(recording_format, 'synapse')
            temp_offset = epData.epocs.TTyp.offset;
            offset_inf = isinf(temp_offset);
            epData_onsets = epData.epocs.TTyp.onset(~offset_inf);
            epData_offsets = epData.epocs.TTyp.offset(~offset_inf);
        elseif strcmp(recording_format, 'intan')
            trial_events = epData.event_ids == 3;
            all_trial_events_timestamps = epData.timestamps(trial_events);
            trial_event_states = epData.event_states(trial_events);
            trial_onset_events = trial_event_states == 1;
            trial_offset_events = trial_event_states == 0;
            
            epData_onsets = all_trial_events_timestamps(trial_onset_events);
            epData_offsets = all_trial_events_timestamps(trial_offset_events);

        end
        
        epData_onsets(phantom_trial) = [];
        epData_offsets(phantom_trial) = [];
        
        % Change values in session_data
        try
            session_data.Trial_onset = epData_onsets;
            session_data.Trial_offset = epData_offsets;
        catch ME
            % Sometimes the above doesn't work. Not sure why but epData ends up
            % with 1 more element than cur_session. Let's cut the last one for
            % now
            if strcmp(ME.identifier, 'MATLAB:table:RowDimensionMismatch')
                session_data.Trial_onset = epData_onsets(1:size(session_data,1));
                session_data.Trial_offset = epData_offsets(1:size(session_data,1));
            end
        end

        % Recheck
        iterations = iterations + 1;
        session_data = detect_ePsych_drift(session_data, epData, session_name, recording_format, iterations);
        
        if iterations > 0
            warndlg(sprintf('\nIssue resolved with %d non-AM trial(s) removed\n', iterations));
        end
    end

end