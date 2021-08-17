function [output,varargout] = ep_rescue_calc_hits_and_misses(stimuli,resps,varargin)
%output = ep_rescue_calc_hits_and_misses(stimuli,resps)
%
%This function calculates the numbers of hits, false alarms, misses and
%correct rejects during a behavioral sessions and assembles the data into a
%format ready for psychometric fitting. It also calculates behavioral
%dprime values. To avoid dprime values of +/- inf, percent correct values
%have a ceiling of 95%, and false alarm rates have a floor of 5% (default).
%This correction can be turned off with optional boolean flag.
%
%Input variables:
%   stimuli: 1D vector of stimulus values (in percent depth).
%   resps: 1D vector of responses (binary: 1 = contact. 0 = withdrawal)
%   varargin{1}: 0 | 1   If 1, turns off floor and ceiling corrections. 
%
%Output variable:
%   output: 2D structure with the following fields:
%       trialmat: M x 3 matrix arranged as 
%               [stimulus value (dB re: 100%), n_yes, n_trials]
%               The first row of trialmat contains fa and safe trial data.
%
%       dprimemat: M x 2 matrix arranged as
%               [stimulus value (dB re: 100%), dprime]
%               The safe stimulus is not included in the dprimemat.
%               This field is only created if floor/ceiling corrections are
%               applied to the hit rates (default).
%
%       varargout{1}: uncorrected fa rate
%
%Written by ML Caras Dec 5 2016. Updated Jan 6 2017.


%Initialize trialmat
trialmat = [];

%Calculate hits, misses, crs and fas
unique_stim = unique(stimuli);

%For each stimulus...
for i = 1:numel(unique_stim)
    
    stimulus_value = unique_stim(i);
    
    stimulus_index = find(stimuli == stimulus_value);
    
    %Pull out responses for just that stimulus...
    responses = resps(stimulus_index); %#ok<FNDSB>
    
    
    %Adjust for perfect performance (hit rate = 1 or FA rate = 0) by
    %bounding hit/fa rates between 0.05 and 0.95. Note that other common
    %corrections (i.e. log-linear, 1/2N, etc) artificially inflate lower
    %bound when go trial numbers are small, nogo trial numbers are large,
    %hit rates are very low and fa rates are very low. 
    
    %If NOGO
    if stimulus_value == 0
        
        %Count correct rejects and false alarms
        n_cr = sum(responses);
        n_fa = (numel(responses) - n_cr);
        n_safe = numel(responses);
        
        %Calculate fa rate
        fa_rate = (n_fa/n_safe);
        
        %Return uncorrected FA rate if desired
        if nargout>1
            varargout{1} = fa_rate;
        end
        
        %If correction should be applied (default)
        if nargin <3
            
            %Correct floor
            if fa_rate <0.05
                fa_rate = 0.05;
            end
            
            %Correct ceiling
            if fa_rate >0.95
                fa_rate = 0.95;
            end
            
            
            %Adjust number of false alarms to match adjusted fa rate (so we can
            %fit data with psignifit later)
            n_fa = fa_rate*n_safe;
        end
        
        %Convert to z score
        z_fa = sqrt(2)*erfinv(2*fa_rate-1);
        
        %Append to trialmat
        trialmat = [trialmat;stimulus_value,n_fa,n_safe];
        
    %IF GO
    else

        %Count hits and misses
        n_miss = sum(responses);
        n_hit = (numel(responses)- n_miss);
        n_warn = numel(responses);
        
        %Calculate hit rate
        hit_rate = n_hit/n_warn;
        
        
        %If correction should be applied (default)
        if nargin <3
            %Adjust floor
            if hit_rate <0.05
                hit_rate = 0.05;
            end
            
            %adjust ceiling
            if hit_rate >0.95
                hit_rate = 0.95;
            end
            
            %Adjust number of hits to match adjusted hit rate (so we can fit
            %data with psignifit later)
            n_hit = hit_rate*n_warn;
            
        end
       
        %Append to trial mat
        trialmat = [trialmat;stimulus_value,n_hit,n_warn]; %#ok<AGROW>
        
        
    end

end



%Convert stimulus values to log and sort data so safe stimulus is on top
trialmat(:,1) = make_stim_log(trialmat);
trialmat = sortrows(trialmat,1);

%Construct final output
output.trialmat = trialmat;

%If correction was applied (default), calculate dprime
if nargin <3
    hitrates = trialmat(2:end,2)./trialmat(2:end,3);
    z_hit = sqrt(2)*erfinv(2*(hitrates)-1);
    dprime = z_hit - z_fa;
    dprimemat = [trialmat(2:end,1),dprime];
    output.dprimemat = dprimemat;
end





end
