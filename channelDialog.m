function varargout = channelDialog(callbackfn, callbackparams, channeldata, varargin)
% CHANNELDIALOG Application M-file for channelDialog.fig
%    FIG = CHANNELDIALOG launch channelDialog GUI.
%    CHANNELDIALOG('callback_name', ...) invoke the named callback.

% Last Modified by GUIDE v2.0 10-Mar-2003 13:51:01
% $Id$
%
% The Channel Dialogbox is used to create new analog input/output channels
% and to edit properties of existing channels.  Called with a function handle
% and a channel description structure which has the following fields:
%
% .name - the name of the channel
% .hwch - the hardware id of the channel
% .availableChannels - the available hardware id's
% .Units - the units of the hardware connected to this channel
% .ScalingFactor

if nargin < 3  % insufficient parameters
    
    disp('Usage: channelDialog(callbackfn, callbackparams, channeldata, varargin)');
    return;
end

if nargin == 2  % LAUNCH GUI

	fig = openfig(mfilename,'reuse');

	% Use system color scheme for figure:
	set(fig,'Color',get(0,'defaultUicontrolBackgroundColor'));

	% Generate a structure of handles to pass to callbacks, and store it. 
	handles = guihandles(fig);
    handles.callbackfn = callbackfn;
    handles.callbackparams = callbackparams;
    handles.channeldata = channeldata;
	guidata(fig, handles);
    initializefigure(handles);

	% Wait for callbacks to run and window to be dismissed:
	uiwait(fig);

	if nargout > 0
		varargout{1} = fig;
	end

elseif ischar(varargin{1}) % INVOKE NAMED SUBFUNCTION OR CALLBACK

	try
		[varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
	catch
		disp(lasterr);
	end

end


%| ABOUT CALLBACKS:
%| GUIDE automatically appends subfunction prototypes to this file, and 
%| sets objects' callback properties to call them through the FEVAL 
%| switchyard above. This comment describes that mechanism.
%|
%| Each callback subfunction declaration has the following form:
%| <SUBFUNCTION_NAME>(H, EVENTDATA, HANDLES, VARARGIN)
%|
%| The subfunction name is composed using the object's Tag and the 
%| callback type separated by '_', e.g. 'slider2_Callback',
%| 'figure1_CloseRequestFcn', 'axis1_ButtondownFcn'.
%|
%| H is the callback object's handle (obtained using GCBO).
%|
%| EVENTDATA is empty, but reserved for future use.
%|
%| HANDLES is a structure containing handles of components in GUI using
%| tags as fieldnames, e.g. handles.figure1, handles.slider2. This
%| structure is created at GUI startup using GUIHANDLES and stored in
%| the figure's application data using GUIDATA. A copy of the structure
%| is passed to each callback.  You can store additional information in
%| this structure at GUI startup, and you can change the structure
%| during callbacks.  Call guidata(h, handles) after changing your
%| copy to replace the stored original so that subsequent callbacks see
%| the updates. Type "help guihandles" and "help guidata" for more
%| information.
%|
%| VARARGIN contains any extra arguments you have passed to the
%| callback. Specify the extra arguments by editing the callback
%| property in the inspector. By default, GUIDE sets the property to:
%| <MFILENAME>('<SUBFUNCTION_NAME>', gcbo, [], guidata(gcbo))
%| Add any extra arguments after the last argument, before the final
%| closing parenthesis.

function varargout = initializeFigure(handles)
% initializes the figure with lovely values, or blanks if there are none
chd = handles.channeldata;
if (~isfield(handles.channeldata,'NewChannel'))
    set(handles.txtName,'String',chd.name); 
    set(handles.txtUnits,'String',chd.Units);
    set(handles.txtScaling,'String',num2str(chd.ScalingFactor));
    set(handles.txtScalingUnits,'String', [chd.Units '/ V']);
    set(handles.popupChannels,'String',chd.availableChannels);
    set(handles.popupChannels,'Value',chd.hwch);
end

% --------------------------------------------------------------------
function varargout = txtName_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.txtName.
% does ntohing

% --------------------------------------------------------------------
function varargout = txtUnits_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.txtUnits.
set(handles.txtScalingUnits,'String',[get(handles.txtUnits,'String') '/ V']);

% --------------------------------------------------------------------
function varargout = txtScaling_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.txtScaling.
% does ntohing


% --------------------------------------------------------------------
function varargout = popupChannel_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.popupChannel.
% does ntohing


% --------------------------------------------------------------------
function varargout = btnOK_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.btnOK.
close;
feval(handles.callbackfn, handles.callbackparams{:}, handles.channeldata)


% --------------------------------------------------------------------
function varargout = btnCancel_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.btnCancel.
close;