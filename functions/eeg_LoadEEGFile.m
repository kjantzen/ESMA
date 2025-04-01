%EEG = eeg_LoadEEGFile(filename, field)
% 
%   INPUTS 
%   filename -    a string containing the name of the file to load
%   field    -    an optional  cell array of field names to load or
%   'header' to load all fields except .data and .icaact
%
%   OUTPUT 
%   EEG     -   an EEG file structure.  The structure can be either an
%   eeglab structure which in ESMA are either .cnt or .epc files, or a Mass
%   Univeriate toolsbox GND file format which ESMA uses for ERP files.  If
%   loading fails, EEG will be empty.
%   
%   ESMA EEG function to load EEG data files
%   If the FIELD input is included, only data from the specific fields in the 
%   in the data structure will be loaded.  For example:
%   
%   EEG = eeg_LoadEEGFIle('test.cnt', {'chanlocs'}) 
%   
%   would return an EEG structure that contains only
%   the field chanlocs with all the channel locations from the data file.  
%   
%    
%   This function
%   can speed up loading when only specific limited information is desired.
%   If a field argument is not included the entire data strucure is loaded
%   and returned.  If the requested field does not exist, the entire
%   contents of the file is return.
%
%   NOTE - this function will also recalalculate ica activations when
%   loading a file.
function EEG = eeg_LoadEEGFile(filename, field)

EEG = [];
if nargin < 1
    help eeg_LoadEEGFile;
    return
end
if nargin < 2
    field = '';
end
if ~isfile(filename)
    warning('File %s does not exist\n', filename);
    return
end
[fpath,fname,fileext] = fileparts(filename);

%check to see if the user wishes to load only a subset of the data fields
if ~isempty(field)
    if strcmp(field, 'header')
        EEG = load(filename, '-mat', '-regexp', '^(?!data$|icaact$).');
    else
        cmd = sprintf('load(''%s'', ''-mat''', filename);
        if iscell(field)
            for ii = 1:length(field)
                cmd = [cmd, ',''',field{ii}, ''''];
            end
            cmd = [cmd, ')'];
        else
            cmd = [cmd, ',''', field, ''')'];
        end
        EEG = eval(cmd);
        %if the field does not exist, revert to the default
        if ~isfield(EEG, field)
            EEG = eeg_LoadEEGFile(filename);
            return;
        end
    end
else
    EEG = load(filename, '-mat');
    %handles version differences since previously files were not saved with the
    % struct option
    if isfield(EEG, 'EEG')
        EEG = EEG.EEG;
    elseif isfield(EEG, 'GND')  %allow for using this function to open GND files as well
        EEG = EEG.GND;
    end

    %continuous and epoched files are faithful to the eeglab format so they can
    %be checked using eeglab tools
    if strcmp(fileext, '.cnt') || strcmp(fileext, '.epc')
        EEG = eeg_checkset(EEG);
    end

    %check to see if there are some ICA components in the file and if there
    %are recompute the icaacts - this is done because depnding on version
    %an platform, the file may or may not be saved withe the ica
    %activations
    if isfield(EEG, 'icaweights')  && isfield(EEG, 'icasphere') && isfield(EEG, 'icaact') && ~isempty(EEG.icaweights)
        for ii = 1:EEG.trials
            EEG.icaact(:,:,ii) = icaact(EEG.data(:,:,ii), EEG.icaweights * EEG.icasphere);
        end
    end
end
%set default file and saved values
EEG.saved = 'yes';
EEG.filename = [fname, fileext];
EEG.filepath = fpath;




