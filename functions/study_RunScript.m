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

arguments
    study {isstruct}
    filelist {iscellstr}
end

scheme = eeg_LoadScheme;
W = 550; H = 180;
FIGPOS = [(scheme.ScreenWidth-W)/2,(scheme.ScreenHeight-H)/2, W, H];

handles.figure = uifigure;
set(handles.figure, ...
    'color', scheme.Window.BackgroundColor.Value,...
    'name', 'Run custom matlab script',...
    'numbertitle', 'off', ...
    'menubar', 'none', ...
    'position', FIGPOS, ...
    'units', 'pixels');
h = handles.figure;

handles.panel1 = uipanel(...
    'Parent', handles.figure,...
    'FontSize',10,...
    'BackgroundColor',scheme.Panel.BackgroundColor.Value,...
    'ForegroundColor',scheme.Panel.FontColor.Value,...
    'FontName', scheme.Panel.Font.Value,...
    'FontSize', scheme.Panel.FontSize.Value,...
    'Position',[10, 50, 530, 120]);

parent = handles.panel1;
uilabel('Parent', parent,...
    'Text','MATLAB Script to apply to your data',...
    'Position', [20,60,400,20],...
    'FontName',scheme.Label.Font.Value,...
    'FontColor',scheme.Label.FontColor.Value,...
    'FontSize', scheme.Label.FontSize.Value);

handles.button_addscript = uibutton(...
    'Parent', parent,...
    'Text', '...',...
    'Position', [440, 30, 60, 25],...
    'BackgroundColor', scheme.Button.BackgroundColor.Value,...
    'FontColor', scheme.Button.FontColor.Value,...
    'FontName', scheme.Button.Font.Value,...
    'FontSize', scheme.Button.FontSize.Value);

handles.edit_script_name = uieditfield('Parent', parent,...
    'position', [20,30,400,25],...
    'BackgroundColor', scheme.Edit.BackgroundColor.Value,...
    'FontColor', scheme.Edit.FontColor.Value,...
    'FontName', scheme.Edit.Font.Value,...
    'FontSize', scheme.Edit.FontSize.Value);

handles.button_runscript = uibutton(...
    'Parent', handles.figure,...
    'Text', 'Run Script',...
    'Position', [440, 10, 100,30],...
    'BackgroundColor', scheme.Button.BackgroundColor.Value,...
    'FontColor', scheme.Button.FontColor.Value,...
    'FontName', scheme.Button.Font.Value,...
    'FontSize', scheme.Button.FontSize.Value);

handles.button_close = uibutton(...
    'Parent', handles.figure,...
    'Text', 'Close',...
    'Position', [330, 10, 100, 30],...
    'BackgroundColor', scheme.Button.BackgroundColor.Value,...
    'FontColor', scheme.Button.FontColor.Value,...
    'FontName', scheme.Button.Font.Value,...
    'FontSize', scheme.Button.FontSize.Value);

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
    
    
