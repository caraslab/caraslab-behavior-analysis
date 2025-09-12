function qualitycontrol(directoryname,n)
%qualitycontrol(directoryname,n)
%
%This function checks files to ensure that there are a sufficient number of
%sessions, that there is no data missing, that the animal ID in the
%file metadata matches the name of the file, and that session dates are in
%the correct order.
%
%Inputs:
%
%   n   The minimum number of sessions required
%
%
%Written by ML Caras July 2018.


%Get list of files in the directory
[files,fileIndex] = listFiles(directoryname,'*.mat');
files = files(fileIndex);

%For each file...
for which_file = 1:numel(files)
    
    %Start fresh
    clear animal_data behav_sessions output names dates
    status = 'good';
    
    %Load file
    filename = files(which_file).name;
    behav_files = load(fullfile(directoryname,filename));
    behav_sessions = behav_files.Session;
    
    check1 = numel(behav_sessions);
    
    %Are there the correct number of sessions?
    if check1 < n
        disp([filename,' does not have enough sessions']);
        status = 'bad';
    end
    
    %Are the dates in the correct order?
    for i = 1:numel(behav_sessions)
        dates{i} = behav_sessions(i).Info.Date;
    end
    
    orig = datetime(dates)';
    sorted = sortrows(orig);
    
    if ~isequal(orig,sorted)
        disp([filename, ' has session dates in the wrong order'])
        status = 'bad';
    end
    
    
    
    %Is the data from each session from the same animal? (That is-- did you
    %accidentally combine sessions from different animals into a single
    %file?)
    for i = 1:numel(behav_sessions)
        names{i} = behav_sessions(i).Info.Name;
    end
    
    for i = 2:numel(names)
        check2 = strcmp(names{1},names{i});
        
        if ~check2
            disp([filename, ' has data from different animals']);
            status = 'bad';
        end
        
    end
    
    %Does the ID in the file name match the ID in the data? (That is-- is
    %the data attributed to the correct animal?)
    name1 = char(regexp(behav_sessions(1).Info.Name,'\d\d\d\d\d\d','match'));
    name2 = char(regexp(filename,'\d\d\d\d\d\d','match'));
    
    check3 = strcmp(name1,name2);
    
    if ~check3
        disp([filename, ' has a discrepancy in the animal ID'])
        status = 'bad';
    end
    
    
    
    if strcmp(status,'good')
        disp([filename, ' is OK!']);
    end
end