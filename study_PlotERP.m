function study_PlotERP(study, filename)

fprintf('Opening ERP plotting and analysis tool...\n');

if isempty(filename)
    error('No valid file was found')
end

load(filename{1}, '-mat');

%sometimes the time points used variable is a cell vector and sometimes it is
%an integer vector.  I will harmonize it here rather than figure out why

if isfield(GND, 'F_tests')
    if ~isempty(GND.F_tests)
        for ii = 1:length(GND.F_tests)
            if iscell(GND.F_tests(ii).used_tpt_ids)
                GND.F_tests(ii).used_tpt_ids = cell2mat(GND.F_tests(ii).used_tpt_ids);
            end
        end
    end
end

%build the figure
p = plot_params;
p.GND = GND;
p.study = study;
p.ts_colors = lines(length(GND.bin_info));  %use the lines colormap for defining plot colors
clear GND;

W = round(p.screenwidth * .6);
if p.screenheight < 1080
    H = p.screenheight;
else
    H = 1080;
end
figpos = [420, p.screenheight - H, W, H];

handles.figure = uifigure(...
    'Color', p.backcolor,...
    'Position', figpos,...
    'NumberTitle', p.numbertitle,...
    'Menubar', p.menubar,...
    'Name', 'hcnd ERP Ploting and Analysus Tool');

%handles.figure.Visible = false;

handles.gl = uigridlayout('Parent', handles.figure,...
    'ColumnWidth',{280, '1x'},...
    'RowHeight', {35, '1x','1x','1x', '1x'});

%panel for holding the topo plot
handles.panel_topo = uipanel(...
    'Parent', handles.gl,...
    'AutoResizeChildren', false);
handles.panel_topo.Layout.Column = 2;
handles.panel_topo.Layout.Row = 5;

handles.axis_erp = uiaxes(...
    'Parent', handles.gl,...
    'Units', 'normalized',...
    'OuterPosition', [0,0,1,1],...
    'Interactions',[]);
handles.axis_erp.Layout.Column = 2;
handles.axis_erp.Layout.Row = [2 4];
handles.axis_erp.Toolbar.Visible = 'off';

%**************************************************************************
%Create a panel to hold the  line plot options
handles.panel_plotopts = uipanel(...
    'Parent', handles.gl);
handles.panel_plotopts.Layout.Column = 2;
handles.panel_plotopts.Layout.Row = 1;

%check box for stacking or spreading the plot
handles.check_stacked = uicheckbox(...
    'Parent', handles.panel_plotopts,...
    'Position', [10, 7, 100, 20],...
    'FontColor', p.labelfontcolor,...
    'Text', 'Stacked', ...
    'Value', 1);

uilabel('Parent', handles.panel_plotopts,...
    'Position', [110, 7, 100, 20],...
    'Text', 'Channel Distance',...
    'FontColor', p.labelfontcolor);

handles.spinner_distance = uispinner(...
    'Parent', handles.panel_plotopts,...
    'Position', [220,7,80,20],...
    'FontColor', p.textfieldfontcolor,...
    'BackgroundColor', p.textfieldbackcolor,...
    'Value', 100, ...
    'Limits', [1, inf],...
    'RoundFractionalValues', 'on',...
    'ValueDisplayFormat', '%i %%');


[fp,fn,~] = fileparts(filename{:});
handles.label_filename = uilabel(...
    'Parent', handles.panel_plotopts,...
    'Position', [310,7,80,20],...
    'Text', 'Average File:',...
    'FontColor', p.labelfontcolor);

handles.label_filename = uilabel(...
    'Parent',handles.panel_plotopts,...
    'Position', [400,7,200,20],...
    'Text', fn,...
    'BackgroundColor', [.85,.85,.85],...
    'FontColor', p.textfieldfontcolor,...
    'HorizontalAlignment', 'center');

handles.label_filename = uilabel(...
    'Parent', handles.panel_plotopts,...
    'Position', [610,7,80,20],...
    'Text', 'Folder:',...
    'FontColor', p.labelfontcolor);

handles.label_filename = uilabel(...
    'Parent', handles.panel_plotopts,...
    'Position', [700,7,540,20],...
    'Text', fp,...
    'BackgroundColor',  [.85,.85,.85],...
    'FontColor', p.textfieldfontcolor,...
    'HorizontalAlignment', 'center');


%**************************************************************************
%Create a panel to hold the  plotting options of condition, channel and
%subject
handles.panel_po = uipanel('Parent', handles.gl,...
    'BackgroundColor', p.backcolor,...
    'Title', 'Select Content to Plot');
