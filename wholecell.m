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
    
    WholeCell('setpath');
    InitWC;
    DAQControl('init');
    ProtocolControl('init');
    
case 'destroy'
    clear wc;
    daqreset;
    disp('Cleaned up WholeCell');

case 'setpath'
    warning off;
    w = what(pwd);
    if ~isempty(strmatch('wholecell.m',w.m))
        rmpath(pwd);
        rmpath([pwd filesep 'Utility']);
        rmpath([pwd filesep 'Analysis']);
        
        path(path,pwd);
        path(path,[pwd filesep 'Utility']);
        path(path,[pwd filesep 'Analysis']);
        disp('Set up path for wholecell.');
    end
    warning on;
    
otherwise
    disp([action ' is not supported.']);
end


