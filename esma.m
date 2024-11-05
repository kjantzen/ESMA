%esma() -   EEG study management and analysis
%               main user interface for the Human Cognition and Neural
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

function esma()

%version number is major.minor
%major revision indicates the addition of a new major function or a change
%that may impact people using previous version.
%Minor revisions indicate a bug fix or addition/expansion of a minor feature.
VersionNumber = '1.2.1';
fprintf('Starting EEG Study Management and Analysis V%s....\n', VersionNumber);

try
    addSubFolderPaths
catch me
    wwu_msgdlg(me.message, 'Fatal Error!', {"OK"}, 'isError', true);  
    return
end

EEGPath = study_GetEEGPath;
if isempty(EEGPath)
    Message = sprintf('No valid experiment path was identified.\nPlease restart ESMA and identify a your experiment folder when prompted');
    Title = 'Missing path file';
    options = {"OK"}; 
    wwu_msgdlg(Message, Title, options, 'isError', true);
    return
end

fprintf('...building GUI\n');

scheme = eeg_LoadScheme;

%size of the figure
W = 400; H = 500;
FIGPOS = [0,(scheme.ScreenHeight-H), W, H];
VERSION = ['ESMA', VersionNumber];

%restart the display if it is already loaded
existingFigure = findall(groot,'Type', 'Figure', 'Tag', VERSION);
if ~isempty(existingFigure)
    handles.figure = existingFigure;
    clf(handles.figure);
    fprintf('hcnd_eeg is already running.  Reinitialiing display\n');
else    
    %setup the main figure window
    handles.figure = uifigure;
end


set(handles.figure,...
    'Color', scheme.Window.BackgroundColor.Value, ...
    'name', sprintf('EEG Study Management and Analysis V%s', VersionNumber),...
    'NumberTitle', 'off',...
    'Position', FIGPOS,...
    'Resize', 'off',...
    'menubar', 'none',...
    'Tag', VERSION);

msg = uiprogressdlg(handles.figure, 'Message', 'Building GUI', 'Cancelable',false);
drawnow

handles.dropdown_study = uidropdown(...
    'Parent', handles.figure,...
    'Position', [10,H-30,W-20,scheme.Dropdown.Height.Value],...
    'Editable', 'off',...
    'BackgroundColor', scheme.Dropdown.BackgroundColor.Value,...
    'FontColor', scheme.Dropdown.FontColor.Value,...
    'FontName', scheme.Dropdown.Font.Value,...
    'FontSize', scheme.Dropdown.FontSize.Value);

handles.tree_filetree = uitree(...
    'Parent', handles.figure,...
    'Multiselect', 'on',...
    'Editable', 'off',...
    'Position', [10,H-260,W-20,225],...
    'BackgroundColor', scheme.Edit.BackgroundColor.Value,...
    'FontColor', scheme.Edit.FontColor.Value,...
    'FontName', scheme.Edit.Font.Value,...
    'FontSize', scheme.Edit.FontSize.Value);

handles.panel_info = uipanel(...
    'Parent', handles.figure,...
    'Title','Study Information', ...
    'BackgroundColor', scheme.Panel.BackgroundColor.Value,...
    'FontName', scheme.Panel.Font.Value,...
    'FontSize', scheme.Panel.FontSize.Value,...
    'ForegroundColor', scheme.Panel.FontColor.Value,...
    'HighlightColor', scheme.Panel.BorderColor.Value,...
    'BorderType', 'line',...
    'Position',[10,H-490, W-20,225]);

handles.label_info = uihtml(handles.panel_info,...
    'Position', [10,10,W-40,190],...
    'UserData', scheme.Panel.FontColor.Value);

msg.Message = 'Creating menus';
drawnow

%ESMA menu
list = getSchemeList();
handles.menu_esma = uimenu('Parent', handles.figure,'Label', 'ESMA');
handles.menu_datapath = uimenu(handles.menu_esma, 'Label', 'Change data path');
handles.menu_appearance = uimenu(handles.menu_esma, 'Label', 'Appearance');
handles.menu_editappeanace = uimenu(handles.menu_appearance, 'Label', 'Edit appearance');
handles.menu_scheme = uimenu(handles.menu_appearance, 'Label', 'Themes');
for ii = 1:length(list)
    [~,themeName,~] = fileparts(list(ii).name);
    handles.menu_selScheme(ii) = uimenu('Parent', handles.menu_scheme, 'Label',themeName,...
        'UserData', fullfile(list(ii).folder, list(ii).name),...
        'Callback', {@callback_changeScheme});
end
handles.menu_exit = uimenu(handles.menu_esma, 'Label', 'Quit', 'Separator', 'on', 'callback', {@callback_exit, handles});

%Study menu
handles.menu_study = uimenu('Parent', handles.figure,'Label', '&Study', 'Accelerator', 's');
handles.menu_new = uimenu(handles.menu_study, 'Label', '&New Study', 'Accelerator', 'n');
handles.menu_edit = uimenu(handles.menu_study, 'Label', '&Edit Study', 'Accelerator', 'e');
handles.menu_refresh = uimenu(handles.menu_study, 'Label', '&Refresh Study List', 'Accelerator', 'r');
handles.menu_deletestudy = uimenu(handles.menu_study, 'Label', 'Delete Study', 'Separator', 'on');
handles.menu_archivestudy = uimenu(handles.menu_study, 'Label', 'Archive Study');

