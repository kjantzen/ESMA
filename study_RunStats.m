function fighandle = study_RunStats(GND, stats)

p = plot_params;
scheme = eeg_LoadScheme;

sz = get(0, 'ScreenSize');
W = 450; H = 300;
L = (sz(3) - W)/2; B = (sz(4) - H)/2;
h.figure = uifigure(...
    'Position', [L,B,W,H],...
    'Color', scheme.Window.BackgroundColor.Value,...
    'Name', 'Assign Conditions',...
    'NumberTitle', 'off',...
    'Resize', 'off',...
    'menubar', 'none');

fighandle = h.figure;

h.list_conditions = uilistbox(...
    'Parent', h.figure,...
    'Position', [10,40, 185, 200],...
    'BackgroundColor', scheme.Dropdown.BackgroundColor.Value,...
    'FontColor', scheme.Dropdown.FontColor.Value,...
    'FontName', scheme.Dropdown.Font.Value,...
    'FontSize', scheme.Dropdown.FontSize.Value,...
    'MultiSelect', 'on');

h.list_model = uilistbox(...
    'Parent', h.figure,...
    'Position', [255, 40, 185, 200],...
    'BackgroundColor', scheme.Dropdown.BackgroundColor.Value,...
    'FontColor', scheme.Dropdown.FontColor.Value,...
    'FontName', scheme.Dropdown.Font.Value,...
    'FontSize', scheme.Dropdown.FontSize.Value,...
    'MultiSelect', 'off');

modelkey = join(stats.factors,'x ');

uilabel('Parent', h.figure,...
    'Position', [255, 240, 185, 20],...
    'Text', modelkey,...
    'Fontsize', scheme.Label.FontSize.Value,...
    'FontName', scheme.Label.Font.Value,...
    'FontColor', scheme.Label.FontColor.Value);

uilabel('Parent', h.figure,...
    'Position', [255, 260, 185, 20],...
    'Text', 'Within Subject Factors',...
    'FontColor', p.labelfontcolor);

uilabel('Parent', h.figure,...
    'Position', [10, 240, 185, 20],...
    'Text', 'Variables',...
    'Fontsize', scheme.Label.FontSize.Value,...
    'FontName', scheme.Label.Font.Value,...
    'FontColor', scheme.Label.FontColor.Value);


h.button_add = uibutton(...
    'Parent', h.figure,...
    'Position', [200, 215, 50, 25],...
    'Text', '-->', ...
    'BackgroundColor', scheme.Button.BackgroundColor.Value,...
    'FontColor', scheme.Button.FontColor.Value,...
    'FontName', scheme.Button.Font.Value,...
    'FontSize', scheme.Button.FontSize.Value,...
    'Tag', 'add');

h.button_remove = uibutton(...
    'Parent', h.figure,...
    'Position', [200, 150, 50, 25],...
    'Text', '<--', ...
    'BackgroundColor', scheme.Button.BackgroundColor.Value,...
    'FontColor', scheme.Button.FontColor.Value,...
    'FontName', scheme.Button.Font.Value,...
    'FontSize', scheme.Button.FontSize.Value,...
    'Tag', 'rem');

h.button_dostats = uibutton(...
    'Parent', h.figure,...
    'Position', [365, 5, 80, 25],...
    'Text', 'Continue', ...
    'BackgroundColor', scheme.Button.BackgroundColor.Value,...
    'FontColor', scheme.Button.FontColor.Value,...
    'FontName', scheme.Button.Font.Value,...
    'FontSize', scheme.Button.FontSize.Value);

h.button_cancel = uibutton(...
    'Parent', h.figure,...
    'Position', [275, 5, 80, 25],...
    'Text', 'Cancel', ...
    'BackgroundColor', scheme.Button.BackgroundColor.Value,...
    'FontColor', scheme.Button.FontColor.Value,...
    'FontName', scheme.Button.Font.Value,...
    'FontSize', scheme.Button.FontSize.Value)


if contains(stats.test, 'ANOVA')
    h.button_export = uibutton(...
        'Parent', h.figure,...
        'Position', [190, 5, 80, 25],...
        'Text', 'Export', ...
    'BackgroundColor', scheme.Button.BackgroundColor.Value,...
    'FontColor', scheme.Button.FontColor.Value,...
    'FontName', scheme.Button.Font.Value,...
    'FontSize', scheme.Button.FontSize.Value)

end


%fill in the blank model information
n_factors = length(stats.factors);
levels = cellfun(@str2double, stats.levels);
n_conds = prod(levels);

bin2cond = zeros(n_factors, n_conds);
nc = 1;

