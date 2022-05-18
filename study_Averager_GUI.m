%study_Averager_GUI() - GUI for collecting information and computing the 
%                       average within and acrocc participants.
%Usage:
%>> study_Averager_GUI(study, filenames, bingroup);
%
%Required Inputs:
%   study       -   an hcnd STUDY structure passed from the hcnd eeg management
%                   software or from the command line. 
%
%   filenames   -   a cell array of filenames to average.  The resulting
%                   output file will containt the average of the trials 
%                   within each input file and the grand average across files.
%                   Conditions are defined by bin labels in each file
% Update 5/13/20 KJ Jantzen
%
function fh = study_Averager_GUI(study, filenames)

p = plot_params;

scrsze = get(0, 'ScreenSize');
scrsze = scrsze(3:4);

W = 400; H = 300;
FIGPOS = [(scrsze(1)-W)/2,(scrsze(2)-H)/2, W, H];


handles.figure = uifigure;
set(handles.figure, ...
    'Color', p.backcolor',...
    'name', 'Averager',...
    'NumberTitle', 'off', ...
    'menubar', 'none', ...
    'position', FIGPOS, ...
    'resize', 'off',...
    'units', 'pixels',...
    'WindowStyle', 'modal');
fh = handles.figure;

handles.panel1 = uipanel(...
    'Parent', handles.figure,...
    'Title','Averaging Options',...
    'BackgroundColor',p.backcolor,...
    'Position',[10, 40, W-20, H-50]);

PNT = handles.panel1;

handles.check_excludebadtrials = uicheckbox('parent', PNT,...
    'Text', 'Exclude bad trials before averaging',...
    'Value', 1, ...
    'Position', [20, 180, 300, 20]);

handles.check_excludebadcomps = uicheckbox('parent', PNT,...
    'Text', 'Project without bad components before averaging',...
    'Value', 1, ...
    'Position', [20, 140, 300, 20]);

handles.check_excludebadsubjs = uicheckbox('parent', PNT,...
    'Text', 'Exclude bad participatns',...
    'Value', 1, ...
    'Position', [20, 100, 300, 20]);


uilabel('Parent', PNT,...
    'Text', 'Output filename', ...
    'Position', [20, 20, 150, 20],...
    'FontColor', p.labelfontcolor)

handles.edit_outfilename = uieditfield(...
    'Parent', PNT,...
    'Position', [170, 20, 200, 20],...
    'BackgroundColor', p.textfieldbackcolor,...
    'FontColor', p.textfieldfontcolor);


handles.button_average = uibutton(...
    'Parent', handles.figure,...
    'Text', 'Average',...
    'Position', [W-90, 5, 80, 25],...
    'BackgroundColor', p.buttoncolor,...
    'FontColor', p.buttonfontcolor);

handles.button_cancel = uibutton(...
    'Parent', handles.figure,...
    'Text', 'Cancel',...
    'Position', [W-180, 5, 80, 25],...
    'BackgroundColor', p.buttoncolor,...
    'FontColor', p.buttonfontcolor);



handles.button_average.ButtonPushedFcn = {@callback_DoAverage, handles};
handles.button_cancel.ButtonPushedFcn = {@callback_exit, handles};

if size(filenames,1) > 1
    handles.check_combine.Enable = 'on';
    handles.label_file.Enable = 'on';
    handles.edit_newfilename.Enable = 'on';
end

p.study = study;
p.filenames = filenames;

handles.figure.UserData  = p;



%**************************************************************************
%start of functions
%**************************************************************************
function callback_exit(hObject, eventdata, h)
    close(h.figure)
    

%**************************************************************************
function callback_DoAverage(hObject, eventdata, h)

p = h.figure.UserData;
study = p.study;

%for now I think I will just do the average here rather than farm it out to the non-gui routine.
%This may change as things get more complex.

exclude_badtrials = h.check_excludebadtrials.Value;
exclude_badcomps = h.check_excludebadcomps.Value;
exclude_badsubjs = h.check_excludebadsubjs.Value;
outfilename = h.edit_outfilename.Value;


