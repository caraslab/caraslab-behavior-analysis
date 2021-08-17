function ind = find_index(foldername,str)
%ind = find_index(foldername,str)
%
%Returns the index of the folder that matches str
%
%Written by ML Caras 2014

ind = arrayfun(@(x)(strfind(x.name,str)),foldername,'UniformOutput',false);
ind = cellfun(@(x)(~isempty(x)),ind,'UniformOutput',false);
ind = cell2mat(ind);
ind = find(ind == 1);

end