%study_plotCNT() - GUI for plotting continuous EEG files.  Currently the
%                   function of this tool is limited to scrolling unepoched
%                   EEG data, selecting the data from participants within 
%                   a study, and selecting & interploating bad channels.
%                   Functions will be added over time as needed.
%
%Usage:
%>> study_plotCNT(study, filenames);
%
%Required Inputs:
%   study       -   an hcnd STUDY structure passed from the hcnd_eeg main 
%                   interface or from the command line. 
%
%   filenames   -   a cell array of filenames to review.  The routine
%                   automatically assumes one filename for each participant 
%                   listed in the study structure.

%TODO list
%   
% Update 5/11/23 KJ Jantzen
function study_PlotCNT(study, filenames)

try
    %build the figure
    handles = build_gui();
    handles = setCallbacks(handles, study);
    handles = initializeControls(handles, study, filenames);
    callback_loadnewfile([], [], study, handles);
catch me
    if exist('handles', 'var') && ~isempty(handles)
        close(handles.figure);
    end
    rethrow(me);
end
% ***********************************************************************
function callback_deselectchans(hObject, eventdata, h)

p = h.figure.UserData;
p.selchans = zeros(1,p.EEG.nbchan);
h.figure.UserData = p;

callback_drawdata([],[],h);

%*************************************************************************
function callback_markchannels(hObject, eventdata, h, status)

p = h.figure.UserData;
if sum(p.selchans)==0
    uialert(h.figure, 'No channels have been selected.', 'Mark Channels');
    return
end

if ~isfield(p.EEG.chaninfo, 'badchans') || isempty(p.EEG.chaninfo.badchans)
    p.EEG.chaninfo.badchans = zeros(1,p.EEG.nbchan);
end

if contains(status, 'good')
    p.EEG.chaninfo.badchans(find(p.selchans)) = 0;
   
%ask the user what to do if bad channels already exist
else
    if sum(p.EEG.chaninfo.badchans)>0
        choice = uiconfirm(h.figure,'What do you want to do with the existing bad channels?',...
            'Bad Channels','Options',{'Overwrite', 'Combine', 'Cancel'},...
            'DefaultOption',2,'CancelOption',3);
        switch choice
            case 'Overwrite'
                p.EEG.chaninfo.badchans = p.selchans;
            case 'Combine'
                p.EEG.chaninfo.badchans = p.EEG.chaninfo.badchans | p.selchans;
            otherwise
                return
        end
    else
        p.EEG.chaninfo.badchans = p.selchans;
    end
end
pb = uiprogressdlg(h.figure,'Indeterminate','on', 'Message','Saving channel status');
p.EEG = wwu_SaveEEGFile(p.EEG,[],{'chaninfo'});
close(pb);

h.figure.UserData = p;
callback_drawdata([], [],h)

%**************************************************************************
function callback_selectchannel(hObject, ~,h, ch_num)


    selectedChannelColor = opponentColor(h.scheme.Axis.BackgroundColor.Value);

    %make sure the shift key is not pressed because that enables a
    %different function used to select segments

    if ~any(strcmp(h.figure.CurrentModifier, 'shift'))
        p = h.figure.UserData;
        p.selchans(ch_num) = ~p.selchans(ch_num);
        h.figure.UserData = p;  

        badchans = getBadChans(p.EEG);
        if p.selchans(ch_num) 
            hObject.Color = selectedChannelColor;
            hObject.LineWidth = h.scheme.EEGTraces.Width.Value + 2;
        else
            hObject.Color = h.scheme.EEGTraces.GoodColor.Value;
            hObject.LineWidth  = h.scheme.EEGTraces.Width.Value;
        end
        if badchans(ch_num)
            hObject.Color = h.scheme.EEGTraces.BadColor.Value;
        end
    
        if strcmp(hObject.Tag, 'FFT_Channel')
           callback_drawdata([],[],h);
        end
    end
 
%*************************************************************************        
function local_close_request(hObject, eventdata, h)
    p = h.figure.UserData;
    if isfield(p, 'EEG')
        check_for_unsaved_changes(h.figure, p.EEG);
    end
    closereq;


