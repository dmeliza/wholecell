function [Z] = AutoSelect(matfile, output)
%
% AutoSelect runs on the matfile output of AutoAnalyze, which is a giant
% structure containing all the relevant data from the analysis of the
% experiments.  What this mfile does is apply a series of criteria to the
% elements of the structure and return the pre/post plasticity of those
% cells that meet the criteria.
%
% $Id$

% here are the criteria.  If empty, the criterion is ignored.
% general
ELECTRICAL      = 0;        % use electrical induction cells
VISUAL          = 1;        % use visual induction cells
CURRENTCLAMP    = 0;        % use current clamp cells
% pre-induction (baseline)
BASELINE_LENGTH = 5;        % minutes, minimum
BASELINE_SLOPE  = 0.1;      % maximum slope, as a fraction of the size of the event
% post-induction
POST_LENGTH     = 15;       % minutes, minimum (rounded)
POST_IR         = 0.3;      % fraction of baseline IR that post IR is allowed to deviate
POST_SR         = [];       % like POST_IR

% other analysis parameters
POST_INTERVAL   = [5 15];   % minutes, time over which analysis is made
RESPONSE_TYPE   = 'ampl';   % the fieldname containing the response ('ampl' or 'slope')
PRE_SPIKE_TIME  = 'peak';  % use onset or peak for calculating spike time
MATFILE_STRUC   = 'results';

% okay, here goes:

% load the main structure array
z   = load(matfile);
Z   = z.(MATFILE_STRUC);
clear z;

% do the easy filtering:
sel     = ones(size(Z));
iselec  = [Z.stim_electrical];
iscclam = [Z.mode_currentclamp];
if ~isempty(ELECTRICAL)
    if ~ELECTRICAL
        sel = sel & ~iselec;
    end
end
if ~isempty(VISUAL)
    if ~VISUAL
        sel = sel & iselec;
    end
end
if ~isempty(CURRENTCLAMP)
    if ~CURRENTCLAMP
        sel = sel & ~iscclam;
    end
end
Z   = Z(sel);

