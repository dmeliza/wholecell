
function d = LoadPrefs(varargin)
% loads control information from a mat file
% data = LoadPrefs([file])
% if [file] is not supplied, the function opens a UI getfile dialog
global wc;

if (nargin == 0)
    [fn pn] = uigetfile;
    d = load([pn fn]);
else
    fn = varargin{1};
    d = load(fn);
end
wc.control = d.data.control;
wc.ai = d.data.ai;
wc.ao = d.data.ao;
if (isfield(wc.control,'data_dir'))
    set(wc.ai,'LogFileName',NextDataFile);
end