handles.panel_po.Layout.Column = 1;
handles.panel_po.Layout.Row = [1 3];
drawnow;
pause(.1);

psh = handles.panel_po.InnerPosition(4);

uilabel('Parent', handles.panel_po,...
    'Position', [10,psh-30,100,20],...
    'Text', 'Conditions to plot',...
    'FontColor', p.labelfontcolor);

uilabel('Parent', handles.panel_po,...
    'Position', [10,psh-220,100,20],...
    'Text', 'Channels to plot',...
    'FontColor', p.labelfontcolor);

uilabel('Parent', handles.panel_po,...
    'Position', [155,psh-220,100,20],...
    'Text', 'Subjects to plot',...
    'FontColor', p.labelfontcolor);

handles.list_condition = uilistbox(...
    'Parent', handles.panel_po, ...
    'Position', [10, psh-180, 250, 150 ],...
    'BackgroundColor', p.textfieldbackcolor, ...
    'FontColor', p.textfieldfontcolor',...
    'MultiSelect', 'on');

handles.check_allchans = uicheckbox(...
    'Parent', handles.panel_po,...
    'Position', [10,psh-250,125,20],...
    'Text', 'All Channels',...
    'Value', 1);

handles.list_channels = uilistbox(...
    'Parent', handles.panel_po,...
    'Position', [10,10,125,psh-270],...
    'Enable', 'off',...
    'MultiSelect', 'on');

handles.list_subject = uilistbox(...
    'Parent', handles.panel_po,...
    'Position', [145,10,125,psh-240],...
    'MultiSelect', 'off');


%**************************************************************************
%panel for the overlay
handles.panel_statoverlay = uipanel('Parent', handles.gl,...
    'BackgroundColor', p.backcolor,...
    'Title', 'Plots and Overlays');
handles.panel_statoverlay.Layout.Column = 1;
handles.panel_statoverlay.Layout.Row = [4 5];
%need a pause here for the screen to update and the new sizes of the
%control
drawnow;
pause(1);
drawnow;
psh = handles.panel_statoverlay.InnerPosition;

handles.tab_stats = uitabgroup(...
    'Parent', handles.panel_statoverlay,...
    'OuterPosition', [0,0,psh(3), psh(4)]);

handles.tab_massuniv = uitab(...
    'Parent', handles.tab_stats,...
    'Title', 'Mass Univariate');

handles.tab_ANOVA = uitab(...
    'Parent', handles.tab_stats,...
    'Title', 'GLM');

handles.tab_newtest = uitab(...
    'Parent', handles.tab_stats,...
    'Title', 'New Stats Test');

drawnow
psh = handles.tab_massuniv.InnerPosition(4);

handles.check_MUoverlay = uicheckbox(...
    'Parent', handles.tab_massuniv,...
    'Position', [10,psh-60,260,20],...
    'Text', 'Overlay Statistical Results',...
    'Value', 0);

uilabel('Parent', handles.tab_massuniv,...
    'Position', [10, psh-100, 260, 20],...
    'Text', 'Select a test',...
    'FontColor', p.labelfontcolor);

handles.dropdown_MUtest = uidropdown(...
    'Parent', handles.tab_massuniv,...
    'Position', [10,psh-120, 260, 20],...
    'BackgroundColor', p.textfieldbackcolor,...
    'FontColor', p.textfieldfontcolor);

uilabel('Parent', handles.tab_massuniv,...
    'Position', [10, psh-160, 260, 20],...
    'Text', 'Select an effect',...
    'FontColor', p.labelfontcolor);

handles.dropdown_MUeffect = uidropdown(...
    'Parent', handles.tab_massuniv,...
    'Position', [10,psh-180, 260, 20],...
    'BackgroundColor', p.textfieldbackcolor,...
    'FontColor', p.textfieldfontcolor);

uilabel('Parent', handles.tab_massuniv,...
    'Position', [10, psh-220, 260, 20],...
    'Text', 'Test information',...
    'FontColor', p.labelfontcolor);

handles.tree_massuniv = uitree(...
    'Parent', handles.tab_massuniv,...
    'Position', [10,10,260,psh-230]);

%**********************
%ANOVA tab
uilabel('Parent', handles.tab_ANOVA,...
    'Position', [10, psh-60, 260, 20],...
    'Text', 'Select a test',...
    'FontColor', p.labelfontcolor);

