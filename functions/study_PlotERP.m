% Interface for reviewing ERP's within the ESMA envirionment
% This interface uses the GND file type generated using the FMUT and MUT
% matlab packages.  This is for convenience because ESMA uses these
% toolboxes to perform mass univariate statistics.  Moreover, this format
% retains individual participant information that allows for invetigation
% of individual and subject level means.
%
function study_PlotERP(study, filename)

fprintf('Opening ERP plotting and analysis tool...\n');
if isempty(filename)
    error('No valid file was found')
end

handles.figure = uifigure;
pb = uiprogressdlg(handles.figure, 'Indeterminate','on','Message','Building GUI','Cancelable','off',...
   'Title','Starting ERP Plotter');
handles = build_gui(handles);
drawnow();


pb.Message = 'Loading Data...';
[~,fname,~] = fileparts(filename{:});
handles.figure.Name = sprintf('ERP Tool: %s', fname);
GND = wwu_LoadEEGFile(filename{1});

%load(filename{1}, '-mat');
%calculate the within subject confidence interval
GND = addWithinCI(GND);

pb.Message = 'Initializing display with data values...';
initialize_gui(handles, GND);
pb.Message = 'Creating callbacks...';
handles = assign_callbacks(handles);


% % %sometimes the time points used variable is a cell vector and sometimes it is
% % %an integer vector.  I will harmonize it here rather than figure out why
% if isfield(GND, 'F_tests') && ~isempty(GND.F_tests)
%     for ii = 1:length(GND.F_tests)
%         if iscell(GND.F_tests(ii).used_tpt_ids)
%              GND.F_tests(ii).used_tpt_ids = cell2mat(GND.F_tests(ii).used_tpt_ids);
%         end
%     end
% end

pb.Message = 'Stashing data...';
p.GND = GND;
p.study = study;
p.ts_style = repmat({'-', '--', '-.', ':'}, 1, 6);
clear GND;

%initialize the cursor
cinfo.cursor = [];
cinfo.currentcursor = [];
cinfo.dragging = false;

%save the cursor information
handles.axis_erp.UserData = cinfo;
handles.figure.UserData = p;

%initialize the displays and plot the data
pb.Message = 'Drawing data...';
callback_relfreshDisplay([],[],handles, false)
callback_toggleallchannel([],handles.check_allchans,handles);
event.Source.Tag = 'add';
callback_managecursors([], event, handles);

fprintf('...done\n');
pb.Message = 'All done...Enjoy!!';
pause(1);
close(pb);

%***************************************************************************
function callback_togglePlotANOVAStyle(~,event, h)

%get the state to display
if isfield(event, 'Edited')
    changingStatTest = true;
else
    changingStatTest = false;
end

state = h.check_plotANOVAStyle.Value;
testIndx = h.dropdown_ANOVAtest.Value;
if testIndx == 0
    wwu_msgdlg("A GLM test must exist and be selected to use this option", 'Plot as ANOVA',...
        {'Ok'}, 'isError',true);
    return
end

if state
    p = h.figure.UserData;
    if ~isfield(p.GND, 'ANOVA') || isempty(p.GND.ANOVA) || length(p.GND.ANOVA) < testIndx
        wwu_msgdlg("No stats information was found", 'Plot as ANOVA', {'OK'}, 'isError',true);
        return
    end
    test = p.GND.ANOVA(testIndx);
    chans = unique(test.chans_used);
    h.check_allchans.Value = false; %make sure the all channel check is off
    chan_indx = find(contains(h.list_channels.Items, chans));
    h.list_channels.Value = h.list_channels.ItemsData(chan_indx);

    indx = matches(h.list_condition.Items,test.conditions);
    h.list_condition.Value = h.list_condition.ItemsData(indx);
    m = cond2StyleTable(test);
    h.check_plotANOVAStyle.UserData = m;
    callback_ploterp([],[],h);
elseif   ~xor(state, changingStatTest)
    callback_ploterp([],[],h);
end

%***************************************************************************
function m = cond2StyleTable(stat)

    
    nFactors = length(stat.factors);
    %channel is not a factor we have to worry about
    %when plotting
    if contains('Channel', stat.factors(end).Factor)
        nFactors = nFactors -1;
        stat.factors(end) = [];
    end
    nConds = length(stat.conditions);

    %combine colors and styles to make life easier
    
    m = zeros(nConds, nFactors);
    lm = stat.level_matrix(1:nConds,:);
    for ii = 1:nFactors
        l = unique(lm(:,ii));
        for jj = 1:length(l)
            m(contains(lm(:,ii), l(jj)), ii) = jj;
        end
    end
    m = array2table(m, 'VariableNames', {stat.factors.Factor});
    m.condition = stat.conditions';
    

%***************************************************************************
function callback_togglemapoption(hObject, ~, h)
    for ii = 1:4
        h.menu_mapquality(ii).Checked = false;
    end
    hObject.Checked = ~hObject.Checked;
    plot_topos(h)

%***************************************************************************
function callback_toggleAverageBetweenCursors(hObject, ~, h)
    hObject.Checked = ~hObject.Checked;
    plot_topos(h)

 %***************************************************************************
function callback_toggleautoscale(hObject, event, h)

    hObject.Checked = ~hObject.Checked;
    h.spinner_maxamp.Enable = ~hObject.Checked;
    h.spinner_minamp.Enable = ~hObject.Checked;

    callback_ploterp(hObject, event, h)

%************************************************************************
function callback_toggletopomenustate(hObject, event, h)

for ii = 1:3
    h.menu_mapscale(ii).Checked = false;
end
hObject.Checked = true;
plot_topos(h)

%**************************************************************
function callback_toggleplotoption(hObject, event, h)

    hObject.Checked = ~hObject.Checked;
    
    callback_ploterp(hObject, event, h);

%**************************************************************
function callback_changePlotRange(hObject, event, h)
    
    tag = hObject.Tag;

    %check to make sure the min and max are not opposite
    mnt = h.spinner_mintime.Value;
    mxt = h.spinner_maxtime.Value;
    mna = h.spinner_minamp.Value;
    mxa = h.spinner_maxamp.Value;

    if mnt >= mxt
        p = h.figure.UserData;
        if mxt == p.GND.time_pts(end) || strcmp(tag, 'maxtime')
            mnt = mxt - h.spinner_mintime.Step;
            h.spinner_mintime.Value = mnt;
        elseif mnt == p.GND.time_pts(1) || strcmp(tag, 'mintime')
            mxt = mnt + h.spinner_maxtime.Step;
            h.spinner_maxtime.Value = mxt;
        end
    end

    if mna >=mxa
        mna = mxa - 1;
        h.spinner_minamp.value = mna;
    end

    callback_ploterp(hObject,event,h);

%*************************************************************************
function callback_editconditions(~,~,h)
    p = h.figure.UserData;
    waitfor(eeg_EditERPConditions(p.GND));
    callback_relfreshDisplay([],[],h, true);

%*************************************************************************
function callback_plotANOVAresult(hObject, event,h, export)
%either plot the ANOVA results or export them depending of the status of
%the export flag.

%if the export flag is not passed, assume it is false
if nargin < 4
    export = false;
end
    
p = h.figure.UserData;

if ~isfield(p.GND, 'ANOVA') || isempty(p.GND.ANOVA)
    error('No ANOVA data for this GND file');
end

%if isempty(p.GND.ANOVA)
%    error('No ANOVA data for this GND file');
%nd

ANOVAnum = h.dropdown_ANOVAtest.Value;
r = p.GND.ANOVA(ANOVAnum);

if ~export
    study_PlotANOVAresults(r);
else
    exportStats(r);
end
%************************************************************************
function exportStats(r)

%get a temporary filename
if ~isfield(r, 'name')
    r.name = 'stat output';
end

excelFilename = sprintf('%s.xlsx', r.name);
[excelFilename, pathname] = uiputfile('*.xlsx', 'Select an excel filename and location', excelFilename);

if excelFilename == 0
    fprintf('The user selected Cancel...\n');
    return
end

excelFilename = fullfile(pathname, excelFilename);

%write the general information about the test
v(:,1) = {'Name'; 'Measure'; 'Time Window'};
v(:,2) = {r.name; r.type; sprintf('%3.2f - %3.2f ms', r.timewindow(1), r.timewindow(2))};
writecell(v, excelFilename,'Range', 'A1', 'Sheet', 'Data');

writecell({'Channels'}, excelFilename, 'Range', 'A4', 'Sheet', 'Data');


%make the row number variable here because the size of variables is not
%static
rowNum = 5;

%write some headers for factor levels
range = sprintf('A%i', rowNum);
nFacs = length(r.factors);
fac_names = {r.factors.Factor}';
writecell(fac_names, excelFilename,'Range',range, 'Sheet', 'Data');

%default next write column is 'B' - which is ascii 66
colNum = 66;

%shift writing by the number of between variables so the rows indicating
% condition numbers line up.
if r.hasBetween
    nBetween = size(r.betweenVars, 2);
    colNum = colNum+nBetween;
end

