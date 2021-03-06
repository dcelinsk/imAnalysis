function [TSdataBBBperm] = BBBpermTSwholeExp(regStacks,userInput)


%% do background subtraction 
[input_Stacks,~] = backgroundSubtraction(regStacks{2,4});

%% average registered imaging data across planes in Z 
clear inputStackArray
inputStackArray = zeros(size(regStacks{2,4}{1},1),size(regStacks{2,4}{1},2),size(regStacks{2,4}{1},3),size(regStacks{2,4},2));
for Z = 1:size(regStacks{2,4},2)
    inputStackArray(:,:,:,Z) = input_Stacks{Z};
end 
inputStacks = mean(inputStackArray,4);

%% create non-vascular ROI- x-y plane 

%go to dir w/functions
% [imAn1funcDir] = getUserInput(userInput,'imAnalysis1_functions Directory');
% cd(imAn1funcDir); 

%update userInput 
UIr = size(userInput,1)+1;
numROIs = input("How many BBB perm ROIs are we making? "); userInput(UIr,1) = ("How many BBB perm ROIs are we making?"); userInput(UIr,2) = (numROIs); UIr = UIr+1;

%for display purposes mostly: average across frames 
stackAVsIm = mean(inputStacks,3);

%create the ROI boundaries           
ROIboundDatas = cell(1,numROIs);
for VROI = 1:numROIs 
    disp('Create your ROI for BBB perm analysis');

    [~,xmins,ymins,widths,heights] = firstTimeCreateROIs(1, stackAVsIm);
    ROIboundData{1} = xmins;
    ROIboundData{2} = ymins;
    ROIboundData{3} = widths;
    ROIboundData{4} = heights;

    ROIboundDatas{VROI} = ROIboundData;
end

ROIstacks = cell(1,numROIs);
for VROI = 1:numROIs
    %use the ROI boundaries to generate ROIstacks 
    xmins = ROIboundDatas{VROI}{1};
    ymins = ROIboundDatas{VROI}{2};
    widths = ROIboundDatas{VROI}{3};
    heights = ROIboundDatas{VROI}{4};
    [ROI_stacks] = make_ROIs_notfirst_time(inputStacks,xmins,ymins,widths,heights);
    ROIstacks{VROI} = ROI_stacks{1};
end 

%% segment the BBB ROIs - goal: identify non-vascular/non-terminal space 

segQ = 1; 
cd(imAn1funcDir); 
while segQ == 1     

    %segment the vessel (small sample of the data) 
    VROI = input("What BBB ROI do you want to use to make segmentation algorithm? ");

    imageSegmenter(mean(ROIstacks{VROI},3))
    continu = input('Is the image segmenter closed? Yes = 1. No = 0. ');

    while continu == 1 
        BWstacks = cell(1,numROIs);
        BW_perim = cell(1,numROIs);
        segOverlays = cell(1,numROIs);         
        for VROI = 1:numROIs                     
            for frame = 1:size(ROIstacks{VROI},3)
                [BW,~] = segmentImageBBB(ROIstacks{VROI}(:,:,frame));
                BWstacks{VROI}(:,:,frame) = BW; 
                %get the segmentation boundaries 
                BW_perim{VROI}(:,:,frame) = bwperim(BW);
                %overlay segmentation boundaries on data
                segOverlays{VROI}(:,:,:,frame) = imoverlay(mat2gray(ROIstacks{VROI}(:,:,frame)), BW_perim{VROI}(:,:,frame), [.3 1 .3]);
            end               
        end      
        continu = 0;
    end 

    %check segmentation 
    if numROIs == 1 
        %play segmentation boundaries over images 
        implay(segOverlays{1})
    elseif numROIs > 1 
        VROI = input("What BBB ROI do you want to see? ");
        %play segmentation boundaries over images 
        implay(segOverlays{VROI})
    end 


    segQ = input('Does segmentation need to be redone? Yes = 1. No = 0. ');    
end 

%% invert the mask
BWstacksInv = cell(1,numROIs);
for VROI = 1:numROIs                
    for frame = 1:size(ROIstacks{VROI},3)                            
        BWstacksInv{VROI}(:,:,frame) = ~(BWstacks{VROI}(:,:,frame)); 
    end         
end 