%*************************************************************************        
function check_for_unsaved_changes(fh, EEG)
%save any unsaved changes in the file we are navigating away from 
if strcmp(EEG.saved, 'no')
     msg = sprintf('Saving changes to %s', EEG.filename);
     pb = uiprogressdlg(fh,'Indeterminate','on', 'Message',msg);
     p.EEG = wwu_SaveEEGFile(EEG);
     close(pb);
end

%*************************************************************************    
function callback_loadnewfile(hObject, eventdata, study, h)

p = h.figure.UserData;

if isfield(p, 'EEG')
    check_for_unsaved_changes(h.figure, p.EEG);
end
pb = uiprogressdlg(h.figure, 'Indeterminate','on', 'Message', 'Loading new subject...');
drawnow;
snum = h.dropdown_subjselect.Value;
fnames = h.dropdown_subjselect.UserData;
filename = fnames{snum};

h.label_subjectstatus.Text = study.subject(snum).status;
if contains(study.subject(snum).status, 'good')
    h.label_subjectstatus.BackgroundColor = h.scheme.GoodSubjectColor;
else    
    h.label_subjectstatus.BackgroundColor = h.scheme.BadSubjectColor;
end

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
EEG = wwu_LoadEEGFile(filename);

if EEG.trials > 1
    uialert(h.figure, 'The file may contain epoched data. Please use the trial viewer instead.');
    return
end
    
%initialize the plotting parameters
plot = h.figure.UserData;

