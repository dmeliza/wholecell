function [pre_rf, pst_rf, pre_cm, pst_cm] = CompareSpatialRF(pre, post, induction, peak)
%
% Generates a figure comparing two spatial RFs (either two cells or
% before/after).
%
% [pre_rf, post_rf] = SPATIALRF(pre, post, [induction], peak, start_time, end_time)
%
% pre and post must be directories.  All the daqdata-?.r0 files will be loaded, 
% and the individual trials used to determine the error in the RF and in
% the center of mass measurement.
%
%
% $Id$
SZ      = [3.0 3.0];
X       = [-47.25 -33.75 -20.25 -6.75];

[pre_rf, pre_cm, pre_rf_err, pre_cm_err]    = SpatialRF(pre, peak);
[pst_rf, pst_cm, pst_rf_err, pst_cm_err]    = SpatialRF(post, peak);

if pre_cm_err(1)==pre_cm
    fprintf('%s: %3.2f to %3.2f\n', pre, pre_cm, pst_cm);
else
    if (all(pst_cm_err > pre_cm) | all(pst_cm_err < pre_cm))
        sig = '*';
    else
        sig = 'ns';
    end
    fprintf('%s: %3.2f [%3.2f %3.2f] to %3.2f [%3.2f %3.2f] (%s)\n',...
        pre, pre_cm, pre_cm_err(1), pre_cm_err(2),...
        pst_cm, pst_cm_err(1), pst_cm_err(2), sig);
end


if nargout > 0
    return
end
    

f       = figure;
set(f,'color',[1 1 1],'name',pre);
ResizeFigure(f,SZ);
hold on

if isempty(X)
    X       = 1:length(pre_rf);
else
    pre_cm   = interp1(1:length(X),X,pre_cm);
    pst_cm  = interp1(1:length(X),X,pst_cm);
end

pre_rf_err  = diff(pre_rf_err) ./ 2;
pst_rf_err  = diff(pst_rf_err) ./ 2;
p(1:2) = errorbar(X,pre_rf, pre_rf_err,'k');
p(3:4) = errorbar(X,pst_rf, pst_rf_err,'r');

vline(pre_cm,'k:');
vline(pst_cm,'r:');
set(p,'LineWidth',2);

Xd  = mean(diff(X));
%set(gca,'XTick',X, 'XLim', [X(1) - 0.2 * Xd, X(4) + 0.2 * Xd],'Box','On')
set(gca,'XLim', [X(1) - 0.2 * Xd, X(4) + 0.2 * Xd],'Box','On')
xlabel('Bar Position (degrees)')
ylabel('Response (pA)')
%title(pre)
if nargin > 2
    hold on
    ylim    = get(gca,'YLim');
    mx  = max([pre_rf(induction) pst_rf(induction)]);
    h   = plot(X(induction), mx * 1.4, 'kv');
    set(h,'MarkerFaceColor',[0 0 0])
end
