
%% PPS -- Step 5 -- Exporting single trial data in trial order for each participant

% This combines the event files for each participant with the power spectral densities of EEG
% on a single trial basis. The output is a csv file for each participant containing the trial
% structure, and columns with the band power in each of the selected frequency bands, time
% windows, and electrode combinations.
% Input data have been preprocessed using EEGLAB and FieldTrip.

% Danielle Hewitt (created 10/04/2024) -- needs checking before final
% version

eeglab_path = '/Users/dhewitt/Analysis/eeglab2023.1/'; addpath(eeglab_path);
fieldtrip_path = '/Users/dhewitt/Analysis/fieldtrip-20240110/'; addpath(fieldtrip_path); ft_defaults;

dir  = '/Users/dhewitt/Data/pps/';
%sub  = {'02', '03', '04', '05', '06', '08', '09', '10', '11', '12', '13', '14', '15', '16','17','19', '20','21','22','24','25','26','27','28','29','30'};
%sub  = {'02', '03', '04', '05', '06', '08', '09', '10', '11', '12', '13', '14', '15', '16','17','19', '20','21','22','24','25','26','27','28','29','30'};
sub = {'02'};

psdexport.bands    = [4 7; 8 12; 16 24]; %theta, alpha, and beta, respectively
psdexport.windows = [0 0.79; 0.8 1.79; 1.8 2.8]; %cue period, early anticipation, late anticipation
psdexport.electrodes = {[1 2 32], [6 7 8 24 25 28 29], [11 12 13 14 15 19 20 22 23]}; %frontal electrodes, central electrodes, parietal electrodes

for iSub = 1:numel(sub)
    currentSubject = sub{iSub};

    participantERDfile = [fullfile(dir, ['P', currentSubject, '/P', currentSubject, '_allspa_cues_2802_withcsd_bl21_dpss_st_nofqbl.mat'])];
    evtFile = [fullfile(dir, ['/Modelling/P', currentSubject,  '_newEVT.csv'])];
    outname = [fullfile(dir, ['/Modelling/P', currentSubject,  '_datEVT.csv'])];

    load(participantERDfile, 'ERDall');
    load([fullfile(dir, 'PPStimefreq.mat')]); % also import csv with event file
    eventFile = readtable(evtFile); datEVT = eventFile;

    for freqi = 1:size(psdexport.bands,1)
        for timei = 1:size(psdexport.windows,1)

            freqBand = psdexport.bands(freqi,:);
            timeWindow = psdexport.windows(timei,:);

            t1=nearest(PPStime,timeWindow(1)); t2=nearest(PPStime,timeWindow(2));
            s1=nearest(PPSfreq,freqBand(1)); s2=nearest(PPSfreq,freqBand(2));

            for el = 1:numel(psdexport.electrodes)
                electrodes = psdexport.electrodes{el};

                v = squeeze(mean(ERDall(electrodes,s1:s2,t1:t2,:,:,:),2));
                v=squeeze(mean(v,2)); v=squeeze(mean(v,1));

                %% This is all a bit janky but it seems to work ok - checking needed

                numTrials = find(eventFile.Block == 1 & eventFile.Include == 1); totalb1 = length(numTrials);
                numTrials = find(eventFile.Block == 2 & eventFile.Include == 1); totalb2 = length(numTrials);
                numTrials = find(eventFile.Block == 3 & eventFile.Include == 1); totalb3 = length(numTrials);
                numTrials = find(eventFile.Block == 4 & eventFile.Include == 1); totalb4 = length(numTrials);

                cond1 = squeeze(v(1,:,1:totalb1));
                deval1 = squeeze(v(2,:,totalb1+1:totalb1+totalb2));
                cond2 = squeeze(v(3,:,totalb1+totalb2+1:totalb1+totalb2+totalb3));
                deval2 = squeeze(v(4,:,totalb1+totalb2+totalb3+1:totalb1+totalb2+totalb3+totalb4));

                inds = find(cond1(1,:)); cond1L = cond1(1,inds)';
                inds = find(cond1(2,:)); cond1R = cond1(2,inds)';
                inds = find(cond1(3,:)); cond1M = cond1(3,inds)';

                inds = find(deval1(1,:)); deval1L = deval1(1,inds)';
                inds = find(deval1(2,:)); deval1R = deval1(2,inds)';
                inds = find(deval1(3,:)); deval1M = deval1(3,inds)';

                inds = find(cond2(1,:)); cond2L = cond2(1,inds)';
                inds = find(cond2(2,:)); cond2R = cond2(2,inds)';
                inds = find(cond2(3,:)); cond2M = cond2(3,inds)';

                inds = find(deval2(1,:)); deval2L = deval2(1,inds)';
                inds = find(deval2(2,:)); deval2R = deval2(2,inds)';
                inds = find(deval2(3,:)); deval2M = deval2(3,inds)';

                %% Adding all to the eventFile

                newcols = zeros(length(eventFile.type),1);

                middle = find(strcmp(eventFile.type, 'middle') & eventFile.Include == 1);
                newcols(middle,1) = [cond1M;deval1M;cond2M;deval2M];

                left = find(strcmp(eventFile.type, 'left') & eventFile.Include == 1);
                newcols(left,1) = [cond1L;deval1L;cond2L;deval2L];

                right = find(strcmp(eventFile.type, 'right') & eventFile.Include == 1);
                newcols(right,1) = [cond1R;deval1R;cond2R;deval2R];

                colname = ['Freq_f' num2str(freqi) '_t' num2str(timei) '_el' num2str(el)];
                datEVT.(colname) = newcols;

            end

        end
    end
    
%% Saving

    writetable(datEVT,outname);
    disp(['Data EVT saved to ' outname])

end
