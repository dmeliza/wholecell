function currdir = uigetdir( varargin )
% UIGETDIR A dialog window that fetches a directory; analogous to UIGETFILE.
%

%   Author(s): P. N. Secakusuma, 27/04/98
%   Copyright (c) 1997 by The MathWorks, Inc.
%   $Revision$   $Date$

origdir = pwd;

if nargin == 0,
   
       fig = figure('NumberTitle', 'off', ...
              'MenuBar', 'none', ...
                 'Name', 'Get Directory', ...
                    'Resize', 'off', ...
                'Color', [0.760784 0.74902 0.647059], ...
               'Position', [700 500 300 250], ...
               'WindowStyle', 'modal', ...
               'CloseRequestFcn', 'set(gcf, ''Userdata'', ''Cancel'')', ...
                 'Tag', 'GetDirectoryWindow');
            
   hedit = uicontrol('Style', 'Edit', ...
                  'String', pwd, ...
                     'HorizontalAlignment', 'left', ...
                        'BackgroundColor', 'w', ...
                   'Position', [10 220 225  20], ...
                      'Tag', 'PWDText', ...
                         'ToolTipString', 'Present working directory');

       DirList = dir;
       DirName = { DirList.name }';
       finddir = find(cat(1, DirList.isdir));
       DirName = DirName(finddir);

       hlist = uicontrol('Style', 'Listbox', ...
                         'String', DirName, ...
                       'BackgroundColor', 'w', ...
                  'Position', [10  40 225 160], ...
                     'Callback', 'uigetdir(1)', ...
                        'Max', 1, ...
                   'ToolTipString', 'History of current directories', ...
                      'Tag', 'DirectoryContentListbox');
                 
   htxt1 = uicontrol('Style', 'Text', ...
                    'String', ['Choice:  ', pwd], ...
                    'HorizontalAlignment', 'left', ...
                    'FontWeight', 'bold', ...
                    'Position', [10  10 280 20], ...
                    'Tag', 'ChosenDirectoryText');
                 
   hbut1 = uicontrol('Style', 'Pushbutton', ...
                    'String', 'Get it!', ...
                    'Callback', 'uigetdir(2)', ...
                    'Position', [245  125  45  45]);
                 
   hbut2 = uicontrol('Style', 'Pushbutton', ...
                    'String', 'Cancel', ...
                    'Callback', 'uigetdir(3)', ...
                    'Position', [245  65  45  45]);
                 
   waitfor(fig, 'Userdata');
              
       switch get(fig, 'Userdata'),
   case 'OK',
     hlist_val = get(hlist, 'Value');
     hlist_str = get(hlist, 'String');
     cd([pwd, '\', hlist_str{hlist_val}]);
   case 'Cancel',
     cd(origdir);
       end
   currdir = pwd;

       delete(fig);

else
   
   switch varargin{1},
   case 1,
     if strcmp(get(gcf, 'SelectionType'), 'open'),
        hfig  = findobj('Tag', 'GetDirectoryWindow');
        hlist = findobj(hfig, 'Tag', 'DirectoryContentListbox');
                       hedit = findobj(hfig, 'Tag', 'PWDText');
                       htxt1 = findobj(gcf, 'Tag', 'ChosenDirectoryText');

                       hlist_val = get(hlist, 'Value');
                       hlist_str = get(hlist, 'String');
                       hlist_dir = hlist_str{hlist_val};

                       cd([pwd, '\', hlist_dir]);
                       DirList = dir;
                       DirName = { DirList.name }';
                       finddir = find(cat(1, DirList.isdir));
                       DirName = DirName(finddir);

                       set(hlist, 'String', DirName, ...
                                 'Value', 1);
                       set(hedit, 'String', pwd);

                       hlist_val = get(hlist, 'Value');
                       hlist_str = get(hlist, 'String');
                       ChosenDir = strrep([pwd, '\', hlist_str{hlist_val}], '\\', '\');
        
                       set(htxt1, 'String', ['Choice:  ', ChosenDir]);
     else
        hlist = findobj(gcf, 'Tag', 'DirectoryContentListbox');
        htxt1 = findobj(gcf, 'Tag', 'ChosenDirectoryText');
        
        hlist_val = get(hlist, 'Value');
        hlist_str = get(hlist, 'String');
        ChosenDir = strrep([pwd, '\', hlist_str{hlist_val}], '\\', '\');
        
        set(htxt1, 'String', ['Choice:  ', ChosenDir]);
     end
   case 2,
     set(gcf, 'Userdata', 'OK');
   case 3,
     set(gcf, 'Userdata', 'Cancel');
   end

end

return
