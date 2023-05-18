function study_PlotERSP(study, filename)

fprintf('Opening ERSP plotting and analysis tool...\n');

if isempty(filename)
    error('No valid file was found')
end


%sometimes the time points used variable is a cell vector and sometimes it is
%an integer vector.  I will harmonize it here rather than figure out why

%build the figure
p = plot_params;
p.study = study;



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
    'Name', 'hcnd ERSP Plotting and Analysis Tool');

drawnow;

dlg = uiprogressdlg(handles.figure,'Title', 'ERSP Viewer', 'Cancelable',false,...
    'Indeterminate', true);
dlg.Message = 'Loading ERSP data...this may take several seconds';
drawnow;

fprintf('...loading the data file.  This may takes several seconds...');
load(filename{1}, '-mat');
fprintf('done\n');
p.TFData = TFData;
%p.topo_layout = tf_topo_layout(TFData.chanlocs);
p.ts_colors = lines(length(TFData.bindesc));  %use the lines colormap for defining plot colors
clear TFData;

dlg.Message = 'Building primary display';

handles.gl = uigridlayout('Parent', handles.figure,...
    'ColumnWidth',{280, '1x'},...
    'RowHeight', {35, '1x','1x','1x', '1x'});

%panel for holding the topo plot
handles.panel_topo = uipanel(...
    'Parent', handles.gl,...
    'AutoResizeChildren', false);
handles.panel_topo.Layout.Column = 2;
handles.panel_topo.Layout.Row = 5;

handles.panel_ersp = uipanel(...
    'Parent', handles.gl,...
    'Units', 'normalized');
handles.panel_ersp.Layout.Column = 2;
handles.panel_ersp.Layout.Row = [2 4];

pause(.5);
drawnow;

%**************************************************************************
%Create a panel to hold the  line plot options
handles.panel_plotopts = uipanel(...
    'Parent', handles.gl);
handles.panel_plotopts.Layout.Column = 2;
handles.panel_plotopts.Layout.Row = 1;

%check box for stacking or spreading the plot
handles.check_topolayout = uicheckbox(...
    'Parent', handles.panel_plotopts,...
    'Position', [10, 7, 100, 20],...
    'FontColor', p.labelfontcolor,...
    'Text', 'Topo Layout', ...
    'Value', 0);


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


drawnow;

%**************************************************************************
%Create a panel to hold the  plotting options of condition, channel and
%subject
handles.panel_po = uipanel('Parent', handles.gl,...
    'BackgroundColor', p.backcolor,...
    'Title', 'Select Content to Plot');
handles.panel_po.Layout.Column = 1;
handles.panel_po.Layout.Row = [1 3];
pause(.5)
drawnow;

psh = handles.panel_po.InnerPosition;

handles.tab_ops = uitabgroup(...
    'Parent', handles.panel_po,...
    'OuterPosition', [0,0,psh(3), psh(4)]);

handles.tab_seldata = uitab(...
    'Parent', handles.tab_ops,...
    'Title', 'Data');

handles.tab_mapping = uitab(...
    'Parent', handles.tab_ops,...
    'Title', 'Freq Mapping');

handles.tab_opts = uitab(...
    'Parent', handles.tab_ops,...
    'Title', 'Options');

pause(.5)
drawnow;

psh = handles.tab_opts.InnerPosition(4);

uilabel('Parent', handles.tab_seldata,...
    'Position', [10,psh-30,100,20],...
    'Text', 'Conditions to plot',...
    'FontColor', p.labelfontcolor);

uilabel('Parent', handles.tab_seldata,...
    'Position', [10,psh-220,100,20],...
    'Text', 'Channels to plot',...
    'FontColor', p.labelfontcolor);

uilabel('Parent', handles.tab_seldata,...
    'Position', [155,psh-220,100,20],...
    'Text', 'Subjects to plot',...
    'FontColor', p.labelfontcolor);

