%**************************************************************************
%function to allow users to dynamically change the location of data
%**************************************************************************
function EEGPath = study_ChangeEEGPath

    EEGPath = "";
    %read the configuration file
    config = eeg_ReadConfig();
    if ~isempty(config) & isfield(config, 'EEGPath')
       EEGPath = config.EEGPath;
    end

    NewPath = uigetdir(EEGPath,'Select the folder that contains your STUDY subfolder');
    if ~(isempty(NewPath)) & (NewPath ~= 0)
        EEGPath = NewPath;
    end
     
    config.EEGPath = EEGPath; 
    eeg_WriteConfig(config)
 end
