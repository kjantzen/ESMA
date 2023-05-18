function study_eventsummary_GUI(study, filenames)
 
%p = plot_params;
scheme = eeg_LoadScheme;

%default the size of the window
W = 400;
H = 400;

sz = get(0, 'ScreenSize');
figpos = [(sz(3) - W)/2, (sz(4)-H)/2, W, H];

handles.figure = uifigure(...
    'Position', figpos,...
    'NumberTitle', 'off',...
    'Menubar', 'none',...
    'Color', scheme.Window.BackgroundColor.Value);

handles.info = uilabel('Parent', handles.figure,...
    'Position', [10, H-30, W-20, 30],...
    'FontName',scheme.Label.Font.Value,...
    'FontColor',scheme.Label.FontColor.Value,...
    'FontSize', scheme.Label.FontSize.Value);

handles.tabgrp = uitabgroup('Parent', handles.figure, ...
    'Units', 'pixels', ...
    'Position', [0,0,W,H-31]);

handles.tab1 = uitab('Parent', handles.tabgrp,...
    'Title', 'All Events',...
    'BackgroundColor',scheme.Panel.BackgroundColor.Value);

handles.tab2 = uitab('Parent', handles.tabgrp,...
    'Title', 'Epoch Onset Events',...
    'BackgroundColor',scheme.Panel.BackgroundColor.Value);

drawnow;
[eTable, pTable] = load_eventdata(handles, study, filenames);
handles.allTable = uitable('Parent', handles.tab1, 'Data', eTable,...
    'RowStriping','off');

if ~isempty(pTable)
    handles.epochTable = uitable('Parent', handles.tab2, 'Data', pTable);
end

%**************************************************************************
function [eventsTable, epochsTable] = load_eventdata(h, study, filenames)

     pbar = uiprogressdlg(h.figure,...
            'Title', 'loading event data ',...
            'ShowPercentage', 'on');

    HAS_EPOCHS = false;
    nfiles = length(filenames);
    columnName = cell(1,nfiles);
    for ii = 1:nfiles
        pbar.Value = ii/nfiles;
    
        [fpath, fname, fext] = fileparts(filenames{ii});
        fname = [fname, fext];
        fprintf('Loading event data for file %s\n', fname);
        EEG = wwu_LoadEEGFile(filenames{ii}, {'event', 'trials', 'epoch'});
        fprintf('getting all event types from the EEG structure...\n')
        allTypes = {EEG.event.type};
        
        %convert numeric events to strings
        allTypes = cellfun(@(x) num2str(x), allTypes, 'UniformOutput',false);

        columnName{ii}= study.subject(ii).ID;
        cevents = unique(allTypes, 'sorted');
        if ii == 1
            all_gevents = cevents;
            all_count = zeros(nfiles, length(all_gevents));
        else
            [all_gevents, all_count] = compareevents(cevents, all_gevents, all_count);
        end
        for jj = 1:length(all_gevents)
            all_count(ii,jj) = sum(strcmp(allTypes, all_gevents{jj}));
        end

        if EEG.trials > 1
             fprintf('Epochs detected.  Getting epoch onset events...\n');
             t = arrayfun(@(x) getonsettype(x), EEG.epoch);
             cevents = unique(t, 'sorted');
             if ii == 1
                 HAS_EPOCHS = true;
                 epoch_gevents = cevents;
                 epoch_count = zeros(nfiles, length(epoch_gevents));
             else
                 [epoch_gevents, epoch_count] = compareevents(cevents, epoch_gevents, epoch_count);
             end
             for jj = 1:length(epoch_gevents)
                 epoch_count(ii,jj) = sum(cell2mat(strfind(t, epoch_gevents{jj})));
             end
        end
    end
    %create the table
    varType = repmat({'double'}, 1,nfiles);
    eventsTable = table('Size', size(all_count'), 'VariableTypes', varType, 'VariableNames', columnName, 'RowNames',all_gevents);
    eventsTable.Variables = all_count';
    h.info.Text = ['Events for file: ' fname];

    if HAS_EPOCHS
        epochsTable = table('Size', size(epoch_count'), 'VariableTypes', varType, 'VariableNames',columnName,'RowNames',epoch_gevents);
        epochsTable.Variables = epoch_count';
    else
        epochsTable = [];
        delete(h.tab2);

    end
 

    close(pbar);
%**************************************************************************
function [gevents, count] = compareevents(cevents, gevents, count)
%compare the current events to teh group events and adds a new event to the
%existing list if it is not already there

%nothing to do if the event structures are the same
if isequal(cevents, gevents)
    fprintf('matching events found...\n');
    return; 
end

fprintf('appending new events to master list...\n')
for ee = 1:length(cevents)
    if sum(contains(gevents, cevents(ee))) == 0
        gevents(end + 1) = cevents(ee);
        count(:, end + 1) = 0;
    end
end

%**************************************************************************
function type = getonsettype(s)
    indx = find(cell2mat(s.eventlatency)==0);
    type = s.eventtype(indx(1));


