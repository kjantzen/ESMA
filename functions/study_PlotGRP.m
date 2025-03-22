%study_PlotGRP(GRPFile, F_test_number)
% Overly simple tool for viewing FMUT between sbject results
% in a GRP (FMUT) file format.
% Right now you can just view the raster plot of a single F_test
%click on the raster will generate a F-stat map and a map of which channel
%is include in which cluster.
% Future expansion will be
%   1. To allow for the user to select which F test to view
%   2. To show plots of time series as well (although these depend on GND
%   files.
function study_PlotGRP(GRPFile, F_test_number)

arguments
    GRPFile (1,:) char {isfile}
    F_test_number (1,1) int8 {mustBeNumeric, mustBePositive} = 1
end
GRP = loadGRPFile(GRPFile, F_test_number);
if isempty(GRP)
    error('There was a problem loading the GRP file.  Goodbye!\n')
end
handles = buildGUI(GRP.F_tests(F_test_number));
handles.figure.Name = GRPFile;
GRP.test_to_display = F_test_number;
%stash the data
handles.figure.UserData = GRP;
drawRaster(handles)

seed_time = GRP.time_pts(round(length(GRP.time_pts)/2));
drawCursor(handles, seed_time)
drawTopo(handles, seed_time)

clear seed_time F_test_number


%% Helper functions
% ***********************************************************************
function GRP = loadGRPFile(inFile, test_number)
GRP = [];
%make sure it exists
if ~isfile(inFile)
    warning('The GRP file does not exist')
    return
end
tmp = load(inFile, '-mat');
if isfield(tmp, 'GRP')
    tmp = tmp.GRP;
end
if ~isfield(tmp, 'group_desc')
    warning('This does not appear to be a valid GRP file');
    return
end
if ~isfield(tmp, 'F_tests')
    warning('This GRP file does not have any statistical information')
    return
end
if length(tmp.F_tests) < test_number
    warning('The F_test number does not seem to exist!')
    return
end
%now that all the tests have been passed
GRP = tmp;
fprintf('loaded %s with descriptions %s', GRP.filename, GRP.exp_desc);
fprintf('The GRP file is based on:\n')
fprintf('\tGND file:%s\n', GRP.GND_fnames{:});

%clean up the clust_info array so only significant values remain
effect_names = fieldnames(GRP.F_tests(test_number).clust_info);
for tt = 1:length(effect_names)
    effect = effect_names{tt};
    clust_info = GRP.F_tests(test_number).clust_info.(effect);
    sig_clust = zeros(size(clust_info.clust_ids));
    sig_clust_num = find(clust_info.null_test);
    if ~isempty(sig_clust_num)
        for ii = 1:length(sig_clust_num)
            sig_clust(clust_info.clust_ids == sig_clust_num(ii)) = ii;
        end
    end
    GRP.F_tests(test_number).clust_info.(effect).clust_ids = sig_clust;
end
% ***********************************************************************
function callback_replot(~,~,h)
    drawRaster(h);
    callback_handle_mouseclicks(h.axis_raster,[], h)
% ***********************************************************************
function drawRaster(h)

GRP = h.figure.UserData;
nchans = length(GRP.chanlocs);

effect_to_draw = h.bg_effect.SelectedObject.Tag;
plot_title = h.bg_effect.SelectedObject.Text;
test = GRP.F_tests(GRP.test_to_display);
sig_clust = test.clust_info.(effect_to_draw).clust_ids;

%clear the axis
cla(h.axis_raster)
colormap(h.axis_raster,orderedcolors("gem12"));

im = image(h.axis_raster, GRP.time_pts(test.used_tpt_ids), test.used_chan_ids, sig_clust,...
    'CDataMapping', 'direct');
im.AlphaData = sig_clust;
im.PickableParts = "none";

cb = colorbar(h.axis_raster);
cb.Label.String = 'Cluster Number';

h.axis_raster.Title.String = plot_title;
h.axis_raster.YTick = 1:nchans;
h.axis_raster.YTickLabel = {GRP.chanlocs.labels};
h.axis_raster.YGrid = 'on';

h.axis_raster.YLim = [0, nchans+1];
h.axis_raster.XLim = [GRP.time_pts(1), GRP.time_pts(end)];
% ***********************************************************************
function drawTopo(h, time_pt)

GRP = h.figure.UserData;
%get the FData
effect_to_draw = h.bg_effect.SelectedObject.Tag;
test = GRP.F_tests(GRP.test_to_display);
nchans = length(GRP.chanlocs);
%cluster_colors = {gem12};
cluster_colors = orderedcolors("gem12");

%get the index of the closest time point
[~,time_indx]  = min(abs(time_pt-GRP.time_pts));
map_time = GRP.time_pts(time_indx);
stat_time_indx = find(test.used_tpt_ids == time_indx,1);
if isempty(stat_time_indx)
    F_data_for_map = ones(length(GRP.chanlocs),1);
else
    F_data_for_map = test.F_obs.(effect_to_draw)(:,stat_time_indx);
end
maplimits =[0, max(F_data_for_map)];
mapstring = ['wwu_topoplot(F_data_for_map, GRP.chanlocs, ''axishandle'', h.axis_topo,''maplimits'', maplimits, ' ...
            '''style'', ''map'', ''numcontour'', 0'];

%list of sig channel to display
sig_chans = test.clust_info.(effect_to_draw).clust_ids(:,stat_time_indx);
sig_ch_indx = find(sig_chans);
if ~isempty(sig_ch_indx)
   mapstring = [mapstring, ',  ''emarker2'', {sig_ch_indx, ''o'', ''k'', 8, 1});'];
   sig_clust_indx = sig_chans(sig_chans>0);
   cluster_colors = {cluster_colors(sig_clust_indx,:)};
else
   mapstring = [mapstring, ');'];
end
cla(h.axis_topo)
eval(mapstring);
h.axis_topo.Colormap = autumn;
cb = colorbar(h.axis_topo);
cb.Label.String = 'F-Score';
text(h.axis_topo, 0, -.57, sprintf('%.2f ms', map_time),...
    'HorizontalAlignment','center', 'FontSize', 14);

cla(h.axis_cluster_topo)
%draw the map showing significant clusters
wwu_topoplot(sig_ch_indx, GRP.chanlocs, 'axishandle', h.axis_cluster_topo, 'style', 'blank',...
    'emarkercolors', cluster_colors);
text(h.axis_cluster_topo, 0, -.57, sprintf('%.2f ms', map_time),...
    'HorizontalAlignment','center', 'FontSize', 14);
% ***********************************************************************
function callback_handle_mouseclicks(hObject, event, h)
time_pt = hObject.CurrentPoint(1,1);
moveCursor(h, time_pt);
drawTopo(h, time_pt);
% ***********************************************************************
function drawCursor(h, time)
    %redraws a cursor so lets make sure there are no existing cursors
    %already
    cursor = h.axis_raster.UserData;
    if ~isempty(cursor)
        delete(cursor)
    end
    cursor = line(h.axis_raster, [time, time], h.axis_raster.YLim, 'Color', [.5,.5,.5], ...
        'LineWidth', 3);
    h.axis_raster.UserData = cursor;
% ***********************************************************************
function moveCursor(h, time)
   %redraws a cursor so lets make sure there are no existing cursors
    %already
    cursor = h.axis_raster.UserData;
    if isempty(cursor)
        drawCursor(h, time)
    else
        cursor.XData = [time, time];
        h.axis_raster.UserData = cursor; 
        drawnow;
    end
% ***********************************************************************
function formatted_name = formatEffectName(name)
    name_array = strsplit(name, 'X');
    if isscalar(name_array)
        formatted_name = name_array{1};
        formatted_name(1) = upper(formatted_name(1));
    else
        formatted_name = "";
        for ii = 1:length(name_array) -1
            name_part = name_array{ii};
            name_part(1) = upper(name_part(1));
            formatted_name = join([formatted_name,name_part, "X"]);
        end
        name_part = name_array{ii+1};
        name_part(1) = upper(name_part(1));            
        formatted_name = join([formatted_name,name_part]);
    end
    formatted_name = strtrim(formatted_name);  
% ***********************************************************************
function h = buildGUI(test)

scheme = eeg_LoadScheme;
h.figure = uifigure();
%set some default parameters for window size

W = round(800);
if scheme.ScreenHeight < 1000
    H = scheme.ScreenHeight;
else
    H = 1000;
end
figpos = [420, scheme.ScreenHeight - H, W, H];
h.figure.Color = scheme.Window.BackgroundColor.Value;
h.figure.Position = figpos;
h.figure.NumberTitle = 'off';

%keep it simpl for now with a single raster plot and map of the F values
%and significant channels
h.grid  = uigridlayout('Parent',h.figure,...
    'BackgroundColor', scheme.Window.BackgroundColor.Value,...
    'ColumnWidth',{'1x', '1x'},'RowHeight',{40, '3x','1x'});

h.bg_effect = uibuttongroup(...
    'Parent', h.grid,...
    'AutoResizeChildren', false,...
    'BorderType', 'none',...
    'BackgroundColor', scheme.Window.BackgroundColor.Value,...
    'HighlightColor', scheme.Panel.BorderColor.Value,...
    'FontName',scheme.Panel.Font.Value,...
    'FontSize', scheme.Panel.FontSize.Value,...
    'ForegroundColor', scheme.Panel.FontColor.Value);
h.bg_effect.Layout.Row = 1;
h.bg_effect.Layout.Column = [1,2];
drawnow;
pause(1)

effect_names = fieldnames(test.F_obs);
n_effects = length(effect_names);
bw = h.bg_effect.Position(3)/n_effects;
for ii = 1:length(effect_names)
    bl = (ii-1) * bw + 1;
    button_label = formatEffectName(effect_names{ii});
    h.button_effect(ii) = uitogglebutton('Parent', h.bg_effect,...
        'Position',[bl,1,bw,40], ...
        'Text', button_label,...
        'Tag', effect_names{ii},...
        'FontName', scheme.Button.Font.Value,...
        'FontSize', scheme.Button.FontSize.Value,...
        'FontColor', scheme.Button.FontColor.Value,...
        'BackgroundColor', scheme.Button.BackgroundColor.Value);
end

h.axis_raster = uiaxes(...
    'Parent', h.grid,...
    'Units', 'normalized',...
    'Interactions',[],...
    'OuterPosition',[0,0,1,1],...
    'Color', scheme.Axis.BackgroundColor.Value,...
    'XColor', scheme.Axis.AxisColor.Value,...
    'YColor',scheme.Axis.AxisColor.Value,...
    'FontName',scheme.Axis.Font.Value,...
    'FontSize', scheme.Axis.FontSize.Value);
h.axis_raster.Layout.Column = [1,2];
h.axis_raster.Layout.Row = 2;
h.axis_raster.Toolbar.Visible = 'off';
h.axis_raster.Title.Color = scheme.Axis.AxisColor.Value;
h.axis_raster.Title.BackgroundColor = 'none';

h.axis_topo = uiaxes(...
    'Parent', h.grid,...
    'Units', 'normalized',...
    'Interactions',[],...
    'OuterPosition',[0,0,1,1],...
    'Color', scheme.Axis.BackgroundColor.Value,...
    'XColor', scheme.Axis.AxisColor.Value,...
    'YColor',scheme.Axis.AxisColor.Value,...
    'FontName',scheme.Axis.Font.Value,...
    'FontSize', scheme.Axis.FontSize.Value);
h.axis_topo.Layout.Column = 1;
h.axis_topo.Layout.Row = 3;
h.axis_topo.Toolbar.Visible = 'off';
h.axis_topo.Title.Color = scheme.Axis.AxisColor.Value;
h.axis_topo.Title.BackgroundColor = 'none';
h.axis_topo.Colormap = autumn;

h.axis_cluster_topo = uiaxes(...
    'Parent', h.grid,...
    'Units', 'normalized',...
    'Interactions',[],...
    'OuterPosition',[0,0,1,1],...
    'Color', scheme.Axis.BackgroundColor.Value,...
    'XColor', scheme.Axis.AxisColor.Value,...
    'YColor',scheme.Axis.AxisColor.Value,...
    'FontName',scheme.Axis.Font.Value,...
    'FontSize', scheme.Axis.FontSize.Value);
h.axis_cluster_topo.Layout.Column = 2;
h.axis_cluster_topo.Layout.Row = 3;
h.axis_cluster_topo.Toolbar.Visible = 'off';
h.axis_cluster_topo.Title.Color = scheme.Axis.AxisColor.Value;
h.axis_cluster_topo.Title.BackgroundColor = 'none';
h.axis_cluster_topo.Colormap = autumn;

h.bg_effect.SelectionChangedFcn = {@callback_replot, h};
h.axis_raster.ButtonDownFcn = {@callback_handle_mouseclicks, h};

