function varargout = myplot(varargin)
%varargout = myplot(varargin)
%
%Initializes a figure window of my preferred size and color. Optional input
%can be the figure number. Optional output is figure handle.
%
%Written by Melissa L. Caras 4-12-10

scrsz = get(0,'ScreenSize');

if nargin>0
   f =  figure(varargin{1});
else
   f =  figure;
end

set(gcf,'color','w');
set(gcf,'position',[1 scrsz(4)/2 scrsz(3)/1.5 scrsz(4)]);
varargout{1} = f;

end