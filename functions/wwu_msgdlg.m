function output = wwu_msgdlg(msg, title, button, options)
%wwu_msgdlg(params) is an hcnd_eeg replacement for the matlab msgbox function.
% It presents an message to the user as well as possible button options and
% returns a test string indicating which button was pushed.  
%
%Inputs - params is a structure whos fields contain the following dialog box
% parameters
%   .msg    the message to display to the user
%   .title  the dialog title
%   .options a cell array of strings with the title of button options
%   .iserror a boolean indicating whether to show the error icon
%   
%Outputs - result is a character vector containing the text of the button
%   pressed
%
arguments
    msg {mustBeNonempty(msg) mustBeText(msg)};
    title {mustBeNonempty(title) mustBeText(title)};
    button (1,:) cell = {'OK'}; 
    options.isError (1,1) logical = false
end
%assert(nargin==1, 'wwu_inputdlg:invalidNumberOfInputs', ...
%    'The number of inputs is invalid.  Input should be a single
%    structure.');
%
%assert(isfield(p, 'msg'), 'wwu_inputdlg:noMsgInput',...
%   'The input parameter must contain a message field.');
% 
% assert(isfield(p, 'title'), 'wwu_inputdlg:noTitleInput',...
%     'The input parameter must contain a title field.');
% 
% assert(isfield(p, 'options'), 'wwu_inputdlg:noOptionsInput',...
%     'The input parameter must contain an options field.');
% 
% nButtons = length(p.options);
% 
% assert(~isempty(nButtons) && nButtons >=1, 'wwu_inputdlg:emptyOptions',...
%     'The options parameters must contain at least one string cell containing a button label');

scheme = eeg_LoadScheme;
width = 400; height = 150;
left = (scheme.ScreenWidth - width)/2;
bottom = (scheme.ScreenHeight - height)/2;
buttonWidth = 80; buttonHeight = 30;
nButtons = length(button);

% build the dialog box
h.fig = uifigure('WindowStyle', 'modal',...
    'Position', [left, bottom, width, height],...
    'Name',title,...
    'Resize', false,...
    'MenuBar','none',...
    'NumberTitle','off',...
    'Color',scheme.Window.BackgroundColor.Value...
   );

h.label_msg = uilabel('Parent', h.fig,...
    'Position', [84,buttonHeight+20,width-94,height-(buttonHeight+30)],...
    'WordWrap','on',...
    'FontSize',13,...
    'FontColor',scheme.Label.FontColor.Value,...
    'FontName', scheme.Label.Font.Value,...
    'FontWeight','normal',...
    'Text',msg,...
    'VerticalAlignment','center',...
    'HorizontalAlignment','center');

h.image_icon = uiimage('Parent', h.fig,...
    'Position', [10, buttonHeight+20, 64,64],...
    'BackgroundColor',scheme.Window.BackgroundColor.Value);
if options.isError
    icon_file = 'icons/error_icon.png';
else
    icon_file = 'icons/info_icon.png';
end
h.image_icon.ImageSource = icon_file;


for ii = 1:nButtons
    l = width-(ii*(10 + buttonWidth));
    h.btn_option(ii) = uibutton('Parent', h.fig,...
        'Position', [l, 10,buttonWidth,buttonHeight],...
        'Text',button{ii},...
        'FontName', scheme.Button.Font.Value,...
        'FontSize', scheme.Button.FontSize.Value,...
        'FontColor', scheme.Button.FontColor.Value,...
        'BackgroundColor', scheme.Button.BackgroundColor.Value);
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