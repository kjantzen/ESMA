%STUDY_DISPLAYFILEINFORMATION
% study_DisplayFileInformation(study, fnames) displays basic file
% information for the files passed in the fnames variable.
%
% Inputs
%   study - an hcnd_eeg study structure
%   fnames - a cell array of strings containing the names of files to
%   display informaiton for.  The assumption is that the files are all of
%   the same type and stage of processing and that there is one file listed
%   for each participant in your study.
%
% Outputs
%   none
%
function study_DisplayFileInformation(study, fnames)

%check to see if the gui already exists
h = findall(groot, 'Type', 'figure', 'Tag', 'hcnd_file_information');
h = build_gui(h);
drawnow

%add file information to the display
populateFileInformation(h, fnames)
%that is it unless I add funcitonality in future.

end
% *************************************************************************
function h = build_gui(existingHandle)

scheme = eeg_LoadScheme;

W = 400;H = 600;
figPos = [600,scheme.ScreenHeight-H, W,H];
if isempty(existingHandle)
    h.figure = uifigure("WindowStyle","normal",'Name','File Properties',...
        'Position',figPos, 'Color',scheme.Window.BackgroundColor.Value,...
        'Tag', "hcnd_file_information");
else
    delete(existingHandle.Children);
    h.figure = existingHandle;
end

h.grid = uigridlayout(h.figure, [1,1],"BackgroundColor",scheme.Window.BackgroundColor.Value);

h.uitree = uitree(h.grid,"BackgroundColor",scheme.Edit.BackgroundColor.Value,...
    'FontName', 'Courier',...
    'FontSize',12,... %scheme.Edit.FontSize.Value,...
    'FontColor', scheme.Edit.FontColor.Value,...
    'FontWeight','bold');

end
% *************************************************************************
function populateFileInformation(h, fnames)

nFiles = length(fnames);
n = h.uitree.Children;
if ~isempty(n)
    delete(n);
end

%load the first data file
pb = uiprogressdlg(h.figure, "Cancelable","off","Message",'Loading data and building display','Value',0);
for ii = 1:nFiles
    pb.Value = ii/nFiles;
    [p, f, e] = fileparts(fnames{ii});
    if ~isempty(p) && length(p) > 8
        fileEntry = [p(end-8:end),' --> ', f];
    else
        fileEntry = [p,' --> ',f];
    end
    n = uitreenode('Parent', h.uitree, 'Text', fileEntry);
    switch lower(e)
        case {'.cnt', '.gnd', '.epc', '.erp', '.set'}
            data = wwu_LoadEEGFile(fnames{1}, 'header');
            addFields(n,data);
        otherwise
            msg = sprintf('Cannot display information for file type %s.', e);
            uitreenode('Parent', n, 'Text',msg);
    end

end
close(pb);
end

%function to call recursively when adding fields from a structure
% *************************************************************************
function addFields(parent, struct)
    fields  = fieldnames(struct);
    maxTabs = maxTabNums(fields);

    for ii = 1:length(fields)
        nameStr = tabStr(maxTabs, fields{ii});
        n = uitreenode('Parent',parent, 'Text', nameStr);
        fieldClass = class(struct.(fields{ii}));
        fieldScalar = isscalar(struct.(fields{ii}));
        fieldEmpty = isempty(struct.(fields{ii}));
        if ~fieldEmpty
            switch fieldClass
                case 'struct'
                    n.Text = sprintf('%s[ %s struct ]  Expand node to view first entry.', n.Text,  makeSizeString(struct.(fields{ii})));
                    addFields(n, struct.(fields{ii})(1));
                case {'double' 'single' 'integer'}
                    if fieldScalar
                        n.Text = sprintf('%s%s',n.Text, num2str(struct.(fields{ii})));
                    else
                        n.Text = sprintf('%s[ %s %s ]', n.Text, makeSizeString(struct.(fields{ii})), fieldClass);
                    end
                case 'char' 
                    n.Text = sprintf('%s%s', n.Text, struct.(fields{ii}));
                case 'cell'
                    if isscalar(struct.(fields{ii}){1})
                        n.Text = [n.Text, struct.(fields{ii}){1}];
                    else
                        n.Text = sprintf('%s[ %s %s ]', n.Text, makeSizeString(struct.(fields{ii}){1}), fieldClass);
                    end
            end
        else
            n.Text = sprintf('%s[ ]',n.Text);
        end
    end   
end
% *************************************************************************
function szMsg = makeSizeString(field)
    sz = size(field);
    szMsg = num2str(sz(1));
    if length(sz) > 1
        szMsg = [szMsg, sprintf(' X %i', sz(2:end))] ;
    end
end                  
% *************************************************************************
function mn = maxTabNums(fields)
    mn = max(ceil(cellfun(@length, fields)/4+1));
end
% *************************************************************************
function str = tabStr(maxTabs, str)
    nchars = (maxTabs * 4 - length(str));
    str(end+1:end+nchars) = ' ';
end