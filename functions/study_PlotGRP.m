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
function study_PlotGRP(GRPFile)
arguments
    GRPFile (1,:) char {isfile}
end
GRP = loadGRPFile(GRPFile);
if isempty(GRP)
    error('There was a problem loading the GRP file.  Goodbye!\n')
end
handles = buildGUI(GRP.F_tests(1));
handles.figure.Name = GRPFile;
%stash the data
handles.figure.UserData = GRP;

handles = populateGUI(handles);
drawRaster(handles)

seed_time = GRP.time_pts(round(length(GRP.time_pts)/2));
drawCursor(handles, seed_time)
drawTopo(handles, seed_time)

clear seed_time F_test_number

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

%now that all the tests have been passed
GRP = tmp;
fprintf('loaded %s with descriptions %s', GRP.filename, GRP.exp_desc);
fprintf('The GRP file is based on:\n')
fprintf('\tGND file:%s\n', GRP.GND_fnames{:});
% ***********************************************************************
function callback_replot(~,~,h)
    drawRaster(h);
    tp = refreshCursor( h);
    drawTopo(h, tp);
% ***********************************************************************
function callback_newtest(~,~,h)
    refresh_effect_list(h)
    drawRaster(h);
    tp = refreshCursor(h);
    drawTopo(h, tp)
% ***********************************************************************
function drawRaster(h)

GRP = h.figure.UserData;
nchans = length(GRP.chanlocs);
test_number = h.dropdown_test.Value;
effect_to_draw = h.dropdown_effect.Value;
plot_title = h.dropdown_effect.Items(h.dropdown_effect.ValueIndex);
test = GRP.F_tests(test_number);

raster_data = GRP.F_tests(test_number).F_obs.(effect_to_draw);
mask_data = GRP.F_tests(test_number).null_test.(effect_to_draw);

%clear the axis
cla(h.axis_raster)

im = image(h.axis_raster, GRP.time_pts(test.used_tpt_ids), test.used_chan_ids, raster_data,...
    'CDataMapping', 'scaled');
im.AlphaData = mask_data;
im.PickableParts = "none";

cb = colorbar(h.axis_raster);
cb.Label.String = 'F-Score';

h.axis_raster.Title.String = plot_title;
h.axis_raster.YTick = 1:nchans;
h.axis_raster.YTickLabel = {GRP.chanlocs.labels};
h.axis_raster.YGrid = 'on';
h.axis_raster.XGrid = 'on';
h.axis_raster.YAxis.FontSize = 12;
h.axis_raster.XLabel.String = 'Time (ms)';
h.axis_raster.YLim = [0, nchans+1];
h.axis_raster.XLim = [GRP.time_pts(1), GRP.time_pts(end)];
% ***********************************************************************
function drawTopo(h, time_pt)

GRP = h.figure.UserData;
%get the FData
effect_to_draw = h.dropdown_effect.Value;
test_number = h.dropdown_test.Value;

test = GRP.F_tests(test_number);

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
 sig_ch_indx = find(test.null_test.(effect_to_draw)(:,stat_time_indx));
 if ~isempty(sig_ch_indx)
    mapstring = [mapstring, ',  ''emarker2'', {sig_ch_indx, ''o'', ''k'', 8, 1});'];
%    sig_clust_indx = sig_chans(sig_chans>0);
%    cluster_colors = {cluster_colors(sig_clust_indx,:)};
 else
    mapstring = [mapstring, ');'];
 end
 cla(h.axis_topo)
 eval(mapstring);
 h.axis_topo.Colormap = parula;
 cb = colorbar(h.axis_topo);
 cb.Label.String = 'F-Score';
 text(h.axis_topo, 0, -.57, sprintf('%.2f ms', map_time),...
     'HorizontalAlignment','center', 'FontSize', 14);

% ***********************************************************************
function callback_handle_mouseclicks(hObject, event, h)
    time_pt = hObject.CurrentPoint(1,1);
    moveCursor(h, time_pt);
    drawTopo(h, time_pt);
% ***********************************************************************
function callback_handle_keypresses(hObject, event, h)
    
