function fh = study_RejectIC(filelist, threshold)


 if nargin < 1
     error('study_RejectIC:NoInputs', 'At least one intput is required for this function.');
 end

 if isempty(threshold)
     threshold = .6;
 end
    
 if isempty(filelist)
     error('study_RejectIC:NoFiles', 'No valid filelist was provided.');
 end

 for ii = 1:length(filelist)
    if ~exist(filelist{ii}, 'file')
        error('study_RejectIC:MissingFiles', 'At least one of the listed files is missing.');
    end
 end

fprintf('getting IC information from first file\n');

[fpath, fname, fext] = fileparts(filelist{1});
try
    EEGhead = wwu_LoadEEGFile(filelist{1}, {'icasphere', 'etc'});
catch me
    if contains(me.message, 'Unrecognized field name')
        error('study_RejectIC:NoICA', 'Your data files do not appear to have ICA components calculated');
    else
        rethrow me
    end
end
if ~isfield(EEGhead, 'icasphere') || isempty(EEGhead.icasphere)
    error('study_RejectICA:NoICA', 'This data does not contain independent components.  Please run Preprocess -> ICA -> Compute ICA first.');
end

if isempty(EEGhead.etc.ic_classification)
        error('study_RejectICA:NoICALabel', 'This data does not contain independent components labels.  Please run Preprocess -> ICA -> Classify Comonents first.');
end

classes = EEGhead.etc.ic_classification.ICLabel.classes;

handles = build_gui(classes);
handles.edit_threshold.Value =  threshold * 100;

fh = handles.figure;
handles.figure.UserData = filelist;
%***************************************************************************
function callback_markbadica(hObject, event, h)


threshold = h.edit_threshold.Value/100;
overwrite = h.check_overwrite.Value;

%get the rejection options
nclasses = length(h.check_complabel);
reject_classes = zeros(1,nclasses);

for ii = 1:length(h.check_complabel)
    if h.check_complabel(ii).Value==1
        class_num = str2double(h.check_complabel(ii).Tag) + 1;
        reject_classes(class_num) = 1;
    end
end

files = h.figure.UserData;

%include a progress bar here
pb = uiprogressdlg(h.figure, 'Title', 'IC reject', 'ShowPercentage', 'on');


for ii = 1:length(files)
    
    pb.Message = sprintf('Marking components for data file %i of %i', ii, length(files));
    pb.Value = ii/length(files);
    [fpath, fname, fext] = fileparts(files{ii});
  %  EEG = pop_loadset('filename', [fname, fext], 'filepath', fpath);
    EEG = wwu_LoadEEGFile(files{ii});
    
    if ~isfield(EEG.etc, 'ic_classification')
        fprintf('No classifications found.  Skipping file.\n')
        continue
    end
    
    weights = EEG.etc.ic_classification.ICLabel.classifications;
    [class, ic_indx] = wwu_getICclass(weights, threshold);

    if overwrite; EEG.reject.gcompreject = zeros(1, length(class)); end
    
    for jj = 1:nclasses
        if reject_classes(jj)==1
            EEG.reject.gcompreject(ic_indx(class==(jj-1))) = 1;
        end
    end
    
    fprintf('%i components marked as bad.  Saving file...\n', sum(EEG.reject.gcompreject));
    wwu_SaveEEGFile(EEG, files{ii});
    %save(files{ii}, '-v6', '-mat', 'EEG');
    
    
end
%close the figure when done
callback_closeFigure([],[],h);

% *************************************************************************
function callback_closeFigure(~,~, h)
   delete(h.figure)

% *************************************************************************
function handles = build_gui(classes)
%build the figure
scheme = eeg_LoadScheme;

W = 500; H = 300;
figpos = [(scheme.ScreenWidth - W)/2, (scheme.ScreenHeight - H)/2, W, H];

handles.figure = uifigure(...
    'Color', scheme.Window.BackgroundColor.Value,...
    'Position', figpos,...
    'NumberTitle', 'off',...
    'Menubar', 'none',...
    'Name', 'Mark Bad Independent Components');

