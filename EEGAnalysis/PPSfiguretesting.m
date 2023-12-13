

close all;

%=====================================================================

%optional plotting of data to check ERD data
fplot          = []; %figure plot structure
fplot.draw     = 1; %if 1, figures will be plotted, else only saves spectra
%fplot.els      = {'C3' 'C4'};
%fplot.what     = 1; %1 = ERD; 2 = power; 3 = amplitude (square root of power) - only option 1 works at the moment!
%fplot.bands    = [8 12; 16 32];

% =================================================================
freq = [4 7];
topoTimeWindow = [26 46];
tfTimeWindow = [6 45];
stats = 1;
% =================================================================

fplot.erdscale = [-20 20];
fplot.timepnt  = [1.0 2.0 4.0]; %plotting ERD maps at 3 selected time points
fplot.clusters = {'C3' 'C5' 'C1' 'CP3' 'FC3'; 'C4' 'C2' 'C6' 'CP4' 'FC4'};
conds = {'cond-b1', 'deval-b1', 'cond-b2', 'deval-b2'}; %order of saving
cues = {'left', 'right', 'middle'};
lfirst=[3,5,9,11,13,15,17,19,21,25,27,29];
rfirst=[2,4,6,8,10,12,14,16,20,22,24,26,28,30];
allsubs=sort([3,5,9,11,13,15,17,19,21,25,27,29,2,4,6,8,10,12,14,16,20,22,24,26,28,30]);

%=====================================================================

load('AllERD_csd_09-Oct-2023.mat');
E = readlocs('chanlocs32.sfp'); %please check the presence of the electrode coordinate file when calling rlocs64
v = squeeze(mean(GERDall(:,freq(1):freq(2),topoTimeWindow(1):topoTimeWindow(2),:,:,:),2)); v=squeeze(mean(v,2)); bv=squeeze(mean(v,3));

%%%%%%%%%%%%%%%%%%%%%%%
%commented out because it's not that insightful - but works fine

% figure('Name','Topoplots averaged over each successive block');
% cond1 = squeeze(mean(bv(:,1,:),2));
% deval1 = squeeze(mean(bv(:,2,:),2));
% cond2 = squeeze(mean(bv(:,3,:),2));
% deval2 = squeeze(mean(bv(:,4,:),2));
% 
% subplot(1,4,1); topoplot(mean(cond1,2),E,'style','map','maplimits',fplot.erdscale); title('Conditioning block 1'); colorbar;
% subplot(1,4,3); topoplot(mean(cond2,2),E,'style','map','maplimits',fplot.erdscale); title('Conditioning block 2'); colorbar;
% subplot(1,4,2); topoplot(mean(deval1,2),E,'style','map','maplimits',fplot.erdscale); title('Extinction block 1'); colorbar;
% subplot(1,4,4); topoplot(mean(deval2,2),E,'style','map','maplimits',fplot.erdscale); title('Extinction block 2'); colorbar;

%%%%%%%%%%%%%%%%%%%%%%%

figure('Name','Averaged topoplots in each of the 4 conditions, time locked to the cue');

cond = squeeze(mean(v(:,[1,3],:,:),2));
condPain = squeeze(mean(cond(:,[1,2],:),2));
condNonPain = squeeze(mean(cond(:,3,:),2));

deval = squeeze(mean(v(:,[2,4],:,:),2));
devalPain = squeeze(mean(deval(:,[1,2],:),2));
devalNonPain = squeeze(mean(deval(:,3,:),2));

allcond = (condPain+condNonPain)./2; allcond = mean(allcond,2);
alldeval = (devalPain+devalNonPain)./2; alldeval = mean(alldeval,2);

