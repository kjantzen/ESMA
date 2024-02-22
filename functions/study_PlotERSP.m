%this function is under revision and does not work perfectly.
function study_PlotERSP(study, filename)

fprintf('Opening ERSP plotting and analysis tool...\n');

if isempty(filename)
    error('No valid file was found')
end

scheme = eeg_LoadScheme;
p.study = study;

fprintf('...loading the data file.  This may takes several seconds...');
load(filename{1}, '-mat');
TFData.saved = 'yes';
[fpath, fname, fileext] = fileparts(filename{1});
TFData.filename = [fname, fileext];
TFData.filepath = fpath;

fprintf('done\n');
p.TFData = TFData; clear TFData;

%p.topo_layout = tf_topo_layout(TFData.chanlocs);
p.ts_colors = prism(length(p.TFData.bindesc));  %use the lines colormap for defining plot colors

%build the figure
handles.scheme = scheme;
handles = build_gui(handles);
initialize_gui(handles, p.TFData);
handles.figure.UserData = p;

%initialize the displays and plot the data
callback_reloadfiles([],[],handles, false)
callback_toggleallchannel([],handles.check_allchans,handles);
fprintf('...done\n');

%***************************************************************************
function callback_togglemcs(hObject, ~, h)
%toggle mean cursor status
 hObject.Checked = ~hObject.Checked;
 plot_topos(h)

%************************************************************************
function callback_toggletopomenustate(hObject, ~, h)

for ii = 1:2
    h.menu_mapscale(ii).Checked = false;
end
hObject.Checked = true;
plot_topos(h)

%**************************************************************
function callback_togglemapquality(hObject, ~, h)

    hObject.Checked = ~hObject.Checked;
    plot_topos(h);

%*************************************************************************
function callback_plotANOVAresult(~, ~,h)

p = h.figure.UserData;

if ~isfield(p.TFData, 'ANOVA')
    error('No ANOVA data for this TFData file');
end

if isempty(p.TFData.ANOVA)
    error('No ANOVA data for this TFData file');
end

ANOVAnum = h.dropdown_ANOVAtest.Value;
r = p.TFData.ANOVA(ANOVAnum);
study_PlotANOVAresults(r);

%************************************************************************
function callback_togglestatsoption(hObject, ~, h)

    h.ItemsData = [];
    switch hObject.Value
       case 'TF_Parametric'
            
            h.dropdown_MCtype.Items = {'None','Bonferroni', 'Holm', 'Hochberg', 'FDR'};
            h.dropdown_MCType.ItemsData = {'no', 'bonferroni', 'holm', 'hochberg', 'fdr'};
       
        case 'TF_Permutation'
            h.dropdown_MCtype.Items = {'None','Max', 'Cluster', 'Bonferroni', 'Holm', 'Hochberg', 'FDR'};
            h.dropdown_MCType.ItemsData = {'no', 'max', 'cluster', 'bonferroni', 'holm', 'hochberg', 'fdr'};

    end

%************************************************************************
function callback_toggleMCOption(hObject, ~, h)

    
    if contains(hObject.Value, 'cluster')
        h.dropdown_ClustStat.Enable = 'on';
    else
        h.dropdown_ClustStat.Enable = 'off';
    end
%*************************************************************************
%function to delete unwanted bins and stats tests
function callback_removebinsandstats(~, event, h)

p = h.figure.UserData;
TFData = p.TFData;

switch event.Source.Tag
    case 'bin'
        c_bin = h.list_condition.Value;
        if length(h.list_condition.Items) < 2
            uialert(h.figure, 'You must have at least one condition per file', 'Delete Error');
            return
        end
        
        response = uiconfirm(h.figure, sprintf('Are you sure you want to delete %s?', TFData.bindesc{c_bin}), 'Confirm Delete');
        if contains(response, 'OK')
            TFData = rm_bins(TFData, c_bin);
            outfile = eeg_BuildPath(TFData.filepath, TFData.filename);
            save(outfile,'TFData', '-mat');
            callback_reloadfiles([],[],h, 1);
        end
        
    case 'MU'
        
        c_stat = h.dropdown_MUtest.Value;
        if isempty(c_stat)
            return
        end
        
        response = uiconfirm(h.figure, sprintf('Are you sure you want to delete %s?', h.dropdown_MUtest.Items{c_stat}), 'Confirm Delete');
        if contains(response, 'OK')
            TFData.F_tests(c_stat) = [];
            outfile = eeg_BuildPath(TFData.filepath, TFData.filename);
            save(outfile,'TFData', '-mat');
            callback_reloadfiles([],[],h, 1);
            
            if ~isempty(TFData.F_tests) %if we did not delete them all
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
            TFData.ANOVA(c_stat) = [];
            TFData = save_TFData(TFData);
            
            callback_reloadfiles([],[],h, 1);
            
            if ~isempty(TFData.ANOVA) %if we did not delete them all
                if length(h.dropdown_ANOVAtest.Items) >= c_stat
                    h.dropdown_ANOVAtest.Value = c_stat;
                else
                    h.dropdown_ANOVAtest.Value = h.dropdown_ANOVAtest.ItemsData(end);
                end
            end
        end
end
%% ***********************************************************************
function TFData = save_TFData(TFData)

outfile = [TFData.filepath,TFData.filename];
%do some checking here in future if necessary
TFData.saved = 'yes';
save(outfile, 'TFData', '-mat')

%*************************************************************************
%function to handle adding and removing factors
function callback_changefactors(~, event, h)

switch event.Source.Tag
    case 'Add'
        
        fname = h.edit_factors.Value;
        flevel = h.edit_levels.Value;
        
        if isempty(fname) || isempty(flevel)
            uialert(h.figure, 'Please enter a factor name and number of levels.', 'Add factor');
            return
        end
        
        flabel = {sprintf('%s (%i) levels', fname, flevel)};
        
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
        h.list_model.ItemsData = 1:length(h.list_model.Items);
       
        if isempty(h.list_model.ItemsData)
            h.list_model.Items = {'[Enter your factors here]'};
            h.button_factremove.Enable = 'off';
        end
        
end

%************************************************************************
function callback_runstatstest(~, ~, h)

p = h.figure.UserData;

%collect information from the GUI
if isempty(h.list_model.ItemsData)
    uialert(h.figure,'Please define some conditions before running the test.','Run Stats')
    fprintf('No factors have been defined!')
    return
end

newStr = split(h.list_model.Items, {'(', ')'});
if length(h.list_model.Items) ==1
    stats.factors = newStr(1);
    stats.levels = newStr(2);
else
    stats.factors = newStr(1,:,1);
    stats.levels = newStr(1,:,2);
end

stats.test = h.dropdown_MUtype.Value;
stats.multcomparecorrectino = h.dropdown_MCtype.Value;
stats.clusterstatistic = h.dropdown_ClustStat.Value;
stats.winstart = h.edit_statTimeStart.Value;
stats.winend = h.edit_statTimeEnd.Value;
stats.freqwinstart = h.edit_statFreqStart.Value;
stats.freqwinend = h.edit_statFreqEnd.Value;
stats.meanwindow = h.check_massunivavetime.Value;
stats.meanfreq = h.check_massunivavefreq.Value;
stats.alpha = h.edit_massunivalpha.Value;
stats.ave_channels = false;
stats.eegchans = [];

