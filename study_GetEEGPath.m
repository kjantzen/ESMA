%*************************************************************************
%load the path file that points to the location where EEG data are stored
%on this machine
%*************************************************************************
function EEGPath = study_GetEEGPath
    
    EEGPATHFILE = fullfile(matlabroot,'EEGpath.mat');
    result = dir(EEGPATHFILE);

    nopath = true;

    if ~isempty(result)
       load(EEGPATHFILE);
       if isfolder(num2str(EEGPath))
           nopath = false;
       end
    end
    if nopath
        msg = sprintf('Could not find path file %s\nClick OK and specify the path where EEG data can be found.', EEGPATHFILE);
        msgbox(msg);
        EEGPath = uigetdir('','Specify the EEG Data Path');
        if isempty(EEGPath)
           return
        else
            save(EEGPATHFILE, 'EEGPath');
        end
    end
    