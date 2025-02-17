function fh = study_EditStudy(study)

newStudy = false;
if nargin < 1 || isempty(study)
    newStudy = true;
end

h = build_GUI;
h = assign_callbacks(h);
fh = h.figure;

if newStudy
    study = callback_newStudy([],[],h);
    %close the figure if the study comes back empty 
    if isempty(study)
        close(h.figure);
        return
    end
else
    study = checkForCompatibility(study);
end
setstudy(h,study);
populate_studyinfo(study, h);
%**************************************************************************
function study = checkForCompatibility(study)
% do some things to ensure backward compatibility with previous studies that
% may not have all the same fields    
if ~isfield(study, 'subject')
    return
end

for ii = 1:length(study.subject)
    if ~isfield(study.subject(ii), 'conditions')
        study.subject(ii).conditions = [];
    end
end
%**************************************************************************
function study = callback_newStudy(hObject, hEvent, h)
%callback function for when user pushes the new study button
%this will also be called when the user calls this funciton without passing
%an existing study structure

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
study.subject = [];
study.version = 1;

%make sure that the general tab is selected
h.infotabs.SelectedTab = h.tab(1);

%create a dialog box telling the person what is going to happen
msg ='Select the folder where the study data are located. ';
msg = sprintf('%s\nParticpant data should be stored in individual subfolders within the folder you select.', msg);
msg = sprintf('%s\nUse eeg_FilesToFolders to move files from a single to individual folders.',msg);
choice = uiconfirm(h.figure, msg,'New Study',...
    'Options',{'Proceed', 'Cancel'},...
    'CancelOption',2,...
    'DefaultOption',1,...
    'Icon', 'info');

%if they choose to proceed present them with a dialog box to select the
%path of the data
if strcmp(choice, 'Cancel')
    study = [];
    return
end
h.figure.Visible = false;
studyFolder = uigetdir(EEGPath, 'Select data folder');
h.figure.Visible = true;
if studyFolder == 0
    study = [];
    return
end

%extract just the folder portion so the path is relative ot the EEGPath
i = strfind(studyFolder, EEGPath);
studyFolder = studyFolder(i+length(EEGPath):length(studyFolder));
study.path = studyFolder;

%now get the channel locations file for the study
msg = 'Select a channel locations files.';
msg = [msg, 'The same positions will be assigned to each file during conversion'];
selection = uiconfirm(h.figure, msg, 'Add channel locations',...
    'Options', {'Add Locations', 'Cancel'}, 'Icon', 'info');

if strcmp(selection, 'Add Locations')
    h.figure.Visible = false;
    defaultLocPath = fullfile(fileparts(mfilename("fullpath")), 'config', 'position files');
    [loc_file, loc_path] = uigetfile('*.*', 'Select channel locations file',...
        defaultLocPath);
    h.figure.Visible = true;
    if ~isempty(loc_file)
        %use the eeglab readlocs function to get the position
        %information
        chanlocs = readlocs(fullfile(loc_path,loc_file));
        if ~isempty(chanlocs)
            study.chanlocs = chanlocs;
        end
    end
else
    study = [];
    return
end

%now get the channel locations file for the study
msg = 'Would you like to try and autodetect the subject folders for this experiment?';
msg = [msg, 'If you select NO you can add subjets manually using the Subjects tab.'];
selection = uiconfirm(h.figure, msg, 'Add channel locations',...
    'Options', {'Yes', 'No'}, 'Icon', 'question');

if strcmp(selection, 'Yes')
    study = autoAssignSubjects(study);
end

setstudy(h, study);
%save the study
[study, notsaved_flag] = study_SaveStudy(study, 'saveas', true);
if notsaved_flag
    study = [];
    return
end

msg = sprintf('The new study %s has been created and saved.\n',study.name);
msg = sprintf('%sYou can edit the study using the Study Editing tool, or close the tool to return to the main interface.', msg);
uialert(h.figure,msg,'Study saved','Icon','info');
%************************************************************************
function populate_studyinfo(study, h)
% populate the study information when the GUI is first built
h.edit_studyname.Value = study.name;
h.edit_studypath.Value = study.path;
if isempty(study.description)
    h.edit_studydescr.Value = '';
else
    h.edit_studydescr.Value = study.description;
end
populate_SubjectDisplay(study, h)
populate_ChanGroupDisplay(study, h)
populate_bintree(study, h)
callback_changeBinGroupButtonStatus([],[], h, false)
%*************************************************************************
function populate_SubjectDisplay(study, h)

%clear the nodes from the tree
n = h.tree_subjectlist.Children;
delete(n);
if study.nsubjects > 0

    badSubjStyle = uistyle('FontColor', 'r');

    for ss = 1:length(study.subject)
        n = uitreenode('Parent', h.tree_subjectlist,...
            'Text', sprintf('Subject: \t%s', study.subject(ss).ID),...
            'NodeData', ss);
        if strcmp(study.subject(ss).status, 'bad')
            addStyle(h.tree_subjectlist, badSubjStyle, 'node', n);
        end
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
        cnode = uitreenode('Parent', n,...
            'Text', 'Conditions',...
            'NodeData', ss);
        for cc = 1:length(study.subject(ss).conditions)
            uitreenode('Parent', cnode,...
                'Text', study.subject(ss).conditions{cc},...
                'NodeData', ss);
        end
    end
end
%% BIN GROUP FUNCTIONS
%*************************************************************************
function callback_addbingroup(hObject, hEvent, h)
% add a new bin group to the study
study = getstudy(h);

epochgroup_name = h.edit_bingroupname.Value;
epoch_start = h.edit_epochstart.Value;
epoch_end = h.edit_epochend.Value;
epoch_filename = h.edit_epochfilename.Value;

%this is set by the calling function and is used to know if this is a new
%bin group or an existing bin group is being updated
isNew = hObject.UserData;

if isempty(epochgroup_name)
    uialert(h.figure, 'Please enter a valid bin group name.', 'Error');
    return
else
    eg.name = epochgroup_name;
end

if isempty(epoch_filename)
    uialert(h.figure, 'Please enter a valid epoch filename', 'Error');
    return
else
    eg.filename = epoch_filename;
end

if epoch_start >= epoch_end
    uialert(h.figure, 'the epoch start cannot be greater than the epoch end.', 'Error');
else
    eg.interval = [epoch_start, epoch_end];
end

if ~isNew %this is an update and not a new bin group
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
setstudy(h,study);
populate_bintree(study, h);

%switch back to the non-editing mode now
callback_changeBinGroupButtonStatus(hObject, hEvent, h, false)
%toggleEpochTabState(h.tab_trialgroup, 'off');

% ***********************************************************************
function callback_removebingroup(hObject, eventdata, h)
% remove an existing bin from the study
%
n = h.tree_bingrouplist.SelectedNodes;
study = getstudy(h);


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
setstudy(h,study);
populate_bintree(study, h, [enum, cnum]);
%*************************************************************************
%callback function for allowing editing of an existing condition
function callback_editbingroup(hObject, eventdata, h, isNew)
% edit an existing bin
%
study = getstudy(h);

n = h.tree_bingrouplist.SelectedNodes;
if isNew
    h.edit_bingroupname.Value = '';
    h.edit_epochfilename.Value = '';
    h.edit_epochstart.Value = double(-.1);
    h.edit_epochend.Value = double(.6);
else
    if isempty(n)
        uialert(h.figure, 'You must select a Bin Group to edit.', 'Edit Bin Group');
        return
    end

    gnum = n.NodeData{1};
    h.edit_bingroupname.Value = study.bingroup(gnum).name;
    h.edit_epochfilename.Value = study.bingroup(gnum).filename;
    h.edit_epochstart.Value = study.bingroup(gnum).interval(1);
    h.edit_epochend.Value = study.bingroup(gnum).interval(2);
