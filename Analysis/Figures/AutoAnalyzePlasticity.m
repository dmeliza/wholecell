function [] = AutoAnalyzePlasticity(fid)
% Part of the AutoAnalyze suite.  Analyzes an experiment in the framework
% of an attempt to induce plasticity, either on electrical or visual
% responses.  Called from a rat/cell directory.
%
% This function attempts to figure out some things about the experiment.  
% First, whether the experiment completed (need at least three subfolders).
% Second, if there are more than three folders, which ones should be used.
% Third, if DAQ2MAT has been run in those directories.  Once these have
% been determined, the script will run a subscript to measure the amplitude
% of the responses pre and post, and to determine the spike timing.
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
R0_SELECT       = '*.r0';
ANALYSIS_FN_RESP    = 'AutoAnalyzeResponse';
ANALYSIS_FN_SPIKE   = 'AutoAnalyzeSpikeTiming';
DAQ2MAT_MODE    = 'stack';
DAQ2MAT_CHAN    = 1;

% load subdirectories
start_dir   = pwd;
dd  = GetSubdirectories(FOLDER_SELECT);

len = length(dd);
fprintf(fid,'Subdirectories: %d', len)

if len < 3
    fprintf(fid,'\n(experiment ignored)\n');
    return
else
    fprintf(fid,'\n');
    if len > 3
        fprintf(fid,'(experiment ignored)\n');
        return
        % figure out which directories to use
    end
    % check each directory for .r0 files
    for i = 1:len
        d   = dir(fullfile(dd{i}, R0_SELECT));
        if isempty(d)
            cd(dd{i});
            daq2mat(DAQ2MAT_MODE, DAQ2MAT_CHAN);
            cd(start_dir);
        end
    end
end

% for visual data we need to figure out which bar is induced
seq_fn  = fullfile(dd{2}, 'sequence.txt');
d       = dir(seq_fn);
if length(d) == 1
    induction_sequence = load(seq_fn);
    induced = induction_sequence(1);
    if ~all(induction_sequence==induced)
        induced = -1;           % unknown
    end
else
    induced = 0;                % electrical
end

fprintf(fid, 'Pre: %s\n', dd{1});
fprintf(fid, 'Induced: %s', dd{2});
switch induced
    case -1
        fprintf(fid,' (unknown induction bar)\n')
    case 0
        fprintf(fid,' (electrical stimulus)\n')
    otherwise
        fprintf(fid,' (%d)\n', induced)
end
fprintf(fid, 'Post: %s\n', dd{3});
fprintf(fid, '----\n')
% run the analysis script, first in the pre/post directories, then in the
% induction directory
[pre, pst]   = feval(ANALYSIS_FN_RESP,dd{1},dd{3}, fid);
fprintf(fid, '----\n')
t_post       = feval(ANALYSIS_FN_SPIKE,dd{2}, fid);