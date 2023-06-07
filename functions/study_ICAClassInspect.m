%study_ICAClassInspect() - GUI for inpsecting the ICA compoennts previous 
%                           classified using the ICLabel plugin for EEGLAB.
%                           Allows for changing the threshold for
%                           automatically identifying IC compoenents and
%                           rejecting components for later removal prior to
%                           averaging.
%Usaage:
%>> study_Averager_GUI(study, filenames);
%
%Required Inputs:
%   study       -   an hcnd STUDY structure passed from the hcnd_eeg main 
%                   interface or from the command line. 
%
%   filenames   -   a cell array of filenames to review.  The routine
%                   automatically assumes one filename for each participant 
%                   listed in the study structure.

% Update 5/13/20 KJ Jantzen
function study_ICAClassInspect(study, filenames)

%build the figure
scheme = eeg_LoadScheme;
scheme.Axis.FontSize.Value = 10;
W = round(scheme.ScreenWidth * .4); H = round(scheme.ScreenHeight * .5);
figpos = [420, scheme.ScreenHeight - H, W, H];

fprintf('Opening ICA Class Inspector...\n');
fprintf('...creating GUI\n');
handles.figure = uifigure(...
    'Color', scheme.Window.BackgroundColor.Value,...
    'Position', figpos,...
    'NumberTitle', 'off',...
    'Menubar', 'none',...
    'Name', 'ICA classification inspector');

handles.grid = uigridlayout(handles.figure,...
    'RowHeight', {'fit','3x','1x', '2x'}, ...
    'ColumnWidth', {'1x', '1x', '1x','1x', '1x', '1x','1x', '1x', '1x'},...
    'BackgroundColor',scheme.Window.BackgroundColor.Value);

handles.dropdown_selsubject = uidropdown('Parent', handles.grid,...
    'BackgroundColor',scheme.Dropdown.BackgroundColor.Value,...
    'FontName', scheme.Dropdown.Font.Value,...
    'FontSize', scheme.Dropdown.FontSize.Value,...
    'FontColor', scheme.Dropdown.FontColor.Value);
handles.dropdown_selsubject.Layout.Row = 1;
handles.dropdown_selsubject.Layout.Column = 1;

handles.label = uilabel('Parent', handles.grid,...
    'FontName', scheme.Label.Font.Value,...
    'FontSize', scheme.Label.FontSize.Value,...
    'FontColor', scheme.Label.FontColor.Value);
handles.label.Layout.Row = 1;
handles.label.Layout.Column = 2;
handles.label.Text = 'Threshold (%)';
handles.label.HorizontalAlignment = 'right';

handles.spinner_threshold = uispinner('Parent', handles.grid,...
    'BackgroundColor',scheme.Dropdown.BackgroundColor.Value,...
    'FontName', scheme.Dropdown.Font.Value,...
    'FontSize', scheme.Dropdown.FontSize.Value,...
    'FontColor', scheme.Dropdown.FontColor.Value);

handles.spinner_threshold.Layout.Row = 1;
handles.spinner_threshold.Layout.Column = 3;
handles.spinner_threshold.RoundFractionalValues = 'on';
handles.spinner_threshold.ValueDisplayFormat = '%i%%';
handles.spinner_threshold.Limits = [1 100];
handles.spinner_threshold.Value = 60;

handles.button_togglestatus = uibutton('Parent', handles.grid,...
    'BackgroundColor', scheme.Button.BackgroundColor.Value,...
    'FontName', scheme.Button.Font.Value,...
    'FontSize', scheme.Button.FontSize.Value,...
    'FontColor', scheme.Button.FontColor.Value);
handles.button_togglestatus.Layout.Row = 1;
handles.button_togglestatus.Layout.Column = 8;
handles.button_togglestatus.Text = 'Toggle status';

handles.button_markcomps = uibutton('Parent', handles.grid,...
    'BackgroundColor', scheme.Button.BackgroundColor.Value,...
    'FontName', scheme.Button.Font.Value,...
    'FontSize', scheme.Button.FontSize.Value,...
    'FontColor', scheme.Button.FontColor.Value);
handles.button_markcomps.Layout.Row = 1;
handles.button_markcomps.Layout.Column = [6,7];
handles.button_markcomps.Text = 'Reject Components...';

