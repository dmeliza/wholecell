function Scope(varargin)
% The Scope is a general purpose figure used to display stuff.
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

    fig = OpenGuideFigure(me);
    zoom(fig,'on');
    
case 'xshrink_callback'
    xlim = GetUIParam(me,'scope','XLim');
    SetUIParam(me,'scope','XLim',[xlim(1) xlim(2) * 1.2]);

case 'xstretch_callback'
    xlim = GetUIParam(me,'scope','XLim');
    SetUIParam(me,'scope','XLim',[xlim(1) xlim(2) * .8]);
    
case 'yshrink_callback'
    xlim = GetUIParam(me,'scope','YLim');
    SetUIParam(me,'scope','YLim',[xlim(1) *1.2, xlim(2) * 1.2]);
    
case 'ystretch_callback'
    xlim = GetUIParam(me,'scope','YLim');
    SetUIParam(me,'scope','YLim',[xlim(1) * .8, xlim(2) * .8]);
    
    
case 'close_callback'
    disp('Stopping protocol');
    ProtocolControl('stop_callback');
    pause(1)
    DeleteFigure(me);
    
otherwise
    disp([action ' is not supported.']);
end

%%%%%%%%%%%%%functions
function out = me()
out = mfilename;


% --------------------------------------------------------------------
function varargout = xslider_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.xslider.
disp('xslider Callback not implemented yet.')


% --------------------------------------------------------------------
function varargout = slider2_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.slider2.
disp('slider2 Callback not implemented yet.')