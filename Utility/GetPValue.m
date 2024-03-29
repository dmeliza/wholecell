function out = GetPValue(paramstruct, varargin)
% This function retrieves the value from a parameter structure.
% This is particularly useful if the fieldtype is 'list' (or something else),
% as this will make the value something useful/displayable.
%
% USAGE: out = GetPValue(paramstruct, [value_format])
%
% paramstruct   - the parameter structure
% value_format  - for lists, value_format can be 'String' or {'Value'}, otherwise
%                 it's meaningless
%
% out           - the output value, which can be numeric or a character string
%
% See Also:
%   headers/param_struct.m  - defines the fields in a parameter struct
%
% $Id$

out = paramstruct.value;
switch lower(paramstruct.fieldtype)
case 'list'
    if nargin > 1
        value_format = varargin{2};
    else
        value_format = 'Value';
    end
    switch lower(value_format)
    case 'value'
        if ~isnumeric(out)
            out = strmatch(out,paramstruct.choices);
        end
    otherwise
        if isnumeric(out)
            out = paramstruct.choices{out};
        end
    end
case 'value'
    if ischar(out)
        out = str2num(out);
    end
case 'string'
    if isnumeric(out)
        out = num2str(out);
    end
end

            