if isempty(plot)
    plot.pwidth = EEG.srate * 10;
    h.spinner_changepwidth.Value = 10;

    plot.scale = max(range(EEG.data'))/10;
    plot.scale = double(plot.scale);
    
    fprintf('\n%f\n', plot.scale);
    h.spinner_changescale.Value = plot.scale;

end

%initialize the selected channels
plot.selchans = zeros(1,EEG.nbchan);

%store the data
plot.EEG = EEG;
h.figure.UserData = plot;

%reset the slider
h.slider_timescroll.Limits = [1, EEG.pnts - plot.pwidth];
h.slider_timescroll.Value = 1;
cchan = h.spinner_changechannum.Value;
if cchan > EEG.nbchan
    h.spinner_changechannum.Value = EEG.nbchan;
end
h.spinner_changechannum.Limits = [1. EEG.nbchan];
slider_max = EEG.nbchan - h.spinner_changechannum.Value+1;
if h.slider_channelscroll.Value > slider_max
    h.slider_channelscroll.Value = slider_max;
end
if slider_max == 1
    h.slider_channelscroll.Limits = [1,2 ];
    h.slider_channelscroll.Visible = 'off';
else
    h.slider_channelscroll.Limits = [1, slider_max];
    h.slider_channelscroll.Visible = 'on';
end
   
%draw it
callback_drawdata([],[],h);
close(pb);

%*************************************************************************
function callback_scrollPage(hObject, eventdata, h, direction)
    
    %get the current start position of the screen
    p = h.figure.UserData;
    cPoint = h.slider_timescroll.Value;

    %get the current width of the screen
    w = p.pwidth;

    %add or subject the width to the current start point
    cPoint = cPoint + (direction * w);

    %check for potential overrun of start or end of file
    if cPoint < h.slider_timescroll.Limits(1)
        cPoint = h.slider_timescroll.Limits(1);
    elseif cPoint > h.slider_timescroll.Limits(2) - w;
        cPoint = h.slider_timescroll.Limits(2) - w;
    end
        
    %assign the new position to the scroll bar and redraw the data
    h.slider_timescroll.Value = cPoint;
    callback_drawdata(hObject, eventdata, h);
    

%*************************************************************************
function badchans = getBadChans(EEG)
    if isfield(EEG.chaninfo,'badchans')
        badchans = EEG.chaninfo.badchans;
    else
        badchans = zeros(1,EEG.nbchan);
    end
%*************************************************************************
function callback_drawdata(hObject, eventdata, h)

%TO DO
%fix the selected channels vector so that it reflects all possible
%channels, not just those shown on the screen.

%get some plotting information
p = h.figure.UserData;
chans_to_plot = h.spinner_changechannum.Value;
EventMarkerColor = opponentColor(h.scheme.Axis.BackgroundColor.Value);
SelChannelColor = opponentColor(h.scheme.Axis.BackgroundColor.Value);

%get the plotting position from the slider
if ~isempty(eventdata)
    switch eventdata.Source.Tag 
        case 'TimeScroll'
            startpos = round(eventdata.Value);
            start_chan = p.EEG.nbchan - chans_to_plot + 1 - (round(h.slider_channelscroll.Value)-1);

        case 'ChannelScroll'
            startpos = round(h.slider_timescroll.Value);
            start_chan = p.EEG.nbchan - chans_to_plot + 1 - (round(eventdata.Value-1));
        otherwise
           startpos = round(h.slider_timescroll.Value);
           start_chan = p.EEG.nbchan - chans_to_plot + 1 - (round(h.slider_channelscroll.Value)-1);
    end
else
   startpos = round(h.slider_timescroll.Value);
   start_chan = p.EEG.nbchan - chans_to_plot + 1 - (round(h.slider_channelscroll.Value)-1);
end

end_chan = start_chan + chans_to_plot -1;

%grab the data to plot
endpos = startpos + p.pwidth-1;
d = p.EEG.data(start_chan:end_chan,startpos:endpos);
t = p.EEG.times(startpos:endpos)./1000;

badchans = getBadChans(p.EEG);

%scale it so that that channels are not stacked
scalefac = (0:1:chans_to_plot-1) * p.scale;
scalefacarray = repmat(scalefac', 1, p.pwidth);
d = d + scalefacarray;
xlims = [t(1), t(end)]; ylims = [scalefac(1) - p.scale, scalefac(end) + p.scale];

ph = plot(h.axis_main, t,d, 'Color', h.scheme.EEGTraces.GoodColor.Value, ...
    'LineWidth',h.scheme.EEGTraces.Width.Value);
for ii = 1:length(ph)
    chIndx = start_chan + ii-1;
    ph(ii).ButtonDownFcn = {@callback_selectchannel, h, chIndx};
    ph(ii).LineWidth = (p.selchans(chIndx) * 2) + h.scheme.EEGTraces.Width.Value;
    if p.selchans(chIndx) 
        ph(ii).Color = SelChannelColor;
    end
    if badchans(chIndx)
        ph(ii).Color = h.scheme.EEGTraces.BadColor.Value;
    end
    
end

h.axis_main.YTick = scalefac;
h.axis_main.YTickLabel = {p.EEG.chanlocs(start_chan:end_chan).labels};
h.axis_main.XLim = xlims;
h.axis_main.YLim = ylims;
h.axis_main.YDir = 'reverse';
h.axis_main.Layer = 'bottom';

%get event markers that lie within the plotting range
all_latencies = [p.EEG.event.latency];
evt_indx = find(all_latencies >= startpos & all_latencies <= endpos);

if ~isempty(evt_indx)
    for ii = evt_indx
        evt_time = p.EEG.times(int32(p.EEG.event(ii).latency))/1000;
        evt_label = p.EEG.event(ii).type;
        if isnumeric(evt_label)
            evt_label = num2str(evt_label);
        end
        line(h.axis_main, [evt_time, evt_time], [ylims(1)-p.scale, ylims(2)], 'Color',EventMarkerColor, 'LineWidth', 1.5);
        text(h.axis_main, evt_time, ylims(1)-p.scale, evt_label, ...
            'Color', EventMarkerColor, 'HorizontalAlignment', 'center',...
            'Interpreter','none','Rotation',90,...
            'VerticalAlignment','top')
    end
end
if isfield(p.EEG, 'SelectedRects')
    if ~isempty(p.EEG.SelectedRects)
        h.button_reject.Enable = 'on';
        for ii = 1:length(p.EEG.SelectedRects)
            mn = min(p.EEG.SelectedRects(ii).XData);
            mx = max(p.EEG.SelectedRects(ii).XData);
            if (mn > xlims(1) && mn < xlims(2)) || (mx > xlims(1) && mx < xlims(2)) || (mn < xlims(1) && mx > xlims(2))
                po = patch('Parent', h.axis_main,...
                    'XData', p.EEG.SelectedRects(ii).XData,...
                    'YData', [ylims(1), ylims(1), ylims(2), ylims(2)],...
                    'FaceColor', EventMarkerColor, ...
                    'LineStyle', 'none',...
                    'FaceAlpha', .35,...
                    'Tag', p.EEG.SelectedRects(ii).Tag);
                po.ButtonDownFcn = {@removeSelectedPatch, h};
                if mn < xlims(1)
                    lp = xlims(1);
                else
                    lp = mn;
                end
                text('Parent', h.axis_main,'Position',[lp, ylims(1)],...
                    'VerticalAlignment', 'bottom', 'HorizontalAlignment','left', ...
                    'String', sprintf('#%i (%3.2f - %3.2f sec)', ii, mn, mx),...
                    'Color', [1,0,0], 'FontSize',10, 'BackgroundColor',[1,1,1]);
            end
        end
    else
        h.button_reject.Enable = 'off';
    end
else
    h.button_reject.Enable = 'off';
end
%*************************************************************************
function callback_changechannnum(~, ~, h)
    
%get users input for how many channels to show
    chans_to_show = h.spinner_changechannum.Value;
%update the slider
    mx = h.spinner_changechannum.Limits;
    mx = mx(2);
    slider_mx = mx - chans_to_show + 1;
    if h.slider_channelscroll.Value > slider_mx
        h.slider_channelscroll.Value = slider_mx;
    end
    if slider_mx == 1
        h.slider_channelscroll.Limits = [1, 2];
        h.slider_channelscroll.Visible = 'off';
    else
        h.slider_channelscroll.Limits = [1, slider_mx];
        h.slider_channelscroll.Visible = 'on';
    end
    callback_drawdata([],[],h)

%*************************************************************************
function callback_changescale(hObject, eventdata, h)

plot = h.figure.UserData;
plot.scale = eventdata.Value;
h.figure.UserData = plot;

callback_drawdata(hObject, eventdata, h);
%**************************************************************************
function callback_changepwidth(hObject, eventdata, h)

plot = h.figure.UserData;
plot.pwidth = eventdata.Value * plot.EEG.srate;
h.figure.UserData = plot;

h.slider_timescroll.Limits = [1, plot.EEG.pnts - plot.pwidth];
callback_drawdata([], [], h);

%**************************************************************************
function callback_mouseeventhandler(hObject, event, h)

    persistent isdragging;
    persistent Xstart Xend;
    persistent r;

    if isempty(isdragging)
        isdragging = 0;
    end

    mousePos = hObject.CurrentPoint;
    shiftKey = any(strcmp(hObject.CurrentModifier, 'shift'));
    if (mouseIsInRegion(mousePos, h.axis_main.Position) && shiftKey) || isdragging
        
        h.figure.Pointer = "cross"; 

        tlimits = h.axis_main.XLim;

        switch event.EventName
            case 'WindowMousePress'
                isdragging = true;
                Xstart = h.axis_main.CurrentPoint;
                Xstart = Xstart(1);
                %create rectangular highlight
                r = gobjects(1,1);
            case 'WindowMouseRelease'
                if isdragging
                    isdragging = false;

                    %make sure the rect does not extend past the end of the
                    %visible data
                    r.XData(r.XData < tlimits(1)) = tlimits(1);
                    r.XData(r.XData > tlimits(2)) = tlimits(2);

                    %add the patch to the file so we have a record of what has
                    %been marked 
                    p = h.figure.UserData;
                    %add a callback to remove the patch if it is selected
                    %again in the future
                    r.ButtonDownFcn = {@removeSelectedPatch, h};
                   
                    %add the rect field if it does not exist
                    if ~isfield(p.EEG, 'SelectedRects')
                        r.Tag = num2str(1);
                        p.EEG.SelectedRects(1).XData = r.XData;
                        p.EEG.SelectedRects(1).Tag = r.Tag;
                    else
                        r.Tag = num2str(length(p.EEG.SelectedRects) + 1);
                        p.EEG.SelectedRects(end+1).XData = r.XData;
                        p.EEG.SelectedRects(end).Tag = r.Tag;
                    end
                    p.EEG.saved = 'no';
                    p.SelectedRect = str2double(r.Tag);
                    h.figure.UserData = p;
                    h.figure.Pointer = 'arrow';
                    h.button_reject.Enable = 'on';
                    callback_drawdata([],[],h);

                end

            case 'WindowMouseMotion'
                if isdragging
                    Xend = h.axis_main.CurrentPoint;
                    Xend = Xend(1);
                    %need a check here to see if the patch is extending
                    %beyond the end of the visible window.
  
                    y = h.axis_main.YLim;       
                    %if there is a blank patch we should create the patch
                    %for the first time
                    if contains(class(r), 'Placeholder')
                        %change to patch so it can be transparent
                        r = patch('Parent',h.axis_main,...
                            'XData', [Xstart, Xend, Xend, Xstart],...
                            'YData', [y(1), y(1), y(2), y(2)],...
                            'FaceColor',opponentColor(h.scheme.Axis.BackgroundColor.Value),...
                            'FaceAlpha', .4,...
                            'LineStyle', 'none');
                    opponentColor(h.scheme.Axis.BackgroundColor.Value)
                    h.scheme.Axis.BackgroundColor.Value

                    else
                        r.XData = [Xstart, Xend, Xend, Xstart];
                    end
                end
        end
    end
% ***********************************************************************
function removeSelectedPatch(hObject, ~,h)
    p = h.figure.UserData;
    if isfield(p.EEG, 'SelectedRects')
        for ii = 1:length(p.EEG.SelectedRects)
            if strcmp(hObject.Tag, p.EEG.SelectedRects(ii).Tag)
                p.EEG.SelectedRects(ii) = [];
                break
            end
        end
    end
    if isempty(p.EEG.SelectedRects)
        h.button_reject.Enable = 'off';
    end

    h.figure.UserData = p;
    callback_drawdata(hObject, [], h);
%**************************************************************************
function callback_removeSelectedData(~,~,h)
    p = h.figure.UserData;

    msg = 'This will remove highlighted data segments from this participant and overwrite the existing data.';
    msg = sprintf('%s\n\nTo remove segments from all participants without overwriting use the Preprocess->Remove bad segments menu option in the main window.',msg);
    response = uiconfirm(h.figure, msg, 'Remove highlights data segments', 'Options',{'Continue', 'Cancel'}, 'CancelOption',2,'DefaultOption',2);
    if strcmp(response, 'Continue')
        %collect all the data segments
        rmTimes = [p.EEG.SelectedRects.XData];
        rmTimes = sort(rmTimes(1:2,:))';
        
        %check for overlapping boundaries
%        rmTimes = checkForOverlap(rmTimes);
        p.EEG = pop_select(p.EEG,'rmtime',rmTimes);
        p.EEG.save = 'no';
        p.EEG.SelectedRects = [];
        h.figure.UserData = p;
        h.slider_timescroll.Limits = [1, p.EEG.pnts - p.pwidth];
        
        callback_drawdata([],[],h);
    end
%************************************************************************** 
function callback_moveToSelectedRect(hObject, event, h, direction)

    p = h.figure.UserData;
    if isfield(p.EEG, 'SelectedRects') && ~isempty(p.EEG.SelectedRects)
        nRects = length(p.EEG.SelectedRects);
        if isfield(p, 'SelectedRect')
            if p.SelectedRect > nRects
                p.SelectedRect = nRects;
            else
                newRect = p.SelectedRect + direction;
                if newRect < 1
                    newRect = 1;
                elseif newRect > nRects
                     newRect = nRects;
                end
                p.SelectedRect = newRect;
            end
        else
            p.SelectedRect = 1;
        end
        xData = p.EEG.SelectedRects(p.SelectedRect).XData;
        h.slider_timescroll.Value = min(xData) * p.EEG.srate;
        h.figure.UserData = p;
        callback_drawdata([],[],h);
    else
        fprintf('No selected regions found.\n')
    end
%**************************************************************************
function callback_clearAllRects(~,~,h)
    p = h.figure.UserData;
    p.EEG.SelectedRects = [];
    h.figure.UserData = p;
    callback_drawdata([],[],h);

%**************************************************************************
function result = mouseIsInRegion(mousePos, region)
    mouseX = mousePos(1);
    mouseY = mousePos(2);

    result= mouseX> region(1) && mouseX < (region(1)+ region(3)) ...
            && mouseY > region(2) && mouseY < (region(2) + region(4));
%**************************************************************************
function callback_makefreqplot(~,~,h)

    p = h.figure.UserData;

    pb = uiprogressdlg(h.figure, 'Message', 'Computing FFT for all channels', 'Title', 'Computing FFT', 'Indeterminate', 'on');
    
    [s, f] = spectopo(p.EEG.data, 0, p.EEG.srate, 'plot', 'off', 'winsize', p.EEG.srate * 2);
    fig = uifigure;
    fig.Name = p.EEG.setname;
    fig.NumberTitle = 'off';
    g = uigridlayout(fig, [1,1]);
    g.BackgroundColor =  h.scheme.Window.BackgroundColor.Value;
    
    a = uiaxes(...
    'Parent', g,...
    'Units', 'Pixels',...
    'Interactions', [],...
    'Color', h.scheme.Axis.BackgroundColor.Value,...
    'XColor',h.scheme.Axis.AxisColor.Value,...        
    'YColor',h.scheme.Axis.AxisColor.Value,...
    'FontName', h.scheme.Axis.Font.Value,...
    'FontSize', h.scheme.Axis.FontSize.Value,...
    'GridLineStyle','-',...
    'XGrid','on','YGrid','on');

    a.XLabel.String = 'Frequency';
    a.YLabel.String = 'Spectral power (dB)';

    badchans = getBadChans(p.EEG);

    ph = plot(a, f,s', 'Color', h.scheme.EEGTraces.GoodColor.Value);
    for ii = 1:length(ph)
        ph(ii).ButtonDownFcn = {@callback_selectchannel, h, ii};
        ph(ii).Tag = 'FFT_Channel';
        if p.selchans(ii) 
            ph(ii).Color = 'c';
        end
        if badchans(ii)
            ph(ii).Color = h.scheme.EEGTraces.BadColor.Value;
        end
        
    end
    pb.Message = 'Close the FFT figure to return to the Continuous Data Plot Tool.';
    a.XLim = [0, 100];
    drawnow;
    uiwait(fig);
    close(pb)

%**************************************************************************    
function rgbOut = opponentColor(rgbIn)
    hsvIn = rgb2hsv(rgbIn);   
    rgbOut = 1-rgbIn;
    %hsvIn = rem(hsvIn + .5, 1);
    %rgbOut = hsv2rgb(hsvIn);

%**************************************************************************
function handles = build_gui(study)

scheme = eeg_LoadScheme;
W = round(scheme.ScreenWidth * .8); H = round(scheme.ScreenHeight * .6);
figpos = [(scheme.ScreenWidth - W)/2, (scheme.ScreenHeight - H)/2, W, H];
handles.scheme = scheme;
handles.figure = uifigure(...
    'Color', scheme.Window.BackgroundColor.Value,...
    'Position', figpos,...
    'NumberTitle', 'off', ...
    'Toolbar', 'none');

handles.axis_main = uiaxes(...
    'Parent', handles.figure,...
    'Units', 'Pixels',...
    'Position', [50,50,W-100,H-100],...
    'Interactions', [],...
    'Color', scheme.Axis.BackgroundColor.Value,...
    'XColor',scheme.Axis.AxisColor.Value,...        
    'YColor',scheme.Axis.AxisColor.Value,...
    'FontName', scheme.Axis.Font.Value,...
    'FontSize', scheme.Axis.FontSize.Value,...
    'GridLineStyle','-',...
    'XGrid','on','YGrid','on');

handles.axis_main.Toolbar.Visible = 'off';
handles.axis_main.XLabel.String = 'Time (seconds)';
handles.axis_main.YLabel.String = 'Channel X Amplitude (uV)';

handles.panel_chpanel = uipanel(...
    'Parent', handles.figure,...
    'Position', [300, H-35, 230, 35],...
    'Title', '',...
    'BackgroundColor',scheme.Panel.BackgroundColor.Value,...
    'HighlightColor',scheme.Panel.BorderColor.Value,...
    'BorderType','none');

axis_pos = handles.axis_main.InnerPosition;
handles.slider_timescroll = uislider(...
    'Parent', handles.figure,...
    'Position', [axis_pos(1),20,axis_pos(3),3],...
    'Limits', [0,100],...
    'MajorTicks', [],...
    'MinorTicks', [],...
    'FontColor', scheme.Label.FontColor.Value,...
    'Tag', 'TimeScroll');

handles.slider_channelscroll = uislider(...
    'Parent', handles.figure,...
    'Position', [axis_pos(1)+axis_pos(3)+20,axis_pos(2), axis_pos(4),3],...
    'Limits', [1,64],...
    'MajorTicks', [],...
    'MinorTicks', [],...
    'FontColor', scheme.Label.FontColor.Value,...
    'Orientation','vertical',...
    'Tag', 'ChannelScroll');

handles.panel_subjpanel = uipanel(...
    'Parent', handles.figure,...
    'Position', [axis_pos(1), H-35, 230, 35],...
    'Title', '',...
    'BackgroundColor',scheme.Panel.BackgroundColor.Value,...
    'BorderType','none');

handles.dropdown_subjselect = uidropdown(...
    'Parent', handles.panel_subjpanel,...
    'Position', [10, 5, 100, 25],...
    'BackgroundColor',scheme.Dropdown.BackgroundColor.Value,...
    'FontColor', scheme.Dropdown.FontColor.Value,...
    'FontSize',scheme.Dropdown.FontSize.Value,...
    'FontName', scheme.Dropdown.Font.Value);

handles.label_subjectstatus = uilabel(...,
    'Parent', handles.panel_subjpanel,...
    'Position', [120, 5, 100, 25], ...
    'HorizontalAlignment', 'center',...
    'FontName', scheme.Label.Font.Value,...
    'FontColor', scheme.Label.FontColor.Value,...
    'FontSize', scheme.Label.FontSize.Value);

handles.button_prevpage = uibutton(...
    'Parent', handles.figure,...
    'Position', [330, H-32, 60, 27],...
    'BackgroundColor',scheme.Button.BackgroundColor.Value,...
    'FontName',scheme.Button.Font.Value,...
    'FontSize', scheme.Button.FontSize.Value,...
    'FontColor', scheme.Button.FontColor.Value,...
    'Text','<<',...
    'Tag', 'backward',...
    'Enable','on');

handles.button_nextpage = uibutton(...
    'Parent', handles.figure,...
    'Position', [400, H-32, 60, 27],...
    'BackgroundColor',scheme.Button.BackgroundColor.Value,...
    'FontName',scheme.Button.Font.Value,...
    'FontSize', scheme.Button.FontSize.Value,...
    'FontColor', scheme.Button.FontColor.Value,...
    'Text','>>',...
    'Tag', 'forward', ...
    'Enable','on');

handles.spinner_changescale = uispinner(...
    'Parent', handles.figure,...
    'Position', [axis_pos(1) + axis_pos(3) - 100, H-25, 100, 20],...
    'Limits', [1, inf],...
    'RoundFractionalvalues', 'on', ...
    'ValueDisplayFormat', '%i mV',...
    'BackgroundColor',scheme.Dropdown.BackgroundColor.Value,...
    'FontName',scheme.Dropdown.Font.Value,...
    'FontSize', scheme.Dropdown.FontSize.Value,...
    'FontColor',scheme.Dropdown.FontColor.Value);

handles.spinner_changepwidth = uispinner(...
    'Parent', handles.figure,...
    'Position', [axis_pos(1) + axis_pos(3) - 210, H-25, 100, 20],...
    'Limits', [1, inf],...
    'RoundFractionalvalues', 'on', ...
    'ValueDisplayFormat', '%i sec',...
    'BackgroundColor',scheme.Dropdown.BackgroundColor.Value,...
    'FontName',scheme.Dropdown.Font.Value,...
    'FontSize', scheme.Dropdown.FontSize.Value,...
    'FontColor',scheme.Dropdown.FontColor.Value);

handles.spinner_changechannum = uispinner(...
    'Parent', handles.figure,...
    'Position', [axis_pos(1) + axis_pos(3) - 320, H-25, 100, 20],...
    'Limits', [1, 64],...
    'Value', 64,...
    'RoundFractionalvalues', 'on', ...
    'ValueDisplayFormat', '%i channels',...
    'BackgroundColor',scheme.Dropdown.BackgroundColor.Value,...
    'FontName',scheme.Dropdown.Font.Value,...
    'FontSize', scheme.Dropdown.FontSize.Value,...
    'FontColor',scheme.Dropdown.FontColor.Value);

handles.button_reject = uibutton(...
    'Parent', handles.figure,...
    'Position', [axis_pos(1) + axis_pos(3) - 430, H-32, 100, 27],...
    'BackgroundColor',scheme.Button.BackgroundColor.Value,...
    'FontName',scheme.Button.Font.Value,...
    'FontSize', scheme.Button.FontSize.Value,...
    'FontColor', scheme.Button.FontColor.Value,...
    'Text','Reject',...
    'Enable','off');

%menu items
handles.menu_data = uimenu('Parent', handles.figure, 'Text', 'Data');
handles.menu_freq = uimenu('Parent', handles.menu_data, 'Text', 'Show frequency plot');

handles.menu_channel = uimenu('Parent', handles.figure, 'Text', 'Channels');
handles.menu_badchan = uimenu('Parent', handles.menu_channel,...
    'Text',"Set selected to bad channels ");
handles.menu_goodchan = uimenu('Parent', handles.menu_channel,...
    'Text',"Set selected to good channels ");
handles.menu_clearchan = uimenu('Parent', handles.menu_channel,...
    'Text','Clear selections', 'Separator','on');
handles.menu_segment = uimenu('Parent', handles.figure, 'Text','Selected Segments');
handles.menu_nextsegment = uimenu('Parent', handles.menu_segment, 'Text', 'Go to Next', 'Accelerator', 'N');
handles.menu_previoussegment = uimenu('Parent', handles.menu_segment, 'Text', 'Go to Previous', 'Accelerator', 'P');
handles.menu_clearsegment = uimenu('Parent', handles.menu_segment, 'Text', 'Clear all selections');


clear axis_pos

% ***********************************************************************
function handles = setCallbacks(handles, study)
handles.figure.CloseRequestFcn = {@local_close_request, handles};
handles.figure.WindowButtonDownFcn = {@callback_mouseeventhandler, handles};
handles.figure.WindowButtonMotionFcn = {@callback_mouseeventhandler, handles};
handles.figure.WindowButtonUpFcn = {@callback_mouseeventhandler, handles};
handles.slider_timescroll.ValueChangingFcn = {@callback_drawdata, handles};
handles.slider_channelscroll.ValueChangingFcn = {@callback_drawdata, handles};
handles.slider_channelscroll.ValueChangedFcn = {@callback_drawdata, handles};
handles.spinner_changescale.ValueChangedFcn = {@callback_changescale, handles};
handles.spinner_changepwidth.ValueChangedFcn = {@callback_changepwidth, handles};
handles.spinner_changechannum.ValueChangedFcn = {@callback_changechannnum, handles};
handles.dropdown_subjselect.ValueChangedFcn = {@callback_loadnewfile, study, handles};
handles.button_reject.ButtonPushedFcn = {@callback_removeSelectedData, handles};
handles.button_nextpage.ButtonPushedFcn = {@callback_scrollPage, handles, 1};
handles.button_prevpage.ButtonPushedFcn = {@callback_scrollPage, handles, -1};

handles.menu_freq.MenuSelectedFcn = {@callback_makefreqplot, handles};
handles.menu_badchan.MenuSelectedFcn = {@callback_markchannels, handles, 'bad'};
handles.menu_goodchan.MenuSelectedFcn = {@callback_markchannels, handles, 'good'};
handles.menu_clearchan.MenuSelectedFcn = {@callback_deselectchans, handles};
handles.menu_nextsegment.MenuSelectedFcn = {@callback_moveToSelectedRect, handles, 1};
handles.menu_previoussegment.MenuSelectedFcn = {@callback_moveToSelectedRect, handles, -1};
handles.menu_clearsegment.MenuSelectedFcn = {@callback_clearAllRects, handles};

% ************************************************************************
function handles = initializeControls(handles, study, filenames)
%do a more sophisticated check later to make sure this information matches
handles.dropdown_subjselect.Items   = {study.subject.ID};
handles.dropdown_subjselect.ItemsData = 1:length(study.subject);
handles.dropdown_subjselect.UserData = filenames;
[~, n, e] = fileparts(filenames{1});
handles.figure.Name = [n, e];