% now for things that have to be analyzed one by one
sel = ones(size(Z));
for i = 1:length(sel)
    % select the stimulus parameter to analyze:
    induced = Z(i).induced;
    if induced == -1
        fprintf('%s/%s - rejected; unable to determine induction bar\n',...
            Z(i).rat,Z(i).cell);
        sel(i) = 0;
        continue
    elseif induced == 0
        induced = 1;
    end
    pre = Z(i).pre(induced);
    pst = Z(i).pst(induced);
    if isempty(pre.(RESPONSE_TYPE)) | isempty(pst.(RESPONSE_TYPE))
        fprintf('%s/%s - rejected; pre or post was empty\n',...
            Z(i).rat,Z(i).cell);
        sel(i)  = 0;
        continue
    end        
    % baseline length:
    if ~isempty(BASELINE_LENGTH)
        baseline_length = pre.time(end) - pre.time(1);
        if baseline_length < BASELINE_LENGTH
            fprintf('%s/%s - rejected; baseline too short (%3.2f)\n',...
                Z(i).rat,Z(i).cell,baseline_length);
            sel(i)  = 0;
            continue
        end
    end
    % post-induction length:
    if ~isempty(POST_LENGTH)
        pst_length = pst.time(end) - pst.time(1);
        if round(pst_length) < POST_LENGTH
            fprintf('%s/%s - rejected; post-induction too short (%3.2f)\n',...
                Z(i).rat,Z(i).cell,pst_length);
            sel(i)  = 0;
            continue
        end        
    end
    
    % baseline slope:
    value           = mean(pre.(RESPONSE_TYPE));
    [slope, stats]  = polyfit(pre.time, pre.(RESPONSE_TYPE), 1);
    if ~isempty(BASELINE_SLOPE)
        if abs(slope(1)) > (value .* BASELINE_SLOPE)
            fprintf('%s/%s - rejected; baseline unstable (%3.2f mean, %3.2f slope)\n',...
                Z(i).rat,Z(i).cell, value, slope(1));
            sel(i)  = 0;
            continue
        end
    end
    % IR:
    field   = 'ir';
    pre_r   = nanmean(cat(1,Z(i).pre.(field)));
    % only select IR values in post measurement interval
    pst_r   = nanmean(getFromInterval(Z(i).pst,field,POST_INTERVAL));
    shift_ir = pst_r / pre_r;        
    if ~isempty(POST_IR) & ~Z(i).skip_ir
        thresh   = [1/(1 - POST_IR), 1/(1 + POST_IR)];
        if shift_ir > thresh(1) | shift_ir < thresh(2)
            fprintf('%s/%s - rejected; IR bad (%3.2f %s %3.2f; %3.2f%%)\n',...
                Z(i).rat,Z(i).cell,...
                pre_r, char(187), pst_r, (shift_ir - 1) * 100);
            sel(i)  = 0;
            continue            
        end
    end
    % SR:
    field   = 'sr';
    pre_r   = nanmean(cat(1,Z(i).pre.(field)));
    % only select IR values in post measurement interval
    pst_r   = nanmean(getFromInterval(Z(i).pst,field,POST_INTERVAL));
    shift_sr = pst_r / pre_r;
    if ~isempty(POST_SR) & ~Z(i).skip_sr
        thresh   = [1/(1 - POST_SR), 1/(1 + POST_SR)];
        if shift_sr > thresh(1) | shift_sr < thresh(2)
            fprintf('%s/%s - rejected; SR bad (%3.2f %s %3.2f; %3.2f%%)\n',...
                Z(i).rat,Z(i).cell,...
                pre_r, char(187), pst_r, (shift_sr - 1) * 100);
            sel(i)  = 0;
            continue            
        end
    end
    
    % if we've reached this point, the experiment is good, and we can
    % calculate and store some computed results
    fprintf('%s/%s - cell passed!\n',Z(i).rat,Z(i).cell);
    pre_val = pre.(RESPONSE_TYPE);
    pst_val = getFromInterval(pst,RESPONSE_TYPE,POST_INTERVAL);
    if ~isempty(pre_val) | ~isempty(pst_val)
        Z(i).pre_value  = mean(pre_val);
        Z(i).pst_value  = mean(pst_val);
        [h,p]           = ttest2(pre_val,pst_val);
        Z(i).P_shift    = p;
    end
    Z(i).pre_slope  = slope(1);
    Z(i).shift_ir   = shift_ir;
    Z(i).shift_sr   = shift_sr;
    if ~isempty(Z(i).t_spike)
        Z(i).spike_peak = Z(i).t_spike - pre.t_peak;
        Z(i).spike_onset = Z(i).t_spike - pre.t_onset;
    end
    % also, for futher analysis we're only going to keep the induced bars
    Z(i).pre    = pre;
    Z(i).pst    = pst;
end
% now eliminate the failed experiments again
Z   = Z(find(sel));
% produce output file
if nargin > 1
    rats    = char({Z.rat}');
    rats    = str2num(rats(:,4:end));
    cells   = char({Z.cell}');
    cells   = str2num(cells(:,5:end));
    values  = [Z.pre_value;Z.pst_value;Z.P_shift;Z.spike_onset;Z.spike_peak]';
    fid = fopen(output,'w');
    try
        for i = 1:length(rats)
            fprintf(fid,'%d/%d,%3.4f,%3.4f,%3.1f,%3.4f\n',...
                rats(i),cells(i),Z(i).pre_value,Z(i).pst_value,...
                Z(i).spike_onset*1000,Z(i).spike_peak*1000);
        end
        fclose(fid);
    catch
        fclose(fid);
        error(lasterr)
    end
end

function value = getFromInterval(structure, field, interval)
value = [];
for j = 1:length(structure)
    t       = structure(j).time;
    if length(interval) > 1
        ind     = find(t>=interval(1) & t<=interval(2));
    else
        ind     = find(t>=interval(1));
    end
    value   = cat(1,value,structure(j).(field)(ind));
end
