function EEG = wwu_SaveEEGFile(EEG, filename)
%EEG = wwu_SaveEEGFile(EEG, filename) - save the eeg data in EEG to the
%file specified in filename.  If omitted, the filename stored in teh EEG
%structure will be used.

if nargin < 1
    help wwu_SaveEEGFile;
    return;
end
if nargin < 2
    if isempty(EEG.filepath) || isempty(EEG.filename)
        warning('The EEG file does not contain valid filename information. Please save the data manually!');
        return;
    else
        filename = fullfile(EEG.filepath, EEG.filename);
    end
end

[fpath, fname, fext] = fileparts(filename);
%check if this is an eeglab file type and check its consistencny if it is
if strcmp(fext, '.cnt') || strcmp(fext,'.epc')
        EEG = eeg_checkset(EEG);
end
%save the information in the EEG structure so that it can be used in the
%future instead of relying on the filename input.
EEG.filepath = fpath;
EEG.filename = [fname, fext];
EEG.saved = 'yes';
save(filename, '-mat', '-struct',  "EEG");