handles.list_condition = uilistbox(...
    'Parent', handles.tab_seldata, ...
    'Position', [10, psh-180, 250, 150 ],...
    'BackgroundColor', p.textfieldbackcolor, ...
    'FontColor', p.textfieldfontcolor',...
    'MultiSelect', 'on');

handles.check_allchans = uicheckbox(...
    'Parent', handles.tab_seldata,...
    'Position', [10,psh-250,125,20],...
    'Text', 'All Channels',...
    'Value', 0);

handles.list_channels = uilistbox(...
    'Parent', handles.tab_seldata,...
    'Position', [10,10,125,psh-270],...
    'Enable', 'off',...
    'MultiSelect', 'on');

handles.list_subject = uilistbox(...
    'Parent', handles.tab_seldata,...
    'Position', [145,10,125,psh-240],...
    'MultiSelect', 'off');

%frequency mapping panel

uilabel('Parent', handles.tab_mapping,...
    'Position', [10,psh-40,280,20],...
    'Text', 'Time Frequency Mapping Window',...
    'FontColor', p.labelfontcolor,...
    'HorizontalAlignment','center');

uilabel('Parent', handles.tab_mapping,...
    'Position', [10,psh-70,100,20],...
    'Text', 'Start Time',...
    'FontColor', p.labelfontcolor);

uilabel('Parent', handles.tab_mapping,...
    'Position', [10,psh-100,100,20],...
    'Text', 'End Time',...
    'FontColor', p.labelfontcolor);

handles.spinner_time = uispinner(...
    'Parent', handles.tab_mapping,...
    'Position', [150,psh-70,120,20],...
    'FontColor', p.textfieldfontcolor,...
    'BackgroundColor', p.textfieldbackcolor,...
    'Value', p.TFData.times(1), ...
    'Step', diff(p.TFData.times(1:2)),...
    'Limits', [p.TFData.times(1), p.TFData.times(end)],...
    'RoundFractionalValues', 'off',...
    'ValueDisplayFormat', '%3.2f ms');

handles.spinner_twidth = uispinner(...
    'Parent', handles.tab_mapping,...
    'Position', [150,psh-100,120,20],...
    'FontColor', p.textfieldfontcolor,...
    'BackgroundColor', p.textfieldbackcolor,...
    'Value', 0, ...
    'Limits', [0, p.TFData.times(end)],...
    'RoundFractionalValues', 'off',...
    'ValueDisplayFormat', '%3.2f ms');

uilabel('Parent', handles.tab_mapping,...
    'Position', [10,psh-130,100,20],...
    'Text', 'Start Freq',...
    'FontColor', p.labelfontcolor);

uilabel('Parent', handles.tab_mapping,...
    'Position', [10,psh-160,100,20],...
    'Text', 'End Freq',...
    'FontColor', p.labelfontcolor);

handles.spinner_freq = uispinner(...
    'Parent', handles.tab_mapping,...
    'Position', [150,psh-130,120,20],...
    'FontColor', p.textfieldfontcolor,...
    'BackgroundColor', p.textfieldbackcolor,...
    'Value', p.TFData.freqs(1), ...
    'Step', diff(p.TFData.freqs(1:2)),...
    'Limits', [p.TFData.freqs(1), p.TFData.freqs(end)],...
    'RoundFractionalValues', 'off',...
    'ValueDisplayFormat', '%3.2f Hz');

handles.spinner_fwidth = uispinner(...
    'Parent', handles.tab_mapping,...
    'Position', [150,psh-160,120,20],...
    'FontColor', p.textfieldfontcolor,...
    'BackgroundColor', p.textfieldbackcolor,...
    'Value', p.TFData.freqs(end), ...
    'Limits', [p.TFData.freqs(1), p.TFData.freqs(end)],...
    'RoundFractionalValues', 'off',...
    'ValueDisplayFormat', '%3.2f Hz');

uilabel('Parent', handles.tab_mapping,...
    'Position', [10,psh-190,280,20],...
    'Text', '(Use shift+arrow to translate window)',...
    'FontColor', p.labelfontcolor,...
    'HorizontalAlignment','center');


