function out = centroid(varargin)
% Computes the center of mass of a one-parameter receptive field.
%
% out    = centroid(RF)
%
% If RF is a single argument, each element is the mean response at each
% position; if it is a list of arguments, then each argument corresponds to
% a position and the elements of the argument correspond to individual
% observations, in which case the centroid and mean will be computed from
% the mean of these observations.
%
% For vector RF, OUT is a single value (the centroid).  For list RFs, OUT
% is a vector with the following values: [centroid; rf(:)]
%
% $Id$

if nargin > 1
    for i = 1:nargin
        rf(i)   = mean(mean(varargin{i}));
    end
else
    rf      = varargin{1};
end

rfa = rf - min(rf);
a   = sum(rfa);
b   = sum(rfa .* (1:length(rfa)));
cm  = b/a;
if nargin > 1
    out = [cm; rf(:)];
else
    out = cm;
end
%rf  = rf(:);
% if nargin > 1
%     a_e = sqrt(sum(rf_err.^2));
%     b_e = sqrt(sum((rf_err .* (1:length(rf))).^2));
%     x_e = (a_e/a)^2 + (b_e/b)^2;
%     x_err   = sqrt(x_e) * x;
% else
%     x_err   = 0;
% end

% if iscell(rf)
% %    fun     = @my_centroid;
%     fun     = @test;
%     NBOOT   = 100;
%     cm      = bootstrp(NBOOT,fun,rf{1});
%     keyboard
% else        
%     rf  = rf - min(rf);
%     a   = sum(rf);
%     b   = sum(rf .* (1:length(rf)));
%     x   = b/a;
%     if nargin > 1
%         a_e = sqrt(sum(rf_err.^2));
%         b_e = sqrt(sum((rf_err .* (1:length(rf))).^2));
%         x_e = (a_e/a)^2 + (b_e/b)^2;
%         x_err   = sqrt(x_e) * x;
%     else
%         x_err   = 0;
%     end
% end
% 
% function [cm] = my_centroid(X)
% % actually computes the centroid from an n-sample set
%     
% 
% function [cm] = bs_centroid(varargin)
% % bootstrappable function for computing the centroid
% d   = [varargin{:}];
% a   = sum(d);
% b   = sum(d .* 1:length(d));
% cm  = b/a;
