function caraslab_behav_pipeline(Savedir, Behaviordir, varargin)

% caraslab_behav_pipeline.m
% This pipeline takes ePsych .mat behavioral files, combines and analyzes them and
% outputs files ready for further behavioral analyses and for aligning
% timestamps with neural recordings
% Author ML Caras

% In this patched version, this pipeline also incorporates ephys recordings
% in the processing to extract timestamps related to spout and stimulus
% delivery
% Author: M Macedo-Lima
% November, 2020

%% Set your paths
% Ephysdir: Where your processed ephys recordings are. No need to declare this
%   variable if you are not interested in or don't have ephys

% Behaviordir: Where the ePsych behavior files are; -mat files will be
%   combined into a single file. Before running this, group similar sessions
%   into folders named:
%   shock_training, psych_testing, pre_passive, post_passive

% experiment_type: optional: 'behavior', 'synapse', 'intan', '1IFC', 'synapse_1IFC'

% Defaults
split_by_optostim    = 0;
universal_nogo       = 1;
experiment_type      = 'behavior';
assert_five_amdepths = 0;
trial_subset         = NaN;
n_trial_blocks       = 0;

% Loading optional arguments
while ~isempty(varargin)
    switch lower(varargin{1})
        case 'split_by_optostim'
            split_by_optostim = varargin{2};
        case 'universal_nogo'
            universal_nogo = varargin{2};
        case 'experiment_type'
            experiment_type = varargin{2};
        case 'assert_five_amdepths'
            assert_five_amdepths = varargin{2};
        case 'trial_subset'
            trial_subset = varargin{2};
        case 'n_trial_blocks'
            n_trial_blocks = varargin{2};
        otherwise
            error(['Unexpected parameter: ' varargin{1}])
    end
    varargin(1:2) = [];
end


%%  If this function is run directly (behavior only; no ephys data will be analyzed)
if nargin == 0
    default_dir = 'G:\My Drive\Documents\PycharmProjects\Photometry_processing\Data_OFC-axonGCaMP8s_V1-fiber\Behavioral performance\matlab_data_files';

    % Select MULTIPLE save directories (one per animal/subject)
    Savedirs_paths = uigetfile_n_dir(default_dir, 'Select one or more save directories');
    if isempty(Savedirs_paths)
        warning('No save folders selected. Aborting...')
        return
    end

    experiment_type   = 'behavior';
    n_trial_blocks    = 0;
    split_by_optostim = 0;
    universal_nogo    = 1;

    %% Loop over each selected save directory
    for s = 1:numel(Savedirs_paths)
        cur_top_savedir = Savedirs_paths{s};
        fprintf('\n=== Processing Savedir %d/%d: "%s" ===\n', s, numel(Savedirs_paths), cur_top_savedir);

        % Auto-discover Behaviordir
        Behaviordirs = find_mat_dirs(cur_top_savedir);

        if isempty(Behaviordirs)
            warning('No .mat files found in "%s" or its immediate subfolders. Skipping...', cur_top_savedir)
            continue
        end

        for b = 1:numel(Behaviordirs)
            fprintf('\n--- Behaviordir %d/%d: "%s" ---\n', b, numel(Behaviordirs), Behaviordirs{b});
            run_pipeline(Behaviordirs{b}, cur_top_savedir, ...
                experiment_type, assert_five_amdepths, trial_subset, ...
                n_trial_blocks, split_by_optostim, universal_nogo, false);
        end
    end

else
    % Called programmatically with explicit Savedir and Behaviordir:
    % original single-run behavior, unchanged.
    run_pipeline(Behaviordir, Savedir, ...
        experiment_type, assert_five_amdepths, trial_subset, ...
        n_trial_blocks, split_by_optostim, universal_nogo, true);
end


%% ------------------------------------------------------------------------
function run_pipeline(Behaviordir, Savedir, experiment_type, assert_five_amdepths, ...
                      trial_subset, n_trial_blocks, split_by_optostim, universal_nogo, ...
                      interactive)

if interactive
    datafolders_names = uigetfile_n_dir(Behaviordir, 'Select data directory');
    if isempty(datafolders_names)
        warning('Data folders not selected for "%s". Skipping...', Behaviordir)
        return
    end
    datafolders = {};
    for i = 1:length(datafolders_names)
        [~, datafolders{end+1}, ~] = fileparts(datafolders_names{i});
    end
    [Behaviordir, ~, ~] = fileparts(datafolders_names{1});

