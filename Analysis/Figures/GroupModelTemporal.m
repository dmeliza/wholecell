function [] = GroupModelTemporal()
%
% Runs ModelTemporal() on several different timings to create a composite
% timing window
%
% $Id$

dt  = unidrnd(100,30,1) - 50;

for i = 1:length(dt)
    [dZ(:,i),dR(:,i),tt(:,i)]   = ModelTemporal(dt(i));
end

[dR,t] = AlignTimes(dR,tt,150);
[dZ,t] = AlignTimes(dZ,tt,150);

figure
subplot(2,1,1)
plot(t,dR);
subplot(2,1,2)
plot(t,mean(dZ,2));

keyboard