function caraslab_combinefiles(directoryname,savepath)
%combinefiles(directoryname,savepath)
%
%This function takes mat files collected with the epsych program and
%combines them into a single file. Use this file to combine data from
%multiple sessions for a single animal into one mat file for easier
%storage, manipulation and analysis.
%
%Written by ML Caras Jan 29, 2018

%Start fresh
clear Session


%List the files in the folder (each file = one session)
[files,fileIndex] = listFiles(directoryname,'*.mat');
files = files(fileIndex);

% Empty folder. Not psychometric testing
if isempty(files)
    return
end

%Convert dates to datetime, then character array
%This is important because if you combined the files in the order
%they exist within the directory, you might erroneously combine them in
%the wrong order. The files are stored with abbreviations for the month
%(Oct, Dec, etc) and are ordered alphabetcially. Thus, if you don't
%convert the dates to standard datetime format, you might end up with a
%session collected in Dec listed before a session collected in Oct.
for j = 1:numel(files)
    files(j).date = char(datetime(files(j).date,'Format','yyyyMMdd'));
end

%Sort files by date 
[sortedfiles, ~] = sortStruct(files, 'date');

% Extract subject ID from first filename
subj_id = split(sortedfiles(1).name, "_");
subj_id = subj_id{1};

%For each file...
for k = 1:numel(sortedfiles)

    %Start fresh
    clear temp

    %Load data
    filename=sortedfiles(k).name;
    data_file=[directoryname,'/',filename];
    temp = load(data_file);

    %Save data to data structure
    try
        Session(k).Data = temp.Data;
        Session(k).Info = temp.Info;
    catch ME
        if strcmp(ME.identifier, 'MATLAB:nonExistentField')
            try
                % This might happen when ePsych crashes and we need to use the
                % recovered file, which is formatted differently and
                % incompletely. You need to manually search for this file in
                % the MatLab ePsych crash files and rename it appropriately.
                % This chunk should take care of the rest
                Session(k).Data = temp.data;
                Session(k).Info = temp.info;
                Session(k).Info.Name = temp.info.Subject.Name;
                Session(k).Info.Date = temp.info.StartDate;
                Session(k).Info.Bits = struct('hit',1, 'miss', 2, 'cr', 3, 'fa', 4);
            catch ME
                if strcmp(ME.identifier, 'MATLAB:nonExistentField')
                    % If this happens a second time, we might be dealing
                    % with a frequency tuning file, which for the moment is
                    % missing the Info field. Handle this here
                    Session(k).Data = temp.Data;
                    
                    % Exctract start date from first ComputerTimestamp
                    first_timestamp = datetime(struct2table(temp.Data).ComputerTimestamp(1,:));
                    Session(k).Info.Name = subj_id;
                    Session(k).Info.Date = [int2str(day(first_timestamp)) '-' ...
                                            cell2mat(month(first_timestamp, "shortname")) '-' ...
                                            int2str(year(first_timestamp))];
                    Session(k).Info.StartTime = struct2table(temp.Data).ComputerTimestamp(1,:);
                else
                    throw(ME)
                end        
            end
        else
            throw(ME)
        end
    end
end



%Save data structure to new file
%e = regexp(filename,'\d\d\d\d\d\d','end');


savename = fullfile(savepath,[subj_id '_allSessions.mat']);
save(savename,'Session')