%files menu
handles.menu_file = uimenu('Parent', handles.figure,'Label', '&File', 'Accelerator', 'f');
handles.menu_renamefiles = uimenu(handles.menu_file, 'Label', '&Rename');
handles.menu_deletefiles = uimenu(handles.menu_file, 'Label', '&Delete','Accelerator', 'd');
handles.menu_exportfiles = uimenu(handles.menu_file, 'Label', 'Export to eeglab', 'Separator', 'on');

%plotting menu
handles.menu_plot = uimenu('Parent', handles.figure, 'Label', '&Plot', 'Accelerator', 'p');
handles.menu_trialplot = uimenu(handles.menu_plot, 'Label', 'Plot and Review Data');

%preprocess menu
handles.menu_preprocess = uimenu('Parent', handles.figure, 'Label', 'Preprocess');
handles.menu_resample = uimenu('Parent', handles.menu_preprocess, 'Label', 'Resample');
handles.menu_filter = uimenu('Parent', handles.menu_preprocess, 'Label', 'Filter');
handles.menu_rbadtimes = uimenu('Parent', handles.menu_preprocess, 'Label', 'Remove bad time segments');
handles.menu_rbadchans = uimenu('Parent', handles.menu_preprocess, 'Label', 'Remove bad channels');
handles.menu_reref = uimenu('Parent', handles.menu_preprocess, 'Label', 'Average reference');
handles.menu_cleanline = uimenu('Parent', handles.menu_preprocess, 'Label', 'Reduce line noise');
handles.menu_extractepochs = uimenu('Parent', handles.menu_preprocess, 'Label', 'Create epoched files', 'Separator', 'on');
handles.menu_markbadtrials = uimenu('Parent', handles.menu_preprocess, 'Label', 'Automatically mark bad tials');
handles.menu_computetf = uimenu('Parent', handles.menu_preprocess, 'Label', 'Compute ERSP', 'Separator', 'on');


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
handles.menu_filesummary = uimenu(handles.menu_utils, 'Label', 'Show File Information');
handles.menu_evtsummary = uimenu(handles.menu_utils, 'Label', 'Event Summary');

%assign all the callbacks
set(handles.menu_datapath, 'Callback', @callback_editdatapath)
set(handles.menu_editappeanace, 'Callback', {@callback_editscheme, handles});

set(handles.dropdown_study, 'ValueChangedFcn', {@callback_loadstudy, handles});
set(handles.menu_new, 'Callback', {@callback_newstudy, handles, false});
set(handles.menu_edit, 'Callback', {@callback_newstudy, handles, true});
set(handles.menu_refresh, 'Callback', {@callback_refresh, handles});
set(handles.menu_deletestudy, 'Callback', {@callback_archivestudy, handles, true});
set(handles.menu_archivestudy, 'Callback', {@callback_archivestudy, handles, false});

set(handles.menu_exit, 'Callback', {@callback_exit, handles});
set(handles.menu_script, 'Callback', {@callback_runscript, handles});
set(handles.menu_filesummary, 'Callback', {@callback_filesummary, handles})
set(handles.menu_evtsummary, 'Callback', {@callback_evtsummary, handles});
set(handles.menu_trialplot, 'Callback', {@callback_trialplot, handles});
set(handles.menu_deletefiles, 'Callback', {@callback_deletefiles, handles});
set(handles.menu_renamefiles, 'Callback', {@callback_changeFilenames, handles});
set(handles.menu_exportfiles, 'Callback', {@callback_exportfiles, handles});
set(handles.menu_rbadtimes, 'Callback', {@callback_removeDataSegments, handles});
set(handles.menu_rbadchans, 'Callback', {@callback_interpchans, handles});
set(handles.menu_resample, 'Callback', {@callback_resample, handles});
set(handles.menu_filter, 'Callback', {@callback_filter, handles});
set(handles.menu_reref, 'Callback', {@callback_reref, handles});
set(handles.menu_cleanline, 'Callback', {@callback_cleanline, handles});
set(handles.menu_extractepochs , 'Callback', {@callback_extract, handles});
set(handles.menu_markbadtrials, 'Callback', {@callback_reject, handles});
set(handles.menu_computetf, 'Callback', {@callback_computeersp, handles});

set(handles.menu_ica, 'Callback', {@callback_ICA, handles});
set(handles.menu_classify, 'Callback', {@callback_classifyICA, handles});
set(handles.menu_icainspect, 'Callback', {@callback_inspectICA, handles});
set(handles.menu_icareject, 'Callback', {@callback_rejectICA, handles});
set(handles.menu_erpave, 'Callback', {@callback_average, handles});
set(handles.menu_icacopy, 'Callback', {@callback_copypastecomponents, handles});
set(handles.menu_icapaste, 'Callback', {@callback_copypastecomponents, handles});

set(handles.menu_convert, 'Callback', {@callback_convert,handles});

msg.Message = 'Loading studies';
fprintf('...reading STUDY information');

%placeholder for the number of studies
n = 0;

%keep asking for a path untill studies are found
n = populate_studylist(handles);
fprintf("...found %i Studies...\n", n)

msg.Message = 'Loading current study and populating GUI';
fprintf('...loading current study and populating GUI\n');
callback_loadstudy(0,0,handles)

msg.Message = 'OK, all done. Have fun!';
fprintf('...done\n');
pause(1);
close(msg);

%%
%Start of function definitions
%**************************************************************************
function callback_copypastecomponents(hObject, event, h)

study = getstudy(h);
if study.nsubjects < 1
    uialert(h.figure, 'No subjects are listed in your study','Conversion Error');
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
            sourceEEG = wwu_LoadEEGFile(copy_info.flist{ii});
            
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

