function [p, h]     = DunnettTest(stats, control, alpha)
% DUNNETTTEST Computes P values comparing experimental means with a control
% mean using Dunnett's Test
%
% [P, H] =      DUNNETTTEST(STATS, CONTROL, ALPHA)
%
% - STATS is the structure returned by ANOVA1, ANOVA2, etc
% - CONTROL is the group to use as a control (default 1)
% - ALPHA has a default value of 0.05 and determines the confidence level
%
% - P is a column vector containing the P values comparing the experimental
%   group to the control group
% - H is 0 or 1, depending on whether the P value rejects the null
%   hypothesis
%
% Formula for Dunnett's Test from
% http://davidmlane.com/hyperstat/B112114.html where:
%
% T(i)  = (mean(i) - mean(control))/sqrt(2 * MSE / nh)
% (where nh is the harmonic mean of n(i) and n(control))
%
% $Id$

ALPHA    = 0.05;

error(nargchk(1,3,nargin));

if nargin < 2
    control = [];
end
if nargin < 3
    alpha   = [];
end
if isempty(control)
    control = 1;
end
if isempty(alpha)
    alpha   = ALPHA;
end
    
n_groups    = length(stats.n);
if control > n_groups | control < 1
    error(sprintf('Control group index must be between 1 and %d',n_groups));
end

n_control   = stats.n(control);
m_control   = stats.means(control);
mse         = power(stats.s,2);

for i = 1:n_groups
    if i == control
        t(i)    = 0;
    else
        nh      = harmmean([n_control stats.n(i)]);
        t(i)    = (stats.means(i) - m_control) / sqrt(2 * mse / nh);
    end
end
p = 1 - tcdf(t, stats.df);
h = p < alpha;