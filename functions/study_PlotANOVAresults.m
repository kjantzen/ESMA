%study_PlotANOVAresults(r)
%   plots the results of an ANOVA based on the informationin the structure
%   r
function study_PlotANOVAresults(r)

%for now the philosophy will be to open an new figure each time the user
%requests a plot.

p = plot_params;
scheme = eeg_LoadScheme;

W = 600; H = 1080;
L = (scheme.ScreenWidth - W) /2;
B = (scheme.ScreenHeight - H)/2;
h.figure = uifigure('Position', [L, B, W, H],...
    'Color', p.backcolor);

h.grid = uigridlayout('Parent', h.figure,...
    'RowHeight', {'1x', 20,'1x', '2x',20, '1.5x'}, ...
    'ColumnWidth', {150, '1x'}, 'Scrollable', 'on',...
    'BackgroundColor',scheme.Window.BackgroundColor.Value);

h.tree_info = uitree('Parent', h.grid,...
    'BackgroundColor', scheme.Window.BackgroundColor.Value, ...
    'FontColor', scheme.Label.FontColor.Value,...
    'FontName', scheme.Label.Font.Value,...
    'FontSize', scheme.Label.FontSize.Value);
h.tree_info.Layout.Row = 1;
h.tree_info.Layout.Column = [1,2];

h.label_desc = uilabel('Parent', h.grid,'Text', 'Descriptives',...
    'FontColor', scheme.Label.FontColor.Value,...
    'FontName', scheme.Label.Font.Value,...
    'FontSize', scheme.Label.FontSize.Value);
h.label_desc.Layout.Row = 2;
h.label_desc.Layout.Column = 1;

h.copy_button = uibutton('Parent', h.grid,...
    'Text', 'Copy Descriptives',...
    'BackgroundColor',scheme.Button.BackgroundColor.Value,...
    'FontName', scheme.Button.Font.Value,...
    'FontColor', scheme.Button.FontColor.Value,...
    'FontSize', scheme.Button.FontSize.Value);
h.copy_button.Layout.Row = 2;
h.copy_button.Layout.Column = 2;

h.label_source = uilabel('Parent', h.grid,'Text', 'Source Table',...
    'FontColor', scheme.Label.FontColor.Value,...
    'FontName', scheme.Label.Font.Value,...
    'FontSize', scheme.Label.FontSize.Value);
h.label_source.Layout.Row = 5;
h.label_source.Layout.Column = [1,2];

h.desctable = uitable('Parent', h.grid);
h.desctable.Layout.Row = 3;
h.desctable.Layout.Column = [1,2];

h.sourcetable = uitable('Parent', h.grid);
h.sourcetable.Layout.Row = 6;
h.sourcetable.Layout.Column = [1,2];

h.tabgroup = uitabgroup('Parent', h.grid);
h.tabgroup.Layout.Row = 4;
h.tabgroup.Layout.Column = 2;

h.bar_tab = uitab('Parent', h.tabgroup,...
    'Title', 'Scatter Plot');
h.box_tab = uitab('Parent', h.tabgroup,...
    'Title', 'Box Plot');
h.ungroupedbox_tab = uitab('Parent', h.tabgroup,...
    'Title', 'Ungrouped Box Plot');
drawnow
pause(2);

h.axis_bar = uiaxes('Parent', h.bar_tab, 'Position', [0,0, h.tabgroup.InnerPosition(3), h.tabgroup.InnerPosition(4)-40]);
h.axis_box = uiaxes('Parent', h.box_tab, 'Position', [0,0, h.tabgroup.InnerPosition(3), h.tabgroup.InnerPosition(4)-40]);
h.axis_ungroupedbox = uiaxes('Parent', h.ungroupedbox_tab, 'Position', [0,0, h.tabgroup.InnerPosition(3), h.tabgroup.InnerPosition(4)-40]);


h.panel = uipanel('Parent', h.grid, 'Title', 'Legend');
h.panel.Layout.Row = 4;
h.panel.Layout.Column = 1;

uilabel('Parent', h.panel,...
    'Position', [10, 300, 130, 20],...
    'Text', 'Factor on x-axis',...
    'FontColor', p.labelfontcolor);

h.dropdown_xaxis = uidropdown('Parent', h.panel,...
    'Position', [10, 280, 130, 20], ...
    'Items', r.factors, 'ItemsData', 1:length(r.factors));

