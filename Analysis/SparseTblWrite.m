function string = SparseTblWrite(data, varnames, casenames, filename, delimiter)
% Like tblwrite, generates a table of delimited values, but using
% a sparse array as input
%
% s = SparseTblWrite(data, varnames, casenames, filename, delimiter)
% $Id$

error(nargchk(5,5,nargin))

fid = fopen(filename,'w');
data = squeeze(data); % eliminate empty dimensions
[nrows, ncols] = size(data);
if ~isempty(casenames)
    [ncasenames, maxl] = size(casenames);   
    if isempty(varnames)
        d = '';
    else
        d = delimiter;
    end
    for i = 1:ncasenames
        fprintf(fid,'%s%s', d, casenames(:,i));
        d = delimiter;
    end
    fprintf(fid,'\n');
end
if ~isempty(varnames)
    [nvarnames, maxl] = size(varnames);
    for i = 1:nvarnames
        fprintf(fid,'%g%s%s\n', varnames(i), delimiter,...
            delimitedstring(data(i,:), delimiter));
    end
else
    for i = 1:nrows
        fprintf(fid,'%s\n', delimitedstring(data(i,:), delimiter));
    end
end
fclose(fid);


function s = delimitedstring(data, delimiter)
% transforms a one-dimensional sparse array into a delimited string
d = '';
s = '';
if isa(data,'sparse')
    ind = find(data); % defined values
else
    ind = find(data~=NaN);
end
for i = 1:length(data)
    if find(ind==i)
        s = sprintf('%s%s%g', s, d, data(i));
    else
        s = sprintf('%s%s',s,d);
    end
    d = delimiter;
end
        
            