function varargout = wholecell(varargin)
% WHOLECELL Application M-file for wholecell.fig
%    FIG = WHOLECELL launch wholecell GUI.
%    WHOLECELL('callback_name', ...) invoke the named callback.

% Last Modified by GUIDE v2.0 10-Mar-2003 12:49:01

if nargin == 0  % LAUNCH GUI

	fig = openfig(mfilename,'reuse');

	% Generate a structure of handles to pass to callbacks, and store it. 
	handles = guihandles(fig);
	guidata(fig, handles);
    initializeFigure(fig, handles);
    
	if nargout > 0
		varargout{1} = fig;
	end

elseif ischar(varargin{1}) % INVOKE NAMED SUBFUNCTION OR CALLBACK

%	try
		[varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
        %	catch
		%disp(lasterr);
        %end

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

% --------------------------------------------------------------------
function varargout = initializeFigure(h, handles, varargin)
% Initializes the figure for the first time.
% find out what hardware we have
daqinfo = daqhwinfo;
set(handles.digitizerMenu, 'String', daqinfo.InstalledAdaptors)
% let the user know what the status is
%set(handles.daqStatus, 'String', 'Digitizer uninitialized.')
set(handles.channels, 'String', 'Digitizer Uninitialized...');
set(handles.channels, 'Enable', 'Off');

% --------------------------------------------------------------------
function varargout = daqInitialize_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.pushbutton1.
% Clean up existing controller or make one if there is none
if (isfield(handles, 'controller'))
    delete(handles.controller);
end
% find out which digitizer the user wants
digitizers = get(handles.digitizerMenu, 'String');
choice = digitizers{get(handles.digitizerMenu,'Value')};
% start up the controller with dummy values
% TODO: add dialog to set some of this crap
daqconfig.SampleRate = 8000;
newcontroller = controller(choice, daqconfig);
handles.controller = newcontroller;
updateDisplay(handles);
guidata(gcbo,handles);

%---
function updateDisplay(handles)
% Updates fields in the GUI with information in hidden objects, e.g. the controller
if (isfield(handles,'controller'))
    c = handles.controller;
    set(handles.txtDevice,'String',get(c,'DeviceName'));
    set(handles.txtAdaptor,'String',get(c,'AdaptorName'));
    set(handles.txtCoupling,'String',get(c,'Coupling'));
    set(handles.txtSampling,'String',get(c,'SamplingRate'));
    set(handles.txtChannels,'String',get(c,'TotalChannels'));
    set(handles.txtStatus,'String',get(c,'Status'));
    % generate a list of channels
    channels = getChannelList(c);
    if (isempty(channels))
        set(handles.channels,'String',{'No Channels'});
        set(handles.channels,'Enable','Inactive');
    else
        set(handles.channels,'String',channels);
        set(handles.channels,'Enable','On');
    end
end
    

% --------------------------------------------------------------------
function varargout = btnAI_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.ai.
% Allows the user to create an analog input channel on the digitizer


% --------------------------------------------------------------------
function varargout = ao_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.ao.
disp('ao Callback not implemented yet.')


% --------------------------------------------------------------------
function varargout = dio_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.dio.
disp('dio Callback not implemented yet.')


% --------------------------------------------------------------------
function varargout = msg_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.msg.
disp('msg Callback not implemented yet.')




% --------------------------------------------------------------------
function varargout = channels_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.channels.
disp('channels Callback not implemented yet.')


% --------------------------------------------------------------------
function varargout = txtDevice_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.txtDevice.
disp('txtDevice Callback not implemented yet.')


% --------------------------------------------------------------------
function varargout = txtAdaptor_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.txtAdaptor.
disp('txtAdaptor Callback not implemented yet.')


% --------------------------------------------------------------------
function varargout = txtCoupling_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.txtCoupling.
disp('txtCoupling Callback not implemented yet.')


% --------------------------------------------------------------------
function varargout = txtSampling_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.txtSampling.
disp('txtSampling Callback not implemented yet.')


% --------------------------------------------------------------------
function varargout = txtChannels_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.txtChannels.
disp('txtChannels Callback not implemented yet.')


% --------------------------------------------------------------------
function varargout = txtStatus_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.txtStatus.
disp('txtStatus Callback not implemented yet.')

% --------------------------------------------------------------------
function varargout = digitizerMenu_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.digitizerMenu.
% choosing a digitizer does nothing


