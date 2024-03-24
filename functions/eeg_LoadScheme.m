function scheme = eeg_LoadScheme(option)
arguments
    option.SchemeFile {mustBeText} = 'Default.mat';
    option.SchemePath {mustBeText, mustBeFolder} = fileparts(mfilename("fullpath"));
end

SchemeFile = fullfile(option.SchemePath, '..','config','schemes', option.SchemeFile);
if isfile(SchemeFile)
    scheme = load(SchemeFile, '-mat');
else
    scheme.Axis.AxisColor.Value =           [1,1,1];
    scheme.Axis.BackgroundColor.Value =     [0,	0.137,	0.235];
    scheme.Axis.Font.Value =                'Helvetica';
    scheme.Axis.FontSize.Value =            14;
    
    scheme.Dropdown.BackgroundColor.Value = [0,0.1765,0.3137];
    scheme.Dropdown.Font.Value =            'Helvetica';
    scheme.Dropdown.FontSize.Value =        11;
    scheme.Dropdown.FontColor.Value =       [.9412, .9412, .9412];
    scheme.Dropdown.Height.Value =          25;

    scheme.Button.BackgroundColor.Value =   [0.470588235294118,0.631372549019608,0.188235294117647];
    scheme.Button.Font.Value =              'Helvetica';
    scheme.Button.FontColor.Value =         [1,1,1];
    scheme.Button.FontSize.Value =          12;
    scheme.Button.Height.Value =            30;

    scheme.Panel.BackgroundColor.Value =    [0,0.137254901960784,0.235294117647059];
    scheme.Panel.BorderColor.Value =        [1,1,1];
    scheme.Panel.Font.Value =               'Helvetica';
    scheme.Panel.FontSize.Value =           10;
    scheme.Panel.FontColor.Value =          [0.392156862745098,0.831372549019608,0.074509803921569];

    scheme.Edit.BackgroundColor.Value =     [0,0.176470588235294,0.313725490196078];
    scheme.Edit.Font.Value =                'Helvetica';
    scheme.Edit.FontSize.Value =            12;
    scheme.Edit.FontColor.Value =           [0.901960784313726,0.901960784313726,0.901960784313726];
    scheme.Edit.Height.Value =              25;

    scheme.Checkbox.FontColor.Value =       [0.941176470588235,0.941176470588235,0.941176470588235];
    scheme.Checkbox.Font.Value =            'Helvetica';
    scheme.Checkbox.FontSize.Value =        11;

    scheme.Label.FontColor.Value =          [0.941176470588235,0.941176470588235,0.941176470588235];
    scheme.Label.Font.Value =               'Helvetica';
    scheme.Label.FontSize.Value =           11;

    scheme.Window.BackgroundColor.Value =   [0,0.137254901960784,0.235294117647059];
end
sz = get(0, "ScreenSize");
scheme.ScreenWidth = sz(3);
scheme.ScreenHeight = sz(4);
%very hacky work around for the windows task bar
if ispc
    scheme.ScreenHeight = scheme.ScreenHeight - 50;
end
scheme.GoodSubjectColor = [.2, .8, .2];
scheme.BadSubjectColor = [.8, .2, .2];