end

%pass the isNew flag forward to the update button so the
%add bin function knows whether to update or add.
h.button_bingroupupdate.UserData = isNew;
callback_changeBinGroupButtonStatus(hObject, eventdata, h, true)

%make sure the bin group tab is selected
h.tabgroup_bins.SelectedTab = h.tab_trialgroup;
toggleEpochTabState(h.tab_trialgroup, 'on');
%*************************************************************************
function callback_changeBinGroupButtonStatus(hObject, hEvent, h, editing)
% changes the state of the editing buttons so they cannot be used when a
% bin group is being edited

h.button_bingroupadd.Enable = ~editing;
h.button_bingroupremove.Enable = ~editing;
h.button_bingroupedit.Enable = ~editing;
h.tree_bingrouplist.Enable = ~editing;

if editing
    checkBinAddEnableStatus(h, 'off');
else
    checkBinAddEnableStatus(h);
end

if editing == false
    toggleEpochTabState(h.tab_trialgroup, 'off');
    toggleEpochTabState(h.tab_trialdef, 'off');
end
%*************************************************************************
function callback_newbintogroup(~,~,h)
% callback function for when teh user clicks the new bin button for adding
% a new bin to an existing bin group
%
n = h.tree_bingrouplist.SelectedNodes;
if isempty(n)
    uialert(h.figure,'Please create or select a Bin Group first.', 'Add Condition');
    return
end
callback_changeBinGroupButtonStatus([],[],h,true);
toggleEpochTabState(h.tab_trialdef, 'on');
h.tabgroup_bins.SelectedTab = h.tab_trialdef;
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

gnum = n.NodeData{1};
if ~isempty(study.bingroup(gnum).bins)
    new_cnum = length(study.bingroup(gnum).bins) + 1;
else
    new_cnum = 1;
end

%get information from the input boxes
p.name = h.edit_binname.Value;
p.events = h.edit_eventlist.Value;
if length(p.events) > 1 % there are multiple lines
    p.events = p.events';
end

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
setstudy(h,study);
populate_bintree(study, h, [gnum, new_cnum]);
callback_changeBinGroupButtonStatus([],[],h, false)
checkBinAddEnableStatus(h)
% *************************************************************************
function callback_removeBinFromGroup(~, ~, h)
% function to delete a bin from a bin group

study = getstudy(h);

n = h.tree_bingrouplist.SelectedNodes;
if isempty(n)
    uialert(h.figure,'Please create or select a Bin to remove.', 'Remove Bin');
    return
end

%stepped updating this function here.
groupOfBin = n.NodeData{1};
binToRemove = n.NodeData{2};

if groupOfBin == 0 || binToRemove == 0
    wwu_msgdlg("Please select a specific bin to remove!", "Remove Bin", {'OK'}, "isError",true);
    return
end
if isempty(study.bingroup(groupOfBin).bins)
    wwu_msgdlg("There are no bins to remove!", "Remove Bin", {'OK'}, "isError",true);
    return
end
if isempty(study.bingroup(groupOfBin).bins(binToRemove))
    wwu_msgdlg("The bin you are attempting to remvoe does not seem to exist",...
        "Remove Bin", {"OK"}, "isError",true);
    return
end

resp = wwu_msgdlg('Are you sure you want to remove the selected bin',...
    "Remove Bin", {"Yes", "No"});
if strcmp(resp, "Yes")
    study.bingroup(groupOfBin).bins(binToRemove) = [];

    study = study_SaveStudy(study);
    setstudy(h,study);
    populate_bintree(study, h);
    callback_changeBinGroupButtonStatus([],[],h, false)
    checkBinAddEnableStatus(h)
end
%toggleEpochTabState(h.tab_trialgroup, 'off');
% *************************************************************************
function callback_canceladdbintogroup(~,~,h)

    callback_changeBinGroupButtonStatus([],[],h, false)
    checkBinAddEnableStatus(h);
    %toggleEpochTabState(h.tab_trialgroup, 'off');
% ************************************************************************
function callback_binGroupSelected(hObject,~,h)
 % checkBinAddEnableStatus(h, 'on');
 % investigate what we can know about the passed objects

  % selectAndPopulateBinEditPanels(hObject, [], h);
% ************************************************************************    
function checkBinAddEnableStatus(h, status)
 %checks the state of the uitree and determines if the add bin button 
 % should be active.  The state will be forced to status if it is set.
 if nargin > 1
     h.button_binadd.Enable = status;
 else
    if isempty(h.tree_bingrouplist.SelectedNodes)
        h.button_binadd.Enable = 'off';
        h.button_binremove.Enable = 'off';
    else
        h.button_binadd.Enable = 'on';
        h.button_binremove.Enable = 'on';
    end
 end
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
n = [];

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
    callback_binGroupSelected(h.tree_bingrouplist, [], h);
elseif ~isempty(n)
    expand(n)
    h.tree_bingrouplist.SelectedNodes = n;
    callback_binGroupSelected(h.tree_bingrouplist, [], h);
end
% *************************************************************************
%function to call when usser selects on information in the 
%epoch groups display.  it will populate the tabs wit appropriate
%information and make that tab the active one.
function selectAndPopulateBinEditPanels(hObject, eventdata, h)

 %   study = getstudy(h);
    nd = hObject.SelectedNodes.NodeData;
  
    %this is an indication that they node is for a bin within a hin group
    if nd{2} > 0
        h.tabgroup_bins.SelectedTab = h.tab_trialdef;
        disp('you selected a bin');
    else
        h.tabgroup_bins.SelectedTab = h.tab_trialgroup;
        callback_editbingroup(hObject, [], h, false)
    end
% ************************************************************************    
%toggle all teh items on an epoch control tab      
function toggleEpochTabState(tab, state)

c = tab.Children;
for i = 1:length(c)
    c(i).Enable = state;
end
%*************************************************************************
%% CHANNEL GROUP CALLBACKS and FUNCTIONS
%**************************************************************************
function populate_ChanGroupDisplay(study, h)

n = h.tree_changroup.Children;
grpCount = length(n);
n.delete;

if ~isfield(study, 'chanlocs')
    return
end

h.list_chanpicker.Items = {study.chanlocs.labels};
h.list_chanpicker.ItemsData = 1:length(study.chanlocs);
callback_drawchannelpositions([],[], h)

%add the ones from the current study
if isfield(study,'chgroups') && ~isempty(study.chgroups)
    for ii = 1:length(study.chgroups)
        n = uitreenode('Parent', h.tree_changroup,...
            'Text', study.chgroups(ii).name, 'NodeData', ii);
        for jj = 1:length(study.chgroups(ii).chans)
            uitreenode('Parent', n, 'Text', study.chgroups(ii).chanlocs(jj).labels,...
                'NodeData', ii);
        end
    end
    h.tree_changroup.SelectedNodes = n;
    expand(n);
end

toggle_changroupbuttons(h);
%*************************************************************************
%draw the display that shows the channel locations on a 2-d projection
%**************************************************************************
function callback_drawchannelpositions(~, ~, h)

study = getstudy(h);
selchans = h.list_chanpicker.Value;
if isempty(selchans)
    h.button_addchangroup.Enable = 'off';
    h.button_clearselchans.Enable = 'off';
    h.label_chanselectedsummary.Text = "Click or Shift+Click+Drag to select electrodes";
else
     h.button_addchangroup.Enable = 'on';
     h.button_clearselchans.Enable = 'on';
     h.label_chanselectedsummary.Text = sprintf("%i Electrodes selected", length(selchans));

