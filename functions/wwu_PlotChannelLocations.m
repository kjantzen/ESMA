%hCMarker, hCMarkerSubset = wwu_PlotChannelLocations(chanlocs, varargin)
%
%plots the location of the EEG channels projected onto 2 dimensions
%chanlocs is a 1Xn eeglab channel structure where n is the nunmber of
%channels.
%varargin is a series of parameter name, value pairs that stipulate the
%plotting parameters.
%   'AxisHandle', h is the handle of the axis to draw in.  The default is 
%   to open a new figure for plotting 
% 
%   'X', 1Xn array of x values for plotting the channels markers.  The
%   default is to calculate the position from the 3D informaiton in chanlocs
%
%   'Y', 1Xn array of y values for plotting the channels markers.  The
%   default is to calculate the position from the 3D informaiton in chanlocs
%
%   'Elec_SelColor', c where c is a 1x3 array of real values indicating the
%   rgb color of the selected electrodes. Default = [.2,.8,.2]
%
%   'Elec_Color', c where c is a 1x3 array of real values indicating the
%   rgb color of the  electrodes. Default = [1,1,1]
%
%   'Elec_Size', sz where sz is the size in points of the electrode marker.
%   Default = 10;
%
%   'Elec_SelSize', sz where sz is the size in points of the selected 
%   electrode marker. Default = 10;
%
%   'HeadBorder', 'on'|'off' indicated whether to draw the border of the
%   head around the electrodes.  Default = 'on'
%
%   'Subset', 1Xs integer array where indicating the indx in chanlocs of
%   the subset of selected electrodes.
%
%   'Labels', 'none'|'name'|'number'|'both' indicates what style of label
%   to use each marker.  Name is the electrode name and number is the
%   electrode number. Default = 'both'
%
%   'LabelPos, 'inside'|'outside' is a string indicating the location of
%   the labels. Inside will place the label inside the marker.  Outside
%   will place the label above the marker.  Default='outside'
%
%Returns
%hCMarker is a handle to the scatter object for the markers
%hCMarkerSubset is a handle to the scatter object of the highlighted
%markers
%
function [hCMarker,hCMarkerSubset] = wwu_PlotChannelLocations(chanlocs, varargin)

 p = wwu_finputcheck(varargin, {...
        'AxisHandle', 'handle', [], [];...
        'X', 'real', [], []; ...
        'Y', 'real', [], []; ...
        'Elec_Selcolor', 'real', [0,1], [.2,.8,.2];...
        'Elec_Color', 'real', [0,1], [1,1,1];...
        'Elec_Size', 'integer', [1], 10;...
        'Elec_SelSize', 'integer', [1],10;...
        'HeadBorder', 'string', {'on', 'off'}, 'on';...
        'Subset', 'integer', [], [];...
        'Labels', 'string', {'none', 'name', 'number', 'both'}, 'both';...
        'LabelPos', 'string', {'inside', 'outside'}, 'outside';...
        'LabelColor', 'real', [0,1], [0,0,0];...
        'Callback', 'string', [], ''
        });
    

if isempty(p.Subset) 
    plot_subset = false;
else
    plot_subset = true;
end

if isempty(p.AxisHandle)
    figure
    set(gcf, 'color', 'w');
    p.AxisHandle = subplot(1,1,1);
else
    cla(p.AxisHandle);
end

% %compute some X and Y positions for plotting results
 if isempty(p.X) || isempty(p.Y)
     [p.Y,p.X] = wwu_ChannelProjection(chanlocs);
 end
 
switch p.HeadBorder
    case 'on'
        rectangle(p.AxisHandle,'position', [0, .1, 1, .9], 'Curvature', [1, 1]);
        hold(p.AxisHandle, 'on');
end    
%hCMarker = plot(p.AxisHandle,p.X,p.Y, 'o', 'markersize', p.Elec_Size, 'markerfacecolor', p.Elec_Color, 'markeredgecolor', 'k');
hCMarker = scatter( p.X, p.Y, 'Marker', 'o', ...
    'Parent',p.AxisHandle,...
    'MarkerEdgeColor', p.Elec_Color,...
    'MarkerFaceColor', p.Elec_Color,...
    'SizeData', p.Elec_Size);


if plot_subset
    hold(p.AxisHandle, 'on');

    %plot(p.AxisHandle,p.X(p.Subset),p.Y(p.Subset), 'o', 'markersize', p.Elec_SelSize, 'markerfacecolor', p.Elec_Selcolor, 'markeredgecolor', 'k');
    hCMarkerSubset = scatter(p.X(p.Subset),p.Y(p.Subset), 'Marker', 'o', ...
    'Parent',p.AxisHandle, ...
    'MarkerEdgeColor', 'k',...
    'MarkerFaceColor', p.Elec_Selcolor,...
    'SizeData', p.Elec_SelSize);
else
    hCMarkerSubset = [];
end

switch p.Labels
    case 'none'
    otherwise       
        
        switch p.LabelPos
            case 'outside'
                    set(p.AxisHandle, 'units', 'pixel');
                    pos = get(p.AxisHandle, 'position');
                    xl = get(p.AxisHandle, 'xlim');
                    voffset = (xl(2)- xl(1))/pos(3) * ((p.Elec_Size/10)+2);
            otherwise
                    voffset = 0;
        end
            
        for ii = 1:length(p.X)
            switch p.Labels
                case 'name'
                    lb = sprintf('%s',chanlocs(ii).labels);
                case 'number'
                    lb = sprintf('%i',ii);
                case 'both'
                    lb = sprintf('%i:%s',ii,chanlocs(ii).labels);
            end
            set(p.AxisHandle, 'units', 'pixels');
            text(p.AxisHandle, p.X(ii), p.Y(ii)+voffset, lb,...
                'fontsize', 9,...
                'HorizontalAlignment', 'center',...
                'VerticalAlignment', 'Bottom',...
                'fontname', 'Arial',...
                'fontweight', 'demi',...
                'Color',p.LabelColor);
            
       end
end

p.AxisHandle.Box = 'off';
p.AxisHandle.XLim = [-.1, 1.1]; 
p.AxisHandle.YLim = [-.1, 1.1];

end 