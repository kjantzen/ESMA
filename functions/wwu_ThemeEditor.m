% THEMEEDITOR - provides an interface for editing the scheme of the
% plotter interface
function fig = wwu_ThemeEditor(options)

    arguments
        options.SchemeFile = ''
    end
    
    p = eeg_LoadScheme(options.SchemeFile);
    if isempty(p)
        return
    end
    
    h = buildGUI(p);
    fig = h.fig; 
    [~, f,e] = fileparts(options.SchemeFile);
    if ~isempty(f)
        fig.Name = ['Theme: ', [f,e]];
    end
    h.SchemeFile = options.SchemeFile;
    setParameters(h,p);
    saveUserData(h.fig, h, p);

end

%% Callback functions
% ************************************************************************
function callback_selectScheme(src, ~, fig)
    [h,p] = readUserData(fig);
    fig.Name = ['Theme: ', src.Text];
    p = eeg_LoadScheme(src.UserData);

    drawEditPanel(h, p);
    setParameters(h,p);
    h.SchemeFile = src.UserData;
    saveUserData(fig, h, p);

    
end
% ************************************************************************
function callback_ChangeColor(src, ~, fig)

    [h,p] = readUserData(fig);
    fields = src.UserData;
    currColor = p.(fields{1}).(fields{2}).Value;
    txt = sprintf('Select a new %s color for %s', fields{2}, fields{1});
    newColor = uisetcolor(currColor,txt);

    src.BackgroundColor = newColor;
    p.(fields{1}).(fields{2}).Value = newColor;
    setParameters(h,p);
    saveUserData(fig, h, p);
  
end
% ************************************************************************
function callback_ChangeFontOrSize(src, evt, fig)

    [h,p] = readUserData(fig);
    fields = src.UserData;
    var = src.Value;
    p.(fields{1}).(fields{2}).Value = var;
    setParameters(h,p);
    saveUserData(fig, h, p);
  
end
% ************************************************************************
function callback_Close(~,~,f)
    close(f);
end
% ************************************************************************

function callback_SaveScheme(~,~,f, SaveAsFlag)
    [h,p] = readUserData(f);

    %if there is no current name for this scheme
    if ~SaveAsFlag && isempty(h.SchemeFile)
        SaveAsFlag = true;
        h.SchemeFile = fullfile(schemeFilePath);
    end

    if SaveAsFlag
        [saveFile, saveLoc] = uiputfile('*.mat','Enter a name for the theme file', fullfile(schemeFilePath, h.SchemeFile));
        if saveFile == 0
            return
        end
        h.SchemeFile =fullfile(saveLoc, saveFile);
    end

    save(h.SchemeFile, '-struct','p', '-mat');
end
   
%% Helper functions
% ************************************************************************
function [h,p] = readUserData(f)
    v = f.UserData;
    h = v{1}; p = v{2};
end
% ************************************************************************
function saveUserData(f,h,p)
    f.UserData = {h,p};
end
% ************************************************************************
function p = loadScheme(schemeFile)
    
%if no scheme file is passed, populate with the defaults
    if isempty(schemeFile)
        p = eeg_DefaultScheme;
    else
        if ~isfile(schemeFile)
            warning('Could not find the theme file in the editor folder.  Resorting to defaults!');
            p = eeg_DefaultScheme;
        else
            p = load(schemeFile);
        end
    end
end
% ************************************************************************
function schemePath = schemeFilePath()
    cp = mfilename('fullpath');
    [cp,~,~] = fileparts(cp);
    schemePath = fullfile(cp, '..','config','schemes');
