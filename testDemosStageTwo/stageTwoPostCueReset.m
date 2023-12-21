%% in this program, several new functions are added 
% 1. timer reset if early-lick happened in post-cue period      check
% 2. time length for single trial is saved in the data matrix      
% 3. the hit trial information will be saved in the data matrix
% 4. possible output for the trial collection raster ??
timer = timerfindall;
delete(timer)
sca  
clc
clear h.a
clear all

%% open the monitor, h the gray color background
global h 
PsychDefaultSetup(2);
%Screen('Preference','ScreenToHead',0,0,1);
Screen('Preference','ScreenToHead',1,0,2);
h.screenNumber = max(Screen('Screens'));
h.white = WhiteIndex(h.screenNumber);
h.grey = h.white / 2;
[h.window, h.windowRect] = PsychImaging('OpenWindow', h.screenNumber, h.grey,...
    [], 32, 2, [], [], kPsychNeedRetinaResolution); 
h.ifi = Screen('GetFlipInterval',h.window); 
h.topPriorityLevel = MaxPriority(h.window); 
Priority(h.topPriorityLevel);

%% initialize sound configuration
InitializePsychSound;
h.sampleFrequency = 48000;
audioPreparation;

%% start communication
h.a = arduino("/dev/ttyACM0",'Leonardo','BaudRate',115200);
h.sensorPin = 'D13';
h.waterPumpPin = 'D9';

%% Gabor presetting
%size of the gabor patch, full of the height in this case
h.gaborDimPix = h.windowRect(4)*2;
h.width = h.windowRect(3);
h.height = h.windowRect(4);

%center of diplay position
h.center = [(h.width-h.height)/2,0,(h.width+h.height)/2,h.height];

%other parameters
h.sigma = h.gaborDimPix / 4;
h.orientationTarget = 0; %vertical
h.orientationNontarget = 90; %horizontal
h.contrast = 1;
h.aspectRatio = 1;
h.phase = 0; 

%spatial frequency
h.numCycles = 12;
h.freq = h.numCycles / h.gaborDimPix;

%make procedural gabor texture
h.backgroundOffset = [0.5 0.5 0.5 0.0];
h.disableNorm = 1;
h.preContrastMultiplier = 0.5;
h.gabortex = CreateProceduralGabor(h.window, h.gaborDimPix, h.gaborDimPix, [],...
    h.backgroundOffset, h.disableNorm, h.preContrastMultiplier);

%make the property matrix
h.propertiesMat = [h.phase, h.freq, h.sigma, h.contrast, h.aspectRatio, 0, 0, 0];
updateVbl;
h.waitframes = 1;
h.phasePerFrame = 4 * pi;  %change the speed of grating moving

%% program variables
h.licktrial = 1;
lickTrialLimit = 150;
h.lickdata = {};
h.inVSOutData = [];
h.totalLickTimes = 0;

%% define the timers
h.tLickCounter = timer('ExecutionMode', 'fixedRate', 'Period', 0.01,...
                             'TimerFcn',@(src,event)pinStatusChanged);
%global lick report timer with 10ms period

h.tRefractory = timer('BusyMode','error','TasksToExecute',1,'StartDelay',0.1,...
    'StartFcn',@(src,event)refStart,...
    'TimerFcn',@(src,event)refEnd);

%% h UI, waiting for the initialization
infoUI();

%% counterUI
f = figure;

%total counter UI
 h.totalTrialNum = uicontrol(f,'Style','text','Units','normalized',...
    'Position',[0.1 0.75 0.15 0.17],'String','total trial number','BackgroundColor',[0 1 1],...
    'FontSize',16);
 h.totalTrialNumUI= uicontrol(f,'Style','edit','Units','normalized',...
    'Position',[0.1 0.6 0.15 0.1],'FontSize',16); 
 h.licktrialNum= uicontrol(f,'Style','text','Units','normalized',...
    'Position',[0.3 0.75 0.15 0.17],'String','lick trial number','BackgroundColor',[0 1 1],...
    'FontSize',16);
 h.lickTrialNumUI = uicontrol(f,'Style','edit','Units','normalized',...
    'Position',[0.3 0.6 0.15 0.1],'FontSize',16); 

  h.hitTrialNum = uicontrol(f,'Style','text','Units','normalized',...
    'Position',[0.17 0.35 0.2 0.17],'String','Hit trial number','BackgroundColor',[1 1 0],...
    'FontSize',16);
 h.hitTrialNumUI= uicontrol(f,'Style','edit','Units','normalized',...
    'Position',[0.17 0.2 0.2 0.1],'FontSize',16); 
