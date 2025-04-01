%study = study_CheckStudy(study);
%
%   INPUT
%   study:  An ESMA study structure
%   
%   OUTPUTS
%   study:  The input study structure after performing continuity checks
%   and correcting any errors or problems
%
% study_CheckStudy() reviews an ESMA study structure and performs some
% basic checks to make sure the structure is complete and free from errors.
% The current list of checks is short and may grow over time.  The plan is
% for this function to act as a mechanisms for updating older study files
% as features of the study structure change over time.
%
function study = study_CheckStudy(study)
arguments
    study (1,1) {mustBeStruct}
end
%check version
currentVersion = eeg_GetESMAVersion();
if ~isfield(study, 'version')
    fprintf('The study does not have a known ESMA version number.  Adding the current version.\n');
    study.version = currentVersion;
end

%make sure #of subjects is correct
if study.nsubjects ~= length(study.subjects)
    fprintf('The number of subjects does not match the subject information. Updating to %i\n', length(study.subjects));
    study.nsubjects = length(study.subjects);
end

%check to make sure all ID's are unique
sID = {study.subject.ID};
[IDList, ia, ib] = unique(sID);
if length(sID) ~= length(IDList)  %if there are duplicates
    fprintf('Duplication subject IDs were found. Forcing unique IDs\n');
    for ii = 1:length(ia)  %loop through and find duplicates
        if sum(ib == ia(ii)) > 1
            sCount = 1;
            for jj = find(ib==ia(ii))
                study.subject(jj).ID = [study.subject(jj).ID, sprintf('_%i',sCount)]; %add an incrementing integer
                sCount = sCount + 1;
            end
        end
    end
end

%set default colorpalettes if they don't exist to allow for backward
%compatibility
if ~isfield(study, 'Render')
    fprintf('Render information not found! Adding defaults');
    map = orderedcolors('gem12');
    study.Render.ERP.Palette = map(1:8, :);
    study.Render.ERP.LineWidth = 1.5;
    study.Render.Map.Palette = 'turbo';
    study.Render.Map.StatPalette = 'autumn';
end

%I added these at some point but never used them
if isfield(study, 'nconditions')
    study = rmfield(study, 'nconditions');
end
if isfield(study, 'nfactors')
    study = rmfield(study, 'nfactors');
end

%**************************************************************************
%helper functions
function mustBeStruct(s)
assert(isstruct(s), 'The input must be a Matlab structure');