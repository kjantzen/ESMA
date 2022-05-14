%   wwu_Biosemi2EEGLab
%   wwu_Biosemi2EEGLab(filelist) - converts the files listed in the cell
%   array FILELIST from BIOSEMI BDF format to the EEGLAB set format.
%   This function accounts for the specific trigger inputs used in the
%   HCND lab.
%
%   0ptional parameter name, value pairs
%   ChanFile       A string providing the name and path of a EEGLAB readable channel
%   position file.  All files being converted will be assigned the channel names and
%   locations in the specified file.
%
%   ChansToStrip    An integer vector specifying Analog Input channels to
%   remove from the main data file and save as a seperate file with '_AI' added
%   to the file name.
%
%   AveRef          A boolean indicated whether to compute the average
%   reference of the data [1] or to leave the data unreferenced [0:
%   default]
%
%   LPass           The cuttoff for the low pass filter to apply
%
%   Hpass           The cut off for a high pass filter to apply
%
%   OWrite          A boolean  indicating whether to overwrite [1] an
%   existing output file. The default [0] is to skip conversion when the 
%   output file already exists 
%
%   FileExt         This strng will be added to the filename as a way of
%   making the name distinct from other files.  The '.set' extension will
%   still be added at the end
%
function [Trig_Events, Btn_Events] = wwu_Biosemi2EEGLab(filelist, varargin)

warning off;

p = wwu_finputcheck(varargin, {...
    'ChanstoStrip', 'integer', [], [];...
    'AvgRef',       'real', [0,1], 0;...
    'Lpass',        'real', [], [];...
    'Hpass',        'real', [], [];...
    'OWrite',       'integer', [0:2], 0;...
    'FileExt',      'string', [], '';...
    'FigHandle',    'handle', [], [];...
    'ApplyFilt',    'real', [0,1], 0;...
    'Chanlocs',     'struct', [], struct;...
    'ChanFile',     'string', [], ''
    });

%start by using the existing EEGlab routines to convert the BDF file to
%EEGLab format.  Make sure to keep the status channel if desired
if isempty(filelist)
    sprintf('ERROR: no valid files to process\n');
    return
end

nfiles = length(filelist);
wsteps = nfiles * 5;
wstep = 0;
wb = waitbar(0, 'Converting');

for ii = 1:nfiles
    
    MText = sprintf('Converting file %i of %i', ii, nfiles);
    [path, name, ext] = fileparts(filelist{ii});
    outname = [name, '.cnt'];
  
    
    %if the output file already exists
    if isfile(fullfile(path, outname))
        fprintf('Existing file %s found...', outname);
        %see how the user wants to handle this scenario
        if p.OWrite == 1    %just overwrite the previous file
            fprintf('Converting and Overwriting\n\n');
        elseif p.OWrite == 2    %ask what to do
            msg = sprintf('The file %s already exists.', outname);
            response = uiconfirm(p.FigHandle, msg, 'File Exists', ...
                    'Options',{'Overwrite','Save as new','Skip Existing'}, ...
           'DefaultOption',2,'CancelOption',3);
             switch response
                 case 'Overwrite'
                    p.OWrite = 1;
                 case 'Save as new'
                     p.OWrite = 3;
                     outname = ['name', '_1.cnt']; 
                 case 'Skip Existing'
                     p.OWrite = 0;
             end
             
        elseif p.OWrite == 3 %assign a new name to the file
            outname = ['name', '_1.cnt']; 
        else
            p.Owrite = 0;
            fprintf('Skipping file\n\n');
            continue
        end
     
    end
    
    
    
    wstep = wstep + 1;
    waitbar(wstep/wsteps, wb, sprintf('%s\n loading file...', MText));
    
    EEGraw = pop_biosig(filelist{ii},  'rmeventchan', 'on', 'importannot', 'off');
    EEGraw.setname=name;
    EEGraw = eeg_checkset( EEGraw );
    
    %lets assume for now that we want to get rid of all channels greater than
    %64 for the moment.
    %status = squeeze(EEGraw.data(EEGraw.nbchan,:));
    EEG = pop_select( EEGraw, 'nochannel',65:EEGraw.nbchan);
    EEG = eeg_checkset( EEG );
    
    if ~isempty(p.ChanstoStrip)
        EEGAI = pop_select( EEGraw, 'channel', p.ChanstoStrip(ii,:));
        EEGAI = eeg_checkset(EEGAI);
        outname_ai = [name, '_ai.set'];
    end
    
    
    %now read through the stats channel to decode all the triggers.
    %convert the channel to unsigned 32 bit integer
    %read the low byte - which in our lab is the software trigger byte
    %EEG = wwu_decodetrigchannel(status, EEG);
    % Btn_Events = wwu_decodebuttonchannel(status);
    
    wstep = wstep + 1;
    waitbar(wstep/wsteps, wb, sprintf('%s\n scanning event channel...', MText));
  
 %%   
    
    wstep = wstep + 1;
    waitbar(wstep/wsteps, wb, sprintf('%s\n assigning event types...', MText));
    
    %     for ii = 1:length(EEG.event)
    %         if isnumeric(EEG.event(ii).type)
    %             EEG.event(ii).type = sprintf('U%i', EEG.event(ii).type);
    %             EEG.urevent(ii).type = sprintf('U%i', EEG.urevent(ii).type);
    %         end
    %     end

    
