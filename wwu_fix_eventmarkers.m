function EEG = wwu_fix_eventmarkers(EEG)

tmpepochs = EEG.epoch;
tmpevents = EEG.event;

for ii = 1:length(tmpepochs)
    
    %find the time locking event in this epoch
    tl_events = cell2mat(tmpepochs(ii).eventlatency)==0;
    n_matches = sum(tl_events);
    
    if n_matches == 0 %for some reason there was no timelocking event
        continue
    end
    
    tl_event_type = tmpepochs(ii).eventtype(find(tl_events)); %get the event type
   
    if sum(tl_events>1) %there is probably already a valid bin entry
        hasbin =  contains(tl_event_type, 'bin');
        if sum(hasbin>0) %looks ok
            continue
        end
    else %only one time locking event was found so now look to see if there is a bin
        tl_indx = find(tl_events);
        bin_indx = find(contains(tmpepochs(ii).eventtype, 'bin'));
        bin_indx = bin_indx(1);
        if ~isempty(bin_indx) % if a bin was found 
            if tmpepochs(ii).eventlatency{bin_indx} ~= 0  % if the bin is not already the time locking event
                tmpepochs(ii).eventlatency(bin_indx) = tmpepochs(ii).eventlatency(tl_indx);
                tmpepochs(ii).eventurevent(bin_indx) = tmpepochs(ii).eventurevent(tl_indx);
                tmpevents(tmpepochs(ii).event(bin_indx)) = tmpevents(tmpepochs(ii).event(tl_indx));
                tmpevents(tmpepochs(ii).event(bin_indx)).type = tmpepochs(ii).eventtype{bin_indx};
            end
        end
    end
end
EEG.event = tmpevents;
EEG.epoch = tmpepochs;

end

                
            
        