handles.dropdown_ANOVAtest = uidropdown(...
    'Parent', handles.tab_ANOVA,...
    'Position', [10,psh-80, 260, 20],...
    'BackgroundColor', p.textfieldbackcolor,...
    'FontColor', p.textfieldfontcolor);

handles.button_plotANOVA = uibutton(...
    'Parent', handles.tab_ANOVA,...
    'Position', [185, psh-105, 85, 20],...
    'Text', 'Plot Results',...
    'BackgroundColor', p.buttoncolor,...
    'FontColor', p.buttonfontcolor);

uilabel('Parent', handles.tab_ANOVA,...
    'Position', [10, psh-135, 260, 20],...
    'Text', 'Test information',...
    'FontColor', p.labelfontcolor);

handles.tree_ANOVA = uitree(...
    'Parent', handles.tab_ANOVA,...
    'Position', [10,10,260,psh-145]);



%*************************************************************************
%tab for the statistical analysis

uilabel('Parent', handles.tab_newtest,...
    'Position', [10, psh-60, 100, 20],...
    'Text', 'Factor',...
    'FontColor', p.labelfontcolor);

uilabel('Parent', handles.tab_newtest,...
    'Position', [120, psh-60, 50, 20],...
    'Text', 'Levels',...
    'FontColor', p.labelfontcolor);

handles.edit_factors = uieditfield(...
    'Parent', handles.tab_newtest,...
    'Position', [10, psh-80, 100, 20],...
    'BackgroundColor', p.textfieldbackcolor', ...
    'FontColor', p.textfieldfontcolor);

handles.edit_levels = uieditfield(...
    handles.tab_newtest,'numeric',...
    'Limits', [2,inf],...
    'Position', [115, psh-80, 30, 20],...
    'BackgroundColor', p.textfieldbackcolor', ...
    'FontColor', p.textfieldfontcolor,...
    'Value', 2);

handles.button_factadd = uibutton(...
    'Parent', handles.tab_newtest,...
    'Position', [150, psh-80, 55, 20],...
    'Text', 'Add',...
    'BackgroundColor', p.buttoncolor,...
    'FontColor', p.buttonfontcolor,...
    'Tag', 'Add');

handles.button_factremove = uibutton(...
    'Parent', handles.tab_newtest,...
    'Position', [210, psh-80, 60, 20],...
    'Text', 'Remove',...
    'BackgroundColor', p.buttoncolor,...
    'FontColor', p.buttonfontcolor,...
     'Tag','Remove', ...
     'Enable', 'off');

handles.list_model = uilistbox(...
    'Parent', handles.tab_newtest,...
    'Position', [10, psh-190, 260, 100],...
    'BackgroundColor', p.textfieldbackcolor,...
    'FontColor',p.textfieldfontcolor,...
    'Items', {'[Insert Factors Here]'});

uilabel('Parent', handles.tab_newtest,...
    'Position', [10,psh-220, 200, 20],...
    'Text', 'Test to conduct',...
    'FontColor', p.labelfontcolor);

handles.dropdown_MUtype = uidropdown(...
    'Parent', handles.tab_newtest,...
    'Position', [10,psh-240,260,20],...
    'BackgroundColor', p.textfieldbackcolor,...
    'FontColor', p.textfieldfontcolor,...
    'Items', {'F-max permutation test', 'Cluster mass permutation test', 'False discovery rate', 'General linear model'},...
    'ItemsData', {'FmaxGND', 'FclustGND', 'FfdrGND', 'ANOVA'});

uilabel('Parent', handles.tab_newtest,...
    'Position', [10,psh-270, 100, 20],...
    'Text', 'Data to select',...
    'FontColor', p.labelfontcolor);

handles.bgroup = uibuttongroup(...
    'Parent', handles.tab_newtest,...
    'Position', [10, psh-320, 260,50]);

handles.radio_amp = uiradiobutton(...
    'Parent', handles.bgroup,...
    'Text', 'Amplitude',...
    'Position', [5,25,85,20],...
    'Enable', 'off');

handles.radio_pospeak = uiradiobutton(...
    'Parent', handles.bgroup,...
    'Text', 'Latency (+)',...
    'Position', [90,25,85,20],...
    'Enable', 'off');

handles.radio_negpeak = uiradiobutton(...
    'Parent', handles.bgroup,...
    'Text', 'Latency (-)',...
    'Position', [175,25,80,20],...
    'Enable', 'off');

handles.radio_peakplusminus = uiradiobutton(...
    'Parent', handles.bgroup,...
    'Text', 'Peak +/-',...
    'Position', [5,3,80,20],...
    'Enable', 'off');

