function eeg_WriteConfig(config)

    arguments
        config (1,1) {mustBeA(config, 'struct')}
    end
    
    configFile = fullfile(fileparts(mfilename('fullpath')),'..' ,'config','config.mat');
    
    if isfile(configFile)    
        save(configFile, '-struct', "config", '-append');
    else
        save(configFile, '-struct', 'config');
        warning('A configuration file was not found.  ESMA created a new one')
    end
