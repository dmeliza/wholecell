function out = GetSelected(list_handle)
% Returns the string selected in a list uicontrol
%
% $Id$
i = get(list_handle,'Value');
s = get(list_handle,'String');
if iscell(s)
    out = s{i};
elseif i <= length(s)
    out = s(i,:);
else
    out = s;
end