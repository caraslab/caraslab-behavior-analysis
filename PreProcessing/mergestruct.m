%mergescript.m
%
%Use this script to merge the data and info structures from two different
%data files. Necessary when program crashes in the middle of testing, and a
%second session is run immediately after crash.
%
%Written by ML Caras May 2019

savename = 'mergedfile.mat'; %Update with your preferred filename and path


%Load first file
[f,p] = uigetfile;
A = load([p,f]);

%Load second file
[f,p] = uigetfile;
B = load([p,f]);

%How many values are in each structure?
szA = length(A.Data);
szB = length(B.Data);
fullsz = szA+szB;

%Pull out field names
fields = fieldnames(A.Data);

%Create empty structure
Data = [];

%For each field...
for i = 1:numel(fields)
     aField  = fields{i};
     
     %Add value into data structure
     for k = 1:fullsz
         if k <= szA
             Data(1,k).(aField) = A.Data(1,k).(aField);
         else
             m = k - szA;
             Data(1,k).(aField) = B.Data(1,m).(aField);
         end
     end
end

%Update info structure and water value
water = A.Info.Water + B.Info.Water;
Info = A.Info;
Info.Water = water;

%Save variables
save(savename,'Data','Info')