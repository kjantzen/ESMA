function fighandle = study_RunStats(GND, stats)
% fh = STUDY_RUNSTATS(data, stats)
%
% Computes statistics on EEG time or time/frequency data within the esma
% environment.  The tool creates an interface for users to assign
% experimental conditions to statistical levels (passed in the stats
% structure) and runs the statistical test using information provided in
% the stats structure.  This function is meant to be called from the
% study_PlotERP and study_PlotERSP tools rather than called directly.
% 
% Inputs
% GND - a data structure of the type .GND (which is s modified GND file of
% the format used by the FMUT library) or of the type .ersp which is a
% cobled together format that holds ersp data for an experiment.
%
% stats - a structure has the following fields
%   stats.factors - a 1xn cell char array of factor names, one name for each of the n factors
%
%   stats.levels - a 1xn cell char array of factor levels indicating the number of levels of each factors
%
%   exand the above to be a structure that also holds names for each of the
%   levels
%
%   stats.winstart - the time (in ms) for the start of the time window that 
%       defines the data used for analysis
%   
%   stats.windend - the time (in ms) for the end of the time window that
%       defines the data used for analysis
%
%   stats.freqwinstart - the frequency (Hz) of the start of the frequency
%       window t analyze stats.freqwinstart < stats.freqwinend.  Ignored
%       unless stats.Test = 'FT_Parametric" or "FT_Permutation"
%
%   stats.freqwinend - the frequency (Hz) of the end of the frequency
%       window t analyze where stats.freqwinend > stats.freqwinstart
%
%   stats.meanwindow - if true (1) data will be averaged within the time
%       window before performing statistics.  If false  (0) a test will be 
%       conducted on each time point separately.
%    
%       This variable is ignored when performing a GLM on time series data
%       because values are automatically averaged in time.   Mass univariate
%       approaches should be used to conduct statistics on each time point.
%    
%   stats.meanfreq - if true (1) data will be averaged across frequency
%       befor running stats
%
%   stat.test - the name of the test to perform
%       For EEG time series mass univariate tests, this is the actual name
%       of the FMUT m file to use and must be one of the following:
%          'FmaxGND', 
%          'FclustGND'
%          'FfdrGND'
%       For parametric statistics, this is the name of the test to perform
%       currently supported options are - 
%           'ANOVA'
%       For time frequency statistics this should be one of the following:
%           'TF_Parametric'
%           'TF_Permutation'       
%
%   stats.measure must be one of 
%       'Amplitude' - performs stats on amplitude data
%
%        ** The following apply only to EEG time series analysis
%       'Positive Peak Latency' - performs statistics on latency of the positive peak
%           in the window 
%       'Negative Peak Latency' - performs statistics on latency of the negative peak
%           in the window 
%       'Peak Plus Minus' - unused currently
%       'Peak to Peak' - performs statistics on the amplitude difference
%           between the highest and lowest values in the window.
%
%   stats.alpha - the alpha to use for determining significance
%
%   stats.eegchans -
%       If conducting stats on a channel group this variable should be
%       a structure vector with one element per channel group.  Each of the
%       elements of the structure should have the following fields:
%          chans - an integer vector with the number of channels in each group
%          name = a string holding the name for the channel group
%
%       If conducting multivariate on the time series data this should be a
%       cell array with the name of channels to use in the statistical
%       analaysis
%
%       This field is not used by the time frequency stats functions
%
%   stats.eegchan_numbers a integer vector with the channel numbers to use
%      in the analysis.  THe order should match the names in stats.eegchans.
%   
%   stats.multcomparecorrection - the type of multiple comparison
%       correction to perform.  Instituted for time frequency statistics
%       only becaue the correction type is built into the FMUT selection
%       already.
%           'Cluster'
%           'Others will go here'
%       
% Output
% fighandle - a handle to the interface figure that can be used to halt processing
% until the function call returns
%