%% get pixel intensity value of extravascular space and within vessels 
meanPixIntArray = cell(1,numROIs);
wVmeanPixIntArray = cell(1,numROIs);
for VROI = 1:numROIs           
    for frame = 1:size(ROIstacks{VROI},3)                            
        stats = regionprops(BWstacksInv{VROI}(:,:,frame),ROIstacks{VROI}(:,:,frame),'MeanIntensity');       
        wVstats = regionprops(BWstacks{VROI}(:,:,frame),ROIstacks{VROI}(:,:,frame),'MeanIntensity');   
        
        ROIpixInts = zeros(1,length(stats));
        WvROIpixInts = zeros(1,length(stats));
        for stat = 1:length(stats)
            ROIpixInts(stat) = stats(stat).MeanIntensity;
        end 
        for stat = 1:length(wVstats)
            WvROIpixInts(stat) = wVstats(stat).MeanIntensity;
        end 
        meanPixIntArray{VROI}(frame) = mean(ROIpixInts);  
        wVmeanPixIntArray{VROI}(frame) = mean(WvROIpixInts);         
    end 
    % turn all rows full of zeros into NaNs 
    allZeroRows = find(all(meanPixIntArray{VROI} == 0,2));
    for row = 1:length(allZeroRows)
        meanPixIntArray{VROI} = NaN; 
    end    
    wVallZeroRows = find(all(wVmeanPixIntArray{VROI} == 0,2));
    for row = 1:length(wVallZeroRows)
        wVmeanPixIntArray{VROI} = NaN; 
    end    
end 

           
%% normalize and z score 
            
% dataMeds = cell(1,numROIs);
% DFOF = cell(1,numROIs);
dataSlidingBLs = cell(1,numROIs);
wVdataSlidingBLs = cell(1,numROIs);
Data = cell(1,numROIs);
WvData = cell(1,numROIs);
% zData = cell(1,numROIs);
for VROI = 1:numROIs          
    %get median value per trace
%     dataMed = nanmedian(meanPixIntArray{VROI});     
%     dataMeds{VROI} = dataMed;
%     wVdataMed = nanmedian(wVmeanPixIntArray{VROI});     
%     wVdataMeds{VROI} = wVdataMed;
%     %compute DF/F using median  
%     DFOF{VROI} = (meanPixIntArray{VROI}-dataMeds{VROI})./dataMeds{VROI};   
%     WvDFOF{VROI} = (wVmeanPixIntArray{VROI}-wVdataMeds{VROI})./wVdataMeds{VROI};
    %get sliding baseline 
    [dataSlidingBL]=slidingBaseline(meanPixIntArray{VROI},floor((FPS)*10),0.5); %0.5 quantile thresh = the median value                 
    dataSlidingBLs{VROI} = dataSlidingBL;   
    [wVdataSlidingBL]=slidingBaseline(wVmeanPixIntArray{VROI},floor((FPS)*10),0.5); %0.5 quantile thresh = the median value                 
    wVdataSlidingBLs{VROI} = wVdataSlidingBL;    
    %subtract sliding baseline from DF/F
    Data{VROI} = meanPixIntArray{VROI}-dataSlidingBLs{VROI}; 
    WvData{VROI} = wVmeanPixIntArray{VROI}-wVdataSlidingBLs{VROI}; 
    %z-score data                
%     zData{VROI} = zscore(Data{VROI});
%     wVzData{VROI} = zscore(WvData{VROI});
end 

%% create cumulative pixel intensity traces 

cumData = cell(1,numROIs);
wVcumData = cell(1,numROIs);
for VROI = 1:numROIs
    for frame = 1:size(Data{VROI},2)
        if frame == 1 
            cumData{VROI}(frame) = Data{VROI}(frame);
            wVcumData{VROI}(frame) = WvData{VROI}(frame);
        elseif frame > 1 && frame < size(Data{VROI},2)
            cumData{VROI}(frame) = Data{VROI}(frame)+cumData{VROI}(frame-1);
            wVcumData{VROI}(frame) = WvData{VROI}(frame)+wVcumData{VROI}(frame-1);
        end 
    end 
end 

%% plot 
FPM = FPS*60;
figure;

for VROI = 1:size(cumData,2)
    
    subplot(1,size(cumData,2),VROI)
    ax = gca;
    hold all; plot(cumData{VROI},'r','LineWidth',3);plot(wVcumData{VROI},'k','LineWidth',3)
    %set time in x axis 
    min_TimeVals = floor(0:5:(size(cumData{VROI},2)/FPM));
    FrameVals = floor(0:(size(cumData{VROI},2)/((size(cumData{VROI},2)/FPM)/5)):size(cumData{VROI},2));
    ax.XTick = FrameVals;
    ax.XTickLabel = min_TimeVals;
    ax.FontSize = 20;
    legend('Outside vessel','Inside vessel')
    xlabel('time (min)');
    ylabel('pixel intensity rate change')
