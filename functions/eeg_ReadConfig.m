function config = eeg_ReadConfig(variable)

    arguments
        variable (1,1) string = 'all'
    end

    configFile = fullfile(fileparts(mfilename('fullpath')),'..' ,'config','config.mat');
    
    if isfile(configFile)    
        if strcmp(variable, 'all')
            config = load(configFile);
        else
            v = whos('-file', configFile);
            n = {v.name};
            if sum(contains(n, variable)) > 0
                config = load(configFile, variable);
            else config = '';
            end
        end
    else
        error('Configuration file was not found!');
    end