handles.radio_peak2peak = uiradiobutton(...
    'Parent', handles.bgroup,...
    'Text', 'Peak to peak',...
    'Position', [90,3,120,20],...
    'Enable', 'off');


uilabel('Parent', handles.tab_newtest,...
    'Position', [10,psh-360, 100, 20],...
    'Text', 'Window',...
    'FontColor', p.labelfontcolor);

handles.edit_massunivstart = uieditfield(...
    handles.tab_newtest,'numeric',...
    'Position', [90, psh-360, 85, 20],...
    'Limits', [p.GND.time_pts(1), p.GND.time_pts(end)],...
    'ValueDisplayFormat', '%0.2f ms',...
    'Value', p.GND.time_pts(1),...
    'BackgroundColor', p.textfieldbackcolor,...
    'Fontcolor', p.textfieldfontcolor);

handles.edit_massunivend = uieditfield(...
    handles.tab_newtest,'numeric',...
    'Position', [185, psh-360, 85, 20],...
    'Limits', [p.GND.time_pts(1), p.GND.time_pts(end)],...
    'ValueDisplayFormat', '%0.2f ms',...
    'Value', p.GND.time_pts(end),...
    'BackgroundColor', p.textfieldbackcolor,...
    'Fontcolor', p.textfieldfontcolor);