end   
[mHandle, smHandle] = wwu_PlotChannelLocations(study.chanlocs,...
    'Elec_Color', [.25,.25,.25],...
    'Elec_Selcolor',[.2,.9,.9],...
    'Elec_Size', 50,...
    'Elec_SelSize', 150,...
    'Labels', 'name',...
    'LabelColor', [1,1,1],...
    'Subset', selchans,...
    'AxisHandle', h.axis_chanpicker);

mHandle.ButtonDownFcn = {@callback_channelClick, h};
smHandle.ButtonDownFcn = {@callback_channelClick, h};
%************************************************************************
function callback_channelClick(hObject, ~, h)

study = getstudy(h);

[yp, xp] =  wwu_ChannelProjection(study.chanlocs);

mp = h.axis_chanpicker.CurrentPoint;
x = mp(1,1); y = mp(1,2);
%get the cartesian distance to all the electrodes
dx = xp - x; dy = yp - y;
d = sqrt(dx.^2 + dy.^2);

%the smallest is the one that was clicked
[~, en] = min(d);
i = find(h.list_chanpicker.Value==en);
if isempty(i)
    h.list_chanpicker.Value = sort([h.list_chanpicker.Value, en]);
else
    h.list_chanpicker.Value(i) = [];
end

callback_drawchannelpositions(hObject, [], h)
% *************************************************************************
function callback_handleMouseDown(hObject, hEvent, h)

if contains(hObject.SelectionType, 'extend')
    cp = hObject.CurrentPoint;
    ap = h.axis_chanpicker.Position;
    pp = h.tab(4).Position;

    xp = cp(1,1); yp = cp(1,2);
    axWin(1) = ap(1) + pp(1);
    axWin(2) = ap(2) + pp(2);
    axWin(3) = axWin(1) + ap(3);
    axWin(4) = axWin(2) + ap(4);

    isInAxis = (xp > axWin(1)) && (yp > axWin(2)) && (xp < axWin(3)) && (yp < axWin(4));
    if isInAxis
        css = h.axis_chanpicker.UserData;
        css.drawing = true;
        %initialize drawing
        cp = h.axis_chanpicker.CurrentPoint;
        css.line = line(h.axis_chanpicker, cp(1,1), cp(1,2), 'Color', 'g',...
            'LineWidth', 2);
        h.axis_chanpicker.UserData = css;
        fprintf('started drawing...')
    end
end
%*************************************************************************
function callback_handleMouseUp(hObject, hEvent, h)

css = h.axis_chanpicker.UserData;
if isempty(css) || css.drawing == false
    return
else
    %delete the line object
    %close the shape
    css.line.XData(end+1) = css.line.XData(1);
    css.line.YData(end+1) = css.line.YData(1);
    drawnow

    %figure out which channels are in the shape
    study = getstudy(h);
    [yp, xp] = wwu_ChannelProjection(study.chanlocs);
    selected = find(inpolygon(xp, yp, css.line.XData, css.line.YData));
    h.list_chanpicker.Value = selected;
    callback_drawchannelpositions(hObject, hEvent, h);

    %clear the drawing and stop drawing mode
    css.drawing = false;
    h.axis_chanpicker.UserData = css;
    fprintf('finished drawing\n');
    delete(css.line);


end
%************************************************************************
function callback_handleMouseMove(hObject, hEvent, h)

css = h.axis_chanpicker.UserData;
if ~isempty(css) && css.drawing == true
    %the handle may get deleted
    if ~isvalid(css.line)
        css.drawing = false;
        h.axis_chanpicker.UserData  = css;
        return
    end

    cp = h.axis_chanpicker.CurrentPoint;
    css.line.XData(end+1) = cp(1,1);
    css.line.YData(end+1) = cp(1,2);
    drawnow;
end
%*************************************************************************
%edit the description of the study in real time
function callback_editstudydescr(hObject, event, h)

study = getstudy(h);
study.description = h.edit_studydescr.Value;
study = study_SaveStudy(study);
setstudy(h,study);
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
dlgparams.msg = 'Enter a name for the new channel group';
dlgparams.title = 'New Channel Group';
dlgparams.options = {'OK', 'Cancel'};
dlgparams.default = default_groupname;
info = wwu_inputdlg(dlgparams);

if isempty(info.input) || strcmp(info.input, '') || contains(info.option, 'Cancel')
    fprintf('No valid group name or operation aborted\n');
    return
end
%now make the group
study.chgroups(gnum).name = info.input;
study.chgroups(gnum).chans = h.list_chanpicker.Value;
study.chgroups(gnum).chanlocs = study.chanlocs(study.chgroups(gnum).chans);

setstudy(h, study);
study = study_SaveStudy(study);
populate_ChanGroupDisplay(study, h)
%*************************************************************************
function callback_updatechangroup(~, ~, h)
study = getstudy(h);
n = h.tree_changroup.SelectedNodes;
if isempty(n)
    return
end
gnum = n.NodeData;
study.chgroups(gnum).chans = h.list_chanpicker.Value;
study.chgroups(gnum).chanlocs = study.chanlocs(study.chgroups(gnum).chans);

setstudy(h, study);
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
    setstudy( h, study)
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
toggle_changroupbuttons(h);
if ~isempty(n)
    h.list_chanpicker.Value = study.chgroups(n.NodeData).chans;
    callback_drawchannelpositions(hObject,eventdata,h)
end
%**************************************************************************
function toggle_changroupbuttons(h)
    n = h.tree_changroup.SelectedNodes;

    if isempty(n)
        h.button_updatechangroup.Enable = 'off';
        h.button_removechangroup.Enable = 'off';
    else
        h.button_updatechangroup.Enable = 'on';
        h.button_removechangroup.Enable = 'on';
    end
%*********************************************************************
function callback_clearselectedchans(~,~,h)
    h.list_chanpicker.Value = [];
    callback_drawchannelpositions([],[],h);
%% SUBJECT RELATED FUNCTIONS
%*********************************************************************
function callback_editsubject(hObject, hEvent,h, isNew)

study = getstudy(h);
if ~isNew
    n = h.tree_subjectlist.SelectedNodes;
    if isempty(n)
        uialert(h.figure, 'Please select a subject to edit', 'Subject Edit');
        return
    end

    %figure out which subject is selected
    sn = n.NodeData;

    %extract any condition list
    if ~isempty(study.subject(sn).conditions)
        conds = strjoin(study.subject(sn).conditions, ',');
    else 
        conds = '';
    end
    
    %place the values from the selected subject in the appropriate controls
    h.edit_subjectid.Value = study.subject(sn).ID;
    h.edit_subjectpath.Value = study.subject(sn).path;
    h.dropdown_subjectgender.Value = study.subject(sn).gender;
    h.spinner_subjectage.Value = str2num(study.subject(sn).age);
    h.dropdown_subjecthand.Value = study.subject(sn).hand;
    h.edit_subjcond.Value = conds;
    h.check_subjectstatus.Value = strcmp(study.subject(sn).status, 'good');

    h.button_updatesubject.UserData = sn;

else
    set_subjectdefaults(h);
end

%change the status of the controls so the user cannot
%do anything until they finish editing the subject
callback_changeSubjectEntryMode(hObject, hEvent, h, false);
%**************************************************************************
%add a subject to the current study
function callback_addsubject(hObject, hEvent, h)

sn = hObject.UserData;
study = getstudy(h);

%collect all the data into a subject structure
subject.ID = h.edit_subjectid.Value;
subject.path = h.edit_subjectpath.Value;
subject.gender = h.dropdown_subjectgender.Value;
subject.age = num2str(h.spinner_subjectage.Value);
subject.hand = h.dropdown_subjecthand.Value;
subject.conditions = strtrim(strsplit(h.edit_subjcond.Value, ','));
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
    %change the status of the controls so the user cannot
    %do anything until they finish editing the subject
    callback_changeSubjectEntryMode(hObject, hEvent, h, true);

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
setstudy( h, study);