subplot(2,3,1); topoplot(allcond,E,'style','map','maplimits',fplot.erdscale); title('All Conditioning'); colorbar;
subplot(2,3,4); topoplot(alldeval,E,'style','map','maplimits',fplot.erdscale); title('All Extinction'); colorbar;
subplot(2,3,2); topoplot(mean(condPain,2),E,'style','map','maplimits',fplot.erdscale); colorbar; title('Conditioning Pain Cue');
subplot(2,3,3); topoplot(mean(condNonPain,2),E,'style','map','maplimits',fplot.erdscale); colorbar; title('Conditioning Neutral Cue');
subplot(2,3,5); topoplot(mean(devalPain,2),E,'style','map','maplimits',fplot.erdscale); colorbar; title('Extinction Pain Cue');
subplot(2,3,6); topoplot(mean(devalNonPain,2),E,'style','map','maplimits',fplot.erdscale); colorbar; title('Extinction Neutral Cue');

%%%%%%%%%%%%%%%%%%%%%%%

% %Figure 1 plots ERD curves in 2 electrodes and 2 bands
% figure('Name','ERD curves'); this doesnt work yet
% c=0;
% for band = 1:2
%     for i=1:4 %conditions
%
%         c=c+1;
%         subplot(2,4,c);
%         eval(['erd = G.ERD' conds{i} ';']);
%         e1 = squeeze(squeeze(mean(erd(elecs(1,1),inds(band,1):inds(band,2),:),2)));
%         e2 = squeeze(squeeze(mean(erd(elecs(1,2),inds(band,1):inds(band,2),:),2)));
%         plot(D.time,e1,'r'); %while ERD is a power decrease, it is actualy a positive value; therefore, for the purpose of plotting, the ERD curve is actually plotted withinverse sign (not logigal, huh?)
%         hold on;
%         plot(D.time,e2,'b');
%         legend(fplot.els{1},fplot.els{2},'location','best');
%         axis([-2 4.9 fplot.erdscale(1,1) fplot.erdscale(1,2)]);
%         grid on;
%         title([conds{i} '  ' num2str(inds(band,1)) '-' num2str(inds(band,2)) ' Hz']);
%
%     end
% end
%

%Figures 2 and 3 plot the 2D maps

%
% for band = 1:2 this doesnt work yet
%     figure('Name',['Maps1 in ' num2str(inds(band,1)) '-' num2str(inds(band,2))]); %each band on a new figure
%
%     c=0;
%     for k=1:4
%         eval(['erd = G.ERD' conds{k} ';']);
%         for i=1:3
%             c=c+1;
%             subplot(2,6,c);
%             t1=nearest(D.time,fplot.timepnt(i));
%             v = squeeze(squeeze(mean(erd(:,inds(band,1):inds(band,2),t1),2)));
%             topoplot(v,E,'style','map','maplimits',fplot.erdscale);  %the maps are the relative power maps, not ERD maps P[%] = -ERD[%]
%             title([conds{k} ' ' num2str(fplot.timepnt(i)) ' s']);
%         end
%     end
%
% end

%%%%%%%%%%%%%%%%%%%%%%%

%% this works

% figure('Name','TFR plots for electrode Pz');
% c=0;
% for k=1:4 %4 conditions
%     for j=1:3
%         erd = squeeze(mean(squeeze(GERDall(13,:,:,:,:,:)),5));
%         c=c+1;
%         tfr=squeeze(erd(:,:,k,j));
%         subplot(4,3,c);
%         imagesc(tfr,fplot.erdscale);
%         ax=gca;
%         ax.XLim = tfTimeWindow;
%         ax.YLim = [1 50];
%         set(gca,'XLim',ax.XLim,'YLim',ax.YLim);
%         title([conds{k} ' ' cues{j}]);
%         colorbar;
%     end
% end


%%%%%%%%%%%%%%%%%%%%%%%

figure('Name','TFR plots averaged');

GAPall = squeeze(mean(GERDall,1));
conderd = squeeze(mean(squeeze(GAPall(:,:,[1,3],:,:)),5)); conderd = squeeze(mean(conderd,3));
devalerd = squeeze(mean(squeeze(GAPall(:,:,[2,4],:,:)),5)); devalerd = squeeze(mean(devalerd,3));