%  h.earlyTrialNum= uicontrol(f,'Style','text','Units','normalized',...
%     'Position',[0.3 0.35 0.15 0.17],'String','early lick trial number','BackgroundColor',[1 0 0],...
%     'FontSize',16);
%  h.earlyTrialUI = uicontrol(f,'Style','edit','Units','normalized',...
%     'Position',[0.3 0.2 0.15 0.1],'FontSize',16); 

h.lickInRWtotal = uicontrol(f,'Style','edit','Units','normalized',...
    'Position',[0.5 0.6 0.2 0.1],'FontSize',16); %replace the 0 with callback function
 h.lickInRWTitleTotal = uicontrol(f,'Style','text','Units','normalized',...
    'Position',[0.5 0.75 0.2 0.17],'String','lick in RW times   total','BackgroundColor',[1 1 1],...
    'FontSize',16);
 h.lickOutRWtotal = uicontrol(f,'Style','edit','Units','normalized',...
    'Position',[0.75 0.6 0.2 0.1],'FontSize',16); %replace the 0 with callback function
 h.lickOutRWTitleTotal = uicontrol(f,'Style','text','Units','normalized',...
    'Position',[0.75 0.75 0.2 0.17],'String','lick out RW times  total','BackgroundColor',[1 1 1],...
    'FontSize',16);

%single trial counter UI
h.lickInRWsingle = uicontrol(f,'Style','edit','Units','normalized',...
    'Position',[0.5 0.2 0.2 0.1],'FontSize',16); %replace the 0 with callback function
h.lickInRWTitleSingle = uicontrol(f,'Style','text','Units','normalized',...
    'Position',[0.5 0.35 0.2 0.17],'String','lick in RW times    single trial','BackgroundColor',[0 1 0],...
    'FontSize',16);
h.lickOutRWSingle = uicontrol(f,'Style','edit','Units','normalized',...
    'Position',[0.75 0.2 0.2 0.1],'FontSize',16); %replace the 0 with callback function
h.lickOutRWTitleSingle = uicontrol(f,'Style','text','Units','normalized',...
    'Position',[0.75 0.35 0.2 0.17],'String','lick out RW times    single trial','BackgroundColor',[1 0 0],...
    'FontSize',16);

%% 3 minutes countdown 
%countDown;

%% start tic 
totalTic = tic;                               
h.inRWCounter = 0;
h.outRWCounter = 0;
h.outRWCounterSingle = 0;
h.lickInRWOneTrial = 0;
h.hitTrialNumber = 0;
h.earlyTrialNumber = 0;

%% main loop
start(h.tLickCounter);   %start the lick counter
for trialNum = 1:1000
    if strcmp(h.tRefractory.Running,'on')
        stop(h.tRefractory);
    end                                             %stop the tRefractory
stop(h.tLickCounter)
h.outRWCounterSingle = 0;
h.lickInRWOneTrial = 0;
set(h.lickInRWsingle,'String',num2str(h.lickInRWOneTrial));
set(h.lickOutRWSingle,'String',num2str(h.outRWCounterSingle));

    if trialNum <= 300  % within 300 trials (about 50 mins)
    h.trialGlobalTic = tic;
    disp('------------------new trial-----------------------')
    fprintf('trialNum = %s\n',num2str(trialNum))
    set(h.totalTrialNumUI,'String',num2str(trialNum));

    trialCue;      %play the auditory cue of the single trial
    postCuePeriod; %1 second after the auditory cue is given
    visiStim;      %present the visual stimulation
    responseWindow;
    ITIperiod;      %intertrial interval

    fprintf('In this trial, lick in RW = %s times! ',num2str(h.lickInRWOneTrial));
    fprintf('lick out of RW = %s times! \n',num2str(h.outRWCounterSingle));
    h.inVSOutData(trialNum,1) = trialNum;
    h.inVSOutData(trialNum,2) = h.lickInRWOneTrial;
    h.inVSOutData(trialNum,3) = h.outRWCounterSingle;
    h.inVSOutData(trialNum,4) = toc(h.trialGlobalTic);     %time length for individual trials
    else
        break
    end