%save the study on the disk
study_SaveStudy(study);

%refresh the node tree
populate_SubjectDisplay(study, h);
%*************************************************************************
function callback_changeSubjectEntryMode(hObject, hEvent, h, state)

h.button_subjectadd.Enable = state;
h.button_subjectremove.Enable = state;
h.button_subjectedit.Enable = state;
h.tree_subjectlist.Enable = state;

if state
    h.panel_sbj.Enable = 'off';
else
    h.panel_sbj.Enable = 'on';
end
%*************************************************************************
function callback_removesubject(hObject, event, h)
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
        setstudy(h, study);

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
fullstudypath = eeg_BuildPath(eeg_path, study.path);

%get the user path input
h.figure.Visible = false;
path = uigetdir(fullstudypath);
h.figure.Visible = true;

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
h.check_subjectstatus.Value = true;
h.edit_subjconds = '';
%******************************************************************
function callback_changeStudyName(hObject, hEvent, h)

study = getstudy(h);

newName = h.edit_studyname.Value;
if ~isempty(newName)
    study.name = newName;
    study = study_SaveStudy(study);
end

fprintf('saving changes to study name\n');
setstudy(h, study);
%*****************************************************************
function study = autoAssignSubjects(study)

eeg_path = study_GetEEGPath();

%build the path for this study
studypath = eeg_BuildPath(eeg_path, study.path);
d = dir(studypath);
d = d([d.isdir]);  %eliminate any that arent folders
folderNames = {d.name};

%find all folders that start with a letters and are followed by numbers
%anything with a space will be removed.
expr = '[a-zA-Z]+\d+';
r = regexp(folderNames, expr);  %search for the desired string

for ii = 1:length(r)
    if r{ii} == 1
        subject.ID = folderNames{ii};
        subject.path = [filesep, folderNames{ii}];
        subject.gender = 'female';
        subject.age = '20';
        subject.hand = 'right';
        subject.status = 'good';
        subject.conditions = '';
        if ~isfield(study, 'subject')
            study.subject(1) = subject;
        else
            if isempty(study.subject)
                study.subject = subject;
            else
                study.subject(end+1) = subject;
            end
        end
        study.nsubjects = study.nsubjects + 1;
    end
end
%**************************************************************************
function callback_closefigure(hObject, hEvent, h)
    delete(h.figure);
%**************************************************************************
function study = getstudy(h)
study = h.figure.UserData;
%**************************************************************************
function setstudy(h, study)
h.figure.UserData = study;
%**************************************************************************
function callback_toggletabs(hObject, hEvent, h)

    %dont do anything if this is the currently selected tab
    if contains(hObject.Tag, 'selected')
        return
    end

    bIndx = hObject.UserData;
    bColor = hObject.BackgroundColor;
    fColor = hObject.FontColor;

    for ii = 1:4
        h.tab(ii).Visible = 'off';
        h.button_tabselect(ii).BackgroundColor = bColor;
        h.button_tabselect(ii).FontColor = fColor;
        h.button_tabselect(ii).Tag = '';
    end
    h.tab(bIndx).Visible = 'on';
    hObject.BackgroundColor = fColor;
    hObject.FontColor = bColor;
    hObject.Tag = 'selected';

%%  GUI BUILDING FUNCTIONS    
%**************************************************************************
function h = assign_callbacks(h)
%a function that assigns all of the control callback functions
%I separate these out because it is easier to deal with the creation of the
%objects and the assignment of the callbacks in two smaller callbacks
%rather than one large one.

h.figure.WindowButtonUpFcn = {@callback_handleMouseUp, h};
h.figure.WindowButtonDownFcn = {@callback_handleMouseDown, h};
h.figure.WindowButtonMotionFcn = {@callback_handleMouseMove, h};

h.edit_studyname.ValueChangedFcn = {@callback_changeStudyName, h};
h.edit_studydescr.ValueChangedFcn = {@callback_editstudydescr, h};

h.button_return.ButtonPushedFcn = {@callback_closefigure, h};

h.button_subjectedit.ButtonPushedFcn = {@callback_editsubject, h, false};
h.button_subjectadd.ButtonPushedFcn =  {@callback_editsubject, h, true};
h.button_subjectpath.ButtonPushedFcn = {@callback_getsubjectpath, h};
h.button_updatesubject.ButtonPushedFcn = {@callback_addsubject, h};
h.button_cancelsubject.ButtonPushedFcn = {@callback_changeSubjectEntryMode, h, true};
h.button_subjectremove.ButtonPushedFcn = {@callback_removesubject, h};

h.button_bingroupupdate.ButtonPushedFcn = {@callback_addbingroup, h};
h.button_addbin.ButtonPushedFcn = {@callback_addbintogroup, h};
h.button_bingroupremove.ButtonPushedFcn = {@callback_removebingroup, h};
h.button_bingroupadd.ButtonPushedFcn = {@callback_editbingroup, h, true};
h.button_binadd.ButtonPushedFcn = {@callback_newbintogroup, h};
h.button_binremove.ButtonPushedFcn = {@callback_removeBinFromGroup, h};
h.button_canceladdbin.ButtonPushedFcn = {@callback_canceladdbintogroup, h};

h.button_bingroupedit.ButtonPushedFcn = {@callback_editbingroup, h, false};
h.list_binevents.ValueChangedFcn = {@callback_addtoeventlist, h};
h.button_bingroupcancel.ButtonPushedFcn = {@callback_changeBinGroupButtonStatus, h, false};
%h.tree_bingrouplist.SelectionChangedFcn = {@callback_binGroupSelected, h};
h.tree_bingrouplist.DoubleClickedFcn = {@callback_binGroupSelected, h};

h.button_addchangroup.ButtonPushedFcn  = {@callback_createchangroup, h};
h.button_updatechangroup.ButtonPushedFcn = {@callback_updatechangroup, h};
h.button_removechangroup.ButtonPushedFcn = {@callback_removechangroup, h};
h.button_clearselchans.ButtonPushedFcn = {@callback_clearselectedchans,h};
h.tree_changroup.SelectionChangedFcn = {@callback_selectchangroup, h};
h.list_chanpicker.ValueChangedFcn = {@callback_drawchannelpositions, h};

for ii = 1:4
    h.button_tabselect(ii).ButtonPushedFcn = {@callback_toggletabs, h};
end

%**************************************************************************
function h = build_GUI()


of = findall(groot, 'Type', 'figure', 'Tag', 'hcnd_study_editor');
if ~isempty(of)
    close(of)
end

scheme = eeg_LoadScheme;
h.scheme = scheme;
width = 780;
height = 400;
buttonwidth = 80;
left = (scheme.ScreenWidth -width)/2;
bottom = (scheme.ScreenHeight - height)/3;
h.figure = uifigure('Position', [left,bottom,width,height]);
h.figure.Color = scheme.Window.BackgroundColor.Value;
h.figure.Resize = false;
h.figure.Name = 'Study Editor';
h.figure.Tag = 'hcnd_study_editor';
h.figureNumberTitle = false;

%main buttons
x = width - 10 - buttonwidth;

h.button_return = uibutton('Parent', h.figure,...
    'Position', [x, 5, buttonwidth, scheme.Button.Height.Value],...
    'Text', 'Return',...
    'BackgroundColor', scheme.Button.BackgroundColor.Value,...
    'FontColor', scheme.Button.FontColor.Value,...
    'FontName', scheme.Button.Font.Value,...
    'FontSize', scheme.Button.FontSize.Value);