tfr=squeeze(mean(conderd(:,:,[1:2]),3)); subplot(2,2,1); imagesc(tfr,fplot.erdscale); ax=gca; ax.XLim = tfTimeWindow; ax.YLim = [1 50]; set(gca,'XLim',ax.XLim,'YLim',ax.YLim); title('Conditioning, Pain cues'); colorbar;
tfr=squeeze(conderd(:,:,3)); subplot(2,2,2); imagesc(tfr,fplot.erdscale); ax=gca; ax.XLim = tfTimeWindow; ax.YLim = [1 50]; set(gca,'XLim',ax.XLim,'YLim',ax.YLim); title('Conditioning, Neutral cues'); colorbar;
tfr=squeeze(mean(devalerd(:,:,[1:2]),3)); subplot(2,2,3); imagesc(tfr,fplot.erdscale); ax=gca; ax.XLim = tfTimeWindow; ax.YLim = [1 50]; set(gca,'XLim',ax.XLim,'YLim',ax.YLim); title('Extinction, Pain cues'); colorbar;
tfr=squeeze(devalerd(:,:,3)); subplot(2,2,4); imagesc(tfr,fplot.erdscale); ax=gca; ax.XLim = tfTimeWindow; ax.YLim = [1 50]; set(gca,'XLim',ax.XLim,'YLim',ax.YLim); title('Extinction, Neutral cues'); colorbar;

%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%

% figure('Name','TFR plots, selected electrode Pz');
%
% GAPall = squeeze(GERDall(13,:,:,:,:,:));
% conderd = squeeze(mean(squeeze(GAPall(:,:,[1,3],:,:)),5)); conderd = squeeze(mean(conderd,3));
% devalerd = squeeze(mean(squeeze(GAPall(:,:,[2,4],:,:)),5)); devalerd = squeeze(mean(devalerd,3));
%
% tfr=squeeze(mean(conderd(:,:,[1:2]),3)); subplot(2,2,1); imagesc(tfr,fplot.erdscale); ax=gca; ax.XLim = tfTimeWindow; ax.YLim = [1 50]; set(gca,'XLim',ax.XLim,'YLim',ax.YLim); title('Conditioning, Pain cues'); colorbar;
% tfr=squeeze(conderd(:,:,3)); subplot(2,2,2); imagesc(tfr,fplot.erdscale); ax=gca; ax.XLim = tfTimeWindow; ax.YLim = [1 50]; set(gca,'XLim',ax.XLim,'YLim',ax.YLim); title('Conditioning, Neutral cues'); colorbar;
% tfr=squeeze(mean(devalerd(:,:,[1:2]),3)); subplot(2,2,3); imagesc(tfr,fplot.erdscale); ax=gca; ax.XLim = tfTimeWindow; ax.YLim = [1 50]; set(gca,'XLim',ax.XLim,'YLim',ax.YLim); title('Extinction, Pain cues'); colorbar;
% tfr=squeeze(devalerd(:,:,3)); subplot(2,2,4); imagesc(tfr,fplot.erdscale); ax=gca; ax.XLim = tfTimeWindow; ax.YLim = [1 50]; set(gca,'XLim',ax.XLim,'YLim',ax.YLim); title('Extinction, Neutral cues'); colorbar;

%%%%%%%%%%%%%%%%%%%%%%%

%tonic pain sides

figure('Name','TFR plots for tonic pain-cue site interaction');

lfirst = find(ismember(allsubs, lfirst));
rfirst = find(ismember(allsubs, rfirst));

deval1erd = squeeze(mean(squeeze(GERDall(:,:,:,2,:,:)),1));
deval2erd = squeeze(mean(squeeze(GERDall(:,:,:,4,:,:)),1));

leftleftdeval1 = squeeze(mean(squeeze(deval1erd(:,:,1,lfirst)),3));
leftleftdeval2 = squeeze(mean(squeeze(deval2erd(:,:,1,rfirst)),3));
TleftCleft = (leftleftdeval1+leftleftdeval2)./2;

leftrightdeval1 = squeeze(mean(squeeze(deval1erd(:,:,2,lfirst)),3));
leftrightdeval2 = squeeze(mean(squeeze(deval2erd(:,:,2,rfirst)),3));
TleftCright = (leftrightdeval1+leftrightdeval2)./2;

