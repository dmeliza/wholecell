function [] = AutoAnalyze(reportfilename)
%
% An script to automagically analyze all the pre-post plasticity data.
% The script will run in all the subdirectories of the current directory
% and generate a report.
%
% $Id$

% global parameters that control whether subsidiary modules will save data
% in their directories
global WRITE_PARAMETERS WRITE_FIGURES WRITE_RESULTS

WRITE_PARAMETERS = 0;    % if this is set, write .p0 files 
WRITE_FIGURES    = 1;    % if this is set, write .fig files
WRITE_RESULTS    = 0;    % if this is set, write .mat files

% local parameters
RAT_SELECT  = '*';
CELL_SELECT = 'cell*';
ANALYSIS_FN = 'AutoAnalyzePlasticity';

% open the output file if supplied
if nargin > 0
    fid = fopen(reportfilename,'wt');       % existing files will be overwritten
    if fid == -1
        error('Unable to open file for writing!');
    end
else
    fid = 1;
end

% cycle through all the primary directories
rootdir = pwd;
dd1     = GetSubdirectories(RAT_SELECT);

fprintf(fid,'AutoAnalyze.m $Revision$\n');
fprintf(fid,'Begin analysis run in %s at %s\n', rootdir, datestr(now));

try
    for i = 1:length(dd1)
        ratdir  = dd1{i};
        cd(rootdir);
        cd(ratdir);
        dd2 = GetSubdirectories(CELL_SELECT);
        
        % cycle through all the cell directories in each rat dir
        for j = 1:length(dd2)
            celdir  = dd2{j};
            cd(celdir);
            fprintf(fid, '-----------------------------');
            fprintf(fid, '\nCell: %s/%s\n', ratdir, celdir);
            feval(ANALYSIS_FN, fid);
            cd(fullfile(rootdir,ratdir));
        end
    end
    
catch
    close(fid)
    error(lasterr)
end