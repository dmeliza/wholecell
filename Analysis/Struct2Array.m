function arr = Struct2Array(struct, field, option)
%
% StructtoArray converts, as much as is possible, the data in a field of a structure 
% array to a well-structured array.  This can be done by clipping all the repeats
% to the same length as the shortest repeat, padding the short repeats to the longest,
% or discarding the shorter repeats.
%
% Usage: arr = StructtoArray(struct, field, option)
%
% struct    - A structure array (not much point in using a 1x1 structure, is there?)
% field     - The field to extract (string)
% option    - can be 'clip','pad', or 'drop'
% 
% array     - an MxNxP array representing the field element in the structure
%
%
% $Id$
%
error(nargchk(3,3,nargin))

sf        = sprintf('{struct.%s}',field);
d         = eval(sf);
len       = cellfun('length',d);
[len i j] = unique(len);

% the no-brainer case
if length(len) == 1
    sf  = sprintf('[struct.%s]',field);
    arr = eval(sf);
else
    switch lower(option)
    case 'clip'
        len     = min(len);
        arr     = zeros(len,length(j));
%         
%         arr     = eval(sf);
        for i = 1:length(j)
            sf       = sprintf('struct(%d).%s(1:len)',i,field);
            arr(:,i) = eval(sf);
        end
              
    case 'pad'
        len     = max(len);
        arr     = zeros(len, length(j));
        for i = 1:length(j)
            len          = length(d(i));
            arr(1:len,i) = d(i);
        end
    case 'drop'
        ind     = find(j==1);
        sf      = sprintf('struct(ind).%s',field);
        arr     = eval(sf);
    otherwise
        error('Option must be ''clip'', ''pad'', or ''drop''');
    end
end
    