rightrightdeval1  = squeeze(mean(squeeze(deval1erd(:,:,2,rfirst)),3));
rightrightdeval2 = squeeze(mean(squeeze(deval2erd(:,:,2,lfirst)),3));
TrightCright = (rightrightdeval1+rightrightdeval2)./2;

rightleftdeval1  = squeeze(mean(squeeze(deval1erd(:,:,1,rfirst)),3));
rightleftdeval2 = squeeze(mean(squeeze(deval2erd(:,:,1,lfirst)),3));
TrightCleft = (rightleftdeval1+rightleftdeval2)./2;

subplot(2,2,1);
imagesc(TleftCleft,fplot.erdscale);
ax=gca;
ax.XLim = tfTimeWindow;
ax.YLim = [1 50];
set(gca,'XLim',ax.XLim,'YLim',ax.YLim);
title(['Pain L Cue L']);
colorbar;

subplot(2,2,2);
imagesc(TleftCright,fplot.erdscale);
ax=gca;
ax.XLim = tfTimeWindow;
ax.YLim = [1 50];
set(gca,'XLim',ax.XLim,'YLim',ax.YLim);
title(['Pain L Cue R']);
colorbar;

subplot(2,2,3);
imagesc(TrightCright,fplot.erdscale);
ax=gca;
ax.XLim = tfTimeWindow;
ax.YLim = [1 50];
set(gca,'XLim',ax.XLim,'YLim',ax.YLim);
title(['Pain R Cue R']);
colorbar;

subplot(2,2,4);
imagesc(TrightCleft,fplot.erdscale);
ax=gca;
ax.XLim = tfTimeWindow;
ax.YLim = [1 50];
set(gca,'XLim',ax.XLim,'YLim',ax.YLim);
title(['Pain R Cue L']);
colorbar;

%% =================================================================

%topoplots of the above

deval1erd = squeeze(mean(squeeze(GERDall(:,freq(1):freq(2),topoTimeWindow(1):topoTimeWindow(2),2,:,:)),2)); deval1erd=squeeze(mean(deval1erd,2));
deval2erd = squeeze(mean(squeeze(GERDall(:,freq(1):freq(2),topoTimeWindow(1):topoTimeWindow(2),4,:,:)),2)); deval2erd=squeeze(mean(deval2erd,2));

TleftCleft=[(squeeze(deval1erd(:,1,lfirst))),(squeeze(deval2erd(:,1,rfirst)))];
TleftCright=[(squeeze(deval1erd(:,2,lfirst))),(squeeze(deval2erd(:,2,rfirst)))];
TrightCright=[(squeeze(deval1erd(:,2,rfirst))),(squeeze(deval2erd(:,2,lfirst)))];
TrightCleft=[(squeeze(deval1erd(:,1,rfirst))),(squeeze(deval2erd(:,1,lfirst)))];
cong=(TleftCleft+TrightCright)./2;
incong = (TleftCright+TrightCleft)./2;

figure('Name','Topoplots for tonic pain-cue site interaction during extinction');
subplot(3,2,1); topoplot(mean(cong,2),E,'style','map','maplimits',fplot.erdscale); title('Congruent Tonic Pain + Cue'); colorbar;
subplot(3,2,2); topoplot(mean(incong,2),E,'style','map','maplimits',fplot.erdscale); title('Incongruent Tonic Pain + Cue'); colorbar;
subplot(3,2,3); topoplot(mean(TleftCleft,2),E,'style','map','maplimits',fplot.erdscale); title('Pain L Cue L'); colorbar;
subplot(3,2,4); topoplot(mean(TleftCright,2),E,'style','map','maplimits',fplot.erdscale); title('Pain L Cue R'); colorbar;
subplot(3,2,6); topoplot(mean(TrightCleft,2),E,'style','map','maplimits',fplot.erdscale); title('Pain R Cue L'); colorbar;
subplot(3,2,5); topoplot(mean(TrightCright,2),E,'style','map','maplimits',fplot.erdscale); title('Pain R Cue R'); colorbar;

%colormap(redblue);

%% =================================================================

%export for statistics

