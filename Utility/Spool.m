function out = Spool(spoolname, action, arg1)
% a 1D data holder for the wholecell system.
% void Spool(spoolname,'init',[initialsize]) - initial size can be a matrix
% void Spool(spoolname,'append',data, [dim]) - data is appended columnwise
%                                       or along DIM
% void Spool(spoolname,'delete')
% data Spool(spoolname,'retrieve')
%
% $Id$
global wc

error(nargchk(2,4,nargin))
error(nargchk(0,1,nargout))

sf = sprintf('wc.%s.%s', mfilename, spoolname);
out = [];

switch lower(action)
    
case 'init'
    z = 0;
    if nargin == 3
        z = arg1;
    end
    eval([sf '.data = zeros(z);']);
    eval([sf '.offset = 1;']);
    
case 'append'
    o = eval([sf '.offset']);
    l = length(arg1);
    sfp = sprintf('%s.data(%d:%d) = arg1;', sf, o, o + l - 1);
    eval(sfp);
    sfp = sprintf('%s.offset = %d;', sf, o + l);
    eval(sfp);
    
case 'delete'
    eval([sf ' = []']);
    
case 'retrieve'
    out = eval([sf '.data']);

otherwise
    error('Please see help SPOOL for usage.');
    
end