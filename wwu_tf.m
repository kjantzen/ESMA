function TFData = wwu_tf(cfg, EEG)
% tf = wwu_tf(cfg, EEG) - computes the event related spectral perturbaiton
% (time frequenct transform )on the channel x time x trial data in the
% EEG stucture.  If EEG is include ERPLAB %epoch and bin information,
% ersp will be computed on each bin group or condition separately.
% The cfg structure contains options for calculating the time frequency
% transform.
%
%INPUTS
%   cfg - a structure that contains the parameters for computing the time
%   frequency
%       cfg.remMean: removes mean erp from each trail if true.  Default: false.
%
%       cfg.defWinsize: use default window size by letting the eeglab
%       function newtimef decide the size of each time window.
%
%       cfg.winsize:  the size of the time window (samples) for each
%       individual transform.  Longer windows allow you to resolve lower
%       frequencies but result in less temporal resolution.  This is
%       ignored if defWinsize = true;
%
%       cfg.defFreq: use default frequency range defined in the eeglab
%       function newtimef.  Default: true.  The default range is from the
%       minimum frequency to 50 Hz where the minimum frequency is defined
%       by the window size and the number of wavelet cycles (if using
%       wavelets).  The minimum frequency will be approximately 1/winsize
%       * Fs * Cycles.  So for a .5 second window at  Fs = 512 adn Cycles = 3
%       the minimum frequency would be 1/256 * 512 * 3 = 6Hz.
%
%       cfg.freqs:  a 2 element vector [min, max] providing the desired
%       minimum and maximum frequencies.  Overwritten by cfg.defFreq
%
%       cfg.preStim: a boolean indicating whether to use the entire
%       prestimulus period for computing the ersp baseline. Default = true
%
%       cfg.baseline: a 2 element vector with the start and end time of the
%       baseline period in ms.  Overwritten by cfg.prestim
%
%       cfg.runtest: a boolean indicating whether to conduct a quick test
%       of the parameters by returning  the results of the ersp data in a
%       time x freq array.
%
%       cfg.testChannel - an integer index for the single channel to
%       convert and return when cfg.runtest = true. Default = 1.
%
%       cfg.testCondition - an integer index for the condition to use when
%       cfg.runtest = true.  Default = 1.
%
%       cfg.cycles - if 0 newtimef uses the fft to compute ersp.  Otherwise
%       a 2 element vector [min max] giving the minimum and maximum number
%       of wavelet cycles to apply at the lowest and highest frequencies.
%       If 0 < max < 1 then cycles increases with increasing frequency with
%       the maximum = minCycles * maxfreq / minfreq * (1-maxCycles).  Note
%       that greater cycles in the time domain reduces resolution in the
%       frequency domain. Default is  0(use FFT);
%
%       NOTE that there are many more options in newtimef that I have not
%       exposed here.  Use help newtimef to see all available options.
%
%   EEG - an eeglab or erplab structure containing the channel x time x
%   trial data.  The mean ersp will be computed across trials.
%
%   runtest - an optional boolean.  If true
% OUTPUT
%   tf - a channel x time x frequency x condition array of power values
%

if nargin < 2
    error('At least 2 inputs are required.');
end


if ~isfield(cfg, 'cycles')
    cfg.cycles = 0;
end

if ~isfield(cfg, 'testChannel') || isempty(cfg.testChannel)
    cfg.testChannel = 1;
end
if ~isfield(cfg, 'testCond') || isempty(cfg.testCond)
    cfg.testCond = 1;
end

%this is the default part of the call to newtimef
cmd = 'newtimef(';
cmd = [cmd, 'data, EEG.pnts, [EEG.xmin * 1000, EEG.xmax * 1000], EEG.srate, cfg.cycles'];

% now get any options that may ahve been passed
if isfield(cfg, 'remmean') && cfg.remMean
    cmd = [cmd, ', ''rmerp'', ''on'''];
end
if isfield(cfg, 'defWinsize') && ~cfg.defWinsize
    cmd = [cmd, ', ''winsize'', cfg.winsize'];
else
    cfg.winsize = -EEG.xmin * EEG.srate;
    cmd = [cmd, ', ''winsize'', cfg.winsize'];
    
end

if isfield(cfg, 'defFreq') && ~cfg.defFreq
    cmd = [cmd, ', ''freqs'', cfg.freqs'];

end

if isfield(cfg, 'preStim') && ~cfg.preStim
    cmd = [cmd, ', ''baseline'', cfg.baseline'];
end





allersp = [];
%get condition information
if isfield(EEG, 'bindesc') %assume we have embedded condition information
    
    %allocate matrix for storing the tf data
    %get a list of epoch numbers for each bin
    elist = getepochlist(EEG);
    nCond = length(EEG.bindesc);
    TFData.bindesc = EEG.bindesc;
else
    elist.bindesc = 'all trials';
    elist.epoch = 1:EEG.trials;
    nCond = 1;
    TFData.bindesc = 'all trials';
end

if cfg.runtest
    figure();
    cmd = [cmd, ', ''plotphasesign'', ''off'');'];
    data = squeeze(EEG.data(cfg.testChannel,:,elist(cfg.testCond).epoch));
    [ersp, itc, powbase, times, freqs, erspboot, itcboot, tfdata] = eval(cmd);
    allersp = ersp;

else
    cmd = [cmd, ', ''plotersp'', ''off'', ''plotitc'', ''off'');']; %add the no plotting commands here.
    for ii = 1:nCond
        for ch = 1:EEG.nbchan
            data = squeeze(EEG.data(ch,:,elist(ii).epoch));
            [ersp, itc, powbase, times, freqs, erspboot, itcboot, tfdata] = eval(cmd);
            if isempty(allersp)
                allersp = zeros(EEG.nbchan, size(ersp,1), size(ersp,2), nCond);
            end
            allersp(ch,:,:,ii) = ersp;

        end
    end
end

TFData.ersp = allersp;
TFData.times = times;
TFData.freqs = freqs;
TFData.ncond = nCond;
TFData.nchan = EEG.nbchan;

end
%***********************************************************************
function binlist = getepochlist(EEG)
%helper function to return the indexes for epochs belinging to a specific
%bin

for ii = 1:length(EEG.bindesc)
    binlist(ii).bindesc = EEG.bindesc{ii};
    binlist(ii).epoch = [];
end

for ii = 1:length(EEG.epoch)
    indx = find(contains(EEG.epoch(ii).eventtype, 'bin'));
    indx = indx(1);  %take only the first one if there are more
    bin = EEG.epoch(ii).eventtype{indx};
    ncond = str2double(bin(end));
    if ~isempty(binlist(ncond).epoch)
        binlist(ncond).epoch(end + 1) = ii;
    else
        binlist(ncond).epoch(1) = ii;
    end
end
end




    