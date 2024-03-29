function scheme = eeg_LoadScheme(themeFile)


arguments
    themeFile = ''
end

%if a themeFile name was not passed
%get the name of teh current theme file from the esma config file
if isempty(themeFile)
    config = eeg_ReadConfig('themeFile');
    if isempty(config)
        warning('No theme information is stored in the cofiguration file');
    else    
        themeFile = config.themeFile;
    end


    schemePath = fullfile(fileparts(mfilename('fullpath')),'..' ,'config','themes');
    if isempty(themeFile)
        themeFile = fullfile(schemePath, 'Defaut.mat');
    else
        [p,f, e] = fileparts(themeFile);
        if isempty(p)
            %in case the themeFile is a file with path or just a file
            themeFile = fullfile(schemePath, themeFile);
        end
    end
end
if isfile(themeFile)
    scheme = load(themeFile, '-mat');
else
    warning('A valid theme file was not found.  Please check the themes folder of your ESMA installation');
    scheme = eeg_DefaultScheme;
end
sz = get(0, "ScreenSize");
scheme.ScreenWidth = sz(3);
scheme.ScreenHeight = sz(4);
%very hacky work around for the windows task bar
if ispc
    scheme.ScreenHeight = scheme.ScreenHeight - 50;
end
scheme.GoodSubjectColor = [.2, .8, .2];
scheme.BadSubjectColor = [.8, .2, .2];