%**************************************************************************
function callback_changeFilenames(hObject, event, h)

    study = getstudy(h);
    filestorename = getselectedfiles(study, h, true);
    if isempty(filestorename)
        return
    end
    
    tic
    parameters.operation = {'Operation', 'Rename files'};
    parameters.date = datetime('now');

    dims = size(filestorename);
    if dims(1) > 1 && dims(2) > 1
        uialert(h.figure, 'You cannot change more than one filename at a time.  Please select only a single file entry', 'Ooops!');
        return
    end
    nFiles = length(filestorename);
    columnName = {'New Filename'};
    reportValues = cell(nFiles, 1);

    if ~isempty(filestorename)
        cfg.msg = 'Enter a new name for the files. Do not include the file path or extension.';
        cfg.title = 'Rename files';
        cfg.options = {'Accept', 'Cancel'};
        [~,fname,~] = fileparts(filestorename{1});
        cfg.default = fname;
        try
            resp = wwu_inputdlg(cfg);
            if strcmp(resp.option, 'Accept') && ~isempty(resp.input)
                pb = uiprogressdlg(h.figure, "Cancelable","off", "icon", "info",...
                    'Message', 'Checking files for duplicates', 'Title', 'Rename Files', 'Value', 0);
                % check to see if there are already files with the selected
                % name 
                checking = true;
                while checking
                    newFile{nFiles} = [];
                    for ii = 1:nFiles
                        pb.Value = ii/nFiles;
                        [path, ~, ext] = fileparts(filestorename{ii});
                        newFile{ii} = fullfile(path, [resp.input, ext]);
                        if isfile(newFile{ii})
                            resp.input = [resp.input, '_1'];
                            break
                        end
                    end
                    checking = false;
                end
                %now loop through again and change the name
                pb.Message = sprintf('Renamining files to %s', resp.input);
                for ii = 1:nFiles
                    pb.Value = ii/nFiles;
                    movefile(filestorename{ii}, newFile{ii})
                    reportValues{ii} = newFile{ii};
                end
                parameters.duration = {'Duration', toc};
                wwu_UpdateProcessLog(study, "ColumnNames",columnName, ...
                    'RowNames',filestorename, 'Parameters',parameters,...
                    'Values',reportValues, 'SheetName','rename');
                close(pb);
                callback_refresh(hObject, event, h)

            else
                fprintf('User pressed Cancel or the filename was empty\n');
            end
        catch me
            uialert(h.figure, me.message, me.identifier);
            return;
        end
    end
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
%populates the study tree with all the studies found in the "STUDIES"
%folder
function nStudies = populate_studylist(h, selected_study)
%populate_study(handles, selectedStudy) populates the drop down study list
%with the names of the studies currently in the STUDIES folder.
%SelectedStudy is the name of the study to select and load once the list is
%filled.  If selectedStudy is not provided, the first study is selected by
%default.
if nargin < 2
    selected_study = [];
end

EEGPath = study_GetEEGPath;
STUDYPATH = fullfile(EEGPath, 'STUDIES');

h.figure.Pointer = 'watch';
d = dir([STUDYPATH, filesep,'*.study']);
studylist = cellfun(@(x) x(1:length(x)-6), {d.name}, 'UniformOutput', false);
studyinfo = cellfun(@(x,y) fullfile(x, y), {d.folder}, {d.name}, 'UniformOUtput', false);

nStudies = length(d);
studyNames = cell(1,nStudies);
for ii = 1:nStudies
    study = study_LoadStudy(studylist{ii});
    studyNames{ii} = study.name;
end

h.dropdown_study.Items = studyNames;
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
    populate_studyinfo([], h);
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
h.figure.Pointer = 'arrow';
%*************************************************************************
%puts all the study information into the display and edit controls on the
%main screen
function populate_studyinfo(study, h)


colorNum = rgb2hex(h.label_info.UserData);

if isempty(study)

    msg = ['<body style="font-family:arial;font-size:14px;color:#', num2str(colorNum),'"><p style="line-height:115%">', ...
        '<b>NO STUDIES FOUND IN CURRENT DATA FOLDER</b></p>'];
    msg = [msg, '<p style="line-height:115%">Please choose a different data folder or create a new study.</p>'];
    h.label_info.HTMLSource = msg;
    return
end    

if isempty(study.description)
    descr = {''};
else
    descr = study.description;
end


msg = ['<body style="font-family:arial;font-size:12px;color:#', num2str(colorNum),'"><p style="line-height:115%"><b>Study:</b>',...
     '<span style=padding-left:40>',study.name,'</span></p>'];
msg = [msg,'<p style="line-height:115%"><b>Folder:</b>',...
     '<span style=padding-left:37>',study.path,'</span></p>'];
msg = [msg,'<p style="line-height:115%"><b>Subjects:</b>',...
     '<span style=padding-left:28>',num2str(study.nsubjects),'</span></p>'];
msg = [msg,'<p style="line-height:115%"><b>Description:</b></span></p>'];
for ii = 1:length(descr)
    msg = [msg,'<p style="line-height:115%; padding-left: 20">',descr{ii},'</span></p>'];
end

h.label_info.HTMLSource = msg;


%*************************************************************************
%load all the information into the file tree
%**************************************************************************
function populate_filelist(study, h)

EEGPath = study_GetEEGPath;
flist = [];
for ii = 1:study.nsubjects
    searchpath = eeg_BuildPath(EEGPath, study.path, study.subject(ii).path, '*.*');
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