% dumb fix because I did not harmonize across file types
%bin information is stored differently on the frequency files than on the
%time files
if ~isfield(GND, 'bin_info') && isfield(GND, 'bindesc')
    for ii = 1:length(GND.bindesc)
        GND.bin_info(ii).bindesc = GND.bindesc{ii};
    end
    %GND.bin_info.bindesc = GND.bindesc;
    GND.time_pts = GND.times;
end

h = build_gui();
fighandle = h.figure;
initialize_gui(h, GND, stats);

% *************************************************************************
function h = initialize_gui(h, GND, stats)

%fill in the blank model information
n_factors = length(stats.factors);

levels = zeros(1,n_factors);
for ii = 1:n_factors
    levels(ii) = length(stats.factors(ii).Levels);
end
%n_conds = prod(levels);

%create a matrix with the condition name cominations
if n_factors > 1
    itemsTable = combinations(stats.factors.Levels);
    cond_name_matrix = table2cell(itemsTable);
    temp = join(cond_name_matrix,",");
else
    cond_name_matrix = stats.factors.Levels;
    temp = cond_name_matrix;
end

items = strcat('[',temp,']');

h.figure.UserData = cond_name_matrix;

h.list_model.Items = items;
h.list_model.ItemsData = items;
h.list_model.UserData = items;
h.list_conditions.Items = {GND.bin_info.bindesc};
h.list_conditions.ItemsData = 1:length(GND.bin_info);

modelkey = join({stats.factors.Factor},' x ');

h.label_model.Text = modelkey;
h.button_add.ButtonPushedFcn = {@callback_assignconditions,h};
h.button_remove.ButtonPushedFcn = {@callback_assignconditions,h};
h.button_dostats.ButtonPushedFcn = {@callback_dostats, h, GND, stats};
h.button_cancel.ButtonPushedFcn = {@callback_cancel, h.figure};

%***********************************************************************
% callback function for the run stats button on the GUI
% collects and verifies all the necessary information and then calls the 
% stats function depending on whether the user is running parametric or 
% mass univariate statistics 
%***********************************************************************
function callback_dostats(hObject, event, h, GND, stats)

%get the condition list from the main list box
cond_info = h.list_model.ItemsData;
if sum(cellfun(@(a) a(1)=='[',cond_info))
    uialert(h.figure, 'Please define all conditions first.', 'Run Stats');
    return
end

% determines if between subject information will be included in the test.
stats.useBetween = h.check_usebetween.Value;
if stats.useBetween
    [hasError, stats] = assignBetweenVariables(stats, GND);
    %if something goes wrong, do not use the between subject
    if hasError 
        warning('Continuing without between groups analysis');
        stats.useBetween = 0;
    end
end

%show a progress bar with a default message
pb = uiprogressdlg(h.figure, 'Title', 'Please Wait', 'Message', 'Running mass univariate statistics(FMUT) ... this could take a while.', 'Indeterminate', 'on');

%convert the time window from time to the correspoding closest sample points
[~,stats.winstartpt] = min(abs(stats.winstart - GND.time_pts));
[~,stats.winendpt] = min(abs(stats.winend - GND.time_pts));

if contains(stats.test, 'ANOVA')
    pb.Message = 'Solving the GLM ... this won''t take long.';
    GND = solve_GLM(h,GND,stats);
elseif contains(stats.test, 'TF_')
    %convert the frequency window to sample points
    [~,stats.freqwinstartpt] = min(abs(stats.freqwinstart - GND.freqs));
    [~,stats.freqwinendpt] = min(abs(stats.freqwinend - GND.freqs));
    pb.Message = 'Using fieldtrip (ft_freqstatistics) to compute time frequency statistics.  This could take a while';
    GND = do_TFStats(h, GND, stats, pb);
else
    GND = do_MassUniv(h,GND,stats);
end

outfile = eeg_BuildPath(GND.filepath, GND.filename);
if isfield(GND, 'freqs')
    TFData = GND;
    save(outfile, 'TFData', '-mat');
else
    save(outfile, 'GND', '-mat');
end

delete(pb);
delete(h.figure);
%*************************************************************************
function [fail, stats] = assignBetweenVariables(stats, GND)

