function [dZ, dR, t] = ModelTemporal(t_spike)
%
% A little model of inter-trial variation in vivo, taking into account
% static and stochastic latency variability.
%
% Variables:
% j - cell number
% i - trial number
%
% Model parameters:
% n     - number of presynaptic cells (cell number j)
% m     - number of trials
% w(j)  - weight of presynaptic cell
% t(j)  - mean latency of presynaptic cell
% T(j,i)  - latency error (distribution)
% P(j,i)  - firing reliability (binomial distribution)
%
% kern  - EPSC kernel
%
% Constants:
% Fs    - binsize
%
% $Id$

% Initialize parameters
Fs      = 5;           % ms
time    = (-20*Fs):Fs:(Fs*120); % 30-bin window

n       = 100;          % cells
m       = 100;          % trials
m_ind   = 30;           % induction trials

t_mu    = 100;
t_sigma = 10;

T_mu    = 0;
T_sigma = 1;

P_n     = 1;
P_p     = 1/n * 2;     % fire ~2 cells per trial


% spike times are relative to the mean event time
if nargin == 0
    t_spike = t_mu + 5;
else
    t_spike = t_mu + t_spike;
end



%kern    = [-1.022077e-002; -4.542572e-003; -2.225854e-002; -8.116035e-002; -1.263588e-001; -9.774068e-002; -1.582324e-001; -2.760360e-001; -5.181542e-001; -8.536977e-001; -1.000044e+000; -8.453697e-001; -7.141655e-001; -6.559451e-001; -6.200589e-001; -5.348860e-001; -4.931702e-001; -4.675804e-001; -4.266974e-001; -3.665843e-001; -3.462185e-001; -3.158591e-001; -2.748247e-001; -2.784587e-001; -2.640739e-001; -2.291720e-001; -2.233424e-001; -2.291720e-001; -1.913930e-001; -1.852606e-001; -1.883647e-001; -2.007053e-001; -1.762512e-001; -1.705730e-001; -1.670147e-001; -1.201506e-001; -1.375638e-001; -1.425606e-001; -1.045545e-001; -9.993625e-002; -1.269645e-001; -9.478802e-002; -8.116035e-002; -9.471230e-002; -8.441585e-002; -4.603125e-002; -5.965892e-002; -7.139385e-002; -3.830890e-002; -3.043514e-002; -6.223303e-002; -5.572204e-002; -3.793036e-002; -4.936246e-002; -4.777256e-002; -1.892733e-002; -1.900304e-002; -3.444773e-002; -1.279488e-002; -1.467692e-008; -2.945092e-002; -1.635322e-002; -3.179806e-003; -1.567183e-002];
kern    = [-1.582324e-001; -2.760360e-001; -5.181542e-001; -8.536977e-001; -1.000044e+000; -8.453697e-001; -7.141655e-001; -6.559451e-001; -6.200589e-001; -5.348860e-001; -4.931702e-001; -4.675804e-001; -4.266974e-001; -3.665843e-001; -3.462185e-001; -3.158591e-001; -2.748247e-001; -2.784587e-001; -2.640739e-001; -2.291720e-001; -2.233424e-001; -2.291720e-001; -1.913930e-001; -1.852606e-001; -1.883647e-001; -2.007053e-001; -1.762512e-001; -1.705730e-001; -1.670147e-001; -1.201506e-001; -1.375638e-001; -1.425606e-001; -1.045545e-001; -9.993625e-002; -1.269645e-001; -9.478802e-002; -8.116035e-002; -9.471230e-002; -8.441585e-002; -4.603125e-002; -5.965892e-002; -7.139385e-002; -3.830890e-002; -3.043514e-002; -6.223303e-002; -5.572204e-002; -3.793036e-002; -4.936246e-002; -4.777256e-002; -1.892733e-002; -1.900304e-002; -3.444773e-002; -1.279488e-002; -1.467692e-008; -2.945092e-002; -1.635322e-002; -3.179806e-003; -1.567183e-002];

