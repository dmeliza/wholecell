function WholeCell(varargin)
% The launching point for the wholecell application.  Initializes connections
% to DAQ hardware, etc, and sets up the WC control structure.
%
% $Id$

global wc

if nargin > 0
	action = lower(varargin{1});
else
	action = 'init';
end
switch action
    
case 'init'
    
    fixpath;
    InitWC;
    DAQControl('init');
    ProtocolControl('init');
    
case 'destroy'
    clear wc;
    daqreset;
    disp('Cleaned up WholeCell');
    
otherwise
    disp([action ' is not supported.']);
end

function fixpath()

warning off;
w = what(pwd);
if ~isempty(strmatch('wholecell.m',w.m))
    rmpath(pwd);
    rmpath([pwd filesep 'Utility']);
    rmpath([pwd filesep 'Analysis']);
    
    path(path,pwd);
    path(path,[pwd filesep 'Utility']);
    path(path,[pwd filesep 'Analysis']);
end
warning on;