fail = false;
% look for a set of unique categories and make sure they are in each file
if isfield(GND, 'indiv_conditions')
    hasConds = cellfun(@isempty, GND.indiv_conditions);
    %check to see if everyone has some conditions
    if sum(hasConds > 1)
        warning('Some participants have not been assigned a condition. Define conditions for each participant and re-calculated the average!\n');
        fail = true;
    else
        %check to see that everyone has the same number of
        %conditions
        nconds = unique(cellfun(@length, GND.indiv_conditions));
        if length(nconds) > 1
            warning('Participants have different numbers of conditions. Define the same number of conditions for each participant and re-calculate the average!\n')
            fail = true;
        else
            stats.btwnFactArray = vertcat(GND.indiv_conditions{:});
            for ii = 1:nconds
                [stats.btwnFacts{ii}, ia, cnt] = unique(stats.btwnFactArray(:,ii));
                fprintf('Between Condition %i\n', ii)
                %tell the user what we found in a crude way
                for jj = 1:length(ia)
                    fprintf('\tfound %i participants with condition %s\n', sum(cnt==jj), stats.btwnFactArray{ia(jj), ii});
                end
            end
        end
    end
else
    warning('No conditions have been defined.  Define conditions for each participant and re-calculated the average!\n');
    fail = true;
end
   

%*************************************************************************
function callback_cancel(~,~,h)
    %need to do more here to let the calling funciton know that we did not
    %do anything
    delete(h)

%*************************************************************************
function GND = do_TFStats(h,GND,stats,hPB)


wwu_msgdlg("This ability is currently disabled", "TF Stats", {'OK'}, "isError",true);
return

cond_info = h.list_model.ItemsData;

%get the saved experiment matrix
stats.cond_matrix = h.figure.UserData';
%populate it with more human names
stats.cond_name_matrix = cellfun(@(x) sprintf('level %i', x), num2cell(stats.cond_matrix), 'UniformOutput', false);
%this is the order the data was assigned to the different conditions
stats.cond_order = cellfun(@str2num, cond_info);
stats.conditions = {GND.bin_info(stats.cond_order).bindesc};
stats.factors = strtrim(stats.factors);
stats.effects = stats.factors;
if length(stats.factors) > 1
    stats.effects{end+1} = [stats.factors{1}, ' X ', stats.factors{2}];
end

stats.eegchans_names = {GND.chanlocs(stats.eegchan_numbers).labels};
n_chans = length(stats.eegchan_numbers);
stats.group_n = size(GND.indiv_ersp, 1);
lv = cellfun(@str2num, stats.levels);

%change the order of the dimensions so that participants is second to last
d = permute(GND.indiv_ersp(:,:,stats.freqwinstartpt:stats.freqwinendpt, stats.winstartpt:stats.winendpt,:), [2,3,4,1,5]);

%start with three data dimensions (channel x frequency x time)
%so we can track when the dimensions are reduced by averaging
nDataDims = 3;

%average across dimension here if doing that
%if we have only time or only frequency, we can do the whole thing at once
%and correct across channel
if stats.meanfreq
    d = mean(d, 2);
    nDataDims = nDataDims-1;
end
if stats.meanwindow
    d = mean(d,3);
    nDataDims = nDataDims-1;
end
%get rid of singleton dimensions
d = squeeze(d);

if contains(stats.test, 'TF_Permutation')
    stats.test = 'permutation';
elseif contains(stats.test, 'TF_Parametric')
    stats.test = 'parametric';
else
    error('RunsStats:InvalidMethod', '%s is not a valid test method.  Must be one of TF_Permutation or TF_Parametric', stats.test);
end

