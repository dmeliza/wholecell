function recursivedaq2mat
% a function which recurses through a directory structure and runs
% daq2mat in each directory

mydir = pwd;
d = dir;

for i = 1:length(d)
    if d(i).isdir
        cd(d(i).name);
        daq2mat;
        cd(mydir);
    end
end
daq2mat;
        