if stats == 0
    disp('Results not saved to file');
    return
else

    % Running permutation analysis using statcond from EEGLAB
    [F df P] = statcond({condPain condNonPain; devalPain devalNonPain},'method','perm','naccu',5000); %permutation test

    % Plotting significant electrodes
    MEBlock = P{1};
    for sigel = 1:32

        if MEBlock(sigel,1) > 0.05
            MEBlock(sigel,1) = 0.001;
        else
            if MEBlock(sigel,1) > 0.01
                MEBlock(sigel,1) = 100;
            else
                if MEBlock(sigel,1) <= 0.05
                    MEBlock(sigel,1) = 50;
                end
            end
        end


    end

    %Main effect of touch loc
    MECue = P{2};
    for sigel = 1:32

        if MECue(sigel,1) > 0.05
            MECue(sigel,1) = 0.001;
        else
            if MECue(sigel,1) > 0.01
                MECue(sigel,1) = 100;
            else
                if MECue(sigel,1) <= 0.05
                    MECue(sigel,1) = 50;
                end
            end
        end
    end

    %Interaction between touch location and speed
    BvCInt = P{3};
    for sigel = 1:32

        if BvCInt(sigel,1) > 0.05
            BvCInt(sigel,1) = 0.001;
        else
            if BvCInt(sigel,1) > 0.01
                BvCInt(sigel,1) = 100;
            else
                if BvCInt(sigel,1) <= 0.05
                    BvCInt(sigel,1) = 50;
                end
            end
        end
    end

    %===

    % Running permutation analysis using statcond from EEGLAB
    [F df P] = statcond({TleftCleft TleftCright; TrightCleft TrightCright},'method','perm','naccu',5000); %permutation test

    % Plotting significant electrodes
    METonicSite = P{1};
    for sigel = 1:32

        if METonicSite(sigel,1) > 0.05
            METonicSite(sigel,1) = 0.001;
        else
            if METonicSite(sigel,1) > 0.01
                METonicSite(sigel,1) = 100;
            else
                if METonicSite(sigel,1) <= 0.05
                    METonicSite(sigel,1) = 50;
                end
            end
        end


    end

    %Main effect of touch loc
    MECueDir = P{2};
    for sigel = 1:32

        if MECueDir(sigel,1) > 0.05
            MECueDir(sigel,1) = 0.001;
        else
            if MECueDir(sigel,1) > 0.01
                MECueDir(sigel,1) = 100;
            else
                if MECueDir(sigel,1) <= 0.05
                    MECueDir(sigel,1) = 50;
                end
            end
        end
    end

    %Interaction between touch location and speed
    TPvCueInt = P{3};
    for sigel = 1:32

        if TPvCueInt(sigel,1) > 0.05
            TPvCueInt(sigel,1) = 0.001;
        else
            if TPvCueInt(sigel,1) > 0.01
                TPvCueInt(sigel,1) = 100;
            else
                if TPvCueInt(sigel,1) <= 0.05
                    TPvCueInt(sigel,1) = 50;
                end
            end
        end
    end


    % =================================================================

    figure('Name', 'Permutation Results');
    subplot(2,3,1); topoplot(MEBlock,E,'style','map','maplimits',[1 100]); title('Main Effect Block'); colorbar;
    subplot(2,3,2); topoplot(MECue,E,'style','map','maplimits',[1 100]); title('Main Effect Cue'); colorbar;
    subplot(2,3,3); topoplot(BvCInt,E,'style','map','maplimits',[1 100]); title('Block x Cue'); colorbar;
    subplot(2,3,4); topoplot(METonicSite,E,'style','map','maplimits',[1 100]); title('Main Effect Tonic Pain Site'); colorbar;
    subplot(2,3,5); topoplot(MECueDir,E,'style','map','maplimits',[1 100]); title('Main Effect Cue Direction'); colorbar;
    subplot(2,3,6); topoplot(TPvCueInt,E,'style','map','maplimits',[1 100]); title('Tonic Pain x Cue'); colorbar;
    colormap(parula(3));
    % =================================================================

end

% =================================================================




