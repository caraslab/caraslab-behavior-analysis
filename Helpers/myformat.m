function myformat(h,varargin)
%myformat(gca,xh,yh,th)
%
%Formats a figure to my preferred settings. Input variable h is the handle
%to the axis you want to format. Optional inputs are handles
%for the x label, y label and title, respectively.
%
%Written by Melissa L. Caras 4-12-10. Updated 6/25/2013.


fontsize = 14;

set(h,'box','off');
set(h,'TickDir','out')
set(h,'ticklength',[0.015 0.015])
set(h,'FontSize',fontsize)
set(h,'FontName','Arial')
set(h,'linewidth',2)

yh = get(h,'ylabel');
xh = get(h,'xlabel');
th = get(h,'title');

set(xh,'FontSize',fontsize)
set(xh,'FontName','Arial')

set(yh,'FontSize',fontsize)
set(yh,'FontName','Arial')

set(th,'FontSize',fontsize)
set(th,'FontName','Arial')


end