drawnow;
%**************************************************************************
%panel for the overlay
handles.panel_statoverlay = uipanel('Parent', handles.gl,...
    'BackgroundColor', p.backcolor,...
    'Title', 'Plots and Overlays');
handles.panel_statoverlay.Layout.Column = 1;
handles.panel_statoverlay.Layout.Row = [4 5];
%need a pause here for the screen to update and the new sizes of the
%control
pause(.5)
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

pause(.5);
drawnow;

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


% 
% %*************************************************************************
% %tab for the statistical analysis
% 
% uilabel('Parent', handles.tab_newtest,...
%     'Position', [10, psh-60, 100, 20],...
%     'Text', 'Factor',...
%     'FontColor', p.labelfontcolor);
% 
% uilabel('Parent', handles.tab_newtest,...
%     'Position', [120, psh-60, 50, 20],...
%     'Text', 'Levels',...
%     'FontColor', p.labelfontcolor);
% 
% handles.edit_factors = uieditfield(...
%     'Parent', handles.tab_newtest,...
%     'Position', [10, psh-80, 100, 20],...
%     'BackgroundColor', p.textfieldbackcolor', ...
%     'FontColor', p.textfieldfontcolor);
% 
% handles.edit_levels = uieditfield(...
%     handles.tab_newtest,'numeric',...
%     'Limits', [2,inf],...
%     'Position', [115, psh-80, 30, 20],...
%     'BackgroundColor', p.textfieldbackcolor', ...
%     'FontColor', p.textfieldfontcolor,...
%     'Value', 2);
% 
% handles.button_factadd = uibutton(...
%     'Parent', handles.tab_newtest,...
%     'Position', [150, psh-80, 55, 20],...
%     'Text', 'Add',...
%     'BackgroundColor', p.buttoncolor,...
%     'FontColor', p.buttonfontcolor,...
%     'Tag', 'Add');
% 
% handles.button_factremove = uibutton(...
%     'Parent', handles.tab_newtest,...
%     'Position', [210, psh-80, 60, 20],...
%     'Text', 'Remove',...
%     'BackgroundColor', p.buttoncolor,...
%     'FontColor', p.buttonfontcolor,...
%      'Tag','Remove', ...
%      'Enable', 'off');
% 
% handles.list_model = uilistbox(...
%     'Parent', handles.tab_newtest,...
%     'Position', [10, psh-190, 260, 100],...
%     'BackgroundColor', p.textfieldbackcolor,...
%     'FontColor',p.textfieldfontcolor,...
%     'Items', {'[Insert Factors Here]'});
% 
% uilabel('Parent', handles.tab_newtest,...
%     'Position', [10,psh-220, 200, 20],...
%     'Text', 'Test to conduct',...
%     'FontColor', p.labelfontcolor);
% 
% handles.dropdown_MUtype = uidropdown(...
%     'Parent', handles.tab_newtest,...
%     'Position', [10,psh-240,260,20],...
%     'BackgroundColor', p.textfieldbackcolor,...
%     'FontColor', p.textfieldfontcolor,...
%     'Items', {'F-max permutation test', 'Cluster mass permutation test', 'False discovery rate', 'General linear model'},...
%     'ItemsData', {'FmaxTFData', 'FclustTFData', 'FfdrTFData', 'ANOVA'});
% 
% uilabel('Parent', handles.tab_newtest,...
%     'Position', [10,psh-270, 100, 20],...
%     'Text', 'Data to select',...
%     'FontColor', p.labelfontcolor);
% 
% handles.bgroup = uibuttongroup(...
%     'Parent', handles.tab_newtest,...
%     'Position', [10, psh-320, 260,50]);
% 
% handles.radio_amp = uiradiobutton(...
%     'Parent', handles.bgroup,...
%     'Text', 'Amplitude',...
%     'Position', [5,25,85,20],...
%     'Enable', 'off');
% 
% handles.radio_pospeak = uiradiobutton(...
%     'Parent', handles.bgroup,...
%     'Text', 'Latency (+)',...
%     'Position', [90,25,85,20],...
%     'Enable', 'off');
% 
% handles.radio_negpeak = uiradiobutton(...
%     'Parent', handles.bgroup,...
%     'Text', 'Latency (-)',...
%     'Position', [175,25,80,20],...
%     'Enable', 'off');
% 
% handles.radio_peakplusminus = uiradiobutton(...
%     'Parent', handles.bgroup,...
%     'Text', 'Peak +/-',...
%     'Position', [5,3,80,20],...
%     'Enable', 'off');
% 
% handles.radio_peak2peak = uiradiobutton(...
%     'Parent', handles.bgroup,...
%     'Text', 'Peak to peak',...
%     'Position', [90,3,120,20],...
%     'Enable', 'off');
% 
% 
% uilabel('Parent', handles.tab_newtest,...
%     'Position', [10,psh-360, 100, 20],...
%     'Text', 'Window',...
%     'FontColor', p.labelfontcolor);
% 
% handles.edit_massunivstart = uieditfield(...
%     handles.tab_newtest,'numeric',...
%     'Position', [90, psh-360, 85, 20],...
%     'Limits', [p.TFData.time_pts(1), p.TFData.time_pts(end)],...
%     'ValueDisplayFormat', '%0.2f ms',...
%     'Value', p.TFData.time_pts(1),...
%     'BackgroundColor', p.textfieldbackcolor,...
%     'Fontcolor', p.textfieldfontcolor);
% 
% handles.edit_massunivend = uieditfield(...
%     handles.tab_newtest,'numeric',...
%     'Position', [185, psh-360, 85, 20],...
%     'Limits', [p.TFData.time_pts(1), p.TFData.time_pts(end)],...
%     'ValueDisplayFormat', '%0.2f ms',...
%     'Value', p.TFData.time_pts(end),...
%     'BackgroundColor', p.textfieldbackcolor,...
%     'Fontcolor', p.textfieldfontcolor);
% 
% handles.check_massunivave = uicheckbox(...
%     'Parent', handles.tab_newtest,...
%     'Position', [10, psh-380, 200, 20],...
%     'Text', 'Average points in window',...
%     'FontColor', p.textfieldfontcolor');
% 
%     
% handles.check_massunivchans = uicheckbox(...
%     'Parent', handles.tab_newtest,...
%     'Position', [10, psh-400, 200, 20],...
%     'Text', 'Use currently displayed channels',...
%     'FontColor', p.textfieldfontcolor');
% 
% uilabel('Parent', handles.tab_newtest,...
%     'Position', [10, psh-430, 200, 20],...
%     'Text', 'Alpha',...
%     'FontColor', p.labelfontcolor);
% 
% handles.edit_massunivalpha = uieditfield(...
%     handles.tab_newtest,'numeric',...
%     'Position', [60, psh-430, 50, 20],...
%     'Limits', [0, 1],...
%     'ValueDisplayFormat', '%g',...
%     'Value', .05,...
%     'BackgroundColor', p.textfieldbackcolor,...
%     'Fontcolor', p.textfieldfontcolor);
% 
% handles.button_massuniv = uibutton(...
%     'Parent', handles.tab_newtest,...
%     'Position', [65, 5, 150, 30],...
%     'Text', 'Run Test',...
%     'BackgroundColor', p.buttoncolor,...
%     'FontColor', p.buttonfontcolor);

dlg.Message = 'Assigning callbacks';

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
handles.menu_cursormean = uimenu('Parent', handles.menu_cursor, 'Label', 'Average between cursors', 'Checked', 'off');

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

dlg.Message = 'Storing functional data';

handles.figure.UserData = p;

dlg.Message = 'Initialiing the displays and plots';

drawnow;

%initialize the displays and plot the data
callback_reloadfiles([],[],handles, false)
callback_toggleallchannel([],handles.check_allchans,handles);
fprintf('...done\n');

dlg.Message = 'Done';
pause(1);
close(dlg);


%***************************************************************************
function callback_togglemcs(hObject, event, h)
%toggle mean cursor status
 hObject.Checked = ~hObject.Checked;
 plot_topos(h)

%************************************************************************
function callback_toggletopomenustate(hObject, event, h)

for ii = 1:2
    h.menu_mapscale(ii).Checked = false;
end
hObject.Checked = true;
plot_topos(h)

%**************************************************************
function callback_togglemapquality(hObject, event, h)

    hObject.Checked = ~hObject.Checked;
    plot_topos(h);

%*************************************************************************
function callback_plotANOVAresult(hObject, event,h)

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
TFData = p.TFData;

switch event.Source.Tag
    case 'bin'
        c_bin = h.list_condition.Value;
        if length(h.list_condition.Items) < 2
            uialert(h.figure, 'You must have at least one condition per file', 'Delete Error');
            return
        end
        
        response = uiconfirm(h.figure, sprintf('Are you sure you want to delete %s?', TFData.bin_info(c_bin).bindesc), 'Confirm Delete');
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

callback_plotersp([],[],h);

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
    erp_filename =eeg_BuildPath(p.TFData.filepath, p.TFData.filename);
    load(erp_filename, '-mat');
    
    if isfield(TFData, 'F_tests')
        if ~isempty(TFData.F_tests)
            for ii = 1:length(TFData.F_tests)
                if iscell(TFData.F_tests(ii).used_tpt_ids)
                    TFData.F_tests(ii).used_tpt_ids = cell2mat(TFData.F_tests(ii).used_tpt_ids);
                end
            end
        end
    end

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
if isfield(p.TFData,'F_tests')
    if ~isempty(p.TFData.F_tests)
        disable = false;
        n = arrayfun(@(x) join(x.factors), p.TFData.F_tests);
        n = cellfun(@(x) strrep(x, ' ', ' X '), n, 'UniformOutput', false);
        t = num2cell(1:length(p.TFData.F_tests));
        tn = cellfun(@num2str, t, 'un', 0);
        labels = strcat(tn, '. ', n);
        
        h.dropdown_MUtest.Items = labels;
        h.dropdown_MUtest.ItemsData = 1:length(p.TFData.F_tests);
        
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
if isfield(p.TFData,'ANOVA')
    if ~isempty(p.TFData.ANOVA)
        disable = false;
        n = arrayfun(@(x) join(x.factors), p.TFData.ANOVA);
        n = cellfun(@(x) strrep(x, ' ', ' X '), n, 'UniformOutput', false);
        t = num2cell(1:length(p.TFData.ANOVA));
        tn = cellfun(@num2str, t, 'un', 0);
        labels = strcat(tn,'. ',  n);
        
        h.dropdown_ANOVAtest.Items = labels;
        h.dropdown_ANOVAtest.ItemsData = 1:length(p.TFData.ANOVA);
        
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


p = h.figure.UserData;

    
tn = h.dropdown_MUtest.Value;
r = p.TFData.F_tests(tn);

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
        'Text', sprintf('%i. %s', ii, p.TFData.bin_info(r.bins(ii)).bindesc));
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
        'Text', sprintf('%i. %s', r.used_chan_ids(ii), p.TFData.chanlocs(r.used_chan_ids(ii)).labels));
