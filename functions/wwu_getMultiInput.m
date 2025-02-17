function userData = wwu_getMultiInput(instruction, prompts)
arguments
    instruction (1,1) string {mustBeNonempty}
    prompts (1,:) cell
end

n =  length(prompts);

%create a GUI with n input text boxes
h = build_gui(n, prompts, instruction);

uiwait(h.figure);

userData = h.figure.UserData;
delete(h.figure)


end
% *************************************************************************
function callback_closedlg(hObject, event, h)

    if contains(hObject.Tag, 'Continue')
        d = get(h.input, "Value");
        h.figure.UserData = d;
    end
    uiresume(h.figure)

end
% *************************************************************************
function h = build_gui(n, prompts, instruction)
scheme = eeg_LoadScheme;

W = 350; H = 250;
L = (scheme.ScreenWidth - W)/2; B = (scheme.ScreenHeight - H)/2;

sl = cellfun(@strlength, prompts);
bw = max(sl) * 5;

h.figure = uifigure(...
    'Position', [L,B,W,H],...
    'Color', scheme.Window.BackgroundColor.Value,...
    'Name', 'Define Condition Levels',...
    'NumberTitle', 'off',...
    'Resize', 'off',...
    'menubar', 'none', ...
    'Tag', 'Continue',...
    'WindowStyle','modal');

h.label_instruction = uilabel(...,
    'Parent', h.figure,...
    'Position',[10, H-40, W-20,40],...
    "Text", instruction,...
    'FontColor', scheme.Label.FontColor.Value,...
    'FontSize', scheme.Label.FontSize.Value + 1,...
    'HorizontalAlignment','center',...
    'VerticalAlignment','bottom',...
    'WordWrap','on');

h.panel_main = uipanel(...
    'Parent', h.figure,...
    'Position', [10, 40, W-20, H-100],...
    'BackgroundColor', scheme.Panel.BackgroundColor.Value,...
    'Scrollable', true);

h.button_cancel = uibutton(...
    'Parent', h.figure,...
    'Position',[W-180, 10, 80, 25],...
    'Text','Cancel',...
    'BackgroundColor',scheme.Button.BackgroundColor.Value,...
    'FontColor',scheme.Button.FontColor.Value,...
    'FontName', scheme.Button.Font.Value,...
    'FontSize',scheme.Button.FontSize.Value,...
    'Tag','Cancel');

h.button_continue = uibutton(...
    'Parent', h.figure,...
    'Position',[W-90, 10, 80, 25],...
    'Text','Continue',...
    'BackgroundColor',scheme.Button.BackgroundColor.Value,...
    'FontColor',scheme.Button.FontColor.Value,...
    'FontName', scheme.Button.Font.Value,...
    'FontSize',scheme.Button.FontSize.Value,...
    'Tag', 'Continue');

y_interval = scheme.Edit.Height.Value + 7;

bottom = 10+(n-1) * y_interval;
if (bottom + 40) < (H-100)
    bottom = H-140;
end
for ii = 1:n
    uilabel(...
        'Parent', h.panel_main,...
        'Position', [5, bottom, bw, 20],...
        'Text', prompts{ii},...
        'FontSize', scheme.Label.FontSize.Value,...
        'FontColor', scheme.Label.FontColor.Value,...
        'HorizontalAlignment', 'right');

    h.input(ii) = uieditfield(...
        'Parent', h.panel_main,...
        'BackgroundColor', scheme.Edit.BackgroundColor.Value,...
        'FontColor',scheme.Edit.FontColor.Value,...
        'InputType','text',...
        'Position', [bw+10,bottom ,330-bw-15,scheme.Edit.Height.Value]);

    bottom = bottom - y_interval;
end
h.button_continue.ButtonPushedFcn = {@callback_closedlg, h};
h.button_cancel.ButtonPushedFcn = {@callback_closedlg, h};
h.figure.CloseRequestFcn = {@callback_closedlg, h};


end