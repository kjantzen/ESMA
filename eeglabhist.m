% EEGLAB history file generated on the 12-May-2022
% ------------------------------------------------

EEG.etc.eeglabvers = '2022.0'; % this tracks which version of EEGLAB is being used, you may ignore it
EEG = pop_biosig('/Users/jantzek/Downloads/108.bdf', 'ref',46,'importannot','off');
EEG = eeg_checkset( EEG );
EEG = pop_reref( EEG, []);
EEG = eeg_checkset( EEG );
EEG=pop_chanedit(EEG, 'lookup','/Applications/Matlab toolboxes/eeglab2022.0/plugins/dipfit/standard_BEM/elec/standard_1005.elc');
EEG = eeg_checkset( EEG );
EEG = eeg_checkset( EEG );
EEG = pop_epoch( EEG, {  '128'  '256'  '384'  '512'  '640'  '768'  }, [-1  2], 'newname', 'BDF file epochs', 'epochinfo', 'yes');
EEG = eeg_checkset( EEG );
EEG = pop_rmbase( EEG, [-500 0] ,[]);
EEG = eeg_checkset( EEG );
EEG = eeg_checkset( EEG );
figure; pop_newtimef( EEG, 1, 30, [-1000  1998], [3         0.8] , 'topovec', 30, 'elocs', EEG.chanlocs, 'chaninfo', EEG.chaninfo, 'caption', 'POz', 'baseline',[-500 0], 'freqs', [[5,100]], 'plotphase', 'off', 'padratio', 1);
figure; pop_newtimef( EEG, 1, 30, [-1000  1998], [3         0.8] , 'topovec', 30, 'elocs', EEG.chanlocs, 'chaninfo', EEG.chaninfo, 'caption', 'POz', 'baseline',[0], 'freqs', [[5,100]], 'plotphase', 'off', 'padratio', 1);
figure; pop_newtimef( EEG, 1, 30, [-1000  1998], [3         0.8] , 'topovec', 30, 'elocs', EEG.chanlocs, 'chaninfo', EEG.chaninfo, 'caption', 'POz', 'baseline',[0],'winsize', 512, 'freqs', [[5,100]], 'plotphase', 'off', 'padratio', 1);
figure; pop_newtimef( EEG, 1, 30, [-1000  1998], [3         0.8] , 'topovec', 30, 'elocs', EEG.chanlocs, 'chaninfo', EEG.chaninfo, 'caption', 'POz', 'baseline',[0],'winsize', 256, 'freqs', [10, 100], 'plotphase', 'off', 'padratio', 1);
figure; pop_newtimef( EEG, 1, 30, [-1000  1998], [0] , 'topovec', 30, 'elocs', EEG.chanlocs, 'chaninfo', EEG.chaninfo, 'caption', 'POz', 'baseline',[0],'winsize', 512, 'freqs', [[5,100]], 'plotphase', 'off', 'padratio', 1);
figure; pop_newtimef( EEG, 1, 30, [-1000  1998], [0] , 'topovec', 30, 'elocs', EEG.chanlocs, 'chaninfo', EEG.chaninfo, 'caption', 'POz', 'baseline',[0],'winsize', 256, 'freqs', [[10,100]], 'plotphase', 'off', 'padratio', 1);
figure; pop_newtimef( EEG, 1, 30, [-1000  1998], [3         0.8] , 'topovec', 30, 'elocs', EEG.chanlocs, 'chaninfo', EEG.chaninfo, 'caption', 'POz', 'baseline',[-500 0], 'freqs', [[5,100]], 'plotphase', 'off', 'padratio', 1);
