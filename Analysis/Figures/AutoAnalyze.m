function [] = AutoAnalyze(reportfilename)
%
% An script to automagically analyze all the pre-post plasticity data.
% The script will run in all the subdirectories of the current directory
% and generate a report.
%
% $Id$

% global parameters that control whether subsidiary modules will save data
% in their directories
global WRITE_PARAMETERS WRITE_FIGURES WRITE_RESULTS SKIP_COMPLETED

WRITE_PARAMETERS = 0;    % if this is set, write .p0 files 
WRITE_FIGURES    = 1;    % if this is set, write .fig files
WRITE_RESULTS    = 1;    % if this is set, write .mat files
SKIP_COMPLETED   = 0;    % if set, ignore directories with .fig files in them

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
    reportfilename  = 'report.txt';
end

% cycle through all the primary directories
rootdir = pwd;
dd1     = GetSubdirectories(RAT_SELECT);

fprintf(fid,'AutoAnalyze.m $Revision$\n');
fprintf(fid,'Begin analysis run in %s at %s\n', rootdir, datestr(now));

expt   = 1;
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
            nfigs = length(dir('*.fig'));
            if SKIP_COMPLETED & nfigs > 0
                fprintf(fid, '(already analyzed)\n');
            else
                try
                    if WRITE_RESULTS
                        % try to put all the results in a single structure,
                        % although this may break the bank memorywise
                        Z             = feval(ANALYSIS_FN, fid);
                        if ~isempty(Z)
                            Z.rat  = ratdir;
                            Z.cell = celdir;
                            results(expt)      = Z;
                            expt          = expt + 1;
                        end
                    else
                        feval(ANALYSIS_FN, fid);
                    end
                catch
                    fprintf(fid,'Error: %s\n',lasterr);
                end
            end
            cd(fullfile(rootdir,ratdir));
        end
    end
    cd(rootdir)
    % write the results to disk
    if WRITE_RESULTS
        resfile  = writeresults(rootdir, reportfilename, results);
        fprintf(fid, 'Wrote results to %s', resfile);
    end
    
catch
    if WRITE_RESULTS
        resfile  = writeresults(rootdir, reportfilename, results);
        fprintf(fid, 'Wrote results to %s', resfile);
    end
    fclose(fid)
    error(lasterr)
end

function [matfile] = writeresults(rootdir, reportfilename, results)
[pn fn ext]     = fileparts(reportfilename);
matfile         = fullfile(rootdir,[fn '.mat']);
save(matfile, 'results');