function caraslab_compile_behaviorData_for_analyses()
%
% This function loops through Subject folders and extracts all relevant
% files into a folder called Data inside the parent directory. The purpose
% is to centralize all subjects' data into common directories
%

%Prompt user to select folder
default_dir = '/mnt/CL_8TB_3/Matheus/1IFC pilot';
Savedir = uigetdir(default_dir, 'Select save directory');
datafolders_names = uigetfile_n_dir(default_dir,'Select data directories');
datafolders = {};
for i=1:length(datafolders_names)
    [~, datafolders{end+1}, ~] = fileparts(datafolders_names{i});
end

% Create data analysis folders in save directory
mkdir(fullfile(Savedir, 'Data'));

behavioralPerformance_path = fullfile(Savedir, 'Data', 'Behavioral performance');
mkdir(behavioralPerformance_path);

% Copy behavior files
for i = 1:numel(datafolders)
    cur_path.name = datafolders{i};
    cur_dir = fullfile(Savedir, cur_path.name);
        
    filedirs = caraslab_lsdir(fullfile(cur_dir, 'Behavior'));
    filedirs = {filedirs.name};
    for file_idx=1:length(filedirs)
        if ~isempty(filedirs)
            cur_filedir = fullfile(cur_dir, 'Behavior', filedirs{file_idx});
            copyfile(cur_filedir, fullfile(behavioralPerformance_path, filedirs{file_idx}));
        end
    end
end
