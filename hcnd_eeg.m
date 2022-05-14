%hcnd_eeg() -   main user interface for the Human Cognition and Neural
%               Dyanmics EEG software suite.
%               This software acts as a custon wrapper for plotting and
%               analysing data with the EEGLAB set of tools.
%               Mass univariate statistics relies on the Mass Univariate
%               ERP Toolbox and the FMUT extension for multi way ANOVA.
%
%Installation
%       Download and Install thh following MATLAB toolboxes and add them to your path.
%
%           EEGLAB  -   https://sccn.ucsd.edu/eeglab/index.php
%           Mass Univariate Toolbox - written by Groppe, Urbach & Kutas can
%                       be found at https://openwetware.org/wiki/Mass_Univariate_ERP_Toolbox
%           FMUT    -   The factorial model extension of the Mass
%                       Univariate Toolbox written by Eric Fields can be downloaded
%                       from https://github.com/ericcfields/FMUT.
%            

% Update 6/15/20 KJ Jantzen
function hcnd_eeg()

fprintf('Starting hcnd_eeg ....\n');

EEGPath = study_GetEEGPath;


p = plot_params;

W = 420; H = 768;
FIGPOS = [0,(p.screenheight-H), W, H];

%checking for eeglab installation and path
eeglabpath = which('eeglab.m');
if isempty(eeglabpath)
    error('Could not find eeglab installation.  Please make sure eeglab is installed on this computer.')
end
eeglabpath = eeglabpath(1:end-length('eeglab.m'));
addpath(eeglabpath);

fprintf('...building GUI\n');

%setup the main figure window
handles.figure = uifigure;
handles.p = p;

set(handles.figure,...
    'Color', p.backcolor, ...
    'name', 'HCND EEG Study Management and Analysis',...
    'NumberTitle', 'off',...
    'position', FIGPOS,...
    'Resize', 'off',...
    'menubar', 'none');%,...

handles.figure.Visible = 'off';

handles.dropdown_study = uidropdown(...
    'Parent', handles.figure,...
    'Position', [10,H-20,400,20],...
    'Editable', 'off',...
    'BackgroundColor', p.textfieldbackcolor,...
    'FontColor', p.textfieldfontcolor);

handles.tree_filetree = uitree(...
    'Parent', handles.figure,...
    'Multiselect', 'on',...
    'Editable', 'on',...
    'Position', [10,H-300,400,275],...
    'BackgroundColor', p.textfieldbackcolor,...
    'FontColor', p.textfieldfontcolor);

handles.infotabs = uitabgroup(...
    'Parent',handles.figure,...
    'TabLocation', 'top',...
    'Position', [10,10,400,448]...
    );

%***********************************************************************
%general tab
handles.tab_general = uitab(...
    'Parent', handles.infotabs,...
    'Title', 'General',...
    'BackgroundColor', p.backcolor);

uilabel('Parent', handles.tab_general,...
    'Text', 'Study name',...
    'Position', [10, 380,100,25],...
    'Fontcolor', p.labelfontcolor);

uilabel('Parent', handles.tab_general,...
    'Text', 'Relative location',...
    'Position', [10, 340,100,25],...
    'Fontcolor', p.labelfontcolor);

uilabel('Parent', handles.tab_general,...
    'Text', 'Description',...
    'Position', [10, 300,100,25],...
    'Fontcolor', p.labelfontcolor);
uilabel('Parent', handles.tab_general,...
    'Text', 'History',...
    'Position', [10, 175,100,25],...
    'Fontcolor', p.labelfontcolor);

handles.edit_studyname = uieditfield(...
    'Parent', handles.tab_general,...
    'Value', 'study name',...
    'Position', [150,380,240,25],...
    'BackgroundColor', p.textfieldbackcolor,...
    'FontColor', p.textfieldfontcolor,...
    'BackgroundColor', p.textfieldbackcolor,...
    'FontColor', p.textfieldfontcolor);

handles.edit_studypath = uieditfield(...
    'Parent', handles.tab_general,...
    'Value', 'study path',...
    'Position', [150,340,240,25],...
    'BackgroundColor', p.textfieldbackcolor,...
    'FontColor', p.textfieldfontcolor,...
    'BackgroundColor', p.textfieldbackcolor,...
    'FontColor', p.textfieldfontcolor);

handles.edit_studydescr = uitextarea(...
    'Parent', handles.tab_general,...
    'Value', 'desription',...
    'Position', [10,215,380,85],...
    'BackgroundColor', p.textfieldbackcolor,...
    'FontColor', p.textfieldfontcolor,...
    'BackgroundColor', p.textfieldbackcolor,...
    'FontColor', p.textfieldfontcolor);

handles.tree_studyhistory = uitree(...
    'Parent', handles.tab_general,...
    'Position', [10,10,380,165],...
    'BackgroundColor', p.textfieldbackcolor,...
    'FontColor', p.textfieldfontcolor,...
    'BackgroundColor', p.textfieldbackcolor,...
    'FontColor', p.textfieldfontcolor);

%*************************************************************************
%subject panel
handles.tab_subjects = uitab(...
    'Parent', handles.infotabs,...
    'Title', 'Subjects');

uilabel('Parent', handles.tab_subjects,...
    'Text', 'Subject ID',...
    'Position', [10, 380,100,25],...
    'Fontcolor', p.labelfontcolor);
uilabel('Parent', handles.tab_subjects,...
    'Text', 'Subject Folder',...
    'Position', [10, 340,100,25],...
    'Fontcolor', p.labelfontcolor);

uilabel('Parent', handles.tab_subjects,...
    'Text', 'Gender',...
    'Position', [10, 300,100,25],...
    'Fontcolor', p.labelfontcolor);

uilabel('Parent', handles.tab_subjects,...
    'Text', 'Age',...
    'Position', [250, 300,50,25],...
    'Fontcolor', p.labelfontcolor);

uilabel('Parent', handles.tab_subjects,...
    'Text', 'Handedness',...
    'Position', [10, 260,100,25],...
    'Fontcolor', p.labelfontcolor);

handles.edit_subjectid = uieditfield(...
    'Parent', handles.tab_subjects,...
    'Value', '',...
    'Position', [100,380,290,25],...
    'BackgroundColor', p.textfieldbackcolor,...
    'FontColor', p.textfieldfontcolor);

handles.edit_subjectpath = uieditfield(...
    'Parent', handles.tab_subjects,...
    'Value', '',...
    'Position', [100,340,190,25],...
    'BackgroundColor', p.textfieldbackcolor,...
    'FontColor', p.textfieldfontcolor);

handles.button_subjectpath = uibutton(...
    'Parent', handles.tab_subjects,...
    'Text', '...', ...
    'Position', [300, 340, 80, 25],...
    'Backgroundcolor', p.buttoncolor,...
    'FontColor', p.buttonfontcolor,...
    'Backgroundcolor', p.buttoncolor,...
    'FontColor', p.buttonfontcolor);

handles.dropdown_subjectgender = uidropdown(...
    'Parent', handles.tab_subjects,...
    'Items', {'female', 'male', 'other'},...
    'Position', [100,300,100,25],...
    'BackgroundColor', p.textfieldbackcolor,...
    'FontColor', p.textfieldfontcolor);

handles.spinner_subjectage = uispinner(...
    'Parent', handles.tab_subjects,...
    'Value', 20,...
    'Limits', [1,100],...
    'RoundFractionalValues', 'on',...
    'Position', [290,300,100,25],...
    'BackgroundColor', p.textfieldbackcolor,...
    'FontColor', p.textfieldfontcolor);

handles.check_subjectstatus = uicheckbox(...
    'Parent', handles.tab_subjects,...
    'Position', [250, 260, 150,25],...
    'Text', 'Good Subject',...
    'Value', true,...
    'FontColor', p.textfieldfontcolor);

handles.dropdown_subjecthand = uidropdown(...
    'Parent', handles.tab_subjects,...
    'Items', {'right', 'left', 'both'},...
    'Position', [100,260,100,25],...
    'BackgroundColor', p.textfieldbackcolor,...
    'FontColor', p.textfieldfontcolor);

handles.tree_subjectlist = uitree(...
    'Parent', handles.tab_subjects,...
    'Position', [10,10,280,240],...
    'BackgroundColor', p.textfieldbackcolor,...
    'FontColor', p.textfieldfontcolor);

handles.button_subjectadd = uibutton(...
    'Parent', handles.tab_subjects,...
    'Position', [300, 225, 80, 25],...
    'Text', 'Add',...
    'Backgroundcolor', p.buttoncolor,...
    'FontColor', p.buttonfontcolor);

handles.button_subjectremove = uibutton(...
    'Parent', handles.tab_subjects,...
    'Position', [300, 195, 80, 25],...
    'Text', 'Remove',...
    'Backgroundcolor', p.buttoncolor,...
    'FontColor', p.buttonfontcolor);

handles.button_subjectedit = uibutton(...
    'Parent', handles.tab_subjects,...
    'Position', [300, 165, 80, 25],...
    'Text', 'Edit',...
    'Backgroundcolor', p.buttoncolor,...
    'FontColor', p.buttonfontcolor);

%*************************************************************************
% Bin tab
handles.tab_bins = uitab(...
    'Parent', handles.infotabs,...
    'Title', 'Bin Data',...
    'BackgroundColor', p.backcolor);

