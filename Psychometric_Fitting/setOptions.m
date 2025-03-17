function [options, plotOptions] = setOptions(options, plotOptions)
%[options, plotOptions] = setOptions(options, plotOptions)
%
% This function sets the options for fitting behavioral data with psignifit,
% and also sets options for the plotting features. These options are
% optimized for an aversive AM detection go/nogo paradigm.
%
% If `options` or `plotOptions` are provided, the function updates only
% the missing fields with default values.
%
% Written by ML Caras Dec 5 2016
% Modified by DJS 2/17/2025

% Check if options is provided, otherwise initialize
if nargin < 1 || isempty(options)
    options = struct();
end

% Set up fit options (only update missing fields)
defaults.dprimeThresh = 1;
defaults.sigmoidName = 'norm'; % Use cumulative Gaussian fit
defaults.expType = 'YesNo';     % For a go/nogo experiment
defaults.confP  = 0.95;         % Confidence level for confidence intervals
defaults.useGPU = 0;            % Disable GPU by default
defaults.plot = false;          % Indicates whether to produce plots

% Merge user-provided options with defaults
options = setDefaults(options, defaults);

% Check if plotOptions is provided, otherwise initialize
if nargin < 2 || isempty(plotOptions)
    plotOptions = struct();
end

% Set up default plot options
plotDefaults.dataColor      = [0 0 0];
plotDefaults.plotData       = 1;
plotDefaults.lineColor      = plotDefaults.dataColor;
plotDefaults.lineWidth      = 2;
plotDefaults.xLabel         = 'AM Depth (dB re: 100%)';
plotDefaults.yLabel         = 'Proportion Correct';
plotDefaults.labelSize      = 15;
plotDefaults.fontSize       = 10;
plotDefaults.fontName       = 'Arial';
plotDefaults.tufteAxis      = false;
plotDefaults.plotAsymptote  = false;
plotDefaults.plotThresh     = false;
plotDefaults.aspectRatio    = false;
plotDefaults.extrapolLength = 0.2;
plotDefaults.CIthresh       = false;
plotDefaults.dataSize       = 25;

% Merge user-provided plotOptions with defaults
plotOptions = setDefaults(plotOptions, plotDefaults);

end

function structOut = setDefaults(structIn, defaults)
% Helper function to set default values in a structure
    fields = fieldnames(defaults);
    for i = 1:numel(fields)
        if ~isfield(structIn, fields{i})
            structIn.(fields{i}) = defaults.(fields{i});
        end
    end
    structOut = structIn;
end