%check to see if this is a time x channel or a frequency by channel and if
%it is then calculate a channel neighborhood and do the stats all in one
%shot
%*************************************************************************
if nDataDims < 3

    %command to convert the data to a cell array for each conditions
    %add one to nDataDims so participants are included in each cell
    cmd = ['squeeze(num2cell(squeeze(d(:,', sprintf('%s', repmat(':,', 1, nDataDims)), 'stats.cond_order)), 1:nDataDims+1))'];
    
    cfg.elec.label = {GND.chanlocs.labels}';
    cfg.elec.chanpos = [[GND.chanlocs.X] ;[ GND.chanlocs.X] ;[ GND.chanlocs.X ]]';
    cfg.elec.elecpos = cfg.elec.chanpos;
    cfg.method = 'distance';
    cfg.channel = 1:length(GND.chanlocs);
    cfg.neighbourdist = 20;
    neighborhood = ft_prepare_neighbours(cfg);

    %do the whole analysis at once since we collapsed across at least one
    %dimension
    indata = eval(cmd);
    indata = reshape(indata, lv);

    s = wwu_TFStatistics(indata, 'method', stats.test ,'alpha',stats.alpha, 'ivar' , length(stats.levels), 'numrandomization','all', 'clusterstatistic',stats.clusterstatistic,...
            'correctm',stats.multcomparecorrectino,'neighbours', neighborhood, 'chandim', 1);

    %expand back to the original dimensions
    
    stats.F_obs = s.F;
    stats.p_val = s.pval;

%if the data are still time x frequency x channel, run the stats one
%channel at a time and do correction based on active clusters in the t and
%f domain
% ******************************************************************
else
    
    %change the waitbar to reflect the progress on each channel
    hPB.Indeterminate = 'off';
    hPB.Value = 0;

    %preallocate arrays for the data output
    fA = zeros(n_chans, size(d,2), size(d,3));fB = fA; fAB = fA;
    pA = fA; pB = fA; pAB = fA;
    %loop over channel
    for ch = 1:n_chans
        %update progress bar
        hPB.Value = ch/n_chans;

        %extract data for a single channel
        indata = squeeze(num2cell(squeeze(d(stats.eegchan_numbers(ch), :,:,:,stats.cond_order)), 1:nDataDims));

        %reshape data based on design
        indata = reshape(indata, lv);
        
        %compute statistics
        [s] = wwu_TFStatistics(indata, 'method', stats.test ,'alpha',stats.alpha, 'ivar' , length(stats.levels), 'numrandomization','all', 'clusterstatistic',stats.clusterstatistic,...
            'correctm',stats.multcomparecorrectino);

        %put the stats together into a single structure in the GND
        fA(ch,:,:) = s.F{1}; fB(ch,:,:) = s.F{2}; fAB(ch,:,:) = s.F{3};
        pA(ch,:,:) = s.pval{1}; pB(ch,:,:) = s.pval{2}; pAB(ch,:,:) = s.pval{3};
    end
    %add results to the stats structure
    stats.F_obs = {fA, fB, fAB};
    stats.p_val = {pA, pB, pAB};
end

% add the stats information to the data structure
 if ~isfield(GND, 'F_tests')
     GND.F_tests(1) = stats;
 else
     GND.F_tests(end+1) = stats;
 end

%*************************************************************************
% perform parametric statistics on the data using both within and between
% vatiables.
%*************************************************************************
function GND = solve_GLM(h,GND,stats)

%This is the mapping of condition onto factor and level
%provided by the user
cond_info = h.list_model.ItemsData;

%get the saved experiment matrix
cond_name_matrix = h.figure.UserData;

%populate it with more human names
%I want to find a way for the participant to enter the name of the level
%cond_name_matrix = cellfun(@(x) sprintf('level %i', x), num2cell(cond_matrix), 'UniformOutput', false);

%this is the order the data was assigned to the different conditions
cond_order = cellfun(@str2num, cond_info);

%extract the data for analysis
if isstruct(stats.eegchans)  %conduct the analysis on the channel group
    ANOVAdata = [];
    n_chans = length(stats.eegchans);
    for ii = 1:n_chans
        ANOVAdata(ii,:,:,:) = mean(GND.indiv_erps(stats.eegchans(ii).chans,  stats.winstartpt:stats.winendpt,cond_order,:),1);
    end
    %these will be used as names for the channel IV
    cnames = {stats.eegchans.name};
