function [] = HandMap(display)
%
% Function for hand-mapping receptive fields.  Allows the user to move a bar of
% variable size and angle around the screen.  Doesn't attempt to acquire any data
% (calling cgmouse and cgkeymap constantly will probably fubar the daq engine)
%
% INPUT - 
%    display - the number of the display to use, or 0 for a sub-window (default)
%
% While the display is active, the following keys will have the following effect:
%    left arrow/right arrow - narrow/widen the bar by 10 pixels
%    up arrow/down arrow    - lengthen/shorten the bar by 10 pixels
%    </>                    - rotate the bar CCW/CW by 10 degrees
%    esc                    - close display
%
% $Id$

if nargin < 1
    display = 0;
end

cgloadlib
cgopen(1,8,0,display)
cgpencol(1,1,1)
cgfont('Courier',10)
gsd = cggetdata('gsd');
ScrWid = gsd.ScreenWidth;
ScrHgh = gsd.ScreenHeight;
ScrDep = gsd.ScreenBits;

angle   = 0;                              % start with a vertical bar
length  = 100;
width   = 20;
c       = 1;                              % state variable
makesprite(length, width, angle, ScrDep); % initialize the first sprite
step    = 2;
dots    = [];                             % click locations

while c
    % first draw the sprite
    [x,y,bs,bp]  = cgmouse;
    if bs
        dots = cat(1,dots,[x y]);
    end
    drawDots(dots)
    cgpencol(1,1,1)
    drawInstructions(-ScrWid/2, ScrHgh/2 - 40);
    cgalign('c','c')
    cgdrawsprite(1,x,y)
    str = sprintf('HandMap %s  Pos: [%d, %d]  Size: [%d, %d]  Angle: [%d]',...
                  '$Revision$', x, y, length, width, angle);
    cgtext(str, 0, ScrHgh/2 -5)
    cgflip(0,0,0)
    % now check the keyboard
    ks           = cgkeymap;
    if any(ks)
        if ks(52)
            angle    = hmrot(angle,-step);
        elseif ks(51)
            angle    = hmrot(angle, step);
        elseif ks(75)
            width    = hmdim(width, -step);
        elseif ks(77)
            width    = hmdim(width, step);
        elseif ks(80)
            length   = hmdim(length, -step);
        elseif ks(72)
            length   = hmdim(length, step);
        elseif ks(46)
            dots     = [];
        elseif ks(1)
            c        = 0;
        end
        makesprite(length,width,angle,ScrDep)
        cgkeymap
    end
end

cgshut

function a  = hmrot(angle, a)
a = angle + a;
if a < 0
    a = 180 + a;
elseif a >= 180
    a = a - 180;
end

function d  = hmdim(d, w)
d = d + w;
if d < 0
    d = 0;
end

function [] = drawInstructions(x,y)
instr = {'Instructions:',...
         ' (rt)  = widen',...
         ' (lft) = narrow',...
         ' (up)  = lengthen',...
         ' (dn)  = shorten',...
         '  >    = rotate CW',...
         '  <    = rotate CCW',...
         '  c    = clear marks',...
         '  ESC  = exit'};
step = -11;
cgalign('l','t')
for i = 1:length(instr)
     cgtext(instr{i}, x, y);
     y = y + step;
end

function [] = drawDots(dots)
% draws cute little red dots at all the supplied locations (Nx2 array)
[rows cols] = size(dots);
if cols == 2
    cgpencol(1,0,0)
    for i = 1:rows
        cgellipse(dots(i,1),dots(i,2),5,5)
    end
end

function [] = makesprite(length, width, angle, bpp)
% generates the sprite for the bar and loads it into video memory
% angle is [0,180)
Z     = MakeBar(length, width, angle);
[r c] = size(Z);
if all([r c])
    cmap  = gray(2);
    cgloadarray(1,r,c,reshape(Z,1,r*c),cmap);
    if bpp == 8
        cgtrncol(1,0)
    else
        cgtrncol(1,'n')
    end
end

