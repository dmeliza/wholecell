function data = Filter_Gaussian(action, data, parameters)
% Filters data using a noncausal Gaussian smoothing filter.
% Achieved by multiplying the data with a gaussian function in the
% hilbert domain.
%
% parameters:
%   hw  - the half-width at half-height parameter, in Hz
%
%
% $Id$

error(nargchk(1,3,nargin))

switch lower(action)
case 'params'
    prompt = {'Half-width of Gaussian'};
    if nargin > 1
        def = {num2str(data.hw)};
    else
        def = {'1000'};
    end
    title = 'Values for Gaussian Filter';
    answer = inputdlg(prompt,title,1,def);
    if ~isempty(answer)
        data = struct('hw',str2num(answer{1}));
    end
case 'describe'
    data = sprintf('Gaussian Filter (%d Hz)', data.hw);
case 'view'
    % gaussian is not causal, so we do the xcorr trick to extract the "equivalent"
    % FIR
    N   = 10000;
    x   = randn(N,1);
    y   = gf(x,10000,data.hw);
    c   = xcorr(x,y,data.hw);
    figure,freqz(c(data.hw/2:end),1);       % plot frequency response of equiv FIR    
case 'filter'
    for i = 1:length(data)
        data(i).data   = gf(data(i).data,data(i).t_rate,parameters.hw);
    end        
    
otherwise
    error(['Action ' action ' is not supported.']);
end

function out = gf(x,Fs,hw)
X   = fft(x);
f   = linspace(-Fs/2,Fs/2,length(X));   % frequency axis, 0 in the middle
G   = ifftshift(exp(-0.5 .* power(f,2) / power(hw,2)));
X   = X .* G';                           % filter in the frequency domain
out = real(ifft(X));                    % need to kill any residual imaginary stuff