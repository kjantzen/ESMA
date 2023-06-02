%function wwu_TFStatistics(data)
function stats = wwu_TFStatistics(data, cfg)

arguments
    %    cfg.numrandomization = number of randomizations, can be 'all'
    data = []
    cfg.method = 'permutation'
    cfg.chandim (1,1) {mustBeInteger} = 0
    cfg.numrandomization = 'all'
    %     cfg.correctm         = string, apply multiple-comparison correction, 'no', 'max', cluster', 'tfce', 'bonferroni', 'holm', 'hochberg', 'fdr' (default = 'no')
    cfg.correctm {mustBeText} = 'cluster'
    %     cfg.alpha            = number, critical value for rejecting the null-hypothesis per tail (default = 0.05)
    cfg.alpha (1,1) {mustBeNumeric, mustBeInRange(cfg.alpha, 0, 1)} = .05
    %     cfg.tail             = number, -1, 1 or 0 (default = 0)
    %     cfg.correcttail      = string, correct p-values or alpha-values when doing a two-sided test, 'alpha','prob' or 'no' (default = 'no')
    %     cfg.ivar             = number or list with indices, independent variable(s)
    cfg.ivar (1,1) {mustBeInteger} = 1
    %     cfg.uvar             = number or list with indices, unit variable(s)
    %     cfg.wvar             = number or list with indices, within-cell variable(s)
    %     cfg.cvar             = number or list with indices, control variable(s)
    %     cfg.feedback         = string, 'gui', 'text', 'textbar' or 'no' (default = 'text')
    %     cfg.randomseed       = string, 'yes', 'no' or a number (default = 'yes')
    %
    %   If you use a cluster-based statistic, you can specify the following options that
    %   determine how the single-sample or single-voxel statistics will be thresholded and
    %   combined into one statistical value per cluster.
    %     cfg.clusterstatistic = how to combine the single samples that belong to a cluster, 'maxsum', 'maxsize', 'wcm' (default = 'maxsum')
    %                            the option 'wcm' refers to 'weighted cluster mass', a statistic that combines cluster size and intensity;
    %                            see Hayasaka & Nichols (2004) NeuroImage for details
    cfg.clusterstatistic {mustBeText} = 'maxsum'
    %     cfg.clusterthreshold = method for single-sample threshold, 'parametric', 'nonparametric_individual', 'nonparametric_common' (default = 'parametric')
    %     cfg.clusteralpha     = for either parametric or nonparametric thresholding per tail (default = 0.05)
    %     cfg.clustercritval   = for parametric thresholding (default is determined by the statfun)
    %     cfg.clustertail      = -1, 1 or 0 (default = 0)
    cfg.neighbours = struct([])
    %
end
%make up data if none was passed
if isempty(data)
    data = {rand(10,20,5),rand(10,20, 5),rand(10,20, 5);rand(10,20, 5)+2,rand(10,20, 5),rand(10,20, 5)}';
end

if cfg.ivar ~= ndims(data)
    error('TFStatistics:IcompatibleInformation', 'The number of independent variables passed does not match the data structure');
end

%do some checking to make sure the data size is compatible with the
%limtations of fieldtrip statistics
if cfg.ivar > 2
    error('TFStatistics:TooManyFactors', 'Stats cannot be performed on more than 2 factors.  Try reducing dimensions first.');
elseif cfg.ivar ==2
    squareData(1:3) = false;
    [nA, nB] = size(data);
    if nA > 2 && nB > 2
        warning('I cannot reduce the interaction term to a single statistical comparison, so it won''t be included in the output');
    end
    %make the rows have the larger factor
    if nB > nA
        data = data';
        [nA, nB] = size(data);
    end

    %the biggest array that can be analyzed is 3x2.  If the first
    %deminstion is 3, an ANOVA will be run and an F test will be returned.
    %If the dimension is 2 a ttest will be returned and the results should
    %be squared.
    if nA == 2 
        squareData(1:3) = true;
    else
        squareData(2) = true;  %always square this one because it cannot more then 2
    end


else
    nA = size(data);
    if nA == 2
        squareData = true;
    else
        squareData = false;
    end
end

%build a command string
cmd = ['statcondfieldtrip(statdata, "method", cfg.method, "naccu", cfg.numrandomization,' ...
    '"alpha", cfg.alpha, "correctm", cfg.correctm, "clustersttistic", cfg.clusterstatistic,'...
    '"chandim", cfg.chandim, "neighbours", cfg.neighbours)'];
%run statistics
if cfg.ivar == 1
    %full model affects using an one way ANOVA or ttest
    statdata = data;
    [stats, df, p] = eval(cmd);
    if squaredata
        stats = stats.^2;
    end
else
    %effects for a 2 way anova broken into main effects and interactions
    %expand the data into a matrix
    dm=cell2mat(cellfun(@(x)reshape(x,[1,1,size(x)]),data,'un',0));

    %individual effects using a 1-way anova
    %main effect of rows by averaging columns
    dr = squeeze(mean(dm, 2));
    dr = num2cell(dr, 2:ndims(dr));
    dr = cellfun(@squeeze, dr, 'UniformOutput', false);
    
    %average across columns leaving just the rows
    dc = squeeze(mean(dm,1));
    dc = num2cell(dc, 2:ndims(dc));
    dc = cellfun(@squeeze, dc, 'UniformOutput', false);

    %do the stats
    statdata = dr;
    [r_stat, r_df, r_p] = eval(cmd);
    if squareData(1)
        r_stat = r_stat.^2;
    end
    statdata = dc;
    [c_stat, c_df, c_p] = eval(cmd);
    if squareData(2)
        c_stat = c_stat.^2;
    end
    %now do the interaction
    contrast = [1 -1];

    for rr = 1:nA
        inter{rr} = zeros(size(data{1}));
        for cc = 1:nB
            inter{rr} = inter{rr} + (data{rr,cc} * contrast(cc));
        end
    end

    statdata = inter;
    [rc_stat, rc_df, rc_p] = eval(cmd);
    if squareData(3)
        rc_stat = rc_stat.^2;
    end
    stats.F = {r_stat, c_stat,rc_stat};
    stats.pval = {r_p, c_p, rc_p};
    stats.df = {r_df, c_df, rc_df};
    

end