if matches(event.Key, 'rightarrow') || matches(event.Key, 'leftarrow')
    GRP = h.figure.UserData;
    cursor = h.axis_raster.UserData;
    [~, cpnt] = min(abs(cursor.time - GRP.time_pts));
    if matches(event.Key, 'rightarrow')
        cpnt = cpnt + 1;
        if cpnt > length(GRP.time_pts)
            cpnt = length(GRP.time_pts);
        end
    else
        cpnt = cpnt - 1;
        if cpnt < 1
            cpnt = 1;
        end
    end
    cursor.time = GRP.time_pts(cpnt);
    cursor.line.XData = [cursor.time, cursor.time];
    h.axis_raster.UserData = cursor;
    drawTopo(h, cursor.time);
end

% ***********************************************************************
function drawCursor(h, time)
    %redraws a cursor so lets make sure there are no existing cursors
    %already
    cursor = h.axis_raster.UserData;
    if ~isempty(cursor) && isfield(cursor, 'line') && isgraphics(cursor.line)
        delete(cursor.line)
    end
    cursor.time = time;
    cursor.line = line(h.axis_raster, [time, time], h.axis_raster.YLim, 'Color', [.5,.5,.5], ...
        'LineWidth', 3);
    h.axis_raster.UserData = cursor;
% ***********************************************************************
function moveCursor(h, time)
    cursor = h.axis_raster.UserData;
    if isempty(cursor) || isempty(cursor.line) || ~isgraphics(cursor.line)
        drawCursor(h, time)
    else
        cursor.line.XData = [time, time];
        cursor.time  = time;
        h.axis_raster.UserData = cursor; 
        drawnow;
    end
% ***********************************************************************
function time = refreshCursor(h)
    cursor = h.axis_raster.UserData;
    time = cursor.time;
    if ~isempty(cursor)
        drawCursor(h, cursor.time);
    end

% ***********************************************************************
function formatted_name = formatEffectName(name)
    name_array = strsplit(name, 'X');
    if isscalar(name_array)
        formatted_name = name_array{1};
        formatted_name(1) = upper(formatted_name(1));
    else
        formatted_name = '';
        for ii = 1:length(name_array) -1
            name_part = name_array{ii};
            name_part(1) = upper(name_part(1));
            formatted_name = join([formatted_name,name_part, 'X']);
        end
        name_part = name_array{ii+1};
        name_part(1) = upper(name_part(1));            
        formatted_name = join([formatted_name,name_part]);
    end
    formatted_name = strtrim(formatted_name);  
% ***********************************************************************
function h = populateGUI(h)
    
    GRP  = h.figure.UserData;

    h.dropdown_test.Items = GRP.F_test_names;
    h.dropdown_test.ItemsData = 1:length(GRP.F_test_names);
    refresh_effect_list(h);
% ***********************************************************************    
function refresh_effect_list(h)

    GRP = h.figure.UserData;

    test_number = h.dropdown_test.Value;
    test = GRP.F_tests(test_number);
    %add the effect buttons here because 
    effect_names = fieldnames(test.F_obs);
    n_effects = length(effect_names);
    nice_names = effect_names;
    for ii = 1:n_effects
        nice_names{ii} = formatEffectName(effect_names{ii});
    end
    h.dropdown_effect.Items = nice_names';
    h.dropdown_effect.ItemsData = effect_names';
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
    'ColumnWidth',{'1x', '1x'},'RowHeight',{20, '3x','1x'});

h.dropdown_test = uidropdown(...
    'Parent', h.grid,...
    'BackgroundColor', scheme.Dropdown.BackgroundColor.Value);

h.dropdown_effect = uidropdown(...
    'Parent', h.grid,...
    'BackgroundColor', scheme.Dropdown.BackgroundColor.Value);
    h.dropdown_effect.Layout.Column = 2;
    h.dropdown_effect.Layout.Row = 1;
    
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
h.axis_topo.Layout.Column = [1, 2];
h.axis_topo.Layout.Row = 3;
h.axis_topo.Toolbar.Visible = 'off';
h.axis_topo.Title.Color = scheme.Axis.AxisColor.Value;
h.axis_topo.Title.BackgroundColor = 'none';
h.axis_topo.Colormap = autumn;


h.bg_effect.SelectionChangedFcn = {@callback_replot, h};
h.axis_raster.ButtonDownFcn = {@callback_handle_mouseclicks, h};
h.dropdown_test.ValueChangedFcn = {@callback_newtest, h};
h.dropdown_effect.ValueChangedFcn = {@callback_replot, h};
h.figure.KeyPressFcn = {@callback_handle_keypresses, h};