handles.spinner_selcomp = uispinner('Parent', handles.grid,...
    'BackgroundColor',scheme.Dropdown.BackgroundColor.Value,...
    'FontName', scheme.Dropdown.Font.Value,...
    'FontSize', scheme.Dropdown.FontSize.Value,...
    'FontColor', scheme.Dropdown.FontColor.Value);
handles.spinner_selcomp.Layout.Row = 1;
handles.spinner_selcomp.Layout.Column = 9;
handles.spinner_selcomp.RoundFractionalValues = 'on';
handles.spinner_selcomp.ValueDisplayFormat = 'IC %i';
handles.spinner_selcomp.Limits = [1 64];

handles.axis_compclassraw = uiaxes('Parent', handles.grid,...
    'Color',scheme.Axis.BackgroundColor.Value,...
    'XColor',scheme.Axis.AxisColor.Value,...
    'YColor', scheme.Axis.AxisColor.Value,...
    'FontName', scheme.Axis.Font.Value,...
    'FontSize', scheme.Axis.FontSize.Value,...
    'XGrid', 'on', 'YGrid', 'on');
handles.axis_compclassraw.Layout.Row = 2;
handles.axis_compclassraw.Layout.Column = [1 4];
handles.axis_compclassraw.Toolbar.Visible = 'off';

handles.axis_compclassthresh = uiaxes('Parent', handles.grid,...
    'Color',scheme.Axis.BackgroundColor.Value,...
    'XColor',scheme.Axis.AxisColor.Value,...
    'YColor', scheme.Axis.AxisColor.Value,...
    'FontName', scheme.Axis.Font.Value,...
    'FontSize', scheme.Axis.FontSize.Value,...
    'XGrid', 'on', 'YGrid', 'on');
handles.axis_compclassthresh.Layout.Row = 3;
handles.axis_compclassthresh.Layout.Column = [1 4];
handles.axis_compclassthresh.Toolbar.Visible = 'off';

handles.axis_icatopo = uiaxes('Parent', handles.grid,...
    'Color',scheme.Axis.BackgroundColor.Value,...
    'XColor',scheme.Axis.AxisColor.Value,...
    'YColor', scheme.Axis.AxisColor.Value,...
    'FontName', scheme.Axis.Font.Value,...
    'FontSize', scheme.Axis.FontSize.Value,...
    'XGrid', 'on', 'YGrid', 'on');
handles.axis_icatopo.Toolbar.Visible = 'off';
handles.axis_icatopo.Layout.Row = [2,3];
handles.axis_icatopo.Layout.Column = [5,6];

handles.axis_icaerp = uiaxes('Parent', handles.grid,...
    'Color',scheme.Axis.BackgroundColor.Value,...
    'XColor',scheme.Axis.AxisColor.Value,...
    'YColor', scheme.Axis.AxisColor.Value,...
    'FontName', scheme.Axis.Font.Value,...
    'FontSize', scheme.Axis.FontSize.Value,...
    'XGrid', 'on', 'YGrid', 'on');
handles.axis_icaerp.Toolbar.Visible = 'off';
handles.axis_icaerp.Layout.Row = [2,3];
handles.axis_icaerp.Layout.Column = [7,9];

handles.axis_icafft = uiaxes('Parent', handles.grid,...
    'Color',scheme.Axis.BackgroundColor.Value,...
    'XColor',scheme.Axis.AxisColor.Value,...
    'YColor', scheme.Axis.AxisColor.Value,...
    'FontName', scheme.Axis.Font.Value,...
    'FontSize', scheme.Axis.FontSize.Value,...
    'XGrid', 'on', 'YGrid', 'on');
handles.axis_icafft.Toolbar.Visible = 'off';
handles.axis_icafft.Layout.Row = 4;
handles.axis_icafft.Layout.Column = [5,6];

handles.axis_icamean = uiaxes('Parent', handles.grid,...
    'Color',scheme.Axis.BackgroundColor.Value,...
    'XColor',scheme.Axis.AxisColor.Value,...
    'YColor', scheme.Axis.AxisColor.Value,...
    'FontName', scheme.Axis.Font.Value,...
    'FontSize', scheme.Axis.FontSize.Value,...
    'XGrid', 'on', 'YGrid', 'on');
handles.axis_icamean.Toolbar.Visible = 'off';
handles.axis_icamean.Layout.Row = 4;
handles.axis_icamean.Layout.Column = [7,9];

