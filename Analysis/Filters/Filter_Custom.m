function out = Filter_Custom(action, data, parameters)
%
% A user can directly specify the transfer function of the filter, using
% B(z)/A(z) coefficients.
%
% parameters:
%   a - A(z) (row vector, n > 0)
%   b - B(z) (row vector, n > 0)
%
% $Id$

error(nargchk(1,3,nargin))
out = [];

switch lower(action)
case 'params'
    prompt = {'B(z) coefficients (vector notation)','A(z) coefficients (vector notation)'};
    if nargin > 1
        def = {['[' num2str(data.b) ']'], ['[' num2str(data.a) ']']};
    else
        def = {'[1]','[1]'};
    end
    title = 'Values for Custom Filter';
    answer = inputdlg(prompt,title,1,def);
    if ~isempty(answer)
        a   = str2num(answer{2});
        b   = str2num(answer{1});
        out = struct('b',b(:),'a',a(:));        % convert to row vectors
    end
case 'describe'
    out = sprintf('Custom Filter (b = [%s], a = [%s])',...
        num2str(data.b), num2str(data.a));
case 'view'
    figure,freqz(data.b,data.a);
case 'filter'
    if ~isstruct(data)
        out = data;
    else
        for i = 1:length(data)
            data(i).data    = filter(parameters.b,parameters.a,data(i).data);
        end
        out = data;
    end
otherwise
    error(['Action ' action ' is not supported.']);
end    