handles.panel_bingroup = uipanel(...
    'Parent', handles.tab_bins,...
    'Position', [10, 140, 380, 170],...
    'Title', 'Bin Group Information',...
    'BackgroundColor', p.backcolor);

handles.button_bingroupadd = uibutton(...
    'Parent', handles.panel_bingroup,...
    'Position', [290, 115, 80, 25],...
    'Text', 'New',...
    'Backgroundcolor', p.buttoncolor,...
    'FontColor', p.buttonfontcolor);

handles.button_bingroupremove = uibutton(...
    'Parent', handles.panel_bingroup,...
    'Position', [290, 85, 80, 25],...
    'Text', 'Remove',...
    'Backgroundcolor', p.buttoncolor,...
    'FontColor', p.buttonfontcolor);

handles.button_bingroupedit = uibutton(...
    'Parent', handles.panel_bingroup,...
    'Position', [290, 55, 80, 25],...
    'Text', 'Edit',...
    'Backgroundcolor', p.buttoncolor,...
    'FontColor', p.buttonfontcolor);


handles.tree_bingrouplist = uitree(...
    'Parent', handles.tab_bins,...
    'Position', [10,320,280,100],...
    'Multiselect', 'off',...
    'BackgroundColor', p.textfieldbackcolor,...
    'FontColor', p.textfieldfontcolor);

handles.list_binevents = uilistbox(...
     'Parent', handles.tab_bins,...
     'Position', [302, 320, 80, 75],...
     'Items', {'click on the button above to import event markers from an existing file'},...
     'MultiSelect', 'on');
 
 handles.button_getevents = uibutton(...
     'Parent', handles.tab_bins, ...
     'Position', [302, 400, 80, 20],...
     'Text', '-->', ...
     'Backgroundcolor', p.buttoncolor,...
     'FontColor', p.buttonfontcolor);


uilabel('Parent', handles.panel_bingroup, ...
    'Position', [10 115, 100, 25],...
    'FontColor', p.labelfontcolor, ...
    'Text', 'Bin Group Name');

uilabel('Parent', handles.panel_bingroup, ...
    'Position', [10 80, 100, 25],...
    'FontColor', p.labelfontcolor, ...
    'Text', 'Epoch Filename');


uilabel('Parent', handles.panel_bingroup, ...
    'Position', [10 45, 100, 25],...
    'FontColor', p.labelfontcolor, ...
    'Text', 'Epoch start');

uilabel('Parent', handles.panel_bingroup, ...
    'Position', [10 10, 100, 25],...
    'FontColor', p.labelfontcolor, ...
    'Text', 'Epoch end');

handles.edit_bingroupname = uieditfield(...,
    'Parent', handles.panel_bingroup,...
    'Position', [120, 115, 157, 25],...
    'BackgroundColor', p.textfieldbackcolor,...
    'FontColor', p.textfieldfontcolor);


handles.edit_epochfilename = uieditfield(...,
    'Parent', handles.panel_bingroup,...
    'Position', [120, 80, 157, 25],...
    'BackgroundColor', p.textfieldbackcolor,...
    'FontColor', p.textfieldfontcolor);

handles.edit_epochstart = uieditfield(...,
    'numeric',...
    'Parent', handles.panel_bingroup,...
    'Position', [120, 45, 75, 25],...
    'BackgroundColor', p.textfieldbackcolor,...
    'FontColor', p.textfieldfontcolor,...
    'ValueDisplayFormat', '%0.3g sec.',...
    'Value', -.1);

handles.edit_epochend = uieditfield(...,
    'numeric',...
    'Parent', handles.panel_bingroup,...
    'Position', [120, 10, 75, 25],...
    'BackgroundColor', p.textfieldbackcolor,...
    'FontColor', p.textfieldfontcolor,...
    'ValueDisplayFormat', '%0.3g sec.',...
    'Value', .5);

handles.panel_bin = uipanel(...
    'Parent', handles.tab_bins,...
    'Position', [10, 5, 380, 130],...
    'Title', 'Bin Information',...
    'BackgroundColor', p.backcolor);


uilabel('Parent', handles.panel_bin, ...
    'Position', [10 80,100, 25],...
    'FontColor', p.labelfontcolor, ...
    'Text', 'Bin Name');

uilabel('Parent', handles.panel_bin, ...
    'Position', [10 50, 100, 25],...
    'FontColor', p.labelfontcolor, ...
    'Text', 'Bin Events');



handles.edit_binname = uieditfield(...,
    'Parent', handles.panel_bin,...
    'Position', [120, 80, 157, 25],...
    'BackgroundColor', p.textfieldbackcolor,...
    'FontColor', p.textfieldfontcolor);

handles.edit_eventlist = uitextarea(...,
    'Parent', handles.panel_bin,...
    'Position', [120, 10, 157, 55],...
    'BackgroundColor', p.textfieldbackcolor,...
    'FontColor', p.textfieldfontcolor);

handles.button_addbin = uibutton(...
    'Parent', handles.panel_bin, ...
    'Position', [290, 80, 80, 25],...
    'Text', 'Add', ...
    'Backgroundcolor', p.buttoncolor,...
    'FontColor', p.buttonfontcolor,...
    'UserData', 0);

%*************************************************************************
%channel group tab
handles.tab_changroup = uitab(...
    'Parent', handles.infotabs,...
    'Title', 'Channel Group',...
    'BackgroundColor', p.backcolor,...
    'Tag', 'changroup');

handles.axis_chanpicker = uiaxes(...
    'Parent', handles.tab_changroup,...
    'Position', [0,0,270,270],...
    'BackgroundColor', p.backcolor,...
    'Color', p.backcolor,...
    'XColor', p.backcolor,...
    'YColor', p.backcolor,...
    'XTick', [], 'YTick', []);
handles.axis_chanpicker.Toolbar.Visible = 'off';

handles.list_chanpicker = uilistbox(...
    'Parent', handles.tab_changroup,...
    'Position', [300, 5, 85, 250],...
    'Multiselect', 'on',...
    'BackgroundColor', p.textfieldbackcolor,...
    'FontColor', p.textfieldfontcolor);

handles.tree_changroup = uitree(...
    'Parent', handles.tab_changroup,...
    'Position', [10,280,280,120],...
    'BackgroundColor', p.textfieldbackcolor,...
    'FontColor', p.textfieldfontcolor);

uilabel('Parent', handles.tab_changroup,...
    'Position', [5,405, 100,20],...
    'Text', 'Channel Groups',...
    'Fontcolor', p.labelfontcolor);

handles.button_addchangroup = uibutton(...
    'Parent', handles.tab_changroup,...
    'Position', [300,375,90,25],...
    'Text', 'Create',...
    'Backgroundcolor', p.buttoncolor,...
    'FontColor', p.buttonfontcolor);

handles.button_removechangroup = uibutton(...
    'Parent', handles.tab_changroup,...
    'Position', [300,345,90,25],...
    'Text', 'Remove ',...
    'Backgroundcolor', p.buttoncolor,...
    'FontColor', p.buttonfontcolor);

%Study menu
handles.menu_study = uimenu('Parent', handles.figure,'Label', '&Study', 'Accelerator', 's');
handles.menu_new = uimenu(handles.menu_study, 'Label', '&New Study', 'Accelerator', 'n');
handles.menu_refresh = uimenu(handles.menu_study, 'Label', '&Refresh Study List', 'Accelerator', 'r');
handles.menu_deletestudy = uimenu(handles.menu_study, 'Label', 'Delete Study', 'Separator', 'on');
handles.menu_archivestudy = uimenu(handles.menu_study, 'Label', 'Archive Study');

handles.menu_exit = uimenu(handles.menu_study, 'Label', 'Exit', 'Separator', 'on', 'callback', {@callback_exit, handles});
%
%files menu
handles.menu_file = uimenu('Parent', handles.figure,'Label', '&File', 'Accelerator', 'f');
handles.menu_deletefiles = uimenu(handles.menu_file, 'Label', '&Delete','Accelerator', 'd');
handles.menu_exportfiles = uimenu(handles.menu_file, 'Label', 'Export to eeglab', 'Separator', 'on');

%plotting menu
handles.menu_plot = uimenu('Parent', handles.figure, 'Label', '&Plot', 'Accelerator', 'p');
handles.menu_trialplot = uimenu(handles.menu_plot, 'Label', 'Plot and Review Data');

%preprocess menu
handles.menu_preprocess = uimenu('Parent', handles.figure, 'Label', 'Preprocess');
handles.menu_resample = uimenu('Parent', handles.menu_preprocess, 'Label', 'Resample');
handles.menu_filter = uimenu('Parent', handles.menu_preprocess, 'Label', 'Filter');
handles.menu_rbadchans = uimenu('Parent', handles.menu_preprocess, 'Label', 'Remove and interpolate bad channels');
handles.menu_reref = uimenu('Parent', handles.menu_preprocess, 'Label', 'Average reference');
handles.menu_cleanline = uimenu('Parent', handles.menu_preprocess, 'Label', 'Reduce line noise');
handles.menu_extractepochs = uimenu('Parent', handles.menu_preprocess, 'Label', 'Create epoched files', 'Separator', 'on');
handles.menu_markbadtrials = uimenu('Parent', handles.menu_preprocess, 'Label', 'Automatic trial rejection');
handles.menu_computetf = uimenu('Parent', handles.menu_preprocess, 'Label', 'Compute time frequency', 'Separator', 'on');


