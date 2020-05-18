%% get userInput
temp = matfile('SF56_20190718_ROI2_1_regIms_green.mat');
userInput = temp.userInput; 
regStacks = temp.regStacks;
numZplanes = temp.numZplanes;

temp2 = matfile('SF56_20190718_ROI2_1_calciumAndVwidthAlignedBBB_tTypes.mat');
Vdata = temp2.Vdata;
Bdata = temp2.Bdata;

%% make HDF chart 
disp('Making HDF Chart')
[imAn1funcDir] = getUserInput(userInput,'imAnalysis1_functions Directory');
cd(imAn1funcDir);
[framePeriod] = getUserInput(userInput,'What is the framePeriod? ');
[state] = getUserInput(userInput,'What teensy state does the stimulus happen in?');
[HDFchart,state_start_f,state_end_f,FPS,vel_wheel_data,TrialTypes] = makeHDFchart_redBlueStim(state,framePeriod);

%% sort data into baseline periods  
disp('Sorting Data')
%go to the right directory for functions 
[imAn1funcDir] = getUserInput(userInput,'imAnalysis1_functions Directory');
cd(imAn1funcDir);

%find the diffent trial types 
[stimTimes] = getUserInput(userInput,"Stim Time Lengths (sec)"); 
[stimTypeNum] = getUserInput(userInput,"How many different kinds of stimuli were used?");
[uniqueTrialData,uniqueTrialDataOcurr,indices,state_start_f,uniqueTrialDataTemplate] = separateTrialTypes(TrialTypes,state_start_f,state_end_f,stimTimes,numZplanes,FPS,stimTypeNum); 

%% re-initialize variables ################################
%##########################################################
%##########################################################
%##########################################################
clearvars -except Cdata state_start_f indices uniqueTrialData uniqueTrialDataOcurr numZplanes FPS 

%% continue sorting data

%sort data 
% [sortedBdata,indices] = eventTriggeredAverages2(Bdata,state_start_f,indices,uniqueTrialData,uniqueTrialDataOcurr,numZplanes);
[sortedCdata,~] = eventTriggeredAverages2(Cdata,state_start_f,indices,uniqueTrialData,uniqueTrialDataOcurr,numZplanes);
% [sortedVdata,~] = eventTriggeredAverages2(Vdata,state_start_f,indices,uniqueTrialData,uniqueTrialDataOcurr,numZplanes);

%get rid of empty cells 
% bBdata = sortedBdata{5};
% bVdata = sortedVdata{5};
bCdata = sortedCdata{5}(~cellfun('isempty',sortedCdata{5}));

%% average sorted data 

%find min length of baseline periods b/c this is our averaging window
%limiting factor 
minLen = min(cellfun('size',bCdata,2));

%get the data that falls w/in the min length window 
% bBdataAVarray = zeros(length(bBdata),minLen);
% bVdataAVarray = zeros(length(bBdata),minLen);
bCdataAVarray = zeros(length(bCdata),minLen);
for per = 1:length(bCdata)
%     bBdataAVarray(per,:) = bBdata{per}(1,1:minLen);
%     bVdataAVarray(per,:) = bVdata{per}(1,1:minLen);
    bCdataAVarray(per,:) = bCdata{per}(1,1:minLen);
end 

%average 
% avbBdata = mean(bBdataAVarray,1);
% avbVdata = mean(bVdataAVarray,1);
avbCdata = mean(bCdataAVarray,1);

%% create power spectrums of averaged baseline periods 
FPstack = FPS/numZplanes;

%compute the fourier transform 
% XB = fft(avbBdata); 
% XV = fft(avbVdata); 
XC = fft(avbCdata); 
%get length of signal 
L = length(avbCdata);
%compute the 2 sided spectrum
% XB2sided = abs(XB/L); 
% XV2sided = abs(XV/L);
XC2sided = abs(XC/L);
%comput the 1 sided spectrum based on the 2 sided spectrum 
% XB1sided = XB2sided(1:L/2+1); 
% XB1sided(2:end-1) = 2*XB1sided(2:end-1);
% XV1sided = XV2sided(1:L/2+1); 
% XV1sided(2:end-1) = 2*XV1sided(2:end-1);
XC1sided = XC2sided(1:L/2+1); 
XC1sided(2:end-1) = 2*XC1sided(2:end-1);
%define the frequency domain f 
f = FPstack*(0:(L/2))/L;            

%% jitter baseline period start times 

%ask how around how many seconds you want to jitter the baseline start
%times 
minTimeSec = minLen/FPstack;
jitterTime = input(sprintf('The minimum baseline period is %0.2f sec long. Around how many sec do you want to jitter the start time? ',minTimeSec));
%create list of how many frames ro jitter by per baseline period (normal
%distribution - mean = jitterTime. sigma = jitterTime/2) 
jitterTimes = floor(normrnd(jitterTime,jitterTime/2,[1 size(bCdataAVarray,1)]));
jitterFrames = floor(jitterTimes*FPstack);