%set and create (if necessary) the output directory;
study_path = study_GetEEGPath;
outdir = wwu_buildpath(study_path, study.path, 'across subject');

%check for an output filename
if isempty(outfilename)
    uialert(h.figure, 'Please enter a valid output filename.', 'Averaging Error');
    return
end

%create the output directory
if ~exist(outdir, 'Dir')
    mkdir(outdir)
end

%make sure there is something to process
if isempty(p.filenames)
    uialert(h.figure, 'Somehow you made it this far without selecting files', 'Averaging Error');
    delete(h.figure);
    return
end


pb = uiprogressdlg(h.figure);

%create a temporary version of each file in the across subject directory so
%that I can remove trials and or components in necessary

%if more than one set of files is selected, the outfile name will be incremented
for ii = 1:size(p.filenames,1)
    
    %if the file exists already append a number to the end
    if exist(fullfile(outdir, [outfilename, '.GND']),'file')
        parselocal = max(strfind(outfilename, '_'));
        if isempty(parselocal)
            outfilename = [outfilename, '_2'];
        else
            fnum = str2num(outfilename(parselocal+1:end));
            if isempty(fnum)
               outfilename = [outfilename, '_2']; 
            else
                fnum = fnum + 1;
                outfilename = sprintf('%s_%i', outfilename(1:parselocal), fnum);
            end
        end
    end
    
    fcount = 0;
    flist = [];
    
    for jj = 1:size(p.filenames,2)
        
        %ignore bad subject
        
        
        pb.Value = jj/size(p.filenames,2);
        pb.Message = 'Loading EEG Data';
        
        [fpath, fname, fext] = fileparts(wwu_buildpath(p.filenames{ii,jj}));
        
        %figure out what subject this is and check to see if this subject
        %is a bad subject
      
            SDir = fpath(max(strfind(fpath, filesep))+1:end);
    %        snum = find(ismember({study.subject.path}, ['/', SDir]) | ismember({study.subject.path}, ['\', SDir]));
            sr = strfind({study.subject.path}, SDir);
            snum = find(cell2mat( cellfun(@(x) ~isempty(x), sr, 'UniformOutput', false)));
            if isempty(snum) || length(snum) > 1
                fprintf('Could not determine subject number.  All subjects will be included!\n');
                exclude_badsubjs = false;
            else
                if strcmp(study.subject(snum).status, 'bad') && exclude_badsubjs
                    continue
                end
            end
        
        EEG = wwu_LoadEEGFile(p.filenames{ii,jj});
        %EEG = pop_loadset('filepath', fpath, 'filename', [fname, fext]);
        EEG.subject = study.subject(snum).ID;
        
        if exclude_badtrials
            pb.Message = 'Removing bad trials';
            btrials = study_GetBadTrials(EEG);
            EEG = pop_rejepoch(EEG, btrials,0);
            %for some reason removing hte epochs scrambles the order of the
            %events so now I have to go in and make sure they are correct.
            EEG = wwu_fix_eventmarkers(EEG);
        end
        if exclude_badcomps && isfield(EEG, 'icasphere')
            pb.Message = 'Removing bad components';
            EEG = pop_subcomp(EEG, [], 0, 0);
        end
        
        %save to a temp file and store the filename
        
        fcount = fcount + 1;
        tempfilename = fullfile(outdir, sprintf('%s_%i.tmp',fname,fcount));
        flist{fcount} = tempfilename;
        wwu_SaveEEGFile(EEG, tempfilename);
        %save(tempfilename, '-v6', '-mat', 'EEG');
        
    end
    
pb.Message = 'creating average';
sets2GND(flist,'out_fname', fullfile(outdir, [outfilename, '.GND']),'verblevel', 3);

delete(fullfile(outdir, [filesep, '*.tmp']));

end

close(pb);
delete(h.figure)

%***********************************************************************

        
            
        