end

if h.check_MUoverlay.Value
    callback_plotersp([],[],h);
end

%**************************************************************************
function callback_changestatselection(hObject, event, h);

if h.check_MUoverlay.Value
    callback_plotersp([],[],h);
end        

%**************************************************************************
function callback_handlekeyevents(hObject, event, h)

%only accept keystrokes if the shift key is pressed.
if ~strcmp(event.Modifier, 'shift'); return; end

p = h.figure.UserData;

[~, indx] = get_tf_cursor_values(h, p.TFData);

if contains(event.Key, 'arrow')
    switch event.Key
        case 'rightarrow'
            indx([1,3]) = indx([1,3]) + 1;
            if indx(3) > length(p.TFData.times);
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
        c.dragging = true;
        c.dragged = false;
        c.startpos = [hObject.CurrentPoint(1,1), hObject.CurrentPoint(1,2)];
        c.endpos = c.startpos + [1,1];
        position = [c.startpos, c.endpos - c.startpos];
        c.axis = hObject;
        c.rect = rectangle(c.axis, 'Position',position,...
            'EdgeColor', [.8,.4,.8], 'LineWidth',2, 'LineStyle','--');
        h.panel_ersp.UserData = c; %save the initial status to the panel
        
    case 'WindowMouseRelease'  %update the cursor position for mapping
       c = h.panel_ersp.UserData;
       if c.dragging
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
            delete(c.rect)
            h.panel_ersp.UserData = c;
            update_cursor_position([],[],h,position);

        end

        
    case 'WindowMouseMotion'
        c = h.panel_ersp.UserData;
        if isempty(c)
            c.dragging = false;
            h.panel_ersp.UserData = c;
        end

        if c.dragging
            c.dragged = true;
            xl = c.axis.XLim; yl = c.axis.YLim;
            cp = c.axis.CurrentPoint;
            if cp(1,1) < xl(1) || cp(1,1) > xl(2) ||  cp(1,2) < yl(1) || cp(1,2) >yl(2) %out of range
                return
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
                h.panel_ersp.UserData = c;
            end
        end
        
