function varargout = ProtocolControl(varargin)
% ProtocolControl is the GUI module used to load and execute protocols (which
% are just mfiles)
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
    
    OpenGuideFigure(me);
    
case 'data_dir_callback'
    if exist(wc.control.data_dir,'dir') == 7
        cd(wc.control.data_dir);
    end
    pn = uigetdir;
    if (pn ~= 0)
        wc.control.data_dir = pn;
        set(wc.ai,'LogFileName',NextDataFile);
    end
    cd(wc.control.base_dir);

case 'data_prefix_callback'
    def = wc.control.data_prefix;
    if isempty(def) | ~ischar(def)
        def = '';
    end
    a = inputdlg('Enter a prefix for subsequent data files','Data Prefix',...
        1,{def});
    if ~isempty(a)
        wc.control.data_prefix = a{1};
    end
    
case 'seal_test_callback'
    SealTest('init');
    
case 'start_scope_callback'
    GapFree('start');
    
case 'start_record_callback'
    if (isempty(wc.control.protocol))
        GapFree('record');
    else
        feval(wc.control.protocol,'record')
    end
    
case 'stop_callback'
    if (isempty(wc.control.protocol))
        StopAcquisition(me,[wc.ai wc.ao]);
    else
        feval(wc.control.protocol,'stop')
    end

case 'start_protocol_callback'
    func = wc.control.protocol;
    if (isempty(func))
        pnfn = GetUIParam(me,'protocolStatus','String');
        [a func] = fileparts(pnfn);
    end
    if (exist(func) > 0)
        feval(func,'start');
    else
        WholeCell('load_protocol_callback');
    end
    
case 'load_protocol_callback'
    [fn pn] = uigetfile('*.m', 'Pick an M-file');
    if (isstr(fn))
        SetUIParam(me,'protocolStatus','String',[pn fn]);
        [a func] = fileparts(fn);
        wc.control.protocol = func;
        feval(func, 'init'); % this assumes the file is the current directory
    end
    
case 'reinit_protocol_callback'
    func = GetParam(me,'protocol');
    feval(func, 'reinit');
    
case 'close_callback'
    DeleteFigure(me);
    
otherwise
    disp([action ' is not supported.']);
end

% local functions

function out = me()
out = mfilename;