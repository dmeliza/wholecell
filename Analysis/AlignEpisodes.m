function [data,time] = AlignEpisodes(data, time, window)
% realigns timing of episodes based on the peak of the
% stimulus artifact.  This can be necessary if the nidaq drivers
% get a little bit behind on their timing and some episodes
% start sooner or later than the average.  At present each episode's
% mark is defined as the fastest positive-going event (calculated by
% looking for the maximum of the first derivative of the trace).
%
% Multiple signal data matrices are supported, in which case the second
% signal is used to align the first.
%
% $Id$

num_traces = size(data,2);
len_traces = size(data,1);
num_signals = size(data,3);

% find mark; if multiple signals are present the derivative of the 2nd one is used
if num_signals > 1
    data_p = diff(data(window,:,2),1,1);
else
    data_p = diff(data(window,:),1,1);
end

%data_p = diff(data,1,1); % derivatives along each column
%[m_p i_p] = max(abs(data_p),[],1); % find indices of maximum
[m_p i_p] = max(data_p,[],1);

% this code will break if we try to access values we don't have
% a more robust (but slower) algorhythm would go through each line
% 1 at a time or throw out traces that don't comply

% matrix method - memory intensive and pretty darn slow

% i = i_p - min(i_p);  % turn i_p into offset values
% m = max(i_p); % use this to avoid going over
% t = 1:(len_traces-m);
% [x y] = meshgrid(i,t);
% i = x+y;
% 
% % remap i to extract values from orig_data
% o = 0:len_traces:len_traces*(num_traces-1);
% o = repmat(o,length(t),1);
% i = i + o;
% 
% % for j = 1:size(orig_data,2)
% %     data(:,j) = orig_data(i(:,j),j);
% % end
% 
% data = orig_data(i);

% loop method (rewrite in c?)

orig_data = data;
i = i_p - min(i_p) + 1;
m = max(i);
len_data = len_traces - m;
data = zeros(len_data + 1,num_traces);
for j = 1:num_traces
    offset = i(j);
    data(:,j) = orig_data(offset:offset + len_data,j);
end

time = time(1:length(data)) - time(min(i_p) + window(1));
