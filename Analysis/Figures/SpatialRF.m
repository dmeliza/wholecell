function [rf, cm, rf_err, cm_err] = SpatialRF(files, peak)
%
% Computes the spatial portion of a receptive field. Basically this
% consists of the amplitude of the EPSCs for each position, measured at the
% time of the peak amplitude (of the strongest response).  The user needs
% to determine this time by hand, as it's somewhat troublesome to do
% algorithmically.
%
% [rf, cm, rf_err, cm_err] = SPATIALRF(files, peak)
%
% FILES can be a .mat file or a directory.  If a single file, it should
% contain at least a .time and .data field.  The data field should be a
% MxN matrix, where N is the number of spatial positions.  If a directory,
% all the .r0 files in the directory will be loaded (along with the .txt
% files that indicate which traces to use).  In the latter case, the
% individual trials will be used in a nonparametric bootstrap to determine
% the 95% confidence limits of the output variables.
%
% RF is a 1xN vector, of which CM is the center of mass.  RF_ERR and
% CM_ERR, if applicable, are 2xN and 2x1 vectors defining the 95%
% confidence levels of RF and CM.
%
% The spatial RF is defined as the average of the 20 ms on either side of
% the maximum response.
%
% $Id$
global SPATIALRF_WIN RFWIN
SPATIALRF_WIN     = [1000 6000];      % analysis window
SZ      = [3.0 3.0];
RFWIN   = 20;
NBOOT   = 1000;
CI      = [2.5  97.5];      % confidence interval
X       = [-47.25 -33.75 -20.25 -6.75];
%X       = [];

type    = exist(files);
if type==2
    A   = load(files);
    win = SPATIALRF_WIN(1):SPATIALRF_WIN(2);
    t   = double(A.time(win,:)) * 1000 - 200;
    a   = double(A.data(win,:));
    u   = A.units;
    rf  = computeAmplitude(t,u,peak,a);
    rfcm  = Centroid(rf);
    cm  = rfcm(1);
    rf_err  = [rf;rf];
    cm_err  = [cm;cm];
else
    [d,t,u]     = loadFiles(files);
    rf          = computeAmplitude(t,u,peak,d);
    % nonparametric bootstrap, split rf into columns first
    for i= 1:size(rf,1);
        RF{i}   = rf(i,:);
    end
    [cmrf] = bootstrp(NBOOT,'Centroid',RF{:});
    cm  = mean(cmrf(:,1));
    rf  = mean(cmrf(:,2:end),1);
    e   = prctile(cmrf,CI);
    cm_err  = e(:,1);
    rf_err  = e(:,2:end);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function rf = computeAmplitude(t,u,peak,a)
global RFWIN
Fs  = mean(diff(t));
i       = find(peak <= t);
i       = i(1); 
w       = fix(RFWIN/Fs);
I       = (-w:w) + i;
%abase   = mean(mean(a(1:200,:,:),1),3);
abase   = mean(a(1:200,:,:),1);
a       = a - repmat(abase,[size(a,1), 1, 1]);
arf     = a(I,:,:);
rf      = squeeze(mean(arf,1));
switch lower(u)
    case {'pa','na'}
        rf = -rf;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [d,t,u] = loadFiles(directory)
global SPATIALRF_WIN
win     = SPATIALRF_WIN(1):SPATIALRF_WIN(2);
wd      = cd(directory);
dd      = dir('*.r0');
fls     = {dd.name};
for i = 1:length(fls)
    [pn fn ext] = fileparts(fls{i});
    seqfile     = fullfile(pn,[fn '.txt']);
    r0          = load('-mat',fls{i});
    D           = double(r0.r0.data(win,:,1));
    if exist(seqfile)
        S       = load('-ascii',seqfile);
        dc{i}    = D(:,S,:);
    else
        dc{i}    = D;
    end
end
lens    = cellfun('size',dc,2);
[m,i]   = min(lens);
for i   = 1:length(dc)
    d(:,:,i)    = [dc{i}(:,1:m)];
end
d       = permute(d,[1 3 2]);
t       = double(r0.r0.time(win,:)) * 1000 - 200;
u       = r0.r0.y_unit{1};
cd(wd)
