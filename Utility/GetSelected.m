function out = GetSelected(list_handle)
% Returns the string selected in a list uicontrol. If multiple items
% are selected, a character array is returned.
%
% Usage: out = GetSelected(list_handle)
%
% list_handle - graphics object handle for the list
%
% $Id$
i = get(list_handle,'Value');
s = get(list_handle,'String');
if iscell(s)
    out = char({s{i}});
elseif i <= length(s)
    out = s(i,:);
else
    out = s;
end