function se = sem(data,dim)
%Calculates the standard error of the mean of the vector data along the
%dimension specified by dim. Uses the n-1 normalization.
%
%Written by MLC 4/10/13


stdev = nanstd(data,0,dim);
n = size(data,dim);
se = stdev/(sqrt(n-1));


end