handles.check_massunivave = uicheckbox(...
    'Parent', handles.tab_newtest,...
    'Position', [10, psh-380, 200, 20],...
    'Text', 'Average points in window',...
    'FontColor', p.textfieldfontcolor');

    
handles.check_massunivchans = uicheckbox(...
    'Parent', handles.tab_newtest,...
    'Position', [10, psh-400, 200, 20],...
    'Text', 'Use currently displayed channels',...
    'FontColor', p.textfieldfontcolor');


uilabel('Parent', handles.tab_newtest,...
    'Position', [10, psh-430, 200, 20],...
    'Text', 'Alpha',...
    'FontColor', p.labelfontcolor);

handles.edit_massunivalpha = uieditfield(...
    handles.tab_newtest,'numeric',...
    'Position', [60, psh-430, 50, 20],...
    'Limits', [0, 1],...
    'ValueDisplayFormat', '%g',...
    'Value', .05,...
    'BackgroundColor', p.textfieldbackcolor,...
    'Fontcolor', p.textfieldfontcolor);

handles.button_massuniv = uibutton(...
    'Parent', handles.tab_newtest,...
    'Position', [65, 5, 150, 30],...
    'Text', 'Run Test',...
    'BackgroundColor', p.buttoncolor,...
    'FontColor', p.buttonfontcolor);


%************************************************************************
% create menus
%*************************************************************************
handles.menu_file = uimenu('Parent', handles.figure, 'Label', 'File');
handles.menu_refresh = uimenu('Parent', handles.menu_file, 'Label', 'Refresh Study and ERP');
handles.menu_conditions = uimenu('Parent', handles.menu_file, 'Label', '&Delete selected condition', 'Separator', 'on', 'Tag', 'bin', 'Accelerator', 'D');
handles.menu_stats = uimenu('Parent', handles.menu_file, 'Label', 'Delete selected Mass &Univ Test', 'Tag', 'MU', 'Accelerator', 'U');
handles.menu_ANOVA = uimenu('Parent', handles.menu_file, 'Label', 'Delete selected &GLM Test', 'Tag', 'ANOVA', 'Accelerator', 'G');

handles.menu_cursor = uimenu('Parent', handles.figure,'Label', 'Cursor');
handles.menu_cursoradd = uimenu('Parent', handles.menu_cursor,'Label', 'Add Cursor', 'Tag', 'add', 'Accelerator', 'A');
handles.menu_cursorsub = uimenu('Parent', handles.menu_cursor,'Label', 'Remove Cursor', 'Tag', 'subtract', 'Accelerator', 'X');

handles.menu_map = uimenu('Parent', handles.figure, 'Label', 'Scalp maps');
handles.menu_mapquality = uimenu('Parent', handles.menu_map, 'Label', 'Print Quality', 'Checked', 'off');
handles.menu_scale = uimenu('Parent', handles.menu_map, 'Label', 'Map Scale Limits');
handles.menu_mapscale(1) = uimenu('Parent', handles.menu_scale, 'Label', 'ALl maps on the same scale', 'Checked', 'on', 'Tag', 'Auto');
handles.menu_mapscale(2) = uimenu('Parent', handles.menu_scale, 'Label', 'Scale individually', 'Checked', 'off', 'Tag', 'Always');


%**************************************************************************
%assign callbacks to the uicontrols and menu items
handles.figure.WindowButtonDownFcn = {@callback_handlemouseevents, handles};
handles.figure.WindowButtonUpFcn = {@callback_handlemouseevents, handles};
handles.figure.WindowButtonMotionFcn = {@callback_handlemouseevents, handles};
handles.figure.WindowKeyPressFcn = {@callback_handlekeyevents, handles};

handles.check_stacked.ValueChangedFcn = {@callback_ploterp, handles};
handles.spinner_distance.ValueChangedFcn = {@callback_ploterp, handles};

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

handles.menu_refresh.MenuSelectedFcn = {@callback_reloadfiles, handles, true};
handles.menu_conditions.MenuSelectedFcn = {@callback_removebinsandstats,handles};
handles.menu_stats.MenuSelectedFcn = {@callback_removebinsandstats,handles};
handles.menu_ANOVA.MenuSelectedFcn = {@callback_removebinsandstats, handles};

handles.menu_cursoradd.MenuSelectedFcn = {@callback_managecursors, handles};
handles.menu_cursorsub.MenuSelectedFcn = {@callback_managecursors, handles};

handles.menu_mapquality.MenuSelectedFcn = {@callback_togglemapquality, handles};
for ii = 1:2
    handles.menu_mapscale(ii).MenuSelectedFcn = {@callback_toggletopomenustate, handles};
end

%initialize the cursor
cinfo.cursor = [];
cinfo.currentcursor = [];
cinfo.dragging = false;

%save the cursor information
handles.axis_erp.UserData = cinfo;
handles.figure.UserData = p;

%initialize the displays and plot the data
callback_reloadfiles([],[],handles, false)
callback_toggleallchannel([],handles.check_allchans,handles);
%callback_ploterp([],[],handles);
event.Source.Tag = 'add';
callback_managecursors([], event, handles);

handles.figure.Visible = true;
fprintf('...done\n');

%***************************************************************************
function callback_toggletopomenustate(hObject, event, h)

for ii = 1:2
    h.menu_mapscale(ii).Checked = false;
end
hObject.Checked = true;
plot_topos(h)

%**************************************************************
function callback_togglemapquality(hObject, event, h)

    hObject.Checked = ~hObject.Checked
    plot_topos(h);

%*************************************************************************
function callback_plotANOVAresult(hObject, event,h)

p = h.figure.UserData;

if ~isfield(p.GND, 'ANOVA')
    error('No ANOVA data for this GND file');
end

if isempty(p.GND.ANOVA)
    error('No ANOVA data for this GND file');
end

ANOVAnum = h.dropdown_ANOVAtest.Value;
r = p.GND.ANOVA(ANOVAnum);
study_PlotANOVAresults(r);

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
            outfile = wwu_buildpath(GND.filepath, GND.filename);
            save(outfile,'GND', '-mat');
            callback_reloadfiles([],[],h, 1);
        end
        
    case 'MU'
        
        c_stat = h.dropdown_MUtest.Value;
        if isempty(c_stat)
            return
        end
        
        response = uiconfirm(h.figure, sprintf('Are you sure you want to delete %s?', h.dropdown_MUtest.Items{c_stat}), 'Confirm Delete');
        if contains(response, 'OK')
            GND.F_tests(c_stat) = [];
            outfile = wwu_buildpath(GND.filepath, GND.filename);
            save(outfile,'GND', '-mat');
            callback_reloadfiles([],[],h, 1);
            
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
            GND = save_GND(GND);
            
            callback_reloadfiles([],[],h, 1);
            
            if ~isempty(GND.ANOVA) %if we did not delete them all
                if length(h.dropdown_ANOVAtest.Items) >= c_stat
                    h.dropdown_ANOVAtest.Value = c_stat;
                else
                    h.dropdown_ANOVAtest.Value = h.dropdown_ANOVAtest.ItemsData(end);
                end
            end
        end
end
%% ***********************************************************************
function GND = save_GND(GND)

outfile = [GND.filepath,GND.filename];
%do some checking here in future if necessary
GND.saved = 'yes';
save(outfile, 'GND', '-mat')

%*************************************************************************
%function to handle adding and removing factors
function callback_changefactors(hObject, event, h)

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
function callback_runstatstest(hObject, event, h)


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
stats.winstart = h.edit_massunivstart.Value;
stats.winend = h.edit_massunivend.Value;
stats.meanwindow = h.check_massunivave.Value;
stats.alpha = h.edit_massunivalpha.Value;
stats.ave_channels = false;
stats.eegchans = [];

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
callback_reloadfiles([],[],h,1)

%set the last item in the dropdown as active.
%h.dropdown_ANOVAtest.Value = h.dropdown_ANOVAtest.ItemsData(end);
%callback_plotANOVAresult([],[],h);
       
%*************************************************************************
%function to handle when user changes the status of the "All Channel" option
function callback_toggleallchannel(hObject, event, h)

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

callback_ploterp([],[],h);

%**************************************************************************
%callback_reloadfiles - reloads the erp and study files and refreshes the
%erp display to reflect any changes.
function callback_reloadfiles(hObject, event, h, reload_flag)


h.figure.Pointer = 'watch';
drawnow;

%get the current information from the figure userdata
p = h.figure.UserData;


%if there is an explicit request to reload - otherwise the displays will
%just be refreshed.  This allows the same code to be used to initialize the
%displays
if reload_flag
    
    
    %update with the most recent data file and the most recent study file
    erp_filename =wwu_buildpath(p.GND.filepath, p.GND.filename);
    load(erp_filename, '-mat');
    
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

%  populate the informaito about the mass univariate tests
if isfield(p.GND,'F_tests')
    if ~isempty(p.GND.F_tests)
        disable = false;
        n = arrayfun(@(x) join(x.factors), p.GND.F_tests);
        n = cellfun(@(x) strrep(x, ' ', ' X '), n, 'UniformOutput', false);
        t = num2cell(1:length(p.GND.F_tests));
        tn = cellfun(@num2str, t, 'un', 0);
        labels = strcat(tn, '. ', n);
        
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
        n = arrayfun(@(x) join(x.factors), p.GND.ANOVA);
        n = cellfun(@(x) strrep(x, ' ', ' X '), n, 'UniformOutput', false);
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

%draw the cursor
rect_x = [cursor.time, cursor.time+1,cursor.time+1,...
    cursor.time+3,cursor.time+3,...
    cursor.time-2,cursor.time-2,...
    cursor.time, cursor.time];

yl = h.axis_erp.YLim;
yr = .015 * range(yl);
rect_y = [yl(2),yl(2),yl(1)+yr, yl(1)+yr, yl(1), yl(1), yl(1)+yr, yl(1)+yr, yl(2)];

ps = polyshape(rect_x, rect_y);
hold(h.axis_erp, 'on');
pg = plot(h.axis_erp, ps);
pg.Annotation.LegendInformation.IconDisplayStyle = 'off';
h.axis_erp.YLim = yl;
hold(h.axis_erp, 'off');

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
%function [data, channel_labels] getdatatoplot(study, GND, h, mode]
function [d, s, labels_or_times, ch_out, cond_sel] = getdatatoplot(study, GND, h, cursors)

d = [];
labels_or_times = [];
ch_out = [];
cond_sel = [];
s = [];

%if cursor informaiton is passed we will send back only the information
%specific to the time of each cursor, otherwise the entire time series will
%be returned.
if nargin < 4
    mapping_mode = false;
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

%get the time points to plot or map
if mapping_mode
    t = sort([cursors.time]); %sort so that maps always increase in time
    pt = zeros(size(t));
    for ii = 1:length(t)
        [~,pt(ii)] = min(abs(t(ii) - GND.time_pts));  %get the exact time of the cursor
    end
else
    pt =1:length(GND.time_pts); %get all the points 
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




%get the channels from the selected conditions
ch_sel = ch(find(ch(:,1)),1);
ch_out = ch_sel;    %send this back to the calling function
if mapping_mode
    ch_sel = 1:length(GND.chanlocs); %overwrite channel selection if we are mapping
end

%it is possible that no channels are selected because just the channel
%groups can be selected
if ~isempty(ch_sel)
    if sbj==0 %this is the grand average
        d = GND.grands(ch_sel,pt,cond_sel);
        %get the statistics information
        if mass_univ_overlay
            
            %initialize the array to the full size of the data
             stat = zeros(size(GND.grands,1), size(GND.grands,2));
             pval = adj_pval<r.desired_alphaORq;
             %provde a thresholded version of the F-scores for mapping
             %in future there will be an option to turn this on and off
            if mapping_mode 
                pval = pval .* F_obs;
            end
            if contains(r.mean_wind, 'yes')
                pval = repmat(pval, 1, length(r.used_tpt_ids));
            end
            
            stat(r.used_chan_ids,r.used_tpt_ids) = pval; %fill the relevant portion of the  matrix
           %% stat(r.used_chan_ids,r.used_tpt_ids) = sig_clust; %fill the relevant portion of the  matrix
            
            s = stat(ch_sel, pt); %select the part the user requested
        end 
    else
        d = GND.indiv_erps(ch_sel, pt, cond_sel, sbj);
        %no stats information for individual subject data
    end    
    labels_or_times = {GND.chanlocs(ch_sel).labels};
end

%if this is for the mapping routine, return the times of the maps instead
%of the labels of the channels
if mapping_mode
    labels_or_times = t;
end

%now get the channel group information 
ch_groups = ch(find(ch(:,2)),2);

%dont do this part of either there are no channel groups selected or this
%function was called from the plot_topo function
if ~isempty(ch_groups) && ~mapping_mode
    %get the means of any channel gorups
    ch_group_data = zeros(length(ch_groups), length(GND.time_pts), length(cond_sel));
    ch_group_s = zeros(length(ch_groups), length(GND.time_pts));
    for ii = 1:length(ch_groups)
        for jj = 1:length(cond_sel)
            if sbj == 0
                ch_group_data(ii,pt,jj) = squeeze(mean(GND.grands(study.chgroups(ch_groups(ii)).chans,:,cond_sel(jj)),1));
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

%************************************************************************
% plot the topographic maps indicated by the active cursors
function plot_topos(h)

if h.menu_mapquality.Checked
    gridscale =  300;
else 
    gridscale = 96;
end


%get map plotting options
for ii = 1:2
    if h.menu_mapscale(ii).Checked
        break
    end
end

scale_option = ii;

has_stat = false;  %assume there are no stats
c = h.axis_erp.UserData;



p = h.figure.UserData;
my_h = h.panel_topo.UserData; %get handles to the subplots

[d, s, map_time, ch_out, cond_num] = getdatatoplot(p.study, p.GND, h, c.cursor);
if scale_option ==1; map_scale = max(max(max(abs(d)))); end


if ~isempty(s)
    d(:,:,end+1) = s;
    has_stat = true;
end
n_maps = length(c.cursor);
if n_maps < 1
    ch = h.panel_topo.Children;
    delete(ch);
    return
end

%there are three possible states here
%the first is when there is only one condition being display
comp_conds = true;
n_conds = size(d,3);
total_maps = n_conds * n_maps;

if n_conds==1 || (n_conds>1 && n_maps==1)
    
    max_cols = 5 ;
    
    nrows = ceil(total_maps/max_cols);
    ncols = ceil(total_maps/nrows);    
    if size(d,3)==1; comp_conds = false; end
    
else 
    
    max_cols = size(d,3);% n_maps;
    ncols = max_cols;
    nrows = n_maps;%size(d,3);
 
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
            ms = [0,max(abs(v))];
            if ms(2)==0; ms(2) = 1; end %just in case there are no stat sig results
            title_string = 'F-score';
            pmask = v>0;
            cmap = hot;
            cmap(1,:) = p.backcolor;            
            eval_string = '''pmask'', pmask, ''conv'', ''off''';

        else
            ms = [-map_scale; map_scale];
            title_string =  h.list_condition.Items{cond_num(jj)};
            cmap = jet;
        end
        
        %build the command string for the topoplot'
        mapstring = 'wwu_topoplot(v, p.GND.chanlocs, ''axishandle'', my_h(pcount),''colormap'', cmap, ''maplimits'', ms,  ''style'', ''map'', ''numcontour'', 0, ''gridscale'', gridscale'; 
        
        %change it based on the different options
        if length(ch_out) < length(p.GND.chanlocs)
            mapstring = [mapstring, ',  ''emarker2'', {ch_out, ''o'', ''k'', msize, 1}'];
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
        end
        
        if ii==1  && comp_conds
            my_h(pcount).Title.String = title_string;
            my_h(pcount).Title.Interpreter = 'none';
        end
        my_h(pcount).XLabel.String = sprintf('%5.2f ms', map_time(ii) );
        my_h(pcount).XLabel.Visible = true;
        my_h(pcount).OuterPosition(2) = 0;
        my_h(pcount).OuterPosition(4) = 1;
       
    end
end

if scale_option ==1
    cb = colorbar(my_h(end));
    cb.Units = 'pixels';
    cb.Position = [40, 10, 16, h.panel_topo.Position(4)-20];
    cb.Label.String = '\muV';
end
h.panel_topo.UserData = my_h;
drawnow nocallbacks
%***************************************************************************
%main erp drawing function
function callback_ploterp(hObject, event, h)

stacked = h.check_stacked.Value;
MUoverlay = h.check_MUoverlay.Value;
separation = h.spinner_distance.Value/100;

clust_colors = lines;

p = h.figure.UserData;
[d, s, labels,~,cond_sel] = getdatatoplot(p.study, p.GND, h);

%account for the fact that plotting will be upside down in order to get
%the channel data in order from top to bottom
d = d * -1;

%can't plot it if it is not there!
if isempty(d)
    return
end

%preallocate for the legend names
%I am not preallocating for the line structures because I am lazy
legend_names = cell(1,size(d,3));
legend_handles = [];

% if the user has selected the butter fly plot option where 
% are stacked on the same origin.
if ~stacked  
    spread_amnt = max(max(max(abs(d)))) * separation;   %get the plotting scale    
    v = 1:1:size(d,1);
    spread_matrix = repmat(v' * spread_amnt, 1, size(d,2), size(d,3));
    d = d + spread_matrix;
end

%main plotting loop - plot the time series for each condition
for ii = 1:size(d,3)
    
    ph = plot(h.axis_erp, p.GND.time_pts, squeeze(d(:,:,ii))', 'Color', p.ts_colors(ii, :), 'LineWidth', 1);
    hold(h.axis_erp, 'on');
    
    legend_handles(ii) = ph(1);
    legend_names(ii) = h.list_condition.Items(cond_sel(ii));
    
    %just storing this loop here for now
    if MUoverlay && ~isempty(s)
        hold(h.axis_erp, 'on');
        dd = squeeze(d(:,:,ii));
        tt = repmat(p.GND.time_pts, size(s,1),1);
        
        %get different colors for different clusters
%       'MarkerFaceColor',p.ts_colors(ii, :), 'Marker', 'o',...
%      
%         scatter(h.axis_erp, tt(s>0)', dd(s>0)',60, clust_colors(s(s>0),:),...
%             'Marker', 'o',...
%             'SizeData', 60,...
%             'MarkerEdgeColor', p.ts_colors(ii, :),'MarkerFaceAlpha', .75,...
%             'MarkerEdgeAlpha', .75);
%     end
  
        splot = scatter(h.axis_erp, tt(s>0)', dd(s>0)',60,'filled');
        splot.CData = clust_colors(s(s>0),:);
        splot.ColorVariable

    end
end
colormap lines;
hold(h.axis_erp, 'off');
    
%handle axes and scaling differently depending on whether the plot is
%stacked or not
if stacked
    h.axis_erp.YLim = [min(min(min(d))) * 1.1, max(max(max(d))) * 1.1];
    
    l = line(h.axis_erp, h.axis_erp.XLim, [0,0],...
        'Color', [.5,.5,.5], 'LineWidth', 1.5);
    l.Annotation.LegendInformation.IconDisplayStyle = 'off';
    
    h.axis_erp.YTickMode = 'auto';
    h.axis_erp.YTickLabel = -h.axis_erp.YTick;
    h.axis_erp.YLabel.String = 'microvolts';
    
else    
    h.axis_erp.YLim = [min(min(min(d))) - (spread_amnt * .1), max(max(max(d))) + (spread_amnt * .1)];
    h.axis_erp.YTick = spread_matrix(:,1);
    h.axis_erp.YTickLabel = labels;
    
    h.axis_erp.YLabel.String = 'microvolts x channel';
    
end


%draw a vertical line at 0 ms;
time_lock_ms = min(abs(p.GND.time_pts));
l = line(h.axis_erp, [time_lock_ms, time_lock_ms], h.axis_erp.YLim,...
    'Color', [.5,.5,.5], 'LineWidth', 1.5);
l.Annotation.LegendInformation.IconDisplayStyle = 'off';

h.axis_erp.XGrid = 'on'; h.axis_erp.YGrid = 'on';
h.axis_erp.XLim = [p.GND.time_pts(1), p.GND.time_pts(end)];
h.axis_erp.XLabel.String = 'Time (ms)';
h.axis_erp.YDir = 'reverse';

if length(legend_names) > 6
    legend_columns = 6;
else
    legend_columns = length(legend_names);
end
lg = legend(h.axis_erp, legend_handles, legend_names, 'box', 'off', 'Location', 'NorthOutside', 'NumColumns', legend_columns,'Interpreter', 'none');
lg.Color = p.backcolor;
lg.LineWidth = 2;

%rebuild and plot existing cursors to fit the currently scaled data
rebuild_cursors(h)
plot_topos(h)