%fill in the basic matrix for holding the factorial levels
for ii = 1:n_factors
    cond = 1;
    for jj = 1:n_conds          
        bin2cond(ii,jj) = cond;
        if mod(jj, nc)==0
            cond = cond + 1;
        end       
        if cond > levels(ii)
            cond = 1;
        end 
    end    
       nc = prod(levels(1:ii));
end

items = cell(1,n_conds);
for ii = 1:n_conds
    items{ii} = ['[',replace(num2str(bin2cond(:,ii)'), '  ',', '), ']'];
end

h.figure.UserData = bin2cond;

h.list_model.Items = items;
h.list_model.ItemsData = items;
h.list_model.UserData = items;
h.list_conditions.Items = {GND.bin_info.bindesc};
h.list_conditions.ItemsData = 1:length(GND.bin_info);

h.button_add.ButtonPushedFcn = {@callback_assignconditions,h};
h.button_remove.ButtonPushedFcn = {@callback_assignconditions,h};
h.button_dostats.ButtonPushedFcn = {@callback_dostats, h, GND, stats, false};
h.button_cancel.ButtonPushedFcn = {@callback_cancel, h.figure};

if contains(stats.test, 'ANOVA')
  h.button_export.ButtonPushedFcn = {@callback_dostats, h, GND, stats, true};
end

%**************************************************************************
function callback_dostats(hObject, event, h, GND, stats, exportFlag)

cond_info = h.list_model.ItemsData;
if sum(cellfun(@(a) a(1)=='[',cond_info))
    uialert(h.figure, 'Please define all conditions first.', 'Run Stats');
    return
end

pb = uiprogressdlg(h.figure, 'Title', 'Please Wait', 'Message', 'Running mass univariate statistics ... this could take a while.', 'Indeterminate', 'on');

[~,stats.winstartpt] = min(abs(stats.winstart - GND.time_pts));
[~,stats.winendpt] = min(abs(stats.winend - GND.time_pts));

if contains(stats.test, 'ANOVA')
    pb = uiprogressdlg(h.figure, 'Title', 'Please Wait', 'Message', 'Solving GLM ... this won''t take long.', 'Indeterminate', 'on');
    GND = do_ANOVA(h,GND,stats);
else  
    pb = uiprogressdlg(h.figure, 'Title', 'Please Wait', 'Message', 'Running mass univariate statistics ... this could take a while.', 'Indeterminate', 'on');
    GND = do_MassUniv(h,GND,stats);
end

outfile = eeg_BuildPath(GND.filepath, GND.filename);
save(outfile, 'GND', '-mat');

delete(pb);
delete(h.figure);
%*************************************************************************
function callback_cancel(~,~,h)
    delete(h)

%*************************************************************************
function GND = do_ANOVA(h,GND,stats)

cond_info = h.list_model.ItemsData;

%get the saved experiment matrix
cond_matrix = h.figure.UserData';
%popluate it with more human names
cond_name_matrix = cellfun(@(x) sprintf('level %i', x), num2cell(cond_matrix), 'UniformOutput', false);
%this is the order the data was assigned to the different conditions
cond_order = cellfun(@str2num, cond_info);

%extract the data for analysis
if isstruct(stats.eegchans)  %conduct the analysis on the channel group
    ANOVAdata = [];
    n_chans = length(stats.eegchans);
    for ii = 1:n_chans
        ANOVAdata(ii,:,:,:) = mean(GND.indiv_erps(stats.eegchans(ii).chans,  stats.winstartpt:stats.winendpt,cond_order,:),1);
    end
    %these will be used as names for the channel IV
    lnames = {stats.eegchans.name};
    lnums = 1:length(stats.eegchans);
else
    n_chans = length(stats.eegchan_numbers);
    ANOVAdata = GND.indiv_erps(stats.eegchan_numbers, stats.winstartpt:stats.winendpt,cond_order,:); 
    lnames = {GND.chanlocs(stats.eegchan_numbers).labels};
    lnums = 1:length(stats.eegchan_numbers);
end

%compile the data differently depending on whether the user wants to
%analyze amplitude or latency

switch stats.measure
    case 'Amplitude'
        ANOVAdata = squeeze(mean(ANOVAdata,2)); %average over time
    case 'Positive Peak Latency'
        %get latencies and convert to time
        [~,ANOVAdata] = max(ANOVAdata,[],2);
        ANOVAdata = GND.time_pts(squeeze(ANOVAdata)+stats.winstartpt-1);      
    case 'Negative Peak Latency'
        [~,ANOVAdata] = min(ANOVAdata,[],2);
        ANOVAdata = GND.time_pts(squeeze(ANOVAdata)+stats.winstartpt-1);
    case 'Peak Plus Minus'
    case 'Peak to Peak'
        [NPeakAmp, NPeakIndx] = min(ANOVAdata,[],2);
        [PPeakAmp,PPeakIndx] = max(ANOVAdata,[],2);
        ANOVAdata = squeeze(PPeakAmp)-squeeze(NPeakAmp);
end

%reshape the data so that channels becomes a factor
n_conds = length(cond_order);
if n_chans> 1
    ANOVAdata = reshape(permute(ANOVAdata, [2,1,3]), n_chans * n_conds, size(ANOVAdata,3));
    %create a column for the channel information
    lnames = reshape(repmat(lnames', 1,n_conds)', 1, n_chans*n_conds);
    lnums = reshape(repmat(lnums', 1, n_conds)', 1, n_chans*n_conds);   
end

data_table = array2table(ANOVAdata');

stats.factors = strtrim(stats.factors);
if n_chans > 1
    stats.factors = [stats.factors, 'Channel'];
    stats.levels = [stats.levels, num2str(n_chans)];
    cond_name_matrix = repmat(cond_name_matrix, n_chans, 1);
    cond_name_matrix(:,end+1) = lnames';
    
    cond_matrix = repmat(cond_matrix, n_chans, 1);
    cond_matrix(:,end+1) = lnums';
end

%get the means and create a table as part of the output
means = mean(ANOVAdata,2);
temp = [cond_name_matrix,num2cell(means)];
mean_tble = cell2table(temp, 'VariableNames', [stats.factors, {'Mean'}]);

%create the ANOVA model
model = sprintf('Var1-Var%i~1', n_conds * n_chans);
within = cell2table(cond_name_matrix, 'VariableNames', stats.factors);
within = convertvars(within, stats.factors, 'categorical');
withinmodel = join(stats.factors, '*');
rm_model = fitrm(data_table,model,'WithinDesign',within,'WithinModel',withinmodel{1});
ANOVAresult = ranova(rm_model,'WithinModel',withinmodel{1});
%add the stats into the GND file
if ~isfield(GND, 'ANOVA')
    GND.ANOVA = [];
end
if isempty(GND.ANOVA)
    indx = 1;
else
    indx = length(GND.ANOVA) + 1;
end

%get a name for the stats test
p.msg = 'Enter a name for this test.';
p.title = 'Statistics';
p.options = {'OK'};
statsName = wwu_inputdlg(p);
if isempty(statsName.input)
    statsName = cond_name_matrix;
else
    statsName = statsName.input;
end
GND.ANOVA(indx).name = statsName;
GND.ANOVA(indx).type = stats.measure;
GND.ANOVA(indx).source_table = ANOVAresult;
GND.ANOVA(indx).data = data_table;
GND.ANOVA(indx).model = model;
GND.ANOVA(indx).withinmodel = withinmodel;
GND.ANOVA(indx).within = mean_tble;
GND.ANOVA(indx).timewindow = [GND.time_pts(stats.winstartpt), GND.time_pts(stats.winendpt)];
GND.ANOVA(indx).pntwindow = [stats.winstartpt, stats.winendpt];
GND.ANOVA(indx).chans_used = lnames;
GND.ANOVA(indx).conditions = {GND.bin_info(cond_order).bindesc};
GND.ANOVA(indx).factors  = stats.factors;
GND.ANOVA(indx).levels  = stats.levels;
GND.ANOVA(indx).level_matrix = cond_matrix;

%writetable(data_table, 'test_data.csv');
%writetable(ANOVAresult, 'test_ANOVA.csv')

%**************************************************************************
function GND = do_MassUniv(h,GND,stats)

cond_info = h.list_model.ItemsData;
cond_order = cellfun(@str2num, cond_info);

if stats.meanwindow
    winmean = 'yes';
else
    winmean = 'no';
end
if contains(stats.test, 'fdr')
    q_or_alpha = 'q';
else
    q_or_alpha = 'alpha';
end

if contains(stats.test, 'clust')
    %figure out a good neighborhood

    head_radius = sprintf('''head_radius'', %f,', GND.chanlocs(1).sph_radius * 2 * pi / 10);

    ch_hood = sprintf('''chan_hood'', %f,', GND.chanlocs(1).sph_radius/2);
else
    ch_hood = '';
    head_radius = '';
end

clevels = cellfun(@str2double, stats.levels);
factors = cellfun(@strtrim, stats.factors, 'UniformOutput', false);
factors = cellfun(@(x) replace(x,' ', '_'), factors, 'UniformOutput', false);

command_str = [stats.test, '( GND, ''bins'', cond_order, ''factor_names'', factors, ''factor_levels'', clevels,' ch_hood head_radius];
command_str = [command_str, '''time_wind'', [stats.winstart stats.winend], ''',q_or_alpha,''', stats.alpha, ''plot_raster'', ''no'','];
command_str = [command_str, '''include_chans'', stats.eegchans, ''mean_wind'', winmean, ''save_GND'', ''no'');'];

GND = eval(command_str);

%**************************************************************************
function callback_assignconditions(~, event, h)
        
switch event.Source.Tag
    case 'add'        
         %clunky way to know how many conditions there are
        total_conds = length(h.list_model.Items); 
       
        %get the data from the conditions list
        cond_sel = h.list_conditions.Value;
        for ii = 1:length(cond_sel)
            cond_sel_pos(ii) = find(h.list_conditions.ItemsData==cond_sel(ii));
        end
        n_cond_sel = length(cond_sel); %get how many are selected
        
        %figure out which conditions are selected in model
        mod_sel = h.list_model.Value;
        if mod_sel(1) ~= '['
            uialert(h.figure, 'This will overwrite previously assigned conditions. Please remove the assigned condition first.', 'Assign Condition');
            return
        end
            
        [~,indx] = ismember({mod_sel},h.list_model.ItemsData);
        
        if (total_conds - indx + 1) < n_cond_sel
            uialert(h.figure, 'There are not enough spaces left in the nodel to hold all the selected conditions.', 'Assign Condition');
            return
        end
        
        for ii = indx:n_cond_sel
            if h.list_model.ItemsData{ii}(1) ~= '['
                uialert(h.figure, 'This will overwrite previously assigned conditions. Please remove the assigned condition first.', 'Assign Condition');
                return
            end
        end
        
        %hopefully everything is OK if we got this far
        for ii = 1:n_cond_sel
            h.list_model.Items(indx+ii-1) = join(horzcat(h.list_model.ItemsData(indx+ii-1),h.list_conditions.Items(cond_sel_pos(ii))));
            h.list_model.ItemsData{indx+ii-1} = num2str(cond_sel(ii));
        end
        
        %remove from the conditions list
        h.list_conditions.Items(cond_sel_pos) = [];
        h.list_conditions.ItemsData(cond_sel_pos) = [];
        
        %automatically select the next item
        if indx+ii-1 < total_conds
            h.list_model.Value = h.list_model.ItemsData{indx+ii};
        else
            h.list_model.Value = h.list_model.ItemsData{end};
        end            
   
    %*********************************************************************
    case 'rem'
        
        total_conds = length(h.list_conditions.ItemsData);
        
        %I will use these if the user removes a condition
        all_blank_conds = h.list_model.UserData;
        
        
        model_sel = h.list_model.Value;
        [~,indx] = ismember(model_sel, h.list_model.ItemsData);
        
        %exit if the user is trying to remove a blank entry
        if model_sel(1) == '['
            return
        end
        
        %figure out where it goes in the old list
        returnPosition = str2num(model_sel);
        
        old_items = h.list_conditions.Items;
        old_itemsdata = h.list_conditions.ItemsData;
        
        %go through each existing item and assign it to the new array
        %if when we get to the return position we insert our returning
        %element
            INSERTED = false;
            new_items = {};
            for ii = 1:total_conds
                if old_itemsdata(ii) < returnPosition
                    new_items(ii) = old_items(ii);
                    new_itemsdata(ii) = old_itemsdata(ii);
                else
                    cn = h.list_model.Items{indx};
                    new_items(ii) = {strtrim(cn(strfind(cn, ']')+1:end))};
                    new_itemsdata(ii) = str2double(h.list_model.ItemsData{indx});
                    new_items(ii+1:total_conds+1) = old_items(ii:total_conds);
                    new_itemsdata(ii+1:total_conds+1) = old_itemsdata(ii:total_conds);
                    INSERTED = true;
                    break
                end
            end
            
        if ~INSERTED

            cn = h.list_model.Items{indx};
            last_item = length(new_items);
            new_items(last_item+1) = {strtrim(cn(strfind(cn, ']')+1:end))};
            new_itemsdata(last_item+1) = str2double(h.list_model.ItemsData{indx});
            
        end
        h.list_conditions.Items = new_items;
        h.list_conditions.ItemsData = new_itemsdata;
        
        %finally remove it from the model list        
        h.list_model.Items(indx) = all_blank_conds(indx);
        h.list_model.ItemsData(indx) = all_blank_conds(indx);
        
end

            
    