else
    n_chans = length(stats.eegchan_numbers);
    ANOVAdata = GND.indiv_erps(stats.eegchan_numbers, stats.winstartpt:stats.winendpt,cond_order,:); 
    cnames = {GND.chanlocs(stats.eegchan_numbers).labels};
end
lnums = 1:n_chans;


%compile the data differently depending on whether the user wants to
%analyze amplitude or latency

switch stats.measure
    case 'Amplitude'
        %will calculate within subject averages for each channel (or group)
        %condition and subject into a channel x condition x subject array
        ANOVAdata = squeeze(mean(ANOVAdata,2)); %average over time
    case 'Positive Peak Latency'
        %get latencies and convert to time
        [~,ANOVAdata] = max(ANOVAdata,[],2);
        ANOVAdata = GND.time_pts(squeeze(ANOVAdata)+stats.winstartpt-1);      
    case 'Negative Peak Latency'
        [~,ANOVAdata] = min(ANOVAdata,[],2);
        ANOVAdata = GND.time_pts(squeeze(ANOVAdata)+stats.winstartpt-1);
    case 'Peak Plus Minus'
    case 'Peak to Peak'
        [NPeakAmp, NPeakIndx] = min(ANOVAdata,[],2);
        [PPeakAmp,PPeakIndx] = max(ANOVAdata,[],2);
        ANOVAdata = squeeze(PPeakAmp)-squeeze(NPeakAmp);
end

