function varargout = InitWC()
% initializes the wc structures with common control information
%
% $Id$
global wc;

wc = [];
% wc = struct([]);
% wc(1).control = struct([]);
% wc.control(1).telegraph = struct([]);
% wc.control.telegraph(1).gain = [];
wc.control.telegraph.mode = [];
wc.control.telegraph.gain = [];
wc.control.amplifier = [];
wc.control.base_dir = pwd;
wc.control.data_dir = pwd;
wc.control.data_prefix = [];