%jitter the start times 
% Jit_bBdata = cell(1,length(bBdata));
% Jit_bVdata = cell(1,length(bBdata));
Jit_bCdata = cell(1,length(bCdata));
for per = 1:length(bCdata)
    if jitterFrames(per) > 0 
%         Jit_bBdata{per}(1:jitterFrames(per)) = NaN;
%         Jit_bBdata{per}(jitterFrames(per)+1:jitterFrames(per)+length(bBdata{per})) = bBdata{per};        
%         Jit_bVdata{per}(1:jitterFrames(per)) = NaN;
%         Jit_bVdata{per}(jitterFrames(per)+1:jitterFrames(per)+length(bVdata{per})) = bVdata{per};
        Jit_bCdata{per}(1:jitterFrames(per)) = NaN;
        Jit_bCdata{per}(jitterFrames(per)+1:jitterFrames(per)+length(bCdata{per})) = bCdata{per};
    elseif jitterFrames(per) < 0
%         Jit_bBdata{per} = bBdata{per}(abs(jitterFrames(per)):end); 
%         Jit_bVdata{per} = bVdata{per}(abs(jitterFrames(per)):end);
        Jit_bCdata{per} = bCdata{per}(abs(jitterFrames(per)):end);
    elseif jitterFrames(per) == 0
%         Jit_bBdata{per} = bBdata{per};
%         Jit_bVdata{per} = bVdata{per};
        Jit_bCdata{per} = bCdata{per};
    end 
end 

%% average jittered baseline periods 

%find min length of jittered baseline periods b/c this is our averaging window
%limiting factor 
minLenJ = min(cellfun('size',Jit_bCdata,2));

%get the data that falls w/in the min length window 
% bBdataJitAVarray = zeros(length(Jit_bBdata),minLenJ);
% bVdataJitAVarray = zeros(length(Jit_bBdata),minLenJ);
bCdataJitAVarray = zeros(length(Jit_bCdata),minLenJ);
for per = 1:length(Jit_bCdata)
%     bBdataJitAVarray(per,:) = Jit_bBdata{per}(1,1:minLenJ);
%     bVdataJitAVarray(per,:) = Jit_bVdata{per}(1,1:minLenJ);
    bCdataJitAVarray(per,:) = Jit_bCdata{per}(1,1:minLenJ);
end 

%remove rows entirely made of NaNs 
coljCNans = find(all(isnan(bCdataJitAVarray),2));
for col = 1:length(coljCNans)
    bCdataJitAVarray(coljCNans,:) = [];
end 

%average 
% Jit_avbBdata = mean(bBdataJitAVarray,1);
% Jit_avbVdata = mean(bVdataJitAVarray,1); 
Jit_avbCdata = mean(bCdataJitAVarray,1); 

%remove NaNs in averaged cols 
% [~, coljBNans] = find(isnan(Jit_avbBdata));
% jBcolStart = max(coljBNans)+1;
% Jit_avbBdata = Jit_avbBdata(jBcolStart:end);
% 
% [~, coljVNans] = find(isnan(Jit_avbVdata));
% jVcolStart = max(coljVNans)+1;
% Jit_avbVdata = Jit_avbVdata(jVcolStart:end);

[~, coljCNans] = find(isnan(Jit_avbCdata));
jCcolStart = max(coljCNans)+1;
Jit_avbCdata = Jit_avbCdata(jCcolStart:end);

%% create power spectrums of averaged baseline periods 
FPstack = FPS/numZplanes;

%compute the fourier transform 
% XJB = fft(Jit_avbBdata); 
% XJV = fft(Jit_avbVdata); 
XJC = fft(Jit_avbCdata); 
%get length of signal 
L = length(Jit_avbCdata);
%compute the 2 sided spectrum
% XJB2sided = abs(XJB/L); 
% XJV2sided = abs(XJV/L); 
XJC2sided = abs(XJC/L); 
%comput the 1 sided spectrum based on the 2 sided spectrum 
% XJB1sided = XJB2sided(1:L/2+1); 
% XJB1sided(2:end-1) = 2*XJB1sided(2:end-1);
% XJV1sided = XJV2sided(1:L/2+1); 
% XJV1sided(2:end-1) = 2*XJV1sided(2:end-1);
XJC1sided = XJC2sided(1:L/2+1); 
XJC1sided(2:end-1) = 2*XJC1sided(2:end-1);
%define the frequency domain f 
fJ = FPstack*(0:(L/2))/L;


%% plot B data 

