%Return the 2-D projection of a set of 3D electrodes 
%
%Usage [X,Y] = wwu_ChannelProjection(chanlocs, 'option', optionval,...)
%Inputs -   chanlocs:  an EEGlab channel structure
%           Normalize:  optional boolean arguement.  if true indicates that 
%           output should be normalized between 0 and 1.  0 indicates no 
%           normalization (default 1).
%
%           ScaleForTopo: Optional boolean.  if true the locations will be
%           centered and scaled to approx [-.5, .5] which works for a topo.
%           Normalization is always conducted when ScaleForTopo = true.
function [X,Y] = wwu_ChannelProjection(chanlocs, varargin)

 p = finputcheck(varargin, {...
        'Normalize', 'boolean', [0, 1], 1;...
        'ScaleForTopo', 'boolean', [0, 1], 0;...
        });
    
%compute some X and Y positions for plotting results
theta = [chanlocs.theta] * pi/180;
rho = [chanlocs.radius];
[X,Y] = pol2cart(theta,rho);

if p.Normalize || p.ScaleForTopo
    X = (X-(min(X))) /(max(X)-min(X));
    Y = (Y-(min(Y))) /(max(Y)-min(Y));
end

if p.ScaleForTopo
    Y = Y-.5; X = X-.55;
    X = X * .89; Y = Y * .79;
end
