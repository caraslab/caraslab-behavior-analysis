function save_my_figure(h,format,save_name)
%Saves the figure with handle "h" in the specified format, 
%with the filename specified by save_name. 
%
%Format options are as follows:
%
% -dps                  PostScript for black and white printers
% -dpsc                 PostScript for color printers
% -dps2                 Level 2 PostScript for black and white printers
% -dpsc2                Level 2 PostScript for color printers
% 
% -deps                 Encapsulated PostScript
% -depsc                Encapsulated Color PostScript
% -deps2                Encapsulated Level 2 PostScript
% -depsc2               Encapsulated Level 2 Color PostScript
% 
% -dhpgl                HPGL compatible with Hewlett-Packard 7475A plotter
% -dill                 Adobe Illustrator 88 compatible illustration file
%
% -djpeg<nn>            JPEG image, quality level of nn (figures only)
% E.g., -djpeg90 gives a quality level of 90.
% Quality level defaults to 75 if nn is omitted.
%
% -dtiff                TIFF with compression
% -dtiffnocompression   TIFF without compression
% -dpng                 Portable Network Graphic 24-bit truecolor image
% (figures only)
%
%Ex usage: save_my_figure(f1,'-dpng','My_figure')
%
%Written by MLC 3/25/2013


directory = uigetdir;
fname =  [directory, '/', save_name];
set(h,'PaperPositionMode','auto');
print(h,'-painters',format, [directory, '/', save_name])


%Fix dotted lines in output file if figure was saved as .eps
% if strcmp(format,'-depsc')
%     fname = [fname '.eps'];
%    fix_lines(fname)
% end

end