end
%% GUI Function
% ************************************************************************
function setParameters(h,p)

    %the window bit
    h.dispWindow.BackgroundColor = p.Window.BackgroundColor.Value;

    %the axis
    h.dispAxis.FontSize = p.Axis.FontSize.Value;
    h.dispAxis.FontName = p.Axis.Font.Value;
    h.dispAxis.Color = p.Axis.BackgroundColor.Value;
    h.dispAxis.XColor = p.Axis.AxisColor.Value;
    h.dispAxis.YColor = p.Axis.AxisColor.Value;

    %the traces
    if isfield(p, 'EEGTraces')
        h.eegtrace_good.Color = p.EEGTraces.GoodColor.Value;
        h.eegtrace_bad.Color = p.EEGTraces.BadColor.Value;
        h.icatrace_good.Color = p.ICATraces.GoodColor.Value;
        h.icatrace_bad.Color = p.ICATraces.BadColor.Value;

        h.eegtrace_good.LineWidth = p.EEGTraces.Width.Value;
        h.eegtrace_bad.LineWidth = p.EEGTraces.Width.Value;
        h.icatrace_good.LineWidth = p.ICATraces.Width.Value;
        h.icatrace_bad.LineWidth = p.ICATraces.Width.Value;
    end

    %the panel
    h.dispPanel.BackgroundColor = p.Panel.BackgroundColor.Value;
    h.dispPanel.HighlightColor = p.Panel.BorderColor.Value;
    h.dispPanel.FontName = p.Panel.Font.Value;
    h.dispPanel.FontSize = p.Panel.FontSize.Value;
    h.dispPanel.ForegroundColor = p.Panel.FontColor.Value;
    
    %the button
    h.dispButton.BackgroundColor = p.Button.BackgroundColor.Value;
    h.dispButton.FontName = p.Button.Font.Value;
    h.dispButton.FontSize = p.Button.FontSize.Value;
    h.dispButton.Position(4) = p.Button.Height.Value;
    h.dispButton.FontColor = p.Button.FontColor.Value;

    %the label
    h.dispLabel.FontColor = p.Label.FontColor.Value;
    h.dispLabel.FontName = p.Label.Font.Value;
    h.dispLabel.FontSize = p.Label.FontSize.Value;

    %the checkbox
    h.dispCheckbox.FontName = p.Checkbox.Font.Value;
    h.dispCheckbox.FontSize = p.Checkbox.FontSize.Value;
    h.dispCheckbox.FontColor = p.Checkbox.FontColor.Value;

    %the dropdown
    h.dispDropdown.BackgroundColor = p.Dropdown.BackgroundColor.Value;
    h.dispDropdown.FontName = p.Dropdown.Font.Value;
    h.dispDropdown.FontSize = p.Dropdown.FontSize.Value;
    h.dispDropdown.FontColor = p.Dropdown.FontColor.Value;
    h.dispDropdown.Position(4) = p.Dropdown.Height.Value;

    %the edit field
    h.dispEdit.BackgroundColor = p.Edit.BackgroundColor.Value;
    h.dispEdit.FontName = p.Edit.Font.Value;
    h.dispEdit.FontSize = p.Edit.FontSize.Value;
    h.dispEdit.FontColor = p.Edit.FontColor.Value;
    h.dispEdit.Position(4) = p.Edit.Height.Value;

    h.legnd.TextColor = p.Axis.AxisColor.Value;
    h.dispWindow.ForegroundColor = p.Panel.FontColor.Value;
    

end
% ************************************************************************
function h = buildGUI(p)

eh = findall(groot, 'Type', 'figure');
for ii = 1:length(eh)
    if strcmp(eh(ii).Tag, 'Appearance Editor')
        delete(eh(ii))
        break;
    end
end

h.fig = uifigure('Position', [100,100,700,550]);
h.fig.Tag = 'Appearance Editor';


 %create a menu for accessing the existing schemes
 h.menu_file = uimenu('Parent', h.fig,...
       'Text','&File',...
       'Accelerator','f');
 
 h.menu_save = uimenu('Parent', h.menu_file,...
     'Text','&Save', 'Accelerator','s',...
     'MenuSelectedFcn',{@callback_SaveScheme, h.fig, false});

 h.menu_saveas = uimenu('Parent', h.menu_file,...
     'Text','Save &As', 'Accelerator','a',...
     'MenuSelectedFcn',{@callback_SaveScheme, h.fig, true});

 h.menu_quit = uimenu('Parent', h.menu_file,...
     'Text', '&Quit', 'Accelerator','q',...
     'MenuSelectedFcn', {@callback_Close, h.fig});

 h.menu_scheme = uimenu('Parent', h.fig,...
     'Text',' Themes');

 schemeList = getSchemeList();
 for ii = 1:length(schemeList)
     [~,schemeName,~] = fileparts(schemeList(ii).name);
     h.schemeMenu(ii) = uimenu('Parent', h.menu_scheme,...
         'Text', schemeName,...
         'UserData',fullfile(schemeList(ii).folder, schemeList(ii).name),...
         'MenuSelectedFcn',{@callback_selectScheme, h.fig});
 end

 
grid = uigridlayout('Parent', h.fig);
grid.RowHeight = {'1x'};
grid.ColumnWidth = {240,'1x'};
drawnow
pause(1)

h.ePanel = uipanel('Parent', grid,'Title','Edit Properites');
h.ePanel.Scrollable = 'on';
drawnow;
pause(1)

