%LoadStudy()    -   loads and hcnd study structure from the STUDIES folder
%
%Usage:
%   -   STUDY = study_LoadStudy(study_name);
%
%Inputs:
%   'study_name'    -   [string] a study filename
%
%Outputs:
%       STUDY       -   [struct] an hcnd_eeg study structure

function study = study_LoadStudy(study_name)

%this will return as empty if something goes wrong
study = [];
if nargin < 1
    error('A valid study filename is required')
end

EEGPath = study_GetEEGPath;
STUDYPATH = fullfile(EEGPath, 'STUDIES');

[~, fname, ~] = fileparts(study_name);

input_filename = fullfile(STUDYPATH, [fname, '.study']);
if ~exist(input_filename,'file');
    error('The study you requested does not exist');
end

s = load(input_filename, 'study', '-mat');
study = s.study;