% Frames = size(avbBdata,2);
% sec_TimeVals = floor(((0:1:Frames/FPstack)));
% FrameVals = floor(0:FPstack:Frames); 
% 
% jFrames = size(Jit_avbBdata,2);
% Jsec_TimeVals = floor(((0:1:jFrames/FPstack)));
% jFrameVals = floor(0:FPstack:jFrames); 
% 
% figure;
% %plot averaged baseline 
% subplot(2,2,1)
% ax=gca;
% plot(avbBdata,'r','LineWidth',2)
% title('average baseline BBB data');
% xlabel('time (s)')
% ylabel('z-score)')
% ax.XTick = FrameVals;
% ax.XTickLabel = sec_TimeVals;
% ax.FontSize = 15;
% %plot the frequency amplitudes of averaged baseline 
% subplot(2,2,2)
% ax2=gca;
% plot(f,XB1sided,'r','LineWidth',2); 
% title('Amplitudes as a function of frequency');
% xlabel('f (Hz)')
% ylabel('|P1(f)|')
% ax2.FontSize = 15;
% %plot jittered averaged baseline 
% subplot(2,2,3)
% ax3=gca;
% plot(Jit_avbBdata,'r','LineWidth',2)
% title({'average jittered baseline BBB data';sprintf('jittered around %d sec',jitterTime)});
% xlabel('time (s)')
% ylabel('z-score)')
% ax3.XTick = jFrameVals;
% ax3.XTickLabel = Jsec_TimeVals;
% ax3.FontSize = 15;
% %plot the frequency amplitudes of jittered averaged baseline 
% subplot(2,2,4)
% ax4 = gca;
% plot(f,XJB1sided,'r','LineWidth',2); 
% title('Amplitudes as a function of frequency');
% xlabel('f (Hz)')
% ylabel('|P1(f)|') 
% ax4.FontSize = 15;

%% plot V data 
% Frames = size(avbBdata,2);
% sec_TimeVals = floor(((0:1:Frames/FPstack)));
% FrameVals = floor(0:FPstack:Frames); 
% 
% jFrames = size(Jit_avbBdata,2);
% Jsec_TimeVals = floor(((0:1:jFrames/FPstack)));
% jFrameVals = floor(0:FPstack:jFrames); 
% 
% figure;
% %plot averaged baseline 
% subplot(2,2,1)
% ax=gca;
% plot(avbVdata,'k','LineWidth',2)
% title('average baseline vessel width data');
% xlabel('time (s)')
% ylabel('z-score)')
% ax.XTick = FrameVals;
% ax.XTickLabel = sec_TimeVals;
% ax.FontSize = 15;
% %plot the frequency amplitudes of averaged baseline 
% subplot(2,2,2)
% ax2=gca;
% plot(f,XV1sided,'k','LineWidth',2); 
% title('Amplitudes as a function of frequency');
% xlabel('f (Hz)')
% ylabel('|P1(f)|')
% ax2.FontSize = 15;
% %plot jittered averaged baseline 
% subplot(2,2,3)
% ax3=gca;
% plot(Jit_avbVdata,'k','LineWidth',2)
% title({'average jittered baseline vessel width data';sprintf('jittered around %d sec',jitterTime)});
% xlabel('time (s)')
% ylabel('z-score)')
% ax3.XTick = jFrameVals;
% ax3.XTickLabel = Jsec_TimeVals;
% ax3.FontSize = 15;
% %plot the frequency amplitudes of jittered averaged baseline 
% subplot(2,2,4)
% ax4 = gca;
% plot(f,XJV1sided,'k','LineWidth',2); 
% title('Amplitudes as a function of frequency');
% xlabel('f (Hz)')
% ylabel('|P1(f)|') 
% ax4.FontSize = 15;

%% plot C data 
Frames = size(avbCdata,2);
sec_TimeVals = floor(((0:1:Frames/FPstack)));
FrameVals = floor(0:FPstack:Frames); 

jFrames = size(Jit_avbCdata,2);
Jsec_TimeVals = floor(((0:1:jFrames/FPstack)));
jFrameVals = floor(0:FPstack:jFrames); 

figure;
%plot averaged baseline 
subplot(2,2,1)
ax=gca;
plot(avbCdata,'k','LineWidth',2)
title('average baseline calcium data');
xlabel('time (s)')
ylabel('z-score)')
ax.XTick = FrameVals;
ax.XTickLabel = sec_TimeVals;
ax.FontSize = 15;
%plot the frequency amplitudes of averaged baseline 
subplot(2,2,2)
ax2=gca;
plot(f,XC1sided,'k','LineWidth',2); 
title('Amplitudes as a function of frequency');
xlabel('f (Hz)')
ylabel('|P1(f)|')
ax2.FontSize = 15;
%plot jittered averaged baseline 
subplot(2,2,3)
ax3=gca;
plot(Jit_avbCdata,'k','LineWidth',2)
title({'average jittered baseline calcium data';sprintf('jittered around %d sec',jitterTime)});
xlabel('time (s)')
ylabel('z-score)')
ax3.XTick = jFrameVals;
ax3.XTickLabel = Jsec_TimeVals;
ax3.FontSize = 15;
%plot the frequency amplitudes of jittered averaged baseline 
subplot(2,2,4)
ax4 = gca;
plot(fJ,XJC1sided,'k','LineWidth',2); 
title('Amplitudes as a function of frequency');
xlabel('f (Hz)')
ylabel('|P1(f)|') 
ax4.FontSize = 15;