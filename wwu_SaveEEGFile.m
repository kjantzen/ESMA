function EEG = wwu_SaveEEGFile(EEG, filename, variables)
%EEG = wwu_SaveEEGFile(EEG, filename, variables) - save the eeg data in EEG to the
%file specified in filename.  If omitted, the filename stored in the EEG
%structure will be used.
%
%INPUTS
%   EEG - an EEG structure to save
%
%   filename - a string containing the name of the file to store the EEG
%   structure to.
%
%   variables - an options cell array of the names of the EEG fields to
%   save.  This can save considerable time when only small changes are made
%   to the structure

if nargin < 1
    help wwu_SaveEEGFile;
    return;
end
if nargin < 2 || isempty(filename)
    if (isempty(EEG.filepath) || isempty(EEG.filename))
        warning('The EEG file does not contain valid filename information. Please save the data manually!');
        return;
    else
        filename = fullfile(EEG.filepath, EEG.filename);
    end
end


if nargin < 3
    variables = [];
end

[fpath, fname, fext] = fileparts(filename);
%check if this is an eeglab file type and check its consistencny if it is
if strcmp(fext, '.cnt') || strcmp(fext,'.epc')
        EEG = eeg_checkset(EEG);
end
%save the information in the EEG structure so that it can be used in the
%future instead of relying on the filename input.
if isempty(variables)
    
    EEG.filepath = fpath;
    EEG.filename = [fname, fext];
    EEG.saved = 'yes';
    save(filename, '-mat', '-struct',  "EEG");
    
else
    
    m = matfile(filename, "Writable",true);
    for ii = 1:length(variables)
        m.(variables{ii}) = EEG.(variables{ii});
    end
    m.filepath = fpath;
    m.filename = [fname, fext];
    
end



