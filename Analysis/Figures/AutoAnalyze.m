function [] = AutoAnalyze(reportfilename, controlfile)
%
% An script to automagically analyze all the pre-post plasticity data.
% The script will run in all the subdirectories of the current directory
% and generate a report.
%
% [] = AutoAnalyze([reportfilename], [controlfile])
%
% controlfile is an xls file. The first column contains paths that will
% restrict the operation of this script to those paths.
%
% $Id$

% global parameters that control whether subsidiary modules will save data
% in their directories
global WRITE_PARAMETERS WRITE_FIGURES WRITE_RESULTS SKIP_COMPLETED

WRITE_PARAMETERS = 1;    % if this is set, write .p0 files 
WRITE_FIGURES    = 1;    % if this is set, write .fig files
WRITE_RESULTS    = 1;    % if this is set, write .mat files
SKIP_COMPLETED   = 0;    % if set, ignore directories with .fig files in them

error(nargchk(0,2,nargin))
if nargin < 2
    controlfile = [];
end
if nargin < 1
    reportfilename = [];
end
    

% local parameters
RAT_SELECT  = '*';
CELL_SELECT = 'cell*';
ANALYSIS_FN = 'AutoAnalyzePlasticity';

% open the output file if supplied
if ~isempty(reportfilename)
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
results = [];

fprintf(fid,'AutoAnalyze.m $Revision$\n');
fprintf(fid,'Begin analysis run in %s at %s\n', rootdir, datestr(now));

try
    % if there's a control file we do things completely differently (ughs)
    if ~isempty(controlfile)
        fprintf(fid,'Using control file %s\n',controlfile);
        [ct_data, ct_files]   = xlsread(controlfile);
        % need to reconstruct the rat and cell dirs
        % this is HIGHLY contingent on the structure of the string, so at
        % present it's only guaranteed to work if you're using the
        % control-RF.xls files where the paths are relative to the current
        % directory
        for i = 1:size(ct_files,1)
            fullpth         = fileparts(ct_files{i,1});     % strip out 'pre.mat'
            [pth,celdir]    = fileparts(fullpth);
            [pth,ratdir]    = fileparts(pth);
            cd(fullpth);
            fprintf(fid, '-----------------------------');
            fprintf(fid, '\nCell: %s/%s\n', ratdir, celdir);
            results         = analyze_directory(fid, ANALYSIS_FN, results, ratdir,...
                celdir, WRITE_RESULTS);
            cd(rootdir);
        end
    else
        % by default, we cycle through all the rat directories in the
        % rootdir, and then in each rat directory, cycle through all the
        % cell directories.
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
                    results = analyze_directory(fid, ANALYSIS_FN, results, ratdir,...
                        celdir, WRITE_RESULTS);
                end
                cd(fullfile(rootdir,ratdir));
            end
        end
    end
    cd(rootdir)
    % write the results to disk
    if WRITE_RESULTS
        resfile  = writeresults(rootdir, reportfilename, results);
        fprintf(fid, 'Wrote results to %s\n', resfile);
    end
    fprintf(fid,'Analysis run completed at %s\n', datestr(now));
    if fid > 1
        fclose(fid)
    end
    
    
catch
    if WRITE_RESULTS
        resfile  = writeresults(rootdir, reportfilename, results);
        fprintf(fid, 'Wrote results to %s\n', resfile);
        fprintf(fid,'Analysis run terminated with errors at %s\n', datestr(now));
    end
    if fid > 1
        fclose(fid)
    end
    error(lasterr)
end

function results = analyze_directory(fid, ANALYSIS_FN, results, ratdir, celdir, WRITE_RESULTS)
try
    if WRITE_RESULTS
        % try to put all the results in a single structure,
        % although this may break the bank memorywise
        Z             = feval(ANALYSIS_FN, fid);
        if ~isempty(Z)
            Z.rat  = ratdir;
            Z.cell = celdir;
            len    = length(results);
            if len == 0
                results         = Z;
            else
                results(len+1)  = Z;
            end
        end
    else
        feval(ANALYSIS_FN, fid);
    end
catch
    fprintf(fid,'Error: %s\n',lasterr);
end


function [matfile] = writeresults(rootdir, reportfilename, results)
[pn fn ext]     = fileparts(reportfilename);
matfile         = fullfile(rootdir,[fn '.mat']);
save(matfile, 'results');