h.axis_legend = uiaxes('Parent', h.panel,...
    'Position', [0,0,150,280],...
    'Color', p.backcolor,...
    'XTick', [],...
    'YTick', [],...
    'Box', 'off',...
    'XColor', p.backcolor,...
    'YColor', p.backcolor);
h.axis_legend.Toolbar.Visible = 'off';


%populate the tree object with information about the test
uitreenode('Parent', h.tree_info,...
    'Text', sprintf('Measurement:\t\t%s',r.type));

n = uitreenode('Parent', h.tree_info,...
    'Text', 'Factors');
for ii = 1:length(r.factors)
    uitreenode('Parent', n,...
        'Text', sprintf('%s (%s)', r.factors{ii}, r.levels{ii}));
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

if contains(r.factors{end}, 'Channel')
    r.has_chans = true;
    r.nchan = str2double(r.levels{end});
    r.nfactors = length(r.factors) -1;
    d.Conditions = repmat(r.conditions', r.nchan,1);
    d.Channel = r.chans_used';
    d = movevars(d, 'Channel', 'Before', d.Properties.VariableNames{1}); 
else
    r.has_chans = false;
    r.nfactors = length(r.factors);
    d.Conditions = r.conditions';
end

d = movevars(d, 'Conditions', 'Before', d.Properties.VariableNames{1});
d.Mean = num2cell(d.Mean);
d.StdDev = num2cell(std(r.data.Variables)');

h.desctable.Data = d{:,:};
h.desctable.ColumnName = d.Properties.VariableNames;
h.desctable.RowName = d.Properties.RowNames;


s = r.source_table;
d = cellfun(@(x) num2str(x,3), num2cell(s.Variables), 'UniformOutput', false);
rows_to_change = contains(s.Properties.RowNames, 'Error');
if sum(rows_to_change)> 0
    d(rows_to_change,4:end) = {''};
end
h.sourcetable.Data = d;
h.sourcetable.ColumnName = s.Properties.VariableNames;
s.Properties.RowNames = strrep(s.Properties.RowNames, '(Intercept):','');
s.Properties.RowNames = strrep(s.Properties.RowNames, ':','*');
h.sourcetable.RowName = s.Properties.RowNames;

%make the statis box plot that compares all conditions without grouping
%************************************************************************
 if ~isfield(r, 'nchan')
     label_names = r.conditions;
 else    
     label_names = repmat(r.conditions, 1, r.nchan);
 end
 
 boxplot(h.axis_ungroupedbox, r.data{:,:},...
     'Notch', 'on', 'symbol', 'x', 'Labels', label_names,...
     'ColorGroup', r.within{:,end-1}, 'LabelVerbosity', 'minor');
%*************************************************************************

h.dropdown_xaxis.ValueChangedFcn = {@callback_createplots, r, h};
h.copy_button.ButtonPushedFcn = {@callback_copyDescriptives, h};


callback_createplots([],[],r,h)

%**********************************************************************
function callback_copyDescriptives(hObject, event, h)

   data = get(h.desctable, 'Data');
   
   str = [];
   for ii = 1:size(data,1)
        row = sprintf('%s, %s, %s, %s, %s, %f, %f\n',data{ii,:});
        str = [str,row];
   end
    clipboard('copy', str);
   

%**************************************************************************
function callback_createplots(hObject, event, r, h)
%makes plots - the current thinking is to make one for each channel'

%this is teh maximum # of factors that can be uniquely plotted.  More can
%be plotted, but they will not have unique symbols, colors, etc.
%this does not include the factor plotted on the xaxis
MAX_FACTORS = 4; 
SPREAD_WIDTH = .25;

%use these to cycle through different plot types
plot_fillcolor = {'#0072BD', '#D95319','#EDB120','#7E2F8E','#77AC30','#4DBEEE', '#A2142F'};
plot_symbol = {'o', 'd', 's', 'p', 'h', '+', '*', 'x'};
plot_linecolor = {'k', 'r', 'g', 'b', 'y', 'm', 'c'};
plot_symbol_size = {80, 100, 120, 140, 160, 180};

avedata = mean(r.data{:,:})';
stderr = std(r.data{:,:})'./ sqrt(size(r.data,1));

%get the factor to plot on the x-axis
xaxis_var = h.dropdown_xaxis.Value;
[~, id, ~] = unique(r.within{:,xaxis_var});
names = r.within{sort(id), xaxis_var};

xaxis_values = r.level_matrix(:,xaxis_var);

%now get the informaiton about the other factors after removing the one to
%plot on the xaxis
a = ones(size(r.levels));
a(xaxis_var) = 0;
rlm = r.level_matrix(:,a==1);
rcm = r.within(:,a==1);
rl = cellfun(@str2num, r.levels(a==1));
rf = r.factors(a==1);

offset = SPREAD_WIDTH/prod(rl);

if r.nfactors < MAX_FACTORS
    a = ones(size(r.level_matrix,1), MAX_FACTORS - r.nfactors+1);
    rlm = [rlm, a];
end


cla(h.axis_bar)
xcount = zeros(str2double(r.levels{xaxis_var}),1);

for ii = 1:length(xaxis_values)
            
            xcount(xaxis_values(ii)) = xcount(xaxis_values(ii)) + 1;
            xpos = xcount(xaxis_values(ii)) * offset - (SPREAD_WIDTH/2) + xaxis_values(ii);
            s = scatter(xpos, avedata(ii), 'Parent',h.axis_bar,...
                'Marker', plot_symbol{rlm(ii,2)},...
                'MarkerFaceColor', plot_fillcolor{rlm(ii,1)},...
                'MarkerEdgeColor', plot_linecolor{rlm(ii,3)},...
                'SizeData', plot_symbol_size{rlm(ii,4)},...
                'LineWidth', 1.5,...
                'MarkerFaceAlpha', 0.5);
            
            line(h.axis_bar, [xpos,xpos],...
                [avedata(ii) - stderr(ii), avedata(ii) + stderr(ii)], ...
                'linewidth', .5, 'color', 'k')
            
                hold(h.axis_bar,  'on');
end
h.axis_bar.XLim = [.5, max(xaxis_values)+.5];
h.axis_bar.XLabel.String = r.factors{xaxis_var};
h.axis_bar.XTick = 1:1:max(xaxis_values);
h.axis_bar.XTickLabel  = names;
h.axis_bar.YLabel.String = r.type;
h.axis_bar.XGrid = 'on';
h.axis_bar.YGrid = 'on';

%% make the box plot

boxplot(h.axis_box, r.data{:,:},r.level_matrix(:,xaxis_var),...
    'Notch', 'off', 'symbol', 'x', 'Labels', names, 'Colors', 'k', 'BoxStyle', 'outline');%,...
   % 'ColorGroup', 1:str2double(r.levels{xaxis_var}), 'LabelVerbosity', 'minor');
h.axis_box.YLabel.String = r.type;
h.axis_box.XLabel.String = r.factors{xaxis_var};
h.axis_box.YGrid = 'on';

%% plot the legend
hold(h.axis_legend, 'off');
cla(h.axis_legend);
hold(h.axis_legend, 'on');
  ypos = 100;
for ii = 1:length(rf)
  
    text(h.axis_legend, 1, ypos, rf{ii});
    [~,ia, ~] = unique(rcm(:,ii));
    lnames = rcm(sort(ia),ii);
   
    ypos = ypos - 5;
    
    ps = plot_symbol{1};
    fc = h.figure.Color;
    lc = plot_linecolor{1};
    ss = plot_symbol_size{1};
    
    
    for jj = 1:rl(ii)
        if ii == 1
            fc = plot_fillcolor{jj};
        elseif ii ==2
            ps = plot_symbol{jj};
        elseif ii ==3
            lc = plot_linecolor{jj};
        elseif ii == 4
            ss = plot_symbol_size{jj};
        else
            break
        end       
        scatter(h.axis_legend, 1,ypos, 'Marker', ps,'MarkerFaceColor', fc,'MarkerEdgeColor', lc, 'SizeData', ss, 'LineWidth', 1.5);
        text(h.axis_legend, 2, ypos,  lnames{jj,1});
        ypos  = ypos - 5;
        
    end
    ypos = ypos - 5;
end

if ypos > 50; ypos = 50; end
h.axis_legend.XLim = [.5, 6];
h.axis_legend.YLim = [ypos, 105];