end
%**************************************************************************
function update_cursor_position(hObject, ~, h, position)

   p = h.figure.UserData;


   [vals, indx] = get_tf_cursor_values(h, p.TFData);
    if isempty(hObject)  %it was called directly and not as a callback 
        vals(1) = position(1);
        [~,indx(1)] = min(abs(p.TFData.times - vals(1)));
        
        vals(2) = position(2);
        [~,indx(2)] = min(abs(p.TFData.freqs - vals(2)));

        if position(3) ~= 0
            vals(3) = position(1) + position(3);
            [~,indx(3)] = min(abs(p.TFData.times - vals(3)));
        end
        if position(4) ~= 0
            vals(4) = position(2) + position(4);
            [~,indx(4)] = min(abs(p.TFData.freqs - vals(4)));
        end
    end

 

    %make sure the time and frequency fall on an extact time and frequency
    %point
 
    %now put the values back into the spinners
    vals(1) = p.TFData.times(indx(1));
    vals(2) = p.TFData.freqs(indx(2));
    vals(3) = p.TFData.times(indx(3));
    vals(4) = p.TFData.freqs(indx(4));


    h.spinner_time.Value = vals(1);
    h.spinner_freq.Value = vals(2);
    h.spinner_twidth.Value = vals(3);
    h.spinner_fwidth.Value = vals(4);

    draw_tf_cursors(h, p);
    plot_topos(h);

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
            rhandle.EdgeColor = [.8,.4,.8];
            rhandle.LineWidth = 1.5;
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
function data = get_ersp_plot_data(study, TFData, h, topostyle)


