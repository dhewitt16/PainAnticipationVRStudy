
%% PPS -- Step 4 -- Figures %

% This program will create figures. Input data is power spectra,
% transformed with current source density transformation.

% Danielle Hewitt (created 14/08/2023, updated 06/03/24 to remove perm)

close all; %clear all;

%=====================================================================
% Set paths for EEGLAB AND FIELDTRIP
% eeglab_path = '/Users/dhewitt/Analysis/eeglab2023.1/'; addpath(eeglab_path);
% fieldtrip_path = '/Users/dhewitt/Analysis/fieldtrip-20220707/'; addpath(fieldtrip_path); ft_defaults;

eeglab_path = '/Users/dhewitt/Analysis/eeglab2023.1/'; addpath(eeglab_path);
fieldtrip_path = '/Users/dhewitt/Analysis/fieldtrip-20240110/'; addpath(fieldtrip_path); ft_defaults;
% %=====================================================================

erdScale = [-20 20]; % scale for all maps - theta usually -30 30, alpha -20 20, beta -15 15
freq = [4 7]; % frequency band - change to 4 7 for theta, 8 12 for alpha, 16 24 for beta
topoTimeWindow = [0 2.8; 0.8 2.8]; % time windows for topographies. 1 sets topo for fig 1, 2 sets time window for figs 2+
tfTimeWindow = [-2 2.8]; % time window for time frequency plots
timewindows = [0 0.79; 0.8 1.79; 1.8 2.8];

frontal = {'Fp1', 'Fp2', 'Fz'};
central = {'FC5', 'FC1', 'FC2', 'FC6', 'C3', 'Cz', 'C4'};
parietal = {'CP5', 'CP1', 'CP2', 'CP6', 'P7', 'P3', 'Pz', 'P4', 'P8'};
occipital = {'O1','O2', 'Oz'}; %optional electrode clusters

% =================================================================

conds = {'cond-b1', 'deval-b1', 'cond-b2', 'deval-b2'}; %order of saving
cues = {'left', 'right', 'middle'};
lfirst=[3,5,9,11,13,15,17,19,21,25,27,29];
rfirst=[2,4,6,8,10,12,14,16,20,22,24,26,28,30];
allsubs=sort([3,5,9,11,13,15,17,19,21,25,27,29,2,4,6,8,10,12,14,16,20,22,24,26,28,30]);

el = frontal; %type in electrodes themselves or choose a cluster

%=====================================================================

load('/Users/dhewitt/Data/pps/AllERD_withcsd_bl21_dpss_nofqbl_04-Mar-2024.mat');
E = readlocs('/Users/dhewitt/Analysis/PPS/chanlocs32.sfp');

t1=nearest(PPStime,topoTimeWindow(1,1)); t2=nearest(PPStime,topoTimeWindow(1,2));
allt = [nearest(PPStime,tfTimeWindow(1)), nearest(PPStime,tfTimeWindow(2))];
s1=nearest(PPSfreq,freq(1)); s2=nearest(PPSfreq,freq(2));

%%%%%%%%%%%%%%%%%%%%%%%

%==========================================================================
%This section extrxts the indices of all valid electrode labels in cfg.els

EL = [];
for j=1:size(el,2)
    for k=1:32
        if strcmp(el{j},E(k).labels)==1
            EL = [EL k];
        end
    end
end

%==========================================================================

v = squeeze(mean(GERDall(:,s1:s2,t1:t2,:,:,:),2)); v=squeeze(mean(v,2)); bv=squeeze(mean(v,3));

figure('Name','Averaged topoplots in each of the 4 conditions, time locked to the cue');

cond = squeeze(mean(v(:,[1,3],:,:),2)); condPain = squeeze(mean(cond(:,[1,2],:),2)); condNonPain = squeeze(mean(cond(:,3,:),2));
allcond = (condPain+condNonPain)./2; allcond = mean(allcond,2);

deval = squeeze(mean(v(:,[2,4],:,:),2)); devalPain = squeeze(mean(deval(:,[1,2],:),2)); devalNonPain = squeeze(mean(deval(:,3,:),2));
alldeval = (devalPain+devalNonPain)./2; alldeval = mean(alldeval,2);

