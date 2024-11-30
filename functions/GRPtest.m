myPath = '/Users/jantzek/Library/CloudStorage/OneDrive-WesternWashingtonUniversity/Classes/BNS 327/Winter24/classData/N170/across subject'


GNDFile = "Last Atttempt .GND";

load(fullfile(myPath, GNDFile), "-mat");

bC = [GND.indiv_conditions{:}];
betweenConditions = unique(bC);
GNDList = [];
for ii = 1:length(betweenConditions)
    l = cellfun(@(x) strcmp(betweenConditions{ii}, x), bC);
    sets2GND(GND.indiv_fnames(l), 'out_fname', betweenConditions{ii}, 'verblevel', 3)
    GNDList{ii} = [betweenConditions{ii}, '.GND'];
end

GRP = GNDs2GRP(GNDList);
