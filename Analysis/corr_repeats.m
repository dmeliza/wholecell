function [] = corr_repeats(data, frate)

%  CORR_REPEATS derive correlations between repeated responses to a single stimulus
%
%    [] = corr_repeats(response, [frate])
%
%     Computes the correlation between all repeats in the response array 
%     The correlations are between all repeats and between each repeats and the
%     exclusive mean.
%
%    INPUTS
%     data   - array of responses (NxM, M responses)
%     frate  - the frame rate of the response, as multiples of the stimulus frame rate
%              Used to figure out how many lags to include
%
%    OUTPUTS
%     []      - none at present time
%
%    SEE ALSO
%
%    EXAMPLE
%     >> corr_repeats(response);
%
%    Adapted from Jon Touryan
%
%   $Id$

error(nargchk(1,2,nargin))

%%% Initialize Constants %%% 
if nargin < 2
    frate = 1;
end
LAGS = 25 * frate;


[FRAMES REPEATS] = size(data);                  % Size of response

% Initialize results vectors
C       = zeros([LAGS*2+1, REPEATS, REPEATS]);
stats   = zeros([3, REPEATS, REPEATS]);

% Make response zero-mean
data    = data - repmat(mean(data,1),FRAMES,1);

fprintf('Calculating correlations...');
for i = 1:REPEATS
   
   % Calculate Exclusive Mean to current repeat
   others   = setdiff(1:REPEATS, i);
   x_mean   = mean(data(:,others), 2);

   % Calculate the ex mean xcorr and store results in C (this will be the diagonal) 
   C(:,i,i)       = xcorr(x_mean, data(:,i), LAGS, 'coeff');
   t              = corrcoef(x_mean, data(:,i));
   stats(1,i,i)   = t(2,1);
   
   % Calculate the stats for the shuffled spikes
   t              = ShuffleSequence(data(:,i), 100);      % shuffle the response
   t              = xcorr(x_mean, t, LAGS, 'coeff');      % xcorr
   stats(2,i,i)   = mean(t);
   stats(3,i,i)   = std(t);

   % Calculate all other xcorrs and store them in Graphs
   for j = 1:(i-1)
      
      % Calculate the xcorr between current spike files
      C(:,j,i)     = xcorr(data(:,j), data(:,i), LAGS, 'coeff');
      t            = corrcoef(data(:,j), data(:,i));
      stats(1,j,i) = t(2,1);
   
   	  % Calculate the stats for the shuffeled spikes
   	  t            = ShuffleSequence(data(:,j), 100);      % shuffle the response
   	  t            = xcorr(data(:,i), t, LAGS, 'coeff');   % xcorr
      stats(2,j,i) = mean(t);
      stats(3,j,i) = std(t);
      
   end
   
   % Calculate the autocorrelation of the mean response
   x_mean          = mean(data, 2);
   C(:,REPEATS,1)  = xcorr(x_mean, x_mean, LAGS, 'coeff');
   
end
fprintf('Graphing Results...\n')
clear data

%%%%% PLOT RESULTS %%%%%%%
findfig('xcorr_repeats');
set(gcf,'Position',[300 300 800 600],'Color',[1 1 1],'Name','xcorr repeats',...
    'NumberTitle','off');
clf

TOP = 0.5;
BOTTOM = -0.02;
x_values = -LAGS:LAGS;

% Graph the correlation coefficients subtracted by the mean of 
%  a shuffled correlation. Make the graphs look pretty....
for i = 1:REPEATS
   
   % Graph the Diagonal, Correlation with Exclusive Mean
   subplot(REPEATS, REPEATS, (i+REPEATS*(i-1)))
   bar(x_values,(C(:,i,i) - stats(2,i,i)),'c')
   hold on
   significant = stats(3,i,i)*2.33;		% P = 0.01 
   plot(x_values,significant*ones(length(x_values),1),'k:')
   plot([0 0],[0 TOP],'k-')
   ylabel(num2str(stats(1,i,i)));
   axis([-LAGS LAGS BOTTOM TOP])
   set(gca,'FontSize',8)
   set(gca,'XTick',[0],'YTick',[])
   
   for j = 1:(i-1)
      
      % Graph above the Diagonal, Correlation Between repeats
      subplot(REPEATS, REPEATS,(i+REPEATS*(j-1)))
   	  bar(x_values,(C(:,j,i) - stats(2,j,i)),'c')
      hold on
      significant = stats(3,j,i)*2.33;	% P = 0.01 
      plot(x_values,significant*ones(length(x_values),1),'k:')
   	  plot([0 0],[0 TOP],'k-')
   	  ylabel(num2str(stats(1,j,i)));
   	  axis([-LAGS LAGS BOTTOM TOP])
   	  set(gca,'FontSize',8)
      set(gca,'XTick',[0],'YTick',[])
      
   end
        
end

% Graph the mean autocorrelation function in the bottom left corner
subplot(REPEATS,REPEATS,REPEATS*(REPEATS-1)+1)
bar(x_values,C(:,REPEATS,1),'b')
axis('tight')
set(gca,'FontSize',8)
set(gca,'XTick',[0],'YTick',[])
title('Autocorr');

drawnow
