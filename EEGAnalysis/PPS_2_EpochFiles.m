%% PPS -- Step 2 -- Epoching %

% This loads each subjects' data for each condition, recodes the event
% markers, does some preprocessing, and saves a merged file of all
% conditions. Next, a file is prepared for ICA, which allows the ICA to run
% faster. The ICA weights file is saved, and then added to the original
% merged file. Data is epoched around left, right and middle cues. After
% this, data should be opened in EEGLAB for ICA eyeblink removal and
% artifact rejection.

% Danielle Hewitt (29/02/24)

%% Set paths for EEGLAB
eeglab_path = '/Users/dhewitt/Analysis/PPS/eeglab2023.1/';
addpath(eeglab_path);

%==========================================================================

%Specify subjects and main directory where data is stored
cfg = [];
cfg.dir     = '/Users/dhewitt/Data/pps/';
cfg.sub = {'30'};
%cfg.sub = {'11'};
%cfg.sub = {'02', '03', '04', '05', '06','08', '09', '10', '11', '12', '13', '14', '15', '16','17','19', '20','21','22','24','25','26','27','28','29','30'};
cfg.cond   = {'cond-b1-backuP', 'cond-b2-backuP', 'cond-b3-backuP', 'cond-b4-backuP'};
cfg.epoch = [-2.5 3.5];

%==========================================================================

%% Loading the data for all subjects
%
for iSub = 1:size(cfg.sub,2)
    currentSubject = cfg.sub{iSub};
    currentDirectory = [cfg.dir 'P' currentSubject '/backuP/'];

    for iCond = 1:4 %loop to run all conditions
        currentCond = cfg.cond{iCond};

        file2load = dir(fullfile(currentDirectory, char(['*' currentCond '.set'])));
        wname = [currentDirectory file2load.name];

        if exist(wname) == 0
            disp(['File ' wname ' does not exist']);
            return;
        end

        eeglab redraw;
        EEG = pop_loadset(wname);
        EEG = eeg_checkset( EEG );


        %% Recoding Event Triggers

        for i = 1:length(EEG.event)
            if strcmp(EEG.event(i).type, 'S  7')
                EEG.event(i).type = ['left' num2str(iCond)];
            elseif strcmp(EEG.event(i).type, 'S  8')
                EEG.event(i).type = ['right' num2str(iCond)];
            elseif strcmp(EEG.event(i).type, 'S  9')
                EEG.event(i).type = ['middle' num2str(iCond)];
            elseif strcmp(EEG.event(i).type, 'S 10')
                EEG.event(i).type = ['objAppear' num2str(iCond)];
            elseif strcmp(EEG.event(i).type, 'S 11')
                EEG.event(i).type = ['objDisappear' num2str(iCond)];
            elseif strcmp(EEG.event(i).type, 'S 17')
                EEG.event(i).type = ['etFixation' num2str(iCond)]; %eye tracking fixation
            elseif strcmp(EEG.event(i).type, 'S 12') || strcmp(EEG.event(i).type, 'S 13') %pain-related cues resulting in shocks (75% of trials)
                EEG.event(i).type = ['PCollShock' num2str(iCond)];
            elseif strcmp(EEG.event(i).type, 'S 18') || strcmp(EEG.event(i).type, 'S 19') %pain-related cues not resulting in shocks due to rand (25% of trials)
                EEG.event(i).type = ['PCollNoShock' num2str(iCond)];
            elseif strcmp(EEG.event(i).type, 'S 20') %non-pain-related cues not resulting in shocks
                EEG.event(i).type = ['nPCollNoShock' num2str(iCond)];
            end
        end


        %% Now some preprocessing
        EEG = pop_reref( EEG, []); %avref
        %EEG = pop_reref( EEG, [10 21] ); %linked mastoids tp9 tp10
        EEG = eeg_checkset( EEG );
        EEG = pop_eegfiltnew(EEG, 'locutoff',1,'hicutoff',70);
        EEG = eeg_checkset( EEG );
        % EEG = pop_cleanline(EEG, 'bandwidth',2,'chanlist',[1:32] ,'computepower',1,'linefreqs',50,'newversion',0,'normSpectrum',0,'p',0.01,'pad',2,'plotfigures',0,'scanforlines',0,'sigtype','Channels','taperbandwidth',2,'tau',100,'verb',1,'winsize',4,'winstep',1);
        % EEG = eeg_checkset( EEG );
        EEG=pop_chanedit(EEG, 'load',{'/Users/dhewitt/Analysis/PPS/chanlocs32.sfp','filetype','autodetect'});
        EEG = eeg_checkset( EEG );
        eval(['EEG' num2str(iCond) ' = EEG;']);

    end


    %==========================================================================

    % Concatenate condition files
    MEEG = pop_mergeset(EEG1,EEG2,'keepall');
    MEEG = pop_mergeset(MEEG,EEG3,'keepall');
    MEEG = pop_mergeset(MEEG,EEG4,'keepall'); MEEG = eeg_checkset( MEEG );

    pop_saveset(MEEG,'filename',['P' currentSubject '_allpreproc.set'],'filepath',currentDirectory); %saving the preproc file for later

    % eeglab redraw;

    %% Now running ICA, starting by preparing a streamlined datafile
    % MEEG = pop_eegfiltnew(MEEG, 'locutoff',1,'hicutoff',30); MEEG = eeg_checkset( MEEG ); %filter 1-30 hz
    % 
    % MEEG = pop_runica(MEEG,'runica');
    % 
    % pop_topoplot(MEEG, 0, [1:32] ,'Merged datasets',[6 6] ,0,'electrodes','on');
    % 
    % %saving ICA maps for future reference
    % savename = [cfg.dir 'Figures/P' currentSubject '_ICAMaps.png'];
    % saveas(gcf,savename);
    % 
    % pop_expica(MEEG, 'weights', [currentDirectory 'P' currentSubject '_combinedICAmatrix']);
    % %==========================================================================

    %% Next, the epoching around pain-related (left, right) and non-pain-related (middle) cues for each condition (1:4)

    % Looping over all subjects

    %for iCond = 1:4 %loop to run all conditions
    %   currentCond = cfg.cond{iCond};

    file2load = dir(fullfile(currentDirectory, char(['*' '_allpreproc.set'])));
    wname = [currentDirectory file2load.name];

    if exist(wname) == 0
        disp(['File ' wname ' does not exist']);
        return;
    end

    [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);
    eeglab redraw;
    EEG = pop_loadset(wname);
    EEG = eeg_checkset( EEG );

    %epoching
    EEG = pop_editset(EEG, 'run', [], 'icaweights', [currentDirectory 'P' currentSubject '_combinedICAmatrix'], 'icasphere', []);
    EEG = eeg_checkset( EEG );
    EEG = pop_epoch( EEG, {  'left1' 'left2' 'left3' 'left4' 'right1' 'right2' 'right3' 'right4' 'middle1' 'middle2' 'middle3' 'middle4'}, cfg.epoch, 'newname', 'Epoched data', 'epochinfo', 'yes');

    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET, 'setname', 'Continuous EEG Data epochs');
    eeglab redraw;
    EEG = pop_eegfiltnew(EEG, 'locutoff',48,'hicutoff',52,'revfilt',1);
    EEG = eeg_checkset( EEG );
    EEG = pop_reref( EEG, []);
    EEG = eeg_checkset( EEG );
    pop_saveset(EEG,'filename',['P' currentSubject '_allepoched_2702.set'],'filepath',currentDirectory); %saving the file ready for ICA rejection and artifact rejection

    % end

end

disp(['Subject T' currentSubject ' epoched, merged file saved after some preprocessing'])