%reshape the data so that channels becomes a factor
n_conds = length(cond_order);
if n_chans> 1
    ANOVAdata = reshape(permute(ANOVAdata, [2,1,3]), n_chans * n_conds, size(ANOVAdata,3));
    %create a column for the channel information
    lnames = reshape(repmat(cnames', 1,n_conds)', 1, n_chans*n_conds);
    lnums = reshape(repmat(lnums', 1, n_conds)', 1, n_chans*n_conds); 
else
    lnames = "";
end

data_table = array2table(ANOVAdata');
%add between subject variables by adding a categorical column to the data
%table
if stats.useBetween
    vNames = {};
    for ii = 1:size(stats.btwnFactArray, 2)
        vNames(end+1) = {sprintf('between%i', ii)};
    end
    bTable = array2table(stats.btwnFactArray, 'VariableNames', vNames);
    convertvars(bTable, vNames, 'categorical');
    data_table = [bTable, data_table];
end

%add channels as factors
if n_chans > 1
    stats.factors(end+1).Factor = 'Channel';
    stats.factors(end).Levels = cnames;
    
    cond_name_matrix = repmat(cond_name_matrix, n_chans, 1);
    cond_name_matrix(:,end+1) = lnames';
end

%get the means and create a table as part of the output
means = mean(ANOVAdata,2);
temp = [cond_name_matrix,num2cell(means)];
varNames = {stats.factors.Factor}; 
mean_tble = cell2table(temp, 'VariableNames', [varNames, {'Mean'}]);

%create the ANOVA model
if stats.useBetween
    btweenFactor = strjoin(vNames, ' + ');
else 
    btweenFactor = '1';
end
model = sprintf('Var1-Var%i~%s', n_conds * n_chans, btweenFactor);
within = cell2table(cond_name_matrix, 'VariableNames', varNames);
within = convertvars(within, varNames, 'categorical');
withinmodel = join(varNames, '*');
rm_model = fitrm(data_table,model,'WithinDesign',within,'WithinModel',withinmodel{1});
ANOVAresult = ranova(rm_model,'WithinModel',withinmodel{1});
%add the stats into the GND file
if ~isfield(GND, 'ANOVA')
    GND.ANOVA = [];
end
if isempty(GND.ANOVA)
    indx = 1;
else
    indx = length(GND.ANOVA) + 1;
end
statsName = getTestName();
GND.ANOVA(indx).name = statsName;
GND.ANOVA(indx).type = stats.measure;
GND.ANOVA(indx).source_table = ANOVAresult;
GND.ANOVA(indx).data = data_table;
GND.ANOVA(indx).model = model;
GND.ANOVA(indx).withinmodel = withinmodel;
GND.ANOVA(indx).within = mean_tble;
GND.ANOVA(indx).timewindow = [GND.time_pts(stats.winstartpt), GND.time_pts(stats.winendpt)];
GND.ANOVA(indx).pntwindow = [stats.winstartpt, stats.winendpt];
GND.ANOVA(indx).chans_used = lnames;
GND.ANOVA(indx).conditions = {GND.bin_info(cond_order).bindesc};
GND.ANOVA(indx).factors  = stats.factors;
%GND.ANOVA(indx).levels  = stats.levels;
GND.ANOVA(indx).level_matrix = cond_name_matrix;
GND.ANOVA(indx).hasBetween = stats.useBetween;
if stats.useBetween
    GND.ANOVA(indx).betweenVars = stats.btwnFactArray;
else
    GND.ANOVA(indx).betweenVars = [];
end

%**************************************************************************
% conducts mass univariate statistics using the FMUT toolbox from Eric
% Fields.  https://github.com/ericcfields/FMUT/wiki/
%**************************************************************************
function GND = do_MassUniv(h,GND,stats)

%TODO:  make compatible with between subject tests by
%   1. checking if between subject is desired and if there are groups
%   labeled.
%   2. Create a GND file for each group
%   3. Create a GRP file from the GND files
%   4. Run the stats

cond_info = h.list_model.ItemsData;
cond_order = cellfun(@str2num, cond_info);

%set some parameters for the call to the FMUT functions
if stats.meanwindow
    winmean = 'yes';
else
    winmean = 'no';
end

%figure out which method will be used to correct for multiple comparisons.
if contains(stats.test, 'fdr')
    q_or_alpha = 'q';
else
    q_or_alpha = 'alpha';
end

if contains(stats.test, 'clust')
    %figure out a good neighborhood
    head_radius = sprintf('''head_radius'', %f,', GND.chanlocs(1).sph_radius * 2 * pi / 10);
    ch_hood = sprintf('''chan_hood'', %f,', GND.chanlocs(1).sph_radius/2);
else
    ch_hood = '';
    head_radius = '';
end

flevels = length(stats.factors);
clevels = zeros(1, flevels);
for ii = 1:flevels
    clevels(ii) = length(stats.factors(ii).Levels);
end
%clevels = cellfun(@str2double, stats.levels);
factors = {stats.factors.Factor};
%factors = cellfun(@strtrim, stats.factors, 'UniformOutput', false);
factors = cellfun(@(x) replace(x,' ', '_'), factors, 'UniformOutput', false);

%build the command string for a within subject design
command_str = [stats.test, '( GND, ''bins'', cond_order, ''factor_names'', factors, ''factor_levels'', clevels,' ch_hood head_radius];
command_str = [command_str, '''time_wind'', [stats.winstart stats.winend], ''',q_or_alpha,''', stats.alpha, ''plot_raster'', ''no'','];
command_str = [command_str, '''include_chans'', stats.eegchans, ''mean_wind'', winmean, ''save_GND'', ''no'');'];

GND = eval(command_str);

cnt = length(GND.F_tests);
GND.F_test_names{cnt} = getTestName();
%**************************************************************************
function statsName = getTestName()
%get a name for the stats test

statsName = "";
while statsName == ""
    p.msg = 'Enter a name for this test.';
    p.title = 'Statistics';
    p.options = {'OK'};
    statsName = wwu_inputdlg(p);
    if isempty(statsName.input)
        wwu_msgdlg("This is not a valid test name", "Ivalid Entry", {"OK"}, isError = true)
    else
        statsName = replace(statsName.input, ' ', '_');
    end
end
%**************************************************************************
function callback_assignconditions(~, event, h)
        
switch event.Source.Tag
    case 'add'        
         %clunky way to know how many conditions there are
        total_conds = length(h.list_model.Items); 
       
        %get the data from the conditions list
        cond_sel = h.list_conditions.Value;
        for ii = 1:length(cond_sel)
            cond_sel_pos(ii) = find(h.list_conditions.ItemsData==cond_sel(ii));
        end
        n_cond_sel = length(cond_sel); %get how many are selected
        
        %figure out which conditions are selected in model
        mod_sel = h.list_model.Value;
        if mod_sel(1) ~= '['
            uialert(h.figure, 'This will overwrite previously assigned conditions. Please remove the assigned condition first.', 'Assign Condition');
            return
        end
            
        [~,indx] = ismember({mod_sel},h.list_model.ItemsData);
        
        if (total_conds - indx + 1) < n_cond_sel
            uialert(h.figure, 'There are not enough spaces left in the nodel to hold all the selected conditions.', 'Assign Condition');
            return
        end
        
        for ii = indx:n_cond_sel
            if h.list_model.ItemsData{ii}(1) ~= '['
                uialert(h.figure, 'This will overwrite previously assigned conditions. Please remove the assigned condition first.', 'Assign Condition');
                return
            end
        end
        
        %hopefully everything is OK if we got this far
        for ii = 1:n_cond_sel
            h.list_model.Items(indx+ii-1) = join(horzcat(h.list_model.ItemsData(indx+ii-1),h.list_conditions.Items(cond_sel_pos(ii))));
            h.list_model.ItemsData{indx+ii-1} = num2str(cond_sel(ii));
        end
        
        %remove from the conditions list
        h.list_conditions.Items(cond_sel_pos) = [];
        h.list_conditions.ItemsData(cond_sel_pos) = [];
        
        %automatically select the next item
        if indx+ii-1 < total_conds
            h.list_model.Value = h.list_model.ItemsData{indx+ii};
        else
            h.list_model.Value = h.list_model.ItemsData{end};
        end            
   
    %*********************************************************************
    case 'rem'
        
        total_conds = length(h.list_conditions.ItemsData);
        
        %I will use these if the user removes a condition
        all_blank_conds = h.list_model.UserData;
        
        
        model_sel = h.list_model.Value;
        [~,indx] = ismember(model_sel, h.list_model.ItemsData);
        
        %exit if the user is trying to remove a blank entry
        if model_sel(1) == '['
            return
        end
        
        %figure out where it goes in the old list
        returnPosition = str2num(model_sel);
        
        old_items = h.list_conditions.Items;
        old_itemsdata = h.list_conditions.ItemsData;
        
        %go through each existing item and assign it to the new array
        %if when we get to the return position we insert our returning
        %element
            INSERTED = false;
            new_items = {};
            for ii = 1:total_conds
                if old_itemsdata(ii) < returnPosition
                    new_items(ii) = old_items(ii);
                    new_itemsdata(ii) = old_itemsdata(ii);
                else
                    cn = h.list_model.Items{indx};
                    new_items(ii) = {strtrim(cn(strfind(cn, ']')+1:end))};
                    new_itemsdata(ii) = str2double(h.list_model.ItemsData{indx});
                    new_items(ii+1:total_conds+1) = old_items(ii:total_conds);
                    new_itemsdata(ii+1:total_conds+1) = old_itemsdata(ii:total_conds);
                    INSERTED = true;
                    break
                end
            end
            
        if ~INSERTED

            cn = h.list_model.Items{indx};
            last_item = length(new_items);
            new_items(last_item+1) = {strtrim(cn(strfind(cn, ']')+1:end))};
            new_itemsdata(last_item+1) = str2double(h.list_model.ItemsData{indx});
            
        end
        h.list_conditions.Items = new_items;
        h.list_conditions.ItemsData = new_itemsdata;
        
        %finally remove it from the model list        
        h.list_model.Items(indx) = all_blank_conds(indx);
        h.list_model.ItemsData(indx) = all_blank_conds(indx);
        
end

% **********************************************************************
function h = build_gui    
scheme = eeg_LoadScheme;

W = 450; H = 300;
L = (scheme.ScreenWidth - W)/2; B = (scheme.ScreenHeight - H)/2;
h.figure = uifigure(...
    'Position', [L,B,W,H],...
    'Color', scheme.Window.BackgroundColor.Value,...
    'Name', 'Assign Conditions',...
    'NumberTitle', 'off',...
    'Resize', 'off',...
    'menubar', 'none');


h.list_conditions = uilistbox(...
    'Parent', h.figure,...
    'Position', [10,40, 185, 200],...
    'BackgroundColor', scheme.Dropdown.BackgroundColor.Value,...
    'FontColor', scheme.Dropdown.FontColor.Value,...
    'FontName', scheme.Dropdown.Font.Value,...
    'FontSize', scheme.Dropdown.FontSize.Value,...
    'MultiSelect', 'on');

h.list_model = uilistbox(...
    'Parent', h.figure,...
    'Position', [255, 40, 185, 200],...
    'BackgroundColor', scheme.Dropdown.BackgroundColor.Value,...
    'FontColor', scheme.Dropdown.FontColor.Value,...
    'FontName', scheme.Dropdown.Font.Value,...
    'FontSize', scheme.Dropdown.FontSize.Value,...
    'MultiSelect', 'off');

h.label_model = uilabel('Parent', h.figure,...
    'Position', [255, 240, 185, 20],...
    'Fontsize', scheme.Label.FontSize.Value,...
    'FontName', scheme.Label.Font.Value,...
    'FontColor', scheme.Label.FontColor.Value);

uilabel('Parent', h.figure,...
    'Position', [255, 260, 185, 20],...
    'Text', 'Within Subject Factors',...
    'FontColor', scheme.Label.FontColor.Value);

uilabel('Parent', h.figure,...
    'Position', [10, 240, 185, 20],...
    'Text', 'Variables',...
    'Fontsize', scheme.Label.FontSize.Value,...
    'FontName', scheme.Label.Font.Value,...
    'FontColor', scheme.Label.FontColor.Value);


h.button_add = uibutton(...
    'Parent', h.figure,...
    'Position', [200, 215, 50, 25],...
    'Text', '-->', ...
    'BackgroundColor', scheme.Button.BackgroundColor.Value,...
    'FontColor', scheme.Button.FontColor.Value,...
    'FontName', scheme.Button.Font.Value,...
    'FontSize', scheme.Button.FontSize.Value,...
    'Tag', 'add');

h.button_remove = uibutton(...
    'Parent', h.figure,...
    'Position', [200, 150, 50, 25],...
    'Text', '<--', ...
    'BackgroundColor', scheme.Button.BackgroundColor.Value,...
    'FontColor', scheme.Button.FontColor.Value,...
    'FontName', scheme.Button.Font.Value,...
    'FontSize', scheme.Button.FontSize.Value,...
    'Tag', 'rem');

h.check_usebetween = uicheckbox(...
    'Parent', h.figure,...
    'Position', [20, 5, 250, 25],...
    'Text', 'Use between variables if present', ...
    'Value', 1,...
    'FontColor', scheme.Label.FontColor.Value,...
    'FontName', scheme.Label.Font.Value,...
    'FontSize', scheme.Label.FontSize.Value);

h.button_dostats = uibutton(...
    'Parent', h.figure,...
    'Position', [365, 5, 80, 25],...
    'Text', 'Continue', ...
    'BackgroundColor', scheme.Button.BackgroundColor.Value,...
    'FontColor', scheme.Button.FontColor.Value,...
    'FontName', scheme.Button.Font.Value,...
    'FontSize', scheme.Button.FontSize.Value);

h.button_cancel = uibutton(...
    'Parent', h.figure,...
    'Position', [275, 5, 80, 25],...
    'Text', 'Cancel', ...
    'BackgroundColor', scheme.Button.BackgroundColor.Value,...
    'FontColor', scheme.Button.FontColor.Value,...
    'FontName', scheme.Button.Font.Value,...
    'FontSize', scheme.Button.FontSize.Value);
