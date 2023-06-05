function output = wwu_inputdlg(p)
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

assert(nargin==1, 'wwu_inputdlg:invalidNumberOfInputs', ...
    'The number of inputs is invalid.  Input should be a single structure.');

assert(isfield(p, 'msg'), 'wwu_inputdlg:noMsgInput',...
    'The input parameter must contain a message field.');

assert(isfield(p, 'title'), 'wwu_inputdlg:noTitleInput',...
    'The input parameter must contain a title field.');

assert(isfield(p, 'options'), 'wwu_inputdlg:noOptionsInput',...
    'The input parameter must contain a options field.');


nButtons = length(p.options);

assert(~isempty(nButtons) && nButtons >=1, 'wwu_inputdlg:emptyOptions',...
    'The options parameters must contain at least one string cell containing a button label');

scheme = eeg_LoadScheme;
width = 400; height = 150;
left = (scheme.ScreeWwidth - width)/2;
bottom = (scheme.ScreenHeight - height)/2;
buttonWidith = 80;

% build the dialog box
h.fig = uifigure('WindowStyle', 'modal',...
    'Position', [left, bottom, width, height],...
    'Name',p.title,...
    'Color',scheme.Window.BackgroundColor.Value,...
    'Resize','off');

h.label_msg = uilabel('Parent', h.fig,...
    'Position', [50,100,width-100,height-100],...
    'WordWrap','on',...
    'FontSize',14,...
    'FontColor',scheme.Label.FontColor.Value,...
    'FontName', scheme.Label.Font.Value,...
    'FontWeight','bold',...
    'Text',p.msg,...
    'VerticalAlignment','center',...
    'HorizontalAlignment','left');

h.edit_input = uieditfield('Parent', h.fig,...
    'Position', [80, 60, width-160, 30],...
    'FontSize', 14,...
    'BackgroundColor',scheme.Edit.BackgroundColor.Value,...
    'FontColor',scheme.Edit.FontColor.Value,...
    'FontName', scheme.Edit.Font.Value,...
    'FontSize', scheme.Edit.FontSize.Value);

for ii = 1:nButtons
    
    l = width-(ii*(5 +pp.buttonwidth));
    h.btn_option(ii) = uibutton('Parent', h.fig,...
        'Position', [l, 5,buttonWidth,buttonHeight],...
        'Text',p.options{ii},...
        'BackgroundColor',scheme.Button.BackgroundColor.Value,...
        'FontName', scheme.Button.Font.Value,...
        'FontSize', scheme.Button.FontSize,...
        'FontColor', scheme.Button.FontColor.Value);
end

for ii = 1:nButtons
    h.btn_option(ii).ButtonPushedFcn = {@callback_handleButtonPress, h};
end

uiwait(h.fig);

if isvalid(h.fig)
    output = h.fig.UserData;
    delete(h.fig);
else
    output.input = [];
    output.option = [];
end

%**************************************************************************
function callback_handleButtonPress(hObject, hEvent, h)

    info.input = h.edit_input.Value;
    info.option = hObject.Text;

    h.fig.UserData = info;

    uiresume(h.fig);