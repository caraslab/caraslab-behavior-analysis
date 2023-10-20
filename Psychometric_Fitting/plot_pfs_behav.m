function plot_pfs_behav(directoryname,figuredirectory, experiment_type)
%plot_pfs_behav(directoryname,figuredirectory)
%
%For each animal in a specified directory, this function
%produces fitted psychometric functions (pfs) within
%individual sessions. This function uses psignifit v4. For additional
%information see: https://github.com/wichmann-lab/psignifit/wiki. Threshold
%and slope values returned are for the scaled fits.
%
%
%Written by MLC 11/28/2016.

% Patched by M Macedo-Lima November, 2020
% Patched by R Ying November 2022

%---------------------------------------
warning('off','psignifit:ThresholdPCchanged');
set(0,'DefaultTextInterpreter','none');

[options, plotOptions] = setOptions;

%Get a list of .mat files in the directory
[file_list, file_index] = listFiles(directoryname,'*allSessions.mat');

subplot_rows = 6;
subplot_cols = 6; %subplot index too small

%For each file...
for which_file = 1:length(file_index)
    

    %Load file
    filename = file_list(file_index(which_file)).name;
    load(fullfile(directoryname, filename));
    
    % Skip files without Info.Bits field which indicates frequency tuning
    % protocol was used
    if ~isfield(Session(1).Info,'Bits')
        continue
    end
    
    
    %Remove fitdata field to start fresh
    if isfield(output,'fitdata')
        output = rmfield(output,'fitdata');
    end
    
    %Set value of dprime that we define as threshold
    options.dprimeThresh = 1;
    
    
    %Clear plots and handle vectors
    f1 = myplot;
    f2 = myplot;
    handles_f1 = [];
    handles_f2 = [];
    
    
    %For each session...
    for which_session = 1:numel(output)
        
        clear data_to_fit;
        
        %Pull out data from a single session
        data_to_fit = output(which_session).trialmat;
        
        %Continue to next file if there's no data
        if isempty(data_to_fit)
            continue
        end
        
        % Make sure threshold is not below lowest AM depth presented
        low_range = data_to_fit(2, 1);
        options.stimulusRange = [low_range, -0.01];
        
        %Fit the data
        [options,results,zFA] = find_threshPC(data_to_fit,options);
        
        %Plot the percent correct values and fit, and save handles
        figure(f1);
        s = subplot(subplot_rows,subplot_cols,which_session);
        plotPsych(results,plotOptions);
        handles_f1 = [handles_f1;s]; %#ok<*AGROW>
        
        
        
        %------------------------------------------------------
        %Now transform to dprime space
        %------------------------------------------------------
        figure(f2)
        s2 = subplot(subplot_rows,subplot_cols,which_session);
        try
        [x,fitted_yes,fitted_dprime,threshold,slope] = ...
            plotPsych_dprime(results,...
            output(which_session).dprimemat,options,plotOptions,zFA);
        catch ME
            if strcmp(ME.message, 'The threshold percent correct is not reached by the sigmoid!')
                continue
            else
                rethrow(ME);
            end
            
        end
        hold on;
        
        %Save plot handles
        handles_f2 = [handles_f2;s2];
        
        
        %Save everything to data structure
        d.results = results;
        d.fit_plot.x = x;
        d.fit_plot.pCorrect = fitted_yes;
        d.fit_plot.dprime = fitted_dprime;
        d.threshold = threshold; %scaled
        d.slope = slope; %scaled
        
        output(which_session).fitdata = d;
        

        
    end
    
    
    %Save figures
    try
        linkaxes(handles_f1);
        linkaxes(handles_f2);
    catch ME
        if strcmp(ME.message, 'There must be at least one valid axes.')
            continue
        else
            rethrow(ME);
        end
    end
    
    for j = 1:2
        if j == 1
            figType = '_perCorrect';
            f = f1;
        else
            figType = '_dprime';
            f = f2;
        end
        
        fname = [file_list(file_index(which_file)).name(1:end-4),figType];
        suptitle(fname(4:end-4))
        set(f,'PaperPositionMode','auto');
        print(f,'-painters','-depsc', fullfile(figuredirectory,fname))
    end
    
    close all
    
    
    %Save file
    fname = file_list(file_index(which_file)).name(1:end-4);
    savename = fullfile(directoryname,fname);
    save(savename,'output','-append');
    disp(['Fit and threshold saved successfully to ', savename])
    
    
    %  MML edit: generate a CSV with thresholds and session ID too
    load(savename);
    block_id = {};
    thresholds = {};
    optoStims = {};
    for session_idx=1:numel(Session)
        try
            try
                cur_block_id = datestr(datetime(Session(session_idx).Info.StartTime), 'yymmdd-HHMMSS');
            catch ME
                if strcmp(ME.identifier, 'MATLAB:datetime:UnrecognizedDateStringSuggestLocale')
                    % Some sessions have weird format because they didn't save properly
                    cur_block_id = [datestr(datenum(Session(session_idx).Info.StartDate), 'yymmdd') '-' Session(session_idx).Info.StartTime];

                else
                    throw(ME)
                end
            end

           cur_threshold = output(session_idx).fitdata.threshold;
        catch ME
            if strcmp(ME.identifier, 'MATLAB:structRefFromNonStruct')
                fprintf(ME.message);
                continue
            else
                throw(ME)
            end
        end

        block_id{end+1} = cur_block_id;
        thresholds{end+1} = cur_threshold;
                
        % Check for Optostim field
        if isfield(Session(session_idx).Info, 'Optostim')
            optoStim = Session(session_idx).Info.Optostim;
            optoStims{end+1} = optoStim;
        end
     
    end
    if isempty(optoStims)
        output_table = cell2table(horzcat(block_id', thresholds'));

        output_table.Properties.VariableNames = {'Block_id' 'Threshold'};
    else
        output_table = cell2table(horzcat(block_id', thresholds', optoStims'));
        output_table.Properties.VariableNames = {'Block_id' 'Threshold' 'Optostim'};
    end

    writetable(output_table, fullfile([savename '_psychThreshold.csv']));
    
end

end





