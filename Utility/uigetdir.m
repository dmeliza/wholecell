function currdir = uigetdir( varargin )
% UIGETDIR A dialog window that fetches a directory; analogous to UIGETFILE.
%

%   Adapted from: P. N. Secakusuma, 27/04/98
%   
%   Copyright (c) 1997 by The MathWorks, Inc.
%   $Revision$   $Date$

origdir = pwd;

if nargin == 0,
   
       fig = figure('NumberTitle', 'off', ...
              'MenuBar', 'none', ...
                 'Name', 'Get Directory', ...
                    'Resize', 'off', ...
                'Color', get(0,'defaultUicontrolBackgroundColor'), ...
               'Position', [700 500 300 250], ...
               'WindowStyle', 'modal', ...
               'CloseRequestFcn', 'set(gcf, ''Userdata'', ''Cancel'')', ...
                 'Tag', 'GetDirectoryWindow');
            
   hedit = uicontrol('Style', 'Edit', ...
                  'String', pwd, ...
                     'HorizontalAlignment', 'left', ...
                        'BackgroundColor', 'w', ...
                   'Position', [10 220 195  20], ...
                      'Tag', 'PWDText', ...
                         'ToolTipString', 'Present working directory');

       hlist = uicontrol('Style', 'Listbox', ...
                         'String', getdirectories, ...
                       'BackgroundColor', 'w', ...
                  'Position', [10  40 195 160], ...
                     'Callback', 'uigetdir(''choose'')', ...
                        'Max', 1, ...
                   'ToolTipString', 'History of current directories', ...
                      'Tag', 'DirectoryContentListbox');
                 
   htxt1 = uicontrol('Style', 'Text', ...
                    'String', ['Choice:  ', pwd], ...
                    'HorizontalAlignment', 'left', ...
                    'FontWeight', 'bold', ...
                    'Position', [10  10 280 20], ...
                    'Tag', 'ChosenDirectoryText');
   
   hbut = uicontrol('Style','pushbutton',...
                    'String','New Directory',...
                    'Callback','uigetdir(''create_dir'')',...
                    'Position',[215 115 80 25]);
                
   hbut1 = uicontrol('Style', 'Pushbutton', ...
                    'String', 'Select', ...
                    'Callback', 'uigetdir(''select'')', ...
                    'Position', [215  90  80  25]);
                 
   hbut2 = uicontrol('Style', 'Pushbutton', ...
                    'String', 'Cancel', ...
                    'Callback', 'uigetdir(''cancel'')', ...
                    'Position', [215  65  80  25]);
                
   drawnow;
                
   waitfor(fig, 'Userdata');
              
       switch get(fig, 'Userdata'),
   case 'OK',
     hlist_val = get(hlist, 'Value');
     hlist_str = get(hlist, 'String');
     cd([pwd, filesep, hlist_str{hlist_val}]);
     currdir = pwd;
     cd(origdir)
   case 'Cancel',
     currdir = pwd;
   end

   delete(fig);

else
   
   switch varargin{1},
   case 'choose',
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
   case 'select',
     set(gcf, 'Userdata', 'OK');
   case 'cancel',
     set(gcf, 'Userdata', 'Cancel');
   case 'create_dir'
     a = inputdlg('New directory name:','Create Directory',1,{'New Directory'});
     if ~isempty(a{1})
         s = mkdir(a{1});
     end
     t = findobj(gcf,'tag','DirectoryContentListbox');
     set(t(1),'String',getdirectories);
   end

end

function dirnames = getdirectories()
% returns the directories in the current directory
dirlist = dir;
dirnames = { dirlist.name }';
finddir = find(cat(1, dirlist.isdir));
dirnames = dirnames(finddir);