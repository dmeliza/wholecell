function sfp = FormatAssignment(property, value)
% When generating assignment string intended to be eval'd
% we have to know what the format of the data is so that
% we can make the correct string.
% 
% OUT = FormatValue(value)
%
%
% $Id$
% we have to escape string assignments
if (ischar(value))
    sfp = sprintf('%s = ''%s'';', property, value);
elseif (isnumeric(value)) % assignment of values
    sfp = sprintf('%s = %d;', property, value);
else % structs, cell arrays, and pointers, we need to know the variable name
%     if (nargin > 1)
%         sfp = varargin{1};
%     else
        disp('Can''t deal with this data structure');
%     end
end