end
stop(h.tLickCounter);
delete(h.tLickCounter);
delete(h.tRefractory);
disp('---------------------finished: 50 licked trials!---------------')
totalTime = toc(totalTic);
totalLickTimes = 0;
for i = 1 : numel(h.lickdata)
    totalLickTimes = totalLickTimes + length(h.lickdata{i});
end
fprintf('>> total time cost:  %s minutes %s seconds \n',num2str(floor((totalTime)/60)),num2str(mod(totalTime,60)));
fprintf('>> total lick times: %s times \n',num2str(h.inRWCounter));
h.lickdata
h.inVSOutData
save h

%% functions
function infoUI(~,~)
 global h
 prompt = {'mouseID', 'trainStage', 'dayNumber', 'saveDir'};
 dlgtitle = 'mouse information';
 dims = [1 35];
 definput = {'', '', '', '/Users/liuqr/files/MATLAB相关/code ref/test code'};
 h.mouseID = inputdlg(prompt, dlgtitle, dims, definput);
end

function updateVbl(~,~)
 global h
 h.vbl = Screen('Flip',h.window);
 h.vblt0 = h.vbl;
end

function countDown(~,~)
 countdownDuration = 180;
 disp('---------Countdown started...check the mouse and lick spout!!!--------------------')

 for remainingSeconds = countdownDuration :-1 :0
     fprintf('Time remaining: %d seconds \n',remainingSeconds);
     pause(1);
 end
 disp('Countdown finished! Start conditioning!')
end

%% trial procedure functions
function trialCue(~,~)
global h
h.audioHandle = PsychPortAudio('Open',0,1,1,h.sampleFrequency,2); %use PsychPortAudio('GetDevices') to find UR12, and change the first number with UR12 number
PsychPortAudio('Volume',h.audioHandle,0.1);  %last number represents volume ratio
[myBeep,samplingRate] = MakeBeep(10000,0.1,h.sampleFrequency); %first number is beep frequency, second number is time length
PsychPortAudio('FillBuffer',h.audioHandle,[myBeep;myBeep]);
PsychPortAudio('Start',h.audioHandle,1,0,1);
[startTime, endPositionSecs, xruns, estStopTime] =PsychPortAudio('Stop',h.audioHandle,1,1);
PsychPortAudio('Close',h.audioHandle);
disp('>>Trial Cue ended!! Post-cue period starts!!')
end

function postCuePeriod(~,~)
global h
    h.inOrOutRW = -1;  %inOrOutRW value: postCuePeriod -1, RW 1, Visi and ITI 0.
    start(h.tLickCounter); 
    postCueDelay = 1;
    h.postCueTime = tic;
    while toc(h.postCueTime) <= postCueDelay
    end
    disp('>>post-cue period finished!!!')
end