%create a group for holding button toggles
h.bg = uibuttongroup('Parent', h.figure,...
    'Position', [10, 375,402,27],...
    'BackgroundColor',scheme.Panel.BackgroundColor.Value,...
    'BorderType','none');

h.button_tabselect(1) = uibutton('Parent', h.bg,...
    'Text', 'General',...
    'Position', [1, 1, 100, 25],...
    'BackgroundColor',scheme.Panel.FontColor.Value,...
    'FontColor',scheme.Panel.BackgroundColor.Value,...
    'FontName', scheme.Panel.Font.Value,...
    'FontSize', scheme.Panel.FontSize.Value,...
    'UserData', 1,...
    'Tag', 'selected');

h.button_tabselect(2) = uibutton('Parent', h.bg,...
    'Text', 'Subject',...
    'Position', [101, 1, 100, 25],...
    'BackgroundColor',scheme.Panel.BackgroundColor.Value,...
    'FontColor',scheme.Panel.FontColor.Value,...
    'FontName', scheme.Panel.Font.Value,...
    'FontSize', scheme.Panel.FontSize.Value,...
    'UserData', 2);

h.button_tabselect(3) = uibutton('Parent', h.bg,...
    'Text', 'Epoch Bins',...
    'Position', [201, 1, 100, 25],...
    'BackgroundColor',scheme.Panel.BackgroundColor.Value,...
    'FontColor',scheme.Panel.FontColor.Value,...
    'FontName', scheme.Panel.Font.Value,...
    'FontSize', scheme.Panel.FontSize.Value,...
    'UserData', 3);
h.button_tabselect(4) = uibutton('Parent', h.bg,...
    'Text', 'Channel Groups',...
    'Position', [301, 1, 100, 25],...
    'BackgroundColor',scheme.Panel.BackgroundColor.Value,...
    'FontColor',scheme.Panel.FontColor.Value,...
    'FontName', scheme.Panel.Font.Value,...
    'FontSize', scheme.Panel.FontSize.Value,...
    'UserData', 4);

%general tab
% **********************************************************************
h.tab(1) = uipanel(...
    'Parent', h.figure,...
    'Position', [10, scheme.Button.Height.Value + 10, width-20, height - scheme.Button.Height.Value - 10-24 ],...
    'BackgroundColor', scheme.Panel.BackgroundColor.Value,...
    'ForegroundColor', scheme.Panel.FontColor.Value,...
    'FontName', scheme.Panel.Font.Value,...
    'FontSize', scheme.Panel.FontSize.Value,...
    'BorderType','line');

uilabel('Parent', h.tab(1),...
    'Text', 'Study name',...
    'Position', [10, 280,100,25],...
    'FontColor', scheme.Label.FontColor.Value,...
    'FontName', scheme.Label.Font.Value,...
    'FontSize', scheme.Label.FontSize.Value);

h.edit_studyname = uieditfield(...
    'Parent', h.tab(1),...
    'Placeholder','click "Edit Name" to enter a study name',...
    'Value', '',...
    'Position', [10,255,250,25],...
    'BackgroundColor', scheme.Edit.BackgroundColor.Value,...
    'FontColor', scheme.Edit.FontColor.Value,...
    'BackgroundColor', scheme.Edit.BackgroundColor.Value,...
    'FontColor', scheme.Edit.FontColor.Value);

uilabel('Parent', h.tab(1),...
    'Text', 'Data location',...
    'Position', [400, 280,100,25],...
    'FontColor', scheme.Label.FontColor.Value,...
    'FontName', scheme.Label.Font.Value,...
    'FontSize', scheme.Label.FontSize.Value);

h.edit_studypath = uieditfield(...
    'Parent', h.tab(1),...
    'Placeholder','click "Edit Path" to enter a data path',...
    'Editable','off',...
    'Value', '',...
    'Position', [400,255,250,25],...
    'BackgroundColor', scheme.Edit.BackgroundColor.Value,...
    'FontColor', scheme.Edit.FontColor.Value,...
    'FontName',scheme.Edit.Font.Value,...
    'FontSize', scheme.Edit.FontSize.Value);

h.btn_editpath = uibutton( 'Parent', h.tab(1),...
    'Text', 'Edit Path',...
    'Position', [660,255,buttonwidth,scheme.Button.Height.Value],...
    'BackgroundColor', scheme.Button.BackgroundColor.Value,...
    'FontColor', scheme.Button.FontColor.Value,...
    'FontName', scheme.Button.Font.Value,...
    'FontSize', scheme.Button.FontSize.Value);

uilabel('Parent', h.tab(1),...
    'Text', 'Experiment Description',...
    'Position', [10, 220,200,25],...
    'FontColor', scheme.Label.FontColor.Value,...
    'FontName', scheme.Label.Font.Value,...
    'FontSize', scheme.Label.FontSize.Value);

h.edit_studydescr = uitextarea(...
    'Parent', h.tab(1),...
    'Placeholder','Enter your description here',...
    'Value', '',...
    'Position', [10,60,725,160],...
    'BackgroundColor', scheme.Edit.BackgroundColor.Value,...
    'FontColor', scheme.Edit.FontColor.Value,...
    'FontName',scheme.Edit.Font.Value,...
    'FontSize', scheme.Edit.FontSize.Value);

%*************************************************************************
%subject panel
%going to have to change the tab to a button group because the tabs cannot
%be styled
h.tab(2) = uipanel(...
    'Parent', h.figure,...
    'Position', [10, scheme.Button.Height.Value + 10, width-20, height - scheme.Button.Height.Value - 10-24 ],...
    'BackgroundColor', scheme.Panel.BackgroundColor.Value,...
    'ForegroundColor', scheme.Panel.FontColor.Value,...
    'FontName', scheme.Panel.Font.Value,...
    'FontSize', scheme.Panel.FontSize.Value,...
    'BorderType','line',...
    'Visible','off');

h.panel_sbj = uipanel('Parent', h.tab(2),...
    'Position', [320, 10, 400, 300],...
    'Title', 'Subject Properties',...
    'Enable','off',...
    'BackgroundColor',scheme.Panel.BackgroundColor.Value,...
    'FontName', scheme.Panel.Font.Value,...
    'FontSize', scheme.Panel.FontSize.Value,...
    'ForegroundColor',scheme.Panel.FontColor.Value,...
    'HighlightColor',scheme.Panel.BorderColor.Value);

rc = 20;
t = 245;

uilabel('Parent', h.panel_sbj,...
    'Text', 'Subject ID',...
    'Position', [rc, t-40,100,25],...
    'FontColor', scheme.Label.FontColor.Value,...
    'FontName', scheme.Label.Font.Value,...
    'FontSize', scheme.Label.FontSize.Value);

uilabel('Parent', h.panel_sbj,...
    'Text', 'Subject Folder',...
    'Position', [rc, t,100,25],...
    'FontColor', scheme.Label.FontColor.Value,...
    'FontName', scheme.Label.Font.Value,...
    'FontSize', scheme.Label.FontSize.Value);

uilabel('Parent',h.panel_sbj,...
    'Text', 'Gender',...
    'Position', [rc, t-80,100,25],...
    'FontColor', scheme.Label.FontColor.Value,...
    'FontName', scheme.Label.Font.Value,...
    'FontSize', scheme.Label.FontSize.Value);

uilabel('Parent', h.panel_sbj,...
    'Text', 'Age',...
    'Position', [rc+220, t-80,50,25],...
    'FontColor', scheme.Label.FontColor.Value,...
    'FontName', scheme.Label.Font.Value,...
    'FontSize', scheme.Label.FontSize.Value);

uilabel('Parent',h.panel_sbj,...
    'Text', 'Handedness',...
    'Position', [rc, t-120,100,25],...
    'FontColor', scheme.Label.FontColor.Value,...
    'FontName', scheme.Label.Font.Value,...
    'FontSize', scheme.Label.FontSize.Value);

