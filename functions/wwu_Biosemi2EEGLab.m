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

%   ApplyFilt       A boolean indicating wether to apply a filter to the
%                   data (default = false)
%   LPass           The cuttoff for the low pass filter to apply
%
%   Hpass           The cut off for a high pass filter to apply
%
%   OWrite          An integer  indicating whether to overwrite [1] an
%   existing output file. The default [0] is to skip conversion when the 
%   output file already exists.  If OWrtite = 2, the user will be promopted
%   for how to handle existing files.
%
%   FigHandle       the handle to a figure for showing the dialog box used
%   for prompting the user about whether to overwrite existing output
%   files.  This shoudl always be provided when OWrite = 2;
%
%   FileExt         This strng will be added to the filename as a way of
%   making the name distinct from other files.  The '.set' extension will
%   still be added at the end
%
%   SaveAsStruct  A boolean indicating whether to save the EEG file in
%   struct formatusing the wwu_SaveEEGFile function will be used.  This may
%   make the file format incompatible with EEGlab. Default true
%
function results = wwu_Biosemi2EEGLab(filelist, varargin)

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
    'ChanFile',     'string', [], '';...
    'SaveAsStruct', 'real', [0, 1], 1
    });

%start by using the existing EEGlab routines to convert the BDF file to
%EEGLab format.  Make sure to keep the status channel if desired
if isempty(filelist)
    sprintf('ERROR: no valid files to process\n');
    return
end

nfiles = length(filelist);

if ~isempty(p.FigHandle)
    wb  = uiprogressdlg(p.FigHandle,'Message', 'Converting', 'Title','biosemi 2 eeglab');
else
    wb = waitbar(0, 'Converting');
end

results = cell(nfiles, 2);
for ii = 1:nfiles
    if ~isempty(p.FigHandle)
        wb.Message = sprintf('Converting file %i of %i', ii, nfiles);
        wb.Value = ii/nfiles;
    else
        waitbar(ii/nfiles, wb, sprintf('Converting file %i of %i', ii, nfiles));
    end

    [path, name, ~] = fileparts(filelist{ii});
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
            results{ii,1} = false;
            continue
        end
     
    end
    results{ii, 1} = true;
    results{ii, 2} = outname;

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
               
%if not speficied then do not assign channels
    if ~isempty(p.Chanlocs)
        EEG.chanlocs = p.Chanlocs;
        EEG = eeg_checkset(EEG);
    end    
    if ~isempty(p.ChanFile)
            EEG.chanlocs = readlocs(p.ChanFile);
        EEG = eeg_checkset(EEG);
    end
       
    %convert data to the average reference
    if (p.AvgRef==1)        
        EEG = pop_reref(EEG, []);
        EEG = eeg_checkset( EEG );
    end
    
    %filter the data   
    if p.ApplyFilt
        if ~isempty(p.Hpass)
            EEG = pop_eegfilt(EEG, p.Hpass,0);
            EEG = eeg_checkset( EEG );
        end
        if ~isempty(p.Lpass)
            EEG = pop_eegfilt(EEG, 0, p.Lpass);
            EEG = eeg_checkset( EEG );
        end
    end
    EEG = eeg_checkset( EEG );
    if p.SaveAsStruct
        wwu_SaveEEGFile(EEG, fullfile(path, outname));
    else
        save(fullfile(path, outname), 'EEG', '-mat');
    end    
    
    if ~isempty(p.ChanstoStrip)
        EEGAI.event = EEG.event;
        EEGAI.urevent = EEG.urevent;
        EEGAI = pop_saveset(EEGAI, 'filename', outname_ai);
    end       
    warning on;
    fprintf('....DONE.....');    
end
close(wb);
