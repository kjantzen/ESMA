function pstruct = plot_params()


pstruct.backcolor = [240/255,240/255,240/255];

pstruct.textfieldbackcolor = [250/255,250/255,250/255]';
pstruct.textfieldfontcolor = [40/255, 40/255, 40/255]';
pstruct.labelfontcolor = [100/255,100/255,100/255]';

pstruct.goodicactcolor = [117/255, 112/255, 179/255];
pstruct.badicactcolor = [217/255,95/255,2/255];

scrsze = get(0, 'ScreenSize');

pstruct.screenleft = scrsze(1);
pstruct.screenbottom = scrsze(2);
pstruct.screenwidth = scrsze(3);
pstruct.screenheight = scrsze(4);

pstruct.numbertitle = 'off';
pstruct.menubar = 'none';
pstruct.units = 'pixels';
pstruct.dockcontrols = 'off';
pstruct.toolbar = 'none';
pstruct.windowstyle = 'normal';
pstruct.monospaced = 'Monaco';


pstruct.buttonheight = 25;
pstruct.buttonwidth = 75;
pstruct.buttoncolor = [80/255, 80/255, 80/255]';
pstruct.buttonfontcolor = [200/255,200/255,200/255]';

pstruct.goodsubjectcolor = [.2,.6,.2];
pstruct.badsubjectcolor = [.8,.2,.2];

pstruct.goodtrialcolor = [.2,.6,.2];
pstruct.badtrialcolor = [.8,.2,.2];