uilabel('Parent',h.panel_sbj,...
    'Text', 'Conditions',...
    'Position', [rc, t-160,100,25],...
    'FontColor', scheme.Label.FontColor.Value,...
    'FontName', scheme.Label.Font.Value,...
    'FontSize', scheme.Label.FontSize.Value,...
    'WordWrap','on',...
    'Tooltip','Comma separated names for 1 or more between subject conditions');

h.edit_subjectid = uieditfield(...
    'Parent', h.panel_sbj,...
    'Value', '',...
    'Position', [rc+90,t-40,140,25],...
    'BackgroundColor', scheme.Edit.BackgroundColor.Value,...
    'FontColor', scheme.Edit.FontColor.Value,...
    'FontName',scheme.Edit.Font.Value,...
    'FontSize', scheme.Edit.FontSize.Value);

h.edit_subjectpath = uieditfield(...
    'Parent',h.panel_sbj,...
    'Value', '',...
    'Position', [rc+90,t,140,25],...
    'BackgroundColor', scheme.Edit.BackgroundColor.Value,...
    'FontColor', scheme.Edit.FontColor.Value,...
    'FontName',scheme.Edit.Font.Value,...
    'FontSize', scheme.Edit.FontSize.Value);

h.button_subjectpath = uibutton(...
    'Parent', h.panel_sbj,...
    'Text', '...', ...
    'Position', [rc+240, t, 40, 25],...
    'BackgroundColor', scheme.Button.BackgroundColor.Value,...
    'FontColor', scheme.Button.FontColor.Value,...
    'FontName', scheme.Button.Font.Value,...
    'FontSize', scheme.Button.FontSize.Value);

h.dropdown_subjectgender = uidropdown(...
    'Parent',h.panel_sbj,...
    'Items', {'female', 'male', 'other'},...
    'Position', [rc+90,t-80,100,25],...
    'BackgroundColor', scheme.Dropdown.BackgroundColor.Value,...
    'FontColor', scheme.Dropdown.FontColor.Value,...
    'FontName', scheme.Dropdown.Font.Value,...
    'FontSize', scheme.Dropdown.FontSize.Value);

h.spinner_subjectage = uispinner(...
    'Parent', h.panel_sbj,...
    'Value', 20,...
    'Limits', [1,100],...
    'RoundFractionalValues', 'on',...
    'Position', [rc+300,t-80,60,25],...
    'BackgroundColor', scheme.Dropdown.BackgroundColor.Value,...
    'FontColor', scheme.Dropdown.FontColor.Value,...
    'FontName', scheme.Dropdown.Font.Value,...
    'FontSize', scheme.Dropdown.FontSize.Value);

h.dropdown_subjecthand = uidropdown(...
    'Parent', h.panel_sbj,...
    'Items', {'right', 'left', 'both'},...
    'Position', [rc+90,t-120,100,25],...
     'BackgroundColor', scheme.Dropdown.BackgroundColor.Value,...
    'FontColor', scheme.Dropdown.FontColor.Value,...
    'FontName', scheme.Dropdown.Font.Value,...
    'FontSize', scheme.Dropdown.FontSize.Value);

h.check_subjectstatus = uicheckbox(...
    'Parent', h.panel_sbj,...
    'Position', [rc+220, t-120, 150,25],...
    'Text', 'Good Subject',...
    'Value', true,...
    'FontColor', scheme.Checkbox.FontColor.Value,...
    'FontName', scheme.Checkbox.Font.Value,...
    'FontSize', scheme.Checkbox.FontSize.Value);

h.edit_subjcond = uieditfield(...
    'Parent', h.panel_sbj,...
    'Value', '',...
    'Position', [rc+90,t-160,240,25],...
    'BackgroundColor', scheme.Edit.BackgroundColor.Value,...
    'FontColor', scheme.Edit.FontColor.Value,...
    'FontName',scheme.Edit.Font.Value,...
    'FontSize', scheme.Edit.FontSize.Value);

h.button_updatesubject = uibutton(...
    'Parent', h.panel_sbj,...
    'Position', [310, 10, 80, 25],...
    'Text', 'Update',...
    'BackgroundColor', scheme.Button.BackgroundColor.Value,...
    'FontColor', scheme.Button.FontColor.Value,...
    'FontName', scheme.Button.Font.Value,...
    'FontSize', scheme.Button.FontSize.Value);

h.button_cancelsubject = uibutton(...
    'Parent', h.panel_sbj,...
    'Position', [220, 10, 80, 25],...
    'Text', 'Cancel',...
    'BackgroundColor', scheme.Button.BackgroundColor.Value,...
    'FontColor', scheme.Button.FontColor.Value,...
    'FontName', scheme.Button.Font.Value,...
    'FontSize', scheme.Button.FontSize.Value);

uilabel('Parent',h.tab(2),...
    'Position',[10,300,100,20],...
    'Text','Subject list',...
    'FontColor', scheme.Label.FontColor.Value,...
    'FontName', scheme.Label.Font.Value,...
    'FontSize', scheme.Label.FontSize.Value);

h.tree_subjectlist = uitree(...
    'Parent', h.tab(2),...
    'Position', [10,40,250,255],...
    'BackgroundColor', scheme.Edit.BackgroundColor.Value,...
    'FontColor', scheme.Edit.FontColor.Value,...
    'FontName',scheme.Edit.Font.Value,...
    'FontSize', scheme.Edit.FontSize.Value);

h.button_subjectadd = uibutton(...
    'Parent', h.tab(2),...
    'Position', [10, 10, 80, 25],...
    'Text', 'New',...
    'BackgroundColor', scheme.Button.BackgroundColor.Value,...
    'FontColor', scheme.Button.FontColor.Value,...
    'FontName', scheme.Button.Font.Value,...
    'FontSize', scheme.Button.FontSize.Value);

h.button_subjectremove = uibutton(...
    'Parent', h.tab(2),...
    'Position', [100, 10, 80, 25],...
    'Text', 'Delete',...
    'BackgroundColor', scheme.Button.BackgroundColor.Value,...
    'FontColor', scheme.Button.FontColor.Value,...
    'FontName', scheme.Button.Font.Value,...
    'FontSize', scheme.Button.FontSize.Value);

h.button_subjectedit = uibutton(...
    'Parent', h.tab(2),...
    'Position', [190, 10, 80, 25],...
    'Text', 'Edit',...
    'BackgroundColor', scheme.Button.BackgroundColor.Value,...
    'FontColor', scheme.Button.FontColor.Value,...
    'FontName', scheme.Button.Font.Value,...
    'FontSize', scheme.Button.FontSize.Value);

%*************************************************************************
% Bin tab
h.tab(3) = uipanel(...
    'Parent', h.figure,...
    'Position', [10, scheme.Button.Height.Value + 10, width-20, height - scheme.Button.Height.Value - 10-24 ],...
    'BackgroundColor', scheme.Panel.BackgroundColor.Value,...
    'ForegroundColor', scheme.Panel.FontColor.Value,...
    'FontName', scheme.Panel.Font.Value,...
    'FontSize', scheme.Panel.FontSize.Value,...
    'BorderType','line',...
    'Visible','off');

%Bin group list
h.tree_bingrouplist = uitree(...
    'Parent', h.tab(3),...
    'Position', [120,10,200,300],...
    'Multiselect', 'off',...
    'BackgroundColor', scheme.Edit.BackgroundColor.Value,...
    'FontColor', scheme.Edit.FontColor.Value,...
    'FontName',scheme.Edit.Font.Value,...
    'FontSize', scheme.Edit.FontSize.Value);