range = sprintf('%s%i',char(colNum), rowNum-1);
writecell(r.chans_used, excelFilename, 'Range',range, 'Sheet', 'Data');
range = sprintf('%s%i',char(colNum), rowNum);
writecell(r.level_matrix', excelFilename,'Range',range, 'Sheet', 'Data')

%add the names of the condition files that map onto the data columns
range = sprintf('%s%i',char(colNum), rowNum+nFacs);
writecell(r.conditions, excelFilename,'Range',range, 'Sheet', 'Data')

%write the raw data
range = sprintf('B%i',rowNum+nFacs+2);
writetable(r.data, excelFilename, 'Range', range,'WriteMode','inplace','WriteVariableNames', false, 'WriteRowNames', false, 'Sheet', 'Data');

%consider writing the mean and standard deviations

%write the source table
writetable(r.source_table, excelFilename, 'Sheet', 'ANOVA','Range', 'A1', 'WriteRowNames', true);



%************************************************************************
function callback_togglestatsoption(hObject, event, h)

if contains(event.Source.Value, 'ANOVA')
    state = true;
else
    state = false;
end
h.radio_amp.Enable = state;
h.radio_pospeak.Enable = state;
h.radio_negpeak.Enable = state;
h.radio_peakplusminus.Enable = state;
h.radio_peak2peak.Enable = state;
h.check_massunivave.Enable = ~state; 
   
%*************************************************************************
%function to delete unwanted bins and stats tests
function callback_removebinsandstats(hObject, event, h)

p = h.figure.UserData;
GND = p.GND;

switch event.Source.Tag
    case 'bin'
        c_bin = h.list_condition.Value;
        if length(h.list_condition.Items) < 2
            uialert(h.figure, 'You must have at least one condition per file', 'Delete Error');
            return
        end
        
        response = uiconfirm(h.figure, sprintf('Are you sure you want to delete %s?', GND.bin_info(c_bin).bindesc), 'Confirm Delete');
        if contains(response, 'OK')
            GND = rm_bins(GND, c_bin);
            GND = wwu_SaveEEGFile(GND);
            callback_relfreshDisplay([],[],h, 1);
        end
        
    case 'MU'
        
        c_stat = h.dropdown_MUtest.Value;
        if isempty(c_stat)
            return
        end
        
        response = uiconfirm(h.figure, sprintf('Are you sure you want to delete %s?', h.dropdown_MUtest.Items{c_stat}), 'Confirm Delete');
        if contains(response, 'OK')
            GND.F_tests(c_stat) = [];
            if isfield(GND, "F_test_names")
                GND.F_test_name(c_stat) = [];
            end
            GND = wwu_SaveEEGFile(GND);
            callback_relfreshDisplay([],[],h, 1);
            
            if ~isempty(GND.F_tests) %if we did not delete them all
                if length(h.dropdown_MUtest.Items) >= c_stat
                    h.dropdown_MUtest.Value = c_stat;
                else
                    h.dropdown_MUtest.Value = h.dropdown_MUtest.ItemsData(end);
                end
            end
            
        end
        
    case 'ANOVA'
        c_stat = h.dropdown_ANOVAtest.Value;
        if isempty(c_stat)
            return
        end
        
        response = uiconfirm(h.figure, sprintf('Are you sure you want to delete %s?', h.dropdown_ANOVAtest.Items{c_stat}), 'Confirm Delete');
        if contains(response, 'OK')
            GND.ANOVA(c_stat) = [];
            GND = wwu_SaveEEGFile(GND);
            p.GND = GND;
            h.figure.UserData = p;
            
            callback_relfreshDisplay([],[],h, 1);
            
            if ~isempty(GND.ANOVA) %if we did not delete them all
                if length(h.dropdown_ANOVAtest.Items) >= c_stat
                    h.dropdown_ANOVAtest.Value = c_stat;
                else
                    h.dropdown_ANOVAtest.Value = h.dropdown_ANOVAtest.ItemsData(end);
                end
            end
        end
end
%*************************************************************************
%function to handle adding and removing factors
function callback_changefactors(hObject, event, h)

%get the experiment structure now to avoid redundency since both the add
%and remove operations need it
d = h.list_model.UserData;

%allow for using the same function to both add and remove factors
switch event.Source.Tag
    case 'Add'
        
        %get information about the factor name and number of levels
        fname = h.edit_factors.Value;
        flevel = h.edit_levels.Value;

        %make sure the values are valid
        if isempty(fname) || isempty(flevel)
            uialert(h.figure, 'Please enter a factor name and number of levels.', 'Add factor');
            return
        end
        
        %make sure fname has no spaces in it.

        %get a label to associate with each level of the factor
        prompts = arrayfun(@(x) {sprintf('%s level %i', fname,x)}, 1:flevel);
        instr = sprintf("Please enter a label for each level of the Factor %s.", upper(fname));
        level_labels = wwu_getMultiInput(instr, prompts);

        %do not add the factor if the user pressed cancel
        if isempty(level_labels)
            return
        end
        for ii = 1:length(level_labels)
            if isempty(level_labels(ii))
                level_labels{ii} = sprintf('Level %i', ii);
            end
        end
       
        %once label names are available, probably store the name of the
        %factor and associated level labels in a stucuture in the
        %uicontrols user data.  Have to remember to move things to the end
        %and to remove them as well if they are deleted.  The pass that
        %structure to the statistics function so that name of the label
        %will be included.

        %do some checking to makes sure the levels arent empty
        if isempty(d)
            indx = 1;
        else
            indx = length(d) + 1;
        end
        d(indx).Factor = fname;
        d(indx).Levels = level_labels;
   
        %make a label to display this information to the user
        flabel = {sprintf('%s (%s)', fname, strjoin(level_labels, ","))};
        
        %if there are no factors
        if isempty(h.list_model.ItemsData)
            h.list_model.Items = flabel;
            h.list_model.ItemsData = 1;
        else
            h.list_model.Items = horzcat(h.list_model.Items, flabel);
            h.list_model.ItemsData = 1:length(h.list_model.Items);
        end

        %select the last item added
        h.list_model.Value = h.list_model.ItemsData(end);
        h.button_factremove.Enable = 'on';
        
        h.edit_factors.Value = '';
    case 'Remove'
        
        selected = h.list_model.Value;
        h.list_model.Items(selected) = [];
        d(selected) = [];
        h.list_model.ItemsData = 1:length(h.list_model.Items);
       
        if isempty(h.list_model.ItemsData)
            h.list_model.Items = {'[Enter your factors here]'};
            h.button_factremove.Enable = 'off';
        end
        
end

h.list_model.UserData = d;

%************************************************************************
function callback_runstatstest(hObject, event, h)

p = h.figure.UserData;

%collect information from the GUI
factorInfo = h.list_model.UserData;
if isempty(factorInfo)
    wwu_msgdlg("'Please define some conditions before running the test.",...
        "RunStats", {"Ok"},"isError",true);
    fprintf("No factors have been defined");
    return
end

stats.factors = factorInfo;
stats.test = h.dropdown_MUtype.Value;
stats.winstart = h.edit_massunivstart.Value;
stats.winend = h.edit_massunivend.Value;
stats.meanwindow = h.check_massunivave.Value;
stats.alpha = h.edit_massunivalpha.Value;
stats.ave_channels = false;
stats.eegchans = [];

%a GLM without correction can be run on the channel groups
if contains(stats.test, 'ANOVA')
    d = h.list_channels.Value;
    s = cell2mat(d');
    ch_groups = s(:,2);
    if sum(ch_groups) > 0
        stats.eegchans = p.study.chgroups(ch_groups);
    end
    if h.radio_amp.Value == 1
        stats.measure = 'Amplitude';
    elseif h.radio_pospeak.Value ==1
        stats.measure = 'Positive Peak Latency';
    elseif h.radio_negpeak.Value ==1
        stats.measure = 'Negative Peak Latency';
    elseif h.radio_peakplusminus == 1
        stats.measure = 'Peak Plus Minus';
    else
        stats.measure = 'Peak to Peak';
    end
end

if isempty(stats.eegchans)
    if h.check_massunivchans.Value
        d = h.list_channels.Value;
        s = cell2mat(d');
        stats.eegchan_numbers = s(:,1);
        stats.eegchans = {p.GND.chanlocs(stats.eegchan_numbers).labels};
        if isempty(stats.eegchans)
            uialert(h.figure, 'You have not selected any eeg channels!', 'Stats Error');
            return
        end
    else
        stats.eegchan_numbers = 1:length(p.GND.chanlocs);
        stats.eegchans = {p.GND.chanlocs.labels};
    end
end
myh = study_RunStats(p.GND, stats);
uiwait(myh);
callback_relfreshDisplay([],[],h,true)
       
%*************************************************************************
%function to handle when user changes the status of the "All Channel" option
function callback_toggleallchannel(hObject, event, h)

manual_select = ~event.Value;

h.list_channels.Enable = manual_select;
cur_selected = h.list_channels.Value;

%select all the regular channels
if ~manual_select
    d = h.list_channels.ItemsData;
    s = cell2mat(d');
    h.list_channels.Value = d((s(:,1)>0));
    h.list_channels.UserData = cur_selected;
else
    %restore previous selection
    cs = h.list_channels.UserData;
    if ~isempty(cs)
        h.list_channels.Value = cs;
    end
    
end

callback_ploterp([],[],h);

%**************************************************************************
%callback_reloadfiles - reloads the erp and study files and refreshes the
%erp display to reflect any changes.
function callback_relfreshDisplay(~, ~, h, reload_flag)

h.figure.Pointer = 'watch';
drawnow;

%get the current information from the figure userdata
p = h.figure.UserData;

%if there is an explicit request to reload - otherwise the displays will
%just be refreshed.  This allows the same code to be used to initialize the
%displays
if reload_flag      
    %update with the most recent data file and the most recent study file
    erp_filename =fullfile(p.GND.filepath, p.GND.filename);
    GND = wwu_LoadEEGFile(erp_filename);
%    load(erp_filename, '-mat');
    %calculate the within subject confidence interval
    GND = addWithinCI(GND);
    if isfield(GND, 'F_tests')
        if ~isempty(GND.F_tests)
            for ii = 1:length(GND.F_tests)
                if iscell(GND.F_tests(ii).used_tpt_ids)
                    GND.F_tests(ii).used_tpt_ids = cell2mat(GND.F_tests(ii).used_tpt_ids);
                end
            end
        end
    end

    p.GND = GND;
    
    study = study_LoadStudy(p.study.filename);
    p.study = study;
    
    h.figure.UserData = p;
    callback_ploterp({},{},h);
    %callback_toggleallchannel([],h.check_allchans,h);

end

cname = {p.GND.bin_info.bindesc};
h.list_condition.Items = cname;
h.list_condition.ItemsData = 1:length(cname);

chans = {p.GND.chanlocs.labels};
ch_data = zeros(length(chans),2);
ch_data(:,1) = 1:length(chans);

if isfield(p.study, 'chgroups')
if ~isempty(p.study.chgroups)
    groups = {p.study.chgroups.name};  %collect group names
    %data for the list box to identify that 1) these are channel groups and
    %2) what channel group was selected
    gr_data = zeros(length(p.study.chgroups),2);
    gr_data(:,2) = 1:length(p.study.chgroups);
    
    %combine with channel data
    chans = horzcat(groups, chans);
    ch_data = vertcat(gr_data,ch_data);
end
end
ch_data = mat2cell(ch_data, ones(1,length(ch_data)));

h.list_channels.Items = chans;
h.list_channels.ItemsData = ch_data;

%get the list of subjects to include
snames = horzcat('GRAND AVERAGE', p.GND.indiv_subnames);
h.list_subject.Items = snames;
h.list_subject.ItemsData = 0:length(snames);

%  populate the information about the mass univariate tests
if isfield(p.GND,'F_tests')
    if ~isempty(p.GND.F_tests)            
        disable = false;
        if ~isfield(p.GND, "F_test_names")
            n = arrayfun(@(x) join(x.factors), p.GND.F_tests);
            n = cellfun(@(x) strrep(x, ' ', ' X '), n, 'UniformOutput', false);
            t = num2cell(1:length(p.GND.F_tests));
            tn = cellfun(@num2str, t, 'un', 0);
            labels = strcat(tn, '. ', n);
        else
            labels = p.GND.F_test_names;
            
        end
        h.dropdown_MUtest.Items = labels;
        h.dropdown_MUtest.ItemsData = 1:length(p.GND.F_tests);
        
        callback_populateMUtestinfo([],[],h)

    else 
        disable = true;
    end
else
    disable = true;
end

if disable
    h.dropdown_MUtest.Items = {'No Mass Univ tests found'};
    h.dropdown_MUtest.Enable = false;
    
    h.dropdown_MUeffect.Items = {'No Mass Univ tests found'};
    h.dropdown_MUeffect.Enable = false;
    
    h.check_MUoverlay.Enable = false;
    delete(h.tree_massuniv.Children);
    h.tree_massuniv.Enable = false;
    
    
else
    h.dropdown_MUtest.Enable = true;
    h.dropdown_MUeffect.Enable = true;
    h.check_MUoverlay.Enable = true;
    h.tree_massuniv.Enable = true;
end

%populate the information about the ANOVA tests
if isfield(p.GND,'ANOVA')
    if ~isempty(p.GND.ANOVA)
        disable = false;
         n = arrayfun(@(x) join({x.factors.Factor}), p.GND.ANOVA);
         n = cellfun(@(x) strrep(x, ' ', ' X '), n, 'UniformOutput', false);

        if ~isfield(p.GND.ANOVA, 'name')
            for ii = 1:length(n)
                p.GND.ANOVA(ii).name = n{ii};
            end
        else
            missing = find(arrayfun(@(x) isempty(x.name), p.GND.ANOVA));
            for ii = missing
                p.GND.ANOVA(ii).name = n{ii};
            end
        end
        n = arrayfun(@(x) join(x.name), p.GND.ANOVA, 'UniformOutput',false);
        t = num2cell(1:length(p.GND.ANOVA));
        tn = cellfun(@num2str, t, 'un', 0);
        labels = strcat(tn,'. ',  n);
    
        h.dropdown_ANOVAtest.Items = labels;
        h.dropdown_ANOVAtest.ItemsData = 1:length(p.GND.ANOVA);
        
        callback_populateANOVAtestinfo([],[],h)
    else 
        disable = true;
    end
else
    disable = true;
end
if disable
    h.dropdown_ANOVAtest.Items = {'No ANOVA results found'};
    h.dropdown_ANOVAtest.Enable = false;
        
    delete(h.tree_ANOVA.Children);
    h.tree_ANOVA.Enable = false;
else
    h.dropdown_ANOVAtest.Enable = true;
    h.tree_ANOVA.Enable = true;
end

h.figure.Pointer = 'arrow';

%**************************************************************************
function callback_populateANOVAtestinfo(hObject, event, h)

p = h.figure.UserData;

    
tn = h.dropdown_ANOVAtest.Value;
r = p.GND.ANOVA(tn);
factors = {r.factors.Factor};
callback_togglePlotANOVAStyle(hObject, event, h);

delete(h.tree_ANOVA.Children);

n = uitreenode(h.tree_ANOVA, 'Text', sprintf('type:\t\t%s', r.type));
n = uitreenode(h.tree_ANOVA,...
    'Text', 'Conditions');
for ii = 1:length(r.conditions)
    uitreenode(n,...
        'Text', r.conditions{ii});
end

%add the number of levels after each factor name
n = uitreenode(h.tree_ANOVA,...
    'Text', 'Factors');
for ii = 1:length(factors)
    uitreenode('Parent',n,...
        'Text', sprintf('%s', factors{ii}));
end

n = uitreenode(h.tree_ANOVA,...
    'Text', sprintf('mean window:\t\tYes'));

n = uitreenode(h.tree_ANOVA,...
    'Text', sprintf('Time Window'));

uitreenode(n,'Text', sprintf('Start:\t%3.2f ms. (sample: #%i)', r.timewindow(1), r.pntwindow(1)));
uitreenode(n,'Text', sprintf('End:\t\t%3.2f ms. (sample: #%i)', r.timewindow(2), r.pntwindow(2)));

n = uitreenode(h.tree_ANOVA,...
    'Text', sprintf('Channels Included'));
for ii = 1:length(r.chans_used)
    uitreenode('parent', n,...
        'Text', sprintf('%i. %s', ii,r.chans_used{ii}));
end

%**************************************************************************
function callback_populateMUtestinfo(hObject, event, h)


p = h.figure.UserData;

    
tn = h.dropdown_MUtest.Value;
r = p.GND.F_tests(tn);

%add the possible effects
if isstruct(r.F_obs)
    h.dropdown_MUeffect.Items = fieldnames(r.F_obs);
else
    h.dropdown_MUeffect.Items = {'Difference between 2 means'};
end

delete(h.tree_massuniv.Children);
n = uitreenode(h.tree_massuniv,...
    'Text', 'Conditions');
for ii = 1:length(r.bins)
    uitreenode(n,...
        'Text', sprintf('%i. %s', ii, p.GND.bin_info(r.bins(ii)).bindesc));
end

%add the number of levels after each factor name
n = uitreenode(h.tree_massuniv,...
    'Text', 'Factors');
for ii = 1:length(r.factors)
    uitreenode('Parent',n,...
        'Text', sprintf('%s (%i)', r.factors{ii}, r.factor_levels(ii)));
end

n = uitreenode(h.tree_massuniv,...
    'Text', sprintf('Participants(n):\t%i', r.group_n));

n = uitreenode(h.tree_massuniv,...
    'Text', sprintf('Alpha:\t\t\t%0.3g', r.desired_alphaORq));

n = uitreenode(h.tree_massuniv,...
    'Text', sprintf('Method:\t\t%s', r.mult_comp_method));

n = uitreenode(h.tree_massuniv,...
    'Text', sprintf('permutations:\t\t%i', r.n_perm));

n = uitreenode(h.tree_massuniv,...
    'Text', sprintf('mean window:\t\t%s', r.mean_wind));

n = uitreenode(h.tree_massuniv,...
    'Text', sprintf('Time Window'));
uitreenode(n,'Text', sprintf('Start:\t%3.2f ms. (sample: #%i)', r.time_wind(1), r.used_tpt_ids(1)));
uitreenode(n,'Text', sprintf('End:\t\t%3.2f ms. (sample: #%i)', r.time_wind(2), r.used_tpt_ids(end)));

n = uitreenode(h.tree_massuniv,...
    'Text', sprintf('Channels Included'));
for ii = 1:length(r.include_chans)
    uitreenode('parent', n,...
        'Text', sprintf('%i. %s', r.used_chan_ids(ii), p.GND.chanlocs(r.used_chan_ids(ii)).labels));
end

if h.check_MUoverlay.Value
    callback_ploterp([],[],h);
end

%**************************************************************************
function callback_changestatselection(hObject, event, h);

if h.check_MUoverlay.Value
    callback_ploterp([],[],h);
end
%**************************************************************************
function callback_handlekeyevents(hObject, event, h)

switch event.Key
    case {'rightarrow', 'leftarrow'}
    c = h.axis_erp.UserData;
    
    if contains(event.Key, 'right')
        new_t = c.cursor(c.currentcursor).time + c.mincursorstep;
    else
        new_t = c.cursor(c.currentcursor).time - c.mincursorstep;
    end   
    if new_t >= c.mincursorpos && new_t <= c.maxcursorpos
        c.cursor(c.currentcursor) = update_cursor_position(c.cursor(c.currentcursor), new_t);
        h.axis_erp.UserData = c;
        plot_topos(h);
    end
end
        
%**************************************************************************
%main function for handling mouse events that select and control the cursors
function callback_handlemouseevents(hObject, event,h)

%button types are:
%   normal  -   left mouseclick
%   alt     -   right mouse button OR control & left button
%   extend  -   shift & either button
btype = h.figure.SelectionType;

%get the current data from the figure
c = h.axis_erp.UserData;

%leave if there are no cursors and if any other mouse button combos occur
%the latter will change as funcitonality is added
if isempty(c.cursor) || ~contains(btype, 'normal'); return; end


%get the current cursor informatino from the plot
cp = h.axis_erp.CurrentPoint;
%get the axis limits
xl = h.axis_erp.XLim;
yl = h.axis_erp.YLim;

%check to see if the mouse points is in the plot area
if cp(1,1) < xl(1) || cp(1,1) > xl(2) || cp(1,2) < yl(1) || cp(1,2) > yl(2)
    return
end

switch event.EventName
    
    case 'WindowMousePress'
        c.dragging = true;
        h.axis_erp.UserData = c; %save the cursor before making more calls to functinos that load cursor data.
        new_cursor = has_clicked_on_cursor(cp, c.cursor);
        if new_cursor > 0
            c = switch_cursors(c, new_cursor);
        end
        c.cursor(c.currentcursor) = update_cursor_position(c.cursor(c.currentcursor), cp(1), c.mincursorstep);
        h.axis_erp.UserData = c; %save it again to update the cursor
        
    case 'WindowMouseRelease'
        c.dragging = false;
        h.axis_erp.UserData = c;
        plot_topos(h);
        
    case 'WindowMouseMotion'
        if c.dragging
            xl = h.axis_erp.XLim;
            if cp(1) >= xl(1) && cp(2) <= xl(2) %out of range
                c.cursor(c.currentcursor) = update_cursor_position(c.cursor(c.currentcursor), cp(1), c.mincursorstep);
                h.axis_erp.UserData = c;              
            end
        end
        
end
%**************************************************************************
%check to see if the location clicked in the plot window is on an existing
%cursor
function cursor_num = has_clicked_on_cursor(mouse_location, cursor)

for ii = 1:length(cursor)
    if (isinterior(cursor(ii).polygon.Shape, mouse_location(1,1), mouse_location(1,2)))>0
        cursor_num = ii;
        return
    end
end
cursor_num = 0;

%**************************************************************************
%move the cursor to a new position defined by the current x and y locaiton
%of the mouse pointer in the plot window
function cursor = update_cursor_position(cursor, new_time, samp_interval)


%a sample interval has been included so make sure the cursor is a
%multiple of that interval
if nargin > 2
    new_time = samp_interval * floor(new_time/samp_interval);
end
cursor.time = new_time;
curr_loc = cursor.polygon.Shape.Vertices(1,1);
delta_loc = new_time - curr_loc;
cursor.polygon.Shape.Vertices(:,1) = cursor.polygon.Shape.Vertices(:,1) + delta_loc;

%*************************************************************************
%manage events from the cursor menus.  Includes adding and remvoving
%cursors
function callback_managecursors(hObject, event, h)

%store cursor informaiton in the axis UserData
c = h.axis_erp.UserData;
p = h.figure.UserData;

switch(event.Source.Tag)
    case 'add'
        if isempty(c.cursor)
            enum = 1;
        else
            enum = length(c.cursor) + 1;
        end
        
        c.cursor(enum).time = h.axis_erp.XLim(2)/2;
        c.cursor(enum).width = 10;
        c.cursor(enum).open = false;
        c.cursor(enum).polygon = build_cursor(c.cursor(enum), h);
        c.mincursorstep = 1/p.GND.srate * 1000;
        c.maxcursorpos = p.GND.time_pts(end);
        c.mincursorpos = p.GND.time_pts(1);
        c = switch_cursors(c, enum);
        
        
        
    case 'subtract' %remove the current cursor
        if isempty(c.cursor) %nothing to delete
            return
        end
        
        delete(c.cursor(c.currentcursor).polygon);
        c.cursor(c.currentcursor) = [];
        c.currentcursor = []; %set thh current cursor to nothing so the switch cursor routine ignores teh deleted cursor
     
        c = switch_cursors(c, 1);       
end

h.axis_erp.UserData = c;
plot_topos(h)

%**************************************************************************
%rebuild all existing cursors when the plot changes
function rebuild_cursors(h)

c = h.axis_erp.UserData;
cnum = length(c.cursor);
if cnum < 1
    return
end

for ii = 1:cnum
    c.cursor(ii).polygon = build_cursor(c.cursor(ii), h);
end

h.axis_erp.UserData = c;

%**************************************************************************
%build a cursor based on the size of the current plotting window
function pg = build_cursor(cursor, h)

clr = h.axis_erp.XColor;
%draw the cursor
rect_x = [cursor.time-.5, cursor.time+.5,cursor.time+.5,...
    cursor.time+2.5,cursor.time+2.5,...
    cursor.time-2.5,cursor.time-2.5,...
    cursor.time-.5, cursor.time-.5];

yl = h.axis_erp.YLim;
yr = .05 * range(yl);
rect_y = [yl(2),yl(2),yl(1)+yr, yl(1)+yr, yl(1), yl(1), yl(1)+yr, yl(1)+yr, yl(2)];

ps = polyshape(rect_x, rect_y);
hold(h.axis_erp, 'on');
pg = plot(h.axis_erp, ps,  'FaceColor', clr, 'FaceAlpha', .5, 'EdgeColor', clr, 'EdgeAlpha', 1);
pg.Annotation.LegendInformation.IconDisplayStyle = 'off';
h.axis_erp.YLim = yl;
hold(h.axis_erp, 'off');

%**************************************************************************
function r = range(x)

r = max(x) - min(x);
%*************************************************************************
%switch between current cursors
function cinfo = switch_cursors(cinfo, new_cnum)

if ~isempty(cinfo.currentcursor)
    cinfo.cursor(cinfo.currentcursor).polygon.LineWidth = .5;
end
if ~isempty(new_cnum) && ~isempty(cinfo.cursor)
    cinfo.cursor(new_cnum).polygon.LineWidth = 1;
    cinfo.currentcursor = new_cnum;
end

%**************************************************************************

%**************************************************************************
function GND = addWithinCI(GND)
    %calculate the 95% confidence interval so that can be used instead of
    %the standard error across subject
    
    nS = size(GND.indiv_erps, 4);
    nC = size(GND.indiv_erps, 3); 
    sMean = mean(GND.indiv_erps, 3); %mean within subject
    gMean = mean(sMean, 4); %grand mean across subject
    sMean = repmat(sMean, 1, 1, nC, 1);
    gMean = repmat(gMean, 1, 1, nC, nS);
    normMean = GND.indiv_erps - sMean + gMean;
    normSD = squeeze(std(normMean, 0,4)); %new SD across subjects
    %this is the standard error within
    GND.grands_within_CI = normSD/sqrt(nS) * sqrt(nC/(nC-1));
    %this is the 95% confidence interval within
    %GND.grands_within_CI = tinv(.975, nS-1) * normSD / sqrt(nS) * sqrt(nC/(nC-1));

%**************************************************************************
function [d,se, s, p,labels_or_times, ch_out, cond_sel, fixedScale] = getdatatoplot(study, GND, h, cursors, aveBetween)

d = []; se = [];
labels_or_times = [];
ch_out = [];
cond_sel = [];
fixedScale = [];
s = [];
p = [];
gfp = [];


%if cursor information is passed we will send back only the information
%specific to the time of each cursor, otherwise the entire time series will
%be returned.
if nargin < 4
    mapping_mode = false;
    aveBetween = false;
elseif isempty(cursors)
    return
else
    mapping_mode = true;
end

%get the conditions, channels and subject to plot from the listboxes
cond_sel = h.list_condition.Value;
ch = cell2mat(h.list_channels.Value');
sbj = h.list_subject.Value;

%check to see if the user wants to plot mass_univariate statistics
mass_univ_overlay = h.check_MUoverlay.Value;

%get the channels from the selected conditions
ch_sel = ch(find(ch(:,1)),1);
ch_out = ch_sel;    %send this back to the calling function

if mapping_mode
    [~,pt] = arrayfun(@(a) min(abs(a-GND.time_pts)), sort([cursors.time]));
    ch_sel = 1:length(GND.chanlocs); %overwrite channel selection if we are mapping
    plot_GFP = false;
else
    pt =1:length(GND.time_pts); %get all the points 
    plot_GFP = h.menu_GFP.Checked;  %allow the user to choose
end


%get the statistics to plot if desired
if mass_univ_overlay
    if isempty(GND.F_tests)
        r = [];
    else
        r = GND.F_tests(h.dropdown_MUtest.Value);   %get the desired results
    end
    if isempty(r)   %if for some reason there is no data
        s = [];
        mass_univ_overlay = false;
    else
        effect_name = h.dropdown_MUeffect.Value;    %this is the specific condition to show
    
        if isstruct(r.adj_pval)
            %try getting the cluster number here so we can plot clusters in
            %different colors
            adj_pval = r.adj_pval.(effect_name);
            F_obs = r.F_obs.(effect_name);
        else
            adj_pval = r.adj_pval;
            F_obs = r.F_obs;
        end

        if ~isstruct(r.clust_info)
            sig_clust = zeros(size(adj_pval));
        elseif ~isfield(r.clust_info, effect_name)
            sig_clust_nums = find(r.clust_info.null_test);
            sig_clust = zeros(size(r.clust_info.clust_ids));
            for sc = 1:length(sig_clust_nums)
                sig_clust(r.clust_info.clust_ids == sig_clust_nums(sc)) = sc;
            end
        else
            sig_clust_nums = find(r.clust_info.(effect_name).null_test);
            %now get the cluster positions
            %first initalize to zero
            sig_clust = zeros(size(r.clust_info.(effect_name).clust_ids));
            %then loop through each significant cluster and assign a number to
            %the sig cluster array
            for sc = 1:length(sig_clust_nums)
                sig_clust(r.clust_info.(effect_name).clust_ids == sig_clust_nums(sc)) = sc;
            end
        end

    end
end

%it is possible that no channels are selected because just the channel
%groups can be selected
if ~isempty(ch_sel)
    if sbj==0 %this is the grand average
        if aveBetween
            d = mean(GND.grands(ch_sel,pt(1):pt(2),cond_sel),2);
        else
            d = GND.grands(ch_sel,pt,cond_sel);
            se = GND.grands_within_CI(ch_sel, pt, cond_sel);
            %se = GND.grands_stder(ch_sel, pt, cond_sel);
        end
        fixedScale = max(max(max(GND.grands(ch_sel,:,cond_sel))));

        %get the statistics information
        if mass_univ_overlay            
            %initialize the array to the full size of the data
             stat = zeros(size(GND.grands,1), size(GND.grands,2));
             pstat = stat;
             pval = adj_pval<r.desired_alphaORq;
             fval = F_obs;
            if contains(r.mean_wind, 'yes')
                fval = repmat(fval, 1, length(r.used_tpt_ids));
                pval = repmat(pval, 1, length(r.used_tpt_ids));
            end
            stat(r.used_chan_ids,r.used_tpt_ids) = fval; %fill the relevant portion of the  matrix    
            pstat(r.used_chan_ids, r.used_tpt_ids) = pval;
            if aveBetween
                s = mean(stat(ch_sel,pt(1):pt(2)),2);
                p = mean(pstat(ch_sel,pt(1):pt(2)),2);
            else
                s = stat(ch_sel, pt); %select the part the user requested
                p = pstat(ch_sel,pt);
            end            
        end 
    else
        if aveBetween
            d = mean(GND.indiv_erps(ch_sel, pt(1):pt(2),cond_sel,sbj),2);
        else
            d = GND.indiv_erps(ch_sel, pt, cond_sel, sbj);
        end
        fixedScale = max(max(max(GND.indiv_erps(ch_sel, :,cond_sel, sbj))));
        %no stats information for individual subject data
    end    
    if mapping_mode
        labels_or_times = sort([cursors.time]);
    else
        labels_or_times = {GND.chanlocs(ch_sel).labels};
    end
end

%now get the channel group information 
ch_groups = ch(find(ch(:,2)),2);

%dont do this part if either there are no channel groups selected or this
%function was called from the plot_topo function
if ~isempty(ch_groups) && ~mapping_mode
    %get the means of any channel groups
    ch_group_data = zeros(length(ch_groups), length(GND.time_pts), length(cond_sel));
    se = ch_group_data;
    ch_group_s = zeros(length(ch_groups), length(GND.time_pts));
    for ii = 1:length(ch_groups)
        for jj = 1:length(cond_sel)
            if sbj == 0
                ch_group_data(ii,pt,jj) = squeeze(mean(GND.grands(study.chgroups(ch_groups(ii)).chans,:,cond_sel(jj)),1));
                %get the std error averaged across the channels in the group 
                se(ii,pt,jj) = squeeze(mean(GND.grands_within_CI(study.chgroups(ch_groups(ii)).chans,:,cond_sel(jj)),1));
                %se(ii,pt,jj) = squeeze(mean(GND.grands_stder(study.chgroups(ch_groups(ii)).chans,:,cond_sel(jj)),1));
                if mass_univ_overlay && ~mapping_mode %mapping data for these channels is not valid
                    %again - initialize the array to the full size of the data
                    stat = zeros(size(GND.grands,1), size(GND.grands,2));
                    pval = adj_pval<r.desired_alphaORq;
                    if contains(r.mean_wind, 'yes')
                        %under this condition the pval will only be a
                        %single column
                        pval = repmat(pval, 1, length(r.used_tpt_ids));
                    end
                    
                    %provde a thresholded version of the F-scores for mapping
                    %in future there will be an option to turn this on and off
                 
                    stat(r.used_chan_ids,r.used_tpt_ids) = pval; %fill the relevant portion of the  matrix
                    all_chan_s = stat(study.chgroups(ch_groups(ii)).chans, :); %select the channels in the group
                    ch_group_s(ii,pt) = max(all_chan_s,[],1); %this will indicate signficance if the timepoint was significant on any of the channels
                end
            else
                ch_group_data(ii,pt,jj) = squeeze(mean(GND.indiv_erps(study.chgroups(ch_groups(ii)).chans,:,cond_sel(jj), sbj),1));
            end
        end
    end
    
    %put it all together if both channel group and channel information
    %exist
    if ~isempty(ch_sel)
        d = cat(1, ch_group_data, d); 
        labels_or_times = horzcat({study.chgroups(ch_groups).name}, labels_or_times);
    else
        d = ch_group_data;
        labels_or_times = {study.chgroups(ch_groups).name};
    end
    %now add the statistical information if needed
    if mass_univ_overlay
        if ~isempty(ch_sel)
            s = cat(1, ch_group_s, s);
        else
            s = ch_group_s;
        end
    end
end
%last thing to do is add the global field power to the end
if plot_GFP
    %calculate the global field power
    if sbj == 0
        gfp = std(GND.grands(:,:,cond_sel),0,1);
    else
        gfp = GND.indiv_erps(ch_sel, pt, cond_sel, sbj);
    end

    d = cat(1, d, gfp);
    labels_or_times(end + 1) = {'GFP'}; 
 end

%************************************************************************
% plot the topographic maps indicated by the active cursors
function plot_topos(h)

%set the resolution of the map
gridscale = 32;
for ii = 1:4
    if h.menu_mapquality(ii).Checked
        gridscale = gridscale * ii;
        break
    end
end
averageBetweenCursors = h.menu_cursormean.Checked;
%get map plotting options
for ii = 1:3
    if h.menu_mapscale(ii).Checked
        scale_option = ii;
        break
    end
end
has_stat = false;  %assume there are no stats
c = h.axis_erp.UserData;
p = h.figure.UserData;
my_h = h.panel_topo.UserData; %get handles to the subplots
bColor = h.panel_topo.BackgroundColor;
n_maps = length(c.cursor);
if averageBetweenCursors
    if n_maps ~= 2
        warning('Averaging between cursors only works when 2 cursors are available. You have %i.  Ignoring this option', n_maps)
        averageBetweenCursors = false;
    else
        n_maps = 1;
    end
end
[d, ~,s, pv,map_time, ch_out, cond_num, fixedScale] = getdatatoplot(p.study, p.GND, h, c.cursor, averageBetweenCursors);
if scale_option ==1
    map_scale = max(max(max(abs(d)))); 
elseif scale_option == 3 %fixed scale
    map_scale = fixedScale;
end
if ~isempty(s)
    d(:,:,end+1) = s;
    has_stat = true;
end
%n_maps = 1; %temporary while i work out averaging between cursors
if n_maps < 1
    ch = h.panel_topo.Children;
    delete(ch);
    return
end
%there are three possible states here
%the first is when there is only one condition being display
comp_conds = true; %flag indicating a comparison of conditions
n_conds = size(d,3); %the number of conditions
total_maps = n_conds * n_maps;  %total maps to display
if n_conds==1 || (n_conds>1 && n_maps==1)
    max_cols = 5 ;
    nrows = ceil(total_maps/max_cols);
    ncols = ceil(total_maps/nrows);    
    if size(d,3)==1; comp_conds = false; end
else 
    max_cols = size(d,3);
    ncols = max_cols;
    nrows = n_maps;
end
pcount = 0;
%delete any unused axes
for ii = length(my_h):-1:total_maps+1
    delete(my_h(ii));
    my_h(ii) = [];
end
%delete the colorbars
cb_h = findobj(h.panel_topo, 'Type', 'Colorbar');
if ~isempty(cb_h)
    delete(cb_h);
end
msize = 5; %markersize for displaying the channels displayed
for ii = 1:n_maps
    for jj = 1:n_conds %this will be for comparing conditions        
        pcount = pcount + 1;
        v = d(:,ii,jj);
        if scale_option ==2; map_scale = max(abs(v)); end
           
        if pcount <= length(my_h)
            my_h(pcount) = subplot(nrows, ncols, pcount, 'Parent', h.panel_topo);
        else
            if isempty(my_h)
                my_h = subplot(nrows, ncols, pcount,'Parent', h.panel_topo);
                my_h.Toolbar.Visible = 'off';
            else
                my_h(pcount) = subplot(nrows, ncols, pcount,'Parent', h.panel_topo);
                my_h(pcount).Toolbar.Visible = 'off';
            end
        end     
        cla(my_h(pcount));
        eval_string = [];
        if jj==n_conds && has_stat %this is the statistical map
            ms = [0,max(max(d(:,:,n_conds))) * .8];
            %ms = [0,max(abs(v))];
            if ms(2)==0; ms(2) = 1; end %just in case there are no stat sig results
            title_string = 'F-score';
            cmap = feval(p.study.Render.Map.StatPalette);
            eval_string = '''conv'', ''off''';
            extraChans = find(pv(:,ii));
        else
            ms = [-map_scale; map_scale];
            title_string =  h.list_condition.Items{cond_num(jj)};
            cmap = feval(p.study.Render.Map.Palette);
            extraChans = ch_out;
        end
        
        %build the command string for the topoplot'
        mapstring = ['wwu_topoplot(v, p.GND.chanlocs, ''axishandle'', my_h(pcount),''colormap'', cmap, ''maplimits'', ms, ' ...
            '''style'', ''map'', ''numcontour'', 0, ''gridscale'', gridscale, ''backcolor'' , bColor'];
        
        %change it based on the different options
        if length(extraChans) < length(p.GND.chanlocs)
            mapstring = [mapstring, ',  ''emarker2'', {extraChans, ''o'', ''k'', msize, 1}'];
        end
        if ~isempty(eval_string)
            mapstring = [mapstring, ', ', eval_string, ');'];
        else
            mapstring = [mapstring, ');'];
        end
       
        %evaluate the command string
        eval(mapstring)
        if scale_option == 2 
            colorbar(my_h(pcount));
        elseif jj==n_conds && has_stat 
            cb = colorbar(my_h(pcount));
            cb.Units = 'normalized';       
            cb.Position(1) = my_h(pcount).Position(1) + my_h(pcount).Position(3);
            cb.Label.String = 'F-score';
            cb.Color = h.axis_erp.XColor;
        end
        
        if ii==1  && comp_conds
            my_h(pcount).Title.String = title_string;
            my_h(pcount).Title.Interpreter = 'none';
            my_h(pcount).Title.Color = h.axis_erp.XColor;
        end
        if averageBetweenCursors
            my_h(pcount).XLabel.String = sprintf('%5.1f-%5.1f ms', map_time(1),map_time(2));
        else
            my_h(pcount).XLabel.String = sprintf('%5.1f ms', map_time(ii) );
        end
        my_h(pcount).XLabel.Visible = true;
        my_h(pcount).XLabel.Color = h.axis_erp.XColor;     
    end
end

if scale_option ~=2
    ht = h.panel_topo.Position(4); 
    cb = colorbar(my_h(1));
    cb.Units = 'pixels';
    cb.Position = [40, 20, 16, ht-40];
    cb.Label.String = '\muV';
    cb.Color = h.axis_erp.XColor;
end


h.panel_topo.UserData = my_h;
drawnow nocallbacks

%***************************************************************************
%main erp drawing function
function callback_ploterp(~, ~, h)

stacked = h.menu_stack.Checked;
userScale = ~h.menu_autoscale.Checked;
SEoverlay = h.menu_stderr.Checked;
MUoverlay = h.check_MUoverlay.Value;
separation = h.spinner_distance.Value/100;
lwidth = h.spinner_lwidth.Value;
mnTime = h.spinner_mintime.Value;
mxTime = h.spinner_maxtime.Value;
mnAmp = h.spinner_minamp.Value;
mxAmp = h.spinner_maxamp.Value;
ANOVAStyle = h.check_plotANOVAStyle.Value;


p = h.figure.UserData;
[d, se,~, s,labels,~,cond_sel, ~] = getdatatoplot(p.study, p.GND, h);

%can't plot it if it is not there!
if isempty(d)
    return
end

%if the user has selected the button to display ERP traces as a function
%of the conditions in a stats test.
if ANOVAStyle
    styleMatrix = h.check_plotANOVAStyle.UserData;
    stacked = false;  
    statInfo = p.GND.ANOVA(h.dropdown_ANOVAtest.Value);
    statRange = statInfo.timewindow; 
end
%preallocate for the legend names
%I am not preallocating for the line structures because I am lazy
legend_names = cell(1,size(d,3));
legend_handles = [];

% if the user has selected the butter fly plot option where 
% are stacked on the same origin.
if ~stacked  && size(d, 1) > 1
    if userScale 
         spread_amnt = max(abs([mnAmp, mxAmp])) * separation;   %get the plotting scale    
    else
        spread_amnt = max(max(max(abs(d)))) * separation;   %get the plotting scale
    end
    v = size(d,1):-1:1;
    spread_matrix = repmat(v' * spread_amnt, 1, size(d,2), size(d,3));
    d = d + spread_matrix;
end

%main plotting loop - plot the time series for each condition
cla(h.axis_erp);
hold(h.axis_erp, 'on');
for ii = 1:size(d,3)
    %assign colors and styles to allow user to better figure out which
    %trace is from which condition - requires statistical information
    if ANOVAStyle
        nFactor = width(styleMatrix)-1;
        n = h.list_condition.Items{cond_sel(ii)};
        indx = matches(styleMatrix.condition, n);
        if sum(indx) == 0
            continue
        end
        styleColumn = table2cell(styleMatrix(indx,:));
        pColor = p.study.Render.ERP.Palette(styleColumn{1}, :);
        if nFactor < 2
            pStyle = '-';
        else
            pStyle = p.ts_style{styleColumn{2}};
        end
    else
       pColor = p.study.Render.ERP.Palette(ii,:);
       pStyle = '-';
    end
    dd = squeeze(d(:,:,ii));

    %plot the statistics
    if MUoverlay && ~isempty(s)
        hold(h.axis_erp, 'on');
        tt = repmat(p.GND.time_pts, size(s,1),1);        
        splot = scatter(h.axis_erp, tt(s>0)', dd(s>0)',60,'filled');
        splot.CData =  pColor;
    end

    %plot the standard error overlay
    if ~isempty(se) && SEoverlay
        for jj = 1:size(d,1)
        e = squeeze(se(jj,:,ii));
            xe = [p.GND.time_pts, fliplr(p.GND.time_pts)];
            ye = [dd(jj,:) + e, fliplr(dd(jj,:)-e)];
            er = patch(h.axis_erp,xe, ye,pColor);
            er.FaceColor = pColor;
            er.EdgeColor = 'None';
            er.FaceAlpha = .25;
        end
    end

    ph = plot(h.axis_erp, p.GND.time_pts, dd', 'Color',pColor,...
        'LineWidth', lwidth,...
        'LineStyle',pStyle);
    hold(h.axis_erp, 'on');
    for phi = 2:length(ph)
        ph(phi).Annotation.LegendInformation.IconDisplayStyle = 'off';
    end
    if matches(labels{end}, 'GFP')
        ph(end).LineWidth = ph(end).LineWidth + .5;
        ph(end).Color = [0,.8,0];
    end
    legend_handles(ii) = ph(1);
    legend_names(ii) = h.list_condition.Items(cond_sel(ii));
end
hold(h.axis_erp, 'off');    
%handle axes and scaling differently depending on whether the plot is
%stacked or not
if ~stacked && size(d, 1) > 1
    h.axis_erp.YLim = [min(min(min(d))) - (spread_amnt * .1), max(max(max(d))) + (spread_amnt * .1)];
    h.axis_erp.YTick = sort(spread_matrix(:,1));
    h.axis_erp.YTickLabel = labels(v);
    h.axis_erp.YLabel.String = 'microvolts x channel';
else
    if userScale 
        h.axis_erp.YLim = [mnAmp, mxAmp]; 
    else
        h.axis_erp.YLim = [min(min(min(d))) * 1.1, max(max(max(d))) * 1.1];
    end
    l = line(h.axis_erp, h.axis_erp.XLim, [0,0],...
        'Color', [.5,.5,.5], 'LineWidth', 1.5);
    l.Annotation.LegendInformation.IconDisplayStyle = 'off';    
    h.axis_erp.YTickMode = 'auto';
    h.axis_erp.YTickLabelMode = 'auto';
    h.axis_erp.YLabel.String = 'microvolts';        
end
h.axis_erp.XGrid = 'on'; h.axis_erp.YGrid = 'on';
h.axis_erp.XLim = [mnTime, mxTime];
h.axis_erp.XLabel.String = 'Time (ms)';
h.axis_erp.YDir = 'normal';
h.axis_erp.FontSize = 14;


%draw a vertical line at 0 ms;
time_lock_ms = min(abs(p.GND.time_pts));
l = line(h.axis_erp, [time_lock_ms, time_lock_ms], h.axis_erp.YLim,...
    'Color', [.5,.5,.5], 'LineWidth', 1.5);
l.Annotation.LegendInformation.IconDisplayStyle = 'off';

if ANOVAStyle
    %draw a shaded region around where the stats were done
    yr = h.axis_erp.YLim;
    rgn = patch(h.axis_erp, ...
        [statRange(1),statRange(2),statRange(2),statRange(1),statRange(1)],...
        [yr(1), yr(1), yr(2), yr(2), yr(1)],...
        [.5,.5,.5], 'FaceAlpha', .25,...
        'EdgeColor', 'none');
    uistack(rgn,"bottom");
end
if length(legend_names) > 6
    legend_columns = 6;
else
    legend_columns = length(legend_names);
end
lg = legend(h.axis_erp, legend_handles, legend_names, 'box', 'off', 'Location', 'NorthOutside', 'NumColumns', legend_columns,'Interpreter', 'none');
lg.Color ='none';
lg.TextColor = h.axis_erp.XColor;
lg.LineWidth = 2;
lg.FontSize = 14;

%rebuild and plot existing cursors to fit the currently scaled data
rebuild_cursors(h)
plot_topos(h)
% *************************************************************************
function callback_togglestatspanel(hObject, ~, h)
    currentTab = str2double(hObject.Tag);
    for ii = 1:3
        h.tab_stats(ii).Visible = false;
    end
    h.tab_stats(currentTab).Visible = true;
%%
% ************************************************************************
function initialize_gui(handles, GND)

handles.spinner_mintime.Value = GND.time_pts(1);
handles.spinner_mintime.Limits = [GND.time_pts(1), GND.time_pts(end)];
handles.spinner_mintime.Step = diff(GND.time_pts(1:2));
   
handles.spinner_maxtime.Value = GND.time_pts(end);
handles.spinner_maxtime.Limits = [GND.time_pts(1), GND.time_pts(end)];
handles.spinner_maxtime.Step = diff(GND.time_pts(1:2));

handles.edit_massunivstart.Limits = [GND.time_pts(1), GND.time_pts(end)];
handles.edit_massunivstart.Value = GND.time_pts(1);

handles.edit_massunivend.Limits = [GND.time_pts(1), GND.time_pts(end)];
handles.edit_massunivend.Value = GND.time_pts(end);

%**************************************************************************
function handles = assign_callbacks(handles)
%assign callbacks to the uicontrols and menu items
handles.figure.WindowButtonDownFcn = {@callback_handlemouseevents, handles};
handles.figure.WindowButtonUpFcn = {@callback_handlemouseevents, handles};
handles.figure.WindowButtonMotionFcn = {@callback_handlemouseevents, handles};
handles.figure.WindowKeyPressFcn = {@callback_handlekeyevents, handles};

handles.spinner_distance.ValueChangedFcn = {@callback_ploterp, handles};
handles.spinner_lwidth.ValueChangedFcn = {@callback_ploterp, handles};
handles.spinner_mintime.ValueChangedFcn = {@callback_changePlotRange, handles};
handles.spinner_maxtime.ValueChangedFcn = {@callback_changePlotRange, handles};
handles.spinner_minamp.ValueChangedFcn = {@callback_changePlotRange, handles};
handles.spinner_maxamp.ValueChangedFcn = {@callback_changePlotRange, handles};

handles.list_condition.ValueChangedFcn = {@callback_ploterp, handles};
handles.check_allchans.ValueChangedFcn = {@callback_toggleallchannel, handles};
handles.list_channels.ValueChangedFcn = {@callback_ploterp, handles};
handles.list_subject.ValueChangedFcn = {@callback_ploterp, handles};

handles.button_factadd.ButtonPushedFcn = {@callback_changefactors, handles};
handles.button_factremove.ButtonPushedFcn = {@callback_changefactors, handles};
handles.dropdown_MUtype.ValueChangedFcn = {@callback_togglestatsoption, handles};
handles.button_massuniv.ButtonPushedFcn = {@callback_runstatstest, handles};


handles.check_MUoverlay.ValueChangedFcn = {@callback_ploterp, handles};
handles.dropdown_MUtest.ValueChangedFcn = {@callback_populateMUtestinfo, handles};
handles.dropdown_MUeffect.ValueChangedFcn = {@callback_changestatselection, handles};
handles.dropdown_ANOVAtest.ValueChangedFcn = {@callback_populateANOVAtestinfo, handles};
handles.button_plotANOVA.ButtonPushedFcn = {@callback_plotANOVAresult, handles};
handles.button_exportANOVA.ButtonPushedFcn = {@callback_plotANOVAresult, handles, true};
handles.check_plotANOVAStyle.ValueChangedFcn = {@callback_togglePlotANOVAStyle, handles};
%handles.dropdown_ANOVAtest.ValueChangedFcn = {@callback_togglePlotANOVAStyle, handles};


handles.menu_refresh.MenuSelectedFcn = {@callback_relfreshDisplay, handles, true};
handles.menu_conditions.MenuSelectedFcn = {@callback_removebinsandstats,handles};
handles.menu_stats.MenuSelectedFcn = {@callback_removebinsandstats,handles};
handles.menu_ANOVA.MenuSelectedFcn = {@callback_removebinsandstats, handles};
handles.menu_editcond.MenuSelectedFcn = {@callback_editconditions, handles};

handles.menu_stderr.MenuSelectedFcn = {@callback_toggleplotoption, handles};
handles.menu_stack.MenuSelectedFcn = {@callback_toggleplotoption, handles};
handles.menu_autoscale.MenuSelectedFcn = {@callback_toggleautoscale, handles};
handles.menu_GFP.MenuSelectedFcn = {@callback_toggleautoscale, handles};

handles.menu_cursoradd.MenuSelectedFcn = {@callback_managecursors, handles};
handles.menu_cursorsub.MenuSelectedFcn = {@callback_managecursors, handles};
handles.menu_cursormean.MenuSelectedFcn = {@callback_toggleAverageBetweenCursors, handles};

for ii = 1:4
    handles.menu_mapquality(ii).MenuSelectedFcn = {@callback_togglemapoption, handles};
end
for ii = 1:3
    handles.menu_mapscale(ii).MenuSelectedFcn = {@callback_toggletopomenustate, handles};
end
for ii = 1:3
    handles.button_statstab(ii).ButtonPushedFcn = {@callback_togglestatspanel, handles};
end
% *************************************************************************
% create the user interface
function handles = build_gui(handles)

%load the display scheme for this instance
scheme = eeg_LoadScheme;

%set some default parameters for window size
W = round(scheme.ScreenWidth * .6);
if scheme.ScreenHeight < 1080
    H = scheme.ScreenHeight;
else
    H = 1080;
end
figpos = [420, scheme.ScreenHeight - H, W, H];
handles.figure.Color = scheme.Window.BackgroundColor.Value;
handles.figure.Position = figpos;
handles.figure.NumberTitle = 'off';

%create a grid layout for organizing the interface
handles.gl = uigridlayout('Parent', handles.figure,...
    'ColumnWidth',{280, '1x'},...
    'RowHeight', {30, '1x','1x','1x', '1.5x'},...
    'BackgroundColor',scheme.Window.BackgroundColor.Value);
%create panels within those grids for holding ui controls.  Because the 
% figure takes time to size all the panels to their grid containers, it is 
% more efficient to create them all at once and then execute a single drawnow
% commaind than to create them in sequence and use several draw commands.
%panel for holding the topo plot
handles.panel_topo = uipanel(...
    'Parent', handles.gl,...
    'AutoResizeChildren', false,...
    'BorderType', 'none',...
    'BackgroundColor', scheme.Panel.BackgroundColor.Value,...
    'HighlightColor', scheme.Panel.BorderColor.Value,...
    'FontName',scheme.Panel.Font.Value,...
    'FontSize', scheme.Panel.FontSize.Value,...
    'ForegroundColor', scheme.Panel.FontColor.Value);
handles.panel_topo.Layout.Column = 2;
handles.panel_topo.Layout.Row = 5;
%panel for holding the uiaxis 
handles.panel_axes = uipanel(...
    'Parent', handles.gl,...
    'AutoResizeChildren', false,...
    'BorderType', 'none',...
    'Units', 'normalized',...
    'BackgroundColor', scheme.Panel.BackgroundColor.Value,...
    'HighlightColor', scheme.Panel.BorderColor.Value,...
    'FontName',scheme.Panel.Font.Value,...
    'FontSize', scheme.Panel.FontSize.Value,...
    'ForegroundColor', scheme.Panel.FontColor.Value);
handles.panel_axes.Layout.Column = 2;
handles.panel_axes.Layout.Row = [2 4];
%panel for holding the plotting options
handles.panel_plotopts = uipanel(...
    'Parent', handles.gl,...
    'BorderType', 'none',...
    'AutoResizeChildren', 'off',...
     'BackgroundColor', scheme.Panel.BackgroundColor.Value,...
    'HighlightColor', scheme.Panel.BorderColor.Value,...
    'FontName',scheme.Panel.Font.Value,...
    'FontSize', scheme.Panel.FontSize.Value,...
    'ForegroundColor', scheme.Panel.FontColor.Value);
handles.panel_plotopts.Layout.Column = 2;
handles.panel_plotopts.Layout.Row = 1;
handles.panel_po = uipanel('Parent', handles.gl,...
    'Title', 'Select Content to Plot',...
    'BackgroundColor', scheme.Panel.BackgroundColor.Value,...
    'HighlightColor', scheme.Panel.BorderColor.Value,...
    'FontName',scheme.Panel.Font.Value,...
    'FontSize', scheme.Panel.FontSize.Value,...
    'ForegroundColor', scheme.Panel.FontColor.Value,...
    'Scrollable', true);
handles.panel_po.Layout.Column = 1;
handles.panel_po.Layout.Row = [1 3];
%stats overlay panel
handles.panel_statoverlay = uipanel('Parent', handles.gl,...
    'Title', 'Plots and Overlays',...
    'Scrollable','on',...
    'BackgroundColor', scheme.Panel.BackgroundColor.Value,...
    'HighlightColor', scheme.Panel.BorderColor.Value,...
    'FontName',scheme.Panel.Font.Value,...
    'FontSize', scheme.Panel.FontSize.Value,...
    'ForegroundColor', scheme.Panel.FontColor.Value);
handles.panel_statoverlay.Layout.Column = 1;
handles.panel_statoverlay.Layout.Row = [4 5];
%update the figure so the sizes of objects will be accurate
drawnow nocallbacks
pause(.5)
%**************************************************************************
%now fill each panel
%start with the main plotting axis
handles.axis_erp = uiaxes(...
    'Parent', handles.panel_axes,...
    'Units', 'normalized',...
    'Interactions',[],...
    'OuterPosition',[0,0,1,1],...
    'Color', scheme.Axis.BackgroundColor.Value,...
    'XColor', scheme.Axis.AxisColor.Value,...
    'YColor',scheme.Axis.AxisColor.Value,...
    'FontName',scheme.Axis.Font.Value,...
    'FontSize', scheme.Axis.FontSize.Value);
%handles.axis_erp.Layout.Column = 2;
%handles.axis_erp.Layout.Row = [2 4];
handles.axis_erp.Toolbar.Visible = 'off';
handles.axis_erp.Title.Color = scheme.Axis.AxisColor.Value;
handles.axis_erp.Title.BackgroundColor = 'none';
%**************************************************************************
%Create a line plot options objects
uilabel('Parent', handles.panel_plotopts,...
    'Position', [0, 7, 60, 20],...
    'Text', 'Time limits',...
    'HorizontalAlignment','left',...
    'FontName', scheme.Label.Font.Value,...
    'FontSize', scheme.Label.FontSize.Value,...
    'FontColor', scheme.Label.FontColor.Value);
handles.spinner_mintime = uispinner(...
    'Parent', handles.panel_plotopts,...
    'Position', [60,7,100,20],...
    'RoundFractionalValues', 'off',...
    'ValueDisplayFormat', '%6.2f ms',...
    'Tag', 'mintime',...
    'BackgroundColor',scheme.Dropdown.BackgroundColor.Value,...
    'FontColor', scheme.Dropdown.FontColor.Value,...
    'FontName', scheme.Dropdown.Font.Value,...
    'FontSize', scheme.Dropdown.FontSize.Value);
uilabel('Parent', handles.panel_plotopts,...
    'Position', [160, 7, 20, 20],...
    'Text', 'to',...
    'HorizontalAlignment','center',...
    'FontName', scheme.Label.Font.Value,...
    'FontSize', scheme.Label.FontSize.Value,...
    'FontColor', scheme.Label.FontColor.Value);
handles.spinner_maxtime = uispinner(...
    'Parent', handles.panel_plotopts,...
    'Position', [180,7,100,20],...
    'RoundFractionalValues', 'off',...
    'ValueDisplayFormat', '%6.2f ms',...
    'Tag', 'maxtime',...    
    'BackgroundColor',scheme.Dropdown.BackgroundColor.Value,...
    'FontColor', scheme.Dropdown.FontColor.Value,...
    'FontName', scheme.Dropdown.Font.Value,...
    'FontSize', scheme.Dropdown.FontSize.Value);
uilabel('Parent', handles.panel_plotopts,...
    'Position', [290, 7, 60, 20],...
    'Text', 'Amp limits',...
    'HorizontalAlignment','left',...    
    'FontName', scheme.Label.Font.Value,...
    'FontSize', scheme.Label.FontSize.Value,...
    'FontColor', scheme.Label.FontColor.Value);
handles.spinner_minamp = uispinner(...
    'Parent', handles.panel_plotopts,...
    'Position', [350,7,80,20],...
    'Value', -5, ...
    'Limits', [-inf, 0],...
    'Step',.1,...
    'RoundFractionalValues', 'off',...
    'ValueDisplayFormat', '%3.1f uV',...
    'Tag', 'mintime', ...
    'Enable', false,...    
    'BackgroundColor',scheme.Dropdown.BackgroundColor.Value,...
    'FontColor', scheme.Dropdown.FontColor.Value,...
    'FontName', scheme.Dropdown.Font.Value,...
    'FontSize', scheme.Dropdown.FontSize.Value);
uilabel('Parent', handles.panel_plotopts,...
    'Position', [430, 7, 20, 20],...
    'Text', 'to',...
    'HorizontalAlignment','center',...
    'FontName', scheme.Label.Font.Value,...
    'FontSize', scheme.Label.FontSize.Value,...
    'FontColor', scheme.Label.FontColor.Value);
handles.spinner_maxamp = uispinner(...
    'Parent', handles.panel_plotopts,...
    'Position', [450,7,80,20],...
    'Value', 5, ...
    'Limits', [0, inf],...
    'Step',.1,...
    'RoundFractionalValues', 'off',...
    'ValueDisplayFormat', '%3.1f uV',...
    'Tag', 'maxtime', ...
    'Enable', false,...
    'BackgroundColor',scheme.Dropdown.BackgroundColor.Value,...
    'FontColor', scheme.Dropdown.FontColor.Value,...
    'FontName', scheme.Dropdown.Font.Value,...
    'FontSize', scheme.Dropdown.FontSize.Value);
uilabel('Parent', handles.panel_plotopts,...
    'Position', [540, 7, 80, 20],...
    'Text', 'Stack Dist.',...
    'HorizontalAlignment','Left',...    
    'FontName', scheme.Label.Font.Value,...
    'FontSize', scheme.Label.FontSize.Value,...
    'FontColor', scheme.Label.FontColor.Value);
handles.spinner_distance = uispinner(...
    'Parent', handles.panel_plotopts,...
    'Position', [600,7,70,20],...
    'Value', 100, ...
    'Limits', [1, inf],...
    'RoundFractionalValues', 'on',...
    'ValueDisplayFormat', '%i %%',...
    'BackgroundColor',scheme.Dropdown.BackgroundColor.Value,...
    'FontColor', scheme.Dropdown.FontColor.Value,...
    'FontName', scheme.Dropdown.Font.Value,...
    'FontSize', scheme.Dropdown.FontSize.Value);
uilabel('Parent', handles.panel_plotopts,...
    'Position', [680, 7, 80, 20],...
    'Text', 'Line width',...
    'HorizontalAlignment','Left',...    
    'FontName', scheme.Label.Font.Value,...
    'FontSize', scheme.Label.FontSize.Value,...
    'FontColor', scheme.Label.FontColor.Value);
handles.spinner_lwidth = uispinner(...
    'Parent', handles.panel_plotopts,...
    'Position', [730,7,70,20],...
    'Value', 1.5, ...
    'Limits', [.5, 4],...
    'Step', .5,...
    'AllowEmpty', 'off',...
    'RoundFractionalValues', 'off',...
    'ValueDisplayFormat', '%3.1f',...
    'BackgroundColor',scheme.Dropdown.BackgroundColor.Value,...
    'FontColor', scheme.Dropdown.FontColor.Value,...
    'FontName', scheme.Dropdown.Font.Value,...
    'FontSize', scheme.Dropdown.FontSize.Value);
%**************************************************************************
%add controls for the  plotting options of condition, channel and
%subject
psh = handles.panel_po.InnerPosition(4);
uilabel('Parent', handles.panel_po,...
    'Position', [10,psh-30,100,20],...
    'Text', 'Conditions to plot',...
    'FontName', scheme.Label.Font.Value,...
    'FontSize', scheme.Label.FontSize.Value,...
    'FontColor', scheme.Label.FontColor.Value);
uilabel('Parent', handles.panel_po,...
    'Position', [10,psh-200,100,20],...
    'Text', 'Channels to plot',...
    'FontName', scheme.Label.Font.Value,...
    'FontSize', scheme.Label.FontSize.Value,...
    'FontColor', scheme.Label.FontColor.Value);
uilabel('Parent', handles.panel_po,...
    'Position', [155,psh-180,100,20],...
    'Text', 'Subjects to plot',...
    'FontName', scheme.Label.Font.Value,...
    'FontSize', scheme.Label.FontSize.Value,...
    'FontColor', scheme.Label.FontColor.Value);
handles.list_condition = uilistbox(...
    'Parent', handles.panel_po, ...
    'Position', [10, psh-150, 250, 120 ],...
    'MultiSelect', 'on',...
    'BackgroundColor',scheme.Edit.BackgroundColor.Value,...
    'FontName', scheme.Edit.Font.Value,...
    'FontSize', scheme.Edit.FontSize.Value,...
    'FontColor', scheme.Edit.FontColor.Value);
handles.check_allchans = uicheckbox(...
    'Parent', handles.panel_po,...
    'Position', [10,psh-180,125,20],...
    'Text', 'All Channels',...
    'Value', 1,...
    'FontName',scheme.Checkbox.Font.Value,...
    'FontSize', scheme.Checkbox.FontSize.Value,...
    'FontColor', scheme.Checkbox.FontColor.Value);
handles.list_channels = uilistbox(...
    'Parent', handles.panel_po,...
    'Position', [10,10,120,psh-210],...
    'Enable', 'off',...
    'MultiSelect', 'on',...
    'BackgroundColor',scheme.Edit.BackgroundColor.Value,...
    'FontName', scheme.Edit.Font.Value,...
    'FontSize', scheme.Edit.FontSize.Value,...
    'FontColor', scheme.Edit.FontColor.Value);
handles.list_subject = uilistbox(...
    'Parent', handles.panel_po,...
    'Position', [150,10,120,psh-190],...
    'MultiSelect', 'off',...
    'BackgroundColor',scheme.Edit.BackgroundColor.Value,...
    'FontName', scheme.Edit.Font.Value,...
    'FontSize', scheme.Edit.FontSize.Value,...
    'FontColor', scheme.Edit.FontColor.Value);
%**************************************************************************
%panel for the overlay
psh = handles.panel_statoverlay.InnerPosition;
pshd(1) = 0; psh(2) = 0;
inner_panel_pos = psh; inner_panel_pos(4) = psh(4) - 30;
handles.grp_statselect = uibuttongroup(...
    'Parent',handles.panel_statoverlay,...
    'Position',[psh(1), psh(4)-30, psh(3), 30]);
stats_tab_text = {'Mass Univ', 'GLM', 'New Test'};
for ii = 1:length(stats_tab_text)
    xpos = psh(3) / 3 * (ii -1); 
    handles.button_statstab(ii) = uibutton(handles.grp_statselect, ...
        'Position', [xpos, 0, psh(3)/3, 30],...
        'Text', stats_tab_text{ii},...
        'BackgroundColor', scheme.Panel.BackgroundColor.Value,...
        'FontName', scheme.Panel.Font.Value,...
        'FontColor', scheme.Panel.FontColor.Value,...
        'FontSize', scheme.Panel.FontSize.Value,...
        'Tag', int2str(ii));
end
handles.tab_stats(1) = uipanel(...
    'Parent', handles.panel_statoverlay,...
    'Title', 'Mass Univariate',...
    'Position', inner_panel_pos,...
    'BackgroundColor', scheme.Panel.BackgroundColor.Value,...
    'HighlightColor', scheme.Panel.BorderColor.Value,...
    'FontName',scheme.Panel.Font.Value,...
    'FontSize', scheme.Panel.FontSize.Value,...
    'ForegroundColor', scheme.Panel.FontColor.Value,...
    'Scrollable','on');
handles.tab_stats(2) = uipanel(...
    'Parent', handles.panel_statoverlay,...
    'Title', 'GLM',...
    'Position', inner_panel_pos,...
    'BackgroundColor', scheme.Panel.BackgroundColor.Value,...
    'HighlightColor', scheme.Panel.BorderColor.Value,...
    'FontName',scheme.Panel.Font.Value,...
    'FontSize', scheme.Panel.FontSize.Value,...
    'ForegroundColor', scheme.Panel.FontColor.Value,...
    'Visible','off','Scrollable','on');
handles.tab_stats(3) = uipanel(...
    'Parent', handles.panel_statoverlay,...
    'Title', 'New Stats Test',...
    'Position', inner_panel_pos,...
    'BackgroundColor', scheme.Panel.BackgroundColor.Value,...
    'HighlightColor', scheme.Panel.BorderColor.Value,...
    'FontName',scheme.Panel.Font.Value,...
    'FontSize', scheme.Panel.FontSize.Value,...
    'ForegroundColor', scheme.Panel.FontColor.Value,...
    'Visible','off','Scrollable','on');
psh = handles.tab_stats(1).InnerPosition(4);
handles.check_MUoverlay = uicheckbox(...
    'Parent', handles.tab_stats(1),...
    'Position', [10,385,260,20],...
    'Text', 'Overlay Statistical Results',...
    'Value', 0,...
    'FontName', scheme.Checkbox.Font.Value,...
    'FontSize', scheme.Checkbox.FontSize.Value,...
    'FontColor', scheme.Checkbox.FontColor.Value);
uilabel('Parent', handles.tab_stats(1),...
    'Position', [10, 355, 260, 20],...
    'Text', 'Select a test',...
    'FontName', scheme.Label.Font.Value,...
    'FontSize', scheme.Label.FontSize.Value,...
    'FontColor', scheme.Label.FontColor.Value);
handles.dropdown_MUtest = uidropdown(...
    'Parent', handles.tab_stats(1),...
    'Position', [10,330, 260, 20],...
    'BackgroundColor',scheme.Dropdown.BackgroundColor.Value,...
    'FontColor', scheme.Dropdown.FontColor.Value,...
    'FontName', scheme.Dropdown.Font.Value,...
    'FontSize', scheme.Dropdown.FontSize.Value);
uilabel('Parent', handles.tab_stats(1),...
    'Position', [10, 295, 260, 20],...
    'Text', 'Select an effect',...
    'FontName', scheme.Label.Font.Value,...
    'FontSize', scheme.Label.FontSize.Value,...
    'FontColor', scheme.Label.FontColor.Value);
handles.dropdown_MUeffect = uidropdown(...
    'Parent', handles.tab_stats(1),...
    'Position', [10,270, 260, 20],...
    'BackgroundColor',scheme.Dropdown.BackgroundColor.Value,...
    'FontColor', scheme.Dropdown.FontColor.Value,...
    'FontName', scheme.Dropdown.Font.Value,...
    'FontSize', scheme.Dropdown.FontSize.Value);
uilabel('Parent', handles.tab_stats(1),...
    'Position', [10, 235, 260, 20],...
    'Text', 'Test information',...
    'FontName', scheme.Label.Font.Value,...
    'FontSize', scheme.Label.FontSize.Value,...
    'FontColor', scheme.Label.FontColor.Value);
handles.tree_massuniv = uitree(...
    'Parent', handles.tab_stats(1),...
    'Position', [10,10,260,220],...
    'BackgroundColor',scheme.Edit.BackgroundColor.Value,...
    'FontName', scheme.Edit.Font.Value,...
    'FontSize', scheme.Edit.FontSize.Value,...
    'FontColor', scheme.Edit.FontColor.Value);
%**********************
%ANOVA tab
uilabel('Parent', handles.tab_stats(2),...
    'Position', [10, 310, 260, 20],...
    'Text', 'Select a test',...
    'FontName', scheme.Label.Font.Value,...
    'FontSize', scheme.Label.FontSize.Value,...
    'FontColor', scheme.Label.FontColor.Value);
handles.dropdown_ANOVAtest = uidropdown(...
    'Parent', handles.tab_stats(2),...
    'Position', [10,290, 260, 20],...
    'BackgroundColor',scheme.Dropdown.BackgroundColor.Value,...
    'FontColor', scheme.Dropdown.FontColor.Value,...
    'FontName', scheme.Dropdown.Font.Value,...
    'FontSize', scheme.Dropdown.FontSize.Value);
handles.button_plotANOVA = uibutton(...
    'Parent', handles.tab_stats(2),...
    'Position', [185, 260, 85, 25],...
    'Text', 'Display',...
    'BackgroundColor', scheme.Button.BackgroundColor.Value,...
    'FontColor', scheme.Button.FontColor.Value,...
    'FontName', scheme.Button.Font.Value,...
    'FontSize', scheme.Button.FontSize.Value);
handles.button_exportANOVA = uibutton(...
    'Parent', handles.tab_stats(2),...
    'Position', [95, 260, 85, 25],...
    'Text', 'Export',...
    'BackgroundColor', scheme.Button.BackgroundColor.Value,...
    'FontColor', scheme.Button.FontColor.Value,...
    'FontName', scheme.Button.Font.Value,...
    'FontSize', scheme.Button.FontSize.Value);
handles.check_plotANOVAStyle = uicheckbox(...
    'Parent', handles.tab_stats(2),...
    'Position', [10, 230, 120, 25],...
    'Text', 'Show as ERP plot',...
    'Value',false,...
    'FontSize', scheme.Checkbox.FontSize.Value,...
    'FontColor', scheme.Checkbox.FontColor.Value,...
    'FontName', scheme.Checkbox.Font.Value);
uilabel('Parent', handles.tab_stats(2),...
    'Position', [10, 210, 260, 20],...
    'Text', 'Test information',...
    'FontName', scheme.Label.Font.Value,...
    'FontSize', scheme.Label.FontSize.Value,...
    'FontColor', scheme.Label.FontColor.Value);
handles.tree_ANOVA = uitree(...
    'Parent', handles.tab_stats(2),...
    'Position', [10,10,260,200],...
    'BackgroundColor',scheme.Edit.BackgroundColor.Value,...
    'FontName', scheme.Edit.Font.Value,...
    'FontSize', scheme.Edit.FontSize.Value,...
    'FontColor', scheme.Edit.FontColor.Value);

%*************************************************************************
%tab for the statistical analysis
uilabel('Parent', handles.tab_stats(3),...
    'Position', [10, 465, 100, 20],...
    'Text', 'Factor',...
    'FontName', scheme.Label.Font.Value,...
    'FontSize', scheme.Label.FontSize.Value,...
    'FontColor', scheme.Label.FontColor.Value);
uilabel('Parent', handles.tab_stats(3),...
    'Position', [120, 465, 50, 20],...
    'Text', 'Levels',...
    'FontName', scheme.Label.Font.Value,...
    'FontSize', scheme.Label.FontSize.Value,...
    'FontColor', scheme.Label.FontColor.Value);
handles.edit_factors = uieditfield(...
    'Parent', handles.tab_stats(3),...
    'Position', [10, 440, 100, 20],...
    'BackgroundColor',scheme.Edit.BackgroundColor.Value,...
    'FontName', scheme.Edit.Font.Value,...
    'FontSize', scheme.Edit.FontSize.Value,...
    'FontColor', scheme.Edit.FontColor.Value,...
    'InputType','letters');
handles.edit_levels = uieditfield(...
    handles.tab_stats(3),'numeric',...
    'Limits', [2,inf],...
    'Position', [115, 440, 30, 20],...
    'BackgroundColor',scheme.Edit.BackgroundColor.Value,...
    'FontName', scheme.Edit.Font.Value,...
    'FontSize', scheme.Edit.FontSize.Value,...
    'FontColor', scheme.Edit.FontColor.Value,...
    'Value', 2);
handles.button_factadd = uibutton(...
    'Parent', handles.tab_stats(3),...
    'Position', [150, 440, 55, 20],...
    'Text', 'Add',...
    'BackgroundColor', scheme.Button.BackgroundColor.Value,...
    'FontColor', scheme.Button.FontColor.Value,...
    'FontName', scheme.Button.Font.Value,...
    'FontSize', scheme.Button.FontSize.Value,...
    'Tag', 'Add');
handles.button_factremove = uibutton(...
    'Parent', handles.tab_stats(3),...
    'Position', [210, 440, 60, 20],...
    'Text', 'Remove',...
    'BackgroundColor', scheme.Button.BackgroundColor.Value,...
    'FontColor', scheme.Button.FontColor.Value,...
    'FontName', scheme.Button.Font.Value,...
    'FontSize', scheme.Button.FontSize.Value,...
     'Tag','Remove', ...
     'Enable', 'off');
handles.list_model = uilistbox(...
    'Parent', handles.tab_stats(3),...
    'Position', [10, 330, 260, 100],...
    'BackgroundColor',scheme.Edit.BackgroundColor.Value,...
    'FontName', scheme.Edit.Font.Value,...
    'FontSize', scheme.Edit.FontSize.Value,...
    'FontColor', scheme.Edit.FontColor.Value,...
    'Items', {'[Insert Factors Here]'});
uilabel('Parent', handles.tab_stats(3),...
    'Position', [10,290, 200, 20],...
    'Text', 'Test to conduct',...
    'FontName', scheme.Label.Font.Value,...
    'FontSize', scheme.Label.FontSize.Value,...
    'FontColor', scheme.Label.FontColor.Value);
handles.dropdown_MUtype = uidropdown(...
    'Parent', handles.tab_stats(3),...
    'Position', [10,265,260,20],...
    'BackgroundColor',scheme.Dropdown.BackgroundColor.Value,...
    'FontColor', scheme.Dropdown.FontColor.Value,...
    'FontName', scheme.Dropdown.Font.Value,...
    'FontSize', scheme.Dropdown.FontSize.Value,...
    'Items', {'F-max permutation test', 'Cluster mass permutation test', 'False discovery rate', 'General linear model'},...
    'ItemsData', {'FmaxGND', 'FclustGND', 'FfdrGND', 'ANOVA'});
uilabel('Parent', handles.tab_stats(3),...
    'Position', [10,225, 100, 20],...
    'Text', 'Data to select',...
    'FontName', scheme.Label.Font.Value,...
    'FontSize', scheme.Label.FontSize.Value,...
    'FontColor', scheme.Label.FontColor.Value);
handles.bgroup = uibuttongroup(...
    'Parent', handles.tab_stats(3),...
    'Position', [10, 170, 260,50],...
    'BackgroundColor',scheme.Window.BackgroundColor.Value);
handles.radio_amp = uiradiobutton(...
    'Parent', handles.bgroup,...
    'Text', 'Amplitude',...
    'Position', [5,25,85,20],...
    'Enable', 'off',...
    'FontName', scheme.Checkbox.Font.Value,...
    'FontSize', scheme.Checkbox.FontSize.Value,...
    'FontColor', scheme.Checkbox.FontColor.Value);
handles.radio_pospeak = uiradiobutton(...
    'Parent', handles.bgroup,...
    'Text', 'Latency (+)',...
    'Position', [90,25,85,20],...
    'Enable', 'off',...
    'FontName', scheme.Checkbox.Font.Value,...
    'FontSize', scheme.Checkbox.FontSize.Value,...
    'FontColor', scheme.Checkbox.FontColor.Value);
handles.radio_negpeak = uiradiobutton(...
    'Parent', handles.bgroup,...
    'Text', 'Latency (-)',...
    'Position', [175,25,80,20],...
    'Enable', 'off',...
    'FontName', scheme.Checkbox.Font.Value,...
    'FontSize', scheme.Checkbox.FontSize.Value,...
    'FontColor', scheme.Checkbox.FontColor.Value); 
handles.radio_peakplusminus = uiradiobutton(...
    'Parent', handles.bgroup,...
    'Text', 'Peak +/-',...
    'Position', [5,3,80,20],...
    'Enable', 'off',...
    'FontName', scheme.Checkbox.Font.Value,...
    'FontSize', scheme.Checkbox.FontSize.Value,...
    'FontColor', scheme.Checkbox.FontColor.Value);
handles.radio_peak2peak = uiradiobutton(...
    'Parent', handles.bgroup,...
    'Text', 'Peak to peak',...
    'Position', [90,3,120,20],...
    'Enable', 'off',...
    'FontName', scheme.Checkbox.Font.Value,...
    'FontSize', scheme.Checkbox.FontSize.Value,...
    'FontColor', scheme.Checkbox.FontColor.Value);
uilabel('Parent', handles.tab_stats(3),...
    'Position', [10,130, 100, 20],...
    'Text', 'Window',...
    'FontName', scheme.Label.Font.Value,...
    'FontSize', scheme.Label.FontSize.Value,...
    'FontColor', scheme.Label.FontColor.Value);
handles.edit_massunivstart = uieditfield(...
    handles.tab_stats(3),'numeric',...
    'Position', [90, 130, 85, 20],...
    'ValueDisplayFormat', '%0.2f ms',...
    'BackgroundColor',scheme.Edit.BackgroundColor.Value,...
    'FontName', scheme.Edit.Font.Value,...
    'FontSize', scheme.Edit.FontSize.Value,...
    'FontColor', scheme.Edit.FontColor.Value);
handles.edit_massunivend = uieditfield(...
    handles.tab_stats(3),'numeric',...
    'Position', [185, 130, 85, 20],...
    'ValueDisplayFormat', '%0.2f ms',...
    'BackgroundColor',scheme.Edit.BackgroundColor.Value,...
    'FontName', scheme.Edit.Font.Value,...
    'FontSize', scheme.Edit.FontSize.Value,...
    'FontColor', scheme.Edit.FontColor.Value);
handles.check_massunivave = uicheckbox(...
    'Parent', handles.tab_stats(3),...
    'Position', [10, 90, 200, 20],...
    'Text', 'Average points in window',...
    'FontName', scheme.Checkbox.Font.Value,...
    'FontSize', scheme.Checkbox.FontSize.Value,...
    'FontColor', scheme.Checkbox.FontColor.Value);
handles.check_massunivchans = uicheckbox(...
    'Parent', handles.tab_stats(3),...
    'Position', [10, 70, 200, 20],...
    'Text', 'Use currently displayed channels',...
    'FontName', scheme.Checkbox.Font.Value,...
    'FontSize', scheme.Checkbox.FontSize.Value,...
    'FontColor', scheme.Checkbox.FontColor.Value);
uilabel('Parent', handles.tab_stats(3),...
    'Position', [10, 40, 200, 20],...
    'Text', 'Alpha',...
    'FontName', scheme.Label.Font.Value,...
    'FontSize', scheme.Label.FontSize.Value,...
    'FontColor', scheme.Label.FontColor.Value);
handles.edit_massunivalpha = uieditfield(...
    handles.tab_stats(3),'numeric',...
    'Position', [60, 40, 50, 20],...
    'Limits', [0, 1],...
    'ValueDisplayFormat', '%g',...
    'Value', .05,...
    'BackgroundColor',scheme.Edit.BackgroundColor.Value,...
    'FontName', scheme.Edit.Font.Value,...
    'FontSize', scheme.Edit.FontSize.Value,...
    'FontColor', scheme.Edit.FontColor.Value);
handles.button_massuniv = uibutton(...
    'Parent', handles.tab_stats(3),...
    'Position', [85, 5, 150, 30],...
    'Text', 'Run Test',...
    'BackgroundColor', scheme.Button.BackgroundColor.Value,...
    'FontColor', scheme.Button.FontColor.Value,...
    'FontName', scheme.Button.Font.Value,...
    'FontSize', scheme.Button.FontSize.Value);
%************************************************************************
% create menus
%*************************************************************************
handles.menu_file = uimenu('Parent', handles.figure, 'Label', 'File');
handles.menu_refresh = uimenu('Parent', handles.menu_file, 'Label', 'Refresh Study and ERP');
handles.menu_conditions = uimenu('Parent', handles.menu_file, 'Label', '&Delete selected condition', 'Separator', 'on', 'Tag', 'bin', 'Accelerator', 'D');
handles.menu_stats = uimenu('Parent', handles.menu_file, 'Label', 'Delete selected Mass &Univ Test', 'Tag', 'MU', 'Accelerator', 'U');
handles.menu_ANOVA = uimenu('Parent', handles.menu_file, 'Label', 'Delete selected &GLM Test', 'Tag', 'ANOVA', 'Accelerator', 'G');
handles.menu_editcond = uimenu('Parent', handles.menu_file, 'Label', 'Edit Conditions', 'Separator', 'on');

handles.menu_plot = uimenu('Parent', handles.figure, 'Label', 'ERP Options');
handles.menu_autoscale = uimenu('Parent', handles.menu_plot, 'Label', 'Auto scale amplitude', 'Checked', true);
handles.menu_stderr = uimenu('Parent', handles.menu_plot, 'Label', 'Show Std Error (Within Subject)');
handles.menu_stack = uimenu('Parent', handles.menu_plot, 'Label', 'Stack Channels', 'Checked', true);
handles.menu_GFP = uimenu('Parent', handles.menu_plot, 'Label', 'Show Global Field Power', 'Checked', false);

handles.menu_cursor = uimenu('Parent', handles.figure,'Label', 'Cursor');
handles.menu_cursoradd = uimenu('Parent', handles.menu_cursor,'Label', 'Add Cursor', 'Tag', 'add', 'Accelerator', 'A');
handles.menu_cursorsub = uimenu('Parent', handles.menu_cursor,'Label', 'Remove Cursor', 'Tag', 'subtract', 'Accelerator', 'X');
handles.menu_cursormean = uimenu('Parent', handles.menu_cursor, 'Label', 'Average between cursors', 'Checked', 'off');

handles.menu_map = uimenu('Parent', handles.figure, 'Label', 'Scalp maps');
handles.menu_mapRes = uimenu('Parent',handles.menu_map, 'Label', 'Quality');
labels = {'low', 'medium', 'high', 'print quality'};
for ii = 1:4
    handles.menu_mapquality(ii) = uimenu('Parent', handles.menu_mapRes, 'Label', labels{ii}, 'Checked', 'off');
end
handles.menu_mapquality(2).Checked = true; %default to medium res
handles.menu_scale = uimenu('Parent', handles.menu_map, 'Label', 'Map Scale Limits');
handles.menu_mapscale(1) = uimenu('Parent', handles.menu_scale, 'Label', 'ALl maps on the same scale', 'Checked', 'on', 'Tag', 'Auto');
handles.menu_mapscale(2) = uimenu('Parent', handles.menu_scale, 'Label', 'Scale individually', 'Checked', 'off', 'Tag', 'Always');
handles.menu_mapscale(3) = uimenu('Parent', handles.menu_scale, 'Label', 'Fixed Scale', 'Checked', 'off', 'Tag', 'Fixed');

