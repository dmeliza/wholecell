function [stim, str] = LoadStimulusFile(filename)
%
% This function is a wrapper that will attempt to load a stimulus from a .mat file
% In addition to returning the stimulus, it returns a string description of the
% stimulus which can be useful in scripts and GUIs.  It catches all errors, in which
% case stim is empty and str is the error.
%
% Usage: [stim, str] = LoadStimulusFile(filename)
%
% filename - path or filename of stimulus file
% 
% stim     - the stimulus structure (empty in errors)
% str      - a string describing the stimulus properties (or the error)
%
% See Also:     headers/stim_struct.m
%
% $Id$

error(nargchk(1,1,nargin));
stim = [];
err = [];
% Check Existence of File
if exist(filename,'file') == 0
    err = 'File does not exist';
end

% Load File
try
    stim = load('-mat',filename);
catch
    err = 'File is not a MAT file';
end

% Load Required Parameters
[pn fn ext] = fileparts(filename);
try
    switch lower(ext)
    case '.s0'
        stimulus = getfield(stim,'stimulus');
        [X Y T] = size(stimulus);
        colmap = getfield(stim,'colmap');
        str = sprintf('s0: %d frames\n%d x %d x %d\n',T, X, Y, size(colmap,1));
    case '.s1'
        param   = getfield(stim,'param');
        xres    = getfield(stim,'x_res');
        yres    = getfield(stim,'y_res');
        mfile   = getfield(stim,'mfile');
        static  = getfield(stim,'static');
        colmap  = getfield(stim,'colmap');
        count   = size(unique(param,'rows'),1);
        str     = sprintf('s1: %d frames\n%d x %d x %d\n %d inst %d params\n',...
                          size(param,1),xres,yres,size(colmap,1),count,size(param,2));
    otherwise
        err     = 'Unknown stimulus type';
    end
catch
    err  = 'File lacks proper structure';
end

if ~isempty(err)
    stim = [];
    str  = err;
    return
end

% Load Optional Parameters
if strcmpi(ext,'.s0') & isfield(stim,'parameters')
    params = getfield(stim,'parameters');
    count = size(unique(params,'rows'),1);
    str = sprintf('%s%d params\n',str,count);
    str = str(1:end-1);
end