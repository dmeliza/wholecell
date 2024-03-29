function data = Filter_Lowpass(action, data, parameters)
% Filters data using an n-pole butterworth bandpass filter.
% Uses FiltFilt to avoid phase offsets.
%
% parameters:
%    .passmin  - low passband, in Hz
%    .passmax  - high passband, in Hz
%    .order    - order of the filter, default = 4
%
% undefined results if pass > Fs of data
%
% $Id$
error(nargchk(1,3,nargin))

switch lower(action)
case 'params'
    prompt = {'Low Passband (Hz)','High Passband (Hz)','Order'};
    if nargin > 1
        def = {num2str(data.passmin),num2str(data.passmax),num2str(data.order)};
    else
        def = {'1','1000','4'};
    end
    title   = 'Values for BandPass Filter (ignored)';
    answer  = inputdlg(prompt,title,1,def);
    if isempty(answer)
        data = [];
    else
        data    = struct('passmin',abs(str2num(answer{1})),'passmax',abs(str2num(answer{2})),...
                  'order',abs(fix(str2num(answer{3}))));
    end
case 'describe'
    % test for stability
    [b,a]   = makefilter(data, 10000);
    stable  = StabilityCheck(a);
    data    = sprintf('BandPass Filter (%d - %d Hz, order %d)',...
        data.passmin, data.passmax, data.order);
    if ~stable
        data = sprintf('%s. Not Stable.',data);
    end
case 'view'
    [b,a]   = makefilter(data, 10000);
    figure,freqz(b,a);    
case 'filter'
    if isstruct(data)
        if ~isfield(parameters,'order')
            parameters.order = 3;
        end
        for i = 1:length(data);
            Fs      = data(i).t_rate;
            [b,a]   = makefilter(parameters, Fs);
            data(i).data = filtfilt(b,a,data(i).data);  % modify data in place
        end
    end
otherwise
    error(['Action ' action ' is not supported.']);
end

function [b,a] = makefilter(parameters, Fs)
Wn      = [parameters.passmin/(Fs/2), parameters.passmax/(Fs/2)];
[b,a]   = butter(parameters.order,Wn);