%if not speficied then do not assign channels

    if ~isempty(p.Chanlocs)
        EEG.chanlocs = p.Chanlocs;
        EEG = eeg_checkset(EEG);
    end
    
    if ~isempty(p.ChanFile)
            EEG.chanlocs = readlocs(p.ChanFile);
        EEG = eeg_checkset(EEG);
    end
    
    wstep = wstep + 1;
    
    %convert data to the average reference
    if (p.AvgRef==1)
        waitbar(wstep/wsteps, wb, sprintf('%s\n rereferencing...', MText));
        
        EEG = pop_reref(EEG, []);
        EEG = eeg_checkset( EEG );
    end
    
    %filter the data
    
    if p.ApplyFilt
        if ~isempty(p.Hpass)
            waitbar(wstep/wsteps, wb, sprintf('%s\n Applying high pass pass filter (this may take a while)...', MText));
            EEG = pop_eegfilt(EEG, p.Hpass,0);
            EEG = eeg_checkset( EEG );
        end
        if ~isempty(p.Lpass)
            waitbar(wstep/wsteps, wb, sprintf('%s\n Applying low pass filter...', MText));
            EEG = pop_eegfilt(EEG, 0, p.Lpass);
            EEG = eeg_checkset( EEG );
        end
    end
    waitbar(wstep/wsteps, wb, sprintf('%s\n Saving...', MText));
    EEG = eeg_checkset( EEG );
    save(fullfile(path, outname), 'EEG', '-mat');
    %EEG = pop_saveset( EEG,  'filename', outname, 'filepath', path, 'savemode', 'onefile');
    
    
    if ~isempty(p.ChanstoStrip)
        EEGAI.event = EEG.event;
        EEGAI.urevent = EEG.urevent;
        EEGAI = pop_saveset(EEGAI, 'filename', outname_ai);
    end
    
    
    warning on;
    fprintf('....DONE.....');
    
end

close(wb);
%this function is depricated
%**************************************************************************
function EEGOut = wwu_decodetrigchannel(status, EEG)

%BITMASK = 255;

%initialize a variable
sEventData = [];
%make a copy of the data
EEGOut = EEG;

% %these are events from the stimtracker
% StimChannel = bitand(status, 32);
% StimOnset = find(diff(StimChannel)>0)+1;
% StimEvent(1:length(StimOnset)) = 10;
% 
% %these are button pushes from the stimtracker although I think there is
% %only one being used here so more code is probably needed
% ButtonChannel = bitand(status, 1024);
% ButtonOnset = find(diff(ButtonChannel)>0) + 1;
% ButtonEvent(1:length(ButtonOnset)) = 100;

Event_Channel = bitand(status, double(intmax('uint16')));
Event_Onset = find(diff(Event_Channel)>0)+1;


%this decodes the event marker bits coming from the stimulus computer
%they appear on the middle three bits of a 16 bit value
% DecVals = [4,2,1];
% CondBits = [bitget(status, 10);bitget(status, 9);bitget(status, 8)]';
% for ii = 1:length(CondBits);
%     CondDec(ii) = sum(CondBits(ii,:).*DecVals);
% end
% CondOnset = find(diff(CondDec)>0)+1;
% CondEvent(1:length(CondOnset)) = CondDec(CondOnset);

%CellArray = num2cell([StimOnset,ButtonOnset, CondOnset;StimEvent, ButtonEvent, CondEvent]);
CellArray = num2cell([Event_Onset,; Event_Channel(Event_Onset)]);
    
CellArray = CellArray';
%CellArray = sortrows(CellArray,1);
CellArray(:,3) = num2cell(1:length(CellArray));


urevent = struct('type', CellArray(:,2), 'latency', CellArray(:,1), 'duration', num2cell(ones(length(CellArray),1)));
event = struct('type', CellArray(:,2), 'latency', CellArray(:,1), 'duration', num2cell(ones(length(CellArray),1)), 'urevent', CellArray(:,3));

EEGOut.urevent = urevent;
EEGOut.event = event;


%**************************************************************************
function btn_events = wwu_decodebuttonchannel(status)

BITMASK = 65280;

bchannel  = bitand(status, BITMASK);
idx = find(diff(bchannel))+1;
bval = bchannel(idx);

btn_events = struct([]);
nevents = 0;

for ii = 1:length(bval)
    for jj = 1:8
        if (bitand(bval(ii), 2^(jj+7))>0)
            nevents = nevents+1;
            btn_events(nevents).button = jj;
            btn_events(nevents).tpoint = idx(ii);
        end
    end
end

