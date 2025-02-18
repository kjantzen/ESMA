function eeg_FilesToFolders(options)
% EEG_FILESTOFOLDERS(options)
%
%   Attempts to arrange BDF files into the 1 folder per subject file
%   structure compatible with ESMA.
%
%   All BDF files must be located in tbe same folder.  Attempts at
%   automatic categorization of the files will be made in the following
%   order.
%       name:   categorize based on name information in the BDF header
%       ID:     categorize based on subject ID information in the BDF
%       header
%       filename:   categorize based on the name of the BDF file.
%
%   NOTE: to categorize based on name, files must have a consistent naming
%   convention of the format ?id.bdf where ? is a prepended set of
%   characters (determined by  SIDPrefix below), id is an integer
%   indicating the ID number of the subject, and .bdf is the file
%   extension.  The preprended filename should be passed in the SIDPrefix
%   parameter (defaults to "S", which means the first 3 participants would
%   be named "S1.bdf", S2.bdf", and "S3.bdf").
%
% Usage
%   eeg_FilesToFolders("FilePath", pathToBDF, "SIDPrefix", prefix)
%
% Inputs 
% FilePath: a string variable containing teh path in which the BDF files are 
% located.  If no filepath is provided, the user will be prompted for one.
%
% SIDPrefix: a string containing any characters in teh BDF filename that
% precede the subject ID.  Defaults to "S".  Is not necessary if BDF header
% information is being used to categorize data.
% 
arguments
    options.FilePath = []
    options.SIDPrefix (1,:) {mustBeText} = 'S'; 
end

oldPath = [];

%check to see if there is a version of biosig on the computer
%assume it exists
canReadHeader = true;
%check to see if it exists
biosig_Path = fileparts(which('sopen'));
%if not, see if we can find it
if isempty(biosig_Path)
    %check for an eeglab installation
    eeg_Path = fileparts(which("eeglab"));
    if isempty(eeg_Path)
        fprintf('No eeglab installation detected, disabling header checking');
        canReadHeader = false;
    else
        plugin_folders = dir(fullfile(eeg_Path, 'plugins'));
        ft_indx = find(contains({plugin_folders.name}, 'biosig'));
        if ~isempty(ft_indx)
            biosig_Path = fullfile(plugin_folders(ft_indx).folder,plugin_folders(ft_indx).name);
            biosig_Path = fillfile(biosig_Path, 'biosig', 't200_FileAccess');
            oldPath = addpath(biosig_Path);
            fprintf('Found biosig file "sopen.m".  Will attempt to categorize files based on header information.')
        else
            fprintf('Biosig file "sopen.m" not found so categorization will be based on filenames.')
            canReadHeader = false;
        end
    end
end
        
if isempty(options.FilePath) || ~isfolder(options.FilePath)
    fprintf('Specify a path containing 1 or more BDF file for each participant\n');
    FilePath = uigetdir(options.FilePath, 'Specify a path containing 1 or more BDF files for each participant');
    if FilePath == 0
        fprintf('The user selected Cancel');
        return
    end
else
    FilePath = options.FilePath;
end

%scan folder for bdf files
searchString = fullfile(FilePath, '*.bdf');
d = dir(searchString);
if isempty(d)
    fprintf('NO BDF FILES WERE FOUND IN THE DATA FOLDER....exiting!');
    return
end
nFiles = length(d);
fprintf('...found %i BDF files...scanning for subject information\n', nFiles);

name_info = cell(1,nFiles);
id_info = cell(1, nFiles);

%scan for subject info in BDF files
if canReadHeader
    fprintf('Scanning BDF files for participant information...\n')
    for ii = 1:nFiles
        fprintf('%i of %i\n',ii, nFiles);
        fn = fullfile(d(ii).folder, d(ii).name);
        h = sopen(fn);
        name_info{ii} = h.Patient.Name;
        id_info{ii} = h.PID;
        h = sclose(h);
    end
    fprintf('Scanning complete...checking the subject name information\n');
    missing = sum(cellfun(@isempty, name_info));
    if missing > 0
        fprintf('Some files having missing name information....checking ID\n');
        missing = sum(cellfun(@isempty, id_info));
        if missing > 0
            fprintf('Some files have missing ID information...using filenames\n');
            canReadHeader = false;
        else
            final_info = id_info;
        end
    else
        canReadHeader = false;
    end
end
if ~canReadHeader
    %if we cannot read the header just use filenames
    fprintf('Default to using filenames\n');
    expression = sprintf('%s[0-9]+', options.SIDPrefix);
    final_info = regexpi({d.name}, expression, 'match');
    final_info = cellfun(@char, final_info, 'UniformOutput',false);
    if sum(cellfun(@isempty, final_info)) > 0
        fprintf('There is missing subject information in at least one BDF file...exiting\n');
        return
    end
end

newFolders = unique(final_info);
for ii = 1:length(newFolders)
    fileIndx = find(strcmp(final_info, newFolders{ii}));
    fullFolderPath = fullfile(FilePath, newFolders{ii});
    if ~isfolder(fullFolderPath)
        mkdir(fullFolderPath);
    end
    for ff = 1:length(fileIndx)
        sourceFile = fullfile(d(fileIndx(ff)).folder, d(fileIndx(ff)).name);
        destFile = fullfile(fullFolderPath, sprintf('RawFile_Session%i.bdf', ff));
        copyfile(sourceFile, destFile);
    end
end
if ~isempty(oldPath)
    path = oldPath;
end