FileTypes = {'Biosemi Files', 'Continuous EEG', 'Epoched Trial Data', 'ERP (Average)', 'ERSP (Average)', 'EEGLab Files', 'Other'};
Included_Extensions = {'.bdf', '.cnt', '.epc', '.GND', '.ersp', '.set'};
Excluded_Extensions = {'.fdt'};
Acrosssubj_Extensions = {'.GND', '.ersp'};

%clear the existing list of files
n = h.tree_filetree.Children;
n.delete;

Nodes = [];
for ii = 1:length(FileTypes)
    Nodes(ii).Node = uitreenode(h.tree_filetree, 'Text', FileTypes{ii});
    Nodes(ii).Node.Tag = 'uneditable';
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
    [~,fNameOnly,~] = fileparts(flist(ii).name);
    node_name = sprintf('(%i)\t%s', flist(ii).count,fNameOnly);
    uitreenode(Nodes(category).Node,'Text', node_name, 'NodeData', flist(ii).name, 'Tag', 'editable');
end

%now get the average files from the across subect folder
searchpath = eeg_BuildPath(EEGPath, study.path, 'across subject');

if ~exist(searchpath, 'dir')
    return
else
    for ee = 1:length(Acrosssubj_Extensions)
        flist = dir(fullfile(searchpath,filesep, ['*',Acrosssubj_Extensions{ee}]));
        for ii = 1:length(flist)
            
            [~,fname,ext] = fileparts(flist(ii).name);
        
             category = find(strcmp(Included_Extensions,Acrosssubj_Extensions{ee}));
             if isempty(category); category = length(FileTypes); end
             [~,fNameOnly,~] = fileparts(flist(ii).name);
             node_name = sprintf('(%i)\t%s', 1 ,fNameOnly);
             uitreenode(Nodes(category).Node,'Text', node_name, 'NodeData', flist(ii).name, 'Tag', 'editable');
             
        end
    end
end


%*************************************************************************
function callback_newstudy(hObject, eventdata, h, editMode)

   
    study = getstudy(h);
    
    if isempty(study)
        editMode = false;
    else
        currentStudy = study.name;
        oldStudies = h.dropdown_study.Items;
    end
    
    if editMode
        fh = study_EditStudy(study);
        waitfor(fh);
        populate_studylist(h, currentStudy);
    else
        fh = study_EditStudy();
        waitfor(fh);
        populate_studylist(h);
        
        newStudies = h.dropdown_study.Items;
    
        c = setdiff(newStudies, oldStudies);
    
        if isempty(c)
            populate_studylist(h, currentStudy)
        else
            populate_studylist(h, c{1});
        end
    end

%**************************************************************************
function callback_archivestudy(hObject, event, h, deleteStudy)
  
    study = getstudy(h);
    EEGPath = study_GetEEGPath();

    if deleteStudy
        msg = sprintf('This action will permanantly delete "%s"! ', study.name);
        title = 'Delete Study';
    else
        msg = sprintf('This action will move "%s" to the archive folder!  ', study.name);
        title = 'Archive Study';
    end
    msg = [msg, 'Are you sure you want to continue?'];

    response = uiconfirm(h.figure, msg, title,'Options', {'Yes', 'No'}, 'CancelOption','No');

    if contains(response, 'Yes')
        file = fullfile(EEGPath, 'STUDIES', [study.name, '.study']);
        f = dir(file);
        if isempty(f)
            uialert(h.figure, sprintf('%s was not found on the disk',file), 'Error')
            return
        end
        if deleteStudy
            delete(file);
        else
            archiveFolder = fullfile(EEGPath, 'STUDIES', 'ARCHIVE');
            if ~isfolder(archiveFolder)
                status = mkdir(archiveFolder);
                if ~status
                    uialert('Failed to create the ARCHIVE folder');
                    return
                end
            end
           status = movefile(file, archiveFolder);
           if ~status
               uialert('File failed to move.  You may want to move it manually')
               return
           end
        end
        
        populate_studylist(h);
       
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
        case '.ersp'
            study_PlotERSP(study, files);
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
if contains(fext,'.GND') || contains(fext, '.ersp')
    for jj = 1:length(fnames)
        temp = eeg_BuildPath(eeg_path, study.path, 'across subject', fnames{jj});
        if exist(temp, 'file') > 0
            cntr = cntr + 1;
            filelist{cntr} = temp;
        end
    end
else

for ii = 1:study.nsubjects
    for jj = 1:length(fnames)
        temp = eeg_BuildPath(eeg_path, study.path,  study.subject(ii).path, fnames{jj});
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
    uialtert(h.figure, 'No subjects are listed in your study','Conversion Error');
    return
end

fnames = getselectedfiles(study,h);
if isempty(fnames)
    return
end
if ~eeg_ValidateFileTypes(fnames, {'bdf'})
    msg = 'This conversion can only be completed on BIOSEMI files.';
    title = 'File Type Error';
    options ={'OK'};
    wwu_msgdlg(msg, title,options);
    return
end

tic
parameters.operation = {'Operation', 'Convert from biosemi format'};
parameters.date = {'Date and time', datetime('now')};
columnNames = {'Save output?', 'Output filename'};
start = clock;
reportValues = wwu_Biosemi2EEGLab(fnames,'Chanlocs', study.chanlocs, ...
    'AvgRef', 0, 'ApplyFilt', 0, 'Lpass', 0, 'Hpass', 0, 'OWrite', 2, ...
    'FileExt', '.cnt', 'FigHandle', h.figure);


parameters.duration = {'Duration', toc};
wwu_UpdateProcessLog(study, 'ColumnNames',columnNames, 'RowNames', fnames,...
    'SheetName','biosemi convert', 'Parameters',parameters, 'Values',reportValues);

