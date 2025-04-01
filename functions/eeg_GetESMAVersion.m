%version = eeg_GetESMAVersion()
%
%   INPUTS
%   none
%
%   OUTPUTS 
%   version:    character array containing the running ESMA version
%
%   Returns a string with the hardcoded version of the version of ESMA you
%   are running.  
%   Note that to ensure this information is accurate you must replace your
%   entire ESMA installation with the newest version of all files when
%   updating.
%
function version = eeg_GetESMAVersion()
    version = '3.0.1-beta';