uilabel('Parent',h.tab(3),...
    'Position', [100,315,100,20],...
    'Text','Epoch Groups',...
    'FontColor', scheme.Label.FontColor.Value,...
    'FontName', scheme.Label.Font.Value,...
    'FontSize', scheme.Label.FontSize.Value);

h.button_bingroupadd = uibutton(...
    'Parent', h.tab(3),...
    'Position', [10, 275, 100, 25],...
    'Text', 'New Group',...
    'BackgroundColor', scheme.Button.BackgroundColor.Value,...
    'FontColor', scheme.Button.FontColor.Value,...
    'FontName', scheme.Button.Font.Value,...
    'FontSize', scheme.Button.FontSize.Value);

h.button_bingroupedit = uibutton(...
    'Parent', h.tab(3),...
    'Position', [10, 245, 100, 25],...
    'Text', 'Edit Group',...
    'BackgroundColor', scheme.Button.BackgroundColor.Value,...
    'FontColor', scheme.Button.FontColor.Value,...
    'FontName', scheme.Button.Font.Value,...
    'FontSize', scheme.Button.FontSize.Value);

h.button_bingroupremove = uibutton(...
    'Parent', h.tab(3),...
    'Position', [10, 215, 100, 25],...
    'Text', 'Remove Group',...
    'BackgroundColor', scheme.Button.BackgroundColor.Value,...
    'FontColor', scheme.Button.FontColor.Value,...
    'FontName', scheme.Button.Font.Value,...
    'FontSize', scheme.Button.FontSize.Value);

h.button_binadd = uibutton(...
    'Parent', h.tab(3),...
    'Position', [10, 185, 100, 25],...
    'Text', 'New Bin',...
    'BackgroundColor', scheme.Button.BackgroundColor.Value,...
    'FontColor', scheme.Button.FontColor.Value,...
    'FontName', scheme.Button.Font.Value,...
    'FontSize', scheme.Button.FontSize.Value,...
    'Enable', 'off');

h.button_binremove = uibutton(...
    'Parent', h.tab(3),...
    'Position', [10, 155, 100, 25],...
    'Text', 'Remove Bin',...
    'BackgroundColor', scheme.Button.BackgroundColor.Value,...
    'FontColor', scheme.Button.FontColor.Value,...
    'FontName', scheme.Button.Font.Value,...
    'FontSize', scheme.Button.FontSize.Value,...
    'Enable', 'off');

%add a tab group for teh bin group and bin edit screens
h.tabgroup_bins = uitabgroup("Parent",h.tab(3),...
    "Position", [330,10,width - 36d0, 320]);
h.tab_trialgroup = uitab(h.tabgroup_bins, "Title", "Trial Groups",...
    'BackgroundColor', scheme.Panel.BackgroundColor.Value);
h.tab_trialdef = uitab(h.tabgroup_bins, "Title","Trial Definition",...
  'BackgroundColor', scheme.Panel.BackgroundColor.Value);

% bin group add/edit tab
 
 h.button_bingroupupdate = uibutton(...
     'Parent', h.tab_trialgroup,...
     'Position', [20, 10, 80, 25],...
     'Text', 'Update Group',...
     'BackgroundColor', scheme.Button.BackgroundColor.Value,...
     'FontColor', scheme.Button.FontColor.Value,...
     'FontName', scheme.Button.Font.Value,...
     'FontSize', scheme.Button.FontSize.Value);
% 
h.button_bingroupcancel = uibutton(...
    'Parent', h.tab_trialgroup,...
    'Position', [110, 10, 80, 25],...
    'Text', 'Revert',...
    'BackgroundColor', scheme.Button.BackgroundColor.Value,...
    'FontColor', scheme.Button.FontColor.Value,...
    'FontName', scheme.Button.Font.Value,...
    'FontSize', scheme.Button.FontSize.Value);

uilabel('Parent', h.tab_trialgroup, ...
    'Position', [20, 270, 160, 25],...
    'Text', 'Name for the bin group',...
    'FontColor', scheme.Label.FontColor.Value,...
    'FontName', scheme.Label.Font.Value,...
    'FontSize', scheme.Label.FontSize.Value,...
    'VerticalAlignment','bottom');

uilabel('Parent', h.tab_trialgroup, ...
    'Position', [20, 210, 160, 25],...
    'Text', 'Epoch filename',...
    'FontColor', scheme.Label.FontColor.Value,...
    'FontName', scheme.Label.Font.Value,...
    'FontSize', scheme.Label.FontSize.Value,...
    'VerticalAlignment','bottom');

uilabel('Parent', h.tab_trialgroup, ...
    'Position', [20 150, 100, 25],...
    'Text', 'Epoch start',    ...
    'FontColor', scheme.Label.FontColor.Value,...
    'FontName', scheme.Label.Font.Value,...
    'FontSize', scheme.Label.FontSize.Value,...
    'VerticalAlignment','bottom');

uilabel('Parent', h.tab_trialgroup, ...
    'Position', [20 90, 100, 25],...
    'Text', 'Epoch end',...    
    'FontColor', scheme.Label.FontColor.Value,...
    'FontName', scheme.Label.Font.Value,...
    'FontSize', scheme.Label.FontSize.Value,...
    'VerticalAlignment','bottom');

h.edit_bingroupname = uieditfield(...,
    'Parent', h.tab_trialgroup,...
    'Position', [20, 240, 160, 25],...
    'BackgroundColor', scheme.Edit.BackgroundColor.Value,...
    'FontColor', scheme.Edit.FontColor.Value,...
    'FontName',scheme.Edit.Font.Value,...
    'FontSize', scheme.Edit.FontSize.Value);

h.edit_epochfilename = uieditfield(...,
    'Parent', h.tab_trialgroup,...
    'Position', [20, 180, 160, 25],...
    'BackgroundColor', scheme.Edit.BackgroundColor.Value,...
    'FontColor', scheme.Edit.FontColor.Value,...
    'FontName',scheme.Edit.Font.Value,...
    'FontSize', scheme.Edit.FontSize.Value);

h.edit_epochstart = uieditfield(...,
    'numeric',...
    'Parent', h.tab_trialgroup,...
    'Position', [20, 120, 160, 25],...
    'ValueDisplayFormat', '%0.3g sec.',...
    'Value', -.1,...
    'BackgroundColor', scheme.Edit.BackgroundColor.Value,...
    'FontColor', scheme.Edit.FontColor.Value,...
    'FontName',scheme.Edit.Font.Value,...
    'FontSize', scheme.Edit.FontSize.Value);

h.edit_epochend = uieditfield(...,
    'numeric',...
    'Parent', h.tab_trialgroup,...
    'Position', [20, 60, 160, 25],...
    'ValueDisplayFormat', '%0.3g sec.',...
    'Value', .5,...
    'BackgroundColor', scheme.Edit.BackgroundColor.Value,...
    'FontColor', scheme.Edit.FontColor.Value,...
    'FontName',scheme.Edit.Font.Value,...
    'FontSize', scheme.Edit.FontSize.Value);
 
%     % ***** indivudal bin add/edit panel
uilabel('Parent', h.tab_trialdef, ...
    'Position', [20 260,220,25],...
    'Text', 'Bin Name: The mean data in the bin will appear using this name',...
    'FontColor', scheme.Label.FontColor.Value,...
    'FontName', scheme.Label.Font.Value,...
    'FontSize', scheme.Label.FontSize.Value,...
    'WordWrap','on',...
    'VerticalAlignment','bottom');

uilabel('Parent', h.tab_trialdef, ...
    'Position', [20, 188, 220, 25],...
    'Text', 'Bin Events: Include all trials with these events codes in the bin (conditions).',...
    'FontColor', scheme.Label.FontColor.Value,...
    'FontName', scheme.Label.Font.Value,...
    'FontSize', scheme.Label.FontSize.Value,...
    'VerticalAlignment','bottom',...
    'WordWrap','on');