handles.uipanel1 = uipanel(...
    'parent', handles.figure,...
    'Position', [10,45, W-20, H-55],...
    'BackgroundColor', scheme.Panel.BackgroundColor.Value,...
    'ForegroundColor',scheme.Panel.FontColor.Value,...
    'HighlightColor',scheme.Panel.BorderColor.Value,...
    'FontSize', scheme.Panel.FontSize.Value,...
    'FontName', scheme.Panel.Font.Value);

handles.button_mark = uibutton(...
    'Parent', handles.figure,...
    'Position', [W-110, 10, 100, 25],...
    'BackgroundColor', scheme.Button.BackgroundColor.Value,...
    'FontColor', scheme.Button.FontColor.Value,...
    'Fontname', scheme.Button.Font.Value,...
    'FontSize', scheme.Button.FontSize.Value,...
    'Text', 'Mark as Bad');

handles.button_cancel = uibutton(...
    'Parent', handles.figure,...
    'Position', [W-220, 10, 100, 25],...
    'BackgroundColor', scheme.Button.BackgroundColor.Value,...
    'FontColor', scheme.Button.FontColor.Value,...
    'Fontname', scheme.Button.Font.Value,...
    'FontSize', scheme.Button.FontSize.Value,...
    'Text', 'Cancel');

nclasses = length(classes);
xinc = 35;
maxcol = 3; col = 1; row = 1;
for ii = 1:nclasses
    
    xpos = 20 + ((col-1) * 150);
    ypos = handles.uipanel1.Position(4)-(row*xinc);
    handles.check_complabel(ii) = uicheckbox(...
        'Parent', handles.uipanel1, ...
        'Position', [xpos, ypos, 150, 25],...
        'Text', classes{ii},...
        'Tag', num2str(ii),...
        'Value', 0,...
        'FontColor', scheme.Checkbox.FontColor.Value,...
        'FontName', scheme.Checkbox.Font.Value,...
        'FontSize', scheme.Checkbox.FontSize.Value);
    
    if mod(ii, maxcol)==0 
        row = row + 1;
        col = 1;
    else
        col = col + 1;
    end
end

    xpos = 20 + ((col-1) * 150);
    ypos = handles.uipanel1.Position(4)-(row*xinc);
    handles.check_complabel(ii+1) = uicheckbox(...
        'Parent', handles.uipanel1, ...
        'Position', [xpos, ypos, 150, 25],...
        'Text', 'Unclassified',...
        'Tag', '0',...
        'Value', 0,...
        'FontColor', scheme.Checkbox.FontColor.Value,...
        'FontName', scheme.Checkbox.Font.Value,...
        'FontSize', scheme.Checkbox.FontSize.Value);

ypos = ypos - xinc;

uilabel('Parent', handles.figure,...
    'Text', 'Threshold for classifications', ...
    'Position', [20,ypos,200,25],...
    'FontColor', scheme.Label.FontColor.Value,...
    'FontSize', scheme.Label.FontSize.Value,...
    'FontName',scheme.Label.Font.Value);

handles.edit_threshold = uieditfield(handles.figure, 'numeric',...
    'Limits', [1, 100],...
    'RoundFractionalValues', 'on',...
    'ValueDisplayFormat','%i percent',...
    'BackgroundColor', scheme.Edit.BackgroundColor.Value,...
    'FontColor', scheme.Edit.FontColor.Value,...
    'FontName', scheme.Edit.Font.Value,...
    'FontSize', scheme.Edit.FontSize.Value,...
    'Position', [240, ypos, 100, 25]);

ypos = ypos - (xinc);

handles.check_overwrite = uicheckbox(...
    'Parent', handles.figure,...
    'Position', [20, ypos, 300, 25],...
    'Text', 'Overwrite existing IC rejection information.',...
    'Value', 1,...
    'FontColor', scheme.Checkbox.FontColor.Value,...
    'FontName', scheme.Checkbox.Font.Value,...
    'FontSize', scheme.Checkbox.FontSize.Value);

handles.button_mark.ButtonPushedFcn = {@callback_markbadica, handles};
handles.button_cancel.ButtonPushedFcn = {@callback_closeFigure, handles};