end 


Bdata = Data{1};

%{

%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


%% make cumulative pizel intensity images 

% cumIms = cell(1,numROIs);
cumFull = zeros(size(inputStacks,1),size(inputStacks,2),size(inputStacks,3));
% for VROI = 1:numROIs
    for frame = 1:size(Data{VROI},2)
        if frame == 1
%             cumIms{VROI}(:,:,frame) = ROIstacks{VROI}(:,:,frame); 
            cumFull(:,:,frame) = inputStacks(:,:,frame); 
            
        elseif frame > 1 && frame < size(Data{VROI},2)    
%             cumIms{VROI}(:,:,frame) = ROIstacks{VROI}(:,:,frame)+cumIms{VROI}(:,:,frame-1);
            cumFull(:,:,frame) = inputStacks(:,:,frame)+cumFull(:,:,frame-1); 
        end 
    end 
% end 



%%
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%THE BELOW CODE IS FOR AVERAGING ACROSS MICE 

%% import just the data you need 
temp = matfile('63-64-WT6_70FITC_BBB_wholeExp');
cumData_WT6_ROI4 = temp.cumData;
wVcumData_WT6_ROI4 = temp.wVcumData;
FPS_WT6_ROI4 = temp.FPS;

%% put data into same cell array for simplicity 
%cumData{mouse}{ROI}
cumData{1}{1} = cumData_63_ROI1;
cumData{1}{2} = cumData_63_ROI2;
cumData{2}{1} = cumData_64_ROI1;
cumData{2}{2} = cumData_WT6_ROI3;
cumData{3}{1} = cumData_WT6_ROI4;

wVcumData{1}{1} = wVcumData_63_ROI1;
wVcumData{1}{2} = wVcumData_63_ROI2;
wVcumData{2}{1} = wVcumData_64_ROI1;
wVcumData{2}{2} = wVcumData_WT6_ROI3;
wVcumData{3}{1} = wVcumData_WT6_ROI4;

FPS{1}{1} = FPS_63_ROI1;
FPS{1}{2} = FPS_63_ROI2;
FPS{2}{1} = FPS_64_ROI1;
FPS{2}{2} = FPS_WT6_ROI3;
FPS{3}{1} = FPS_WT6_ROI4;


%% get just the first 25 mins of the data 

cumData45min = cell(1,length(cumData));
wVcumData45min = cell(1,length(cumData));
for mouse = 1:length(cumData)
    for ROI = 1:length(cumData{mouse})
        for FOV = 1: length(cumData{mouse}{ROI})
            cumData45min{mouse}{ROI}{FOV} = cumData{mouse}{ROI}{FOV}(1:FPS{mouse}{ROI}*(25*60));
            wVcumData45min{mouse}{ROI}{FOV}= wVcumData{mouse}{ROI}{FOV}(1:FPS{mouse}{ROI}*(25*60));
        end 
    end 
end 



%% average across FOV 

cumDataArray = cell(1,length(cumData));
wVcumDataArray = cell(1,length(cumData));
cumData45minAv1 = cell(1,length(cumData));
wVcumData45minAv1 = cell(1,length(cumData));
for mouse = 1:length(cumData)
    for ROI = 1:length(cumData{mouse})
        for FOV = 1: length(cumData{mouse}{ROI})
            cumDataArray{mouse}{ROI}(FOV,:) = cumData45min{mouse}{ROI}{FOV};
            wVcumDataArray{mouse}{ROI}(FOV,:)= wVcumData45min{mouse}{ROI}{FOV};
        end 
        cumData45minAv1{mouse}{ROI} = mean(cumDataArray{mouse}{ROI},1);
        wVcumData45minAv1{mouse}{ROI} = mean(wVcumDataArray{mouse}{ROI},1);
    end 
end 

%% resample and average across ROIs 

RcumData45minAv1 = cell(1,length(cumData));
RwVcumData45minAv1 = cell(1,length(cumData));
RcumData45minAv = cell(1,length(cumData));
RwVcumData45minAv = cell(1,length(cumData));
for mouse = 1:length(cumData)
    % figure out what value to upsample to (resLen) within mice 
    if length(cumData{mouse}) == 1 
        resLen = length(cumData45minAv1{mouse}{1});
    elseif length(cumData{mouse}) == 2 
        len1 = length(cumData45minAv1{mouse}{1});
        len2 = length(cumData45minAv1{mouse}{2});
        if len1>len2
            resLen = len1;
        elseif len2>len1
            resLen = len2;
        end 
    end 
   
    for ROI = 1:length(cumData{mouse})
        %upsample 
        RcumData45minAv1{mouse}(ROI,:) = resample(cumData45minAv1{mouse}{ROI},resLen,length(cumData45minAv1{mouse}{ROI}));
        RwVcumData45minAv1{mouse}(ROI,:) = resample(wVcumData45minAv1{mouse}{ROI},resLen,length(wVcumData45minAv1{mouse}{ROI}));
    end 
    
    %average 
    RcumData45minAv{mouse} = mean(RcumData45minAv1{mouse},1);
    RwVcumData45minAv{mouse} = mean(RwVcumData45minAv1{mouse},1) ;
   
end 

%% resample across mice 

%figure out what value to upsample to across mice (resLen2)
lens(1) = length(RcumData45minAv{1});
lens(2) = length(RcumData45minAv{2});
lens(3) = length(RcumData45minAv{3});
% lens(4) = length(RcumData45minAv{4});

resLen = max(lens);

for mouse = 1:length(cumData)
    %resample across mice 
    miceCumData(mouse,:) = resample(RcumData45minAv{mouse},resLen,length(RcumData45minAv{mouse}));
    miceCumWvData(mouse,:) = resample(RwVcumData45minAv{mouse},resLen,length(RwVcumData45minAv{mouse}));      
end 

%get average and var across mice 
AVmiceCumData = nanmean(miceCumData,1);
VARmiceCumData = (nanstd(miceCumData,1))/(sqrt(size(miceCumData,1)));
AVmiceCumWvData = nanmean(miceCumWvData,1);
VARmiceCumWvData = (nanstd(miceCumWvData,1))/(sqrt(size(miceCumWvData,1)));


%% plot 
FPS = size(AVmiceCumData,2)/(25*60);
FPM = FPS*60;

figure;
ax = gca;
hold all; 
plot(AVmiceCumData,'r','LineWidth',3);
plot(NC_AVmiceCumData,'k','LineWidth',3);
% plot(AVmiceCumWvData,'k','LineWidth',3);
varargout = boundedline(1:size(AVmiceCumData,2),AVmiceCumData,VARmiceCumData,'r','transparency', 0.1,'alpha');    
varargout = boundedline(1:size(NC_AVmiceCumData,2),NC_AVmiceCumData,NC_VARmiceCumData,'k','transparency', 0.1,'alpha'); 
% varargout = boundedline(1:size(AVmiceCumWvData,2),AVmiceCumWvData,VARmiceCumWvData,'k','transparency', 0.1,'alpha'); 
%set time in x axis 
min_TimeVals = ceil(0:5:(size(AVmiceCumData,2)/FPM));
FrameVals = ceil(0:(size(AVmiceCumData,2)/((size(AVmiceCumData,2)/FPM)/5)):size(AVmiceCumData,2));
ax.XTick = FrameVals;
ax.XTickLabel = min_TimeVals;
ax.FontSize = 20;
legend('Chrimson(+) mice','Chrimson(-) mice')
xlabel('time (min)');
ylabel('normalized pixel intensity')
title('Chrimson(-) mice')
ylim([-100 800])

figure; 
hold all; 
ax = gca;
for mouse = 1:size(miceCumData,1)
    plot(miceCumData(mouse,:),'r','LineWidth',3);
%     plot(miceCumWvData(mouse,:),'k','LineWidth',3);
end 
%set time in x axis 
% min_TimeVals = floor(0:5:(size(AVmiceCumData,2)/FPM));
FrameVals = floor(0:(size(AVmiceCumData,2)/((size(AVmiceCumData,2)/FPM)/5)):size(AVmiceCumData,2));
ax.XTick = FrameVals;
ax.XTickLabel = min_TimeVals;
ax.FontSize = 20;
% legend('Outside vessel','Inside vessel')
xlabel('time (min)');
ylabel('normalized pixel intensity')
title('Chrimson(+) mice')
ylim([-100 800])
xlim([0 17030])



end 
 %}