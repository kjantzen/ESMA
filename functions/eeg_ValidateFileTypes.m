function isValid = eeg_ValidateFileTypes(fileList, validTypes)

    arguments
        fileList (1,:) cell {mustBeVector(fileList)}
        validTypes (1,:) cell {mustBeVector(validTypes)}
    end

    %extract teh filetypes from the filelist
    [~,~,ftypes] = cellfun(@fileparts, fileList, 'UniformOutput', false);
    r = zeros(size(ftypes));
    for ii = 1:length(validTypes)
        r = r | contains(ftypes, validTypes{ii});
    end
    if sum(r) < length(ftypes)
        warning('At least one file does match the valid type...');
        isValid = false;
    else
        isValid = true;
    end