h.edit_binname = uieditfield(...,
    'Parent', h.tab_trialdef,...
    'Position', [20, 230, 220, 25],...
    'BackgroundColor', scheme.Edit.BackgroundColor.Value,...
    'FontColor', scheme.Edit.FontColor.Value,...
    'FontName',scheme.Edit.Font.Value,...
    'FontSize', scheme.Edit.FontSize.Value);

h.edit_eventlist = uitextarea(...,
    'Parent', h.tab_trialdef,...
    'Position', [20, 45, 220, 125],...
    'BackgroundColor', scheme.Edit.BackgroundColor.Value,...
    'FontColor', scheme.Edit.FontColor.Value,...
    'FontName',scheme.Edit.Font.Value,...
    'FontSize', scheme.Edit.FontSize.Value);

h.button_addbin = uibutton(...
    'Parent', h.tab_trialdef, ...
    'Position', [20, 10, 80, 25],...
    'Text', 'Add bin', ...
    'BackgroundColor', scheme.Button.BackgroundColor.Value,...
    'FontColor', scheme.Button.FontColor.Value,...
    'FontName', scheme.Button.Font.Value,...
    'FontSize', scheme.Button.FontSize.Value,...
    'UserData', 0);

h.button_canceladdbin = uibutton(...
    'Parent', h.tab_trialdef, ...
    'Position', [110, 10, 80, 25],...
    'Text', 'Cancel', ...
    'BackgroundColor', scheme.Button.BackgroundColor.Value,...
    'FontColor', scheme.Button.FontColor.Value,...
    'FontName', scheme.Button.Font.Value,...
    'FontSize', scheme.Button.FontSize.Value,...
    'UserData', 0);


%*************************************************************************
%channel group tab
h.tab(4) = uipanel(...
    'Parent', h.figure,...
    'Position', [10, scheme.Button.Height.Value + 10, width-20, height - scheme.Button.Height.Value - 10-24 ],...
    'BackgroundColor', scheme.Panel.BackgroundColor.Value,...
    'ForegroundColor', scheme.Panel.FontColor.Value,...
    'FontName', scheme.Panel.Font.Value,...
    'FontSize', scheme.Panel.FontSize.Value,...
    'BorderType','line',...
    'Visible','off');


h.axis_chanpicker = uiaxes(...
    'Parent', h.tab(4),...
    'Position', [210,0,450,330],...
    'XTick', [], 'YTick', [],...
    'BackgroundColor', scheme.Axis.BackgroundColor.Value,...
    'Color', scheme.Axis.BackgroundColor.Value,...
    'XColor', scheme.Axis.BackgroundColor.Value,...
    'YColor', scheme.Axis.BackgroundColor.Value);
h.axis_chanpicker.Toolbar.Visible = 'off';
h.axis_chanpicker.Interactions = [];
h.axis_chanpicker.PlotBoxAspectRatio = [1,1,1];
h.axis_chanpicker.PlotBoxAspectRatioMode = 'manual';

h.list_chanpicker = uilistbox(...
    'Parent', h.tab(4),...
    'Position', [662, 10, 85, 305],...
    'Multiselect', 'on',...
    'BackgroundColor', scheme.Edit.BackgroundColor.Value,...
    'FontColor', scheme.Edit.FontColor.Value,...
    'FontName',scheme.Edit.Font.Value,...
    'FontSize', scheme.Edit.FontSize.Value);

uilabel('Parent', h.tab(4),...
    'Position', [662,315,100,20],...
    'Text', 'Channel list',...
    'FontColor', scheme.Label.FontColor.Value,...
    'FontName', scheme.Label.Font.Value,...
    'FontSize', scheme.Label.FontSize.Value);

h.tree_changroup = uitree(...
    'Parent', h.tab(4),...
    'Position', [10,10,125,305],...
    'BackgroundColor', scheme.Edit.BackgroundColor.Value,...
    'FontColor', scheme.Edit.FontColor.Value,...
    'FontName',scheme.Edit.Font.Value,...
    'FontSize', scheme.Edit.FontSize.Value);

uilabel('Parent', h.tab(4),...
    'Position', [10,315,100,20],...
    'Text', 'Channel Groups',...
    'FontColor', scheme.Label.FontColor.Value,...
    'FontName', scheme.Label.Font.Value,...
    'FontSize', scheme.Label.FontSize.Value);

h.button_addchangroup = uibutton(...
    'Parent', h.tab(4),...
    'Position', [145,295,100,25],...
    'Text', 'New Group',...
    'BackgroundColor', scheme.Button.BackgroundColor.Value,...
    'FontColor', scheme.Button.FontColor.Value,...
    'FontName', scheme.Button.Font.Value,...
    'FontSize', scheme.Button.FontSize.Value);

h.button_updatechangroup = uibutton(...
    'Parent', h.tab(4),...
    'Position', [145,265,100,25],...
    'Text', 'Update Group',...
    'BackgroundColor', scheme.Button.BackgroundColor.Value,...
    'FontColor', scheme.Button.FontColor.Value,...
    'FontName', scheme.Button.Font.Value,...
    'FontSize', scheme.Button.FontSize.Value,...
    'Enable','off');

h.button_removechangroup = uibutton(...
    'Parent', h.tab(4),...
    'Position', [145,235,100,25],...
    'Text', 'Remove Group',...
    'BackgroundColor', scheme.Button.BackgroundColor.Value,...
    'FontColor', scheme.Button.FontColor.Value,...
    'FontName', scheme.Button.Font.Value,...
    'FontSize', scheme.Button.FontSize.Value,...
    'Enable','off');

h.button_savechangroup = uibutton(...
    'Parent', h.tab(4),...
    'Position', [145,205,100,25],...
    'Text', 'Save to file',...
    'BackgroundColor', scheme.Button.BackgroundColor.Value,...
    'FontColor', scheme.Button.FontColor.Value,...
    'FontName', scheme.Button.Font.Value,...
    'FontSize', scheme.Button.FontSize.Value,...
    'Enable','off');

h.button_loadchangroup = uibutton(...
    'Parent', h.tab(4),...
    'Position', [145,175,100,25],...
    'Text', 'Load from file',...
    'BackgroundColor', scheme.Button.BackgroundColor.Value,...
    'FontColor', scheme.Button.FontColor.Value,...
    'FontName', scheme.Button.Font.Value,...
    'FontSize', scheme.Button.FontSize.Value,...
    'Enable','off');

h.button_clearselchans= uibutton(...
    'Parent', h.tab(4),...
    'Position', [145,145,100,25],...
    'Text', 'Clear selected',...
    'BackgroundColor', scheme.Button.BackgroundColor.Value,...
    'FontColor', scheme.Button.FontColor.Value,...
    'FontName', scheme.Button.Font.Value,...
    'FontSize', scheme.Button.FontSize.Value,...
    'Enable','off');

h.label_chanselectedsummary = uilabel(...
    'Parent', h.tab(4),...
    'Position', [145, 10, 300, 25],...
    'Text', 'Left mouse click to select an electrode. Shift+Left+Drag to select many electrodes.',...
    'FontColor', scheme.Label.FontColor.Value,...
    'FontName', scheme.Label.Font.Value,...
    'FontSize', scheme.Label.FontSize.Value);

%Context menus
h.cm_epochlist = uicontextmenu(h.figure);

uimenu(h.cm_epochlist, 'Text', 'Edit', 'MenuSelectedFcn', {@callback_editbingroup, h});
uimenu(h.cm_epochlist, 'Text', 'Delete', 'MenuSelectedFcn', {@callback_removebingroup, h});