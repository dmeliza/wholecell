function out = Filter_Bin(action, data, parameters)
%
% Downsamples data by binning it at a fixed rate.
%
% parameters:
%   .binrate - the amount by which to bin the data.  needs to be a positive integer
%
% $Id$

error(nargchk(1,3,nargin))
out = [];

switch lower(action)
case 'params'
    prompt = {'Bin Rate (n > 0)'};
    if nargin > 1
        def = {num2str(data.binrate)};
    else
        def = {'100'};
    end
    title = 'Values for Binning Filter';
    answer = inputdlg(prompt,title,1,def);
    if ~isempty(answer)
        out = struct('binrate',fix(abs(str2num(answer{1}))));
    end
case 'describe'
    out = sprintf('Binning Filter (%d)', data.binrate);
case 'view'
    % binning is not a LTI filter (or causal), so it's hard to say what to display here
    % what we do is bin some randn data, use xcorr to extract the impulse response
    % function, and display the freqz of an equivalent FIR
    N   = 10000;
    x   = randn(N,1);
    y   = BinData(x,data.binrate,1);
    yr  = interp(y,data.binrate);       % this produces a much smoother kernel
    len = data.binrate*10;              % keep a kernel 10x longer than bintime
    c   = xcorr(x,yr,len);  
    figure,freqz(c(len/2:end),1);       % plot frequency response of equiv FIR
case 'filter'
    if ~isstruct(data)
        out = data;
    else
        for i = 1:length(data)
            Fs      = data(i).t_rate;
            br      = parameters.binrate;
            data(i).data    = BinData(data(i).data, br, 1);
            data(i).t_rate  = fix(Fs/br);
            % fixing the timing is tricky, and only gives good answers in
            % cases where the frame rate of the timing signal is much lower
            % than Fs/br
            data(i).timing  = fix((data(i).timing - 1) / br) + 1;
        end
        out = data;
    end
    
otherwise
    error(['Action ' action ' is not supported.']);
end    