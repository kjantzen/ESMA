function GRP = study_RunFMUTBetween(GND, stats)
% study_RUNFMUTBetween(GND, stats)
%   Runs a between subject mass univariate ANOVA on the data found in a
%   FMUT format GND file.
% INPUTS
%   GND     a GND structure (MUT & FMUT format) that contains the data to
%           analyze
%   stats.  a big ol structure with lots of useful information

GRP = [];

% so the most basic test - I will create a function to validate GND files
% if it becomes a problem in the future
if isempty(GND)
    warning('The GND file is empty.  Aborting statistics');
    return
end
if ~isfield(GND, 'indiv_conditions') || isempty(GND.indiv_conditions)
    fprintf('No between conditions found for these data - aborting\n')
    return
end
if length(GND.indiv_conditions) ~= GND.sub_ct(1)
    warning('The condition list length does not match the number of subjects')
    return
end
if ~isfield(stats, 'ConditionNumber') || (stats.ConditionNumber >  length(GND.indiv_conditions{1}))
    warning('Invalid condition number.  Defaulting to condition 1')
    stats.ConditionNumber = 1;
end

%create an output filename for the GRP file
[~,f, ~] = fileparts(GND.filename);
GRPFileName = [f, '.GRP'];

ConditionArray = [GND.indiv_conditions{stats.ConditionNumber,:}];
betweenConditions = unique(ConditionArray);
fprintf("Found %i unique condition names\n", length(betweenConditions))

%check for consistency in participant number
sNum = zeros(size(betweenConditions));
for ii = 1:length(betweenConditions)
    indx = matches(ConditionArray, betweenConditions{ii});
    sNum(ii) = sum(indx);
end

maxParticipants = min(sNum); 

%check if this GRP file exists already
%if it does we can use that one without creating a new one
%otherwise we will create one from scratch
GRP = checkForExistingGRP(fullfile(GND.filepath, GRPFileName), betweenConditions, maxParticipants);
if isempty(GRP)
    fprintf('Becasue the number of participants in each group must be equal, the maximum # of particiapnts/group is %i\n', maxParticipants);
    fprintf('Any participant over %i will be ignored\n', maxParticipants);
    
    %create a GND file for each condition as per the requirements of MUT and
    %FMUT
    GNDList = [];
    for ii = 1:length(betweenConditions)
        indx = matches(ConditionArray, betweenConditions{ii});
        fnames = GND.indiv_fnames(indx);
        fprintf('Found %i files for %s\n',length(fnames), betweenConditions{ii});
        if length(fnames) > maxParticipants
            fprintf('Ignoring last %i participants...\n', maxParticipants - length(fnames));
            fnames = fnames(1:maxParticipants);
        end
        sets2GND(fnames, 'out_fname', betweenConditions{ii}, 'verblevel', 1)
        GNDList{ii} = [betweenConditions{ii}, '.GND']; %#ok<AGROW>
    end
    %now create a group file from those GND files
    
    
    GRP = GNDs2GRP(GNDList, 'group_desc', betweenConditions,...
        'exp_desc', GND.exp_desc, ...
        'out_fname',GRPFileName,...
        'out_fname', 'no save');
end

if contains(stats.test, 'clust')
    stats.test = 'FclustGRP';
elseif contains(stats.test, 'fdr')
    stats.test = 'FfdrGRP';
else
    stats.test = 'FmaxGRP';
end
%now pass the GRP file to the statistics function
%Options are :
%   FclustGRP - Cluster mass tests for designs with a between-subjects factor.
%   FfdrGRP	- FDR corrected mass univariate analysis for designs with a between-subjects factor.
%   FmaxGRP	- Fmax mass tests for designs with a between-subjects factor.
command_str = [stats.test, '(GRP, ''bins'', stats.cond_order, ''bg_factor_name'', ''Between'','];
command_str = [command_str, '''wg_factor_names'', stats.factors, ''wg_factor_levels'', stats.clevels,'];
command_str = [command_str, '''time_wind'', [stats.winstart, stats.winend],'];
command_str = [command_str, stats.ch_hood stats.head_radius];
command_str = [command_str, '''plot_raster'', ''no'', ''mean_wind'', stats.winmean'];
command_str = [command_str, ',''', stats.q_or_alpha, ''', stats.alpha, ''save_GRP'', ''no'')'];
GRP =  eval(command_str);
 
GRP.filepath = GND.filepath;
GRP.filename = GRPFileName;

% *************************************************************************
function GRP = checkForExistingGRP(GRPFile, Conditions, NPart)
%Check if the GRP file we want to create already exists and if it does,
%prompt the user to use the existing one.
    GRP = [];
    if ~isfile(GRPFile)  %check that the file already exists
        return
    end
    GRP = load(GRPFile, '-mat'); 
    if isfield(GRP, 'GRP')
        GRP = GRP.GRP;
    end
    if isfield(GRP, 'GND')
        GRP = GRP.GND;
    end
    if length(Conditions) ~= length(GRP.GND_fnames)  %see that it has the correct # of between conditions
        return
    end
    nMatches = 0;
    for ii = 1:length(GRP.GND_fnames)       %check tha tthose condition more or less match
        if isfile(fullfile(GRP.filepath, GRP.GND_fnames{ii}))
            if length(GRP.indiv_fnames{1}) == NPart
                nMatches = nMatches + 1;
            end
        end
    end           
    if nMatches == length(GRP.GND_fnames)
        fprintf('Using an existing GRP file...I hope this is OK...\n');
    else
        GRP = [];
    end
