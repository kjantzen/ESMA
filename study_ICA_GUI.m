%study_ICA_GUI() - GUI for batch computing ICA on a set of files
%
%Usage:
%>> study_ICA_GUI(filenames);
%
%Required Inputs:
%   filenames   -   a cell array of filenames to on which to compute ICA.

% Update 5/13/20 KJ Jantzen
function h = study_ICA_GUI(filenames)


p = plot_params;

W = 450; H = 200;
figpos = [(p.screenwidth-W)/2,(p.screenheight-H)/2, W, H];
%setup the main figure window

handles.figure = uifigure(...
    'Color', p.backcolor,...
    'Position', figpos,...
    'NumberTitle', p.numbertitle,...
    'Menubar', p.menubar,...
    'WindowStyle', 'modal');

h = handles.figure;

handles.uipanel1 = uipanel(...
    'Parent', handles.figure,...
    'Title','ICA options',...
    'BackgroundColor',p.backcolor,...
    'Position',[10, 35, 430, 160]);
%*************************************************************************
handles.check_nobad = uicheckbox(...
    'Parent', handles.uipanel1, ...
    'Text', 'Exclude bad trials?',...
    'value', 1,....
    'Position', [20, 100, 250, 20]);

handles.check_overwrite = uicheckbox(...
    'Parent', handles.uipanel1, ...
    'Text', 'Overwrite Existing Components?',...
    'value', 1,....
    'Position', [20, 70, 250, 20]);

handles.check_filter = uicheckbox(...
    'Parent', handles.uipanel1, ...
    'text', 'Apply a band pass filter running ICA?',...
    'Value',1,...
    'Position', [20, 40, 250, 20]);

handles.edit_filtlow = uieditfield(...
    handles.uipanel1, 'numeric',...
    'Value', 1,...
    'BackGroundColor', p.textfieldbackcolor, ...
    'FontColor', p.textfieldfontcolor,...
    'Position', [175, 5, 60, 20],...
    'Limits', [0, 50], ...
    'RoundFractionalValues', 'on',...
    'ValueDisplayFormat', '%i Hz');

handles.edit_filthigh = uieditfield(...
    handles.uipanel1, 'numeric',...
    'Value', 50,...
    'BackGroundColor', p.textfieldbackcolor, ...
    'FontColor', p.textfieldfontcolor,...
    'Position', [245, 5, 100, 20],...
    'Limits', [0, 500], ...
    'RoundFractionalValues', 'on',...
    'ValueDisplayFormat', '%i Hz');


uilabel('Parent', handles.uipanel1, ...
    'text', 'filter edges (low/high)',...
    'HorizontalAlignment', 'left', ...
    'BackGroundColor', p.backcolor, ...
    'Position', [20, 5, 150, 20]);


handles.button_compute = uibutton(...
    'Parent', handles.figure,...
    'Text', 'Compute ICA',...
    'Position', [W-110, 5, 100, 25]);

handles.button_compute.ButtonPushedFcn = {@callback_ComputeICA, handles, filenames};


%**********************************************
function callback_ComputeICA  (src, eventdata, h,fnames)



Excludebad = h.check_nobad.Value;
FiltData = h.check_filter.Value;
OverWrite = h.check_overwrite.Value;


if FiltData
    filtlow = h.edit_filtlow.Value;
    filthigh = h.edit_filthigh.Value;
    
    if filtlow >= filthigh && filthigh ~=0
        uialert(h.figure, 'The low edge of the filter must be less than the high edge', 'Filter error');
        return
    end
    
end


pb = uiprogressdlg(h.figure, 'Message', 'computing the ICA for each particpant will take some time', 'Title', 'Compute ICA', 'ShowPercentage', 'on');


%loop through each subject in the study
for jj = 1:length(fnames)
    
    [fpath, fname, fext] = fileparts(fnames{jj});
    Header = wwu_LoadEEGFile(fnames{jj}, {'icaweights'});

    %check if components exist.
    if ~isempty(Header.icaweights) && ~OverWrite
        fprintf('ICA components found.  Skipping this file\n');
        continue;
    end
    
    %EEG = pop_loadset('filepath', fpath, 'filename', [fname, fext]);
    EEG = wwu_LoadEEGFile(fnames{jj});
    if FiltData
        fprintf('Pre filtering the data\n');
        EEGprocessed = pop_eegfiltnew(EEG, 'locutoff', filtlow, 'hicutoff', filthigh, 'revfilt', 0);
    else
        EEGprocessed = EEG;
    end
    
    
    %compute the IC's
    fprintf('computing Independent components\n\n');
    
    %compute the rank of the data and subtract 1 because we have computed the
    %average reference.  The rank function does not seem to detect this
    %decrease in the rank of data so we compensate manually
    dv = size(EEGprocessed.data);
  %  temp = reshape(EEGprocessed.data, [dv(1), dv(2) * dv(3)]);
    pcacomp = (dv(1));
    
 %   clear temp;
    
    if pcacomp==EEG.nbchan && (strcmp(EEG.ref,'averef') || strcmp(EEG.ref, 'average'))
        pcacomp = pcacomp - 1;
        fprintf('Matlab computed full rank so reducing by 1 for the average reference\n');
    end
    
    if  isfield(EEGprocessed, 'chaninfo') && isfield(EEGprocessed.chaninfo, 'removedchans')
        if ~isempty(EEGprocessed.chaninfo.removedchans)
            pcacomp = pcacomp - length(EEGprocessed.chaninfo.removedchans);
            fprintf('Reducing rank to accouunt for remvoed channels\n')
        end
    end
    if Excludebad
        bad_trials = study_GetBadTrials(EEGprocessed);
        EEGprocessed = pop_rejepoch(EEGprocessed, bad_trials, 0);
    end 
  
   fprintf('hcnd_eeg says the rank of this data is %i\n', pcacomp);
    EEGOut = pop_runica(EEGprocessed, 'concatenate', 'off', 'extended', 1, 'pca', pcacomp);
    
%now restore the original data before filtering and epoch removal
   EEG = EEGOut;
  %[EEG.icaact, EEG.icawinv,EEG.icasphere,EEG.icaweights,EEG.icachansind] = deal(EEGOut.icaact, EEGOut.icawinv,EEGOut.icasphere,EEGOut.icaweights,EEGOut.icachansind );
   
  %I retain all trials and use bad trial markers to keep track of the bad ones so I need to 
  %recompute the ica activations since had trials were
  %removed for the purpose of ICA calculation.
  %if size(EEG.icaact, 3) < EEG.trials
  %    tempact = icaact(EEG.data, EEG.icaweights * EEG.icasphere);
  %    EEG.icaact = reshape(tempact, size(EEG.icaweights, 1), EEG.pnts, EEG.trials); 
  %end
  wwu_SaveEEGFile(EEG, fnames{jj});
  clear EEGIn EEGOut
  pb.Value = jj/length(fnames);
  
end

close(pb);
close(h.figure);
