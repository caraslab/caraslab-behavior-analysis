function d = cohensd(data1,data2)
%d = cohensd(data1,data2)
%
%This function calculates cohen's d, a measure of effect size based on
%differences between the means.
%
%Input variables:
%
%   data1: vector of data values from one sample distribution
%   data2:vector of data values from a second sample distribution
%
%Written by ML Caras Feb 7, 2017.

%Remove nans
data1 = data1(~isnan(data1));
data2 = data2(~isnan(data2));

%Counts
n1 = numel(data1);
n2 = numel(data2);

%Means
mean1 = mean(data1);
mean2 = mean(data2);

%Variances
var1 = (1/(n1-1))*sum((data1 - mean1).^2);
var2 = (1/(n2-1))*sum((data2 - mean2).^2);

%Pooled standard deviation
s = sqrt((((n1-1)*var1) + ((n2-1)*var2))/(n1+n2-2));

%Cohen's d
d = (mean1-mean2)/s;