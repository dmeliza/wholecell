function out = Filter_Threshhold(action, data, parameters)
%
% Now we are getting serious:
%   y(n) = x(n) - R; x(n) > R
%        = 0       ; x(n) <= R
%
% Of course, the user can select whether to keep values above or below the threshhold
%
% parameters:
%   thresh  - the threshhold, in whatever units the signal is in
%   sign    - if >= 0, R is a lower bound, if < 0, R is an upper bound
%   
%
% $Id$

error(nargchk(1,3,nargin))
out = [];

switch lower(action)
case 'params'
    prompt = {'Threshhold','Lower (>0) or Upper (<0) bound?'};
    if nargin > 1
        def = { num2str(data.thresh), num2str(sign(data.sign))};
    else
        def = {'1','1'};
    end
    title = 'Values for Threshhold Filter';
    answer = inputdlg(prompt,title,1,def);
    if ~isempty(answer)
        out = struct('thresh',str2num(answer{1}),'sign',sign(str2num(answer{2})));
    end
case 'describe'
    if data.sign >= 0
        s = 'lower';
    else
        s = 'upper';
    end
    out = sprintf('Threshold Filter (%d, %s)',data.thresh, s);
case 'view'
    % not LTI
case 'filter'
    if ~isstruct(data)
        out = data;
    else
        for i = 1:length(data)
            if parameters.sign >= 0
                data(i).data  = (data(i).data > parameters.thresh) .* (data(i).data - parameters.thresh);
            else
                data(i).data  = (data(i).data < parameters.thresh) .* (data(i).data - parameters.thresh);
            end
        end
        out = data;
    end
otherwise
    error(['Action ' action ' is not supported.']);
end    