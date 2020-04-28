%% get the data you need 
%ALL OF THE CODE BELOW HAS BEEN WRITTEN TO SORT, AVERAGE, AND PLOT CALCIUM
%PEAK ALIGNED DATA - DON'T NEED THIS YET...
%{
temp = matfile('SF56_20190718_ROI2_8_CVBdata_F-SB_terminalWOnoiseFloor_CaPeakAlignedData_2frameMinWidth.mat');
sortedCdata8 = temp.sortedCdata; 
sortedBdata8 = temp.sortedBdata;
sortedVdata8 = temp.sortedVdata; 

%% put all like data into the same cell array 

CdataArray(1,:) = sortedCdata1;
CdataArray(2,:) = sortedCdata2;
CdataArray(3,:) = sortedCdata3;
CdataArray(4,:) = sortedCdata4;
CdataArray(5,:) = sortedCdata5;
CdataArray(6,:) = sortedCdata7;
CdataArray(7,:) = sortedCdata8;

BdataArray(1,:) = sortedBdata1;
BdataArray(2,:) = sortedBdata2;
BdataArray(3,:) = sortedBdata3;
BdataArray(4,:) = sortedBdata4;
BdataArray(5,:) = sortedBdata5;
BdataArray(6,:) = sortedBdata7;
BdataArray(7,:) = sortedBdata8;

VdataArray(1,:) = sortedVdata1;
VdataArray(2,:) = sortedVdata2;
VdataArray(3,:) = sortedVdata3;
VdataArray(4,:) = sortedVdata4;
VdataArray(5,:) = sortedVdata5;
VdataArray(6,:) = sortedVdata7;
VdataArray(7,:) = sortedVdata8;

%% determine weights from number of peaks per video per terminal 

numPeaks = zeros(size(CdataArray,1),size(CdataArray,2));
totalPeaks = zeros(1,size(CdataArray,2));
weights = zeros(size(CdataArray,1),size(CdataArray,2));
for term = 1:size(CdataArray,2)
    for vid = 1:size(CdataArray,1)
        numPeaks(vid,term) = size(CdataArray{vid,term},1);
    end 
    totalPeaks(term) = sum(numPeaks(:,term));
    weights(:,term) = numPeaks(:,term)./totalPeaks(term);
end 


%% determine weighted average 

avCarray = cell(1,size(CdataArray,2));
avCterm = zeros(size(CdataArray,2),length(CdataArray{1}));
avBarray = cell(1,size(CdataArray,2));
avBterm = zeros(size(CdataArray,2),length(CdataArray{1}));
avVarray = cell(1,size(CdataArray,2));
avVterm = zeros(size(CdataArray,2),length(CdataArray{1}));
for term = 1:size(CdataArray,2)
    for vid = 1:size(CdataArray,1)
        if isempty(CdataArray{vid,term}) == 0 
            avCarray{term}(vid,:) = (nanmean(CdataArray{vid,term},1))*weights(vid,term);
            avBarray{term}(vid,:) = (nanmean(BdataArray{vid,term},1))*weights(vid,term);
            avVarray{term}(vid,:) = (nanmean(VdataArray{vid,term},1))*weights(vid,term);
        end 
    end
    avCterm(term,:) = sum(avCarray{term},1);
    avBterm(term,:) = sum(avBarray{term},1);
    avVterm(term,:) = sum(avVarray{term},1);
end 

avC = nanmean(avCterm,1);
avB = nanmean(avBterm,1);
avV = nanmean(avVterm,1);

%% normalize to baseline period and plot


%normalize to baseline period 
baselinePer = floor(length(avC)/3);
avC2 = ((avC-mean(avC(1:baselinePer)))/mean(avC(1:baselinePer)))*100;
avB2 = ((avB-mean(avB(1:baselinePer)))/mean(avB(1:baselinePer)))*100;
avV2 = ((avV-mean(avV(1:baselinePer)))/mean(avV(1:baselinePer)))*100;


avCterm2 = ((avCterm-mean(avCterm(:,1:baselinePer),2))./mean(avCterm(:,1:baselinePer),2))*100;
avBterm2 = ((avBterm-mean(avBterm(:,1:baselinePer),2))./mean(avBterm(:,1:baselinePer),2))*100;
avVterm2 = ((avVterm-mean(avVterm(:,1:baselinePer),2))./mean(avVterm(:,1:baselinePer),2))*100;

%%
figure;
Frames = size(avC,2);
Frames_pre_stim_start = -((Frames-1)/2); 
Frames_post_stim_start = (Frames-1)/2; 
sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack:Frames_post_stim_start)/FPSstack));
FrameVals = round((1:FPSstack:Frames)-5); 
ax=gca;
hold all
% for row = 1:5
%     plot(sortedBdata(row,:),'r','LineWidth',2)
%     plot(sortedCdata(row,:),'b','LineWidth',2)
% end 
plot(avB2,'r','LineWidth',2);
plot(avC2,'b','LineWidth',2);
% plot(avV2,'k','LineWidth',2);
% varargout = boundedline(1:size(avB2,2),avB2,semB2,'r','transparency', 0.3,'alpha');                                                                             
% varargout = boundedline(1:size(avC2,2),avC2,semC2,'b','transparency', 0.3,'alpha'); 
% varargout = boundedline(1:size(avV2,2),avV2,semV2,'k','transparency', 0.3,'alpha'); 
ax.XTick = FrameVals;
ax.XTickLabel = sec_TimeVals;
ax.FontSize = 20;
xlim([0 length(avC)])
ylim([-200 200])
legend('BBB data','DA calcium','Vessel width')
% legend('BBB data','DA calcium')
xlabel('time (s)')
ylabel('percent change')
% title(sprintf('%d calcium peaks',length(peaks)))


