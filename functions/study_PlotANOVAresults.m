%study_PlotANOVAresults(r)
%   plots the results of an GLM test based on the information in the 
%   structure r
%
% r should be a statistics structure passed from an ERP bin file created
% within the esma environment
%
function study_PlotANOVAresults(r)

if nargin < 1
    msg = 'A statistics structure must be passed in the call to study_PlotANOVAresults';
    error('%s\nThis function should not be called directly.', msg);
end

r = arrangeData(r);
scheme = eeg_LoadScheme;
[H, W, L,B] = setFigureSizeAndPosition(scheme);


h.figure = uifigure('Position', [L, B, W, H],...
    'Color', scheme.Window.BackgroundColor.Value);

h.grid = uigridlayout('Parent', h.figure,...
    'RowHeight', {'1x', 20, '1x', 20, '2x'}, ...
    'ColumnWidth', {'1x','1x'}, 'Scrollable', 'on',...
    'BackgroundColor',scheme.Window.BackgroundColor.Value);

h.tree_info = uitree('Parent', h.grid,...
    'BackgroundColor', scheme.Window.BackgroundColor.Value, ...
    'FontColor', scheme.Label.FontColor.Value,...
    'FontName', scheme.Label.Font.Value,...
    'FontSize', scheme.Label.FontSize.Value);
h.tree_info.Layout.Row = 1;
h.tree_info.Layout.Column = 1;

h.label_desc = uilabel('Parent', h.grid,'Text', 'Descriptives',...
    'FontColor', scheme.Label.FontColor.Value,...
    'FontName', scheme.Label.Font.Value,...
    'FontSize', scheme.Label.FontSize.Value);
h.label_desc.Layout.Row = 2;
h.label_desc.Layout.Column = 1;

h.label_source = uilabel('Parent', h.grid,'Text', 'Source Table',...
    'FontColor', scheme.Label.FontColor.Value,...
    'FontName', scheme.Label.Font.Value,...
    'FontSize', scheme.Label.FontSize.Value);
h.label_source.Layout.Row = 4;
h.label_source.Layout.Column = 1;

h.desctable = uitable('Parent', h.grid);
h.desctable.Layout.Row = 3;
h.desctable.Layout.Column = 1;

h.sourcetable = uitable('Parent', h.grid);
h.sourcetable.Layout.Row = 5;
h.sourcetable.Layout.Column = 1;

h.axis_holder = uipanel('Parent', h.grid, ...
    'BackgroundColor', scheme.Panel.BackgroundColor.Value,...
    'Scrollable','on',...
    'BorderType','none');
h.axis_holder.Layout.Row = [2,5];
h.axis_holder.Layout.Column = 2;
drawnow nocallbacks;

h.panel = uipanel('Parent', h.grid, 'Title', 'Plot Parameter',...
    'BackgroundColor',scheme.Panel.BackgroundColor.Value,...
    'BorderType','none',...
    'FontName',scheme.Panel.Font.Value,...
    'FontSize', scheme.Panel.FontSize.Value,...
    'ForegroundColor',scheme.Panel.FontColor.Value);
h.panel.Layout.Row = 1;
h.panel.Layout.Column = 2;

%allow a drawing update because we need to know how big this panel will be
drawnow;


uilabel('Parent', h.panel,...
    'Position', [10, 130, 130, 20],...
    'Text', 'Factor on x-axis',...
    'FontColor',scheme.Label.FontColor.Value);

uilabel('Parent', h.panel,...
    'Position', [10, 85, 130, 20],...
    'Text', 'Factor to plot as colors',...
    'FontColor',scheme.Label.FontColor.Value);

uilabel('Parent', h.panel,...
    'Position', [10, 35, 130, 20],...
    'Text', 'Factor across plots',...
    'FontColor',scheme.Label.FontColor.Value);

h.dropdown_xaxis = uidropdown('Parent', h.panel,...
    'Position', [10, 105, 200, 25], ...
    'Items', {r.factors.Factor}, 'ItemsData', 1:length({r.factors.Factor}),...
    'BackgroundColor',scheme.Dropdown.BackgroundColor.Value,...
    'FontName',scheme.Dropdown.Font.Value,...
    'FontColor', scheme.Dropdown.FontColor.Value,...
    'FontSize', scheme.Dropdown.FontSize.Value);