study = study_AddHistory(study, 'start', start, 'finish', clock,'event', 'Conversion to EEGLAB format', 'function', 'wwu_Biosemi2EEGLab', 'paramstring', fnames, 'fileID', '.cnt');
study = study_SaveStudy(study);
setstudy(study,h);
populate_studyinfo(study, h)
callback_refresh(hObject, eventdata, h)

%**************************************************************************
function callback_resample(hObject, eventdata, h)

study = getstudy(h);
fnames = getselectedfiles(study, h);

if isempty(fnames); return; end
if ~eeg_ValidateFileTypes(fnames, {'cnt', 'epc'})
    msg = 'At least some of the selected files formats cannot be resampled using this function';
    title = 'File Type Error';
    options ={'OK'};
    wwu_msgdlg(msg, title, options);
    return
end

fh = study_Resample_GUI(study, fnames);
waitfor(fh);

callback_refresh(hObject, eventdata, h)

%***************************************************************************
function callback_filter(hObject, eventdata, h)

study = getstudy(h);
fnames = getselectedfiles(study, h);

if isempty(fnames); return; end
if ~eeg_ValidateFileTypes(fnames, {'cnt', 'epc'})
    msg = 'At least some of the selected files formats cannot be filtered using this function';
    title = 'File Type Error';
    options ={'OK'};
    wwu_msgdlg(msg, title, options);
    return
end

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
    return
end
if ~eeg_ValidateFileTypes(fnames, {'cnt', 'epc'})
    msg = 'At least some of the selected files formats cannot be rereferenced using this function';
    title = 'File Type Error';
    options ={'OK'};
    wwu_msgdlg(msg, title, options);
    return
end


parameters.operation = {'Operation', 'Average Reference'};
parameters.date = {'Date and time', datetime('now')};

tic
start = clock;
%include a progress bar for this process
pb = uiprogressdlg(h.figure, 'Title','Average reference');
pb.Message = sprintf('Applying Average to all participants');

reportColumnNames = {'Previous Reference','New Reference', 'New filename'};
reportValues = cell(length(fnames), length(reportColumnNames));

for ii = 1:length(fnames)
    [path, file, ext] = fileparts(fnames{ii});
    [file_id, option, writeflag] = wwu_verifySaveFile(path, file, file_id, ext, option);
    if option == 3 && ~writeflag
        fprintf('skipping existing file...\n')
        continue;
    else
        newfile = [file, file_id];
    end
    EEG = wwu_LoadEEGFile(fnames{ii});
    reportValues{ii,1} = EEG.ref;
    
    EEG = pop_reref(EEG, []);
    reportValues{ii,2} = EEG.ref;

    reportValues{ii,end} = [newfile,ext];
    wwu_SaveEEGFile(EEG, fullfile(path, [newfile, ext]));
    pb.Value = ii/length(fnames);
end

parameters.duration = {'Duration', toc};
wwu_UpdateProcessLog(study,"ColumnNames",reportColumnNames,...
    'Parameters',parameters,'RowNames',fnames,'SheetName','Rereference',...
    'Values',reportValues);
study = study_AddHistory(study, 'start', start, 'finish', clock,'event', 'Average Reference', 'function', 'callback_reref', 'paramstring', fnames, 'fileID',file_id);
study = study_SaveStudy(study);
setstudy(study,h);

close(pb);

%update the list of files now
callback_refresh(hObject, eventdata, h)
%populate_filelist(study, h)
%populate_studyinfo(study,h)

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
callback_refresh(hObject, eventdata, h)

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

info = study_SelectBinGroup(study);
if isempty(info.gnum) || contains(info.option, 'Cancel')
    return
end
gnum = info.gnum;
cnum = info.cnum;

selfiles = getselectedfiles(study, h);

if isempty(selfiles)
    uialert(h.figure, 'Please select the file(s) from which to create epochs.', 'Create Epoch files');
    return
end

if cnum==0 && length(study.bingroup(gnum).bins) > 0
    cnum = 1:length(study.bingroup(gnum).bins);
    fprintf('Extracting all %i conditions in %s.', length(cnum), study.bingroup(gnum).name);
else
    wwu_msgdlg('There is no Bin information in the Bin Group', 'Extract Error', {'OK'});
    return
end

%create a temporary bin list file
bin_list_file = fullfile(eeg_BuildPath(study_GetEEGPath, study.path), 'bin_list_file.txt');
f = fopen(bin_list_file, 'w');
if f==-1
    uialert(h.figure, 'Error creating temporary bin file', 'Extract Epochs');
    return
end

%combine the events from the differnt bins since the routine wants to have
%them in a single vector.
events = [];
for ii = 1:length(study.bingroup(gnum).bins)
    for jj = 1:length(study.bingroup(gnum).bins(ii).events)
        fprintf(f, '%i) %s=%s\n', ii, study.bingroup(gnum).bins(ii).events{jj}, study.bingroup(gnum).bins(ii).name);
        events = strcat(events,{' '}, study.bingroup(gnum).bins(ii).events{jj});
    end
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

callback_refresh(hObject, eventdata, h)

%populate_filelist(study, h)
%populate_studyinfo(study,h)
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
try
    fh = study_RunScript(study, filelist);
    waitfor(fh);
catch me
    uialert(h.figure, me.message, me.identifier);
    return
end
callback_loadstudy(hObject, eventdata, h)
%*************************************************************************
function callback_filesummary(~, ~, h)
    study = getstudy(h);
    filelist = getselectedfiles(study, h);
    study_DisplayFileInformation(study, filelist);