handles.axis_compbar = uiaxes('Parent', handles.grid,...
    'Color',scheme.Axis.BackgroundColor.Value,...
    'XColor',scheme.Axis.AxisColor.Value,...
    'YColor', scheme.Axis.AxisColor.Value,...
    'FontName', scheme.Axis.Font.Value,...
    'FontSize', scheme.Axis.FontSize.Value,...
    'XGrid', 'on', 'YGrid', 'on');
handles.axis_compbar.Layout.Row = 4;
handles.axis_compbar.Layout.Column = [1 4];
handles.axis_compbar.Toolbar.Visible = 'off';

handles.dropdown_selsubject.Items   = {study.subject.ID};
handles.dropdown_selsubject.ItemsData = 1:length(study.subject);
handles.dropdown_selsubject.UserData = filenames;

handles.dropdown_selsubject.ValueChangedFcn = {@callback_loadnewfile, handles};
handles.spinner_threshold.ValueChangedFcn = {@callback_plotclassifications, handles};
handles.spinner_selcomp.ValueChangedFcn = {@callback_plotclassifications, handles};
handles.figure.WindowButtonDownFcn = {@callback_handlemouseevents, handles};
handles.figure.CloseRequestFcn = {@callback_myclosefcn, handles};
handles.button_togglestatus.ButtonPushedFcn = {@callback_togglestatus, handles};
handles.button_markcomps.ButtonPushedFcn = {@callback_rejectic, handles};

%create a custom color map for the component classes 
p.mycolmap = [.6,.6,.6;
    0.4660    0.6740    0.1880;
    0.7500    0.3250    0.0980;
    0.9290    0.6940    0.1250;
    0.4940    0.1840    0.5560;
    0.7700    0.3300    0.6000;
    0    0.4470    0.7410;
    0.6350    0.0780    0.1840];
p.badtrialcolor = [.8, .2, .2];
p.goodtrialcolor = [.2, .8, .2];
p.scheme = scheme;
handles.figure.UserData = p;

fprintf('...loading and displaying data\n');
callback_loadnewfile([], [], handles)
fprintf('..done\n')

%*************************************************************************
function EEG = getNewestData(h, EEG)
%check to make sure that there is no other window that has modified data
%that may be used here.
if study_checkForUnsavedData(h.figure)
    snum = h.dropdown_subjselect.Value;
    fnames = h.dropdown_subjselect.UserData;
    filename = fnames{snum};

    %make sure something was passed
    if isempty(filename)
        uialert(h.figure, 'No data to load and plot!');
        return
    end

    EEG = wwu_LoadEEGFile(filename);
end   
%*************************************************************************
function callback_togglestatus(jObject, eventdata,h)
    
p = h.figure.UserData;
icnum = h.spinner_selcomp.Value;

p.EEG = getNewestData(h, p.EEG);
p.EEG.reject.gcompreject(icnum) = ~p.EEG.reject.gcompreject(icnum);
p.EEG.saved = 'no';
h.figure.UserData = p;
callback_plotclassifications([],[],h);
%**************************************************************************
function callback_loadnewfile(hObject, eventdata, h)


%check to see if we need to save data from another figure before saving and loading
%in this figure.  There is no need to use the needsReload flag from the
%function since we are loading anyway here.
study_checkForUnsavedData(h.figure);

%load the general data    
p = h.figure.UserData;

%get the current participant number and filename
snum = h.dropdown_selsubject.Value;
fnames = h.dropdown_selsubject.UserData;
filename = fnames{snum};

%make sure something was passed
if isempty(filename)
    uialert(h.figure, 'No data to load and plot!');
    return
end

%make sure it is a file that exists
if exist(filename, 'file') ~= 2
    uialert(h.figure, 'The selected file does not seem to exist.  Please double check the file location.');
    return
end


%check to see if the currently displayed file needs saving
saveflag = false;
if isfield(p, 'EEG')
    fprintf('checking old eeg file for changes...')
    if contains(p.EEG.saved, 'no')
        fprintf('changes detected, saving current file\n');
        if ~isempty(eventdata)   
            old_snum = eventdata.PreviousValue;
            saveflag = true;
        else
            fprintf('whoops - cannot determine which file to save')
        end
    end
end

