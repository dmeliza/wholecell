function [m,i] = RandomSample(pop,fraction)
% Returns a random sample of a population.
% [m,i] = RandomSample(population, fraction)
% population - the population to be sampled from. If this is a scalar,
%              m is a subpopulation of the integers from 1 to population
%              (m==i)
% fraction - the (approximate) fraction of points to be returned
% m - the subpopulation
% i - the indices of the the subpopulation in the population
%
% $Id$

error(nargchk(2,2,nargin))

if length(pop)==1
    Z = rand(pop,1);
else
    Z = rand(size(pop));
end

i = find(Z <= fraction);

if length(pop)==1
    m = i;
else
    m = pop(i);
end
    
    