%*************************************************************************
function callback_evtsummary(hObject, event, h)
    study = getstudy(h);
    filelist = getselectedfiles(study, h);
    if isempty(filelist); return; end
    [~,~,ext] = fileparts(filelist{1});
    if ~strcmp(ext, '.cnt') && ~strcmpi(ext, '.epc');
        uialert(h.figure, 'Event summaries are available only for continuous (.cnt) and epoch (.epc) filetypes', 'Event Summary');
        return
    end
    study_eventsummary_GUI(study, filelist);
%*************************************************************************
function callback_interpchans(hObject, eventdata, h)
tic
parameters.Operation = {'Operation', 'Remove bad channels'};
parameters.date = {'Date and time', datetime("now");};

study = getstudy(h);
stime = clock;
option = 0;
file_id = '_rchan';
selfiles = getselectedfiles(study, h);
if isempty(selfiles)
    return
end
pb = uiprogressdlg(h.figure,'Message', 'Removing bad channels', 'Value',0,'Title','Remove bad channels');
maxpbVal= length(selfiles) * 4;
curpbVal = 0;
nFiles = length(selfiles);
reportData = cell(length(selfiles), 3);

for ii = 1:nFiles
    curpbVal = curpbVal + 1;
    pb.Message = 'building output filename...';
    pb.Value = curpbVal/maxpbVal;

    [path, file, ext] = fileparts(selfiles{ii});
    [file_id, option,writeflag] = wwu_verifySaveFile(path, file, file_id, ext, option);
    if option == 3 && ~writeflag
        fprintf('skipping existing file...\n');
        reportData{ii,3} = 'not saved';
        continue;
    else
        outfilename = fullfile(path,[file, file_id, ext]);
        reportData{ii,3} = outfilename;
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
        reportData{ii,1} = 0;
        reportData{ii,2} = 'none';
   
    else
        bchans = EEG.chaninfo.badchans;
        ch_names = join({EEG.chanlocs(find(bchans)).labels});
        fprintf('Removing channels\n%s.\n', ch_names{1});

        EEG = pop_select(EEG, 'rmchannel', find(bchans));
        EEG.chaninfo.badchans(:) = 0;
        reportData{ii,1} = sum(bchans);
        reportData{ii,2} = ch_names{1};
    end
    curpbVal = curpbVal + 1;
    pb.Message = 'saving data...';
    pb.Value = curpbVal/maxpbVal;
    fprintf('saving data file with %i channels to %s\n', EEG.nbchan, outfilename);
    wwu_SaveEEGFile(EEG, outfilename);
end
parameters.duration = {'Duration (seconds)', toc};

wwu_UpdateProcessLog(study,'SheetName', 'rem chans', ...
    'ColumnNames',{'# removed', 'Channels removed', 'Ouput File'},...
    'RowNames',selfiles, 'Values', reportData, 'Parameters',parameters)
study_AddHistory(study, 'start', stime, 'finish', clock, 'event', 'Removed bad channels', 'paramstring', selfiles);
populate_filelist(study, h);
msgbox("Note - removing channels may result in unequal channel numbers.  You should select interpolate missing channels when computing ERPs");

%*************************************************************************
function callback_removeDataSegments(~, ~, h)
    
tic
parameters.Operation = {'Operation', 'Remove continuous segments'};
parameters.date = {'Date and time', datetime("now");};
stime = datetime("now", "Format","HH:MM:SS");
study = getstudy(h);
option = 0;
file_id = '_rtime';
selfiles = getselectedfiles(study, h);
if isempty(selfiles)
    return
end
pb = uiprogressdlg(h.figure,'Message', 'Removing highlights time segments', 'Value',0,'Title','Remove segments');
maxpbVal= length(selfiles) * 4;
curpbVal = 0;
nFiles = length(selfiles);
reportData = cell(length(selfiles), 3);

%loop through each of the selected files
for ii = 1:nFiles
    curpbVal = curpbVal + 1;
    pb.Message = 'building output filename...';
    pb.Value = curpbVal/maxpbVal;

    [path, file, ext] = fileparts(selfiles{ii});
    [file_id, option,writeflag] = wwu_verifySaveFile(path, file, file_id, ext, option);
    if option == 3 && ~writeflag
        fprintf('skipping existing file...\n');
        reportData{ii,3} = 'not saved';
        continue;
    else
        outfilename = fullfile(path,[file, file_id, ext]);
        reportData{ii,3} = outfilename;
    end

    curpbVal = curpbVal + 1;
    pb.Message = 'loading subject data...';
    pb.Value = curpbVal/maxpbVal;

    EEG = wwu_LoadEEGFile(selfiles{ii});

    curpbVal = curpbVal + 1;
    pb.Message = 'finding and removing highlights time segments...';
    pb.Value = curpbVal/maxpbVal;

    %assume there is something to renmove
    segmentRemoved = true;
    if isfield(EEG, 'SelectedRects')
        if isfield(EEG.SelectedRects, 'XData') && ~isempty(EEG.SelectedRects(1).XData)
            rmTimes = [EEG.SelectedRects.XData];
            rmTimes = sort(rmTimes(1:2,:))';        
            EEG = pop_select(EEG,'rmtime',rmTimes);
            EEG.save = 'no';
            EEG.SelectedRects = [];
            reportData{ii,1} = size(rmTimes,1);
            reportData{ii,2} = join(cellstr(num2str(rmTimes)),';');

        else
            segmentRemoved = false;
        end
    else
        segmentRemoved = false;
    end

    if segmentRemoved == false
        fprintf("There were no selected segments to remove for subject %i.\n", ii);
        reportData{ii,1} = 0;
        reportData{ii,2} = 'none';
    end

    curpbVal = curpbVal + 1;
    pb.Message = 'saving data...';
    pb.Value = curpbVal/maxpbVal;
    fprintf('saving data file to %s\n', outfilename);
    wwu_SaveEEGFile(EEG, outfilename);
