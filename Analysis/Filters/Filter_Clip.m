function data = Filter_Clip(action, data, parameters)
% This filter is designed to remove spikes, artifacts, and other nasty
% things that are generally fast but difficult to remove with a
% simple lowpass filter.  This is accomplished by highpass filtering
% the data with a fairly high cutoff, extracting the indices of events
% that cross a certain +/- threshhold, and then directly interpolating
% the data for these time points.
%
% parameters:
%    .thresh - the selection threshhold 
%    .pass  - passband, in Hz, for the highpass filter
%
% undefined results if pass > Fs of data
%
% $Id$
error(nargchk(1,3,nargin))

switch lower(action)
case 'params'
    prompt = {'Exclusion Threshhold', 'Highpass Cutoff (Hz)'};
    if nargin > 1
        def = {num2str(data.thresh),num2str(data.pass)};
    else
        def = {'.1','100'};
    end
    title   = 'Values for Clipping Filter';
    answer  = inputdlg(prompt,title,1,def);
    if isempty(answer)
        data = [];
    else
        data    = struct('thresh',abs(str2num(answer{1})),'pass',abs(str2num(answer{2})),...
                         'order',3);
    end
case 'describe'
    % test for stability
    [b,a]   = makefilter(data, 10000);
    stable  = StabilityCheck(a);    
    data    = sprintf('Clipping Filter (%3.3f thresh, %d Hz cutoff)', data.thresh, data.pass);
    if ~stable
        data = sprintf('%s. Not Stable.',data);
    end
case 'view'
    % no preview necessary since the highpass filter is not used
case 'filter'
    if isstruct(data)
        for i = 1:length(data);
            Fs      = data(i).t_rate;
            [b,a]   = makefilter(parameters,Fs);
            hp      = filtfilt(b,a,data(i).data);       % highpass filtered signal
            t       = linspace(0,length(hp)/Fs,length(hp));
            below   = abs(hp) <= parameters.thresh;    % logical array
            X       = interp1(t(below),data(i).data(below),t','linear','extrap');  % interpolate missing pts
            data(i).data = X;
            %gaps    = findgaps(hp, parameters.thresh);
        end
    end
otherwise
    error(['Action ' action ' is not supported.']);
end

function gaps = findgaps(data, thresh)
% detects points at which the absolute value of the signal (data)
% exceeds the threshhold.  Returns a 2 column array: the first
% column gives the starting index of each gap, and the second column
% gives the length of each gap
above  = abs(data) > 0.1;                           % logical array of excluded points
trans  = diff(above);                               % changes from included/excluded
transi = find(trans);
if trans(transi(1)) == -1
    transi = transi(2:end);                         % remove an initial excluded period
end
if mod(length(transi),2)
    transi = transi(1:end-1);                       % remove a final excluded period
end
ind     = reshape(transi,2,length(transi)/2);       % first column are beginngs, 2nd are ends
gaps    = [ind(:,1), ind(:,2) - ind(:,1)];          % beginnings and lengths


function [b,a] = makefilter(parameters, Fs)
Wn      = parameters.pass/(Fs/2);
if Wn >= 1
    Wn = 0.999;
end
[b,a]   = butter(parameters.order, Wn, 'high');