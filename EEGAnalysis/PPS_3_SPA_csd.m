%% PPS -- Step 3 -- Spectral analysis %

% This program will compute the power spectral densities of EEG in 1-sec
% intervals. Power spectra are computed in sliding manner with 0.9 s overlap.
% Input data have been preprocessed using EEGLAB.

% Danielle Hewitt (created 14/08/2023, updated 04/03/2024)

close all; clear;

%=====================================================================
% Set paths for EEGLAB AND FIELDTRIP
%eeglab_path = '/Users/dhewitt/Analysis/eeglab2021.0/'; addpath(eeglab_path);
fieldtrip_path = '/Users/dhewitt/Analysis/fieldtrip-20220707/'; addpath(fieldtrip_path); ft_defaults;
d = char(datetime('today'));
% %=====================================================================
sub  = {'02', '03', '04', '05', '06', '08', '09', '10', '11', '12', '13', '14', '15', '16','17','19', '20','21','22','24','25','26','27','28','29','30'};
%sub  = {'02'};
dir  = '/Users/dhewitt/Data/pps/';
conds = {'cond-b1', 'deval-b1', 'cond-b2', 'deval-b2'}; %order of saving
cues = {'left', 'right', 'middle'};
runPSD = 0; %1 if you want to compute power spectra
newAllPSD = 0; %1 if you --only-- want to redo the AllERD export
%=====================================================================
epochStart = -2.5; epochSteps = 0.1; epochEnd   = 3.5;
baselineStart = -2.0; baselineEnd   = -1.0; %for ERD
freqStart = 1; freqEnd = 70;
%=====================================================================
% Stats exports
createStatsExports = 1;
psdexport = [];
psdexport.file = ('/Users/dhewitt/Data/pps/AllERD_withcsd_bl21_dpss_nofqbl_04-Mar-2024.mat');
psdexport.bands    = [4 7; 8 12; 16 24; 24 32];
psdexport.windows = [0 0.79; 0.8 1.79; 1.8 2.8];
%psdexport.windows = [0 0.49; 0.5 1.59; 1.6 2.8];
%psdexport.windows = [0 0.39; 0.4 0.79; 0.8 1.19; 1.2 1.59; 1.6 1.99; 2 2.39; 2.4 2.8];
%=====================================================================

