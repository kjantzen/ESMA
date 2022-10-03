function output = study_SelectBinGroup(study)
%wwu_inputdlg(params) is a replacement for the matlab inputdlg function.
%It presents an input dialog for the user to enter text.  It returns the
%text and information about which button was pushed to the user.
%
%Inputs - params is a structure whos fields contain the following dialog box
% parameters
%   .msg    the message to display to the user
%   .title  the dialog title
%   .options a cell array of strings with the title of button options
%   
%Outputs - output is a structure whos fields contain the following output 
% parameters
%   .input  the information the user entered into the dialog
%   .option the title of the button the user pressed.

assert(~isempty(study), 'study_SelectChangGroup:invalidStudy', ...
    'Please pass a valid hcnd Study.');

if ~isfield(study, 'bingroup') || isempty(study.bingroup)
    uialert('This study does not have any bin groups defined.  Use the Study Editor to define at least one bin group first.');
    return
end

pp = plot_params;
width = 300; height = 400;
left = (pp.screenwidth - width)/2;
bottom = (pp.screenheight - height)/2;

% build the dialog box
h.fig = uifigure('WindowStyle', 'modal',...
    'Position', [left, bottom, width, height],...
    'Name','Epoch Bin Selector',...
    'Color',pp.backcolor,...
    'Resize','off');


uilabel('Parent', h.fig,...
    'Position', [10,height-30,width-20,20],...
    'FontSize',12,...
    'FontColor',pp.labelfontcolor,...
    'Text','Epoch Bins',...
    'VerticalAlignment','bottom',...
    'HorizontalAlignment','left');

h.tree_bingrouplist = uitree('Parent', h.fig,...
    'Position', [10,40,width-20, height-55]);

options = {'Cancel', 'OK'};
for ii = 1:length(options)
    l = width - ((pp.buttonwidth + 5)*ii);
    h.btn_option(ii) = uibutton('Parent', h.fig,...
        'Position', [l, 5,pp.buttonwidth,pp.buttonheight],...
        'Text',options{ii});
end

for ii = 1:length(options)
    h.btn_option(ii).ButtonPushedFcn = {@callback_handleButtonPress, h, study};
end
populate_bintree(study, h)

uiwait(h.fig);

if isvalid(h.fig)
    output = h.fig.UserData;
    delete(h.fig);
else
    output.cnum = [];
    output.gnum = [];
    output.option = [];
end

    
 
%**************************************************************************
function callback_handleButtonPress(hObject, hEvent, h, study)

    n = h.tree_bingrouplist.SelectedNodes;
    if isempty(n)
         uialert(h.figure, 'Please select an Epoch Group first.', 'Create Epoch files');   
         return
    end
    info.gnum = n.NodeData{1};
    info.cnum = n.NodeData{2};
    info.option = hObject.Text;
    
    h.fig.UserData = info;

    uiresume(h.fig);
%************************************************************************
%this fills the epoch tree information list with the current epoch
%information for the loaded study
function populate_bintree(study, h, select)

if nargin < 3
    select = [0,0];
end
%clear existing nodes
n = h.tree_bingrouplist.Children;
n.delete;

if ~isfield(study, 'bingroup')
    return
end

node_to_select = [];

for ii = 1:length(study.bingroup)
    n = uitreenode('Parent', h.tree_bingrouplist,'Text', study.bingroup(ii).name,'NodeData', {ii, 0});
    uitreenode('Parent', n, 'Text', sprintf('start:\t%0.3g', study.bingroup(ii).interval(1)),...
        'NodeData', {ii, 0});
    uitreenode('Parent', n, 'Text', sprintf('end:\t\t%0.3g', study.bingroup(ii).interval(2)),...
        'NodeData', {ii, 0});
    n2 = uitreenode('Parent', n, 'Text', 'bins',...
        'NodeData', {ii, 0});

    if isfield(study.bingroup(ii), 'bins')
        for jj = 1:length(study.bingroup(ii).bins)
            n3 = uitreenode('Parent', n2, 'Text', sprintf('%i:\t%s',jj, study.bingroup(ii).bins(jj).name),...
                'NodeData', {ii, jj});
            uitreenode('Parent', n3, 'Text', sprintf('bin events:\t%s ', study.bingroup(ii).bins(jj).events{:}),...
                'NodeData', {ii, jj});
            if (ii==select(1)) && (jj==select(2))
                node_to_select = n3;
            end

        end
    end

end
if ~isempty(node_to_select)
    expand(node_to_select.Parent);
    h.tree_bingrouplist.SelectedNodes = node_to_select;
end