end
parameters.duration = {'Duration (seconds)', toc};

wwu_UpdateProcessLog(study,'SheetName', 'rem time', ...
    'ColumnNames',{'# removed', 'Time boundary', 'Ouput File'},...
    'RowNames',selfiles, 'Values', reportData, 'Parameters',parameters)
%study_AddHistory(study, 'start', stime, 'finish', clock, 'event', 'Removed time segments', 'paramstring', selfiles);
populate_filelist(study, h);



        
%*************************************************************************
function callback_computeersp(hObject, event, h)
    study = getstudy(h);
    filelist = getselectedfiles(study, h);
    if isempty(filelist);return;end
    

    [~,~,ext] = fileparts(filelist{1});
    if ~strcmpi(ext, '.epc')
        uialert(h.figure, 'ERSP is only available for epoch (.epc) filetypes', 'Compute ERSP ');
        return
    end

    fh = study_TF_GUI(study, filelist);
    waitfor(fh);
 

%*************************************************************************
% classifies ICA components using IClabel
function callback_classifyICA(hObject, event, h)
    
    study = getstudy(h);
    filelist = getselectedfiles(study, h);
    if isempty(filelist); return; end

    try
        study_ClassifyICA(filelist, 'WindowHandle', h.figure);
    catch me
        uialert(h.figure, me.message, me.identifier)
    end
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
    
    try
        fh = study_RejectIC(filelist,[]);
        waitfor(fh)
    catch me
        uialert(h.figure, me.message, me.identifier);
    end


%**************************************************************************
function callback_ICA(hObject, eventdata,h)
study = getstudy(h);
if isempty(study); return; end

files = getselectedfiles(study, h);
if ~isempty(files)
    
    start = clock;
    study_ICA_GUI(study, files);
    
    study = study_AddHistory(study, 'start', start, 'finish', clock,'event', 'ICA decomposition', 'function', 'callback_ICA', 'paramstring', files, 'fileID', '');
    study = study_SaveStudy(study);
    setstudy(study,h);
    populate_filelist(study, h)
    populate_studyinfo(study,h)
end
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
if isempty(study)
    warning('No study information is available');
    return
end
%*************************************************************************
%add paths to critical subfolders
function addSubFolderPaths()

    %check the path for esma
    esma_path = fileparts(mfilename('fullpath'));
    tfolder = fullfile(esma_path, 'config');
    if ~contains(path,tfolder)
        addpath(tfolder)
    end
    tfolder = fullfile(esma_path, 'functions');
    if ~contains(path,tfolder)
        addpath(tfolder)
    end
    tfolder = fullfile(esma_path, 'icons');
    if ~contains(path,tfolder)
        addpath(tfolder)
    end
    
    %checking for eeglab installation and path
    eeglabpath = which('eeglab.m');
    if isempty(eeglabpath)
        error('Could not find eeglab installation.  Please make sure eeglab is installed on this computer and is on the MATLAB path.');
    else
         [eeglabpath,~,~] = fileparts(eeglabpath);
    end
    
    %make sure all the necessary plugins are installed in EEGLAB 
    pluginsDir = fullfile(eeglabpath, 'plugins');
    d = dir(pluginsDir);
    if isempty(d)
        error('Could not find the EEGLAB plugins folder.  Please check your EEGLAB installation.');
    end
    d = [d.name];
    if ~contains(d, 'Biosig')
        error('Please make sure the Biosig plugin is installed via eeglab before continuing');
    end
    if ~contains(d, 'ICLabel')
        error('Please make sure the ICLabel plugin is installed via eeglab before continuing');
    end
    
    
    %check to make sure the plugin and functions folders have been put
    %on the path
%    if ~contains(path,pluginsDir)
        addpath(pluginsDir);
        fp = genpath(fullfile(eeglabpath, 'functions'));
        addpath(fp);
%    end

 %     %check for FMUT installation
    if isempty(which('FclustGND.m'))
        error('Could not find FMUT installation.  Please make sure the FMUT toolbox is installed on this computer and is on the MATLAB path');
    end
    %check for MASS UNIVARIATE installation
    if isempty(which('clustGND.m'))
        msg = "Could not find Mass Univariate installation!";
        msg = sprintf("%s\nPlease make sure the Mass Univariate ERP toolbox is installed on this comuputer and is on the MATLAB path", msg);
        msg = sprintf("%s\nThe toolbox can be downloaded from https://github.com/dmgroppe/Mass_Univariate_ERP_Toolbox", msg);
        error(msg);
    end

    %check for fieldtrip installation
    ftripPath = fullfile(eeglabpath, 'plugins', 'Fieldtrip*');
    ft = dir(ftripPath);
    if isempty(ft)
        error('Could not find Fieltrip plugin for eeglab.  Please make sure it is installed before proceeding');
    else
        isFolder = [ft.isdir];
        ft = ft(isFolder==1);
        if isempty(ft)
            error('Could not find Fieltrip plugin for eeglab.  Please make sure it is installed before proceeding');
        end
        fDates = [ft.datenum];
        [~, indx] = max(fDates);
        ft = ft(indx);
        addpath(fullfile(ft.folder, ft.name));
    end

    %add the local folders
    cPath = fileparts(mfilename("fullpath"));
    subfolders = {'config', 'functions', 'toolboxes', 'icons'};
    s = pathsep;
    pathStr = [s, path, s];
    
    for ii = subfolders
        sFolderPath = fullfile(cPath, ii{1});
        onPath  = contains(pathStr, [s, sFolderPath, s], 'IgnoreCase', ispc);
        if ~onPath
            addpath(sFolderPath);
        end
    end