subplot(2,3,1); topoplot(allcond,E,'style','map','maplimits',erdScale); title('All Conditioning'); colorbar;
subplot(2,3,4); topoplot(alldeval,E,'style','map','maplimits',erdScale); title('All Extinction'); colorbar;
subplot(2,3,2); topoplot(mean(condPain,2),E,'style','map','maplimits',erdScale); colorbar; title('Conditioning Pain Cue');
subplot(2,3,3); topoplot(mean(condNonPain,2),E,'style','map','maplimits',erdScale); colorbar; title('Conditioning Neutral Cue');
subplot(2,3,5); topoplot(mean(devalPain,2),E,'style','map','maplimits',erdScale); colorbar; title('Extinction Pain Cue');
subplot(2,3,6); topoplot(mean(devalNonPain,2),E,'style','map','maplimits',erdScale); colorbar; title('Extinction Neutral Cue');


%%%%%%%%%%%%%%%%%%%%%%%

figure('Name','Averaged topoplots in pain vs neutral conditions, time locked to the cue');

allPain = (condPain+devalPain)./2; allPain = mean(allPain,2);
allNeutral = (condNonPain+devalNonPain)./2; allNeutral = mean(allNeutral,2);
subplot(1,2,1); topoplot(allPain,E,'style','map','maplimits',erdScale); title('Pain-related Cues'); colorbar;
subplot(1,2,2); topoplot(allNeutral,E,'style','map','maplimits',erdScale); title('Neutral Cues'); colorbar;

%%%%%%%%%%%%%%%%%%%%%%%

t1=nearest(PPStime,topoTimeWindow(2,1)); t2=nearest(PPStime,topoTimeWindow(2,2));

v = squeeze(mean(GERDall(:,s1:s2,t1:t2,:,:,:),2)); v=squeeze(mean(v,2)); bv=squeeze(mean(v,3));

figure('Name','Averaged topoplots in each of the 4 conditions, specified time window');

cond = squeeze(mean(v(:,[1,3],:,:),2)); condPain = squeeze(mean(cond(:,[1,2],:),2)); condNonPain = squeeze(mean(cond(:,3,:),2));
allcond = (condPain+condNonPain)./2; allcond = mean(allcond,2);

deval = squeeze(mean(v(:,[2,4],:,:),2)); devalPain = squeeze(mean(deval(:,[1,2],:),2)); devalNonPain = squeeze(mean(deval(:,3,:),2));
alldeval = (devalPain+devalNonPain)./2; alldeval = mean(alldeval,2);

subplot(2,3,1); topoplot(allcond,E,'style','map','maplimits',erdScale); title('All Conditioning'); colorbar;
subplot(2,3,4); topoplot(alldeval,E,'style','map','maplimits',erdScale); title('All Extinction'); colorbar;
subplot(2,3,2); topoplot(mean(condPain,2),E,'style','map','maplimits',erdScale); colorbar; title('Conditioning Pain Cue');
subplot(2,3,3); topoplot(mean(condNonPain,2),E,'style','map','maplimits',erdScale); colorbar; title('Conditioning Neutral Cue');
subplot(2,3,5); topoplot(mean(devalPain,2),E,'style','map','maplimits',erdScale); colorbar; title('Extinction Pain Cue');
subplot(2,3,6); topoplot(mean(devalNonPain,2),E,'style','map','maplimits',erdScale); colorbar; title('Extinction Neutral Cue');

%%%%%%%%%%%%%%%%%%%%%%%

figure('Name','TFR plots averaged over chosen electrodes');

GAPall = squeeze(mean(GERDall(EL,:,:,:,:,:),1));
conderd = squeeze(mean(squeeze(GAPall(:,:,[1,3],:,:)),5)); conderd = squeeze(mean(conderd,3));
devalerd = squeeze(mean(squeeze(GAPall(:,:,[2,4],:,:)),5)); devalerd = squeeze(mean(devalerd,3));

tfr=squeeze(mean(conderd(:,:,[1:2]),3));
subplot(2,2,1); imagesc(tfr,erdScale); ax=gca; ax.XLim = allt; ax.YLim = [1 50]; set(gca,'XLim',ax.XLim,'YLim',ax.YLim); title('Conditioning, Pain cues'); colorbar;
hold on; line([26 26], [1 50], 'Color', 'k', 'LineWidth', 1); hold on; line([34 34], [1 50], 'Color', 'k', 'LineWidth', 1); hold off; axis xy; % adds lines at cue start and end
sample_ticks = ax.XLim(1):10:ax.XLim(2); time_ticks = PPStime(sample_ticks); ax.XTick = sample_ticks; ax.XTickLabel = time_ticks; xlabel('Time (s)');
CondPain = squeeze(mean(tfr(s1:s2,:),1));

