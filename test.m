% % test daq function by sending a test pulse
% 
% daqreset;
% ai = analoginput('nidaq');
% set(ai,'InputType','SingleEnded');
% ao = analogoutput('nidaq');
% addchannel(ai,[0 1 2]);
% addchannel(ao, 0);
% 
% set(ai.Channel(3),'InputRange',[-10 10]);
% set(ai.Channel(3),'SensorRange',[-10 10]);
% set(ai.Channel(3),'UnitsRange',[-10 10]);
% 
% set([ai ao], 'TriggerType', 'Manual');
% set(ai, 'ManualTriggerHwOn', 'Trigger');
% 
% pulse = zeros(1000,1);
% pulse(200:500,:) = 1;
% 
% putdata(ao, pulse);
% start([ai ao]);
% trigger([ai ao]);
% [data, time] = getdata(ai);
% plot(time, data);
% 
% start([ai ao]);
% trigger([ai ao]);
% [data, time] = getdata(ai);
% plot(time, data);

% try to send a TTL pulse on DAC1OUT

daqreset;
ao = analogoutput('nidaq');
addchannel(ao,1);
set(ao, 'TriggerType', 'Manual');
set(ao, 'RepeatOutput', 1);

pulse = zeros(1000,1);
pulse(1:500,:) = 10;
putdata(ao,pulse);
start(ao);
trigger(ao);