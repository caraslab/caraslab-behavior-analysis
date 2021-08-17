function x = make_stim_log(mat)
%x = make_stim_log(mat)
%Converts AM depth values from proportions to dB re:100% values.
%
%Input variable mat contains data, with the first column containing
%stimulus values.
%
%ML Caras Dec 2015


x = mat(:,1);
x(x == 1)= 0.99; %to avoid infinity 
x(x == 0) = 0.01;%to avoid infinity
x = 20*log10(x);


end