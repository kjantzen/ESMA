%study_AddHsitory(study,...)    -   Adds a history entry to a study
%
%Usage:
%   function study = study_AddHistory(study,varargin)
%       study       -   a valid study structure
%       varargin    -   a set of variable name and value pairs where the 
%                       first input identifies the name of the field and 
%                       the second is the value to assign to the field
%                   Valid field names are:
%                   'start'   -   a date vector for the date and time of the 
%                                 start of the operation
%                   'finish'  -   a date vector indicating the date and time 
%                                 of the finish of the operation
%                   'event'   -   a string indicating the name of the
%                                 operation
%                   'function' -  the name of the function that performed
%                                 the operation
%                   'paramstring' - a cell array within information about
%                                   the specific parameters used in the operaiton
%                   'fileID'   -  the file part added to the file to make it
%                                unique and identify the specific operation
%                                (e.g. '_f' added to the filename after
%                                filtering)
function study = study_AddHistory(study, varargin)
    

p = wwu_finputcheck(varargin, {...
        'start', 'real', [], clock;...
        'finish', 'real', [], clock;...
        'event', 'string', '', '';...
        'function', 'string', '', '';...
        'paramstring', 'cell', {}, {};...
        'fileID', 'string', '', '';...
         });
     
if ~isfield(study, 'history') || isempty(study.history)
    study.history = p;
    hentries = 1;
else
    study.history(end + 1) = p;
end

study_SaveStudy(study);


     