%% PPS -- Step 3 -- Spectral analysis %

% This program will compute the power spectral densities of EEG in 1-sec
% intervals. Power spectra are computed in sliding manner with 0.9 s overlap.
% Input data have been preprocessed using EEGLAB.

% Danielle Hewitt (created 14/08/2023, updated 15/08/23)

close all; clear;

%=====================================================================
% Set paths for EEGLAB AND FIELDTRIP
eeglab_path = '/Users/dhewitt/Analysis/eeglab2021.0/'; addpath(eeglab_path);
fieldtrip_path = '/Users/dhewitt/Analysis/fieldtrip-20220707/'; addpath(fieldtrip_path); ft_defaults;
d = char(datetime('today'));
% %=====================================================================

% Input: a set file which needs to be changed in cfg.name

sub  = {'02', '03', '04', '05', '06','08', '09', '10', '11', '12', '13', '14', '15', '16','17','19', '20','21','22','24','25','26','27','28','29','30'};
%sub  = {'02','03'};
dir  = '/Users/dhewitt/Data/pps/';
conds = {'cond-b1', 'deval-b1', 'cond-b2', 'deval-b2'}; %order of saving
cues = {'left', 'right', 'middle'};

%=====================================================================
epochStart = -2.5; epochSteps = 0.1; epochEnd   = 2.5;
baselineStart = -2.0; baselineEnd   = -1.0; %for ERD
freqStart = 1; freqEnd = 70;
%=====================================================================

%Pall = zeros(32,numel([freqStart:freqEnd]),numel([epochStart:epochSteps:epochEnd]),numel(conds),numel(cues));
%GPall = zeros(32,numel([freqStart:freqEnd]),numel([epochStart:epochSteps:epochEnd]),numel(conds),numel(cues),numel(sub));

%erd = zeros(32,numel([freqStart:freqEnd]),numel([epochStart:epochSteps:epochEnd]));
ERDall = zeros(32,numel([freqStart:freqEnd]),numel([epochStart:epochSteps:epochEnd]),numel(conds),numel(cues));

for iSub=1:numel(sub)
    currentSubject = sub{iSub};

    wname = [fullfile(dir, ['P', currentSubject, '/P', currentSubject, '_allepoched_cleaned0910.set'])];
    subOutname = [fullfile(dir, ['P', currentSubject, '/P', currentSubject, '_allspa_cues0910.mat'])];

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

    %     cfg = []; %create empty matrix
    %     cfg.trials       = 'all';

    cfg = [];
    cfg.output         = 'pow';
    cfg.channel        = 'EEG';
    cfg.method         = 'mtmconvol';
    cfg.taper          = 'hanning'; %one windowed taper
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

            TFR=freq; % where TFR is struct inc. powspctrm, size cond x chan x freq x time
            TFR.powspctrm = TFR.powspctrm(T,:,:,:); % get the trials for this condition
            TFR.cumtapcnt = TFR.cumtapcnt(T,:);

            % % % % % % % % % Now doing ERD on the selected trials for each cond % % % % % % % % %
            % Not actually using this FT version of the BL correction as it
            % doesn't do the ERD formula properly - leaving in for later.

            cfg                = [];
            cfg.baseline 	   = [baselineStart baselineEnd];
            cfg.baselinetype   = 'relchange';  %was no, which means no standardisation at this stage - we want to see absolute power values first, ERD can be computed anytime later
            TFR.dimord         = 'chan_freq_time';
            TFR.powspctrm      = squeeze(mean(TFR.powspctrm,1));
            TFR.cumtapcnt      = squeeze(TFR.cumtapcnt(1,:));
            TFRrbl             = ft_freqbaseline(cfg,TFR); %when baseline = no, this was commented out too
            %TFRrbl.powspctrm   = TFRrbl.powspctrm*100; %storing absolute values of power (averaged across trials) and compute ERD separately
            % Pall(:,:,:,iCond,iCue) = TFRrbl.powspctrm; %append the data to a matrix of channels x freqs x timepoints x conds
            %GPall(:,:,:,iCond,iCue,iSub) = TFRrbl.powspctrm; %append the data to a matrix of channels x freqs x timepoints x conds x participants


            %=====================================================================

            %getting the time bins correcsponding to the resting interval
            bt1 = nearest(TFR.time,baselineStart); bt2 = nearest(TFR.time,baselineEnd);
            RestVals = mean(TFR.powspctrm(:,:,bt1:bt2),3);

            %computing ERD now with 100*(a-r)/r formula
            erd = zeros(32,numel([freqStart:freqEnd]),numel([epochStart:epochSteps:epochEnd]));
            for els=1:32
                for freqs=1:size(TFR.powspctrm,2)
                    for tms = 1:size(TFR.powspctrm,3)
                        erd(els,freqs,tms) = 100*(TFR.powspctrm(els,freqs,tms)-RestVals(els,freqs))./RestVals(els,freqs); %this is the Pfu's formula 100*(A-R)/R
                    end
                end
            end

            ERDall(:,:,:,iCond,iCue) = erd;
            GERDall(:,:,:,iCond,iCue,iSub) = erd; %append the data to a matrix of channels x freqs x timepoints x conds x participants

        end
    end

    % save(subOutname,'Pall'); %saving per subject - non-ERD
    save(subOutname,'ERDall'); %saving per subject - ERD

end

%=====================================================================

%allSubOutname = [fullfile(dir, ['AllSPA_' d '.mat'])];
%save(allSubOutname,'GPall'); %saving for all subjects

allSubOutname = [fullfile(dir, ['AllERD_csd_' d '.mat'])];
save(allSubOutname,'GERDall'); %saving for all subjects

%=====================================================================


