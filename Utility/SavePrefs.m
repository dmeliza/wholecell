function varargout = SavePrefs(wc, varargin)
% stores control information in the wc structure in a mat file
% void SavePrefs(wc, [file]);
% wc - the wholecell structure
% file - the .mat file to store data in.  If no argument is supplied, a dialog is opened
%
% $Id$

data.control = wc.control;
data.ai = wc.ai;
data.ao = wc.ao;
if (nargin == 2)
    save(varargin{1}, 'data');
else
    [fn,pn] = uiputfile('wholecel.mat','Save preferences...');
    save([pn fn], 'data');
end