tau_p   = 50;
tau_d   = 70;
expfun  = inline('b(1) .* exp(x ./ b(2))','b','x');
ltp_kern    = expfun([0.5 tau_p], (-30*Fs):Fs:0);
ltd_kern    = expfun([-0.5 -tau_d], 0:Fs:(30*Fs));

% static distributions
t       = normrnd(t_mu,t_sigma,n,1);
w       = rand(n,1);                          % equal weight to inputs
w_pre   = w;

% pre-induction period
Z       = zeros(m,length(time));
R       = Z;
for i = 1:m
    % generate trial distributions
    T           = normrnd(T_mu,T_sigma,n,1);
    P           = binornd(P_n,P_p,n,1);
    events      = ((t + T - min(time)) .* P);
    events      = round(events ./ Fs);      % bin # of event
    event_ind   = find(events);
    for k = 1:length(event_ind)
        j       = event_ind(k);                   % cell #
        tm      = events(j);
        Z(i,tm)  = Z(i,tm) + w(j);
    end
    r           = conv(Z(i,:),kern);
    R(i,:)      = r(1:length(time));
end

Z_pre   = Z;
R_pre   = R;

% induction period
Z       = zeros(m,length(time));
R       = Z;
t_s     = fix((t_spike - min(time))./Fs);
for i = 1:m_ind
    % generate trial distributions
    T           = normrnd(T_mu,T_sigma,n,1);
    P           = binornd(P_n,P_p,n,1);
    events      = ((t + T - min(time)) .* P);
    events      = fix(events ./ Fs);      % bin # of event
    event_ind   = find(events);
    for k = 1:length(event_ind)
        j       = event_ind(k);                   % cell #
        tm      = events(j);
        Z(i,tm)  = Z(i,tm) + w(j);
        % potentiate and depress
        dt      = tm - t_s;
        if dt > 0
            w(j)    = w(j) + w(j) * ltd_kern(dt);
        else
            w(j)    = w(j) + w(j) * ltp_kern(end+dt);
        end
    end
%     r           = conv(Z(i,:),kern);
%     R(i,:)      = r(1:length(time));
end

% post-induction period
Z       = zeros(m,length(time));
R       = Z;
for i = 1:m
    % generate trial distributions
    T           = normrnd(T_mu,T_sigma,n,1);
    P           = binornd(P_n,P_p,n,1);
    events      = ((t + T - min(time)) .* P);
    events      = fix(events ./ Fs);      % bin # of event
    event_ind   = find(events);
    for k = 1:length(event_ind)
        j       = event_ind(k);                   % cell #
        tm      = events(j);
        Z(i,tm)  = Z(i,tm) + w(j);
    end
    r           = conv(Z(i,:),kern);
    R(i,:)      = r(1:length(time));
end

Z_post  = Z;
R_post  = R;

dZ  = mean(Z_post',2) - mean(Z_pre',2);
dR  = -(mean(R_post',2) - mean(R_pre',2));
t   = (time - t_spike)';

if nargout > 0
    %return
end

figure
colormap(flipud(gray));
subplot(3,1,1)
imagesc(time,1:n,Z_pre);
vline(t_spike,'k:')
subplot(3,1,2)
% imagesc(time,1:n,Z_post);
plot(time,mean(Z_pre,1),'k');
hold on
plot(time,mean(Z_post,1),'r');
vline(t_spike,'k:')
% subplot(4,1,3)
% mtrialplot(time,R_pre');
subplot(3,1,3)
plot(time,mean(R_pre,1),'k');
hold on
plot(time,mean(R_post,1),'r');
vline(t_spike,'k:')

% rs  = Rasterify(R',2);
% rs  = -rs';
% subplot(5,1,4)
% imagesc(time,1:n,rs);
% subplot(5,1,5)
% plot(time,mean(rs,1));

% keyboard