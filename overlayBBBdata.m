%% get just the BBB data
temp = matfile('63-64_70FITC_BBB.mat');
DAT_GCaMP_data = temp.miceData;

%% resample miceData 
resampThisData = DAT_GCaMP_data;

for trialType = 1:4 
    if trialType == 1 || trialType == 3 
        goalLength = length(DAT_Chrimson_GCaMP_data{1});
    elseif trialType == 2 || trialType == 4 
        goalLength = length(DAT_Chrimson_GCaMP_data{4});  
    end 
    for mouse = 1:size(resampThisData{trialType},1)
        R_DAT_GCaMP_data{trialType}(mouse,:) = resample(DAT_GCaMP_data{trialType}(mouse,:),goalLength,length(DAT_GCaMP_data{trialType}));
    end 
end 

%% normalize data to baseline period - plot % change 
%R_DAT_Chrimson_GCaMP_data
%R_DAT_GCaMP_data
%R_DAT_Chrimson_data
%R_WT_data

normThisData = R_WT_data;

baselineEnd = (FPS/3)*20;
for trialType = 1:4
    for mouse = 1:size(normThisData{trialType},1)
        N_WT_data{trialType}(mouse,:) = (normThisData{trialType}(mouse,:)-mean(normThisData{trialType}(mouse,1:baselineEnd)))/(mean(normThisData{trialType}(mouse,1:baselineEnd)));
    end 
end 



%% smooth data if you want 
smoothQ = input('Do you want to smooth your data? Yes = 1. No = 0. ');

if smoothQ == 1 
    filtTime = input('How many seconds do you want to smooth your data by? '); 
    
    for trialType = 1:size(avMiceData,2)   
        if isempty(avMiceData{trialType}) == 0                  
%             [VfiltD] = MovMeanSmoothData(avMiceData{trialType},filtTime,FPS);
            [VfiltD] = MovMeanSmoothData(miceData{trialType},filtTime,FPS);
%             [VfiltV] = MovMeanSmoothData(varMiceData{trialType},filtTime,FPS);
            VfiltData{trialType} = VfiltD;   
%             VfiltVar{trialType} = VfiltV; 
        end 
    end
     
elseif smoothQ == 0

    for trialType = 1:size(avMiceData,2)   
        if isempty(avMiceData{trialType}) == 0                           
            VfiltData{trialType} = avMiceData{trialType};   
%             VfiltVar{trialType} = varMiceData{trialType};
        end 
    end
    
end


 %% get SEM and average across mice 

for trialType = 1:size(SF64_ROI1av,2)
    varMiceData{trialType} = nanvar(miceData{trialType});
    avMiceData{trialType} = nanmean(miceData{trialType});
end 
miceData = SFWT6av;
avMiceData = SFWT6av;

%% plot
dataMin = input("data Y axis MIN: ");
dataMax = input("data Y axis MAX: ");
FPSstack = FPS;
baselineEndFrame = round(20*(FPSstack));



for trialType = 1:size(miceData,2)  
    if isempty(miceData{trialType}) == 0

        figure;
        %set time in x axis            
        if trialType == 1 || trialType == 3 
            Frames = size(miceData{trialType}(1,:),2);                
            Frames_pre_stim_start = -((Frames-1)/2); 
            Frames_post_stim_start = (Frames-1)/2; 
            sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack*2:Frames_post_stim_start)/FPSstack)+2);
            FrameVals = round((1:FPSstack*2:Frames)-1); 
        elseif trialType == 2 || trialType == 4 
            Frames = size(miceData{trialType}(1,:),2);
            Frames_pre_stim_start = -((Frames-1)/2); 
            Frames_post_stim_start = (Frames-1)/2; 
            sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack*2:Frames_post_stim_start)/FPSstack)+10);
            FrameVals = round((1:FPSstack*2:Frames)-1); 
        end 
        ax=gca;
        plot(VfiltData{trialType},'r','LineWidth',2)
        hold all;     

%         varargout = boundedline(1:size(VfiltData{trialType},2),VfiltData{trialType},VfiltVar{trialType},'r','transparency', 0.3,'alpha');                                                                             

        ax.XTick = FrameVals;
        ax.XTickLabel = sec_TimeVals;
        ax.FontSize = 20;
        if trialType == 1 
            plot([round(baselineEndFrame+((FPSstack)*2)) round(baselineEndFrame+((FPSstack)*2))], [-5000 5000], 'b','LineWidth',3)
            %patch([baselineEndFrame round(baselineEndFrame+((FPSstack/numZplanes)*2)) round(baselineEndFrame+((FPSstack/numZplanes)*2)) baselineEndFrame],[-5000 -5000 5000 5000],'b')
            %alpha(0.4)   
            plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'b','LineWidth',3) 
        elseif trialType == 3 
            plot([round(baselineEndFrame+((FPSstack)*2)) round(baselineEndFrame+((FPSstack)*2))], [-5000 5000], 'r','LineWidth',3)
            %patch([baselineEndFrame round(baselineEndFrame+((FPSstack/numZplanes)*2)) round(baselineEndFrame+((FPSstack/numZplanes)*2)) baselineEndFrame],[-5000 -5000 5000 5000],'r')
            %alpha(0.4)     
            plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'r','LineWidth',3) 
        elseif trialType == 2 
            plot([round(baselineEndFrame+((FPSstack)*20)) round(baselineEndFrame+((FPSstack)*20))], [-5000 5000], 'b','LineWidth',3)
            %patch([baselineEndFrame round(baselineEndFrame+((FPSstack/numZplanes)*20)) round(baselineEndFrame+((FPSstack/numZplanes)*20)) baselineEndFrame],[-5000 -5000 5000 5000],'b')
            %alpha(0.4)   
            plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'b','LineWidth',3) 
        elseif trialType == 4 
            plot([round(baselineEndFrame+((FPSstack)*20)) round(baselineEndFrame+((FPSstack)*20))], [-5000 5000], 'r','LineWidth',3)
            %patch([baselineEndFrame round(baselineEndFrame+((FPSstack/numZplanes)*20)) round(baselineEndFrame+((FPSstack/numZplanes)*20)) baselineEndFrame],[-5000 -5000 5000 5000],'r')
            %alpha(0.4)  
            plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'r','LineWidth',3) 
        end

%         legend('BBB','DA Calcium','Vessel Width')
%             legend('BBB','Vessel Width')
        ylim([dataMin dataMax]);

        if smoothQ == 1 
            title(sprintf('BBB data across mice smoothed by %d seconds.',filtTime));
        elseif smoothQ == 0
            title("Raw BBB data across mice.");
        end 

    end                       
end