handles.menu_icamain = uimenu('Parent', handles.figure, 'Label', 'ICA', 'Separator', 'on');
handles.menu_ica = uimenu('Parent', handles.menu_icamain, 'Label', 'Compute ICA');
handles.menu_classify = uimenu(handles.menu_icamain,'Label', 'Classify components');
handles.menu_icareject = uimenu(handles.menu_icamain, 'Label', 'Reject ICA by classification');
handles.menu_icainspect = uimenu(handles.menu_icamain, 'Label', 'ICA classification inspector');
handles.menu_icacopy = uimenu(handles.menu_icamain, 'Label', 'Copy components', 'Separator', 'on', 'Tag', 'copy');
handles.menu_icapaste = uimenu(handles.menu_icamain, 'Label', 'Paste components', 'Enable', 'off', 'Tag', 'paste');

handles.menu_erp = uimenu(handles.figure, 'Label', 'ERP');
handles.menu_erpave = uimenu(handles.menu_erp, 'Label', 'Compute Averaged ERPs');

%tools menu
handles.menu_utils = uimenu('Parent', handles.figure,'Label', '&Tools', 'Accelerator', 't');
handles.menu_convert = uimenu(handles.menu_utils, 'Label', 'Convert Biosemi File');
handles.menu_script = uimenu(handles.menu_utils, 'Label', 'Run Custom Script');
handles.menu_evtsummary = uimenu(handles.menu_utils, 'Label', 'Event Summary');
handles.menu_trimraw = uimenu(handles.menu_utils, 'Label', 'Trim Continuous (CNT) EEG File');


%Context menus
handles.cm_epochlist = uicontextmenu(handles.figure);

uimenu(handles.cm_epochlist, 'Text', 'Edit', 'MenuSelectedFcn', {@callback_editbingroup, handles});
uimenu(handles.cm_epochlist, 'Text', 'Delete', 'MenuSelectedFcn', {@callback_removebingroup, handles});


%assign all the callbacks
set(handles.dropdown_study, 'ValueChangedFcn', {@callback_loadstudy, handles})

set(handles.menu_new, 'Callback', {@callback_newstudy, handles});
set(handles.menu_refresh, 'Callback', {@callback_refresh, handles});
set(handles.menu_exit, 'Callback', {@callback_exit, handles});
set(handles.menu_script, 'Callback', {@callback_runscript, handles});
set(handles.menu_evtsummary, 'Callback', {@callback_evtsummary, handles});
set(handles.menu_trimraw, 'Callback', {@callback_trimraw, handles});
set(handles.menu_trialplot, 'Callback', {@callback_trialplot, handles});
set(handles.menu_deletefiles, 'Callback', {@callback_deletefiles, handles});
set(handles.menu_exportfiles, 'Callback', {@callback_exportfiles, handles});
set(handles.menu_rbadchans, 'Callback', {@callback_interpchans, handles});
set(handles.menu_resample, 'Callback', {@callback_resample, handles});
set(handles.menu_filter, 'Callback', {@callback_filter, handles});
set(handles.menu_reref, 'Callback', {@callback_reref, handles});
set(handles.menu_cleanline, 'Callback', {@callback_cleanline, handles});
set(handles.menu_extractepochs , 'Callback', {@callback_extract, handles});
set(handles.menu_markbadtrials, 'Callback', {@callback_reject, handles});
set(handles.menu_computetf, 'Callback', {@callback_computetf, handles});

set(handles.menu_ica, 'Callback', {@callback_ICA, handles});
set(handles.menu_classify, 'Callback', {@callback_classifyICA, handles});
set(handles.menu_icainspect, 'Callback', {@callback_inspectICA, handles});
set(handles.menu_icareject, 'Callback', {@callback_rejectICA, handles});
set(handles.menu_erpave, 'Callback', {@callback_average, handles});
set(handles.menu_icacopy, 'Callback', {@callback_copypastecomponents, handles});
set(handles.menu_icapaste, 'Callback', {@callback_copypastecomponents, handles});

set(handles.menu_convert, 'Callback', {@callback_convert,handles});

set(handles.infotabs, 'SelectionChangedFcn', {@callback_checkforchaninfo, handles});
set(handles.button_subjectedit, 'ButtonPushedFcn', {@callback_editsubject,  handles});
set(handles.button_subjectadd, 'ButtonPushedFcn', {@callback_addsubject, handles});
set(handles.button_subjectremove, 'ButtonPushedFcn', {@callback_removesubject, handles});
set(handles.button_subjectpath, 'ButtonPushedFcn', {@callback_getsubjectpath, handles});
set(handles.button_addchangroup, 'ButtonPushedFcn', {@callback_createchangroup, handles});
set(handles.button_removechangroup, 'ButtonPushedFcn', {@callback_removechangroup, handles});
set(handles.button_getevents, 'ButtonPushedFcn', {@callback_importevents, handles});
set(handles.button_bingroupadd, 'ButtonPushedFcn', {@callback_addbingroup, handles});
set(handles.button_addbin, 'ButtonPushedFcn', {@callback_addbintogroup, handles});
set(handles.button_bingroupremove, 'ButtonPushedFcn', {@callback_removebingroup, handles});
set(handles.button_bingroupedit, 'ButtonPushedFcn', {@callback_editbingroup, handles});

set(handles.tree_changroup, 'SelectionChangedFcn', {@callback_selectchangroup, handles});

set(handles.list_chanpicker, 'ValueChangedFcn', {@callback_drawchannelpositions, handles});
set(handles.list_binevents, 'ValueChangedFcn', {@callback_addtoeventlist, handles});

handles.edit_studydescr.ValueChangedFcn = {@callback_editstudydescr, handles};

%these functions are from the original version of eeg_hcnd and have not
%been integrated into the new version yet.
%
% set(handles.button_reject, 'Callback', {@callback_reject, handles});
% set(handles.button_timefreq, 'Callback', {@callback_timefreq, handles});
% set(handles.button_viewtimefreq, 'Callback', {@callback_viewtimefreq, handles});
% set(handles.button_csd, 'Callback', {@callback_CSD, handles});
% set(handles.button_dipole, 'Callback', {@callback_Dipole, handles});
% set(handles.button_ersp, 'Callback', {@callback_ersp, handles});
% set(handles.button_conn, 'Callback', {@callback_conn, handles});
% set(handles.button_connview, 'Callback', {@callback_viewconn, handles});
% set(handles.button_stats, 'Callback', {@callback_stats, handles});
% set(handles.button_average, 'Callback', {@callback_average, handles});

fprintf('...reading STUDY information\n');
populate_studylist(handles)

fprintf('...loading current study and populating GUI\n');
callback_loadstudy(0,0,handles)

fprintf('...done\n');
handles.figure.Visible = 'on';
%%
%Start of function definitions
%**************************************************************************
function callback_copypastecomponents(hObject, event, h)


study = getstudy(h);
if study.nsubjects < 1
    msgbox('No subjects are listed in your study','Conversion Error', 'error');
    return
end

flist = getselectedfiles(study,h);
if isempty(flist)
    return
end

pg = uiprogressdlg(h.figure, 'Message', '', 'Title', 'Copy Paste', 'Indeterminate', 'on');

copy_info = [];
switch hObject.Tag
    case 'copy'
        pg.Message = 'Copying ICA components';
        %check to see if the number of files is greater than the number of participants
        if length(flist) > study.nsubjects
            uialert(h.figure, 'ICA components can only be copied from one file group', 'Copy ICA');
            hObject.UserData = copy_info;
            h.menu_icapaste.Enable = 'off';
            delete(pg);
            return
        end
        
        for fn = flist
            t = load(fn{:}, '-mat');
            if isfield(t, 'EEG')
                EEG = t.EEG;
            else
                EEG = t;
            end
             clear t;
            if isempty(EEG.icasphere)
                uialert(h.figure, 'At least one of the selected files does not have ICA components', 'Copy ICA');
                hObject.UserData = copy_info;
                h.menu_icapaste.Enable = 'off';
                delete(pg);
                return
            end
        end
        
        copy_info.flist = flist;
        copy_info.copy_time = datetime('now');
        h.menu_icacopy.UserData = copy_info;
        h.menu_icapaste.Enable = 'on';
        fprintf('Components from %i files save to the clipboard\n', length(flist));
        
    case 'paste'
        pg.Message = 'Pasting ICA components';
        copy_info = h.menu_icacopy.UserData;
        if isempty(copy_info)
            h.menu_icapaste.Enable = 'off';
            delete(pg);
            return
        end
        
        if length(flist) ~= length(copy_info.flist)
            uialert('The number of files selected is different than the number of originating files')
            h.menu_icapaste.Enable = 'off';
            delete(pg);
            return
        end
        
        %check names
        for ii = 1:length(flist)
            if ~strcmp(fileparts(flist{ii}), fileparts(copy_info.flist{ii}))
                uialert(h.figure, 'At least one of the source and destination paths do not match', 'Copy ICA');
                h.menu_icacopy.UserData = [];
                h.menu_icapaste.Enable = 'off';
                delete(pg);
                return
            end
        end
        
        %now finally do the copying
        for ii = 1:length(flist)
            destEEG = wwu_LoadEEGFile(flist{ii});
        %    t = load(flist{ii}, '-mat');
        %    destEEG = t.EEG;
            sourceEEG = wwu_LoadEEGFile(copy_info.flist{ii});
           % t = load(copy_info.flist{ii}, '-mat');
           % sourceEEG = t.EEG;
            
            destEEG.icasphere = sourceEEG.icasphere;
            destEEG.icaweights = sourceEEG.icaweights;
            EEG = eeg_checkset(destEEG);
            
            wwu_SaveEEGFile(EEG, flist{ii});
        end
        
        
        h.menu_icacopy.UserData = [];
        h.menu_icacopy.Enable = 'off';
        
        fprintf('Components copied')
        delete(pg);
        