else
    fprintf('run_pipeline: auto-discovering sources in "%s"\n', Behaviordir);

    % Check if .mat files exist directly in Behaviordir
    mats = dir(fullfile(Behaviordir, '*.mat'));
    if ~isempty(mats)
        % .mat files are directly in Behaviordir — pass folder straight to combinefiles
        fprintf('  .mat files found directly in Behaviordir, passing folder to combinefiles\n');
        [parent, session_name, ~] = fileparts(Behaviordir);
        datafolders = {session_name};
        Behaviordir = parent;
    else
        contents   = dir(Behaviordir);
        mask       = [contents.isdir] & ...
                     ~strcmp({contents.name}, '.') & ...
                     ~strcmp({contents.name}, '..') & ...
                     ~strcmp({contents.name}, 'Behavior');
        datafolders = {contents(mask).name};
        fprintf('  Source subfolders found: %d\n', numel(datafolders));
        for k = 1:numel(datafolders)
            fprintf('    -> "%s"\n', datafolders{k});
        end

        if isempty(datafolders)
            [parent, session_name, ~] = fileparts(Behaviordir);
            fprintf('  No subfolders found, using Behaviordir itself as source: "%s"\n', session_name);
            datafolders = {session_name};
            Behaviordir = parent;
        end
    end
end

fprintf('  Running pipeline for %d source folder(s)\n', numel(datafolders));

for i = 1:numel(datafolders)
    cur_savedir   = fullfile(Savedir, 'Behavior', datafolders{i});
    cur_sourcedir = fullfile(Behaviordir, datafolders{i});
    fprintf('  Source %d/%d: "%s"\n', i, numel(datafolders), cur_sourcedir);
    mkdir(cur_savedir);

    %% 2. COMBINE INDIVIDUAL MAT FILES INTO SINGLE FILE
    caraslab_combinefiles(cur_sourcedir, cur_savedir)

    %% 2.1 Split blocks of n AM trials into separate Session entries
    if n_trial_blocks > 0
        caraslab_split_trial_blocks(cur_savedir, n_trial_blocks)
    end

    %% 2.2 Split opto trials into separate Session entries
    if split_by_optostim
        caraslab_split_opto_trials(cur_savedir, universal_nogo)
    end

    %% 3. CREATE TRIALMAT AND DPRIMEMAT
    preprocess(cur_savedir, assert_five_amdepths, trial_subset, experiment_type)

    %% 4. FIT PSYCHOMETRIC FUNCTIONS
    plot_pfs_behav(cur_savedir, cur_savedir)

    %% 5. OUTPUT TIMESTAMPS FOR EPHYS
    caraslab_outputBehaviorTimestamps(cur_savedir, Savedir, experiment_type)
end


%% ------------------------------------------------------------------------
function Behaviordirs = find_mat_dirs(top_dir)
% Search for directories containing .mat files:
%   1. One level deep (L1 subfolders of top_dir)
%   2. Fallback: top_dir itself

Behaviordirs = {};

fprintf('find_mat_dirs: searching in "%s"\n', top_dir);

contents = dir(top_dir);
subdirs  = contents([contents.isdir] & ...
                    ~strcmp({contents.name}, '.') & ...
                    ~strcmp({contents.name}, '..'));

fprintf('  Level 1 subfolders: %d\n', numel(subdirs));
for k = 1:numel(subdirs)
    fprintf('    [L1] %s\n', subdirs(k).name);
end

% First: L1 subfolders that directly contain .mat files
for k = 1:numel(subdirs)
    candidate = fullfile(top_dir, subdirs(k).name);
    mats = dir(fullfile(candidate, '*.mat'));
    fprintf('  [L1] "%s": %d .mat files\n', candidate, numel(mats));
    if ~isempty(mats)
        Behaviordirs{end+1} = candidate; %#ok<AGROW>
    end
end

% Fallback: check top_dir itself
if isempty(Behaviordirs)
    mats = dir(fullfile(top_dir, '*.mat'));
    fprintf('  Fallback - top_dir itself: %d .mat files\n', numel(mats));
    if ~isempty(mats)
        Behaviordirs{end+1} = top_dir;
    end
end

if isempty(Behaviordirs)
    fprintf('  No .mat files found anywhere\n');
else
    fprintf('  Behaviordirs found: %d\n', numel(Behaviordirs));
    for k = 1:numel(Behaviordirs)
        fprintf('    -> "%s"\n', Behaviordirs{k});
    end
end