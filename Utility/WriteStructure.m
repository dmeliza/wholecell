function WriteStructure(filename, structure)
% writes a structure to a mat file. The fields of the structure
% are stored individually in the file, so that the command
% str = load(filename) will reconstruct the structure
%
% $Id$
error(nargchk(2,2,nargin));
if ~isa(structure,'struct')
    error('Structure must be a structure array');
end
n = fieldnames(structure);
for i = 1:length(n)
    fn = n{i};
    sf = sprintf('%s = structure.%s;',fn,fn);
    eval(sf);
end
save(filename,n{:});
