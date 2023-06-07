function status = study_ClassifyICA(filenames, p)

arguments
    filenames (1,:) cell
    p.Outfile = []
    p.WindowHandle = []
end

status = 0;

if isempty(filenames) || ~iscell(filenames)
    error('study_ClassifyICA:NoFile', 'filenames must be a cell array strings containing valid names of files');
end

if ~isempty(p.WindowHandle)
    pb = uiprogressdlg(p.WindowHandle, 'Title', 'Please Wait', 'Message', 'Classifying ICA components for all files...');
end

owrite = -1;
fnum  = length(filenames); cnt = 0;
for f = filenames
    cnt = cnt + 1;
    if ~isfile(f)
        error('study_ClassifyICA:NoFile', 'The file %s was not found on the disk', f);
    end
    
    try
        EEG = wwu_LoadEEGFile(f{:});
    catch ME
        fprintf(ME.identifier)
        rethrow ME
    end
    
    if ~isfield(EEG, 'icaweights')
        fprintf('NO ICA components found in %s\nSkipping to the next file...\n', f{:});
        continue
    end
    
    %check to see if classifications already exist
    if isfield(EEG, 'etc')
        if isfield(EEG.etc, 'ic_classification') 
            if owrite == -1
                response = questdlg('Classifications already exist for at least one file.', 'IC Classification', 'Overwrite Current', 'Overwrite All', 'Ignore Existing', 'Ignore Existing');
                switch response
                    case 'Overwrite Current'
                        %do nothing here since you want to ask again if another
                        %file is found,  This is here for readability
                    case 'Overwrite All'
                        owrite = 1;
                    case 'Ignore Existing'
                        owrite = 0;
                        fprintf('Labels found, not overwritting....\n')
                        continue
                end
            elseif owrite == 0
                fprintf('Labels found, not overwritting....\n')
                continue
            end
        end
    end

    %this accomodates for the fact that I remove bad trials before running
    %ICA, but want to keep them in the original data.  For some early data
    %sets I did not recompute the ica activations and those files could
    %show up here.
 %   if size(EEG.icaact, 3) < EEG.trials
    %    icaact_d = zeros(size(EEG.data));
        icaact_d = zeros(size(EEG.icaweights,1), size(EEG.data, 2), size(EEG.data, 3));
        for ii = 1:EEG.trials
            icaact_d(:,:,ii) = icaact(EEG.data(:,:,ii), EEG.icaweights * EEG.icasphere, 0);
        end
        EEG.icaact = icaact_d;
  %  end
            
    EEG = iclabel(EEG);   
    
    if isempty(p.Outfile)
        Outfile = f{:};
    else
        Outfile = fullfile(fpath, [p.Outfile, fext]);
    end
    wwu_SaveEEGFile(EEG, Outfile);
    if isobject(pb); pb.Value = cnt/fnum; end
    
end

close(pb)
status = 1;
    
    