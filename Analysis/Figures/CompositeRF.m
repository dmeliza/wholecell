function rf = compositeRF(data)
%
% RF = COMPOSITERF(data)
%
% produces a composite temporal/spatial RF from multiple data sets.
% Each data set should have a center point (e.g. the induction location)
% results are combined and averaged for center, 1-off, 2-off etc.
%
% DATA - structure array of input data.  'difference' field contains IxJ arrays
%        and 'x_induce' field contains scalars indicating the center of each RF
%
% RF   - output is an NxM array - N is time, and M is equal to the number of unique
%        spatial locations

%D   = sparse([]);
for i = 1:length(data)
    diff = data(i).difference - mean(mean(data(i).difference)); % zero-mean
    cent = data(i).x_induce;
    for j = 1:size(diff,2)
        offset = abs(cent - j) + 1;               % relative distance to center
        d      = diff(:,j);% - mean(diff(:,j)); % zero-mean
        D(:,offset,i,j)    = diff(:,j);       % high dimensional sparse array
    end
end
D   = mean(D,4);
D   = squeeze(mean(D,3));
T   = data(1).time - mean(data(1).time);
rf  = struct('rf',D,'time',T);

if nargout == 0
    figure
    mx  = max(max(abs(D)));
    n   = 1:size(D,2);
    imagesc(T * 1000,n-1,D',[-mx mx]);
    set(gca,'YTick',n-1);
    xlabel('Time (ms)');
    ylabel('Spatial position');
    colormap(redblue(0.4,200))
    colorbar
end
