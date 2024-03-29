function p = eeg_DefaultScheme()
% in case the file is not found on disk, this will provide some defaults

p.Axis.AxisColor.Value = [0,0,0]; p.Axis.AxisColor.Type = 'Color';
p.Axis.BackgroundColor.Value = [1,1,1]; p.Axis.BackgroundColor.Type = 'Color';
p.Axis.Font.Value = 'Helvetica'; p.Axis.Font.Type = 'Font';
p.Axis.FontSize.Value = 14; p.Axis.FontSize.Type = 'Integer';

p.Dropdown.BackgroundColor.Value = [1,1,1];p.Dropdown.BackgroundColor.Type = 'Color';
p.Dropdown.Font.Value = 'Helvetica';p.Dropdown.Font.Type = 'Font';
p.Dropdown.FontSize.Value  = 11;p.Dropdown.FontSize.Type  = 'Integer';
p.Dropdown.FontColor.Value = [0,0,0];p.Dropdown.FontColor.Type = 'Color';
p.Dropdown.Height.Value = 25;p.Dropdown.Height.Type = 'Integer';

p.Button.BackgroundColor.Value = [.8,.8,.8]; p.Button.BackgroundColor.Type = 'Color';
p.Button.Font.Value = 'Helvetica'; p.Button.Font.Type = 'Font';
p.Button.FontColor.Value = [0,0,0];p.Button.FontColor.Type = 'Color';
p.Button.FontSize.Value = 11; p.Button.FontSize.Type = 'Integer';
p.Button.Height.Value = 30; p.Button.Height.Type = 'Integer';

p.Panel.BackgroundColor.Value = [.95,.95,.95]; p.Panel.BackgroundColor.Type = 'Color';
p.Panel.BorderColor.Value = [0,0,0]; p.Panel.BorderColor.Type = 'Color';
p.Panel.Font.Value = 'Helvetica'; p.Panel.Font.Type = 'Font';
p.Panel.FontSize.Value = 11; p.Panel.FontSize.Type = 'Integer';
p.Panel.FontColor.Value = [1,1,1]; p.Panel.FontColor.Type = 'Color';

p.Edit.BackgroundColor.Value = [.95,.95,.95]; p.Edit.BackgroundColor.Type = 'Color';
p.Edit.Font.Value = 'Helvetica'; p.Edit.Font.Type = 'Font';
p.Edit.FontSize.Value = 11; p.Edit.FontSize.Type = 'Integer';
p.Edit.FontColor.Value = [0,0,0]; p.Edit.FontColor.Type = 'Color';
p.Edit.Height.Value = 30; p.Edit.Height.Type = 'Integer';

p.Checkbox.FontColor.Value = [0,0,0]; p.Checkbox.FontColor.Type = 'Color';
p.Checkbox.Font.Value = 'Helvetica'; p.Checkbox.Font.Type = 'Font';
p.Checkbox.FontSize.Value = 11; p.Checkbox.FontSize.Type = 'Integer';

p.Label.FontColor.Value = [0,0,0]; p.Label.FontColor.Type = 'Color';
p.Label.Font.Value = 'Helvetica'; p.Label.Font.Type = 'Font';
p.Label.FontSize.Value = 11; p.Label.FontSize.Type = 'Integer';

p.Window.BackgroundColor.Value = [.95,.95,.95]; p.Window.BackgroundColor.Type = 'Color';

%colors for the raw and epoched eeg data traces
p.EEGTraces.GoodColor.Value = [0,0,1]; p.EEGTraces.GoodColor.Type = 'Color';
p.EEGTraces.BadColor.Value = [1,0,0]; p.EEGTraces.BadColor.Type = 'Color';
p.EEGTraces.Width.Value = 1; p.EEGTraces.Width.Type = 'Integer';

%colors for the PCA traces
p.PCATraces.GoodColor.Value = [0,1,0]; p.PCATraces.GoodColor.Type = 'Color';
p.PCATraces.BadColor.Value = [1,0,0]; p.PCATraces.BadColor.Type = 'Color';
p.PCATraces.Width.Value = 1; p.PCATraces.Width.Type = 'Integer';

%colors for the different ERP conditions
%p.ERPTraces.Color
%lc = line_colors
%    lc(1,:) = [.5, 1, .5];
%   lc(2,:) = [.2, 1, 1];
%    lc(3,:) = [1, .4, .4];
%    lc(4,:) = [1, 1, .4];
%    lc(5,:) = [.6, .6, 1];
%    lc(6,:) = [1, .6, 1];
%    lc(7,:) = [1, 1, 0];
%    lc(8,:) = [0, 1, 0];

end