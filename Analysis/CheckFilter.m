function R = CheckFilter(stimulus, response, filter, t_res)
% checks the accuracy of the predicted response for various lengths of the
% filter
%
% $Id$
l = length(filter);
R = zeros(l,1);
s = 'Calculating filter profile';
h = waitbar(0,[s '(0/' num2str(l) ')']);
for i = 1:l
    pred = conv(stimulus, filter(1:i));
    %R(i) = lms(pred(1:length(response)), response);
    c = corrcoef(pred(1:length(response)), response);
    R(i) = c(2);
    if ishandle(h)
        waitbar(i/l,h,sprintf('%s (%d/%d)', s, i, l));
    else
        return;
    end
end
close(h);
if nargout == 1
    return;
end

% plot if no return value is asked for
if nargin == 4
    t = 0:t_res:(l-1)*t_res;
    figure,plot(t,R)
    s = 'Filter delay (ms)';
else
    figure,plot(R);
    s = 'Filter delay (samples)';
end
ylabel('R');
xlabel(s);
[y i] = max(R);
text(i*t_res,y,sprintf('  R(max) = %f', y));

function R = rms(prediction, response)
% root mean square error of equal length vectors
err = prediction - response;
var = power(err, 2);
R = sqrt(mean(var));