end
%*********************************************************************
%refresh the display after updating information
function callback_refresh(hObject, event, h)

h.figure.Pointer = 'watch';
populate_studylist(h)
callback_loadstudy(0,0,h)
h.figure.Pointer = 'arrow';

%*************************************************************************
%edit the description of the study in real time
function callback_editstudydescr(hObject, event, h)

study = getstudy(h);
study.description = h.edit_studydescr.Value;
study = study_SaveStudy(study);
setstudy(study, h);
%*************************************************************************
%get the events from a file and put them in a dorp down list box
function callback_importevents(hObject, eventdata, h)

study = getstudy(h);
f = getselectedfiles(study, h);
if isempty(f)
    return
end

%use the file from the first participant
%EEG = pop_loadset(f{1});
EEG = wwu_LoadEEGFile(f{1});

%collect all the events into a singlr cell vector
evnts = {EEG.event.type};
%make sure they are string variables
evnts = cellfun(@num2str, evnts, 'UniformOutput', false);

unique_events = unique(evnts);
h.list_binevents.Items = unique_events;

%**************************************************************************
function callback_addtoeventlist(hObject, eventdata, h)

i = hObject.Value;
if isempty(i); return; end
new_evnt = join(i);

cur_evnt = h.edit_eventlist.Value;
cur_evnt = join(cur_evnt');
all_evnt = join(cat(2, cur_evnt, new_evnt));
h.edit_eventlist.Value = all_evnt;

%**************************************************************************
function callback_addbingroup(hObject, eventdata, h)


study = getstudy(h);

epochgroup_name = h.edit_bingroupname.Value;
epochgroup_filename  = h.edit_epochfilename.Value;
epoch_start = h.edit_epochstart.Value;
epoch_end = h.edit_epochend.Value;

mode = hObject.UserData;

if isempty(epochgroup_name)
    uialert(h.figure, 'Please enter a valid bin group name.', 'Error');
    return
else
    eg.name = epochgroup_name;
end

if isempty(epochgroup_filename)
    uialert(h.figure, 'Please enter a valid bin group file name.', 'Error');
    return
else
    eg.filename = epochgroup_filename;
end

    
if epoch_start >= epoch_end
    uialert(h.figure, 'the epoch start cannot be greater than the epoch end.', 'Error');
else
    eg.interval = [epoch_start, epoch_end];
end


if mode == 1 %this is an update and not a new bin group
   n = h.tree_bingrouplist.SelectedNodes;
   cnum = n.NodeData{1};
   eg.bins = study.bingroup(cnum).bins; %save the bin information
elseif ~isfield(study, 'bingroup')
    cnum = 1;   
    eg.bins = [];
else
    cnum = length(study.bingroup) + 1;
    eg.bins = [];
end

study.bingroup(cnum)  = eg;

study = study_SaveStudy(study);
setstudy(study, h);
populate_bintree(study, h);

if mode ==1
    callback_clearcondition(hObject, eventdata, h)
end

%*************************************************************************
function callback_removebingroup(hObject, eventdata, h)

n = h.tree_bingrouplist.SelectedNodes;
study = getstudy(h);

if hObject.UserData ==1
    callback_clearcondition(hObject, eventdata, h)
    return
end


if isempty(n)
    uialert(h.figure, 'Try selecting something to delete first.', 'Epoch delete');
    return
end

enum = n.NodeData{1};
cnum = n.NodeData{2};

if cnum==0 % this is an epoch group
    response = uiconfirm(h.figure, 'Are you sure you want to delete this Bin Group and all its associated bin information?', 'Delete Bin Group');
    if contains(response, 'OK')
        study.bingroup(enum) = [];
        enum = 0;
    end
else
    response = uiconfirm(h.figure, 'Are you sure you want to delete this Bin?', 'Delete Bin');
    if contains(response, 'OK')
        study.bingroup(enum).bins(cnum) = [];
        cnum = length(study.bingroup(enum).bins);
    end
end

study = study_SaveStudy(study);
setstudy(study, h);
populate_bintree(study, h, [enum, cnum]);    

%*************************************************************************
%callback function for allowing editing of an existing condition
function callback_editbingroup(hObject, eventdata, h)

study = getstudy(h);
n = h.tree_bingrouplist.SelectedNodes;
if isempty(n)
    uialert(h.figure, 'You must select a Bin Group to edit.', 'Edit Bin Group');
    return
end

gnum = n.NodeData{1};
cnum = n.NodeData{2};

%if cnum==0 %the user is editing the epoch group name
    h.edit_bingroupname.Value = study.bingroup(gnum).name;
    h.edit_epochfilename.Value = study.bingroup(gnum).filename;
    h.edit_epochstart.Value = study.bingroup(gnum).interval(1);
    h.edit_epochend.Value = study.bingroup(gnum).interval(2);

    %set things in an edit mode
    h.button_bingroupadd.Text = 'Update';
    h.button_bingroupadd.UserData = 1; %this puts the button in edit mode
    h.button_bingroupremove.Text = 'Cancel';
    h.button_bingroupremove.UserData = 1;
    
    h.tree_bingrouplist.Enable = 'off';
%end
%callback for handling the clearing of the information in the condition ui
%boxes and for cancelling the editing mode
function callback_clearcondition(hObject, eventdata, h)

mode = hObject.UserData;

if mode==1   
    %reset things out of edit mode
    h.button_bingroupadd.Text = 'New';
    h.button_bingroupadd.UserData = 0; %this puts the button in edit mode
    h.button_bingroupremove.Text = 'Remove';
    h.button_bingroupremove.UserData = 0;
    h.tree_bingrouplist.Enable = 'on';
end

%*************************************************************************
%adds a new condition to an Epoch group or adds edited information to an
%existing group.
function callback_addbintogroup(hObject,eventdata, h)

study = getstudy(h);


n = h.tree_bingrouplist.SelectedNodes;
if isempty(n)
    uialert(h.figure,'Please create or select a Bin Group first.', 'Add Condition');
    return
end

ndata = n.NodeData;
gnum = ndata{1}; cnum = ndata{2};

if ~isempty(study.bingroup(gnum).bins)
    new_cnum = length(study.bingroup(gnum).bins) + 1;
else
    new_cnum = 1;
end

%get information from the input boxes
p.name = h.edit_binname.Value;
p.events = h.edit_eventlist.Value;


%do some checking
if strcmp(p.name, '')
    uialert(h.figure,'Please enter a valid Bin Name', 'Add Bin');
    return
end

if isempty(p.events)
    uialert(h.figure,'Please enter some event markers', 'Add Condition');
    return
end

if new_cnum==1
    study.bingroup(gnum).bins = p;
else
    study.bingroup(gnum).bins(new_cnum) = p;
end


study = study_SaveStudy(study);
setstudy(study, h);
populate_bintree(study, h, [gnum, new_cnum]);

%***************************************************************************
%this fills the epoch tree information list with the current epoch
%information for the loaded study
function populate_bintree(study, h, select)

if nargin < 3
    select = [0,0];
end
%clear existing nodes
n = h.tree_bingrouplist.Children;
n.delete;

if ~isfield(study, 'bingroup')
    return
end

node_to_select = [];

for ii = 1:length(study.bingroup)
    n = uitreenode('Parent', h.tree_bingrouplist,'Text', study.bingroup(ii).name,'NodeData', {ii, 0}, 'ContextMenu',h.cm_epochlist);
    uitreenode('Parent', n, 'Text', sprintf('start:\t%0.3g', study.bingroup(ii).interval(1)),...
                'NodeData', {ii, 0}, 'ContextMenu',h.cm_epochlist);
    uitreenode('Parent', n, 'Text', sprintf('end:\t\t%0.3g', study.bingroup(ii).interval(2)),...
                'NodeData', {ii, 0}, 'ContextMenu',h.cm_epochlist);
    n2 = uitreenode('Parent', n, 'Text', 'bins',...
                'NodeData', {ii, 0}, 'ContextMenu',h.cm_epochlist);
                    
    if isfield(study.bingroup(ii), 'bins')
        for jj = 1:length(study.bingroup(ii).bins)      
            n3 = uitreenode('Parent', n2, 'Text', sprintf('%i:\t%s',jj, study.bingroup(ii).bins(jj).name),...
                'NodeData', {ii, jj}, 'ContextMenu',h.cm_epochlist);
            uitreenode('Parent', n3, 'Text', sprintf('bin events:\t%s ', study.bingroup(ii).bins(jj).events{:}),...
                'NodeData', {ii, jj}, 'ContextMenu',h.cm_epochlist);
            if (ii==select(1)) && (jj==select(2))
                node_to_select = n3;
            end
                      
        end
    end
  
end
if ~isempty(node_to_select)
    expand(node_to_select.Parent);
    h.tree_bingrouplist.SelectedNodes = node_to_select;
end

setstudy(study, h);
%**************************************************************************
%exports files to the eeglab set format
function callback_exportfiles(hObject, eventdata, h, format)

study = getstudy(h);
filestoexport = getselectedfiles(study, h);
alert = false;

if isempty(filestoexport)
    uialert(h.figure, 'No files have been selected for export.', 'File Export')
else

    pb = uiprogressdlg(h.figure,'Message','Exporting selected files');
    totalEvents = length(filestoexport) * 2;
    for ii = 1:length(filestoexport)
        enum = (ii * 2 -1);
        pb.Value = enum/totalEvents;
        pb.Message = sprintf('Loading file #%i of %i',ii,totalEvents/2);
        [p, f, e] = fileparts(filestoexport{ii});
        switch e
            case {'.cnt', '.epc'}
                EEG = wwu_LoadEEGFile(filestoexport{ii});
                enum = (ii * 2);
                pb.Value = enum/totalEvents;
                pb.Message = sprintf('Saving file #%i of %i',ii, totalEvents/2) ;
                EEG = pop_saveset(EEG, 'filepath', p, 'filename', f);
            otherwise
                fprintf('the file %s cannot be exported to eeglab format\n', filestoexport{ii})
                alert = true;
        end
    end
    if alert 
        uialert(h.figure, 'Not all files were exported.  Please see the MATLAB console for more informaiton', 'File Export');
    end
    populate_filelist(study,h);
   
end

%**************************************************************************
%deletes selected files from the disk
function callback_deletefiles(hObject, eventdata, h)

study = getstudy(h);
filestodelete = getselectedfiles(study, h);


if isempty(filestodelete)
    uialert(h.figure, 'No files have been selected')
else
    start = clock;
    msgstr = sprintf(...
        'Are you sure you want to delete these %i files? This action cannot be undone!', length(filestodelete));
    if(contains(uiconfirm(h.figure, msgstr, 'Confirm file deletion'), 'OK'))
        cellfun(@delete, filestodelete);
        populate_filelist(study,h);
        study = study_AddHistory(study, 'start', start, 'finish', clock,'event', 'Delete Files', 'function', 'callback_deletefiles', 'paramstring', filestodelete, 'fileID', '');
        study = study_SaveStudy(study);
        setstudy(study,h);
        populate_studyinfo(study,h)
    end
    
    
end
%************************************************************************
%populates the study tree with all the studies found in teh "STUDIES"
%folder
function populate_studylist(h, selected_study)

if nargin < 2
    selected_study = [];
end

EEGPath = study_GetEEGPath;
STUDYPATH = fullfile(EEGPath, 'STUDIES');

h.figure.Pointer = 'watch';
d = dir([STUDYPATH, filesep,'*.study']);
studylist = cellfun(@(x) x(1:length(x)-6), {d.name}, 'UniformOutput', false);
studyinfo = cellfun(@(x,y) fullfile(x, y), {d.folder}, {d.name}, 'UniformOUtput', false);


h.dropdown_study.Items = studylist;
h.dropdown_study.ItemsData = studyinfo;

if  ~isempty(selected_study)
    selitem = studyinfo{contains(studylist, selected_study)};
    if ~isempty(selitem)
        h.dropdown_study.Value = selitem;
        callback_loadstudy([],[],h);
    end
end

h.figure.Pointer = 'arrow';
%************************************************************************
function callback_loadstudy(hObject, eventdata, h)

h.figure.Pointer = 'watch';
%first clear out the current list
t = h.tree_filetree.Children;
t.delete;

%load the study information
study_name = h.dropdown_study.Value;

if isempty(study_name)
    return;
end


if isempty(dir(study_name))
    uialert(h.figure,sprintf('The specified study %s does not exist.', study_name));
    h.figure.Pointer = 'arrow';
    return
else
    temp = load(study_name, '-mat'); study = temp.study; clear temp;
    setstudy(study,h);
end

populate_studyinfo(study, h);
populate_filelist(study, h);
populate_bintree(study, h);
h.figure.Pointer = 'arrow';
%*************************************************************************
%puts all the study information into the display and edit controls on the
%main screen
function populate_studyinfo(study, h)

%fprintf('populating study information...\n')
h.edit_studyname.Value = study.name;
h.edit_studypath.Value = study.path;
if isempty(study.description)
    h.edit_studydescr.Value = '';
else
    h.edit_studydescr.Value = study.description;
end

% %clear current history
% n = h.tree_studyhistory.Children;
% n.delete;
% n = h.tree_subjectlist.Children;
% n.delete;
% 
% try
% %load the new history
% fprintf('adding study history...\n')
% if ~isempty(study.history)
%     for hh = 1:length(study.history)
%         n = uitreenode('Parent', h.tree_studyhistory,...
%             'Text', study.history(hh).event);
%         uitreenode('Parent', n, ...
%             'Text', sprintf('%s:\t%s', 'Start', datetime(study.history(hh).start)));
%         uitreenode('Parent', n, ...
%             'Text', sprintf('%s:\t%s', 'Finish', datetime(study.history(hh).finish)));
%         uitreenode('Parent', n, ...
%             'Text', sprintf('Function:\t%s', study.history(hh).function));
%         p = uitreenode('Parent', n, 'Text', 'Parameters');
%         for pp = 1:length(study.history(hh).paramstring)
%        
%             if ischar(study.history(hh).paramstring)
%                 paramStr = study.history(hh).paramstring;
%             else
%                 paramStr = study.history(hh).paramstring{pp};
%             end
%             paramStr = num2str(paramStr);
%             uitreenode('Parent', p, ...
%                     'Text', paramStr);
%         end
%         uitreenode('Parent', n, ...
%             'Text', sprintf('ID:\t%s',study.history(hh).fileID));
%     end
% end
% catch ME
% 
%     fprintf('Some problem with the history display\n')
%     study.history(hh);
%     rethrow(ME)
% end


%load the subjects into the subject tree
if study.nsubjects > 0
    for ss = 1:length(study.subject)
        n = uitreenode('Parent', h.tree_subjectlist,...
            'Text', sprintf('Subject: \t%s', study.subject(ss).ID),...
            'NodeData', ss);
        uitreenode('Parent', n,...
            'Text', sprintf('Data path:\t\t%s', study.subject(ss).path),...
            'NodeData', ss);
        uitreenode('Parent', n,...
            'Text', sprintf('Gender:\t\t\t%s', study.subject(ss).gender),...
            'NodeData', ss);
        uitreenode('Parent', n,...
            'Text', sprintf('Handedness:\t\t%s', study.subject(ss).hand),...
            'NodeData', ss);
        uitreenode('Parent', n,...
            'Text', sprintf('Age:\t\t\t\t%s', study.subject(ss).age),...
            'NodeData', ss);
        uitreenode('Parent', n,...
            'Text', sprintf('Status:\t\t\t%s', study.subject(ss).status),...
            'NodeData', ss);
    end
end
populate_ChanGroupDisplay(study, h)

%*************************************************************************
%load all the information into the file tree
%**************************************************************************
function populate_filelist(study, h)

%fprintf('populating study file list\n')
EEGPath = study_GetEEGPath;
flist = [];

for ii = 1:study.nsubjects
    searchpath = wwu_buildpath(EEGPath, study.path, study.subject(ii).path, '*.*');
    d = dir(searchpath);
    temp = flist;
    
    if ~isempty(d)      %make sure there are files in the directiory
        for ff = 1:length(d)       %loop through each one
            switch d(ff).name(1)              %make sure they are not '.' or '..'
                case {'.'}
                    continue
                otherwise
                    if isempty(temp)    %if this is the first time through, just assign file names
                        nentries = length(flist)+1;
                        flist(nentries).name = d(ff).name;
                        flist(nentries).count = 1;
                    else                %otherwise check for duplicates
                        slist = {flist.name};
                        ismatch = strcmp(slist, d(ff).name);
                        indx = find(ismatch==1);
                        if indx>0
                            flist(indx).count = flist(indx).count + 1;
                        else
                            nentries = length(flist)+1;
                            flist(nentries).name = d(ff).name;
                            flist(nentries).count = 1;
                        end
                    end
            end
        end
    end
end

FileTypes = {'Biosemi Files', 'Continuous EEG', 'Epoched Trial Data', 'Averages', 'EEGLab Files', 'Other'};
Included_Extensions = {'.bdf', '.cnt', '.epc', '.GND', '.set'};
Excluded_Extensions = {'.fdt'};

%clear the existing list of files
n = h.tree_filetree.Children;
n.delete;

Nodes = [];
for ii = 1:length(FileTypes)
    Nodes(ii).Node = uitreenode(h.tree_filetree, 'Text', FileTypes{ii});
end

for ii = 1:length(flist)
    %get the file extension used for categorization
    [~,fname,ext] = fileparts(flist(ii).name);
    
    if ~isempty(find(strcmp(Excluded_Extensions, ext),1))
        continue
    end
    %figure out which category it is
    category = find(strcmp(Included_Extensions,ext));
    if isempty(category); category = length(FileTypes); end
    node_name = sprintf('(%i)\t%s', flist(ii).count,flist(ii).name);
    uitreenode(Nodes(category).Node,'Text', node_name, 'NodeData', flist(ii).name);
end

%now get the average files from the across subect folder
searchpath = wwu_buildpath(EEGPath, study.path, 'across subject');
if ~exist(searchpath, 'dir')
    return
else
    flist = dir(fullfile(searchpath,filesep, '*.GND'));
    for ii = 1:length(flist)
        
        [~,fname,ext] = fileparts(flist(ii).name);
    
         category = find(strcmp(Included_Extensions,'.GND'));
         if isempty(category); category = length(FileTypes); end
         node_name = sprintf('(%i)\t%s', 1 ,flist(ii).name);
         uitreenode(Nodes(category).Node,'Text', node_name, 'NodeData', flist(ii).name);
         
    end
end

%**************************************************************************
%refresh all the informaiton on the channel group tab
%**************************************************************************
function populate_ChanGroupDisplay(study, h)

n = h.tree_changroup.Children;
n.delete;

if ~isfield(study, 'chanlocs')
    return
end

h.list_chanpicker.Items = {study.chanlocs.labels};
h.list_chanpicker.ItemsData = 1:length(study.chanlocs);
callback_drawchannelpositions(0,0,h)

%delete existing channel groups in the display


%add the ones from thh current study

if isfield(study,'chgroups')
    for ii = 1:length(study.chgroups)
        n = uitreenode('Parent', h.tree_changroup,...
            'Text', study.chgroups(ii).name, 'NodeData', ii);
        for jj = 1:length(study.chgroups(ii).chans)
            uitreenode('Parent', n, 'Text', study.chgroups(ii).chanlocs(jj).labels,...
                'NodeData', ii);
        end
    end
end

%*************************************************************************
%Offer the oppportunity to associate channel informaiton to this study in
%case it is not already attached.
%*************************************************************************
function callback_checkforchaninfo(hObject, eventdata,h)

if strcmp('changroup', eventdata.NewValue.Tag)
    study = getstudy(h);
    if ~isfield(study, 'chanlocs')
        msg = 'There are currently no channel locations associated with this study.';
        msg = sprintf('%s Would you like to add information from a channel file?\n\n', msg);
        msg = sprintf('%s All files in your study must have the same channel names and order to avoid problems later', msg);
        
        selection = uiconfirm(h.figure, msg, 'Add channel locations',...
            'Options', {'Add Locations', 'Cancel'});
        
        if strcmp(selection, 'Add Locations')
            
            [loc_file, loc_path] = uigetfile('*.*', 'Select channel locations file');
            if ~isempty(loc_file)
                chanlocs = readlocs(fullfile(loc_path,loc_file));
                if ~isempty(chanlocs)
                    study.chanlocs = chanlocs;
                    setstudy(study, h);
                    study_SaveStudy(study);
                end
            end
        end
        
        
    end
end

%*************************************************************************
%draw the display that shows the channel locations on a 2-d projection
%**************************************************************************
function callback_drawchannelpositions(hobject, eventdata, h)


study = getstudy(h);

selchans = h.list_chanpicker.Value;

wwu_PlotChannelLocations(study.chanlocs,...
    'Elec_Color', h.p.buttoncolor,...
    'Elec_Selcolor',[.2,.9,.2],...
    'Elec_Size', 5,...
    'Elec_SelSize', 10,...
    'Labels', 'name',...
    'Subset', selchans,...
    'AxisHandle', h.axis_chanpicker);

%*************************************************************************
%this is the callback for the Create button on the channel group tab
%*************************************************************************
function callback_createchangroup(hObject, eventdata,h)

study = getstudy(h);

if ~isfield(study, 'chgroups')
    default_groupname = 'Group 1';
    gnum = 1;
else
    default_groupname = sprintf('Group %i', sum(contains({study.chgroups.name},'Group'))+1);
    gnum = length(study.chgroups) + 1;
end

%get a name for this group
prompt = {'Enter a name for the channel group'};
dlgtitle = 'New Channel Group';
dims = [1 35];
definput = {default_groupname};
answer = inputdlg(prompt,dlgtitle,dims,definput);

%now make the group

study.chgroups(gnum).name = answer{:};
study.chgroups(gnum).chans = h.list_chanpicker.Value;
study.chgroups(gnum).chanlocs = study.chanlocs(study.chgroups(gnum).chans);

setstudy(study,h);
study = study_SaveStudy(study);
populate_ChanGroupDisplay(study, h)

%*************************************************************************
function callback_removechangroup(hObject, eventdata, h)

study = getstudy(h);
n = h.tree_changroup.SelectedNodes;

if isempty(n)
    return
end

msg = sprintf('Are you sure you want to remove channgel group %s', study.chgroups(n.NodeData).name);

if strcmp(uiconfirm(h.figure, msg, 'Remove Channel Group'), 'OK')
    
    study.chgroups(n.NodeData) = [];
    
    setstudy(study, h)
    study_SaveStudy(study);
    populate_ChanGroupDisplay(study, h)
    
end

%**************************************************************************
%function to select the channels based on the channel group the user
%selects
%**************************************************************************
function callback_selectchangroup(hObject, eventdata, h)

study = getstudy(h);
n = h.tree_changroup.SelectedNodes;

if isempty(n)
    return
end
h.list_chanpicker.Value = study.chgroups(n.NodeData).chans;
callback_drawchannelpositions(0,0,h)

%*********************************************************************
function callback_editsubject(hObject, eventdata,h)

study = getstudy(h);

n = h.tree_subjectlist.SelectedNodes;
if isempty(n)
    uialert(h.figure, 'Please select a subject to edit', 'Subject Edit');
    return
end

sn = n.NodeData;

%place the values from the selected subject in teh appropriate controls
h.edit_subjectid.Value = study.subject(sn).ID;
h.edit_subjectpath.Value = study.subject(sn).path;
h.dropdown_subjectgender.Value = study.subject(sn).gender;
h.spinner_subjectage.Value = str2double(study.subject(sn).age);
h.dropdown_subjecthand.Value = study.subject(sn).hand;
h.check_subjectstatus.Value = strcmp(study.subject(sn).status, 'good');


%change the status of the controls
h.button_subjectadd.Text = 'Update';
h.button_subjectadd.UserData = sn;

h.button_subjectremove.Text = 'Cancel';
h.button_subjectremove.UserData = sn;

hObject.Enable = 'off';

%**************************************************************************
%add a subject to the current study
function callback_addsubject(hObject, eventdata, h)

sn = hObject.UserData;
study = getstudy(h);

%collect all the data into a subject structure
subject.ID = h.edit_subjectid.Value;
subject.path = h.edit_subjectpath.Value;
subject.gender = h.dropdown_subjectgender.Value;
subject.age = num2str(h.spinner_subjectage.Value);
subject.hand = h.dropdown_subjecthand.Value;
if h.check_subjectstatus.Value==1
    subject.status =  'good';
else
    subject.status = 'bad';
end

%make sure all the necessary information is included
if isempty(subject.ID) || isempty(subject.path)
    uialert(h.figure, 'Please include a valid Subject ID and Folder.', 'New Subject');
    return
end

%make sure the path actually exists.
fullpath = fullfile(study_GetEEGPath, study.path, subject.path);
if ~isfolder(fullpath)
    uialert(h.figure, 'The subject folder could not be found. The subject folder must reside in the study folder.', 'New Subject');
    return
end

if ~isempty(sn)   %this is the edit mode
    study.subject(sn) = subject;
    h.button_subjectadd.Text = 'Add';
    h.button_subjectadd.UserData = [];
    h.button_subjectremove.Text = 'Remove';
    h.button_subjectremove.UserData = [];
    h.button_subjectedit.Enable = 'on';
    
else
    if ~isfield(study, 'subject') 
        study.subject = subject;
    else
        if isempty(study.subject)
            study.subject = subject;
        else
            study.subject(end+1) = subject;
        end
    end
    study.nsubjects = study.nsubjects + 1;
end

%reset all the values to their default state
set_subjectdefaults(h);

%save the study within the figure
setstudy(study, h);

%save the study on the disk
study_SaveStudy(study);

%refresh the node tree
populate_studyinfo(study, h);
populate_filelist(study, h)

%*************************************************************************
function callback_removesubject(hObject, eventdata, h)

sn = hObject.UserData;
study = getstudy(h);

if ~isempty(sn)   %this is the cancel mode
    
    h.button_subjectadd.Text = 'Add';
    h.button_subjectadd.UserData = [];
    h.button_subjectremove.Text = 'Remove';
    h.button_subjectremove.UserData = [];
    h.button_subjectedit.Enable = 'on';
    
else
    n = h.tree_subjectlist.SelectedNodes;
    if isempty(n)
        uialert(h.figure, 'Please select a subject to edit', 'Subject Edit');
        return
    end
    
    sn = n.NodeData;
    msgstr = sprintf('Are you sure you want to remove subject %s from this study?',...
        study.subject(sn).ID);
    selection = uiconfirm(h.figure, msgstr, 'Remove Subject',...
        'Options', {'Remove', 'Cancel'},...
        'DefaultOption', 2,...
        'CancelOption', 2);
    if strcmp(selection, 'Remove')
        study.subject(sn) = [];
        study.nsubjects = study.nsubjects -1;
        
        %save the study within the figure
        setstudy(study, h);
        
        %save the study on the disk
        study_SaveStudy(study);
        
        %refresh the node tree
        populate_studyinfo(study, h);
    end
    
    
end
set_subjectdefaults(h);

%*************************************************************************
function callback_getsubjectpath(hObject, eventdata, h)

eeg_path = study_GetEEGPath();


study = getstudy(h);

%build the path for this study
fullstudypath = wwu_buildpath(eeg_path, study.path);

%get the user path input
path = uigetdir(fullstudypath);

%make sure they made a choice and did not cancel
if isempty(path); return; end

%make sure the folder is in the study folder
i = strfind(path, fullstudypath);
if ~isempty(i)
    %get just the relative portion
    path = path(i+length(fullstudypath):length(path));
else
    uialert(h.figure, sprintf('Not a valid folder.  Subject data folder must be located within the study folder %s',...
        fullstudypath), 'try it again...','Icon', 'info');
    return
end

%assign it
h.edit_subjectpath.Value = path;

%automatically create a likely subject ID if the field is blank
if isempty(h.edit_subjectid.Value)
    [~, autoID, ~] = fileparts(path);
    h.edit_subjectid.Value = autoID;
end


%*************************************************************************
%these are the defaults for adding a new subject
%*************************************************************************
function set_subjectdefaults(h)
    h.edit_subjectid.Value = '';
    h.edit_subjectpath.Value = '';
    h.dropdown_subjectgender.Value = 'female';
    h.dropdown_subjecthand.Value = 'right';
    h.spinner_subjectage.Value = 20;
    h.check_subjectstatus.Value = 1;

%*************************************************************************
function callback_newstudy(hObject, eventdata, h)

    EEGPath = study_GetEEGPath;

    %initialize a new study structure
    study.filename = [];
    study.name = [];
    study.description = [];
    study.path = [];
    study.nfactors = 0;
    study.nsubjects = 0;
    study.nconditions = 0;
    study.history = [];
    study.subject = []

    %get the path indicating the location of subject folders
    selpath = uigetdir(EEGPath, 'Select parent folder for subject data');
    if selpath == 0
        return
    end
    i = strfind(selpath, EEGPath);
    selpath = selpath(i+length(EEGPath):length(selpath));    
    study.path = selpath;
    
    %save the new study
    [study, saved_flag] = study_SaveStudy(study, 'saveas', 1);
   
    if ~saved_flag
        populate_studylist(h, study.name)
    end
    
%**************************************************************************
%plot the data from different file formats
function callback_trialplot(hObject, eventdata, h)

study = getstudy(h);
if isempty(study)
    return
end

files = getselectedfiles(study, h);
if isempty(files)
    uialert(h.figure, 'Please select files to plot', 'Plotting');
    return
end

h.figure.Pointer = 'watch';
%check the first file to see what type it is
try
    [~, ~, ext] = fileparts(files{1});
    switch ext
        case '.cnt' %continuous data plotting
            study_PlotCNT(study, files)
        case '.epc' %epoched time series data plotting
            study_PlotEPC(study, files);
        case '.GND' %averaged subject and grand average data
            study_PlotERP(study, files);
        otherwise
            uialert(h.figure, 'Other files types are not supported, but I am working on it!', 'Plot Data');
            return
    end
catch ME
    h.figure.Pointer = 'arrow';
    rethrow(ME)
end
h.figure.Pointer = 'arrow';

%**************************************************************************
%returns the files selected in the main file list
function [filelist, n_uniquefiles] = getselectedfiles(study,h, stacked)


if nargin < 3
    stacked = 0;
end

eeg_path = study_GetEEGPath;
n = h.tree_filetree.SelectedNodes;

filelist = [];

%make sure something is selected
if isempty(n)
    uialert(h.figure, 'Please select files to process from the main file window.', 'Select Files');
    return
end

%get the names of the files to select
fnames = {n.NodeData};

%if there are actually no files selected
if sum(cellfun(@isempty,fnames)) == length(fnames)
    uialert(h.figure, 'You may have selected a category rather than an actual file. Please expand the category to find the files', 'Select Files')
    return
end


[~,~,fext] = fileparts(fnames{1});
cntr = 0;
n_uniquefiles = 0;

%this is an average file not stored in the subject folders
if contains(fext,'.GND')
    for jj = 1:length(fnames)
        temp = wwu_buildpath(eeg_path, study.path, 'across subject', fnames{jj});
        if exist(temp, 'file') > 0
            cntr = cntr + 1;
            filelist{cntr} = temp;
        end
    end
else

for ii = 1:study.nsubjects
    for jj = 1:length(fnames)
        temp = wwu_buildpath(eeg_path, study.path,  study.subject(ii).path, fnames{jj});
        if (exist(temp)>0)
            cntr = cntr + 1;
            if stacked
                filelist{jj,ii} = temp;
            else
                filelist{cntr} = temp;
            end
        end
    end
end
end
if isempty(filelist)
    uialert(h.figure, 'None of the selected items are valid files.', 'Select Files');
end

%**************************************************************************
%convert BIOSEMI to EEGLAB - right now this is the only conversion
%available
function callback_convert(hObject, eventdata, h)

eeg_path = study_GetEEGPath;
study = getstudy(h);

if study.nsubjects < 1
    msgbox('No subjects are listed in your study','Conversion Error', 'error');
    return
end

fnames = getselectedfiles(study,h);

if isempty(fnames)
    msgbox('No valid files to convert','Conversion Error', 'error');
    return
end
%check to make sure the file type appears to be correct
[~,~,fext] = fileparts(fnames{1});
if ~strcmp(fext, '.bdf')
    uialert(h.figure, 'The selected files don not appear to be in Biosemi bdf format','Convert from Biosemi');
    return;
end
start = clock;
wwu_Biosemi2EEGLab(fnames,'Chanlocs', study.chanlocs, 'AvgRef', 0, 'ApplyFilt', 0, 'Lpass', 0, 'Hpass', 0, 'OWrite', 2, 'FileExt', '.cnt', 'FigHandle', h.figure);

study = study_AddHistory(study, 'start', start, 'finish', clock,'event', 'Conversion to EEGLAB format', 'function', 'wwu_Biosemi2EEGLab', 'paramstring', fnames, 'fileID', '.cnt');
study = study_SaveStudy(study);
setstudy(study,h);
populate_studyinfo(study, h)
%**************************************************************************
function callback_resample(hObject, eventdata, h)

study = getstudy(h);
fnames = getselectedfiles(study, h);

if isempty(fnames); return; end

fh = study_Resample_GUI(study, fnames);
waitfor(fh);

callback_refresh(hObject, eventdata, h)

%***************************************************************************
function callback_filter(hObject, eventdata, h)

study = getstudy(h);
fnames = getselectedfiles(study, h);

if isempty(fnames); return; end;

fh = study_Filter_GUI(study, fnames);
waitfor(fh);

callback_refresh(hObject, eventdata, h)


%**************************************************************************
function callback_reref(hObject, eventdata, h)

file_id = '_ref';
option = 0;
study = getstudy(h);
fnames = getselectedfiles(study, h);

if isempty(fnames)
    uialert(h.figure, 'Select files to average reference.');
    return
end

start = clock;
%include a progress bar for this process
pb = uiprogressdlg(h.figure, 'Title','Average reference');
pb.Message = sprintf('Applying Average to all participants');

for ii = 1:length(fnames)
    
    [path, file, ext] = fileparts(fnames{ii});
    [file_id, option, writeflag] = wwu_verifySaveFile(path, file, file_id, ext, option);
    if option == 3 && ~writeflag
        fprintf('skipping existing file...\n')
        continue;
    else
        newfile = [file, file_id];
    end
 %   EEG = pop_loadset('filename', [file, ext], 'filepath', path);
    EEG = wwu_LoadEEGFile(fnames{ii});
    EEG = pop_reref(EEG, []);
    wwu_SaveEEGFile(EEG, fullfile(path, [newfile, ext]));
 %   EEG = pop_saveset(EEG, 'filename', newfile, 'filepath', path, 'savemode', 'onefile');
 %   movefile(fullfile(path, [newfile, '.set']), fullfile(path, [newfile, ext]));
    pb.Value = ii/length(fnames);
end


study = study_AddHistory(study, 'start', start, 'finish', clock,'event', 'Average Reference', 'function', 'callback_reref', 'paramstring', fnames, 'fileID',file_id);
study = study_SaveStudy(study);
setstudy(study,h);

close(pb);

%update the list of files now
populate_filelist(study, h)
populate_studyinfo(study,h)

%*************************************************************************
function callback_cleanline(hObject, eventdata, h)

study = getstudy(h);
fnames = getselectedfiles(study, h);
file_id = '_line';
option = 0;

if isempty(fnames)
    uialert(h.figure, 'Select files to clean.');
    return
end
start  = clock;
%include a progress bar for this process
pb = uiprogressdlg(h.figure, 'Title','Reducing 60 Hz noise.');
pb.Message = sprintf('Cleaning all participants. This could take a while.');

for ii = 1:length(fnames)
    
    [path, file, ext] = fileparts(fnames{ii});
    [file_id, option, writeflag] = wwu_verifySaveFile(path, file, file_id, ext, option);
    if option == 3 && ~writeflag
        fprintf('skipping existing file...\n')
        continue;
    else
        newfile = [file, file_id, ext];
    end

    EEG = wwu_LoadEEGFile(fnames{ii});
    %use the clealine function with the EEGLAB defaults
    EEG = pop_cleanline(EEG, 'bandwidth',2,'chanlist',1:EEG.nbchan ,'computepower',1,'linefreqs',60,'newversion',0,'normSpectrum',0,'p',0.01,'pad',2,'plotfigures',0,'scanforlines',0,'sigtype','Channels','taperbandwidth',2,'tau',100,'verb',1,'winsize',4,'winstep',1);
    wwu_SaveEEGFile(EEG, fullfile(path, newfile));
    pb.Value = ii/length(fnames);
end

study = study_AddHistory(study, 'start', start, 'finish', clock,'event', 'Clean 60 Hz noise', 'function', 'callback_cleanline', 'paramstring', fnames, 'fileID', file_id);
study = study_SaveStudy(study);
setstudy(study,h);

close(pb);

%update the list of files now
populate_filelist(study, h)
populate_studyinfo(study, h)
%**************************************************************************
%extract epochs and save files to the disk based on the epoch group
%information in the study
function callback_extract(hObject, eventdata, h)

study = getstudy(h);
if isempty(study); return; end

if ~isfield(study, 'bingroup')
    uialert(h.figure, 'Please create an Bin Group that contains epoch extraction information.', 'Create Epoch files');
    return
end

n = h.tree_bingrouplist.SelectedNodes;
if isempty(n)
     uialert(h.figure, 'Please select an Epoch Group first.', 'Create Epoch files');   
     return
end

gnum = n.NodeData{1};
cnum = n.NodeData{2};


selfiles = getselectedfiles(study, h);

if isempty(selfiles)
    uialert(h.figure, 'Please select the file(s) from which to create epochs.', 'Create Epoch files');
    return
end

if cnum==0 && length(study.bingroup(gnum).bins) > 0
    cnum = 1:length(study.bingroup(gnum).bins);
    fprintf('Extracting all %i conditions in %s.', length(cnum), study.bingroup(gnum).name);
else
    uialert(h.figure, 'There is no Bin information in the Bin Group', 'Extract Error');
    return
end

%create a temporary bin list file
bin_list_file = fullfile(wwu_buildpath(study_GetEEGPath, study.path), 'bin_list_file.txt');
f = fopen(bin_list_file, 'w');
if f==-1
    uialert(h.figure, 'Error creating temporary bin file', 'Extract Epochs');
    return
end

%combine the events from the differnt bins since the routine wants to have
%themn in a single vector.
events = [];
for ii = 1:length(study.bingroup(gnum).bins)
    fprintf(f, '%i) %s=%s\n', ii, study.bingroup(gnum).bins(ii).events{1}, study.bingroup(gnum).bins(ii).name);
    events = strcat(events,{' '}, study.bingroup(gnum).bins(ii).events);
end

fclose(f);

pg = uiprogressdlg(h.figure,...
    'Message','Extracting Epochs',...
    'Title', 'Create Epoch files',...
    'Indeterminate', 'on');

start = clock;
eb = [];
cond = study.bingroup(gnum);
[status, eb] = study_ExtractEpochs(selfiles, 'Outfile', cond.filename, 'Events', events, ...
        'EpochStart', cond.interval(1), 'EpochEnd', cond.interval(2), 'Overwrite', 2,...
        'FileExt', '.epc', 'FigHandle', h.figure, 'ExcludeBad', eb, 'BinFile', bin_list_file);
   
%now apply the bin information
close(pg);

study = study_AddHistory(study, 'start', start, 'finish', clock,'event', 'Epoching', 'function', 'study_ExtractEpochs', 'paramstring', selfiles, 'fileID', '.epc');
study = study_SaveStudy(study);
setstudy(study,h);

populate_filelist(study, h)
populate_studyinfo(study,h)
%*************************************************************************
function callback_reject(hObject, eventdata,h)
study = getstudy(h);
filenames = getselectedfiles(study, h);

if isempty(filenames)
    return
end
study_TrialReject(filenames);
%**********************************************************************
%callback_runscript 
%       allows user to run a custom script
%       script should acces the study structure and a list of files to work
%       on.  
%       the function should make any necessary changes to the study
%       structure and save it to the disk. It will be reloaded upon
%       completion
%
function callback_runscript(hObject, eventdata, h)

study = getstudy(h);
if isempty(study); return; end

filelist = getselectedfiles(study, h);
if isempty(filelist); return; end
fh = study_RunScript(study, filelist);
waitfor(fh);
callback_loadstudy(hObject, eventdata, h)
%*************************************************************************
function callback_evtsummary(hObject, event, h)
    study = getstudy(h);
    filelist = getselectedfiles(study, h);
    if isempty(filelist); return; end
    [~,~,ext] = fileparts(filelist{1})
    if ~strcmp(ext, '.cnt') && ~strcmpi(ext, '.epc');
        uialert(h.figure, 'Event summaries are available only for continuous (.cnt) and epoch (.epc) filetypes', 'Event Summary');
        return
    end
    study_eventsummary_GUI(study, filelist);
%*************************************************************************
function callback_interpchans(hObject, eventdata, h)

study = getstudy(h);
stime = clock;
option = 0;
file_id = '_rchan';
selfiles = getselectedfiles(study, h);
if isempty(selfiles)
    uialert(h.figure, 'Please select the file(s) from which to remove bad channels.', 'Remove bad channels');
    return
end
pb = uiprogressdlg(h.figure,'Message', 'Removing bad channels', 'Value',0,'Title','Interpolate bad channels');
maxpbVal= length(selfiles) * 4;
curpbVal = 0;
for ii = 1:length(selfiles)

    curpbVal = curpbVal + 1;
    pb.Message = 'building output filename...';
    pb.Value = curpbVal/maxpbVal;

    [path, file, ext] = fileparts(selfiles{ii});
    [file_id, option,writeflag] = wwu_verifySaveFile(path, file, file_id, ext, option);
    if option == 3 && ~writeflag
        fprintf('skipping existing file...\n');
        continue;
    else
        outfilename = fullfile(path,[file, file_id, ext]);
    end

    curpbVal = curpbVal + 1;
    pb.Message = 'loading subject data...';
    pb.Value = curpbVal/maxpbVal;

    EEG = wwu_LoadEEGFile(selfiles{ii});

    curpbVal = curpbVal + 1;
    pb.Message = 'finding and interpolating bad channels...';
    pb.Value = curpbVal/maxpbVal;

    if ~isfield(EEG.chaninfo, 'badchans') || sum(EEG.chaninfo.badchans)==0
        fprintf('No bad channels found for subject #%i\n', ii)
   
    else
        bchans = EEG.chaninfo.badchans;
        ch_names = join({EEG.chanlocs(find(bchans)).labels});
        fprintf('Removing channels\n%s.\n', ch_names{1});
        EEG = eeg_interp(EEG, find(bchans));
        EEG.chaninfo.badchans(:) = 0;
    end
    curpbVal = curpbVal + 1;
    pb.Message = 'saving data...';
    pb.Value = curpbVal/maxpbVal;
    wwu_SaveEEGFile(EEG, outfilename);
end
study_AddHistory(study, 'start', stime, 'finish', clock, 'event', 'Removed bad channels', 'paramstring', selfiles);
populate_filelist(study, h);
 
%*************************************************************************
function callback_computetf(hObject, event, h)
    study = getstudy(h);
    filelist = getselectedfiles(study, h);
    if isempty(filelist); return; end
    
    fh = study_TF_GUI(study, fnames);
    waitfor(fh);
 
end

% classifies ICA components for use in noice reduction
function callback_classifyICA(hObject, event, h)
    
    study = getstudy(h);
    filelist = getselectedfiles(study, h);
    if isempty(filelist); return; end
    
    study_ClassifyICA(filelist, 'WindowHandle', h.figure);
%**************************************************************************
%provides an in depth GUI for reviewing ICA's and their classificaiton.
%The focus is on identifying ICA's for removal, not for using ICA's for
%data analysis
function callback_inspectICA(hObject, event, h)
    
    study = getstudy(h);
    filelist = getselectedfiles(study, h);
    if isempty(filelist); return; end
    
    study_ICAClassInspect(study, filelist);
%************************************************************************** 
%reject labelled components
function callback_rejectICA(hObject, event,h)
    study = getstudy(h);
    filelist = getselectedfiles(study, h);
    if isempty(filelist); return; end
    
    study_RejectIC(filelist,[]);
%**************************************************************************
function callback_ICA(hObject, eventdata,h)
study = getstudy(h);
if isempty(study); return; end

files = getselectedfiles(study, h);
start = clock;
study_ICA_GUI(files);

study = study_AddHistory(study, 'start', start, 'finish', clock,'event', 'ICA decomposition', 'function', 'callback_ICA', 'paramstring', files, 'fileID', '');
study = study_SaveStudy(study);
setstudy(study,h);
populate_filelist(study, h)
populate_studyinfo(study,h)
%**************************************************************************
function callback_average(hObject, eventdata, h)
    study = getstudy(h);
    if isempty(study); return; end
    
    files = getselectedfiles(study, h, 1); %get the stacked list of files so we can handle them separately if necessary
    
    [n_rows, n_cols] = size(files);
     for ii = n_rows
        for jj = n_cols
            [~,~,fext] = fileparts(files{ii,jj});
            if ~strcmp('.epc', fext)
                uialert(h.figure, 'Only epoched data with a .epc extension can be averaged.', 'ERP Average');
                return
            end
        end
     end
    fh = study_Averager_GUI(study, files);    
    waitfor(fh);
    populate_filelist(study, h);
%**************************************************************************
function callback_exit(hObject, eventdata, h)
close(h.figure)
%*************************************************************************\
%resave study to the UserData of the figure
function setstudy(study, h)
set(h.figure, 'UserData', study);
%*************************************************************************
%get the study from the UserData of the figure
function study = getstudy(h)
study = get(h.figure, 'UserData');
if isempty(study);
    msgbox('Error.  No study information is available');
    return
end
%*************************************************************************