%*************************************************************************
function checkForNewVersion(user, repository, downloadType, name)
% Code to check and download a new version if it exists
% Adapted from - Zoltan Csati's function filestr = githubFetch
% GITHUBFETCH  Download file from GitHub.
%   
%   Inputs:
%       user: name of the user or the organization
%       repository: name of the repository
%       downloadType: 'branch' or 'release'
%       name (optional):
%           if downloadType is 'branch': branch name (default: 'master')
%           if downloadType is 'release': release version (default: 'latest')
%   Output:
%       filestr: path to the downloaded file
%
%   The downloaded file type is .zip.
%
%   Examples:
%       1) githubFetch('GLVis', 'glvis', 'branch')
%       % same as githubFetch('GLVis', 'glvis', 'branch', 'master')
%       2) githubFetch('matlab2tikz', 'matlab2tikz', 'branch', 'develop')
%       3) githubFetch('matlab2tikz', 'matlab2tikz', 'release', '1.1.0')
%       4) githubFetch('matlab2tikz', 'matlab2tikz', 'release')
%       % same as githubFetch('matlab2tikz', 'matlab2tikz', 'release', 'latest')
%   Zoltan Csati
%   04/02/2018

narginchk(3, 4);
website = 'https://github.com';
% Check for download type
branchRequested = strcmpi(downloadType, 'branch');
releaseRequested = strcmpi(downloadType, 'release');
assert(branchRequested | releaseRequested, ...
    'Type must be either ''branch'' or ''release''.');
% Check if the user exists
try
    urlread(fullfile(website, user));
catch ME
    if strcmp(ME.identifier, 'MATLAB:urlread:FileNotFound')
        error('User does not exist.');
    end
end
% Check if the repository exists for the given user
try
    urlread(fullfile(website, user, repository));
catch ME
    if strcmp(ME.identifier, 'MATLAB:urlread:FileNotFound')
        error('Repository does not exist.');
    end
end
% Process branch or release versions
if nargin < 4 % no branch or release version provided
    if branchRequested
        name = 'master';
    elseif releaseRequested
        name = 'latest';
    end
end
if releaseRequested
    if strcmpi(name, 'latest') % extract the latest version number
        s = urlread(fullfile(website, user, repository, 'releases', 'latest'));
        % Search based on https://stackoverflow.com/a/23756210/4892892
        [startIndex, endIndex] = regexp(s, '(?<=<title>).*?(?=</title>)');
        releaseLine = s(startIndex:endIndex);
        % Extract the release number
        [startIndex, endIndex] = regexp(releaseLine, '([0-9](\.?))+');
        name = releaseLine(startIndex:endIndex);
        assert(~isempty(name), 'No release found. Try downloading a branch.');
    end
    versionName = ['v', name];
elseif branchRequested
    versionName = name;
end
% Download the requested branch or release
githubLink = fullfile(website, user, repository, 'archive', [versionName, '.zip']);
downloadName = [repository, '-', name, '.zip'];
try
    fprintf('Download started ...\n');
    filestr = urlwrite(githubLink, downloadName);
    fprintf('Repository %s successfully downloaded.\n', repository);
catch ME
    if strcmp(ME.identifier, 'MATLAB:urlwrite:FileNotFound')
        if branchRequested
            error('Branch ''%s'' does not exist.', name);
        elseif releaseRequested
            error('Release version %s does not exist.', name);
        end
    else
        rethrow(ME);
    end
end

%**************************************************************************
function hex =rgb2hex(rgb)
    arguments
        rgb (1,3) {mustBeFloat}
    end
    rgb = round(rgb * 255);
    d = 0; pos = 1;
    for ii = [4,2,0]
        d = d + rgb(pos) * 16^ii;
        pos = pos + 1;
    end
    hex = dec2hex(d);

%**************************************************************************
function list = getSchemeList()

    cp = mfilename('fullpath');
    [cp,~,~] = fileparts(cp);
    f = fullfile(cp, 'config','themes', '*.mat');
    list = dir(f);

%**************************************************************************
function callback_changeScheme(~, src)

    p.themeFile = src.Source.UserData;
    eeg_WriteConfig(p)
    
    msg = 'Do you want to restart the main interface to use the new theme? Otherwise the theme will take effect on the next restart.';
    response = wwu_msgdlg(msg, 'Restart request', {'Yes','No'});
    if strcmp('Yes', response)
        esma;
    end
%**************************************************************************
function callback_editscheme(~,~,h)

    options = eeg_ReadConfig('themeFile');
    %load the  editor
    f = wwu_ThemeEditor('SchemeFile', options.themeFile);
    waitfor(f)
    msg = 'Do you want to restart the main interface to see the changes? Otherwise the changes will take effect on the next restart.';
    response = wwu_msgdlg(msg, 'Restart request', {'Yes','No'});
    if strcmp('Yes', response)
        esma;
    end
%**************************************************************************
function callback_editdatapath(~,~)
    
    study_ChangeEEGPath;
    esma;
%