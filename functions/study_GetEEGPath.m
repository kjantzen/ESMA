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
        msg = sprintf('Could not the find path file %s\nClick OK and specify the path where EEG data can be found.', EEGPATHFILE);
        f = msgbox(msg,'Missing Path File', 'modal');
        waitfor(f);
        EEGPath = uigetdir('','Specify the EEG Data Path');
        if isempty(EEGPath)
           return
        else
            save(EEGPATHFILE, 'EEGPath');
        end
    end
end