%% draw the controls for changing parameters
h = drawEditPanel(h, p);

%create some fake data to display
x = 0:.1:2;
y = sin(10 * x);

%% draw the controls for displaying the current parameters
    h.dispWindow = uipanel('Parent',grid,'Title','WINDOW');
    h.dispWindow.Layout.Column = 2;
    h.dispWindow.Layout.Row = 1;
    drawnow;
    pause(1);

    pos = h.dispWindow.InnerPosition;
    h.dispAxis = uiaxes('Parent', h.dispWindow,'Position', [0, pos(4)-280, pos(3), 270], 'Toolbar',[]);
    h.eegtrace_good = line(h.dispAxis, x, y+8);
    h.eegtrace_bad = line(h.dispAxis, x, y+6);
    h.icatrace_good = line(h.dispAxis, x, y+4);
    h.icatrace_bad = line(h.dispAxis, x, y+2);

    h.dispAxis.YLim = [0,10];
    h.legnd = legend(h.dispAxis, {'eeg good', 'eeg bad', 'pca good', 'pca bad'});
    h.legnd.Box = 'off'; h.legnd.Location = "northoutside"; h.legnd.FontSize = 10; h.legnd.NumColumns = 4; h.legnd.Color = 'none';
    
    h.dispPanel = uipanel('Parent',h.dispWindow,'Title','PANEL',...
        'Position',[10,10,pos(3)-20,200]);
    h.dispLabel = uilabel('Parent', h.dispPanel, 'Position',[30,120, 100, 20], ...
        'Text', 'Label Text');
    h.dispDropdown = uidropdown('Parent', h.dispPanel, 'Position', [180, 120, 120, 20],...
        'Items',{'Dropdown Option 1', 'Dropdown Option 2'});
    h.dispCheckbox = uicheckbox('Parent', h.dispPanel, 'Position',[30,60, 150, 20], ...
          'Text','Checkbox Control');
    h.dispButton = uibutton('Parent', h.dispPanel, 'Position',[180,60, 120, 30], ...
          'Text','Button Control');
    h.dispEdit = uieditfield('Parent', h.dispPanel, 'Position', [50, 10, 200, 30],...
        'Value', 'Sample edit field text.');
     

end
%**************************************************************************
function h = drawEditPanel(h, p)
    
    parent = h.ePanel;
    ch = allchild(parent);
    if ~isempty(ch)
        delete(ch);
    end

    fonts = listfonts;

    controls = fieldnames(p);
    bottom = 10;
    left = parent.InnerPosition(3)-100;
for cc = length(controls):-1:1
    if ~isstruct(p.(controls{cc}))
        continue
    end
    props = fieldnames(p.(controls{cc}));
    for pp = length(props):-1:1
        uilabel('Parent', parent,'Text', props{pp},...
            'Position', [30,bottom,100,25]);

        sprintf('control: %s, property: $s\n', controls{cc}, props{pp});
        switch p.(controls{cc}).(props{pp}).Type
            case 'Color'
                uibutton('Parent', parent, 'BackgroundColor',p.(controls{cc}).(props{pp}).Value,...
                    'Position', [left, bottom, 80,20], 'Text','',...
                    'UserData', {controls{cc}, props{pp}}, ...
                    'ButtonPushedFcn', {@callback_ChangeColor, h.fig});
            case 'Font'
                uidropdown('Parent', parent, 'Items',fonts,'Value',...
                    p.(controls{cc}).(props{pp}).Value,...
                    'Position',[left-20, bottom, 100,20],...
                    'UserData', {controls{cc}, props{pp}}, ...
                    'ValueChangedFcn',{@callback_ChangeFontOrSize, h.fig});
            case 'Integer'
                uispinner('Parent',parent, 'Step',1,'Limits',[1,100],...
                    'Value',p.(controls{cc}).(props{pp}).Value,...
                    'Position',[left, bottom, 80,20],...
                    'RoundFractionalValues','on',...
                    'UserData', {controls{cc}, props{pp}}, ...
                    'ValueChangedFcn',{@callback_ChangeFontOrSize, h.fig});
        end

        bottom = bottom + 30;

    end

    uilabel('Parent', parent, ...
        'Text', upper(controls{cc}),...
        'Position', [10, bottom, 100, 25]);
    bottom = bottom + 30;
end

end
%*************************************************************************
function list = getSchemeList()

    cp = mfilename('fullpath');
    [cp,~,~] = fileparts(cp);
    f = fullfile(cp, '..','config','themes', '*.mat');
    list = dir(f);

end
