function out = Filter_Static(action, data, parameters)
%
% A simple filter that applies a static function to the data
% (allowing change of units if desired)
%
% parameters:
%   func   - the function, in inline format, to apply to the data
%   units  - the new units
%   
%
% $Id$

error(nargchk(1,3,nargin))
out = [];

switch lower(action)
case 'params'
    prompt = {'Static Function (one variable)','Units'};
    if nargin > 1
        def = {char(data.func), data.units};
    else
        def = {'x','nA'};
    end
    title = 'Values for Static Filter';
    answer = inputdlg(prompt,title,1,def);
    if ~isempty(answer)
        func = inline(answer{1});
        out = struct('func',func,'units',answer{2});
    end
case 'describe'
    out = sprintf('Static Filter (%s, %s)',char(data.func), data.units);
case 'view'
    figure,ezplot(data.func);
case 'filter'
    out = data;
    if isstruct(data)
        for i = 1:length(data)
            try
                data(i).data   =  parameters.func(data(i).data);
                data(i).y_unit =  parameters.units;
            catch
                errordlg(['Unable to execute function: ' lasterr]);
                data = [];
            end                
        end
        out = data;
    end
otherwise
    error(['Action ' action ' is not supported.']);
end    