if runPSD == 1

    ERDall = zeros(32,numel([freqStart:freqEnd]),numel([epochStart:epochSteps:epochEnd]),numel(conds),numel(cues));
    GERDall = zeros(32,numel([freqStart:freqEnd]),numel([epochStart:epochSteps:epochEnd]),numel(conds),numel(cues),numel(sub));

    for iSub=1:numel(sub)
        currentSubject = sub{iSub};

        wname = [fullfile(dir, ['P', currentSubject, '/P', currentSubject, '_allepoched_cleaned_2702.set'])];
        subOutname = [fullfile(dir, ['P', currentSubject, '/P', currentSubject, '_allspa_cues_2802_withcsd_bl21_dpss_nofqbl.mat'])];

        % Check if the file exists
        if exist(wname) == 0
            disp(['File : ' wname  ' does not exist']);
            return;
        end

        %=====================================================================
        % Loading data and events into FT

        % eEEG = pop_loadset(wname);
        % FTdata = eeglab2fieldtrip(eEEG,'preprocessing','none'); %This function converts EEGLAB datasets to Fieldtrip

        cfg.layout = '/Users/dhewitt/Analysis/PPS/chanlocs32.sfp'; %this file must be in the working directory
        EGIlay  = ft_prepare_layout(cfg); %ft_prepare_layout loads or creates a 2-D layout of the channel locations. This

        %==========================================================================
        eEEG = pop_loadset(wname);
        %==========================================================================

        FTdata = eeglab2fieldtrip(eEEG,'preprocessing'); %This function converts EEGLAB datasets to Fieldtrip for source localization

        cfg = []; %create empty matrix
        cfg.method       = 'spline'; %The 'hjorth' method implements B. Hjort; An on-line transformation of EEG scalp potentials into orthogonal source derivation. Electroencephalography and Clinical Neurophysiology 39:526-530, 1975.
        cfg.trials       = 'all'; %'all' or a selection given as a 1xN vector (default = 'all')
        cfg.conductivity = 0.33;
        cfg.lambda = 1e-5;
        cfg.degree = 9;
        cfg.feedback = 'gui';

        [FTdata] = ft_scalpcurrentdensity(cfg, FTdata); %ft_scalpcurrentdensity computes an estimate of the SCD using the second-order derivative (the surface Laplacian) of the EEG potential distribution

        %=====================================================================
        % Running time-frequency analyses on epoched data

        % cfg = []; %create empty matrix
        % cfg.trials       = 'all';

        cfg = [];
        cfg.output         = 'pow';
        cfg.channel        = 'EEG';
        cfg.method         = 'mtmconvol';
        cfg.taper          = 'dpss'; %one windowed taper
        cfg.keeptrials     = 'yes'; %do not average over trials here
        cfg.pad            = 'nextpow2';
        cfg.foi            = [freqStart:1:freqEnd]; %frequencies of interest
        cfg.t_ftimwin      = ones(length(cfg.foi),1).*1;
        cfg.tapsmofrq      = ones(length(cfg.foi),1).*2;
        cfg.toi            = [epochStart:epochSteps:epochEnd]; %time window of interest
        freq            = ft_freqanalysis(cfg, FTdata);
        freq.powspctrm(~isfinite(freq.powspctrm))=0; %getting rid of NaNs

        %=====================================================================
        % Now getting trials for each cond

        for iCond=1:numel(conds)
            for iCue = 1:numel(cues)
                currentCue = cues{iCue};

                T = [];
                for k=1:size(eEEG.event,2)
                    if strcmp([num2str(currentCue) num2str(iCond)],eEEG.event(k).type)  ==1
                        T = [T eEEG.event(k).epoch];
                    end
                end

                TFR=freq; % where TFR is struct inc. powspctrm, size trials x chan x freq x time
                TFR.powspctrm = TFR.powspctrm(T,:,:,:); % get the trials for this condition
                TFR.cumtapcnt = TFR.cumtapcnt(T,:);

                % % % % % % % % % Now doing ERD on the selected trials for each cond % % % % % % % % %
                % Not actually using this FT version of the BL correction as it
                % doesn't do the ERD formula properly - leaving in for later.

                cfg                = [];
                cfg.baseline 	   = [baselineStart baselineEnd];
                cfg.baselinetype   = 'relchange';  %was no, which means no standardisation at this stage - we want to see absolute power values first, ERD can be computed anytime later
                TFR.dimord         = 'chan_freq_time';
                TFR.powspctrm      = squeeze(mean(TFR.powspctrm,1)); %% this bit is averaging over all trials in each condition
                TFR.cumtapcnt      = squeeze(TFR.cumtapcnt(1,:));
                %TFRrbl             = ft_freqbaseline(cfg,TFR); %when baseline = no, this was commented out too
                %TFRrbl.powspctrm   = TFRrbl.powspctrm*100; %storing absolute values of power (averaged across trials) and compute ERD separately
                % Pall(:,:,:,iCond,iCue) = TFRrbl.powspctrm; %append the data to a matrix of channels x freqs x timepoints x conds
                %GPall(:,:,:,iCond,iCue,iSub) = TFRrbl.powspctrm; %append the data to a matrix of channels x freqs x timepoints x conds x participants

                %=====================================================================

                %getting the time bins correcsponding to the resting interval
                bt1 = nearest(TFR.time,baselineStart); bt2 = nearest(TFR.time,baselineEnd);
                RestVals = mean(TFR.powspctrm(:,:,bt1:bt2),3);

                %computing ERD now with 100*(a-r)/r formula
                erd = zeros(32,numel(freqStart:freqEnd),numel(epochStart:epochSteps:epochEnd));
                for els=1:32
                    for freqs=1:size(TFR.powspctrm,2)
                        for tms = 1:size(TFR.powspctrm,3)
                            erd(els,freqs,tms) = 100*((TFR.powspctrm(els,freqs,tms)-RestVals(els,freqs))./RestVals(els,freqs)); %this is the Pfu's formula 100*(A-R)/R
                        end
                    end
                end

                ERDall(:,:,:,iCond,iCue) = erd;
                GERDall(:,:,:,iCond,iCue,iSub) = erd; %append the data to a matrix of channels x freqs x timepoints x conds x participants

            end
        end

        % save(subOutname,'Pall'); %saving per subject - non-ERD
        save(subOutname,'ERDall'); %saving per subject - ERD
        PPSfreq= TFR.freq;
        save(subOutname,'PPSfreq','-Append');
        PPStime= TFR.time;
        save(subOutname,'PPStime','-Append');

    end

    %=====================================================================

    %allSubOutname = [fullfile(dir, ['AllSPA_' d '.mat'])];
    %save(allSubOutname,'GPall'); %saving for all subjects

    allSubOutname = [fullfile(dir, ['AllERD_withcsd_bl21_dpss_nofqbl_' d '.mat'])];
    save(allSubOutname,'GERDall'); %saving for all subjects
    PPSfreq= TFR.freq;
    save(allSubOutname,'PPSfreq','-Append');
    PPStime= TFR.time;
    save(allSubOutname,'PPStime','-Append');

    %=====================================================================

