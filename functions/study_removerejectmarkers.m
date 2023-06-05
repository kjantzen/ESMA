function EEG = removerejectmarkers(EEG, fieldstr)


if isempty(EEG)
    return
end

if ~isfield(EEG, 'reject')
    return
end

fields = split(fieldstr);
for ii =  1: length(fields)
    if isempty(EEG.reject.(fields{ii}))
        continue
    else
        EEG.reject.(fields{ii})(1:end) = 0;
    end
end
