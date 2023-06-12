%*************************************************************************
%load the path file that points to the location where EEG data are stored
%on this machine
%*************************************************************************
function EEGPath = study_GetEEGPath
    
    nopath = true;
    EEGPATHFILE = fullfile(fileparts(mfilename("fullpath")),'..', filesep, 'config','EEGpath.mat');

    if isfile(EEGPATHFILE)
       load(EEGPATHFILE, "EEGPath");
       if isfolder(EEGPath)
           nopath = false;
       end
    end
    if nopath
        cfg. msg = sprintf('No valid path file exists. \n\nClick "Select path" to identify the folder where your experiments can be found.', EEGPATHFILE);
        cfg.options = {'Cancel', 'Select path'};
        cfg.title = 'Missing path file';
        result = wwu_msgdlg(cfg);
        if strcmp(result, 'Cancel')
            fprintf('User clicked cancel')
            return
        elseif strcmp(result, 'Select path')

            EEGPath = uigetdir('','Specify the EEG Data Path');
            if isempty(EEGPath)
                return
            else
                save(EEGPATHFILE, 'EEGPath');
            end
        end
    end
end