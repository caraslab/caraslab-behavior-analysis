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

% experiment_type: optional: 'none', 'synapse', 'intan', 'optoBehavior', '1IFC', 'synapse_1IFC'

% Defaults
split_by_optostim = 0;
universal_nogo = 1;
experiment_type = 'none';
assert_five_amdepths = 0;
trial_subset = NaN;
n_trial_blocks = 0;

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
if nargin ==0
    % default_dir = '/mnt/CL_4TB_2/Matt/OFC_PL_recording/matlab_data_files';
    default_dir = '/mnt/CL_4TB_2/Matt/Fiber photometry/ACx-AAVrg-GCaMP8s_OFC-VO-fiber/matlab_data_files';

    Savedir = uigetdir(default_dir, 'Select save directory');
    if Savedir == 0
        warning('Save folder was not selected. Aborting...')
        return
    end
    Behaviordir = default_dir;

    experiment_type = 'none';  % none or optoBehavior

    % Tweak these
    n_trial_blocks = 0;  % no splitting: 0
    split_by_optostim = 0;  % no splitting: 0
    universal_nogo = 1;  % Only relevant if splitting by optostim
end
%%
%Prompt user to select folders
% uigetfile_n_dir copied from here:
% https://www.mathworks.com/matlabcentral/fileexchange/32555-uigetfile_n_dir-select-multiple-files-and-directories
datafolders_names = uigetfile_n_dir(Behaviordir,'Select data directory');  
if isempty(datafolders_names)
    warning('Data folders not selected. Aborting...')
    return
end
datafolders = {};
for i=1:length(datafolders_names)
    [~, datafolders{end+1}, ~] = fileparts(datafolders_names{i});
end
% Update Behaviordir in case it changed
[Behaviordir, ~, ~] = fileparts(datafolders_names{1});


%For each data folder...
for i = 1:numel(datafolders)
    cur_savedir = fullfile(Savedir, 'Behavior', datafolders{i});
    cur_sourcedir = fullfile(Behaviordir, datafolders{i});
    mkdir(cur_savedir);

    %% 1. MERGE STRUCTURES (OPTIONAL)
    %Use this script to merge the data and info structures from two different
    %data files. Necessary when program crashes in the middle of testing, and a
    %second session is run immediately after crash.

    % Not implemented for current patch

    % mergestruct

    %% 2. COMBINE INDIVIDUAL MAT FILES INTO SINGLE FILE
    %This function takes mat files collected with the epsych program and
    %combines them into a single file. Use this file to combine data from
    %multiple sessions for a single animal into one mat file for easier
    %storage, manipulation and analysis.
    %
    %Note: Combine all the shock training data files into one "training" file,
    %and all the psychometric testing data into a separate "testing" file for
    %each animal. Thus, in the end, each animal will have two behavioral files
    %associated with it. This approach makes it easier to analyze different
    %stages of learning separately.
    caraslab_combinefiles(cur_sourcedir,cur_savedir)

    %% 2.1 Split blocks of n AM trials into separate Session entries
    if n_trial_blocks > 0
        caraslab_split_trial_blocks(cur_savedir, n_trial_blocks)
    end
    
    %% 2.2 Split opto trials into separate Session entries
    if split_by_optostim
        caraslab_split_opto_trials(cur_savedir, universal_nogo)
    end
    
    %% 3. CREATE TRIALMAT AND DPRIMEMAT IN PREPARATION FOR PSYCHOMETRIC FITTING
    %This function goes through each datafile in a directory, and calculates
    %hits, misses and dprime values for each behavioral session. Aggregate data
    %are compiled into an [1 x M] 'output' structure, where M is equal to the 
    %number of behavioral sessions. 'output' has two fields:
    %   'trialmat': [N x 3] matrix arranged as follows- 
    %       [stimulus value, n_yes_responses, n_trials_delivered]
    %
    %   'dprimemat': [N x 2] matrix arranged as follows-
    %       [stimulus value, dprime]
    %
    %Within each matrix, stimulus values are dB re:100% depth.

    % This function also outputs two csv files with trial performance
    % _allSessions_trialMat.csv: number of stimulus presentations and hits/FAs 
    % _allSessions_dprimeMat.csv: d' by stimulus
    preprocess(cur_savedir, assert_five_amdepths, trial_subset, experiment_type)

    %% 4. FIT PSYCHOMETRIC FUNCTIONS 
    %Fits behavioral data with psychometric functions using psignifit v4. Fit
    %info is saved to a data structure within the file. Fits are created both
    %in percent correct space, and in dprime space. 
    % In addition to plots, output a csv file with the thresholds by day
    plot_pfs_behav(cur_savedir,cur_savedir)


    %% 5. Output timestamps info for ephys
    % This function extracts behavioral timestamps of relevance for ephys
    % analyses. It searches within the processed ephys folder (Ephysdir) for information
    % about the behavioral session contained in the .info file generated by the
    % TDT system.
    % Outputs:
    %   *_spoutTimestamps.csv: All spout events containing onset and onset
    %       times
    %   *_trialInfo.csv: All trial events generated by the TDT system but with
    %       a bit more processing to bit-unmask the response variables.
    if ~strcmp(experiment_type, 'none')
        caraslab_outputBehaviorTimestamps(cur_savedir, Savedir, experiment_type)
    end
end