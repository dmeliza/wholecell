function [x, y, pw, ph] = CGDisplay_Position()
%
% An accessory function that looks up the position values for
% placing an image from the CGDisplay module
%
% Usage: [x y pw ph] = CGDisplay_Position()
%
% $Id$
gpd = cggetdata('gpd');
mod = 'cgdisplay';
PW  = gpd.PixWidth;
PH  = gpd.PixHeight;
x   = fix(GetParam(mod,'cent_x','value'));
y   = fix(GetParam(mod,'cent_y','value'));
pw  = fix(GetParam(mod,'width','value'));
ph  = fix(GetParam(mod,'height','value'));
rot = fix(GetParam(mod,'theta','value')); %  can't do anything with this here, really
if pw < 1
    pw = PW;
end
if ph < 1
    ph = PH;
end