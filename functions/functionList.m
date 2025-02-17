function functionList(mFile)

    if isempty(dir(mFile))
        fprintf('File Not Found: %s', mFile)
    end
    fileID = fopen(mFile, "r");
    if (fileID == -1) 
        error("Could not open the file");
    end

    count = 0;
    while ~feof(fileID)
        inLine = fgetl(fileID);
        if inLine == -1
            break
        end
        inLine = strip(inLine);
        if strncmp(inLine, 'function', 8)
            count = count + 1;
            fprintf("%i. %s\n", count, inLine(10:end))
        end
    end
end