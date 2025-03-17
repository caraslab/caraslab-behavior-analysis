function fitdata = fit_trialmat(dprimemat, trialmat, options, plotOptions)

arguments
    dprimemat (:,2) double {mustBeMatrix,mustBeNonempty}
    trialmat (:,4) double {mustBeMatrix,mustBeNonempty}
    options = struct([])
    plotOptions = struct([])
end


[options, plotOptions] = setOptions(options,plotOptions);


%Fit the data
% Make sure threshold is not below lowest AM depth presented
low_range = trialmat(2, 1); % because trialmat(1,1) is catch trial
options.stimulusRange = [low_range, -0.01];
[options,results,zFA] = find_threshPC(trialmat,options);


% extracted from plotPsych_dprime
%Calculate threshold and slope
threshold = getThreshold(results,options.threshPC,false); %scaled threshold
slope = getSlopePC(results,options.threshPC,false); %scaled slope


% Establish x values
xlength = max(results.data(:,1))-min(results.data(:,1));
xLow = min(results.data(:,1))- plotOptions.extrapolLength*xlength;
xHigh = max(results.data(:,1))+ plotOptions.extrapolLength*xlength;
x  = linspace(xLow,xHigh,1000);

%Define percent "yes" responses (y values) for fit
fitted_yes = (1-results.Fit(3)-results.Fit(4))*arrayfun(@(x) results.options.sigmoidHandle(x,results.Fit(1),results.Fit(2)),x)+results.Fit(4);

%Define dprime (y values) for fit
fitted_dprime  = sqrt(2)*erfinv(2*fitted_yes-1)- zFA;



if options.plot
    f = findobj('type','figure','-and','name','psychplots');
    if isempty(f), f = figure('name','psychplots'); end
    figure(f);
    clf(f)

    %Plot the percent correct values and fit
    subplot(211)
    plotPsych(results,plotOptions);

    subplot(212)
    try
        plotPsych_dprime(results,dprimemat,options,plotOptions,zFA);
    catch ME
        if ~strcmp(ME.message, 'The threshold percent correct is not reached by the sigmoid!')
            rethrow(ME);
        end
    end
end


%Save everything to data structure
fitdata.results = results;
fitdata.fit_plot.x = x;
fitdata.fit_plot.pCorrect = fitted_yes;
fitdata.fit_plot.dprime = fitted_dprime;
fitdata.threshold = threshold; %scaled
fitdata.slope = slope; %scaled