%% plot terminal data 
terminals = [13, 20, 12, 16, 11, 15, 10, 8, 9, 7, 4];

for term = 1:size(CdataArray,2)
    
    figure;
    Frames = size(avC,2);
    Frames_pre_stim_start = -((Frames-1)/2); 
    Frames_post_stim_start = (Frames-1)/2; 
    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack:Frames_post_stim_start)/FPSstack));
    FrameVals = round((1:FPSstack:Frames)-5); 
    ax=gca;
    hold all
    % for row = 1:5
    %     plot(sortedBdata(row,:),'r','LineWidth',2)
    %     plot(sortedCdata(row,:),'b','LineWidth',2)
    % end 
    plot(avBterm2(term,:),'r','LineWidth',2);
    plot(avCterm2(term,:),'b','LineWidth',2);
%     plot(avVterm2(term,:),'k','LineWidth',2);
    % varargout = boundedline(1:size(avB2,2),avB2,semB2,'r','transparency', 0.3,'alpha');                                                                             
    % varargout = boundedline(1:size(avC2,2),avC2,semC2,'b','transparency', 0.3,'alpha'); 
    % varargout = boundedline(1:size(avV2,2),avV2,semV2,'k','transparency', 0.3,'alpha'); 
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;
    ax.FontSize = 20;
    xlim([0 length(avC)])
    ylim([-200 200])
    legend('BBB data','DA calcium','Vessel width')
    % legend('BBB data','DA calcium')
    xlabel('time (s)')
    ylabel('percent change')
    title(sprintf('Terminal %d',terminals(term))) 
   
end 
%}

%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%% concatenate trial type data per terminal 
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

%% get the data you need 

temp = matfile('SF56_20190718_ROI2_8_CVBdata_F-SB_terminalWOnoiseFloor_CaPeakAlignedData_2frameMinWidth.mat');
sortedCdata8 = temp.sortedCdata; 
sortedBdata8 = temp.sortedBdata;
sortedVdata8 = temp.sortedVdata; 
