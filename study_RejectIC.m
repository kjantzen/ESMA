function fh = study_RejectIC(filelist, threshold)


 if nargin < 1
     error('study_RejectIC: At least one intput is required for this function.');
 end

 if isempty(threshold)
     threshold = .6;
 end
    

%build the figure
p = plot_params;


W = 500; H = 300;
figpos = [(p.screenwidth - W)/2, (p.screenheight - H)/2, W, H];


handles.figure = uifigure(...
    'Color', p.backcolor,...
    'Position', figpos,...
    'NumberTitle', p.numbertitle,...
    'Menubar', p.menubar,...
    'Name', 'Remove Independent Components');
fh = handles.figure;

handles.uipanel1 = uipanel(...
    'parent', handles.figure,...
    'Position', [10,35, W-20, H-45],...
    'BackgroundColor', p.backcolor);

handles.button_mark = uibutton(...
    'Parent', handles.figure,...
    'Position', [W-110, 5, 100, 25],...
    'BackgroundColor', p.buttoncolor,...
    'FontColor', p.buttonfontcolor,...
    'Text', 'Mark for removal');

handles.button_cancel = uibutton(...
    'Parent', handles.figure,...
    'Position', [W-220, 5, 100, 25],...
    'BackgroundColor', p.buttoncolor,...
    'FontColor', p.buttonfontcolor,...
    'Text', 'Cancel');

if isempty(filelist)
    uialert(handles.figure, 'No files identified', 'Remove Components');
    closereq();
    return
end

if ~exist(filelist{1}, 'file')
    uialert(handles.figure, 'cannot find the specified file', 'Remove Components');
    closereq();
    return
end
fprintf('getting IC information from first file/n');

[fpath, fname, fext] = fileparts(filelist{1});
%EEGhead = pop_loadset('filepath', fpath, 'filename', [fname,fext], 'loadmode', 'info');
EEGhead = wwu_LoadEEGFile(filelist{1}, {'icasphere', 'etc'});
if isempty(EEGhead.icasphere)
    uialert(handles.figure, 'This data does not contain independent components.  Please run Preprocess -> ICA -> Compute ICA first.', 'Remove Components');
    closereq();
    return
end

if isempty(EEGhead.etc.ic_classification)
    uialert(handles.figure, 'This data does not contain independent components labels.  Please run Preprocess -> ICA -> Classify Comonents first.', 'Remove Components');
    closereq();
    return
end

nclasses = length(EEGhead.etc.ic_classification.ICLabel.classes);
xinc = 35;

maxcol = 3; col = 1; row = 1;
for ii = 1:nclasses
    
    xpos = 20 + ((col-1) * 150);
    ypos = handles.uipanel1.Position(4)-(row*xinc);
    handles.check_complabel(ii) = uicheckbox(...
        'Parent', handles.uipanel1, ...
        'Position', [xpos, ypos, 150, 25],...
        'Text', EEGhead.etc.ic_classification.ICLabel.classes{ii},...
        'Tag', num2str(ii),...
        'Value', 0,...
        'FontColor', p.labelfontcolor);
    
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
        'FontColor', p.labelfontcolor);

ypos = ypos - xinc;

uilabel('Parent', handles.figure,...
    'Text', 'Threshold for classifications', ...
    'Position', [20,ypos,200,25],...
    'FontColor', p.labelfontcolor);

handles.edit_threshold = uieditfield(handles.figure, 'numeric',...
    'Value', threshold * 100, ...
    'Limits', [1, 100],...
    'RoundFractionalValues', 'on',...
    'BackgroundColor', p.textfieldbackcolor,...
    'FontColor', p.textfieldfontcolor,...
    'Position', [240, ypos, 100, 25]);

ypos = ypos - (2*xinc);

handles.check_overwrite = uicheckbox(...
    'Parent', handles.figure,...
    'Position', [20, ypos, 300, 25],...
    'Text', 'Overwrite existing IC rejection information.',...
    'Value', 1,...
    'FontColor', p.labelfontcolor);

handles.button_mark.ButtonPushedFcn = {@callback_markbadica, handles};

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
delete(h.figure);


