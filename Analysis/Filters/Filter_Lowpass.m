function data = Filter_Lowpass(action, data, parameters)
% Filters data using an n-pole butterworth lowpass filter.
% Uses FiltFilt to avoid phase offsets.
%
% parameters:
%    .pass  - passband, in Hz
%    .order - order of the filter, default = 3
%
% undefined results if pass > Fs of data
%
% $Id$
error(nargchk(1,3,nargin))

switch lower(action)
case 'params'
    prompt = {'Passband (Hz)','Order'};
    if nargin > 1
        def = {num2str(data.pass),num2str(data.order)};
    else
        def = {'1000','3'};
    end
    title   = 'Values for LowPass Filter (ignored)';
    answer  = inputdlg(prompt,title,1,def);
    data    = struct('pass',abs(str2num(answer{1})),'order',abs(fix(str2num(answer{2}))));
case 'describe'
    data    = sprintf('LowPass Filter (%d Hz, order %d)', data.pass, data.order);
case 'filter'
    if isstruct(data)
        if ~isfield(parameters,'order')
            parameters.order = 3;
        end
        for i = 1:length(data);
            Fs      = data(i).t_rate;
            Wn      = parameters.pass/(Fs/2);
            [b,a]   = butter(parameters.order,Wn);
            data(i).data = filtfilt(b,a,data(i).data);  % modify data in place
        end
    end
otherwise
    error(['Action ' action ' is not supported.']);
end