h.dropdown_coloraxis = uidropdown('Parent', h.panel,...
    'Position', [10, 60, 200, 25], ...
    'Items', {r.factors.Factor}, 'ItemsData', 1:length({r.factors.Factor}),...
    'BackgroundColor',scheme.Dropdown.BackgroundColor.Value,...
    'FontName',scheme.Dropdown.Font.Value,...
    'FontColor', scheme.Dropdown.FontColor.Value,...
    'FontSize', scheme.Dropdown.FontSize.Value);

h.dropdown_multiplot = uidropdown('Parent', h.panel,...
    'Position', [10, 10, 200, 25], ...
    'Items', {r.factors.Factor}, 'ItemsData', 1:length({r.factors.Factor}),...
    'BackgroundColor',scheme.Dropdown.BackgroundColor.Value,...
    'FontName',scheme.Dropdown.Font.Value,...
    'FontColor', scheme.Dropdown.FontColor.Value,...
    'FontSize', scheme.Dropdown.FontSize.Value);

%populate the tree object with information about the test
uitreenode('Parent', h.tree_info,...
    'Text', sprintf('Measurement:\t\t%s',r.type));

n = uitreenode('Parent', h.tree_info,...
    'Text', 'Factors');
for ii = 1:length(r.factors)
    f = uitreenode('Parent', n,...
        'Text', r.factors(ii).Factor);
    for jj = 1:length(r.factors(ii).Levels)
        uitreenode('Parent', f,...
            'Text', r.factors(ii).Levels{jj});
    end 
end
n = uitreenode('Parent', h.tree_info,...
    'Text', 'Conditions');
for ii = 1:length(r.conditions)
    uitreenode('Parent', n,'Text', r.conditions{ii});
end
uitreenode('Parent', h.tree_info, ...
    'Text', sprintf('\nTime window:\t\t%5.2fms to %5.2fms\n', r.timewindow(1), r.timewindow(2)));
uitreenode('Parent', h.tree_info,...
    'Text', sprintf('Time points:\t\tsample %i to sample %i\n', r.pntwindow(1), r.pntwindow(2)));
n = uitreenode('Parent', h.tree_info,...
    'Text', 'Channels');
chans_used = unique(r.chans_used);
for ii = 1:length(chans_used)
    uitreenode('Parent', n, 'Text', chans_used{ii});
end

%display means and standard deviations
d = r.within;

