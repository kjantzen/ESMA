function btrials = study_GetBadTrials(EEG)

btrials = EEG.reject.rejmanual;
 %status_image(1,find(btrials),:) = repmat([1,0,0], sum(btrials),1);
 
 if isempty(btrials)
     btrials = zeros(1, EEG.trials);
 end
 if ~isempty(EEG.reject.rejthresh)
      btrials = or(btrials, EEG.reject.rejthresh);
 end
 
 if ~isempty(EEG.reject.rejkurt)
     btrials = or(btrials, EEG.reject.rejkurt);
 end
 
 if ~isempty(EEG.reject.rejconst)
     btrials = or(btrials, EEG.reject.rejconst);
 end
 
  if ~isempty(EEG.reject.rejjp)
     btrials = or(btrials, EEG.reject.rejjp);
  end
