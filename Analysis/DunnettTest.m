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

switch lower(stats.source)
    case 'anova1'
        n_groups    = length(stats.n);
        if control > n_groups | control < 1
            error(sprintf('Control group index must be between 1 and %d',n_groups));
        end
        
        n_exp       = stats.n;
        n_control   = n_exp(control);
        m_exp       = stats.means;
        m_control   = m_exp(control);
        mse         = power(stats.s,2);
        df          = prod([n_groups n_control]) - n_groups;
    case 'anova2'
        % assume here that we're using columns
        n_groups    = stats.rown;
        if control > n_groups | control < 1
            error(sprintf('Control group index must be between 1 and %d',n_groups));
        end
        n_exp       = repmat(stats.coln,[1 n_groups]);
        n_control   = n_exp(control);
        m_exp       = stats.colmeans;
        m_control   = m_exp(control);
        mse         = stats.sigmasq;
        df          = prod([n_groups n_control]) - n_groups;
end

for i = 1:n_groups
    if i == control
        t(i)    = 0;
    else
        nh      = harmmean([n_control n_exp(i)]);
        t(i)    = (m_exp(i) - m_control) / sqrt(2 * mse / nh);
    end
end
% this is not the right density function
p = tpdf(t, stats.df);
h = p < alpha;