function [] = CGDisplay(varargin)
%
% This function is responsible for initializing and maintaining a display
% using the CogGph toolkit.  It has its own parameter window, which is
% used to control display parameters (screen location in particular). It's
% not a true toolkit because modules are expected to directly access the
% CogGph toolkit themselves to load and display stimuli.  However, they can
% get user preferences and toolkit parameters from this module.
%
% USAGE: [] = CGDisplay(action)
%
% where action can be 'init', which opens the display and parameter windows
% and 'reinit', which re-initializes the display
%
%
% $Id$

if nargin > 0
	action = lower(varargin{1});
else
	action = lower(get(gcbo,'tag'));
end

switch action
    
case 'init'
    p   = defaultParams;
    p   = initDisplay(p);
    fig = ParamFigure(me, p);
    
case 'reinit'
    p   = GetParam(me);
    p   = initDisplay(p);
    fig = ParamFigure(me,p);
    
otherwise
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function out = me()
out = mfilename;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\
function param = initDisplay(param)
cgloadlib;       % error checking needed here for missing toolkit
cgshut;
cgopen(1,8,0,2); % opens a 640x480x8 display on the second monitor by default
gpd                 = cggetdata('gpd');
param.v_res.value   = gpd.RefRate100 / 100;
param.d_res.value   = sprintf('%d x %d x %d', gpd.PixWidth, gpd.PixHeight, gpd.BitDepth);
csd                 = cggetdata('csd');
param.toolkit.value = csd.CogStdString;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\
function p = defaultParams;

f_s = {'description','fieldtype','value'};
f = {'description','fieldtype','value','units'};
p.theta     = cell2struct({'Rotate:','value',0,'deg'},f,2);     % not trivial to implement
p.width     = cell2struct({'Width:','value',640,'px'},f,2);
p.height    = cell2struct({'Height:','value',480,'px'},f,2);
p.cent_y    = cell2struct({'Y:','value',0,'px'},f,2);
p.cent_x    = cell2struct({'X:','value',0,'px'},f,2);

p.d_res     = cell2struct({'Res:', 'fixed',''},f_s,2);
p.v_res     = cell2struct({'Refresh:','fixed',''},f_s,2);
p.toolkit   = cell2struct({'Toolkit:','fixed',''},f_s,2);