tfr=squeeze(conderd(:,:,3));
subplot(2,2,2); imagesc(tfr,erdScale); ax=gca; ax.XLim = allt; ax.YLim = [1 50]; set(gca,'XLim',ax.XLim,'YLim',ax.YLim); title('Conditioning, Neutral cues'); colorbar;
hold on; line([26 26], [1 50], 'Color', 'k', 'LineWidth', 1); hold on; line([34 34],[1 50], 'Color', 'k', 'LineWidth', 1); hold off; axis xy; ax.XTick = sample_ticks; ax.XTickLabel = time_ticks; xlabel('Time (s)');
CondNeutral = squeeze(mean(tfr(s1:s2,:),1));

tfr=squeeze(mean(devalerd(:,:,[1:2]),3));
subplot(2,2,3); imagesc(tfr,erdScale); ax=gca; ax.XLim = allt; ax.YLim = [1 50]; set(gca,'XLim',ax.XLim,'YLim',ax.YLim); title('Extinction, Pain cues'); colorbar;
hold on; line([26 26], [1 50], 'Color', 'k', 'LineWidth', 1); hold on; line([34 34], [1 50], 'Color', 'k', 'LineWidth', 1); hold off; axis xy; ax.XTick = sample_ticks; ax.XTickLabel = time_ticks; xlabel('Time (s)');
ExtnPain = squeeze(mean(tfr(s1:s2,:),1));

tfr=squeeze(devalerd(:,:,3));
subplot(2,2,4); imagesc(tfr,erdScale); ax=gca; ax.XLim = allt; ax.YLim = [1 50]; set(gca,'XLim',ax.XLim,'YLim',ax.YLim); title('Extinction, Neutral cues'); colorbar;
hold on; line([26 26], [1 50], 'Color', 'k', 'LineWidth', 1); hold on; line([34 34], [1 50], 'Color', 'k', 'LineWidth', 1); hold off;  axis xy; ax.XTick = sample_ticks; ax.XTickLabel = time_ticks; xlabel('Time (s)');
colormap(jet);
ExtnNeutral = squeeze(mean(tfr(s1:s2,:),1));

%%%%%%%%%%%%%%%%%%%%%%%

figure('Name','ERD curve in selected electrodes');
subplot(2,2,1);
plot(PPStime,CondPain,'LineWidth',2,'Color',[0.95 0.53 0.37]); hold on;
plot(PPStime,ExtnPain,'--','LineWidth',2,'Color',[0.95 0.53 0.37]); b.FaceColor = "#D95319"; hold on;
plot(PPStime,CondNeutral,'LineWidth',2,'Color',[0.27 0.63 0.51]); hold on;
plot(PPStime,ExtnNeutral,'--','LineWidth',2,'Color',[0.27 0.63 0.51]); hold on;
axis([-2 2.8 erdScale]); hold on;
line([0 0], [-50 50], 'Color', 'k', 'LineWidth', 1); hold on;
line([0.8 0.8], [-50 50], 'Color', 'k', 'LineWidth', 1); 
xlabel('Time (s)'); title('Interaction Cues x Cond'); set(gca,'fontsize', 14) ;

painCues = (CondPain+ExtnPain)./2; neutCues = (CondNeutral+ExtnNeutral)./2;

subplot(2,2,2);
plot(PPStime,painCues,'LineWidth',2,'Color',[0.95 0.53 0.37]); hold on;
plot(PPStime,neutCues,'--','LineWidth',2,'Color',[0.27 0.63 0.51]); b.FaceColor = "#D95319"; hold on;
axis([-2 2.8 erdScale]); hold on; 
line([0 0], [-50 50], 'Color', 'k', 'LineWidth', 1); hold on;
line([0.8 0.8], [-50 50], 'Color', 'k', 'LineWidth', 1); 
xlabel('Time (s)'); title('Pain vs Neutral'); set(gca,'fontsize', 14) ;legend('Pain','Neut');

allCond = (CondPain+CondNeutral)./2; allExt = (ExtnPain+ExtnNeutral)./2;

subplot(2,2,3);
plot(PPStime,allCond,'LineWidth',2,'Color',[0.95 0.53 0.37]); hold on;
plot(PPStime,allExt,'--','LineWidth',2,'Color',[0.95 0.53 0.37]); b.FaceColor = "#D95319"; hold on;
axis([-2 2.8 erdScale]); hold on;
line([0 0], [-50 50], 'Color', 'k', 'LineWidth', 1); hold on;
line([0.8 0.8], [-50 50], 'Color', 'k', 'LineWidth', 1); 
xlabel('Time (s)'); title('Cond vs Extinction'); set(gca,'fontsize', 14) ; legend('Cond','Ext');

