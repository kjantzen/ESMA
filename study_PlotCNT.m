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

% Update 5/13/20 KJ Jantzen
function study_PlotCNT(study, filenames)

%build the figure

p = plot_params;


W = round(p.screenwidth * .8); H = round(p.screenheight * .6);
figpos = [(p.screenwidth - W)/2, (p.screenheight - H)/2, W, H];


handles.figure = uifigure(...
    'Color', p.backcolor,...
    'Position', figpos,...
    'NumberTitle', p.numbertitle, ...
    'Toolbar', 'none');

handles.axis_main = uiaxes(...
    'Parent', handles.figure,...
    'Units', 'Pixels',...
    'Position', [50,50,W-60,H-100],...
    'Interactions', []);

handles.panel_chpanel = uipanel(...
    'Parent', handles.figure,...
    'Position', [300, H-35, 230, 35],...
    'Title', '');

handles.axis_main.Toolbar.Visible = 'off';

temp = handles.axis_main.InnerPosition;

handles.slider_datascroll = uislider(...
    'Parent', handles.figure,...
    'Position', [temp(1),20,temp(3),3],...
    'Limits', [0,100],...
    'MajorTicks', [],...
    'MinorTicks', []);

handles.panel_subjpanel = uipanel(...
    'Parent', handles.figure,...
    'Position', [temp(1), H-35, 230, 35],...
    'Title', '');

handles.dropdown_subjselect = uidropdown(...
    'Parent', handles.panel_subjpanel,...
    'Position', [10, 5, 100, 25]);

handles.label_subjectstatus = uilabel(...,
    'Parent', handles.panel_subjpanel,...
    'Position', [120, 5, 100, 25], ...
    'FontColor', 'w',...
    'HorizontalAlignment', 'center');

handles.spinner_changescale = uispinner(...
    'Parent', handles.figure,...
    'Position', [temp(1) + temp(3) - 100, H-25, 100, 20],...
    'Limits', [1, inf],...
    'RoundFractionalvalues', 'on', ...
    'ValueDisplayFormat', '%i mV');

handles.spinner_changepwidth = uispinner(...
    'Parent', handles.figure,...
    'Position', [temp(1) + temp(3) - 210, H-25, 100, 20],...
    'Limits', [1, 20],...
    'RoundFractionalvalues', 'on', ...
    'ValueDisplayFormat', '%i sec');
handles.menu_file = uimenu('Parent', handles.figure, 'Text', 'File');
handles.menu_trim = uimenu('Parent', handles.menu_file, 'Text', 'Trim file to first and last markers');
handles.menu_channel = uimenu('Parent', handles.figure, 'Text', 'Channels');
handles.menu_badchan = uimenu('Parent', handles.menu_channel,...
    'Text',"Set selected to bad channels ");
handles.menu_goodchan = uimenu('Parent', handles.menu_channel,...
    'Text',"Set selected to good channels ");
handles.menu_clearchan = uimenu('Parent', handles.menu_channel,...
    'Text','Clear selections', 'Separator','on');
clear temp

handles.slider_datascroll.ValueChangingFcn = {@callback_drawdata, handles};
handles.spinner_changescale.ValueChangedFcn = {@callback_changescale, handles};
handles.spinner_changepwidth.ValueChangedFcn = {@callback_changepwidth, handles};
handles.dropdown_subjselect.ValueChangedFcn = {@callback_loadnewfile, study, handles};
handles.figure.ButtonDownFcn = {@callback_selectchannel, handles};
handles.menu_badchan.MenuSelectedFcn = {@callback_markchannels, handles, 'bad'};
handles.menu_goodchan.MenuSelectedFcn = {@callback_markchannels, handles, 'good'};
handles.menu_clearchan.MenuSelectedFcn = {@callback_deselectchans, handles};
handles.menu_trim.MenuSelectedFcn = {@callback_trim, study,handles};

%do a more sophisticated check later to make sure this information matches
handles.dropdown_subjselect.Items   = {study.subject.ID};
handles.dropdown_subjselect.ItemsData = 1:length(study.subject);
handles.dropdown_subjselect.UserData = filenames;

callback_loadnewfile([], [], study, handles)


function callback_deselectchans(hObject, eventdata, h)

p = h.figure.UserData;
p.selchans = zeros(1,p.EEG.nbchan);
h.figure.UserData = p;

callback_drawdata([],[],h);
%*************************************************************************
function callback_trim(~,~,study,h)
%trims empty space from the beginning and end of a continouous file.
p = h.figure.UserData;
%get the time of the first marker
%it should just be the first one, but lets not take that chance
[pstart, indxstart] = min([p.EEG.event.latency]);
[pend, indxend] = max([p.EEG.event.latency]);

%set the trim boundaries to 5 seconds before the first marker
pstart = pstart-(p.EEG.srate * 5);
if pstart < 1
    pstart = 1;
    msg = '';
else
    msg = sprintf('%i points (%3.2f s) will be trimmed from the the start of the file\n',...
        pstart, pstart/p.EEG.srate);
end
pend = pend + (p.EEG.srate * 10);
if pend > p.EEG.pnts
    pend = p.EEG.pnts;
