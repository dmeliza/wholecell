function varargout = TelegraphSetup(action,linename)
% TELEGRAPHSETUP Application M-file for TelegraphSetup.fig
%    TELEGRAPHSETUP(action,lineName) invoke the named callback.
%   
%   Currently the only supported action is 'init'
%
%   This function sets up telegraphing.  Telegraphs work by storing
%   information about the telegraph channel in the wc.control object,
%   which is then used by the SweepAcquired function to scale the data
%   and apply the correct units.
%
%   Telegraphs for the axoclamp 200B
% 
%   Gain:
%    0.5 - 2 V
%   1   - 2.5 V
%   etc (0.5 V steps)
%   500 - 6.5 V
% 
%   Mode:
%   Track - 4 V
%   VClamp - 6 V
%   I=0    - 3 V
%   IClamp - 2 V
%   Fast Ic - 1 V
%
% $Id$

error(nargchk(2,2,nargin))

global wc

switch lower(action)

case 'init'
    c = GetParam('control.telegraph', linename);   
    p = defaultParams(linename, c);
    clfcn = @close_callback;
    fig = OpenParamFigure(me, p, clfcn);
    uiwait(fig);
    
otherwise

end


% private functions
function out = me()
out = mfilename;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function p = defaultParams(linename, channel);
global wc;
f_l = {'description','fieldtype','value','choices'};
f_s = {'description','fieldtype','value'};

if (~isempty(channel))
    currentchannel = wc.ai.Channel(channel).HwChannel;
    availableChannels = [setdiff(wc.control.ai.channels, wc.control.ai.usedChannels)];
    channels = cellstr(char(num2str(currentchannel),num2str(availableChannels')));
else
    currentchannel = 1;
    availableChannels = setdiff(wc.control.ai.channels, wc.control.ai.usedChannels);
    channels = cellstr(char(' ',num2str(availableChannels')));
end

p.channel = cell2struct({'Channel','list',1,channels},f_l,2);
p.linename = cell2struct({'Line','fixed',linename},f_s,2);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function close_callback(varargin)
% save the info in a param
r = GetParam(me,'channel');
choice = r.value;
l = GetParam(me,'linename','value');
f_s = {'description','fieldtype','value'};
s = cell2struct({l,'value',choice},f_s,2);
% when the user presses OK this module opens the channel
% or if it already exists, reconfigures it
if (isempty(choice))
    % do nothing
else
    makeTelegraph(choice);
end
InitParam('control.telegraph',l,s);
uiresume;
DeleteFigure(me);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function c = makeTelegraph(channelName)
global wc
channelHW = str2num(channelName);
linename = GetParam(me,'linename','value');
c = GetParam('control.telegraph', linename,'value');
if (~isempty(c))
    currentchannel = wc.ai.Channel(str2num(c));
    c = ReassignChannel(currentchannel, channelHW);
else
    c = CreateChannel(wc.ai, channelHW);
end
% set up the channel
set(c, 'ChannelName', [linename ' telegraph']);
range = [-10 10];
set(c, {'InputRange','SensorRange','UnitsRange'}, {range, range, range});
