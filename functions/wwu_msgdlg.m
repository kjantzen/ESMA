function output = wwu_msgdlg(p)
%wwu_msgdlg(params) is an hcnd_eeg replacement for the matlab msgbox function.
% It presents an message to the user as well as possible button options and
% returns a test string indicating which button was pushed.  
%
%Inputs - params is a structure whos fields contain the following dialog box
% parameters
%   .msg    the message to display to the user
%   .title  the dialog title
%   .options a cell array of strings with the title of button options
%   
%Outputs - result is a character vector containing the text of the button
%   pressed
%
assert(nargin==1, 'wwu_inputdlg:invalidNumberOfInputs', ...
    'The number of inputs is invalid.  Input should be a single structure.');

assert(isfield(p, 'msg'), 'wwu_inputdlg:noMsgInput',...
    'The input parameter must contain a message field.');

assert(isfield(p, 'title'), 'wwu_inputdlg:noTitleInput',...
    'The input parameter must contain a title field.');

assert(isfield(p, 'options'), 'wwu_inputdlg:noOptionsInput',...
    'The input parameter must contain an options field.');

nButtons = length(p.options);

assert(~isempty(nButtons) && nButtons >=1, 'wwu_inputdlg:emptyOptions',...
    'The options parameters must contain at least one string cell containing a button label');

scheme = eeg_LoadScheme;
width = 400; height = 150;
left = (scheme.ScreenWidth - width)/2;
bottom = (scheme.ScreenHeight - height)/2;
buttonWidth = 80; buttonHeight = 30;

% build the dialog box
h.fig = uifigure('WindowStyle', 'modal',...
    'Position', [left, bottom, width, height],...
    'Name',p.title,...
    'Color',scheme.Window.BackgroundColor.Value,...
    'Resize','off');

h.label_msg = uilabel('Parent', h.fig,...
    'Position', [30,buttonHeight+20,width-60,height-(buttonHeight+30)],...
    'WordWrap','on',...
    'FontSize',12,...
    'FontColor',scheme.Label.FontColor.Value,...
    'FontName', scheme.Label.Font.Value,...
    'FontWeight','normal',...
    'Text',p.msg,...
    'VerticalAlignment','center',...
    'HorizontalAlignment','left');

for ii = 1:nButtons
    l = width-(ii*(5 + buttonWidth));
    h.btn_option(ii) = uibutton('Parent', h.fig,...
        'Position', [l, 10,buttonWidth,buttonHeight],...
        'Text',p.options{ii},...
        'BackgroundColor',scheme.Button.BackgroundColor.Value,...
        'FontName', scheme.Button.Font.Value,...
        'FontSize', scheme.Button.FontSize.Value,...
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
    output= [];
end

%**************************************************************************
function callback_handleButtonPress(hObject, hEvent, h)

    h.fig.UserData = hObject.Text;
    uiresume(h.fig);