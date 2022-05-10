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
if ~isempty(field)
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
    if ~isfield(EEG, field)
        EEG = wwu_LoadEEGFile(filename);
        return;
    end
else
    EEG = load(filename, "-mat");
end
%handles version differences
if isfield(EEG, 'EEG')
    EEG = EEG.EEG;
end

[~,~,fileext] = fileparts(filename);
if strcmp(fileext, '.cnt') || strcmp(fileext, '.epc')
    EEG = eeg_checkset(EEG);
end

EEG.saved = 'yes';



