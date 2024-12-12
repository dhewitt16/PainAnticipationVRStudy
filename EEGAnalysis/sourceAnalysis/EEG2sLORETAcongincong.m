
%% This code loads preprocessed subject datafiles, which have been merged
% into one file. Files are split into each condition of interest, with the
% option of saving the respective files as new .set files for each
% condition for later processing. For each condition, files are exported
% with one file for each trial within each condition - stored in relevant
% individual folders per participant per condition - in binary .ascii
% format for processing in LORETA.

% Danielle Hewitt, 12/12/2024
% Adapted from epns_rest.m, Andrej Stancak, 2019

% EEGLAB and Fieldtrip must be in the path and preloaded (for EEGLAB).

%=====================================================================
% Set paths for EEGLAB AND FIELDTRIP
% eeglab_path = '/Users/dhewitt/Analysis/eeglab2023.1/'; addpath(eeglab_path); eeglab;
% fieldtrip_path = '/Users/dhewitt/Analysis/fieldtrip-20240110/'; addpath(fieldtrip_path); ft_defaults;

% %=====================================================================
%sub  = {'02', '03', '04', '05', '06', '08', '09', '10', '11', '12', '13', '14', '15', '16','17','19', '20','21','22','24','25','26','27','28','29','30'};
sub  = {'02', '04', '05', '06', '08', '09', '10', '11', '12', '13', '14', '15', '16','17','19','21','22','24','25','26','27','28','29','30'};
%sub  = {'05'};
dir  = '/Users/dhewitt/Data/pps/';
conds = {'cond-b1', 'deval-b1', 'cond-b2', 'deval-b2'}; %order of saving
cues = {'left', 'right', 'middle'};
%=====================================================================
epochStart = -2.5; epochSteps = 0.1; epochEnd   = 3.5;
baselineStart = -2.0; baselineEnd   = -1.0; %for ERD

for iSub=1:numel(sub)
    currentSubject = sub{iSub};

    subDir = [dir 'P', currentSubject '/'];

    wname = [fullfile(dir, ['P', currentSubject, '/P', currentSubject, '_allepoched_cleaned_2702.set'])];
    subOutname = [fullfile(dir, ['P', currentSubject, '/P', currentSubject, '_allspa_cues_2802_withcsd_bl21_dpss_st_nofqbl.mat'])];

    % Check if the file exists
    if exist(wname) == 0
        disp(['File : ' wname  ' does not exist']);
        return;
    end

    %=====================================================================
    % Loading data and events into FT

    cfg.layout = '/Users/dhewitt/Analysis/PPS/chanlocs32.sfp'; %this file must be in the working directory
    % EGIlay  = ft_prepare_layout(cfg); %ft_prepare_layout loads or creates a 2-D layout of the channel locations.
    load([dir 'tonicpainsides.mat']);

    subjectIndex = find(tonicpainsides(:,1) == str2double(currentSubject));
    if isempty(subjectIndex)
        error(['Subject ID ', currentSubject, ' not found in tonicpainsides.']);
    end

    %==========================================================================
    eEEG = pop_loadset(wname);
    %==========================================================================

    for iCond=1:numel(conds)
        for iCue = 1:numel(cues)
            currentCue = cues{iCue};

            % Handle 'middle' cue
            if strcmp(currentCue, 'middle')
                loretaDir = [dir 'slor/' 'neutral/' num2str(currentSubject) '/'];
                if ~exist(loretaDir, 'dir')
                    mkdir(loretaDir);
                end
                continue;
            end

            T = [];
            for k=1:size(eEEG.event,2)
                if strcmp([num2str(currentCue) num2str(iCond)],eEEG.event(k).type)  ==1
                    T = [T eEEG.event(k).epoch];
                end
            end

            if isempty(T)
                warning(['No events found for condition ', conds{iCond}, ', cue ', currentCue]);
                continue;
            end

            % Select events
            newEEG = pop_selectevent( eEEG, 'epoch',T ,'deleteevents','off','deleteepochs','on','invertepochs','off');
            loretaData = eeglab2fieldtrip(newEEG,'preprocessing','none');
            loretaDatatrials = loretaData.trial;

            % Congruency logic

            if tonicpainsides(subjectIndex,2) == 1 && strcmp(currentCue, 'left') || ...
                    tonicpainsides(subjectIndex,2) == 2 && strcmp(currentCue, 'right')
                loretaDir = [dir 'slor/' 'congruent/' num2str(currentSubject) '/'];
            else
                loretaDir = [dir 'slor/' 'incongruent/' num2str(currentSubject) '/'];
            end

            if ~exist(loretaDir, 'dir')
                mkdir(loretaDir);
            end



            for k=1:numel(loretaDatatrials)
                tmp=loretaDatatrials{k};
                ws=num2str(k);
                if k<10
                    ws = ['00' ws];
                else
                    if k>9 & k<100
                        ws = ['0' ws];
                    end
                end

                loretaName = [loretaDir ws '.txt'];
                tmp=double(tmp);
                save(loretaName,'tmp','-ASCII');
                disp([loretaName ' saved']);

            end

        end
    end


end

