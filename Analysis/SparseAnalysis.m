function out = SparseAnalysis(window)
% This function is basically a script that automates analyzing
% responses to sparse noise data.  It reads in the daq files,
% adjusts units, frame-shifts the data, and uses Parameterize
% to determine the average response of the cell to each
% stimulus location.
%
% Some day it will be a gui.
%
% Usage: h1_est = SparseAnalysis(window)
%
% window - the window, in ms, to analyze.  Smaller windows save memory, etc.
%
% $Id$

error(nargchk(1,1,nargin))

% load stimulus and reduce parameters to a single vector
if exist('stim.mat','file') > 0
    d = load('stim.mat');
else
    error('Stimulus file (stim.mat) could not be found');
end
% stimulus-param mappings and the parameter vector
[stimulus param params] = unique(d.parameters,'rows'); % all the unique combinations of values
stimulus = binarystimulus(stimulus);
ind_on = find(stimulus(:,3));
ind_off = find(stimulus(:,3)==0);
stimulus = d.stimulus(:,:,param);                      % 2D arrays for each stimulus
% param_on = param(find(stimulus(:,3)));
% param_off = param(find(stimulus(:,3)==0));
% stimulus_on = d.stimulus(:,:,param_on); 
% stimulus_off = d.stimulus(:,:,param_off);
clear('d')

% load response and sync data
if exist('daqdata-sparse.mat','file') > 0
    d = load('daqdata-sparse.mat');
    data = d.data;
    disp('Response loaded from daqdata-sparse.mat');
else
    % assumes sync data is in channel 4 (could get this from the timing files?)
    data = daq2mat('indiv',[1 4]);
    save('daqdata-sparse.mat','data');
    disp('Wrote daqdata-sparse.mat');
end
clear('d')

% loop through each of the sweeps
S = warning('off');
for i = 1:length(data)
    fprintf('Sweep %d: ', i);
    resp = double(data(i).data(:,1));
    sync = double(data(i).data(:,2));
    w = window;

    % convert continuous sync data into timing indices
    sq = zeros(size(sync));
    on = find(sync > sync(1));
    sq(on) = 1;                     % square wave representing on and off states
    timing = find(diff(sq));       % timing of transitions between on and off
    clear('sync','sq');
    
    % frame shift response
    fprintf('Conditioning response... ');
    Fs = data(i).info.t_rate;
    w = w * Fs / 1000;
    R = FrameShift(resp,timing,w);
    clear('resp','timing');
    
    % parameterize response
    fprintf('Parameterizing response...\n');
    len = size(R,1);
    k(:,:,i) = Parameterize(params(1:len),R);
    clear('R');
end
warning(S);
out.h1_est = mean(k,3);
%save('results.mat','k');

% generate STRF
fprintf('Computing STRF...\n');
stimulus = permute(stimulus,[3 1 2]);
[out.strf_on, out.strf_off] = Param2STRF(out.h1_est,stimulus,ind_on,ind_off);
WriteStructure('results.mat',out);

function stim = binarystimulus(stim)
% fixes the z values in the Nx3 array to be 1 and 0
mx = max(stim(:,3));
mn = min(stim(:,3));
stim(:,3) = (stim(:,3) - mn) / (mx - mn);