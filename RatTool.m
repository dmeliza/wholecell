function varargout = RatTool(varargin)
% RatTool does date and dosage calculations
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
    SetUIParam(me, 'date','String',datestr(now - 20,'dd-mmm-yyyy'));
    
case 'weight_callback'
    
    wt = str2num(GetUIParam(me, 'weight', 'String'));
    bup = wt * .1 / 60;
    nem = wt * .060 / 20;
    ketxyl = wt * .0015;
    SetUIParam(me, 'buprenorphine', 'String', sprintf('%1.3f',bup));
    SetUIParam(me, 'nembutal', 'String', sprintf('%1.3f',nem));
    SetUIParam(me, 'cocktail', 'String', sprintf('%1.3f',ketxyl));
    
case 'close_callback'
    delete(gcbf);
end

function out = me()
out = mfilename;