%add a column that holds the name of the file associated with each
%condition
if contains(r.factors(end).Factor, 'Channel')
    %if there are channels we have to do this once for each channel
    r.has_chans = true;
    r.nchan = length(r.factors(end).Levels);
    r.nfactors = length(r.factors);% -1;
    d.Conditions = repmat(r.conditions', r.nchan,1);
 %   d.Channel = r.chans_used';
else
    %if not, once is enough
    r.has_chans = false;
    r.nfactors = length(r.factors);
    d.Conditions = r.conditions';
end


%initialize the plotting drop downs
if r.nfactors == 1
    state = [false, false];
    default_select = [1,1];
elseif r.nfactors == 2
    state = [true, false];
    default_select = [2,2];
else
    state = [true, true];
    default_select = [2,3];
end
h.dropdown_coloraxis.Enable = state(1);
h.dropdown_coloraxis.Value = h.dropdown_coloraxis.ItemsData(default_select(1));
h.dropdown_multiplot.Enable = state(2);
h.dropdown_multiplot.Value = h.dropdown_multiplot.ItemsData(default_select(2));

%%
d = movevars(d, 'Conditions', 'Before', d.Properties.VariableNames{1});
d.Mean = num2cell(d.Mean);
d.StdDev = num2cell(d.StdDev);
d.StdErr = num2cell(d.StdErr);
d.Median = num2cell(d.Median);


h.desctable.Data = d{:,:};
h.desctable.ColumnName = d.Properties.VariableNames;
h.desctable.RowName = d.Properties.RowNames;

s = r.source_table;
sd = cellfun(@(x) num2str(x,3), num2cell(s.Variables), 'UniformOutput', false);
rows_to_change = contains(s.Properties.RowNames, 'Error');
if sum(rows_to_change)> 0
    sd(rows_to_change,4:end) = {''};
end
h.sourcetable.Data = sd;
h.sourcetable.ColumnName = s.Properties.VariableNames;
s.Properties.RowNames = strrep(s.Properties.RowNames, '(Intercept):','');
s.Properties.RowNames = strrep(s.Properties.RowNames, ':','*');
h.sourcetable.RowName = s.Properties.RowNames;

h.scheme = scheme;
h.dropdown_xaxis.ValueChangedFcn = {@callback_createplots, r, h};
h.dropdown_coloraxis.ValueChangedFcn = {@callback_createplots, r, h};
h.dropdown_multiplot.ValueChangedFcn = {@callback_createplots, r, h};

drawnow;

callback_createplots([],[],r,h)

%**************************************************************************
function data = getData(r, h)

%get the factor to show on the x axis
var(1) = h.dropdown_xaxis.Value;

%if available the factor to show as colors
if r.nfactors > 1
    var(2) = h.dropdown_coloraxis.Value;
end

%if available get the factor to show as different plots
if r.nfactors > 2
    var(3) = h.dropdown_multiplot.Value;
end

%get out if any of the factors above are the same
%this is expected if the person is part way through changing the values so
%dont make a big deal out of it
temp = unique(var);
if length(temp) ~= length(var)
    data = [];
    return
end

%it is easier to work with the data if it is not in a table
within = table2cell(r.within);

[~, id, ~] = unique(within(:,var(1)));
nOnXAxis = length(id);
axisLabel = within(sort(id), var(1));

if r.nfactors > 1
    [~, id, ~] = unique(within(:,var(2)));
    nColors = length(id);
    colorLabel = within(sort(id), var(2));
else
    nColors = 1;
    colorLabel = {'Mean'};
end

if r.nfactors > 2
    [~, id, ~] = unique(r.within(:,var(3)));
    nPlots = length(id);
    plotLabel = within(sort(id), var(3));
else
    nPlots = 1;
    plotLabel = {'Data'};
end

%make a structure for each plot
for ii = 1:nPlots

    data(ii).Mean = zeros(nOnXAxis, nColors);
    data(ii).StdErr = zeros(nOnXAxis, nColors);
    
    data(ii).XTitle = r.factors(var(1)).Factor;
    data(ii).YTitle = "ERP amplitude";
    data(ii).XLabels = axisLabel;
    data(ii).CLabels = colorLabel;
    data(ii).Title = plotLabel{ii};
    
    if nPlots > 1
        temp_table = within(within(:,var(3))==string(plotLabel{ii}),:);
    else
        temp_table = within;
    end
    for jj = 1:nOnXAxis
        if nColors == 1
            rows = temp_table(temp_table.within(:, var(1)) == string(axisLabel{jj}));
            data(ii).Means(jj,1) = mean([rows{:, r.nfactors+1}]);
            data(ii).StdErr(jj,1) = mean([rows{:,r.nfactors+2}]);
        else
            for kk = 1:nColors
                rows = temp_table(temp_table(:, var(1)) == string(axisLabel{jj}) & temp_table(:, var(2)) == string(colorLabel{kk}),:);
                %calculating the mean allows for more than one row entry
                %to be combined.  This will take care of the fact that
                %there may be more than 3 variables.
                data(ii).Mean(jj,kk) = mean([rows{:, r.nfactors + 1}]);
                data(ii).StdErr(jj,kk) = mean([rows{:, r.nfactors + 3}]);
            end
        end
    end
end
       

%**************************************************************************
function callback_createplots(hObject, event, r, h)
%makes plots - the current thinking is to make one for each channel'

%this is teh maximum # of factors that can be uniquely plotted.  More can
%be plotted, but they will not have unique symbols, colors, etc.
%this does not include the factor plotted on the xaxis


BarPlotIsVisible = true;

%remove any current axes
delete(h.axis_holder.Children);

d = getData(r, h);
if isempty(d)
    l = uilabel('Parent', h.axis_holder,...
        'Text', 'The same Variable cannot be assigned to more than one parameter',...
        'WordWrap','on',...
        'Position',[0,0,h.axis_holder.InnerPosition(3),h.axis_holder.InnerPosition(4)] ,...
        'VerticalAlignment','center',...
        'HorizontalAlignment','center',...
        'FontColor','w');
    drawnow;
    return
end

nPlots = length(d);

%set the size of teh axis
W = h.axis_holder.InnerPosition(3);
H = h.axis_holder.InnerPosition(4);
if nPlots > 1
    H = H/2.1;    
end

%now make some simple plots for testing

for ii = 1:nPlots
    B =(nPlots-ii) * H;
    a = uiaxes('Parent', h.axis_holder);
    if BarPlotIsVisible
        p = bar(a,d(ii).Mean);
        for jj = 1:length(p)
            p(jj).FaceAlpha = .5;
        end
    end
    a.OuterPosition = [0,B,W,H-20];
    a.XTickLabel = d(ii).XLabels;
    a.Color  = h.scheme.Axis.BackgroundColor.Value;
    a.FontSize = h.scheme.Axis.FontSize.Value;
    a.Box = "on";
    a.XColor = h.scheme.Axis.AxisColor.Value;
    a.YColor = h.scheme.Axis.AxisColor.Value;
    a.ZColor = h.scheme.Axis.AxisColor.Value;
    a.YGrid = "on";
    a.Title.String = d(ii).Title;
    a.Title.Color = h.scheme.Axis.AxisColor.Value;
    a.Toolbar.Visible = 'off';
    a.XLabel.String = d(ii).XTitle;
    a.YLabel.String = d(ii).YTitle;

%add error bars
    hold(a, "on")

    ngroups = size(d(ii).Mean, 1);
    nbars = size(d(ii).Mean, 2);

    % Calculating the width for each bar group
    groupwidth = min(0.8, nbars/(nbars + 1.5));
    colorRange = lines;
    for i = 1:nbars
        x = (1:ngroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*nbars);
        e= errorbar(a, x, d(ii).Mean(:,i), d(ii).StdErr(:,i), '.');
        e.Color = h.scheme.Axis.AxisColor.Value;
        e.LineWidth = 1;
        e.Marker = "o";
        e.MarkerSize = 10;
        e.MarkerEdgeColor = h.scheme.Axis.AxisColor.Value;
        e.MarkerFaceColor = colorRange(i,:);
    end
    %er = errorbar(a, d(ii).Mean, d(ii).StdErr,".");
    %er.LineStyle = ".";
    hold(a, 'off');

    l = legend(a,d(ii).CLabels);
    l.Box = "off";
    l.BackgroundAlpha = 0;
    l.TextColor = h.scheme.Axis.AxisColor.Value;   
    drawnow
end
%*************************************************************************
function rNew = arrangeData(r)
%right now this function is only removing the columns for the between
%subject variable because it interferes with the current plotting method
%in future, it will organize the data to allow for plotting of both between
%and within variables.

    rNew = r;
    if r.hasBetween
        %find out how many between variables there are
        nBetween = size(r.betweenVars,2);

        %strip off the between columns that were necessary for running the
        %stats. The betweencondition data still in the r.betweenVars
        %variable
        rNew.data = removevars(rNew.data,1:nBetween);

    end
    rNew.nlevels = cellfun(@length, {r.factors.Levels});
    
    %add some measures to teh data table
    if r.hasBetween
        tempdata = r.data(:,2:end);
    else
        tempdata = r.data;
    end
    rNew.within.StdDev = table2array(std(tempdata))';
    rNew.within.StdErr = rNew.within.StdDev ./ sqrt(height(r.within));
    rNew.within.Median = table2array(median(tempdata))';

%*************************************************************************
function [H,W,L,B] =  setFigureSizeAndPosition(scheme)

    if scheme.ScreenHeight < 1080
        H= scheme.ScreenHeight;
    else
        H = 1080;
    end
    if scheme.ScreenWidth < 1000
        W = scheme.ScreenWidth;
    else
        W = 1000;
    end
    L = (scheme.ScreenWidth - W) /2;
    B = (scheme.ScreenHeight - H)/2;