%%%%%%%%%%%%%%%%%%%%%%%

figure('Name','TFR plots grand averaged over all electrodes');

allerd = (conderd+devalerd)./2; allerd = squeeze(mean(allerd,3));

imagesc(allerd,erdScale); ax=gca; ax.XLim = allt; ax.YLim = [1 50]; set(gca,'XLim',ax.XLim,'YLim',ax.YLim); title('Grand average time frequency plot'); colorbar;
hold on; line([26 26], [1 50], 'Color', 'k', 'LineWidth', 1); hold on; line([34 34], [1 50], 'Color', 'k', 'LineWidth', 1); hold off; axis xy; % adds lines at cue start and end
sample_ticks = ax.XLim(1):10:ax.XLim(2); time_ticks = PPStime(sample_ticks); ax.XTick = sample_ticks; ax.XTickLabel = time_ticks; xlabel('Time (s)');
colormap(jet); set(gca,'fontsize', 14) ;

%%%%%%%%%%%%%%%%%%%%%%%


figure('Name','TFR plots averaged over chosen electrodes - Cond, Extn, Pain, Neut');
tfr=squeeze(mean(conderd,3));
subplot(2,2,1); imagesc(tfr,erdScale); ax=gca; ax.XLim = allt; ax.YLim = [1 50]; set(gca,'XLim',ax.XLim,'YLim',ax.YLim); title('Conditioning all cues'); colorbar;
hold on; line([26 26], [1 50], 'Color', 'k', 'LineWidth', 1); hold on; line([34 34], [1 50], 'Color', 'k', 'LineWidth', 1); hold off; axis xy; % adds lines at cue start and end
sample_ticks = ax.XLim(1):10:ax.XLim(2); time_ticks = PPStime(sample_ticks); ax.XTick = sample_ticks; ax.XTickLabel = time_ticks; xlabel('Time (s)');

tfr=squeeze(mean(devalerd,3));
subplot(2,2,2); imagesc(tfr,erdScale); ax=gca; ax.XLim = allt; ax.YLim = [1 50]; set(gca,'XLim',ax.XLim,'YLim',ax.YLim); title('Extinction all cues'); colorbar;
hold on; line([26 26], [1 50], 'Color', 'k', 'LineWidth', 1); hold on; line([34 34], [1 50], 'Color', 'k', 'LineWidth', 1); hold off;  axis xy; ax.XTick = sample_ticks; ax.XTickLabel = time_ticks; xlabel('Time (s)');

painerd = squeeze(mean(squeeze(GAPall(:,:,:,[1,2],:)),4)); painerd = squeeze(mean(painerd,3)); tfr = squeeze(mean(painerd,3));
subplot(2,2,3); imagesc(tfr,erdScale); ax=gca; ax.XLim = allt; ax.YLim = [1 50]; set(gca,'XLim',ax.XLim,'YLim',ax.YLim); title('Pain Cues, all conds'); colorbar;
hold on; line([26 26], [1 50], 'Color', 'k', 'LineWidth', 1); hold on; line([34 34], [1 50], 'Color', 'k', 'LineWidth', 1); hold off;  axis xy; ax.XTick = sample_ticks; ax.XTickLabel = time_ticks; xlabel('Time (s)');

neuterd = squeeze(mean(squeeze(GAPall(:,:,:,3,:)),5)); neuterd = squeeze(mean(neuterd,3)); tfr = squeeze(mean(neuterd,3));
subplot(2,2,4); imagesc(tfr,erdScale); ax=gca; ax.XLim = allt; ax.YLim = [1 50]; set(gca,'XLim',ax.XLim,'YLim',ax.YLim); title('Neutral Cues, all conds'); colorbar;
hold on; line([26 26], [1 50], 'Color', 'k', 'LineWidth', 1); hold on; line([34 34], [1 50], 'Color', 'k', 'LineWidth', 1); hold off;  axis xy; ax.XTick = sample_ticks; ax.XTickLabel = time_ticks; xlabel('Time (s)');
colormap(jet)

%tonic pain sides

lfirst = find(ismember(allsubs, lfirst)); rfirst = find(ismember(allsubs, rfirst));

deval1erd = squeeze(GERDall(:,:,:,2,:,:)); deval2erd = squeeze(GERDall(:,:,:,4,:,:));

