%Return the 2-D projection of a set of 3D electrodes 
%
%Usage [X,Y] = wwu_ChannelProjection(chanlocs, 'option', optionval,...)
%Inputs -   chanlocs:  an EEGlab channel structure
%           Normalize:  optional arguement.  A valuye of 1 indicates that 
%           output should be normalized between -1:1.  A 0 indicates no 
%           normalization (default 1).
function [X,Y] = wwu_ChannelProjection(chanlocs, varargin)


 p = finputcheck(varargin, {...
        'Normalize', 'real', [0,1], 1;...
        'ScaleForTopo', 'real', [0,1], 0;...
        });
    
%compute some X and Y positions for plotting results
theta = [chanlocs.theta] * pi/180;
rho = [chanlocs.radius];
[X,Y] = pol2cart(theta,rho);

if p.Normalize == 1
    X = (X-(min(X))) /(max(X)-min(X));
    Y = (Y-(min(Y))) /(max(Y)-min(Y));
end

if p.ScaleForTopo
    Y = Y-.5; X = X-.55;
    X = X * .89; Y = Y * .79;
end
