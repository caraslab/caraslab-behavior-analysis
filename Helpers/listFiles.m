function [files,fileIndex] = listFiles(directoryname,filetype)
%[files,fileIndex] = listFiles(directoryname,filetype)
%
%Creates a list of files for a directory.  The file extension is indicated
%by filetype.
%
%%Written by Melissa Caras 7.22.10

%Obtain a list of files (not directories) in the directory
files = dir(fullfile(directoryname, filetype));
ind=find(~[files.isdir]); 

%Make sure they're real files
files = files(ind);
ind_real = cell2mat(arrayfun(@(x)(~strcmp(x.name(1),'.')),files,'UniformOutput',false));
fileIndex = find(ind_real == 1);

end