%status study_ExtractEpochs(files, varargin)
%Inputs:
%   files:  A cell array containing the full name and path of each file to
%   process.
%Optional inputs are entered as keyword, value pairs
%   'Outfile', 'string', where sting is the name of the output file without an extension
%   'Events', 'carray', where carray is a cell array of event values to use in determine how to
%   epoch the data
%   'EpochStart', start, where start is a real value indicating the time of 
%   the epoch start in seconds relative to the events listed in Event 
%   'EpochEnd', end, where end is a real value indicating the time of the
%   end of the epoch in seconds relative to the events listed in Event
%   'Overwrite' [0], a value of 0 (default) indicates to skip saving an files 
%   that already exist. A value of 1 will automatically overwrite and a
%   value of 2 indicates to check with the user in the event the file
%   exists.
%   'FileExt', ext, where ext is a string giving the file extension to use
%   (default '.epc')
%   
%outputs
%   status = 0 if there was an error and 1 if the operation completed
%   normally
function [status, exclude_decision] = study_ExtractEpochs(selfiles, varargin)

p = wwu_finputcheck(varargin, {...
    'Outfile', 'string', [], 'epoch_files';...
    'Events',       'cell', [], [];...
    'EpochStart',        'real', [], -.1;...
    'EpochEnd',        'real', [], .5;...
    'ExcludeBad', 'integer', [0,1], [];...
    'Overwrite',       'integer', [0:2], 0;...
    'FileExt',      'string', [], '.epc';...
    'FigHandle',   'handle',  [], [];...
    'BinFile',      'string', [], []...
    }, [], 'ignore');



status = 0;  %assume things went wrong

if isempty(selfiles)
    return
end


OWrite = p.Overwrite;
p.Events = split(p.Events);

if isempty(p.ExcludeBad)
    
    %get an idea of what kind of data this is
    [fpath, fname, fext] = fileparts(selfiles{1});
    EEGHead = wwu_LoadEEGFile(selfiles{1});

    %EEGHead = pop_loadset('filename', [fname, fext], 'filepath', fpath, 'loadmode', 'info');
    if EEGHead.trials>1  && isempty(p.ExcludeBad)
        
        response = uiconfirm(p.FigHandle, 'It looks like you are epoching already epoched data.  Do you want to exclude bad trials from your new epochs?', 'Extract Epochs', 'Options', {'Cancel','No', 'Yes'},...
            'DefaultOption', 3, 'CancelOption', 1);
        switch response
            case 'Yes'
                p.ExcludeBad = true;
            case 'No'
                p.ExcludeBad = false;
            case 'Cancel'
                return;
        end
    end
end


exclude_decision = p.ExcludeBad;
for kk = 1:length(selfiles)
    
    
    [fpath, fname, fext] = fileparts(selfiles{kk});
    outfilename =  fullfile(fpath, [p.Outfile, p.FileExt]);
    

    if exist(outfilename, 'file')
        if OWrite == 0 %skip when output file exists 
            fprintf('File %s already exists\nAborting file creation ...\n', outfilename);
            continue
        elseif OWrite==2
            response = questdlg(sprintf('At least one output file already exists!\nWould you like to overwrite?'),...
                'Extract Eopochs', 'Overwrite All', 'Overwrite Current', 'Ignore Existing', 'Ignore Existing');
            switch response
                case 'Overwrite All'
                    OWrite = 1;
                case 'Ignore Existing'
                    OWrite = 0;
                    continue
            end 
        end
    end
                    
 
    %remove bad trials before extracting epochs
    
    %EEGraw = pop_loadset('filepath',  fpath, 'filename', [fname, fext]);
    EEGraw = wwu_LoadEEGFile(selfiles{kk});
    badtrial_list = study_GetBadTrials(EEGraw);
    bad_comps = EEGraw.reject.gcompreject;  %store the bad component list so it can be restored to the new epochs
    if(check_for_events(EEGraw, p.Events))
        if p.ExcludeBad
            EEGraw = pop_rejepoch(EEGraw, badtrial_list, 0);
        end
        %convert all event markers to strings
        for ii = 1:length(EEGraw.event)
            EEGraw.event(ii).type = num2str(EEGraw.event(ii).type);
        end
        
        EEG = pop_epoch(EEGraw, p.Events, [p.EpochStart, p.EpochEnd]);
        if EEG.xmin < 0
            baseWin = [EEG.xmin, 0];
        else
            baseWin = [EEG.xmin, EEG.xmax];
        end
        EEG = pop_rmbase(EEG, baseWin); %remove the offset
        EEG.reject = [];
        EEG = eeg_checkset(EEG);
        EEG.reject.gcompreject = bad_comps;
        if ~isempty(p.BinFile)
            if isfield(EEG, 'bindesc')
                EEG = remove_bins(EEG);
            end
            EEG = bin_info2EEG(EEG, p.BinFile);
            
            
        end
        wwu_SaveEEGFile(EEG, fullfile(fpath, [p.Outfile, p.FileExt]));
        
  
    end
    
end
status = 1; %must be OK if we got this far

%*************************************************************************
%this function removes bins placed by the bin_info2EEG function of the mass
%univariate toolbox.  THis is needed when extracting epochs from already
%epoched data
function EEG = remove_bins(EEG)

bin_names = split(strtrim(sprintf('bin%i ', 1:length(EEG.bindesc))))';

%first remove the information from each epoch
for ii = 1:length(EEG.epoch)
    bin_evs = find(contains(EEG.epoch(ii).eventtype, bin_names));
    EEG.epoch(ii).eventtype(bin_evs) = [];
    EEG.epoch(ii).event(bin_evs) = [];
    EEG.epoch(ii).eventlatency(bin_evs) = [];
    EEG.epoch(ii).eventurevent(bin_evs) = [];
end

%now get rid of the events in teh event structure
for ii = length(EEG.event):-1:1
    if sum(strcmp(bin_names, EEG.event(ii).type)) > 0
        EEG.event(ii) = [];
    end
end

%finally get rid of the bid description field
EEG = rmfield(EEG, 'bindesc');

function status = check_for_events(EEG, events)

status = 1;
%evnt_str = cellstr(int2str([EEG.event(:).type]'));
evnt_str = {EEG.event.type};

for ii = 1:length(events)
    ncnt = strmatch(events{ii},evnt_str);
    if ~isempty(ncnt) return; end
end
status = 0;






