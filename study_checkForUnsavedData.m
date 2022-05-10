%STUDY_CHECKFORUNSAEVEDDATA
%compares thend handle of the current figure passed as hfig to the global
%CURRENTFIGURE handle.  If they are different it determines with the
%current figure has any unsaved data and saves that before setting the
%current figure to the passed figure.
%this function shuould be called before data is saved or plotted on a
%figure to make sure that any changes to the data made by a different
%figure are included and not overwritten.

%could also do more here like determine if the participant being worked on
%currently is the same as the one in the other window.  Will need subject
%information for this.
function updateNeeded = study_checkForUnsavedData(hfig)

persistent CURRENTFIGURE
updateNeeded = false;

%only execuyte if the current figure and the calling figure are different
if ~isequal(hfig, CURRENTFIGURE)
    %signal the need for an update just in case something from the other
    %figure was saveed before it was deleted
    updateNeeded = true;
    %make sure the figure still exists
    if ishandle(CURRENTFIGURE)
        p = CURRENTFIGURE.UserData;
        if isfield(p, 'EEG')
            if contains(p.EEG.saved, 'no')
                pb = uiprogressdlg(CURRENTFIGURE, "Indeterminate","on","Message",'Saving unsaved data...');
                wwu_SaveEEGFile(p.EEG);
                close(pb);
            end
        end
    end
    
end
CURRENTFIGURE = hfig;