end

%% Incase you want to make a new AllERD file but not run the PSD again for all subs

if newAllPSD == 1

    GERDall = zeros(32,numel([freqStart:freqEnd]),numel([epochStart:epochSteps:epochEnd]),numel(conds),numel(cues),numel(sub));

    for iSub=1:numel(sub)
        currentSubject = sub{iSub};
        subOutname = [fullfile(dir, ['P', currentSubject, '/P', currentSubject, '_allspa_cues_2802_withoutcsd.mat'])];

        % Check if the file exists
        if exist(subOutname) == 0
            disp(['File : ' subOutname  ' does not exist']);
            return;
        end

        load(subOutname);
        GERDall(:,:,:,:,:,iSub) = ERDall;
    end

    allSubOutname = [fullfile(dir, ['AllERD_withoutcsd_bl205_' d '.mat'])];
    save(allSubOutname,'GERDall'); %saving for all subjects
    save(allSubOutname,'PPSfreq','-Append');
    save(allSubOutname,'PPStime','-Append');

end

%% Now the stats
if createStatsExports == 1

    if exist("GERDall") == 0
        load(psdexport.file);
    end

    bigexport = zeros([numel(sub)*32*size(psdexport.bands,1)*size(psdexport.windows,2),16]);
    c = 0;

    for freqi = 1:size(psdexport.bands,1)
        freqBand = psdexport.bands(freqi,:);

        for timei = 1:size(psdexport.windows,1)
            timeWindow = psdexport.windows(timei,:);

            t1=nearest(PPStime,timeWindow(1)); t2=nearest(PPStime,timeWindow(2));
            s1=nearest(PPSfreq,freqBand(1)); s2=nearest(PPSfreq,freqBand(2));

            v = squeeze(mean(GERDall(:,s1:s2,t1:t2,:,:,:),2));
            v=squeeze(mean(v,2));
            cond1 = squeeze(mean(v(:,1,:,:),2));
            cond2 = squeeze(mean(v(:,3,:,:),2));
            condPain1L = squeeze(mean(cond1(:,1,:),2))'; condPain1L =reshape(condPain1L,[],1);
            condPain1R = squeeze(mean(cond1(:,2,:),2))'; condPain1R =reshape(condPain1R,[],1);
            condNonPain1M = squeeze(mean(cond1(:,3,:),2))'; condNonPain1M=reshape(condNonPain1M,[],1);

            condPain2L = squeeze(mean(cond2(:,1,:),2))'; condPain2L =reshape(condPain2L,[],1);
            condPain2R = squeeze(mean(cond2(:,2,:),2))'; condPain2R =reshape(condPain2R,[],1);
            condNonPain2M = squeeze(mean(cond2(:,3,:),2))'; condNonPain2M=reshape(condNonPain2M,[],1);

            deval1 = squeeze(mean(v(:,2,:,:),2));
            deval2 = squeeze(mean(v(:,4,:,:),2));
            devalPain1L = squeeze(mean(deval1(:,1,:),2))'; devalPain1L=reshape(devalPain1L,[],1);
            devalPain1R = squeeze(mean(deval1(:,2,:),2))'; devalPain1R=reshape(devalPain1R,[],1);
            devalNonPain1M = squeeze(mean(deval1(:,3,:),2))'; devalNonPain1M=reshape(devalNonPain1M,[],1);

            devalPain2L = squeeze(mean(deval2(:,1,:),2))'; devalPain2L=reshape(devalPain2L,[],1);
            devalPain2R = squeeze(mean(deval2(:,2,:),2))'; devalPain2R=reshape(devalPain2R,[],1);
            devalNonPain2M = squeeze(mean(deval2(:,3,:),2))'; devalNonPain2M=reshape(devalNonPain2M,[],1);

            allconds = [condPain1L, condPain1R, condNonPain1M, devalPain1L, devalPain1R, devalNonPain1M, condPain2L, condPain2R, condNonPain2M, devalPain2L, devalPain2R, devalNonPain2M];

            participantIDs = str2double(sub);
            participantIDs=repmat(participantIDs,1,32)';
            elIDs = [1:32];
            elIDs=repelem(elIDs,numel(sub))';

            allconds(:,13)=participantIDs; allconds(:,14)=elIDs;
            allconds(:,15)=timei; allconds(:,16)=freqBand(1);

            bigexport(c + (1:size(allconds,1)), :) = allconds;
            c = c + size(allconds,1);  % Update the index
        end

    end

    outname = [dir 'Exports/ERD/PPSERDDataWide_noav_180324.csv'];
    writematrix(bigexport,outname);
    disp(['All results saved to ' outname])

    dataTable = array2table(bigexport, 'VariableNames', {'CondPain1L', 'CondPain1R', 'CondNeut1M', 'ExtnPain1L', 'ExtnPain1R', 'ExtnNeut1M', 'CondPain2L', 'CondPain2R', 'CondNeut2M', 'ExtnPain2L', 'ExtnPain2R', 'ExtnNeut2M', 'ID', 'ElectrodeID', 'Timebin', 'FreqBand'});
    stackedTable = stack(dataTable, 1:12, 'NewDataVariableName', 'EEGPowerChange', 'IndexVariableName', 'BlockCue');
    stackedTable.BlockCue = cellstr(stackedTable.BlockCue);
    stackedTable.Block = cellfun(@(x) x(1:4), stackedTable.BlockCue, 'UniformOutput', false);
    stackedTable.Cue = cellfun(@(x) x(5:8), stackedTable.BlockCue, 'UniformOutput', false);
    stackedTable.Rep = cellfun(@(x) x(9), stackedTable.BlockCue, 'UniformOutput', false);
    stackedTable.Side = cellfun(@(x) x(10), stackedTable.BlockCue, 'UniformOutput', false);
    stackedTable(:, 'BlockCue') = [];

    outname = [dir 'Exports/ERD/PPSERDDataLong_noav_180324.csv'];
    writetable(stackedTable,outname);
    disp(['All results saved to ' outname])

    %%% and the non-averaged one

    bigexport = zeros([numel(sub)*32*size(psdexport.bands,1)*size(psdexport.windows,2),8]);
    c = 0;

    for freqi = 1:size(psdexport.bands,1)
        freqBand = psdexport.bands(freqi,:);

        for timei = 1:size(psdexport.windows,1)
            timeWindow = psdexport.windows(timei,:);

            t1=nearest(PPStime,timeWindow(1)); t2=nearest(PPStime,timeWindow(2));
            s1=nearest(PPSfreq,freqBand(1)); s2=nearest(PPSfreq,freqBand(2));

            v = squeeze(mean(GERDall(:,s1:s2,t1:t2,:,:,:),2));
            v=squeeze(mean(v,2));
            cond = squeeze(mean(v(:,[1,3],:,:),2));
            condPain = squeeze(mean(cond(:,[1,2],:),2))'; condPain =reshape(condPain,[],1);
            condNonPain = squeeze(mean(cond(:,3,:),2))'; condNonPain=reshape(condNonPain,[],1);

            deval = squeeze(mean(v(:,[2,4],:,:),2));
            devalPain = squeeze(mean(deval(:,[1,2],:),2))'; devalPain=reshape(devalPain,[],1);
            devalNonPain = squeeze(mean(deval(:,3,:),2))'; devalNonPain=reshape(devalNonPain,[],1);
            allconds = [condPain,condNonPain,devalPain,devalNonPain];

            participantIDs = str2double(sub);
            participantIDs=repmat(participantIDs,1,32)';
            elIDs = [1:32];
            elIDs=repelem(elIDs,numel(sub))';

            allconds(:,5)=participantIDs; allconds(:,6)=elIDs;
            allconds(:,7)=timei; allconds(:,8)=freqBand(1);

            bigexport(c + (1:size(allconds,1)), :) = allconds;
            c = c + size(allconds,1);  % Update the index
        end

    end

    outname = [dir 'Exports/ERD/PPSERDDataWide_180324.csv'];
    writematrix(bigexport,outname);
    disp(['Averaged results saved to ' outname])

    dataTable = array2table(bigexport, 'VariableNames', {'CondPain', 'CondNeut', 'ExtnPain', 'ExtnNeut', 'SubjectID', 'ElectrodeID', 'Timebin', 'FreqBand'});
    stackedTable = stack(dataTable, 1:4, 'NewDataVariableName', 'EEGPowerChange', 'IndexVariableName', 'BlockCue');
    stackedTable.BlockCue = cellstr(stackedTable.BlockCue);
    stackedTable.Block = cellfun(@(x) x(1:4), stackedTable.BlockCue, 'UniformOutput', false);
    stackedTable.Cue = cellfun(@(x) x(5:end), stackedTable.BlockCue, 'UniformOutput', false);
    stackedTable(:, 'BlockCue') = [];

    outname = [dir 'Exports/ERD/PPSERDDataLong_180324.csv'];
    writetable(stackedTable,outname);
    disp(['Averaged results saved to ' outname])


end











