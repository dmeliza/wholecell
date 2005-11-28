function [dZ, dR, dw, tt, t] = ModelTemporal(params)
%
% A little model of inter-trial variation in vivo, taking into account
% static and stochastic latency variability.
%
% Arguments:
% t_spike - (if scalar) time of the spike relative to center of 
%           input distribution (default is 0 for both)
% params  - (if struct) a structure containing the fixed parameters of the
%           experiment (described below)
%
% stoch   - the ratio of the SDs of the stochastic latency distribution and
% the fixed latency distribution. Default is 0.1 (and sigma_t defaults to
% 10)
%
% Experiment paramters:
% t_spike   - time of postsynaptic spike (relative to center of distrib)
%             [default 0 ms]
% t_sigma   - SD of distribution of FIXED latencies
%             [default 10 ms]
% stoch     - ratio of SD of distriubtion of STOCHASTIC latencies to t_sigma
%             [default 0.1]
% n         - number of presynaptic cells (cell number j) [default 100]
% m         - number of trials [default 2000]
% Pn        - scaling factor of firing probability (average # of cells that
%             fire in a trial) [10]
% tau_p     - time constant of ltp window [20 ms]
% tau_d     - time constant of ltd window [20 ms]
% A_p       - amplitude of ltp window [0.005]
% A_d       - amplitude of ltd window [0.005]
% Fs        - sampling rate [4 ms]
%
% Variables:
% j - cell number
% i - trial number
%
% Model parameters:

% w(j)  - weight of presynaptic cell
% t(j)  - mean latency of presynaptic cell
% T(j,i)  - latency error (distribution)
% P(j,i)  - firing reliability (binomial distribution)
%
% kern  - EPSC kernel
%
% Returns:
% dZ(tt) - change in weighted PSTH
% dR(tt) - change in predicted EPSC
% dw(t) - change (norm) in synaptic weights
% tt    - time variable in each trial (relative to spike time)
% t     - latency of each synapse
%
% $Id$
  

% Initialize parameters
% defaults:
default = struct('t_spike',0,...
                 't_sigma',10,...
                 'stoch',0.1,...
                 'n',100,...
                 'm',2000,...
                 'Pn',10,...
                 'tau_p',20,...
                 'tau_d',20,...
                 'A_p',0.005,...
                 'A_d',0.005,...
                 'Fs',4,...
                 'time',[-100 200]);
             
% check the user's arguments
if nargin > 0
    if isstruct(params)
        % here we replace any values that the user supplies
        fn    = fieldnames(params);
        for i = 1:length(fn)
            default.(fn{i}) = params.(fn{i});
        end
    else
        default.t_spike = params;
    end
end
params  = default;

% Derive the rest of the parameters
time    = linspace(params.time(1),params.time(2),diff(params.time)/params.Fs);

t_mu    = 0;
T_mu    = 0;
T_sigma = params.t_sigma * params.stoch;

P_n     = 1;
P_p     = 1/params.n * params.Pn;

expfun  = inline('b(1) .* exp(x ./ b(2))','b','x');
% this goes much faster if there is a lookup table, which has to be double
% the size of the window
w_kern      = [time(1) time(end)] * 2;
t_kern      = linspace(w_kern(1),w_kern(2),diff(w_kern)/params.Fs);
ltd_kern    = expfun([-params.A_d -params.tau_d],t_kern(t_kern>0));
ltp_kern    = expfun([params.A_p params.tau_p],fliplr(t_kern(t_kern<=0)));

% Load and initialize EPSC convolution kernel
kernname    = 'EPSC.mat';
epsc        = load(kernname);
% downsample to Fs
Fs_epsc     = mean(diff(epsc.time)) * 1000;    % in seconds
epsc        = [epsc.data];    
epsc        = BinData(epsc,fix(params.Fs/Fs_epsc),1);

expfun  = inline('b(1) .* exp(x ./ b(2))','b','x');

% static distributions
t       = normrnd(t_mu,params.t_sigma,params.n,1);
w       = ones(params.n,1);
w_pre   = w;

% continuously apply induction, and compare the first 100 to the last 100.
Z       = zeros(params.m,length(time));
t_s     = fix((params.t_spike - min(time))./params.Fs);

for i = 1:params.m
    % generate trial distributions
    T           = normrnd(T_mu,T_sigma,params.n,1);
    P           = binornd(P_n,P_p,params.n,1);
    events      = ((t + T - min(time)) .* P);
    events      = round(events ./ params.Fs);      % bin # of event
    % with a lot of variance, events can wind up outside the window, in
    % which case it should be expanded
    if any(events<0 | events>length(time))
        error('Event fell outside window. Window needs to be expanded.');
    end
    event_ind   = find(events);
    for k = 1:length(event_ind)
        j       = event_ind(k);                   % cell #
        tm      = events(j);
        Z(i,tm)  = Z(i,tm) + w(j);
        % potentiate and depress
        dt      = (tm - t_s);
        if dt > 0
            w(j)    = w(j) + w(j) * ltd_kern(dt);
        else
            w(j)    = w(j) + w(j) * ltp_kern(-dt+1);
        end
    end
end

Z_pre   = Z(1:100,:);
r       = conv(sum(Z_pre,1),epsc);
R_pre   = r(1:length(time));
Z_post  = Z(end-100:end,:);
r       = conv(sum(Z_post,1),epsc);
R_post  = r(1:length(time));

dZ  = mean(Z_post',2) - mean(Z_pre',2);     % delta weighted PSTH
dR  = (R_post - R_pre) / min(R_pre);        % delta predicted EPSC
dw  = w ./ w_pre;                           % delta (norm) synaptic weight
tt  = time - params.t_spike;
t   = t - params.t_spike;

if nargout > 0
    return
end

f   = figure;
set(gcf,'Color',[1 1 1])
ResizeFigure(f,[6.5 5])
colormap(flipud(gray));
a1 = subplot(4,2,[1 3]);
imagesc(time,1:params.m,Z);
vline(params.t_spike,'k:')
ylabel('Trial')
a2 = subplot(4,2,5);
% imagesc(time,1:n,Z_post);
plot(time,mean(Z_pre,1),'k');
hold on
plot(time,mean(Z_post,1),'r');
vline(params.t_spike,'k:')
ylabel('Weighted PSTH')
% subplot(4,1,3)
% mtrialplot(time,R_pre');
a3 = subplot(4,2,7);
plot(time,R_pre,'k');
hold on
plot(time,R_post,'r');
vline(params.t_spike,'k:')
ylabel('Predicted EPSC')
xlabel('Time (ms)')

set([a1 a2 a3],'XLim',[time(1) time(end)],'Box','On')
set([a1 a2],'XTickLabel',[]);
set([a1 a2 a3],'YTick',[]);

a4 = subplot(4,2,[4 6]);
p = plot((t),log10(w),'k.');
yt  = [0.25 0.5 1 2 4];
set(a4,'YTick',log10(yt),'YTickLabel',num2str(yt'*100))
hline(0,'k:'),vline(0,'k:')
xlabel('Time from Spike (ms)')
ylabel('\DeltaSynaptic Weight (%)')