%get the conditions, channels and subject to plot from the listboxes
cond_sel = h.list_condition.Value;
ch = cell2mat(h.list_channels.Value');
sbj = h.list_subject.Value;

%make these explicit so that it is easier to impliment features for
%selecting a reduced range in the future
t =1:length(TFData.times); %get all the points 
f = 1:length(TFData.freqs);

%get teh selected channels
ch_sel = ch(find(ch(:,1)),1);%
ch_out = ch_sel;    %send this back to the calling function

%it is possible that no channels are selected because just the channel
%groups can be selected
if ~isempty(ch_sel)
    if sbj==0 %this is the grand average
        %average across the selected conditions
        data.ersp = squeeze(mean(TFData.grand_ersp(ch_sel,f,t,cond_sel),4));
    else
        data.ersp = squeeze(mean(TFData.indiv_ersp(sbj, ch_sel, f, t, cond_sel),5));
    end    
    data.labels = {TFData.chanlocs(ch_sel).labels};
end

%now get the channel group information 
if topostyle
    ch_groups = [];  %ignore channel gorups if this is a topo plot
else
    ch_groups = ch(find(ch(:,2)),2);
end

%dont do this part if either there are no channel groups selected or this
%function was called from the plot_topo function
if ~isempty(ch_groups) 
    %get the means of any channel groups
    ch_group_data = zeros(length(ch_groups), length(f), length(t));

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
        end
        data.ersp = cat(1, ch_group_data, data.ersp); 
        data.labels = horzcat({study.chgroups(ch_groups).name}, data.labels);
    else
        data.ersp = ch_group_data;
        data.labels = {study.chgroups(ch_groups).name};
    end
 
    
    
end
data.times = TFData.times(t);
data.freqs = TFData.freqs(f);

data.nchan = length(data.labels);
data.chans = ch_out;
data.chanlocs = TFData.chanlocs(ch_out);

%***********************************************************************
function mapinfo = get_topo_plot_data(TFData, h)


%get the conditions, channels and subject to plot from the listboxes
cond_sel = h.list_condition.Value;
sbj = h.list_subject.Value;
[cv, ci] = get_tf_cursor_values(h, TFData);

mapinfo.plotarea = cv;
mapinfo.nmaps = length(cond_sel);
mapinfo.condnames = TFData.bindesc(cond_sel); 


if sbj == 0
    mapinfo.ersp = squeeze(mean(mean(TFData.grand_ersp(:,ci(2):ci(4), ci(1):ci(3), cond_sel),2),3));
else
    mapinfo.ersp = squeeze(mean(mean(TFData.indiv_ersp(sbj, :,ci(2):ci(4), ci(1):ci(3), cond_sel),2),3));
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

mapinfo = get_topo_plot_data(p.TFData, h);


for ii = 1:mapinfo.nmaps
    topo_axis = subplot(1,mapinfo.nmaps + 1,ii, 'Parent', h.panel_topo);
    cmap = colormap(topo_axis, 'jet');
    
    d = mapinfo.ersp(:,ii);

    if singleScaleMode
        ms = max(max(abs(mapinfo.ersp)));
    else
        ms = max(abs(d));
    end
    ms = [-ms, ms];

    wwu_topoplot(d, p.TFData.chanlocs, 'axishandle', topo_axis,'colormap', cmap, 'maplimits', ms,  'style', 'map', 'numcontour', 0, 'gridscale', gridscale); 
    if ~singleScaleMode
        c = colorbar(topo_axis);
        c.Label.String = 'ERSP (dB)';
    end
    topo_axis.Title.String = mapinfo.condnames{ii};
    topo_axis.Title.Interpreter = 'none';

  end

if singleScaleMode
    c = colorbar(topo_axis);
    c.Units = 'pixels';
    c.Position = [50,10,30,panelSize(4)-20];
    c.Label.String = 'ERSP (dB)';
end

%show the general information on the right side
str = sprintf('Mean ERSP topography\n');
str = [str,sprintf("Start Time: %3.2f ms\n", mapinfo.plotarea(1))];
str = [str,sprintf("End Time : %3.2f ms\n", mapinfo.plotarea(3))];
str = [str, sprintf("Start Freq: %3.2f Hz\n", mapinfo.plotarea(2))];
str = [str, sprintf("End Freq: %3.2f Hz\n", mapinfo.plotarea(4))];

annotation(h.panel_topo, 'textbox', [0, 0, 1, 1], 'String', str, ...
    'FitBoxToText', 'off', 'HorizontalAlignment','right',...
    'lineStyle', 'none');




%***************************************************************************
%main erp drawing function
function callback_plotersp(hObject, event, h)

topostyle = h.check_topolayout.Value;
showgrid = true;


p = h.figure.UserData;
data = get_ersp_plot_data(p.study, p.TFData, h, topostyle);

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
    cfg.showaxistitle = false;
    cfg.legendfontsize = 12;
    cfg.axisfontsize = 10;
else
    if data.nchan < 10
        cfg.showaxistitle = true;
        cfg.axisfontsize = 14;
         cfg.legendfontsize = 14;
    else
        cfg.showaxistitle = false;
        cfg.legendfontsize = 12;
        cfg.axisfontsize = 10;
    end     
    layout = tf_grid_layout(data.nchan + ~cfg.showaxistitle);
  
    
end

cfg.showaxis = true;
cfg.scaleindiv = false;

delete(allchild(h.panel_ersp))

p.paxis = [];
for ch = 1:data.nchan
    cfg.axis = uiaxes(h.panel_ersp,"Units", "Normalized","Position",layout(ch).Position );
    cfg.axis.Visible = false;
    cfg.axis.Toolbar.Visible = 'off';
    cfg.axis.ButtonDownFcn = {@callback_handlemouseevents, h};
    cfg.axis.PickableParts = 'all';
    cfg.axis.HitTest = 'on';

    cfg.channel = ch;
    cfg = tfplot(data, cfg);
    cfg.axis.FontSize = cfg.axisfontsize;
    cfg.axis.XGrid = showgrid;
    cfg.axis.YGrid = showgrid;
    cfg.axis.Layer = 'top';
    cfg.axis.GridColor = 'k';
    cfg.axis.GridAlpha = .2;
    p.paxis(ch) = cfg.axis;
    cfg.axis.Visible = true;
end

if ~cfg.showaxistitle
    %%create a legend
    legend_axis = uiaxes(h.panel_ersp, "Units", "Normalized", 'Position', layout(end).Position);
    legend_axis.XLim = [p.TFData.times(1), p.TFData.times(end)];
    legend_axis.YLim = [p.TFData.freqs(1), p.TFData.freqs(end)];
    legend_axis.Color = h.panel_ersp.BackgroundColor;
    legend_axis.XLabel.String = 'Time (ms)';
    legend_axis.YLabel.String = 'Freq (Hz)';
    legend_axis.CLim = cfg.limits;
    legend_axis.Title.String = 'Legend';
    legend_axis.FontSize = cfg.legendfontsize;
    
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
end
draw_tf_cursors(h, p)
if ~isempty(progress) close(progress); end
drawnow
%
%plot_topos(h)
h.figure.UserData = p;



%% start of tfdata specific plotting functions

function cfg = tfplot(data, cfg)
    %dont do alot of checking here since this will only be called
    %internally

    %extract data
    if ndims(data.ersp) > 2
        d = squeeze(data.ersp(cfg.channel,:,:));
    else
        d = data.ersp;
    end

    if isfield(cfg, 'scaleindiv') && cfg.scaleindiv

        limits =  max(max(abs(d))) * .8;
        limits = [-limits, limits];
        cfg.addcolorbar = true;
    elseif isfield(cfg, 'limits')
        limits = cfg.limits;
        cfg.addcolorbar = false;
        
    else
        limits = max(max(max(abs(data.ersp))));
        limits = [-limits, limits] * .6;
        cfg.addcolorbar = false;
     
    end
    cfg.limits = limits;

    colormap(cfg.axis,'jet');
    i = imagesc(cfg.axis, data.times, data.freqs, d, limits);
    i.PickableParts = 'none';
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
x = x * .9 + .05;
y = y * .9 + .05;

minDist = inf;
for ii = 1:length(x)
    for jj = 1:length(x)
        if ii ~= jj
            d = pdist([x(ii), y(ii); x(jj), y(jj)], 'euclidean');
            if d < minDist, minDist = d;end
        end
    end
end
%give a little wiggle room
%minDist = minDist * .9;
width = minDist;% * sind(45);
height = width;
x = x - height/2;
y = y - width/2;

for ii = 1:length(x)
    layout(ii).Position = [x(ii), y(ii), width, height];
    layout(ii).Name = chanlocs(ii).labels;
end
layout(end+1).Position = [max(x)-(width * .5), min(y), width*1.5, height* 1.5];
layout(end).Name = 'Legend';

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
width = x_dist - .025;
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




            
    

    


