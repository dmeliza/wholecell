function recursivedaq2mat
% a function which recurses through a directory structure and runs
% daq2mat in each directory

mydir = pwd;
d = dir;

for i = 1:length(d)
    if d(i).isdir
        n = d(i).name;
        switch(n)
        case {'.' '..'}
            % do nothing
        otherwise
            cd(d(i).name);
            recursivedaq2mat;
            cd(mydir);
        end
    end
end
try
    daq2mat;
catch
    disp(lasterr);
    %disp(['error processing ' d(i).name]);
end