leftleftdeval1 = squeeze(mean(squeeze(deval1erd(:,:,:,1,lfirst)),4));
leftrightdeval1 = squeeze(mean(squeeze(deval1erd(:,:,:,2,lfirst)),4));
rightrightdeval1  = squeeze(mean(squeeze(deval1erd(:,:,:,2,rfirst)),4));
rightleftdeval1  = squeeze(mean(squeeze(deval1erd(:,:,:,1,rfirst)),4));

leftleftdeval2 = squeeze(mean(squeeze(deval2erd(:,:,:,1,rfirst)),4));
leftrightdeval2 = squeeze(mean(squeeze(deval2erd(:,:,:,2,rfirst)),4));
rightrightdeval2 = squeeze(mean(squeeze(deval2erd(:,:,:,2,lfirst)),4));
rightleftdeval2 = squeeze(mean(squeeze(deval2erd(:,:,:,1,lfirst)),4));

TleftCleft = (leftleftdeval1+leftleftdeval2)./2; % cong left
TleftCright = (leftrightdeval1+leftrightdeval2)./2; % incong left
TrightCright = (rightrightdeval1+rightrightdeval2)./2; % cong right
TrightCleft = (rightleftdeval1+rightleftdeval2)./2; %incong right

figure('Name','TFR plots for tonic pain-cue site interaction, averaged over selected electrodes');
subplot(2,2,1);
imagesc(squeeze(mean(TleftCleft(EL,:,:),1)),erdScale); ax=gca; ax.XLim = allt; ax.YLim = [1 50];set(gca,'XLim',ax.XLim,'YLim',ax.YLim); title(['Pain L Cue L']); colorbar;
hold on; line([26 26], [1 50], 'Color', 'k', 'LineWidth', 1); hold on; line([34 34], [1 50], 'Color', 'k', 'LineWidth', 1); hold off; axis xy; % adds lines at cue start and end

sample_ticks = ax.XLim(1):10:ax.XLim(2); time_ticks = PPStime(sample_ticks); ax.XTick = sample_ticks; ax.XTickLabel = time_ticks; xlabel('Time (s)');

subplot(2,2,4);
imagesc(squeeze(mean(TleftCright(EL,:,:),1)),erdScale); ax=gca; ax.XLim = allt; ax.YLim = [1 50]; set(gca,'XLim',ax.XLim,'YLim',ax.YLim); title(['Pain L Cue R']); colorbar;
hold on; line([26 26], [1 50], 'Color', 'k', 'LineWidth', 1); hold on; line([34 34],[1 50], 'Color', 'k', 'LineWidth', 1); hold off; axis xy; ax.XTick = sample_ticks; ax.XTickLabel = time_ticks; xlabel('Time (s)');

subplot(2,2,3);
imagesc(squeeze(mean(TrightCright(EL,:,:),1)),erdScale); ax=gca; ax.XLim = allt; ax.YLim = [1 50]; set(gca,'XLim',ax.XLim,'YLim',ax.YLim); title(['Pain R Cue R']); colorbar;
hold on; line([26 26], [1 50], 'Color', 'k', 'LineWidth', 1); hold on; line([34 34],[1 50], 'Color', 'k', 'LineWidth', 1); hold off; axis xy; ax.XTick = sample_ticks; ax.XTickLabel = time_ticks; xlabel('Time (s)');

subplot(2,2,2);
imagesc(squeeze(mean(TrightCleft(EL,:,:),1)),erdScale); ax=gca; ax.XLim = allt;ax.YLim = [1 50]; set(gca,'XLim',ax.XLim,'YLim',ax.YLim); title(['Pain R Cue L']); colorbar;
hold on; line([26 26], [1 50], 'Color', 'k', 'LineWidth', 1); hold on; line([34 34],[1 50], 'Color', 'k', 'LineWidth', 1); hold off; axis xy; ax.XTick = sample_ticks; ax.XTickLabel = time_ticks; xlabel('Time (s)');
colormap(jet)

%%%%%%%%%%%%%%%%%%%%%%%

cong = (TleftCleft+TrightCright)./2;
incong = (TleftCright+TrightCleft)./2;

figure('Name','TFR plots for tonic cong-incong, averaged over selected electrodes');
subplot(2,2,1);
imagesc(squeeze(mean(cong(EL,:,:),1)),erdScale); ax=gca; ax.XLim = allt; ax.YLim = [1 50];set(gca,'XLim',ax.XLim,'YLim',ax.YLim); title(['Congruent']); colorbar;
hold on; line([26 26], [1 50], 'Color', 'k', 'LineWidth', 1); hold on; line([34 34], [1 50], 'Color', 'k', 'LineWidth', 1); hold off; axis xy; % adds lines at cue start and end

