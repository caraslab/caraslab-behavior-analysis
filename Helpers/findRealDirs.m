function [folders,folderIndex]= findRealDirs(directoryname)
%[folders,folderIndex]= findRealDirs(directoryname)
%
%Creates a list of directories containing real files
%
%Written by ML Caras 7.22.10


folderIndex = [];

folders = dir(fullfile(directoryname));

%For each folder in the starting directory
for i = 1:length(folders)
    
    %Include folder if it's not a hidden folder
    if folders(i).name(1) ~= '.' && folders(i).isdir == 1;
        [folderIndex] = [folderIndex;i];
    end
    
end

end