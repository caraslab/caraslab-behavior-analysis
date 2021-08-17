function folders = caraslab_lsdir(dirname)
%folders = caraslab_lsdir(dirname)
%
%Lists directories and attributes in the given directory (dirname).
%Returned list omits hidden directories.
%
%Written by ML Caras Mar 22 2019


folderIndex = [];

folders = dir(fullfile(dirname));

%For each folder in the starting directory
for i = 1:length(folders)
    
    %Include folder if it's not a hidden folder
    if folders(i).name(1) ~= '.' && folders(i).isdir == 1
        [folderIndex] = [folderIndex;i];
    end
    
end

folders = folders(folderIndex);

end