%EEG = wwu_LoadEEGFile(filename, field) - loads the fields specified in
%FIELD from the file specified in filename.  If field is not specified, the
%entire file is loaded.
%INPUTS - 
% filename -    a string containing the name of the file to load
% field    -    a cell array of field names to load
%HDNC EEG function to load EEG data files
function EEG = wwu_LoadEEGFile(filename, field)

if nargin < 1
    help wwu_LoadEEGFile;
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
            EEG = wwu_LoadEEGFile(filename);
            return;
        end
    end
else
    EEG = load(filename, '-mat');
    %handles version differences since previously files were not saved with the
    % struct option
    if isfield(EEG, 'EEG')
        EEG = EEG.EEG;
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




