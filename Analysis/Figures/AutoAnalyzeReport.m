function [results] = AutoAnalyzeReport(fid)
% Part of the AutoAnalyze suite.  Reports the number of subdirectories in
% an experiment and how many files are in each directory.  A useful report
% for finding experiments that didn't fit into the standard pre/post
% plasticity paradigm.
%
% This mfile will attempt to load the local control file (auto.mat) but
% does not use any of the fields except for the comment
%   .ignore     - if 1, the whole directory is skipped
%   .comment    - a string that gets printed in the report
%   .dirs       - 3x1 array with the INDICES of the dirs to use
%   .t_pre      - Nx2 array of times specifying the onset and peak latency
%   .t_post     - as with t_pre, but for post-induction
%   .t_spike    - manually set the time of the spike
%   .induced    - the index of the bar used for spatial induction
%
% $Id$

% global parameters; empty if uninitialized
global WRITE_PARAMETERS WRITE_FIGURES WRITE_RESULTS

% determine where to write output
if nargin == 0
    fid = 1;        % write to standard out
end

% local parameters
FOLDER_SELECT   = '*';
LOCAL_CONTROL   = 'auto.mat';
DEBUG           = 0;

results         = [];

% load the control file, if there is one
if exist(LOCAL_CONTROL) ~= 0
    control     = load(LOCAL_CONTROL);
    fprintf(fid, '[%s] - loaded control file\n', LOCAL_CONTROL);
    if isfield(control,'comment')
        fprintf(fid,'[%s] - %s\n', LOCAL_CONTROL, control.comment);
    end
else
    control     = struct([]);
end

% load subdirectories
start_dir   = pwd;
dd  = GetSubdirectories(FOLDER_SELECT);

len = length(dd);
fprintf(fid,'Subdirectories: %d ', len);
% check the number of daq files in each dir
for i = 1:len
    n(i)    = length(dir(fullfile(dd{i},'*.daq')));
    fprintf(fid, '\n%s (%d)', dd{i}, n(i));
end
fprintf(fid, '\n');
