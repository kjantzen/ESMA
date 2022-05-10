function [file_id, option, writeflag] = wwu_verifySaveFile(path, outfile, file_id, ext, option)

    narginchk(5,6);
    
    OPTION_QUERY = 0;
    OPTION_OVERWRITE = 1;
    OPTION_APPEND = 2;
    OPTION_IGNORE = 3;

    %assume the file will be written
    writeflag = true;

   if nargin < 5 || isempty(OPTION_QUERY)
        option = OPTION_QUERY;
    end

    %if the file does not exist just return the original information
    tempfile = fullfile(path, [outfile, file_id, ext]);
    if ~isfile(tempfile)
        return
    end
    
    %if the user sends the ignore option then just return
    if option == OPTION_IGNORE
        writeflag = false;
        return
    end

    if option == OPTION_QUERY
        msg = sprintf('The output file %s already exists.', outfile);
        response = questdlg(msg, 'Output exists', 'Overwrite', 'New Filename', 'Ignore Existing', 'New Filename');
        switch response
            case 'Overwrite'
                option = OPTION_OVERWRITE;
            case 'Ignore Existing'
                option = OPTION_IGNORE;
            case 'New Filename'
                option = OPTION_APPEND;
        end
    end

    %if we get this far the file aready exists
    %check the possible options
    %if the input option is to overwrite then simply return the original
    %filename and it will be overwritte
    if option == OPTION_APPEND
        checking = true;
        while checking
            [~,f, e ] = fileparts(outfile);
            c = str2num(file_id(end));
            if isempty(c)
                c = num2str(1);
            else
                c = num2str(c + 1);
                file_id = file_id(1:end-1);
            end
            file_id = [file_id,c];
            tempfile = fullfile(path, [outfile, file_id, ext]);
            if ~isfile(tempfile)
                checking = false;
            end
        end

    end
        