%save the current file if needed and load the new one too.
pb = uiprogressdlg(h.figure, 'Message', '', 'Title', 'Switching participants', 'Indeterminate', 'on');
if saveflag
    pb.Message = 'Saving current subject file.';
    oldfilename = fnames{old_snum};
    EEG = p.EEG;
    wwu_SaveEEGFile(EEG,oldfilename)
end

pb.Message = 'Loading new subject file';

%load the data
[path, name, ext] = fileparts(filename);
EEG = wwu_LoadEEGFile(filename);


%make sure there are components
if ~isfield(EEG, "icasphere") || isempty(EEG.icasphere)
    uialert(h.figure, 'No ICA components found','Load Error');
    return
end

%make sure the classification has been completed
if ~isfield(EEG.etc, 'ic_classification')
    uialert(h.figure, 'No ICA classification has been completed','Load Error');
    return
end    
p.EEG = EEG;
p.EEG.saved = 'yes';
h.figure.UserData = p;

h.spinner_selcomp.Limits = [1, size(EEG.icaweights,1)];
callback_plotclassifications([],[],h)

%*************************************************************************
function callback_plotICtopo(hObject, event, h, p)
%plot the topo and any other information that changes as a function of
%selecting a new ica
%get the new ica
ic_number = h.spinner_selcomp.Value;
ic = p.EEG.icawinv(:,ic_number);
curr_thresh = h.spinner_threshold.Value/100;

cla(h.axis_icatopo);
wwu_topoplot(ic,  p.EEG.chanlocs, 'axishandle', h.axis_icatopo);
cb = colorbar(h.axis_icatopo);
cb.Color = p.scheme.Axis.AxisColor.Value;