if isempty(stats.eegchans)
    if h.check_massunivchans.Value
        d = h.list_channels.Value;
        s = cell2mat(d');
        stats.eegchan_numbers = s(:,1);
        stats.eegchans = {p.TFData.chanlocs(stats.eegchan_numbers).labels};
        if isempty(stats.eegchans)
            uialert(h.figure, 'You have not selected any eeg channels!', 'Stats Error');
            return
        end
    else
        stats.eegchan_numbers = 1:length(p.TFData.chanlocs);
        stats.eegchans = {p.TFData.chanlocs.labels};
    end
end
myh = study_RunStats(p.TFData, stats);
uiwait(myh);
callback_reloadfiles([],[],h,1)

%set the last item in the dropdown as active.
%h.dropdown_ANOVAtest.Value = h.dropdown_ANOVAtest.ItemsData(end);
%callback_plotANOVAresult([],[],h);
 
%*************************************************************************
%function to handle when user changes the status of the "All Channel" option
function callback_toggleallchannel(~, event, h)

manual_select = ~event.Value;

h.list_channels.Enable = manual_select;
cur_selected = h.list_channels.Value;

%select all thh regular channels
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

callback_plotersp([],[],h);

%**************************************************************************
%callback_reloadfiles - reloads the erp and study files and refreshes the
%erp display to reflect any changes.
function callback_reloadfiles(~, ~, h, reload_flag)

h.figure.Pointer = 'watch';
drawnow;

%get the current information from the figure userdata
p = h.figure.UserData;

%if there is an explicit request to reload - otherwise the displays will
%just be refreshed.  This allows the same code to be used to initialize the
%displays
if reload_flag
    
    
    %update with the most recent data file and the most recent study file
    erp_filename =eeg_BuildPath(p.TFData.filepath, p.TFData.filename);
    TFData = load(erp_filename, '-mat', 'TFData');
    if isfield(TFData, 'TFData')
        TFData = TFData.TFData;
    end
    
%     if isfield(TFData, 'F_tests') && ~isempty(TFData.F_tests)
%         for ii = 1:length(TFData.F_tests)
%             if iscell(TFData.F_tests(ii).used_tpt_ids)
%                 TFData.F_tests(ii).used_tpt_ids = cell2mat(TFData.F_tests(ii).used_tpt_ids);
%             end
%         end
%     end

    p.TFData = TFData;
    
    study = study_LoadStudy(p.study.filename);
    p.study = study;
    
    h.figure.UserData = p;
end

h.list_condition.Items = p.TFData.bindesc;
h.list_condition.ItemsData = 1:length(p.TFData.bindesc);

chans = {p.TFData.chanlocs.labels};
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
snames = cell(1, length(p.TFData.erp_file) + 1);
snames{1} = 'GRAND AVERAGE';
for ii = 1:length(p.TFData.erp_file)
    [sp,~,~] = fileparts(p.TFData.erp_file(ii));
    indx = strfind(sp, filesep);
    snames{ii+1} = sp(indx(end)+1:end);
end
clear sp;
h.list_subject.Items = snames;
h.list_subject.ItemsData = 0:length(snames);

%  populate the informaito about the mass univariate tests
if isfield(p.TFData,'F_tests') && ~isempty(p.TFData.F_tests)
    n = arrayfun(@(x) join(x.factors), p.TFData.F_tests);
    n = cellfun(@(x) create_test_name(x), n, 'UniformOutput', false);
    t = num2cell(1:length(p.TFData.F_tests));
    tn = cellfun(@num2str, t, 'un', 0);
    labels = strcat(tn, '. ', n);
    
    h.dropdown_MUtest.Items = labels;
    h.dropdown_MUtest.ItemsData = 1:length(p.TFData.F_tests);
    
    callback_populateMUtestinfo([],[],h)

    h.dropdown_MUtest.Enable = true;
    h.dropdown_MUeffect.Enable = true;
    h.check_MUoverlay.Enable = true;
    h.tree_massuniv.Enable = true;

else 
    h.dropdown_MUtest.Items = {'No Statistical tests found'};
    h.dropdown_MUtest.Enable = false;
    
    h.dropdown_MUeffect.Items = {'No Statistical tests found'};
    h.dropdown_MUeffect.Enable = false;
    
    h.check_MUoverlay.Enable = false;
    delete(h.tree_massuniv.Children);
    h.tree_massuniv.Enable = false;   

end


h.figure.Pointer = 'arrow';

% ************************************************************************
function name =  create_test_name(strIn)

strIn = strip(strIn);
name = regexprep(strIn,' +',' X ');

%**************************************************************************
function callback_populateANOVAtestinfo(hObject, event, h)

p = h.figure.UserData;

    
tn = h.dropdown_ANOVAtest.Value;
r = p.TFData.ANOVA(tn);


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
for ii = 1:length(r.factors)
    uitreenode('Parent',n,...
        'Text', sprintf('%s (%s)', r.factors{ii}, r.levels{ii}));
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

opt = {'no', 'yes'};

p = h.figure.UserData;

    
tn = h.dropdown_MUtest.Value;
r = p.TFData.F_tests(tn);

%add the possible effects
h.dropdown_MUeffect.Items = r.effects;
h.dropdown_MUeffect.ItemsData = 1:length(r.effects);

delete(h.tree_massuniv.Children);
n = uitreenode(h.tree_massuniv,...
    'Text', 'Conditions');
for ii = 1:length(r.conditions)
    uitreenode(n,...
        'Text', sprintf('%i. %s', ii, r.conditions{ii}));
end

%add the number of levels after each factor name
n = uitreenode(h.tree_massuniv,...
    'Text', 'Factors');
for ii = 1:length(r.factors)
    uitreenode('Parent',n,...
        'Text', sprintf('%s (%s)', r.factors{ii}, r.levels{ii}));
end

n = uitreenode(h.tree_massuniv,...
    'Text', sprintf('Participants(n):\t%i', r.group_n));

n = uitreenode(h.tree_massuniv,...
    'Text', sprintf('Alpha:\t\t\t%0.3g', r.alpha));

n = uitreenode(h.tree_massuniv,...
    'Text', sprintf('Method:\t\t%s', r.test));

n = uitreenode(h.tree_massuniv,...
    'Text', sprintf('Comparison correction:\t\t%s', r.multcomparecorrectino));

n = uitreenode(h.tree_massuniv,...
    'Text', sprintf('mean time window:\t\t%s', opt{r.meanwindow+1}));

n = uitreenode(h.tree_massuniv,...
    'Text', sprintf('mean freq window:\t\t%s', opt{r.meanfreq+1}));

n = uitreenode(h.tree_massuniv,...
    'Text', sprintf('Time Window'));
uitreenode(n,'Text', sprintf('Start:\t%3.2f ms. (sample: #%i)', r.winstart, r.winstartpt));
uitreenode(n,'Text', sprintf('End:\t\t%3.2f ms. (sample: #%i)', r.winend, r.winendpt));

n = uitreenode(h.tree_massuniv,...
    'Text', sprintf('Frequency Window'));
uitreenode(n,'Text', sprintf('Start:\t%3.2f ms. (sample: #%i)', r.freqwinstart, r.freqwinstartpt));
uitreenode(n,'Text', sprintf('End:\t\t%3.2f ms. (sample: #%i)', r.freqwinend, r.freqwinendpt));

n = uitreenode(h.tree_massuniv,...
    'Text', sprintf('Channels Included'));
for ii = r.eegchan_numbers
    uitreenode('parent', n,...
        'Text', sprintf('%i. %s', ii, p.TFData.chanlocs(ii).labels));
end

if h.check_MUoverlay.Value
    callback_plotersp([],[],h);
end

%**************************************************************************
function callback_changestatselection(hObject, event, h)

if h.check_MUoverlay.Value
    callback_plotersp([],[],h);
end        

%**************************************************************************
function callback_handlekeyevents(hObject, event, h)

%only accept keystrokes if the shift key is pressed.
if ~strcmp(event.Modifier, 'shift'); return; end

p = h.figure.UserData;

[~, indx] = get_tf_cursor_values(h, p.TFData);

%shift the position of the ROI window
if contains(event.Key, 'arrow')
    switch event.Key
        case 'rightarrow'
            indx([1,3]) = indx([1,3]) + 1;
            if indx(3) > length(p.TFData.times)
                return
            end
    
        case 'leftarrow'
            indx([1,3]) = indx([1,3]) - 1;
            if indx(1) < 1
                return
            end
            
        case 'uparrow'
            indx([2,4]) = indx([2,4]) + 1;
            if indx(4) > length(p.TFData.freqs)
                return
            end
            
        case 'downarrow'
    
            indx([2,4]) = indx([2,4]) - 1;
            if indx(2) < 1
                return
            end
    end
    
    position(1) = p.TFData.times(indx(1));
    position(2) = p.TFData.freqs(indx(2));
    position(3) = p.TFData.times(indx(3)) - position(1);
    position(4) = p.TFData.freqs(indx(4)) - position(2);

update_cursor_position([], [], h, position);
end

%**************************************************************************
%main function for handling mouse events that select and control the cursors
function callback_handlemouseevents(hObject, event,h)


%button types are:
%   normal  -   left mouseclick
%   alt     -   right mouse button OR control & left button
%   extend  -   shift & either button
btype = h.figure.SelectionType;

switch event.EventName
    
    case 'Hit'  %clicked on a uiaxis so initialize drawing

        %check to see if the user clicked on the ROI
        [isClicked, rect, position] = isClickedOnROI(h, hObject);
        if isClicked
            fprintf('HEY - you clicked on the ROI\n')
            c = h.panel_ersp.UserData;
            c.roidragging = true;
            c.dragging = false;
            c.dragged = false;
            c.rect = rect;
            c.startpos = rect.Position(1:2);
            c.endpos = rect.Position(1:2) + rect.Position(3:4);
            c.lastMousePosition = position(1:2);
            c.rect.EdgeColor = 'w';
        
        else
            c.roidragging = false;
            c.dragging = true;
            c.dragged = false;
            c.startpos = [hObject.CurrentPoint(1,1), hObject.CurrentPoint(1,2)];
            c.endpos = c.startpos + [1,1];
            position = [c.startpos, c.endpos - c.startpos];
            
            c.rect = rectangle(hObject, 'Position',position,...
                'EdgeColor', [0,0,0], 'LineWidth',3, 'LineStyle','--');
        end
        c.axis = hObject;
        h.panel_ersp.UserData = c; %save the initial status to the panel
        
    case 'WindowMouseRelease'  %update the cursor position for mapping
       c = h.panel_ersp.UserData;
       if c.dragging || c.roidragging
            if ~c.dragged 
                position = [c.startpos, 0,0]; %update only the position      
            else
                position(1) = min(c.startpos(1), c.endpos(1));
                position(2) = min(c.startpos(2), c.endpos(2));
                position(3) = abs(c.startpos(1) - c.endpos(1));
                position(4) = abs(c.startpos(2) - c.endpos(2));
                
                %update the position and the width
            end

            c.dragged = false;
            c.dragging = false;
            c.roidragging = false;
            delete(c.rect)
            h.panel_ersp.UserData = c;
            update_cursor_position([],[],h,position);

       end
        
    case 'WindowMouseMotion'
        c = h.panel_ersp.UserData;
        if isempty(c)
            c.dragging = false;
            c.roidragging = false;
            h.panel_ersp.UserData = c;
        end

        if c.dragging || c.roidragging
            c.dragged = true;
            xl = c.axis.XLim; yl = c.axis.YLim;
            cp = c.axis.CurrentPoint;
            if cp(1,1) < xl(1) || cp(1,1) > xl(2) ||  cp(1,2) < yl(1) || cp(1,2) >yl(2) %out of range
                return
            else
                if c.roidragging
                    d(1) = cp(1,1) - c.lastMousePosition(1);
                    d(2) = cp(1,2) - c.lastMousePosition(2);

                    c.lastMousePosition(1) = cp(1,1);
                    c.lastMousePosition(2) = cp(1,2);
                    c.endpos = c.endpos + d;
                    c.startpos = c.startpos + d;
                   
                    x1 = min(c.startpos(1), c.endpos(1));
                    y1 = min(c.startpos(2), c.endpos(2));
                    x2 = max(c.startpos(1), c.endpos(1));
                    y2 = max(c.startpos(2), c.endpos(2));
                    %dont update of the bounds of the rect are outside the
                    %plotting limits
                    if x1 > xl(1) && x2 < xl(2) && y1 > yl(1) && y2 < yl(2)
                        position = [x1,y1, x2-x1, y2-y1];
                        c.rect.Position = position;
                        c.rect.EdgeColor = 'w';
                    end

                else

                    c.endpos = [cp(1,1), cp(1,2)];
                    position = [c.startpos, c.endpos - c.startpos];
    
                    if c.endpos(1) < c.startpos(1)
                        position(1) = c.endpos(1);
                        position(3) = abs(position(3));
                    end
                    if c.endpos(2) < c.startpos(2)
                        position(2) = c.endpos(2);
                        position(4) = abs(position(4));
                    end
                    c.rect.Position = position;
                 end
                h.panel_ersp.UserData = c;
            end
        end
        
end
%**************************************************************************
function [isClicked, rect, pos] = isClickedOnROI(h, hObject)

    %assume that it is not clicked
    p = h.figure.UserData;

    isClicked = false;
    rect = findobj(hObject, 'Type', 'rect');

    if ~isempty(rect)
        
        x = hObject.CurrentPoint(1,1);
        y = hObject.CurrentPoint(1,2);
        pos = pos2data([x, y, 0, 0],p.TFData);

        rx1 = rect.Position(1);
        ry1 = rect.Position(2);
        rx2 = rect.Position(1) + rect.Position(3);
        ry2 = rect.Position(2) + rect.Position(4);

        if pos(1) == rx1 || pos(1) == rx2 || pos(2) == ry1 || pos(2) == ry2
            isClicked = true;
        end
        

    end  


%**************************************************************************
function update_cursor_position(hObject, ~, h, position)

   p = h.figure.UserData;

    %make sure the time and frequency fall on an extact time and frequency
    %point
    if isempty(hObject)  %it was called directly and not as a callback 
        vals = pos2data(position, p.TFData);
    else
       [vals, indx] = get_tf_cursor_values(h, p.TFData);
    end
       
    h.spinner_time.Value = vals(1);
    h.spinner_freq.Value = vals(2);
    h.spinner_twidth.Value = vals(3);
    h.spinner_fwidth.Value = vals(4);

    draw_tf_cursors(h, p);
    plot_topos(h);
% *************************************************************************
function vals = pos2data(position, TFData)
        
        vals(1) = position(1);
        [~,indx(1)] = min(abs(TFData.times - vals(1)));
        
        vals(2) = position(2);
        [~,indx(2)] = min(abs(TFData.freqs - vals(2)));

     %   if position(3) ~= 0
            vals(3) = position(1) + position(3);
            [~,indx(3)] = min(abs(TFData.times - vals(3)));
     %   end
     %   if position(4) ~= 0
            vals(4) = position(2) + position(4);
            [~,indx(4)] = min(abs(TFData.freqs - vals(4)));
     %   end

          %now put the values back into the spinners
        vals(1) = TFData.times(indx(1));
        vals(2) = TFData.freqs(indx(2));
        vals(3) = TFData.times(indx(3));
        vals(4) = TFData.freqs(indx(4));
%*************************************************************************
function draw_tf_cursors(h, p)

    vals = get_tf_cursor_values(h, p.TFData);
    
    if ~isfield(p, 'paxis')
        warning('No plot axis were found');
        return
    end

    position = [vals(1), vals(2), vals(3)-vals(1), vals(4)-vals(2)];
 
    for ii = 1:length(p.paxis)
        rhandle = findobj(p.paxis(ii), 'Type', 'rect');
        if isempty(rhandle)
            rhandle = rectangle('Parent',p.paxis(ii), 'Position', position);
            rhandle.EdgeColor = [0,0,0];
            rhandle.LineWidth = 3;
            rhandle.HitTest = "off";
        else
            rhandle.Position = position;
   
        end
    end
%***********************************************************************
function [vals, indx] = get_tf_cursor_values(h, TFData)
%return the value and data matrix index for the time and frequency range
%for mapping
    [~, indx(1)] = min(abs(TFData.times - h.spinner_time.Value));
    [~, indx(2)] = min(abs(TFData.freqs - h.spinner_freq.Value));
    [~, indx(3)] = min(abs(TFData.times - h.spinner_twidth.Value));
    [~, indx(4)] = min(abs(TFData.freqs - h.spinner_fwidth.Value));

    vals(1) = TFData.times(indx(1));
    vals(3) = TFData.times(indx(3));
    vals(2) = TFData.freqs(indx(2));
    vals(4) = TFData.freqs(indx(4));
 
%**************************************************************************
function data = fetchERSPData(study, TFData, h, topostyle)


%get the conditions, channels and subject to plot from the listboxes
cond_sel = h.list_condition.Value;
ch = cell2mat(h.list_channels.Value');
sbj = h.list_subject.Value;

%user option for plotting statistics overlay
plot_stats = h.check_MUoverlay.Value;

if plot_stats && isfield(TFData, 'F_tests')
    nTest = h.dropdown_MUtest.Value;
    nEffect = h.dropdown_MUeffect.Value;
    stat = TFData.F_tests(nTest); 
else 
    plot_stats = false;
end

%make these explicit so that it is easier to impliment features for
%selecting a reduced range in the future
%currently there is not option to zoom, so these points will not vary from
%plot to plot
nt = length(TFData.times);
nf = length(TFData.freqs);
t =1:nt; %get all the points 
f = 1:nf;

%get the selected data channels
ch_sel = ch(find(ch(:,1)),1);%

%it is possible that no channels are selected because just the channel
%groups can be selected
if ~isempty(ch_sel)
    if sbj==0 %this is the grand average
        %average across the selected conditions
        data.ersp = squeeze(mean(TFData.grand_ersp(ch_sel,f,t,cond_sel),4));
    else
        data.ersp = squeeze(mean(TFData.indiv_ersp(sbj, ch_sel, f, t, cond_sel),5));
    end    
    data.statMask = ones(size(data.ersp));
    %create a default statistics mask for overlay
    %get the statistics data for each channel
    if plot_stats
        p = stat.p_val{nEffect};
        F = stat.F_obs{nEffect};
        [~, p] = expandStatToFullArray(F,p,[stat.freqwinstartpt,stat.freqwinendpt], [stat.winstartpt,stat.winendpt]);

        %select statistics just from the displayed channel
        if length(ch_sel)==1
            data.statMask(stat.freqwinstartpt:stat.freqwinendpt, stat.winstartpt:stat.winendpt) = squeeze(p(ch_sel, :,:));
        else
            data.statMask(:,stat.freqwinstartpt:stat.freqwinendpt, stat.winstartpt:stat.winendpt) = squeeze(p(ch_sel, :,:));
        end
        data.statMask = 1-data.statMask;
        data.statMask(data.statMask> (1-stat.alpha)) = 1;
        data.statMask(data.statMask ~= 1) = 0;
    else
        data.statMask =ones(size(data.ersp));
    end   
    data.labels = {TFData.chanlocs(ch_sel).labels};
end

%now get the channel group information 
if topostyle
    ch_groups = [];  %ignore channel groucps if this is a topo plot
else
    ch_groups = ch(find(ch(:,2)),2);
end

%dont do this part if either there are no channel groups selected or this
%function was called from the plot_topo function
if ~isempty(ch_groups) 
    %get the means of any channel groups
    ch_group_data = zeros(length(ch_groups), length(f), length(t));
    ch_group_stats = ch_group_data + 1;

    for ii = 1:length(ch_groups)
        if sbj == 0
            ch_group_data(ii,f,t) = squeeze(mean(mean(TFData.grand_ersp(study.chgroups(ch_groups(ii)).chans,:,:,cond_sel),1),4));
        else
            ch_group_data(ii,f,t) = squeeze(mean(mean(TFData.indiv_ersp(sbj, study.chgroups(ch_groups(ii)).chans,:,:,cond_sel),2),5));
        end       
    end
    
    %put it all together if both channel group and channel information
    %exist
    if ~isempty(ch_sel)
        if ndims(data.ersp) == 2
            temp = data.ersp;
            data.ersp = [];
            data.ersp(1,:,:) = temp;

            temp = data.statMask;
            data.statMask = [];
            data.statMask(1,:,:) = temp';
            %now do the statistical overlay
        end
        data.ersp = cat(1, ch_group_data, data.ersp); 
        data.statMask = cat(1,ch_group_stats, data.statMask);
        data.labels = horzcat({study.chgroups(ch_groups).name}, data.labels);
    else
        data.ersp = ch_group_data;
        data.statMask = ch_group_stats;
        data.labels = {study.chgroups(ch_groups).name};
    end
    
end
data.times = TFData.times(t);
data.freqs = TFData.freqs(f);
%if topostyle is selected and only channel groups are highlighted, there
%will be nothing to plot
if ~isfield(data, 'labels') || isempty(data.labels)
    error('FetchData:WrongFormat', 'Cannot create a topoplot with only channel groups selected.');
else
    data.nchan = length(data.labels);
    data.chans = ch_sel;
    data.chanlocs = TFData.chanlocs(ch_sel);
    
end

%***********************************************************************
function mapinfo = fetchTopoMapData(TFData, h)
%get the data for making topographic maps
%

%get the conditions, subject to plot from the listboxes
cond_sel = h.list_condition.Value;
sbj = h.list_subject.Value;
%get the time/freq cursor position
[cv, ci] = get_tf_cursor_values(h, TFData);

%see if the user is plotting statistical results
plot_stats = h.check_MUoverlay.Value;
if plot_stats && isfield(TFData, 'F_tests')
    nTest = h.dropdown_MUtest.Value;
    nEffect = h.dropdown_MUeffect.Value;
    stat = TFData.F_tests(nTest); 
else 
    plot_stats = false;
end

%assign data to output variable
mapinfo.plotarea = cv;
mapinfo.nmaps = length(cond_sel);
mapinfo.condnames = TFData.bindesc(cond_sel);

ch_list = cell2mat(h.list_channels.Value');
ch_list = ch_list(:, 1);
mapinfo.chanlist = ch_list(ch_list>0);

if sbj == 0
    mapinfo.ersp = squeeze(mean(mean(TFData.grand_ersp(:,ci(2):ci(4), ci(1):ci(3), cond_sel),2),3));
else
    mapinfo.ersp = squeeze(mean(mean(TFData.indiv_ersp(sbj, :,ci(2):ci(4), ci(1):ci(3), cond_sel),3),4))';
end
    %get statistical data
    if plot_stats
        FMask = zeros(TFData.nchan, length(TFData.freqs), length(TFData.times));
        PMask = ones(TFData.nchan, length(TFData.freqs), length(TFData.times));
        p = stat.p_val{nEffect};
        F = stat.F_obs{nEffect};
        [F, p] = expandStatToFullArray(F,p,[stat.freqwinstartpt,stat.freqwinendpt], [stat.winstartpt,stat.winendpt]);
        FMask(:,stat.freqwinstartpt:stat.freqwinendpt, stat.winstartpt:stat.winendpt) = F;
        PMask(:,stat.freqwinstartpt:stat.freqwinendpt, stat.winstartpt:stat.winendpt) = p;
        %get the mean F score in the tf window
        mapinfo.FScores = squeeze(mean(mean(FMask(:, ci(2):ci(4), ci(1):ci(3)),3),2)); 
        %find if there are any stat sig tf points for each channel
        mapinfo.SigChannel = find(min(PMask(:, ci(2):ci(4), ci(1):ci(3)),[], [2,3]) < stat.alpha);
        mapinfo.nStatMaps = 1;
   else
        mapinfo.nStatMaps = 0;
        mapinfo.SigChannel = [];
   end

% ************************************************************************
function [F,p] = expandStatToFullArray(F, p, frange, trange)
%takes  a channel x time or channel x freq array of F and p values and
%returns a fill channel x ferq x time array.  If a full channel x time x
%freq array is passed, the original data is returned
%

windowSize = [frange(2)-frange(1)+1,trange(2)-trange(1)+1]; 
nd = ndims(p);
if nd==2
    nc = size(p,2);
end
%check to see if data has been collapsed across time or frequency
%if it has expand it back out to the size of the original window
if nc == 1  
    p = repmat(p, [1, windowSize]);
    F = repmat(F,[1,windowSize]);
elseif nd == 2
    if size(p, 2) == windowSize(2) 
        p = repmat(p, 1, 1, windowSize(1));
        p = permute(p, [1,3,2]);
        F = repmat(F, 1, 1, windowSize(1));
        F = permute(F, [1,3,2]);
    else
        p = repmat(p, 1,1,windowSize(2));
        F = repmat(F ,1, 1, windowSize(2));
    end
end


%************************************************************************
% plot the topographic maps indicated by the active cursors
function plot_topos(h)

if h.menu_mapquality.Checked
    gridscale =  300;
else 
    gridscale = 64;
end
singleScaleMode = h.menu_mapscale(1).Checked;

p = h.figure.UserData;
delete(h.panel_topo.Children);
an = findall(h.panel_topo,'Type','textboxshape');
delete(an);

panelSize = h.panel_topo.InnerPosition;

mapinfo = fetchTopoMapData(p.TFData, h);
emarker = {mapinfo.chanlist, 'o', 'k', 6, 1};
statSigMarker = {mapinfo.SigChannel, 'o', 'k', 6, 1};
for ii = 1:mapinfo.nmaps
    topo_axis = subplot(1,mapinfo.nmaps + mapinfo.nStatMaps,ii, 'Parent', h.panel_topo);
    cmap = colormap(topo_axis, 'jet');
    
    d = mapinfo.ersp(:,ii);
    if singleScaleMode
        ms = max(max(abs(mapinfo.ersp)));
    else
        ms = max(abs(d));
    end
    ms = [-ms, ms];
    wwu_topoplot(d, p.TFData.chanlocs, 'axishandle', topo_axis,'colormap', cmap, 'maplimits', ms,  'style', 'map', 'numcontour', 0, 'gridscale', gridscale,...
        'emarker2', emarker); 
    if ~singleScaleMode
        c = colorbar(topo_axis);
        c.Label.String = 'ERSP (dB)';
        c.Color = h.scheme.Axis.AxisColor.Value;
    end
    topo_axis.Title.String = mapinfo.condnames{ii};
    topo_axis.Title.Interpreter = 'none';
    topo_axis.Title.Color = h.scheme.Axis.AxisColor.Value;

end
if singleScaleMode
    c = colorbar(topo_axis);
    c.Units = 'pixels';
    c.Position = [50,10,20,panelSize(4)-20];
    c.Label.String = 'ERSP (dB)';
    c.Color = h.scheme.Axis.AxisColor.Value;

end
for ii = 1:mapinfo.nStatMaps
    topo_axis = subplot(1,mapinfo.nmaps + mapinfo.nStatMaps,mapinfo.nmaps+ii, 'Parent', h.panel_topo);
    cmap = colormap(topo_axis, 'parula');
    ms = max(abs(mapinfo.FScores), [], 'all');
    wwu_topoplot(mapinfo.FScores(:,ii), p.TFData.chanlocs, 'axishandle', topo_axis,'colormap', cmap, 'maplimits', [0,ms],  'style', 'map', 'numcontour', 0, 'gridscale', gridscale,...
        'emarker2', statSigMarker); 
    topo_axis.Title.String ='F Score';
    topo_axis.Title.Interpreter = 'none';
    topo_axis.Title.Color = h.scheme.Axis.AxisColor.Value;

    c = colorbar(topo_axis);
    c.Units = 'pixels';
    c.Position = [panelSize(3) - 70,10,20,panelSize(4)-20];
    c.Label.String = 'F Score';
    c.Color = h.scheme.Axis.AxisColor.Value;

end

%***************************************************************************
%main erp drawing function
function callback_plotersp(hObject, event, h)

topostyle = h.check_topolayout.Value;
showgrid = true;


p = h.figure.UserData;
try
    data = fetchERSPData(p.study, p.TFData, h, topostyle);
catch me
    uialert(h.figure, me.message, me.identifier);
    return
end

%can't plot it if it is not there!
if isempty(data)
    return
end

%cannot plot in topostyle with only 1 channel
if data.nchan == 1
    topostyle = false;
    progress = [];
else
    progress = uiprogressdlg(h.figure, 'Cancelable',false, 'Message', 'Plotting data...');
end
    
 cfg = [];
if topostyle
    layout = tf_topo_layout(data.chanlocs);
    if length(layout) > length(data.chanlocs)
        cfg.showaxistitle = false;
    else
        cfg.showaxistitle = true;
    end
    cfg.legendfontsize = 10;
    cfg.axisfontsize = 10;
else
    if data.nchan < 10
        cfg.showaxistitle = true;
        cfg.axisfontsize = 12;
        cfg.legendfontsize = 12;
    else
        cfg.showaxistitle = false;
        cfg.legendfontsize = 10;
        cfg.axisfontsize = 9;
    end     
    layout = tf_grid_layout(data.nchan + ~cfg.showaxistitle);    
end

cfg.showaxis = true;
cfg.scaleindiv = false;

delete(allchild(h.panel_ersp))

p.paxis = [];
for ch = 1:data.nchan
    if ~isempty(progress)
        progress.Value = ch/data.nchan;
    end
    cfg.axis = uiaxes(h.panel_ersp,"Units", "Normalized","Position",layout(ch).Position );
    cfg.axis.Visible = false;
    cfg.axis.Toolbar.Visible = 'off';
    cfg.axis.ButtonDownFcn = {@callback_handlemouseevents, h};
    cfg.axis.PickableParts = 'all';
    cfg.axis.HitTest = 'on';
    cfg.axis.Title.Color = h.scheme.Axis.AxisColor.Value;
    cfg.channel = ch;
    cfg = tfplot(data, cfg);
    cfg.axis.FontSize = cfg.axisfontsize;
    cfg.axis.FontName = h.scheme.Axis.Font.Value;
    cfg.axis.XColor = h.scheme.Axis.AxisColor.Value;
    cfg.axis.YColor = h.scheme.Axis.AxisColor.Value;
    cfg.axis.BackgroundColor = h.scheme.Axis.BackgroundColor.Value;
    cfg.axis.XGrid = showgrid;
    cfg.axis.YGrid = showgrid;
    cfg.axis.Layer = 'top';
    cfg.axis.GridColor = 'k';
    cfg.axis.GridAlpha = .2;
    p.paxis(ch) = cfg.axis;
    cfg.axis.Visible = true;
    if ~cfg.showaxistitle
        cfg.axis.XTickLabel = [];
        cfg.axis.YTickLabel = [];
    end
end

if ~cfg.showaxistitle
    %%create a legend
    legend_axis = uiaxes(h.panel_ersp, "Units", "Normalized", 'Position', layout(end).Position);
    legend_axis.XLim = [p.TFData.times(1), p.TFData.times(end)];
    legend_axis.YLim = [p.TFData.freqs(1), p.TFData.freqs(end)];
    legend_axis.Color = 'none';% h.panel_ersp.BackgroundColor;
    legend_axis.XLabel.String = 'Time (ms)';
    legend_axis.YLabel.String = 'Freq (Hz)';
    legend_axis.CLim = cfg.limits;
    legend_axis.Title.String = 'Legend';
    legend_axis.Title.Color = h.scheme.Axis.AxisColor.Value;
    legend_axis.FontSize = cfg.legendfontsize;
    legend_axis.XColor = h.scheme.Axis.AxisColor.Value;
    legend_axis.YColor = h.scheme.Axis.AxisColor.Value;
    
    line(legend_axis, [0,0], [p.TFData.freqs(1), p.TFData.freqs(end)], 'Color', 'k');
    
    if ~cfg.scaleindiv 
        cb = colorbar(legend_axis);
        cb.Label.String = 'ERSP (dB)';
        cb.FontSize = cfg.legendfontsize;
    end
else
    cb = colorbar(p.paxis(ch));
    cb.Label.String = 'ERSP (dB)';
    cb.Units = 'pixels';
    cp = cb.Position;
    cp(1) = cp(1) + cp(3) + 30;
    cb.Position = cp;
    cb.Color = h.scheme.Axis.AxisColor.Value;
end
draw_tf_cursors(h, p)
if ~isempty(progress); close(progress); end
drawnow
%
plot_topos(h)
h.figure.UserData = p;

%% start of tfdata specific plotting functions
%************************************************************************
function cfg = tfplot(data, cfg)
    %dont do alot of checking here since this will only be called
    %internally

    %extract data
    if ndims(data.ersp) > 2
        d = squeeze(data.ersp(cfg.channel,:,:));
        m = squeeze(data.statMask(cfg.channel,:,:));
    else
        d = data.ersp;
        m = data.statMask;
    end

    %set an transparency level for plotting stuff that is not significant;
    m(m==0) = .15;

    if isfield(cfg, 'scaleindiv') && cfg.scaleindiv

        limits =  max(max(abs(d))) * .8;
        limits = [-limits, limits];
        cfg.addcolorbar = true;
    elseif isfield(cfg, 'limits')
        limits = cfg.limits;
        cfg.addcolorbar = false;
        
    else
        limits = max(data.ersp, [], 'all');
        limits = [-limits, limits] * .6;
        cfg.addcolorbar = false;
     
    end
    cfg.limits = limits;

    colormap(cfg.axis,'jet');
    i = imagesc(cfg.axis, data.times, data.freqs, d, limits);
    i.PickableParts = 'none';
    i.AlphaData = m;
    cfg.axis.XLim = [data.times(1), data.times(end)]; 
    cfg.axis.YLim = [data.freqs(1), data.freqs(end)];
    cfg.axis.YDir = 'normal';
    
    if cfg.addcolorbar
        colorbar(cfg.axis)
    end

    if data.times(1) < 0
        l = line(cfg.axis, [0,0], [data.freqs(1), data.freqs(end)]);
        l.Color = 'k';
        l.LineWidth = 1;
    end
    cfg.axis.Title.String = data.labels{cfg.channel};

    if ~cfg.showaxis
        cfg.axis.XAxis.Visible = false;
        cfg.axis.YAxis.Visible = false;
    elseif cfg.showaxistitle
        cfg.axis.XLabel.String = 'Time (ms)';
        cfg.axis.YLabel.String = "Freq (Hz)";
    end
    
%***********************************************************************
function layout = tf_topo_layout(chanlocs)
%return the position of axis for plotting ersp based on a topo style of
%this should be done only once during loading

[y,x] = wwu_ChannelProjection(chanlocs, 'Normalize', true);
%make the data fit inside the limits
%x = x * .90 + .05;
%y = y * .90 + .05;

minDist = inf;
for ii = 1:length(x)-1
    for jj = ii+1:length(x)
        if ii ~= jj
            d = pdist([x(ii), y(ii); x(jj), y(jj)], 'euclidean');
            if d < minDist
                minDist = d;
                mxX = abs(x(ii) - x(jj));
                mxY = abs(y(ii) - y(jj));
            end
        end
    end
end

mxX = max(mxX, mxY);
mxY = mxX;
if minDist > .3
    minDist = minDist*.75;
    mxX = mxX * .75;
    mxY = mxY * .75;
end
x = x * (1-minDist);
y = y * (1-minDist);
width = mxX;%minDist;% * sind(45);
height = mxY;%width;
%x = x - height/2;
%y = y - width/2;

for ii = 1:length(x)
    layout(ii).Position = [x(ii), y(ii), width, height];
    layout(ii).Name = chanlocs(ii).labels;
end
if minDist < .2 
%layout(end+1).Position = [max(x)-(width * .5), min(y), width*1.5, height* 1.5];
    layout(end+1).Position = [1-(width*1.5) , 0, width*1.5, height*1.5];
    layout(end).Name = 'Legend';
end

%***********************************************************************
function layout = tf_grid_layout(nchan)
%determines the plot layout based on the desired number of channels to
%display

%try for an equal number of rows and columns

rows = round(sqrt(nchan));
cols = ceil(nchan/rows);

limits = [0.01, .99]; %leaves a small border around the area
x_dist = range(limits)./ cols;
y_dist = range(limits)./ rows;
width = x_dist - .04;
height = y_dist - .01;

chcount = 0;
for rr = 1: rows
    for cc = 1:cols
        x = limits(1) + (cc - 1) * x_dist;
        y = limits(2) - (rr * y_dist);
        chcount = chcount + 1;
        layout(chcount).Position = [x,y,width,height ];
    end
end
% ***********************************************************************
function initialize_gui(handles, TFData)
handles.spinner_time.Value = TFData.times(1);
handles.spinner_time.Step = diff(TFData.times(1:2));
handles.spinner_time.Limits= [TFData.times(1), TFData.times(end)];

handles.spinner_twidth.Value = 0;
handles.spinner_twidth.Limits = [0, TFData.times(end)];
handles.spinner_twidth.Step = diff(TFData.times(1:2));
    
handles.spinner_freq.Value =  TFData.freqs(1);
handles.spinner_freq.Step = diff(TFData.freqs(1:2));
handles.spinner_freq.Limits = [TFData.freqs(1), TFData.freqs(end)];
    
handles.spinner_fwidth.Value = TFData.freqs(end);
handles.spinner_fwidth.Limits = [TFData.freqs(1), TFData.freqs(end)];
handles.spinner_fwidth.Step = diff(TFData.freqs(1:2));

handles.edit_statTimeStart.Limits = [TFData.times(1), TFData.times(end)];
handles.edit_statTimeStart.Value = TFData.times(1);    
handles.edit_statTimeEnd.Limits = [TFData.times(1), TFData.times(end)];
handles.edit_statTimeEnd.Value = TFData.times(end);

handles.edit_statFreqStart.Limits = [TFData.freqs(1), TFData.freqs(end)];
handles.edit_statFreqStart.Value = TFData.freqs(1);
handles.edit_statFreqEnd.Limits = [TFData.freqs(1), TFData.freqs(end)];
handles.edit_statFreqEnd.Value = TFData.freqs(end);

% *************************************************************************
function callback_togglestatspanel(hObject, ~, h)
    currentTab = str2double(hObject.Tag);
    for ii = 1:3
        h.tab_stats(ii).Visible = false;
    end
    h.tab_stats(currentTab).Visible = true;
% *************************************************************************
function callback_toggleoptionsspanel(hObject, ~, h)
    currentTab = str2double(hObject.Tag);
    for ii = 1:3
        h.tab_poptions(ii).Visible = 'off';
    end
    h.tab_poptions(currentTab).Visible = 'on';
% ***********************************************************************
function handles = build_gui(handles)

scheme = handles.scheme; % cut down on typing
W = round(scheme.ScreenWidth * .6);
if scheme.ScreenHeight < 1080
    H = scheme.ScreenHeight;
else
    H = 1080;
end

figpos = [420, scheme.ScreenHeight - H, W, H];
handles.figure = uifigure(...
    'Position', figpos,...
    'NumberTitle','off',...
    'Menubar', 'none',...
    'Name', 'ERSP Plotting and Analysis Tool');
drawnow;
dlg = uiprogressdlg(handles.figure,'Title', 'ERSP Viewer', 'Cancelable',false,...
    'Indeterminate', true);
dlg.Message = 'Loading ERSP data...this may take several seconds';
drawnow;

dlg.Message = 'Building primary display';
handles.gl = uigridlayout('Parent', handles.figure,...
    'ColumnWidth',{280, '1x'},...
    'RowHeight', {35, '1x','1x','1x', '1x'},...
    'BackgroundColor',scheme.Window.BackgroundColor.Value);

%panel for holding the topo plot
handles.panel_topo = uipanel(...
    'Parent', handles.gl,...
    'AutoResizeChildren', false,...
    'BackgroundColor', scheme.Panel.BackgroundColor.Value,...
    'HighlightColor', scheme.Panel.BorderColor.Value,...
    'BorderType', 'none',...
    'ForegroundColor', scheme.Panel.FontColor.Value,...
    'FontSize', scheme.Panel.FontSize.Value,...
    'FontName', scheme.Panel.Font.Value);
handles.panel_topo.Layout.Column = 2;
handles.panel_topo.Layout.Row = 5;

handles.panel_ersp = uipanel(...
    'Parent', handles.gl,...
    'Units', 'normalized',...
    'BackgroundColor', scheme.Panel.BackgroundColor.Value,...
    'HighlightColor', scheme.Panel.BorderColor.Value,...
    'ForegroundColor', scheme.Panel.FontColor.Value,...
    'FontSize', scheme.Panel.FontSize.Value,...
    'FontName', scheme.Panel.Font.Value);
handles.panel_ersp.Layout.Column = 2;
handles.panel_ersp.Layout.Row = [1 4];

pause(.5);
drawnow;

%**************************************************************************
% %Create a panel to hold the  line plot options
% handles.panel_plotopts = uipanel(...
%     'Parent', handles.gl,...
%     'BackgroundColor', scheme.Panel.BackgroundColor.Value,...
%     'HighlightColor', scheme.Panel.BorderColor.Value,...
%     'ForegroundColor', scheme.Panel.FontColor.Value,...
%     'FontSize', scheme.Panel.FontSize.Value,...
%     'FontName', scheme.Panel.Font.Value);
% handles.panel_plotopts.Layout.Column = 2;
% handles.panel_plotopts.Layout.Row = 1;

%check box for stacking or spreading the plot

drawnow;

%**************************************************************************
%Create a panel to hold the  plotting options of condition, channel and
%subject
handles.panel_po = uipanel('Parent', handles.gl,...
    'Title', 'Select Content to Plot',....
    'BackgroundColor', scheme.Panel.BackgroundColor.Value,...
    'HighlightColor', scheme.Panel.BorderColor.Value,...
    'ForegroundColor', scheme.Panel.FontColor.Value,...
    'FontSize', scheme.Panel.FontSize.Value,...
    'FontName', scheme.Panel.Font.Value);
handles.panel_po.Layout.Column = 1;
handles.panel_po.Layout.Row = [1 3];
drawnow;
pause(1)

psh = handles.panel_po.InnerPosition;

handles.tab_ops = uibuttongroup(...
    'Parent', handles.panel_po,...
    'OuterPosition', [0,psh(4)-30,psh(3), 30],...
    'BackgroundColor',scheme.Window.BackgroundColor.Value);

handles.button_poptions(1) = uibutton(handles.tab_ops,...
    'Position', [0, 0, psh(3)/3, 30],...
    'Text', 'Data',...
    'BackgroundColor',scheme.Window.BackgroundColor.Value,...
    'FontColor',scheme.Panel.FontColor.Value,....
    'FontSize',scheme.Panel.FontSize.Value,...
    'FontName',scheme.Panel.Font.Value,...
    'Tag', '1');

handles.button_poptions(2) = uibutton(handles.tab_ops,...
    'Position', [psh(3)/3, 0, psh(3)/3, 30],...
    'Text', 'ROI',...
    'BackgroundColor',scheme.Window.BackgroundColor.Value,...
    'FontColor',scheme.Panel.FontColor.Value,....
    'FontSize',scheme.Panel.FontSize.Value,...
    'FontName',scheme.Panel.Font.Value,...
    'Tag', '2');

handles.button_poptions(3) = uibutton(handles.tab_ops,...
    'Position', [psh(3)/3*2, 0, psh(3)/3, 30],...
    'Text', 'Options',...
    'BackgroundColor',scheme.Window.BackgroundColor.Value,...
    'FontColor',scheme.Panel.FontColor.Value,....
    'FontSize',scheme.Panel.FontSize.Value,...
    'FontName',scheme.Panel.Font.Value,...
    'Tag', '3');

handles.tab_poptions(1) = uipanel(...
    'Parent', handles.panel_po,...
    'Title', 'Data',...
    'Position', [0,0,psh(3), psh(4)-30],...
    'BackgroundColor', scheme.Panel.BackgroundColor.Value,...
    'HighlightColor', scheme.Panel.BorderColor.Value,...
    'ForegroundColor', scheme.Panel.FontColor.Value,...
    'FontSize', scheme.Panel.FontSize.Value,...
    'FontName', scheme.Panel.Font.Value);

handles.tab_poptions(2) = uipanel(...
    'Parent', handles.panel_po,...
    'Title', 'Region of Interest',...
    'Position', [0,0,psh(3), psh(4)-30],...
    'Visible', 'off',...    
    'BackgroundColor', scheme.Panel.BackgroundColor.Value,...
    'HighlightColor', scheme.Panel.BorderColor.Value,...
    'ForegroundColor', scheme.Panel.FontColor.Value,...
    'FontSize', scheme.Panel.FontSize.Value,...
    'FontName', scheme.Panel.Font.Value);

handles.tab_poptions(3) = uipanel(...
    'Parent', handles.panel_po,...
    'Title', 'Options',...
    'Position', [0,0,psh(3), psh(4)-30],...
    'Visible', 'off',...    
    'BackgroundColor', scheme.Panel.BackgroundColor.Value,...
    'HighlightColor', scheme.Panel.BorderColor.Value,...
    'ForegroundColor', scheme.Panel.FontColor.Value,...
    'FontSize', scheme.Panel.FontSize.Value,...
    'FontName', scheme.Panel.Font.Value);

drawnow;
pause(1)

psh = handles.tab_poptions(3).InnerPosition(4);

uilabel('Parent', handles.tab_poptions(1),...
    'Position', [10,psh-30,100,20],...
    'Text', 'Conditions to plot',...
    'FontColor', scheme.Label.FontColor.Value,...
    'FontSize', scheme.Label.FontSize.Value,...
    'FontName', scheme.Label.Font.Value);

uilabel('Parent', handles.tab_poptions(1),...
    'Position', [10,psh-220,100,20],...
    'Text', 'Channels to plot',...
    'FontColor', scheme.Label.FontColor.Value,...
    'FontSize', scheme.Label.FontSize.Value,...
    'FontName', scheme.Label.Font.Value);

uilabel('Parent', handles.tab_poptions(1),...
    'Position', [155,psh-220,100,20],...
    'Text', 'Subjects to plot',...
    'FontColor', scheme.Label.FontColor.Value,...
    'FontSize', scheme.Label.FontSize.Value,...
    'FontName', scheme.Label.Font.Value);

handles.list_condition = uilistbox(...
    'Parent', handles.tab_poptions(1), ...
    'Position', [10, psh-180, 250, 150 ],...
    'BackgroundColor', scheme.Dropdown.BackgroundColor.Value, ...
    'FontColor', scheme.Dropdown.FontColor.Value,...
    'FontName', scheme.Dropdown.Font.Value,...
    'FontSize', scheme.Dropdown.FontSize.Value,...
    'MultiSelect', 'on');

handles.check_allchans = uicheckbox(...
    'Parent', handles.tab_poptions(1),...
    'Position', [10,psh-250,125,20],...
    'Text', 'All Channels',...
    'Value', 0,...
    'FontName',scheme.Checkbox.Font.Value,...
    'FontSize', scheme.Checkbox.FontSize.Value,...
    'FontColor',scheme.Checkbox.FontColor.Value);

handles.list_channels = uilistbox(...
    'Parent', handles.tab_poptions(1),...
    'Position', [10,10,125,psh-270],...
    'BackgroundColor', scheme.Dropdown.BackgroundColor.Value, ...
    'FontColor', scheme.Dropdown.FontColor.Value,...
    'FontName', scheme.Dropdown.Font.Value,...
    'FontSize', scheme.Dropdown.FontSize.Value,...
    'Enable', 'off',...
    'MultiSelect', 'on');

handles.list_subject = uilistbox(...
    'Parent', handles.tab_poptions(1),...
    'Position', [145,10,125,psh-240],...
    'BackgroundColor', scheme.Dropdown.BackgroundColor.Value, ...
    'FontColor', scheme.Dropdown.FontColor.Value,...
    'FontName', scheme.Dropdown.Font.Value,...
    'FontSize', scheme.Dropdown.FontSize.Value,...
    'MultiSelect', 'off');

%frequency mapping panel

uilabel('Parent', handles.tab_poptions(2),...
    'Position', [10,psh-40,100,20],...
    'Text', 'Start Time',...
    'FontColor', scheme.Label.FontColor.Value,...
    'FontSize', scheme.Label.FontSize.Value,...
    'FontName', scheme.Label.Font.Value);

uilabel('Parent', handles.tab_poptions(2),...
    'Position', [10,psh-70,100,20],...
    'Text', 'End Time',...
    'FontColor', scheme.Label.FontColor.Value,...
    'FontSize', scheme.Label.FontSize.Value,...
    'FontName', scheme.Label.Font.Value);

handles.spinner_time = uispinner(...
    'Parent', handles.tab_poptions(2),...
    'Position', [150,psh-40,120,20],...
    'BackgroundColor',scheme.Dropdown.BackgroundColor.Value,...
    'FontColor', scheme.Dropdown.FontColor.Value,...
    'FontName', scheme.Dropdown.Font.Value,...
    'FontSize', scheme.Dropdown.FontSize.Value,...
    'RoundFractionalValues', 'off',...
    'ValueDisplayFormat', '%3.2f ms');

handles.spinner_twidth = uispinner(...
    'Parent', handles.tab_poptions(2),...
    'Position', [150,psh-70,120,20],...
    'BackgroundColor',scheme.Dropdown.BackgroundColor.Value,...
    'FontColor', scheme.Dropdown.FontColor.Value,...
    'FontName', scheme.Dropdown.Font.Value,...
    'FontSize', scheme.Dropdown.FontSize.Value,...
    'Value', 0, ...
    'RoundFractionalValues', 'off',...
    'ValueDisplayFormat', '%3.2f ms');

uilabel('Parent', handles.tab_poptions(2),...
    'Position', [10,psh-100,100,20],...
    'Text', 'Start Freq',...
    'FontColor', scheme.Label.FontColor.Value,...
    'FontSize', scheme.Label.FontSize.Value,...
    'FontName', scheme.Label.Font.Value);

uilabel('Parent', handles.tab_poptions(2),...
    'Position', [10,psh-130,100,20],...
    'Text', 'End Freq',...
    'FontColor', scheme.Label.FontColor.Value,...
    'FontSize', scheme.Label.FontSize.Value,...
    'FontName', scheme.Label.Font.Value);

handles.spinner_freq = uispinner(...
    'Parent', handles.tab_poptions(2),...
    'Position', [150,psh-100,120,20],...
    'BackgroundColor',scheme.Dropdown.BackgroundColor.Value,...
    'FontColor', scheme.Dropdown.FontColor.Value,...
    'FontName', scheme.Dropdown.Font.Value,...
    'FontSize', scheme.Dropdown.FontSize.Value,...
    'RoundFractionalValues', 'off',...
    'ValueDisplayFormat', '%3.2f Hz');

handles.spinner_fwidth = uispinner(...
    'Parent', handles.tab_poptions(2),...
    'Position', [150,psh-130,120,20],...
    'BackgroundColor',scheme.Dropdown.BackgroundColor.Value,...
    'FontColor', scheme.Dropdown.FontColor.Value,...
    'FontName', scheme.Dropdown.Font.Value,...
    'FontSize', scheme.Dropdown.FontSize.Value,...
    'RoundFractionalValues', 'off',...
    'ValueDisplayFormat', '%3.2f Hz');

msg = 'Use the controls to change the start and end times/frequencies for the regions of interest.';
msg = sprintf('%s\n\nScalp maps represent the mean ERSP within the ROI.', msg);
msg = sprintf('%s\n\nUse shift+arrow keys to move the ROI location.\nClick and drag the ROI edge to change its position.', msg);
msg = sprintf('%s\n\nLeft click and drag anywhere in the ERSP plot to create a new ROI.', msg);

uilabel('Parent', handles.tab_poptions(2),...
    'Position', [10,psh-320,270,140],...
    'Text', msg,...
    'FontColor', scheme.Label.FontColor.Value,...
    'FontSize', scheme.Label.FontSize.Value,...
    'FontName', scheme.Label.Font.Value,...
    'HorizontalAlignment','left',...
    'WordWrap','on',...
    'VerticalAlignment','top');

%plot options panel

handles.check_topolayout = uicheckbox(...
    'Parent', handles.tab_poptions(3),...
    'Position', [10, psh-40, 100, 20],...
    'Text', 'Topo Layout', ...
    'Value', 0,...
    'FontName',scheme.Checkbox.Font.Value,...
    'FontSize', scheme.Checkbox.FontSize.Value,...
    'FontColor',scheme.Checkbox.FontColor.Value);

drawnow;
%**************************************************************************
%panel for the overlay
handles.panel_statoverlay = uipanel('Parent', handles.gl,...
    'Title', 'Plots and Overlays',...
    'BackgroundColor', scheme.Panel.BackgroundColor.Value,...
    'HighlightColor', scheme.Panel.BorderColor.Value,...
    'ForegroundColor', scheme.Panel.FontColor.Value,...
    'FontSize', scheme.Panel.FontSize.Value,...
    'FontName', scheme.Panel.Font.Value);
handles.panel_statoverlay.Layout.Column = 1;
handles.panel_statoverlay.Layout.Row = [4 5];
%need a pause here for the screen to update and the new sizes of the
%control
drawnow;
pause(.5)
psh = handles.panel_statoverlay.InnerPosition;
psh(1) = 0; psh(2) = 0;
inner_panel_pos = psh; inner_panel_pos(4) = psh(4) - 30;

handles.grp_statselect = uibuttongroup(...
    'Parent',handles.panel_statoverlay,...
    'Position',[psh(1), psh(4)-30, psh(3), 30]);

handles.button_statstab(1) = uibutton(handles.grp_statselect, ...
    'Position', [0, 0, psh(3)/3, 30],...
    'Text', 'Stats Tests',...
    'BackgroundColor', scheme.Panel.BackgroundColor.Value,...
    'FontName', scheme.Panel.Font.Value,...
    'FontColor', scheme.Panel.FontColor.Value,...
    'FontSize', scheme.Panel.FontSize.Value,...
    'Tag', '1');

handles.button_statstab(2) = uibutton(handles.grp_statselect, ...
    'Position', [psh(3)/3, 0, psh(3)/3, 30],...
    'Text', 'New Test',...
    'BackgroundColor', scheme.Panel.BackgroundColor.Value,...
    'FontName', scheme.Panel.Font.Value,...
    'FontColor', scheme.Panel.FontColor.Value,...
    'FontSize', scheme.Panel.FontSize.Value,...
    'Tag', '2');


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
    'Title', 'New Stats Test',...
    'Position', inner_panel_pos,...
    'BackgroundColor', scheme.Panel.BackgroundColor.Value,...
    'HighlightColor', scheme.Panel.BorderColor.Value,...
    'FontName',scheme.Panel.Font.Value,...
    'FontSize', scheme.Panel.FontSize.Value,...
    'ForegroundColor', scheme.Panel.FontColor.Value,...
    'Visible','off','Scrollable','on');

drawnow
%the mass univariate approach is more connected to the GLM for  time/freq
%data
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

%*************************************************************************
%tab for the statistical analysis

uilabel('Parent', handles.tab_stats(2),...
    'Position', [10, 465, 100, 20],...
    'Text', 'Factor',...
    'FontName', scheme.Label.Font.Value,...
    'FontSize', scheme.Label.FontSize.Value,...
    'FontColor', scheme.Label.FontColor.Value);

uilabel('Parent', handles.tab_stats(2),...
    'Position', [120, 465, 50, 20],...
    'Text', 'Levels',...
    'FontName', scheme.Label.Font.Value,...
    'FontSize', scheme.Label.FontSize.Value,...
    'FontColor', scheme.Label.FontColor.Value);

handles.edit_factors = uieditfield(...
    'Parent', handles.tab_stats(2),...
    'Position', [10, 445, 100, 20],...
    'BackgroundColor',scheme.Edit.BackgroundColor.Value,...
    'FontName', scheme.Edit.Font.Value,...
    'FontSize', scheme.Edit.FontSize.Value,...
    'FontColor', scheme.Edit.FontColor.Value);

handles.edit_levels = uieditfield(...
    handles.tab_stats(2),'numeric',...
    'Limits', [2,inf],...
    'Position', [115, 445, 30, 20],...
    'BackgroundColor',scheme.Edit.BackgroundColor.Value,...
    'FontName', scheme.Edit.Font.Value,...
    'FontSize', scheme.Edit.FontSize.Value,...
    'FontColor', scheme.Edit.FontColor.Value,...
    'Value', 2);

handles.button_factadd = uibutton(...
    'Parent', handles.tab_stats(2),...
    'Position', [150, 445, 55, 20],...
    'Text', 'Add',...
    'BackgroundColor', scheme.Button.BackgroundColor.Value,...
    'FontColor', scheme.Button.FontColor.Value,...
    'FontName', scheme.Button.Font.Value,...
    'FontSize', scheme.Button.FontSize.Value,...
    'Tag', 'Add');

handles.button_factremove = uibutton(...
    'Parent', handles.tab_stats(2),...
    'Position', [210, 445, 60, 20],...
    'Text', 'Remove',...
    'BackgroundColor', scheme.Button.BackgroundColor.Value,...
    'FontColor', scheme.Button.FontColor.Value,...
    'FontName', scheme.Button.Font.Value,...
    'FontSize', scheme.Button.FontSize.Value,...
     'Tag','Remove', ...
     'Enable', 'off');

handles.list_model = uilistbox(...
    'Parent', handles.tab_stats(2),...
    'Position', [10, 370, 260, 60],...
    'BackgroundColor',scheme.Edit.BackgroundColor.Value,...
    'FontName', scheme.Edit.Font.Value,...
    'FontSize', scheme.Edit.FontSize.Value,...
    'FontColor', scheme.Edit.FontColor.Value,...
    'Items', {'[Insert Factors Here]'});

uilabel('Parent', handles.tab_stats(2),...
    'Position', [10,340, 200, 20],...
    'Text', 'Test type',...
    'FontName', scheme.Label.Font.Value,...
    'FontSize', scheme.Label.FontSize.Value,...
    'FontColor', scheme.Label.FontColor.Value);

handles.dropdown_MUtype = uidropdown(...
    'Parent', handles.tab_stats(2),...
    'Position', [10,320,260,20],...
    'BackgroundColor',scheme.Dropdown.BackgroundColor.Value,...
    'FontColor', scheme.Dropdown.FontColor.Value,...
    'FontName', scheme.Dropdown.Font.Value,...
    'FontSize', scheme.Dropdown.FontSize.Value,...
    'Items', {'Parametric', 'Permutation'},...
    'ItemsData', {'TF_Parametric', 'TF_Permutation'},...
    'Value','TF_Permutation');


uilabel('Parent', handles.tab_stats(2),...
    'Position', [10,290, 200, 20],...
    'Text', 'Multiple Comparison Correction',...
    'FontName', scheme.Label.Font.Value,...
    'FontSize', scheme.Label.FontSize.Value,...
    'FontColor', scheme.Label.FontColor.Value);

handles.dropdown_MCtype = uidropdown(...
    'Parent', handles.tab_stats(2),...
    'Position', [10,270,260,20],...
    'BackgroundColor',scheme.Dropdown.BackgroundColor.Value,...
    'FontColor', scheme.Dropdown.FontColor.Value,...
    'FontName', scheme.Dropdown.Font.Value,...
    'FontSize', scheme.Dropdown.FontSize.Value,...
    'Items', {'None','Max', 'Cluster', 'TFCE','Bonferroni', 'Holm', 'Hochberg', 'FDR'},...
    'ItemsData', {'no', 'max', 'cluster', 'tfce', 'bonferroni', 'holm', 'hochberg', 'fdr'});

uilabel('Parent', handles.tab_stats(2),...
    'Position', [10,240, 200, 20],...
    'Text', 'Cluster Statistic',...
    'FontName', scheme.Label.Font.Value,...
    'FontSize', scheme.Label.FontSize.Value,...
    'FontColor', scheme.Label.FontColor.Value);

handles.dropdown_ClustStat = uidropdown(...
    'Parent', handles.tab_stats(2),...
    'Position', [10,220,260,20],...
    'BackgroundColor',scheme.Dropdown.BackgroundColor.Value,...
    'FontColor', scheme.Dropdown.FontColor.Value,...
    'FontName', scheme.Dropdown.Font.Value,...
    'FontSize', scheme.Dropdown.FontSize.Value,...
    'Enable', 'off',...
    'Items', {'Max Sum', 'Max Size', 'Weighted Cluster Mass',},...
    'ItemsData', {'maxsum', 'maxsize', 'wcm'});

uilabel('Parent', handles.tab_stats(2),...
    'Position', [10,180, 100, 20],...
    'Text', 'Time Window',...
    'FontName', scheme.Label.Font.Value,...
    'FontSize', scheme.Label.FontSize.Value,...
    'FontColor', scheme.Label.FontColor.Value);

handles.edit_statTimeStart = uieditfield(...
    handles.tab_stats(2),'numeric',...
    'Position', [90, 180, 85, 20],...
    'ValueDisplayFormat', '%0.2f ms',...
    'BackgroundColor',scheme.Edit.BackgroundColor.Value,...
    'FontName', scheme.Edit.Font.Value,...
    'FontSize', scheme.Edit.FontSize.Value,...
    'FontColor', scheme.Edit.FontColor.Value);

handles.edit_statTimeEnd = uieditfield(...
    handles.tab_stats(2),'numeric',...
    'Position', [185, 180, 85, 20],...
    'ValueDisplayFormat', '%0.2f ms',...
    'BackgroundColor',scheme.Edit.BackgroundColor.Value,...
    'FontName', scheme.Edit.Font.Value,...
    'FontSize', scheme.Edit.FontSize.Value,...
    'FontColor', scheme.Edit.FontColor.Value);

uilabel('Parent', handles.tab_stats(2),...
    'Position', [10,150, 100, 20],...
    'Text', 'Freq Window',...
    'FontName', scheme.Label.Font.Value,...
    'FontSize', scheme.Label.FontSize.Value,...
    'FontColor', scheme.Label.FontColor.Value);

handles.edit_statFreqStart = uieditfield(...
    handles.tab_stats(2),'numeric',...
    'Position', [90, 150, 85, 20],...
    'ValueDisplayFormat', '%0.2f ms',...
    'BackgroundColor',scheme.Edit.BackgroundColor.Value,...
    'FontName', scheme.Edit.Font.Value,...
    'FontSize', scheme.Edit.FontSize.Value,...
    'FontColor', scheme.Edit.FontColor.Value);

handles.edit_statFreqEnd = uieditfield(...
    handles.tab_stats(2),'numeric',...
    'Position', [185, 150, 85, 20],...
    'ValueDisplayFormat', '%0.2f ms',...
    'BackgroundColor',scheme.Edit.BackgroundColor.Value,...
    'FontName', scheme.Edit.Font.Value,...
    'FontSize', scheme.Edit.FontSize.Value,...
    'FontColor', scheme.Edit.FontColor.Value);

handles.check_massunivavetime = uicheckbox(...
    'Parent', handles.tab_stats(2),...
    'Position', [10, 120, 200, 20],...
    'Text', 'Average points in time window',...
    'FontName', scheme.Checkbox.Font.Value,...
    'FontSize', scheme.Checkbox.FontSize.Value,...
    'FontColor', scheme.Checkbox.FontColor.Value);

handles.check_massunivavefreq = uicheckbox(...
    'Parent', handles.tab_stats(2),...
    'Position', [10, 100, 200, 20],...
    'Text', 'Average points in frequency window',...
    'FontName', scheme.Checkbox.Font.Value,...
    'FontSize', scheme.Checkbox.FontSize.Value,...
    'FontColor', scheme.Checkbox.FontColor.Value);

handles.check_massunivchans = uicheckbox(...
    'Parent', handles.tab_stats(2),...
    'Position', [10, 80, 200, 20],...
    'Text', 'Use currently displayed channels',...
    'FontName', scheme.Checkbox.Font.Value,...
    'FontSize', scheme.Checkbox.FontSize.Value,...
    'FontColor', scheme.Checkbox.FontColor.Value);

uilabel('Parent', handles.tab_stats(2),...
    'Position', [10, 50, 200, 20],...
    'Text', 'Alpha',...
    'FontName', scheme.Label.Font.Value,...
    'FontSize', scheme.Label.FontSize.Value,...
    'FontColor', scheme.Label.FontColor.Value);

handles.edit_massunivalpha = uieditfield(...
    handles.tab_stats(2),'numeric',...
    'Position', [60, 50, 50, 20],...
    'Limits', [0, 1],...
    'ValueDisplayFormat', '%g',...
    'Value', .05,...
    'BackgroundColor',scheme.Edit.BackgroundColor.Value,...
    'FontName', scheme.Edit.Font.Value,...
    'FontSize', scheme.Edit.FontSize.Value,...
    'FontColor', scheme.Edit.FontColor.Value);

handles.button_massuniv = uibutton(...
    'Parent', handles.tab_stats(2),...
    'Position', [65, 10, 150, 30],...
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

handles.menu_map = uimenu('Parent', handles.figure, 'Label', 'Scalp maps');
handles.menu_mapquality = uimenu('Parent', handles.menu_map, 'Label', 'Print Quality', 'Checked', 'off');
handles.menu_scale = uimenu('Parent', handles.menu_map, 'Label', 'Map Scale Limits');
handles.menu_mapscale(1) = uimenu('Parent', handles.menu_scale, 'Label', 'ALl maps on the same scale', 'Checked', 'on', 'Tag', 'Auto');
handles.menu_mapscale(2) = uimenu('Parent', handles.menu_scale, 'Label', 'Scale individually', 'Checked', 'off', 'Tag', 'Always');

%**************************************************************************
%assign callbacks to the uicontrols and menu items
%turn off for now until I get events back up and running for ersp
%handles.figure.WindowButtonDownFcn = {@callback_handlemouseevents, handles};
handles.figure.WindowButtonUpFcn = {@callback_handlemouseevents, handles};
handles.figure.WindowButtonMotionFcn = {@callback_handlemouseevents, handles};
handles.figure.WindowKeyPressFcn = {@callback_handlekeyevents, handles};

handles.check_topolayout.ValueChangedFcn = {@callback_plotersp, handles};
handles.spinner_distance.ValueChangedFcn = {@callback_plotersp, handles};
handles.spinner_time.ValueChangedFcn = {@update_cursor_position, handles};
handles.spinner_freq.ValueChangedFcn = {@update_cursor_position, handles};
handles.spinner_twidth.ValueChangedFcn = {@update_cursor_position, handles};
handles.spinner_fwidth.ValueChangedFcn = {@update_cursor_position, handles};


handles.list_condition.ValueChangedFcn = {@callback_plotersp, handles};
handles.check_allchans.ValueChangedFcn = {@callback_toggleallchannel, handles};
handles.list_channels.ValueChangedFcn = {@callback_plotersp, handles};
handles.list_subject.ValueChangedFcn = {@callback_plotersp, handles};

handles.button_factadd.ButtonPushedFcn = {@callback_changefactors, handles};
handles.button_factremove.ButtonPushedFcn = {@callback_changefactors, handles};
handles.dropdown_MUtype.ValueChangedFcn = {@callback_togglestatsoption, handles};
handles.dropdown_MCtype.ValueChangedFcn = {@callback_toggleMCOption, handles};
handles.button_massuniv.ButtonPushedFcn = {@callback_runstatstest, handles};


handles.check_MUoverlay.ValueChangedFcn = {@callback_plotersp, handles};
handles.dropdown_MUtest.ValueChangedFcn = {@callback_populateMUtestinfo, handles};
handles.dropdown_MUeffect.ValueChangedFcn = {@callback_changestatselection, handles};
handles.dropdown_ANOVAtest.ValueChangedFcn = {@callback_populateANOVAtestinfo, handles};
handles.button_plotANOVA.ButtonPushedFcn = {@callback_plotANOVAresult, handles};

handles.menu_refresh.MenuSelectedFcn = {@callback_reloadfiles, handles, true};
handles.menu_conditions.MenuSelectedFcn = {@callback_removebinsandstats,handles};
handles.menu_stats.MenuSelectedFcn = {@callback_removebinsandstats,handles};
handles.menu_ANOVA.MenuSelectedFcn = {@callback_removebinsandstats, handles};

handles.menu_cursoradd.MenuSelectedFcn = {@callback_managecursors, handles};
handles.menu_cursorsub.MenuSelectedFcn = {@callback_managecursors, handles};
handles.menu_cursormean.MenuSelectedFcn = {@callback_togglemcs, handles};

handles.menu_mapquality.MenuSelectedFcn = {@callback_togglemapquality, handles};
for ii = 1:2
    handles.menu_mapscale(ii).MenuSelectedFcn = {@callback_toggletopomenustate, handles};
end

for ii = 1:2
    handles.button_statstab(ii).ButtonPushedFcn = {@callback_togglestatspanel, handles};
    handles.button_poptions(ii).ButtonPushedFcn = {@callback_toggleoptionsspanel, handles};
end

close(dlg);
            
    

    


