%% get just the BBB data
temp = matfile('SFWT6_20190607_ROI4_BBB.mat');
SFWT6_ROI4_Bdata = temp.BdataToPlot;

%% resample 
[RSFWT6_ROI3_Bdata,RSFWT6_ROI4_Bdata] = resampleBBBdata(SFWT6_ROI3_Bdata,SFWT6_ROI4_Bdata);
% [RSF57_ROI1_Bdata,RSF57_ROI2_Bdata] = resampleBBBdata(SF57_ROI1_Bdata,SF57_ROI2_Bdata);
% [RSF56_ROI1_Bdata,RSF56_ROI2_Bdata] = resampleBBBdata(SF56_ROI1_Bdata,SF56_ROI2_Bdata);
% [RSF53_ROI1_Bdata,RSF53_ROI2_Bdata] = resampleBBBdata(SF53_ROI1_Bdata,SF53_ROI2_Bdata);

%% average across planes in Z, ROIs, and trials
BdataToPlot = RSFWT6_ROI4_Bdata;

for Z = 1:length(BdataToPlot)
    for trialType = 1:size(BdataToPlot{Z},2)        
        if isempty(BdataToPlot{Z}{trialType}) == 0 
            for trial = 1:size(BdataToPlot{Z}{trialType},2)
                for VROI = 1:size(BdataToPlot{Z}{trialType}{trial},2)
                    BAVdataToPlot1_array{Z}{trialType}{trial}(VROI,:) = BdataToPlot{Z}{trialType}{trial}{VROI};
                    BAVdataToPlot1{Z}{trialType}{trial} = nanmean(BAVdataToPlot1_array{Z}{trialType}{trial},1);

                    BAVdataToPlot2_array{trialType}{trial}(Z,:) = BAVdataToPlot1{Z}{trialType}{trial};
                    BAVdataToPlot{trialType}{trial} = nanmean(BAVdataToPlot2_array{trialType}{trial},1);
                end 
            end 
        end 
        
    end 
end 

%average across trials
AVarray = cell(1,length(BAVdataToPlot));
AVdata = cell(1,length(BAVdataToPlot));
for trialType = 1:size(BAVdataToPlot,2)
    if isempty(BAVdataToPlot{trialType}) == 0 
        for trial = 1:size(BAVdataToPlot{trialType},2)
            AVarray{trialType}(trial,:) = BAVdataToPlot{trialType}{trial};
            AVdata{trialType} = nanmean(AVarray{trialType},1);
        end 
    end   
end    

SFWT6_ROI4av = AVdata;

clear BAVdataToPlot1_array BAVdataToPlot1 BAVdataToPlot2_array BAVdataToPlot

%% average across imaging FOVs 

for trialType = 4%1:size(SFWT6_ROI1av,2)
    SFWT6av{trialType} = (SFWT6_ROI3av{trialType} + SFWT6_ROI4av{trialType})/2;
%     SF57av{trialType} = (SF57_ROI1av{trialType} + SF57_ROI2av{trialType})/2;
%     SF56av{trialType} = SF56_ROI2av{trialType};%(SF56_ROI1av{trialType} + SF56_ROI2av{trialType})/2;
%     SF53av{trialType} = SF53_ROI1av{trialType};%(SF53_ROI1av{trialType} + SF53_ROI2av{trialType})/2;
end 
% SF63av = SF63_ROI1av;
% SF64av = SF64_ROI1av;

%% resample averaged individual mouse data 
for trialType = 1:size(SF64_ROI1av,2)
    if trialType == 1 || trialType == 3 
        goalLen = length(SF64av{1});
%         RSF58av{trialType} = resample(SF58av{trialType},goalLen,length(SF58av{trialType}));
        RSF63av{trialType} = resample(SF63av{trialType},goalLen,length(SF63av{trialType}));
%         RSF53av{trialType} = resample(SF53av{trialType},goalLen,length(SF53av{trialType}));
    elseif trialType == 2 || trialType == 4 
        goalLen = length(SF64av{4});
%         RSF58av{trialType} = resample(SF58av{trialType},goalLen,length(SF58av{trialType}));
        RSF63av{trialType} = resample(SF63av{trialType},goalLen,length(SF63av{trialType}));
%         RSF53av{trialType} = resample(SF53av{trialType},goalLen,length(SF53av{trialType}));
    end 
end 
RSF63av = SF63av;
RSFWT6av = SFWT6av;

%% put all data into the same array 
% for trialType = 1:size(SF64_ROI1av,2)
%     if isempty(RSF64av{trialType}) == 0 
%         miceData{trialType}(1,:) = RSF63av{trialType};
%         miceData{trialType}(2,:) = RSF64av{trialType};
% %         miceData{trialType}(3,:) = RSF58av{trialType};
% %         miceData{trialType}(4,:) = RSF53av{trialType};
%     end 
% end 
% 
% %% get SEM and average across mice 
% % for trialType = 1:size(SF64_ROI1av,2)
% %     varMiceData{trialType} = nanvar(miceData{trialType});
% %     avMiceData{trialType} = nanmean(miceData{trialType});
% % end 
miceData = SFWT6av;
avMiceData = SFWT6av;


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