%if this is epcohed data
%need to edit this to allow for non epoched data as well
if p.EEG.trials > 1
    %get the ICA data without the bad trials
    btrials = ~study_GetBadTrials(p.EEG);
    icaact = squeeze(p.EEG.icaact(ic_number,:,:));
    icaact(:,~btrials) = 0;
    
    %compute the mean of the ica time series for display
    icamean = mean(icaact(:,btrials),2);
    %compute the 2 sided fft
    Y = fft(icaact(:,btrials));
    fftlength = size(icaact,1);
    ffthalf = round(fftlength/2 + 1);
    %compute the 2 sided power
    Y = abs(Y./fftlength).^2;
    %convert to one sided
    icafft = Y(1:ffthalf,:);
    icafft(2:end-1,:) = 2*icafft(2:end-1,:);
    %average across trial
    icafft = mean(icafft,2);
    
    %create an axis for the erp plot and for the  fft plot
    yaxis = 1:p.EEG.trials;
    yaxis = yaxis(btrials);
    faxis = p.EEG.srate * (0:(ffthalf-1))/fftlength; 
    
    %smooth the ica erp plot
    f = ones(10);
    icaact = conv2(icaact, f, 'same');
    mn = min(min(icaact)); mx = max(max(icaact));
    scale = max([abs(mn), mx]);
    cla(h.axis_icaerp);
    h.axis_icaerp.YTickMode = 'auto';
    
    im = imagesc('Parent', h.axis_icaerp, 'XData', [p.EEG.times(1), p.EEG.times(end)],'CData', icaact', [-scale, scale]);
    im.ButtonDownFcn = {@callback_gettrialfromerpimage, h};
    h.axis_icaerp.YLabel.String = 'Trials';
    h.axis_icaerp.YGrid = 'on';
    h.axis_icaerp.GridColor = [.4,.4,.4];
    h.axis_icaerp.XGrid = 'off';
    h.axis_icaerp.Layer = 'top';
    h.axis_icaerp.YDir = 'normal';
    h.axis_icaerp.XLim = [p.EEG.times(1), p.EEG.times(end)];
    h.axis_icaerp.YLim = [1,length(yaxis)];
    mytitle = sprintf('Component %i', ic_number);
    if p.EEG.reject.gcompreject(ic_number)
        mytitle = [mytitle, ' BAD'];
        h.axis_icaerp.Title.Color = p.badtrialcolor;
    else
        mytitle = [mytitle, ' GOOD'];
        h.axis_icaerp.Title.Color = p.goodtrialcolor;
    end
    h.axis_icaerp.Title.String = mytitle;
    cb = colorbar(h.axis_icaerp);
    cb.Color = p.scheme.Axis.AxisColor.Value;
    
    %plot the mean of the ica in the time domain
    scale(1) = floor(min(icamean) * 10)/10;
    scale(2) = ceil(max(icamean) * 10)/10;
    if scale(1) > 0; scale(1) = -.1; end
    if scale(2) < 0; scale(2) = .1; end
    mp = plot(h.axis_icamean, p.EEG.times, icamean);
    h.axis_icamean.YLim = scale; 
    h.axis_icamean.XLim = [p.EEG.times(1), p.EEG.times(end)];
    h.axis_icamean.XLabel.String = 'Time (ms)';
    h.axis_icamean.YLabel.String = 'Amplitude (mV)';
    h.axis_icamean.InnerPosition([1,3]) = h.axis_icaerp.InnerPosition([1,3]);
    h.axis_icamean.Position(2) = 10;
    h.axis_icamean.Box = 'off';
    mp.LineWidth = 2;
    line(h.axis_icamean, [0,0], scale, 'Color', p.scheme.Axis.AxisColor.Value)
    line(h.axis_icamean, p.EEG.times, zeros(size(p.EEG.times)), 'Color', p.scheme.Axis.AxisColor.Value)
    
    %plot the fft of the ica time series
    mp = plot(h.axis_icafft, faxis, icafft);
    mp.LineWidth = 2;
    h.axis_icafft.XLim = [0,40];
    h.axis_icafft.XLabel.String = 'Frequency (Hz)';
    h.axis_icafft.YLabel.String = 'Log Power (mV/freq)';
    h.axis_icafft.YScale = 'log';
    h.axis_icafft.Box = 'off';
end

%plot the classification for the selected component
pbar_data = p.EEG.etc.ic_classification.ICLabel.classifications(ic_number,:);
for ii = 1:length(pbar_data)
    b = bar(h.axis_compbar, ii, pbar_data(ii));
    b.FaceColor = p.mycolmap(ii+1,:);
    if ii == 1; hold(h.axis_compbar, 'on'); end
end
hold(h.axis_compbar, 'off');

h.axis_compbar.YLim = [0,1];
h.axis_compbar.XTick = 1:length(pbar_data);
h.axis_compbar.XTickLabel =p.EEG.etc.ic_classification.ICLabel.classes;
h.axis_compbar.Color = p.scheme.Window.BackgroundColor.Value;

%get the classification
[v, c] = max(pbar_data);
if v < curr_thresh
    classname = 'none';
else
    classname = sprintf('%s (%i%%)',...
        p.EEG.etc.ic_classification.ICLabel.classes{c},...
        round(v*100));
end
h.axis_compbar.Title.String = classname; 
h.axis_compbar.Title.Color = p.scheme.Axis.AxisColor.Value;
h.axis_compbar.YLabel.String = 'Weight';
h.axis_compbar.YLabel.Color = p.scheme.Axis.AxisColor.Value;
lh = legend(h.axis_compbar);
lh.String = p.EEG.etc.ic_classification.ICLabel.classes;
lh.TextColor = p.scheme.Label.FontColor.Value;
lh.Location = 'northoutside';
lh.NumColumns = 7;
lh.Box = 'off';

drawnow;

line(h.axis_compbar, h.axis_compbar.XLim, [curr_thresh, curr_thresh], ...
    'LineStyle', '--', 'Color',  p.scheme.Axis.AxisColor.Value);
lh.String(end) = {'threshold'};

%*************************************************************************
function callback_handlemouseevents(hObject, event, h)

rp = h.axis_compclassraw.CurrentPoint;
thp = h.axis_compclassthresh.CurrentPoint;
xlm = h.axis_compclassraw.XLim;
ylm = h.axis_compclassraw.YLim;

rp = round(rp(1,1:2));
thp = round(thp(1,1:2));

%make sure the mouse click was in the figure
%the xvalues will be the same so I only have to deal with one
if rp(1) < xlm(1) || rp(1) > xlm(2)
    return
end

%now deal with the y range which must in wihtin hte limits for at least one
%figure.  I am not sure what I will do with this position yet, but I might
%as well get it
if rp(2) > ylm(1) && rp(2) < ylm(2)
    class = rp(2);
    comp = rp(1);
elseif thp(2) > .5 && thp(2) < 1.5
    comp = h.axis_compclassthresh.UserData(thp(1));
else
    return %not inslude the range of either axis
end

h.spinner_selcomp.Value = comp;
callback_plotclassifications([],[],h);


%************************************************************************
function callback_plotclassifications(hObject, event, h)

h.figure.Pointer = 'watch';
drawnow
needsReload = study_checkForUnsavedData(h.figure);
if needsReload
    callback_loadnewfile(hObject, event, h);
    %jump out since the load file callback will call the plotting routine
    %anyway
    return
end

p = h.figure.UserData;
w = p.EEG.etc.ic_classification.ICLabel.classifications;
l = p.EEG.etc.ic_classification.ICLabel.classes;
nclasses = length(l);
curr_ic = h.spinner_selcomp.Value;

%plot the raw values
imagesc(h.axis_compclassraw, w', [0,1])
h.axis_compclassraw.XLim = [.5,size(w,1)+.5];
h.axis_compclassraw.YLim = [.5,size(w,2)+.5];
h.axis_compclassraw.YTickLabel = l;
h.axis_compclassraw.Title.String = 'IC Classifications Weights';
h.axis_compclassraw.Title.Color = p.scheme.Axis.AxisColor.Value;
cb = colorbar(h.axis_compclassraw);
cb.Ticks = 0:.1:1;
lv =  num2cell(0:10:100);
cb.TickLabels = cellfun(@(x) sprintf('%i%%', x), lv,'UniformOutput', false);
cb.Color = p.scheme.Label.FontColor.Value;

colormap(h.axis_compclassraw, 'winter');

%get the user defined threshold
threshold = h.spinner_threshold.Value/100;
[thresh_w, ic_indx] = wwu_getICclass(w, threshold);

%plot the thresholded values
imagesc(h.axis_compclassthresh, thresh_w',[0, nclasses] );
h.axis_compclassthresh.XLim = [.5,size(thresh_w,1)+.5];
h.axis_compclassthresh.YLim = [.5,size(thresh_w,2)+.5];
h.axis_compclassthresh.YTick = 1;
h.axis_compclassthresh.YTickLabel = {'Classifications'};
h.axis_compclassthresh.XTick = [];
h.axis_compclassthresh.Box = 'on';
h.axis_compclassthresh.UserData = ic_indx;
h.axis_compclassthresh.Title.String = 'IC sorted by classification';
h.axis_compclassthresh.Title.Color = p.scheme.Axis.AxisColor.Value;

for ii = 2:size(thresh_w,1)
    ml = line(h.axis_compclassraw, [ii - .5, ii-.5], h.axis_compclassraw.YLim, 'Color', [.5,.5,.5]);
    if ii == curr_ic || ii == curr_ic + 1
        ml.Color = 'w';
        ml.LineWidth = 2;
    end
    ml = line(h.axis_compclassthresh, [ii-.5,ii-.5], h.axis_compclassthresh.YLim, 'Color', [.5,.5,.5]);
    if ic_indx(ii) == curr_ic || ic_indx(ii-1) == curr_ic
        ml.Color = 'w';
        ml.LineWidth = 2;
    end
end
colormap(h.axis_compclassthresh, p.mycolmap(1:nclasses+1,:));
callback_plotICtopo([],[],h, p);

h.figure.Pointer = 'arrow';
%*************************************************************************
function callback_rejectic(hObject, event, h)

p = h.figure.UserData;
save_changes(p.EEG);

fnames = h.dropdown_selsubject.UserData;
threshold = h.spinner_threshold.Value/100;

fh = study_RejectIC(fnames, threshold);
waitfor(fh);
callback_loadnewfile([],[],h);

%*************************************************************************
function callback_myclosefcn(hObject, event, h)

p = h.figure.UserData;

if isfield(p, 'EEG')
    save_changes(p.EEG, h);
end
delete(h.figure)

%**************************************************************************
function save_changes(EEG, h)

if strcmp(EEG.saved, 'no')
    pb = uiprogressdlg(h.figure, 'Message', 'Saving changes before changing windows status ...','Indeterminate','on');
    snum = h.dropdown_selsubject.Value;
    fnames = h.dropdown_selsubject.UserData;
    filename = fnames{snum};
    fprintf('saving changes...');
    wwu_SaveEEGFile(EEG, filename);
    fprintf('done\n');
    close(pb);
end
function callback_gettrialfromerpimage(src, event, h)
    fprintf('trial #%i', round(src.Parent.CurrentPoint(1,2)));