function visiStim(~,~)
  global h
  h.inOrOutRW = 0; 
  updateVbl;
  VSLength = 1; %visual stimulation in the first second
  while h.vbl - h.vblt0 < VSLength
  Screen('DrawTextures', h.window, h.gabortex, [], [], h.orientationTarget, [], [], [], [],...
        kPsychDontDoRotation, h.propertiesMat');
  h.vbl = Screen('Flip', h.window, h.vbl + (h.waitframes - 0.5) * h.ifi);
  h.propertiesMat(1) = h.propertiesMat(1) + h.phasePerFrame;
  end
  updateVbl;
  disp('>>Visual stimulation ended!! Response window starts!!')
end

function responseWindow(~,~)
global h
 h.rwTime = tic;
 h.inOrOutRW = 1;  %set as true
 RWLength = 4;    %the RW last for 4 seconds
  while toc(h.rwTime) < RWLength   
  end
  if h.lickInRWOneTrial > 0
      h.licktrial = h.licktrial + 1;
  end
h.inOrOutRW = 0;   %reset the inOrOutRW
disp('>>Response window ended!! ITI start!')
end

function ITIperiod(~,~)
    ITIdelay = 4;
    ITITime = tic;
    while toc(ITITime) <= ITIdelay
    end
    disp('>> ITI period finished!!!')
end

function pinStatusChanged(~,~)
global h
    RWflag = h.inOrOutRW;
    lickFlag = true;
    trialFlag = true;
    lickTimesReporter = 0;
    pinValue = readDigitalPin(h.a,h.sensorPin);
    if pinValue == true && lickFlag == true
        switch RWflag
            case 1 % lick in RW
                h.inRWCounter = h.inRWCounter + 1;
                set(h.lickInRWtotal,'String',num2str(h.inRWCounter));
                if h.lickInRWOneTrial < 1   %only the first  lick is rewarded
                    % && h.outRWCounterSingle == 0        #if only when the
                    % first hit in RW is rewarded, add this limitation
                   writeDigitalPin(h.a,'D9',1);
                   h.hitTrialNumber = h.hitTrialNumber + 1;
                   set(h.hitTrialNumUI,'String',num2str(h.hitTrialNumber))
                else
                   %h.earlyTrialNumber = h.earlyTrialNumber + 1;
                end
                fprintf('lick in RW %s ',num2str(h.inRWCounter));
                start(h.tRefractory);
                lickFlag = false;     
           if lickFlag == false
             if trialFlag == true
             trialFlag = false;
             fprintf('licktrial = %s ',num2str(h.licktrial));
             set(h.lickTrialNumUI,'String',num2str(h.licktrial));
             end
             lickTimesReporter = lickTimesReporter + 1;
             h.lickInRWOneTrial = h.lickInRWOneTrial + lickTimesReporter;
             tocReporter = toc(h.rwTime);
             set(h.lickInRWsingle,'String',num2str(h.lickInRWOneTrial));
             fprintf('licktime = %s  @%s seconds \n',num2str(h.lickInRWOneTrial),num2str(tocReporter));
             h.lickdata{h.licktrial}(h.lickInRWOneTrial,1) = h.lickInRWOneTrial;
             h.lickdata{h.licktrial}(h.lickInRWOneTrial,2) = tocReporter;
           end

            otherwise
                if RWflag == -1                                                                            % early lick reset the post-cue period timer
                    h.postCueTime = tic;
                    disp('!!Early lick! Reset post cue period timer!!')
                end
                h.outRWCounter = h.outRWCounter + 1;
                h.outRWCounterSingle = h.outRWCounterSingle + 1;
                set(h.lickOutRWtotal,'String',num2str(h.outRWCounter));
                set(h.lickOutRWSingle,'String',num2str(h.outRWCounterSingle));
                fprintf('Lick out of RW in this trial: %s  total: %s \n',...
                    num2str(h.outRWCounterSingle),num2str(h.outRWCounter));  
                start(h.tRefractory);
        end
    end
end

function refStart(~,~)
    global h
      stop(h.tLickCounter);
      %disp('timer 1 stopped by timer-2 StartFcn');
      writeDigitalPin(h.a,'D9',0);
end

function refEnd(~,~)
    global h
    start(h.tLickCounter);
    stop(h.tRefractory);
end

function audioPreparation
  global h
   for i = 1:5
pahandle = PsychPortAudio('Open', 0, 1, 1, h.sampleFrequency, 2);

%the first number represents individual devices, use PsychPortAudio('GetDevices') to
%check which is the UR12

% Set the volume
PsychPortAudio('Volume', pahandle, 0.1);

% Make a beep which we will play back to the user
 [myBeep, samplingRate] = MakeBeep(10000, 0.1, h.sampleFrequency);
 PsychPortAudio('FillBuffer', pahandle, [myBeep; myBeep]);

% Show audio playback
 PsychPortAudio('Start', pahandle, 1, 0, 1);
 [startTime, endPositionSecs, xruns, estStopTime] = PsychPortAudio('Stop', pahandle, 1, 1);

% Close the audio device
 PsychPortAudio('Close', pahandle);
end
end