%*************************************************************************
%load the path file that points to the location where EEG data are stored
%on this machine
%*************************************************************************
function EEGPath = study_GetEEGPath
    
    nopath = true;
    config = eeg_ReadConfig();
    if ~isempty(config) && isfield(config, 'EEGPath')
        EEGPath = config.EEGPath;
       if isfolder(EEGPath)
           nopath = false;
       end
    end
    if nopath
        msg = sprintf('No valid path file exists. \n\nClick "Select path" to identify the folder where your experiments can be found.', EEGPATHFILE);
        buttons = {'Cancel', 'Select path'};
        title = 'Missing path file';
        result = wwu_msgdlg(msg,title,buttons, "isError",false);
        if strcmp(result, 'Cancel')
            fprintf('User clicked cancel')
            return
        elseif strcmp(result, 'Select path')
            EEGPath = uigetdir('','Specify the EEG Data Path');
            if isempty(EEGPath)
                return
            else
                %create a separate function to save data to the config file
                p.EEGPath = EEGPath;
                eeg_WriteConfig(p)
            end
        end
    end
end