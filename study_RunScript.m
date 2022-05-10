%study_RunScript() - Extends flelxibility of the toolbox by allowing users
%                    to apply their own custom, data specific routines to
%                    the data in their study.
%                    Example: a custom routine to rename event markers
%                    based on experiment specific performance
%                    parameters,etc.
%                    This funciton is meant to add flexibility not to
%                    extend function.  Please contact Dr. Jantzen to add
%                    long term functionality to the suite.
%
%                    The custom script will be called once per participant
%                    and so should be written to perform its functions on a
%                    single file.  The name of the file to process is
%                    passed to the script so the custom script must open,
%                    process and save the file as well as perform any error
%                    checking
%
%Usage:
%>> study_Run_Script(study, filenames);
%
%Required Inputs:
%   study       -   an hcnd STUDY structure passed from the hcnd_eeg main 
%                   interface or from the command line. 
%
%   filenames   -   a cell array of filenames to review.  The routine
%                   automatically assumes one filename for each participant 
%                   listed in the study structure.

% Update 5/13/20 KJ Jantzen
function h = study_RunScript(study, filelist)


p = plot_params;

W = 550; H = 130;
FIGPOS = [(p.screenwidth-W)/2,(p.screenheight-H)/2, W, H];

handles.figure = uifigure;
set(handles.figure, ...
    'color', p.backcolor',...
    'name', 'Run custom matlab script',...
    'numbertitle', 'off', ...
    'menubar', 'none', ...
    'position', FIGPOS, ...
    'units', 'pixels');

h = handles.figure;

handles.panel1 = uipanel(...
    'Parent', handles.figure,...
    'Title','MATLAB Script to apply to your data',...
    'FontSize',10,...
    'BackgroundColor',p.backcolor,...
    'Position',[10, 35, 530, 80]);

parent = handles.panel1;

handles.button_addscript = uibutton(...
    'Parent', parent,...
    'Text', '...',...
    'Position', [440, 20, 60, 25],...
    'BackgroundColor', p.buttoncolor,...
    'FontColor', p.buttonfontcolor);

handles.edit_script_name = uieditfield('Parent', parent,...
    'position', [20,20,400,25],...
    'BackgroundColor', p.textfieldbackcolor,...
    'FontColor', p.textfieldfontcolor);

handles.button_runscript = uibutton(...
    'Parent', handles.figure,...
    'Text', 'Run Script',...
    'Position', [440, 5, 100, p.buttonheight],...
    'BackgroundColor', p.buttoncolor,...
    'FontColor', p.buttonfontcolor);

handles.button_close = uibutton(...
    'Parent', handles.figure,...
    'Text', 'Close',...
    'Position', [330, 5, 100, p.buttonheight],...
    'BackgroundColor', p.buttoncolor,...
    'FontColor', p.buttonfontcolor);

set(handles.button_addscript, 'ButtonPushedFcn', {@callback_getscriptname, handles});
set(handles.button_runscript, 'ButtonPushedFcn', {@callback_runscript, handles, study, filelist});
set(handles.button_close, 'ButtonPushedFcn', {@callback_exit, handles});

if isempty(filelist)
    closereq();
end


%% Functions
%***************************************************************************
function callback_runscript(hObject, eventdata, h, study, fnames)



script = h.edit_script_name.Value;
if isempty(script) || isempty(dir(script))
    msgbox('No script file was found!', 'Script Error', 'error');
    return
end

[scriptpath, scriptname, scriptext] = fileparts(script);
currdir = pwd;
cd(scriptpath);

%update the study history

if ~isfield(study, 'history')
    study.history = [];
    hentries = 1;
elseif isempty(study.history)
    hentries = 1;
else
    hentries = length(study.history)+1;
end

study.history(hentries).start = clock;
study.history(hentries).event = 'custom script applied to data';
study.history(hentries).function = scriptname;
study.history(hentries).paramstring = fnames;
study.history(hentries).fileID = '';

pb = uiprogressdlg(h.figure, 'Title', 'Custom Matlab script',...
    'ShowPercentage', 'on');
    for jj = 1:length(fnames)
      %  pb.Message = fnames{jj};
        pb.Value = jj/length(fnames);
        
        feval(scriptname, fnames{jj})
    end

close(pb);

cd(currdir);
study.history(hentries).finish = clock;
study_SaveStudy(study);
callback_exit(hObject, eventdata, h)

%************************************************************************
function callback_getscriptname(hObject, eventdata, h)
    [scriptfile, scriptpath] = uigetfile('*.m', 'Select a script file');
    if ~isequal(scriptfile, 0)
       h.edit_script_name.Value = fullfile(scriptpath, scriptfile);
    end
%*************************************************************************
function callback_exit(hObject, eventdata, h)
    closereq();
    
    
