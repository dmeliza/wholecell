function sfp = FormatAssignment(property, value)
% When generating assignment strings intended to be eval'd
% we have to know what the format of the data is so that
% we can make the correct string.  This function is used by
% SetParam.  It can't really deal with anything but strings
% and numeric values, as I have no desire to convert cells or
% structs to string equivalents, and it's pretty easy to just
% assign that value directly.
% 
% USAGE: str = FormatValue(property, value)
%
% property - the field identifier
% value    - the value to assign to the field
% str      - the string that can be eval'd to assign the value to the field
%
% $Id$

if (ischar(value))
    sfp = sprintf('%s = ''%s'';', property, value);
elseif (isnumeric(value))                   
    sfp = sprintf('%s = %d;', property, value);
else 
    error('FormatAssignment can''t deal with this data structure');
end