else
    msg = [msg, sprintf('%i points (%3.2f s) will be trimmed from the the end of the file\n',...
        p.EEG.pnts-pend, (p.EEG.pnts-pend)/p.EEG.srate);];
end
msg = [msg, 'This step will overwrite the current file and cannot be undone!'];

if pstart==1 && pend == p.EEG.pnts
    uialert(h.figure,'These data appear to have been trimmed or do not require trimming!', 'Data Trim');
else
    choice = uiconfirm(h.figure, msg, 'Confirm Trim');
    if contains(choice, 'OK')
        p.EEG = pop_select(p.EEG, 'point',[pstart, pend]);
        p.EEG.saved = 'no';
        p.EEG = wwu_SaveEEGFile(p.EEG);
        h.figure.UserData = p;
        callback_loadnewfile([],[],study,h);
    end
end
%*************************************************************************
function callback_markchannels(hObject, eventdata, h, status)

p = h.figure.UserData;
if sum(p.selchans)==0
    uialert('No channels have been selected.', 'Mark Channels');
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
function callback_selectchannel(hobject, eventdata,h, ch_num)

    p = h.figure.UserData;
    p.selchans(ch_num) = ~p.selchans(ch_num);
    
    h.figure.UserData = p;
    
    callback_drawdata([],[],h);
    
%*************************************************************************    
function callback_loadnewfile(hObject, eventdata, study, h)

p = h.figure.UserData;
pp = plot_params;

if isfield(p, 'EEG')
     if strcmp(p.EEG.saved, 'no')
         msg = sprintf('Saving changes to %s', p.EEG.filename);
         pb = uiprogressdlg(h.figure,'Indeterminate','on', 'Message',msg);
         p.EEG = wwu_SaveEEGFile(p.EEG);
         close(pb);
     end
end
pb = uiprogressdlg(h.figure, 'Indeterminate','on', 'Message', 'Loading new subject...');
drawnow;
snum = h.dropdown_subjselect.Value;
fnames = h.dropdown_subjselect.UserData;
filename = fnames{snum};

h.label_subjectstatus.Text = study.subject(snum).status;
if contains(study.subject(snum).status, 'good')
    h.label_subjectstatus.BackgroundColor = pp.goodsubjectcolor;
else    
    h.label_subjectstatus.BackgroundColor = pp.badsubjectcolor;
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
    class(plot.scale) 
    plot.scale = double(plot.scale);
    
    fprintf('\n%f\n', plot.scale);
    h.spinner_changescale.Value = plot.scale;

end

%initialize the selected channels
plot.selchans = zeros(1,EEG.nbchan);


plot.EEG = EEG;
h.figure.UserData = plot;

%reset the slider
h.slider_datascroll.Limits = [1, EEG.pnts - plot.pwidth];
h.slider_datascroll.Value = 1;
callback_drawdata([],[],h);
close(pb);
%*************************************************************************
function callback_drawdata(hObject, eventdata, h)

%get some plotting information
p = h.figure.UserData;

%get the plotting position from the slider
if ~isempty(eventdata)
    startpos = round(eventdata.Value);
else
    startpos = round(h.slider_datascroll.Value);
end

%grab the data to plot
endpos = startpos + p.pwidth-1;
d = p.EEG.data(:,startpos:endpos);
t = p.EEG.times(startpos:endpos)./1000;

if isfield(p.EEG.chaninfo,'badchans')
    badchans = p.EEG.chaninfo.badchans;
else
    badchans = zeros(1,p.EEG.nbchan);
end

%scale it so that that channels are not stacked
scalefac = (0:1:p.EEG.nbchan-1) * p.scale;
scalefacarray = repmat(scalefac', 1, p.pwidth);
d = d + scalefacarray;

ph = plot(h.axis_main, t,d, 'Color', 'b');

for ii = 1:length(ph)
    ph(ii).ButtonDownFcn = {@callback_selectchannel, h, ii};
    ph(ii).LineWidth = (p.selchans(ii) * 2) + .5;
    if p.selchans(ii) 
        ph(ii).Color = 'k';
    end
    if badchans(ii)
        ph(ii).Color = 'r';
    end
    
end

h.axis_main.YTick = scalefac;
h.axis_main.YTickLabel = {p.EEG.chanlocs.labels};

xlims = [t(1), t(end)]; ylims = [scalefac(1) - p.scale, scalefac(end) + p.scale];
h.axis_main.XLim = xlims;
h.axis_main.YLim = ylims;
h.axis_main.YDir = 'reverse';
h.axis_main.XGrid = 'on';
h.axis_main.YGrid = 'on';
h.axis_main.GridColor = [.25,.25,.25];
h.axis_main.GridAlpha = .5;
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
        line(h.axis_main, [evt_time, evt_time], [ylims(1)+p.scale, ylims(2)], 'Color',[.2,.5,.2], 'LineWidth', 1.5);
        text(h.axis_main, evt_time, ylims(1), evt_label, ...
            'Color', [.2, .5,.2], 'HorizontalAlignment', 'center',...
            'Interpreter','none');
    end
end
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

h.slider_datascroll.Limits = [1, plot.EEG.pnts - plot.pwidth];
callback_drawdata([], [], h);








 