sample_ticks = ax.XLim(1):10:ax.XLim(2); time_ticks = PPStime(sample_ticks); ax.XTick = sample_ticks; ax.XTickLabel = time_ticks; xlabel('Time (s)');

subplot(2,2,2);
imagesc(squeeze(mean(incong(EL,:,:),1)),erdScale); ax=gca; ax.XLim = allt; ax.YLim = [1 50]; set(gca,'XLim',ax.XLim,'YLim',ax.YLim); title(['Incongruent']); colorbar;
hold on; line([26 26], [1 50], 'Color', 'k', 'LineWidth', 1); hold on; line([34 34],[1 50], 'Color', 'k', 'LineWidth', 1); hold off; axis xy; ax.XTick = sample_ticks; ax.XTickLabel = time_ticks; xlabel('Time (s)');
colormap(jet)

%% =================================================================

%topoplots of the above

PainLCong = squeeze(mean(TleftCleft(:,s1:s2,t1:t2),2)); PainLCong = squeeze(mean(PainLCong,2));
PainLIncong = squeeze(mean(TleftCright(:,s1:s2,t1:t2),2)); PainLIncong = squeeze(mean(PainLIncong,2));
PainRCong = squeeze(mean(TrightCright(:,s1:s2,t1:t2),2)); PainRCong = squeeze(mean(PainRCong,2));
PainRIncong = squeeze(mean(TrightCleft(:,s1:s2,t1:t2),2)); PainRIncong = squeeze(mean(PainRIncong,2));
cong=(PainLCong+PainRCong)./2;
incong = (PainLIncong+PainRIncong)./2;

figure('Name','Topoplots for tonic pain-cue site interaction during extinction, specified time window');
subplot(3,2,1); topoplot(mean(cong,2),E,'style','map','maplimits',erdScale); title('Congruent Tonic Pain + Cue'); colorbar;
subplot(3,2,2); topoplot(mean(incong,2),E,'style','map','maplimits',erdScale); title('Incongruent Tonic Pain + Cue'); colorbar;
subplot(3,2,3); topoplot(mean(PainLCong,2),E,'style','map','maplimits',erdScale); title('Pain L Cue L'); colorbar;
subplot(3,2,6); topoplot(mean(PainLIncong,2),E,'style','map','maplimits',erdScale); title('Pain L Cue R'); colorbar;
subplot(3,2,5); topoplot(mean(PainRCong,2),E,'style','map','maplimits',erdScale); title('Pain R Cue R'); colorbar;
subplot(3,2,4); topoplot(mean(PainRIncong,2),E,'style','map','maplimits',erdScale); title('Pain R Cue L'); colorbar;

%% =================================================================

%Cong incong only

figure('Name','Av topoplots for tonic pain-cue site interaction during extinction');
subplot(1,2,1); topoplot(mean(cong,2),E,'style','map','maplimits',erdScale); title('Congruent Tonic Pain + Cue'); colorbar;
subplot(1,2,2); topoplot(mean(incong,2),E,'style','map','maplimits',erdScale); title('Incongruent Tonic Pain + Cue'); colorbar;
%colormap(redblue);

%% =================================================================

%export for statistics -- removed -- see previous versions if needed

% =================================================================
% Uncomment to produce a blank map of electrode locs

% figure('Name','Blank Map');
% noels = zeros(1,32);
% topoplot(noels,E,'style','blank','electrodes','on');
%
% % =================================================================
% Uncomment to look at all participant data individually

% alls = squeeze(mean(squeeze(GERDall(:,:,:,:,:,:)),1));
% alls = squeeze(mean(squeeze(alls(:,:,:,:,:,:)),4));
% alls = squeeze(mean(squeeze(alls(:,:,:,:,:,:)),3));
%
% allsubs=sort([3,5,9,11,13,15,17,19,21,25,27,29,2,4,6,8,10,12,14,16,20,22,24,26,28,30]);
%
% figure;
% for i=1:26
%     subplot(5,6,i);
%     imagesc(squeeze(mean(alls(:,:,i),3)),erdScale);
%     ax=gca;
%     ax.XLim = [6 46];
%     ax.YLim = [1 50];
%     set(gca,'XLim',ax.XLim,'YLim',ax.YLim);
%     title(['Participant ' num2str(allsubs(i))]);
%     colorbar;
% end

% =================================================================

%no L/R in this version

% =================================================================

