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

% types   = [exist(pre) exist(post)];
% if all(types==7)
%     [A,t,u] = loadFiles(pre);
%     B       = loadFiles(post);
%     a       = combineEpisodes(A);
%     b       = combineEpisodes(B);
% else
%     A   = load(pre);
%     B   = load(post);
%     win     = SPATIALRF_WIN(1):SPATIALRF_WIN(2);
%     t   = double(A.time(win,:)) * 1000 - 200;
%     a   = double(A.data(win,:));
%     b   = double(B.data(win,:));
%     u   = A.units;
% end
% 
% Fs  = mean(diff(t));
% abase   = mean(mean(a(1:200,:)));
% bbase   = mean(mean(b(1:200,:)));
% a   = a - abase;
% b   = b - bbase;
% 
% if nargin > 3
%     i       = find(peak <= t);
%     i       = i(1);
% elseif nargin > 2
%     [mx i]  = max(abs(b(:,induction)));
%     fprintf('Max at %d, %3.2f ms\n', induction, t(i));    
% else
%     [mx i]  = max(abs(b));
%     [mx j]  = max(mx);
%     i       = i(j);
%     fprintf('Max at %d, %3.2f ms\n', j, t(i));
% end
% 
% w       = fix(RFWIN/Fs);
% I       = (-w:w) + i;
% arf     = a(I,:);
% brf     = b(I,:);
% 
% 
% pre_rf     = mean(arf,1);
% post_rf    = mean(brf,1);
% switch lower(u)
%     case {'pa','na'}
%         pre_rf = -pre_rf;
%         post_rf = -post_rf;
% end
% 
% 
% % compute error bars
% if iscell(A)
% %     [pre_SD, pre_sem, pre_err]       = computeError(A,I,abase);
% %     [post_SD, post_sem, post_err]    = computeError(B,I,bbase);
% %     [precm,precm_err]                = centroid(pre_rf, pre_err);
% %     [postcm,postcm_err]              = centroid(post_rf, post_err);
%     pre_values                          = computeValues(A,I,abase);
%     post_values                         = computeValues(B,I,bbase);
% %    [precm,precm_err]                  = centroid
%     keyboard
%     fprintf('%3.2f +/- %3.2f (pre); %3.2f +/- %3.2f (post)\n',...
%         precm, precm_err, postcm, postcm_err)
% else
%     precm   = centroid(pre_rf);
%     postcm  = centroid(post_rf);
%     fprintf('%3.2f (pre); %3.2f (post)\n',...
%         precm, postcm)
% end


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
% if iscell(A)
%     p(1:2) = errorbar(X,pre_rf, pre_err, 'k');
%     p(3:4) = errorbar(X,pst_rf, post_err, 'r');
% else
%     p       = plot(X,pre_rf,'k',X,post_rf,'r');
% end
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

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function [d,t,u] = loadFiles(directory)
% global SPATIALRF_WIN
% win     = SPATIALRF_WIN(1):SPATIALRF_WIN(2);
% wd      = cd(directory);
% dd      = dir('*.r0');
% fls     = {dd.name};
% for i = 1:length(fls)
%     [pn fn ext] = fileparts(fls{i});
%     seqfile     = fullfile(pn,[fn '.txt']);
%     r0          = load('-mat',fls{i});
%     D           = double(r0.r0.data(win,:,1));
%     if exist(seqfile)
%         S       = load('-ascii',seqfile);
%         d{i}    = D(:,S,:);
%     else
%         d{i}    = D;
%     end
% end
% t       = double(r0.r0.time(win,:)) * 1000 - 200;
% u       = r0.r0.y_unit{1};
% cd(wd)
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function m  = combineEpisodes(in)
% % turns a cell array into a double array by averaging along dim 2
% for i = 1:length(in)
%     m(:,i)  = mean(in{i},2);
% end
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
% function [tc] = computeValues(in, win, base)
% % computes the 95% Cl of the mean value in the window
% for i = 1:length(in)
%     d       = in{i};
%     d       = d(win,:) - base;
%     tc{i}   = mean(d,1);                    % time course of mean
% %     tval    = tinv(0.975,length(tc)-1);
% %     SD(i)   = std(tc);
% %     SEM(i)  = SD(i) / sqrt(length(tc));
% %     CL(i)   = SEM(i) * tval;
% end
    
