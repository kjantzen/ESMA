function myFig = wwu_EditERPConditions(fileOrData)

%first figure out if the input is data or if it is a file
if isstruct(fileOrData)  %assume it is the data
    GND = fileOrData;
else  %assume it is a filename and try to load it
    GND = load(fileOrData);
end

%create the display and populate the information
h = createGUI();
myFig = h.figure;
populateGUI(h, GND);
h.figure.UserData = GND;


end
%functions
%***********************************************************************
function callback_MakeBin(hObject, event, h)

    GND = h.figure.UserData;

    binName = h.edit_binname.Value;
    binFormula = h.edit_formula.Value;

    if isempty(binName) || isempty(binFormula)
        msgbox('You must provide a bin name and formula!');
        return
    end

    maxBins = length(GND.bin_info);
    
    %extract  the data from all the bins into variables
    for ii = 1:maxBins
        dstring = sprintf('c%i = GND.indiv_erps(:,:,ii,:);', ii);
        eval(dstring);
    end

    newBinData = eval(binFormula);
    GND.indiv_erps(:,:,maxBins + 1, :) = newBinData;
    GND.grands(:,:,maxBins + 1) = mean(newBinData, 4);
    GND.grands_stder(:,:,maxBins+1) = std(newBinData, 1, 4)./sqrt(GND.sub_ct(1));
    GND.grands_t(:,:,maxBins+1) = GND.grands(:,:,maxBins + 1)./GND.grands_stder(:,:,maxBins+1);

    GND.sub_ct(maxBins + 1) = GND.sub_ct(1);
    GND.bin_info(maxBins+1).bindesc = binName;
    GND.bin_info(maxBins+1).equation = binFormula;

    outfile = fullfile(GND.filepath, GND.filename);
    if isempty(outfile) || isempty(dir(outfile))
        outfile = uiputfile();
        if outfile == 0
            return
        end
    end

    save(outfile, 'GND', '-mat');
    populateGUI(h, GND);
    h.figure.UserData = GND;

    

end
%**********************************************************************
function callback_DeleteBin(hObject, event, h)

    GND = h.figure.UserData;
    bin2delete = h.list_bins.Value;

    if length(GND.bin_info) < bin2delete 
        msgbox('The bin you are trying to delete does not seem to exist!')
        return
    end
    if ~isfield(GND.bin_info, 'equation') || isempty(GND.bin_info(bin2delete).equation)
        msgbox('This is not a computed bin and cannot be deleted');
        return
    end

    GND.indiv_erps(:,:,bin2delete,:) = [];
    GND.grands(:,:,bin2delete) = [];
    GND.grands_stder(:,:,bin2delete) = [];
    GND.grands_t(:,:,bin2delete) = [];
    GND.bin_info(bin2delete) = [];

    outfile = fullfile(GND.filepath, GND.filename);
    if isempty(outfile) || isempty(dir(outfile))
        outfile = uiputfile();
        if outfile == 0
            return
        end
    end

    save(outfile, 'GND', '-mat');
    populateGUI(h, GND);
    h.figure.UserData = GND;

end
%***********************************************************************
function populateGUI(h, GND)

    list_str = [];
    for ii = 1:length(GND.bin_info)
        list_str{ii} = sprintf('[c%i] %s', ii, GND.bin_info(ii).bindesc);
    end
    h.list_bins.Items =list_str;
    h.list_bins.ItemsData = 1:length(GND.bin_info);

end
function callback_Close(~,~)
    closereq;
end
%***********************************************************************
function h = createGUI()
%create the GUI
p = plot_params;

width = 450; height = 300;
x = (p.screenwidth-width)/2; y = (p.screenheight - height)/2;

h.figure = uifigure('Position', [x,y,width,height],...
    'Color', p.backcolor, ...
    'ToolBar', p.toolbar,...
    'MenuBar', p.menubar,...
    'Resize','off');

h.panel_left = uipanel('Parent', h.figure,...
    'Position', [10,10,210,280],...
    'Title', 'Existing Conditions',...
    'Units','normalized');

h.list_bins = uilistbox('Parent', h.panel_left,...
    'BackgroundColor',p.textfieldbackcolor,...
    'FontColor', p.textfieldfontcolor,...
    'Position', [5,40,200,200]);

h.btn_delete = uibutton('Parent', h.panel_left,...
    'BackgroundColor',p.buttoncolor,...
    'FontColor',p.buttonfontcolor,...
    'Text', 'Delete',...
    'Position', [5, 5, p.buttonwidth, p.buttonheight]);


h.panel_left = uipanel('Parent', h.figure,...
    'Position', [225,50,215,240],...
    'Title', 'Create New Conditions',...
    'Units','normalized');


uilabel('Parent', h.panel_left,...
    'Position', [5,190,205,30],...
    'Text', 'New Condition Name');

h.edit_binname = uieditfield('Parent', h.panel_left,...
    'BackgroundColor',p.textfieldbackcolor,...
    'FontColor', p.textfieldfontcolor,...
    'Position', [5,165, 205,25],...
    'Placeholder','sum of first two conditions');

uilabel('Parent', h.panel_left,...
    'Position', [5,120,205,20],...
    'Text', 'Equation');

h.edit_formula = uieditfield('Parent', h.panel_left,...
    'BackgroundColor',p.textfieldbackcolor,...
    'FontColor', p.textfieldfontcolor,...
    'Position', [5,96, 205,25],...
    'Placeholder','c1+c2');

h.btn_cancel = uibutton('Parent', h.figure,...
    'BackgroundColor',p.buttoncolor,...
    'FontColor',p.buttonfontcolor,...
    'Text', 'Cancel',...
    'Position', [280, 10, p.buttonwidth, p.buttonheight]);


h.btn_create = uibutton('Parent', h.figure,...
    'BackgroundColor',p.buttoncolor,...
    'FontColor',p.buttonfontcolor,...
    'Text', 'Create',...
    'Position', [280+ 10 + p.buttonwidth, 10, p.buttonwidth, p.buttonheight]);

h.btn_create.ButtonPushedFcn = {@callback_MakeBin, h};
h.btn_delete.ButtonPushedFcn = {@callback_DeleteBin, h};
h.btn_cancel.ButtonPushedFcn = @callback_Close;

end

