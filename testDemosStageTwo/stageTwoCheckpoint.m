timer = timerfindall;
delete(timer)
sca  
clc
clear display.a
clear all

%% open the monitor, display the gray color background
global display 
PsychDefaultSetup(2);
Screen('Preference','ScreenToHead',0,0,1);
Screen('Preference','ScreenToHead',1,0,2);
display.screenNumber = max(Screen('Screens'));
display.white = WhiteIndex(display.screenNumber);
display.grey = display.white / 2;
[display.window, display.windowRect] = PsychImaging('OpenWindow', display.screenNumber, display.grey,...
    [], 32, 2, [], [], kPsychNeedRetinaResolution); 
display.ifi = Screen('GetFlipInterval',display.window); 
display.topPriorityLevel = MaxPriority(display.window); 
Priority(display.topPriorityLevel);

%% initialize sound configuration
InitializePsychSound;
display.sampleFrequency = 48000;
audioPreparation;

%% start communication
display.a = arduino("/dev/ttyACM0",'Leonardo','BaudRate',115200);
display.sensorPin = 'D13';
display.waterPumpPin = 'D9';

%% Gabor presetting
%size of the gabor patch, full of the height in this case
display.gaborDimPix = display.windowRect(4)*2;
display.width = display.windowRect(3);
display.height = display.windowRect(4);

%center of diplay position
display.center = [(display.width-display.height)/2,0,(display.width+display.height)/2,display.height];

%other parameters
display.sigma = display.gaborDimPix / 5;
display.orientationTarget = 0; %vertical
display.orientationNontarget = 90; %horizontal
display.contrast = 0.7;
display.aspectRatio = 1;
display.phase = 0; 

%spatial frequency
display.numCycles = 12;
display.freq = display.numCycles / display.gaborDimPix;

%make procedural gabor texture
display.backgroundOffset = [0.5 0.5 0.5 0.0];
display.disableNorm = 1;
display.preContrastMultiplier = 0.5;
display.gabortex = CreateProceduralGabor(display.window, display.gaborDimPix, display.gaborDimPix, [],...
    display.backgroundOffset, display.disableNorm, display.preContrastMultiplier);

%make the property matrix
display.propertiesMat = [display.phase, display.freq, display.sigma, display.contrast, display.aspectRatio, 0, 0, 0];
updateVbl;
display.waitframes = 1;
display.phasePerFrame = 3 * pi;  %change the speed of grating moving

%% program variables
display.licktrial = 1;
lickTrialLimit = 150;
display.lickdata = {};
display.inVSOutData = [];
display.totalLickTimes = 0;

%% define the timers
display.tLickCounter = timer('ExecutionMode', 'fixedRate', 'Period', 0.01,...
                             'TimerFcn',@(src,event)pinStatusChanged);
%global lick report timer with 10ms period

display.tRefractory = timer('BusyMode','error','TasksToExecute',1,'StartDelay',0.1,...
    'StartFcn',@(src,event)refStart,...
    'TimerFcn',@(src,event)refEnd);

%% display UI, waiting for the initialization
infoUI();

%% counterUI
f = figure;

%total counter UI
 display.totalTrialNum = uicontrol(f,'Style','text','Units','normalized',...
    'Position',[0.1 0.75 0.15 0.17],'String','total trial number','BackgroundColor',[0 1 1],...
    'FontSize',16);
 display.totalTrialNumUI= uicontrol(f,'Style','edit','Units','normalized',...
    'Position',[0.1 0.6 0.15 0.1],'FontSize',16); 
 display.licktrialNum= uicontrol(f,'Style','text','Units','normalized',...
    'Position',[0.3 0.75 0.15 0.17],'String','lick trial number','BackgroundColor',[0 1 1],...
    'FontSize',16);
 display.lickTrialNumUI = uicontrol(f,'Style','edit','Units','normalized',...
    'Position',[0.3 0.6 0.15 0.1],'FontSize',16); 

display.lickInRWtotal = uicontrol(f,'Style','edit','Units','normalized',...
    'Position',[0.5 0.6 0.2 0.1],'FontSize',16); %replace the 0 with callback function
 display.lickInRWTitleTotal = uicontrol(f,'Style','text','Units','normalized',...
    'Position',[0.5 0.75 0.2 0.17],'String','lick in RW times   total','BackgroundColor',[1 1 1],...
    'FontSize',16);
 display.lickOutRWtotal = uicontrol(f,'Style','edit','Units','normalized',...
    'Position',[0.75 0.6 0.2 0.1],'FontSize',16); %replace the 0 with callback function
 display.lickOutRWTitleTotal = uicontrol(f,'Style','text','Units','normalized',...
    'Position',[0.75 0.75 0.2 0.17],'String','lick out RW times  total','BackgroundColor',[1 1 1],...
    'FontSize',16);

%single trial counter UI
display.lickInRWsingle = uicontrol(f,'Style','edit','Units','normalized',...
    'Position',[0.5 0.2 0.2 0.1],'FontSize',16); %replace the 0 with callback function
display.lickInRWTitleSingle = uicontrol(f,'Style','text','Units','normalized',...
    'Position',[0.5 0.35 0.2 0.17],'String','lick in RW times    single trial','BackgroundColor',[0 1 0],...
    'FontSize',16);
display.lickOutRWSingle = uicontrol(f,'Style','edit','Units','normalized',...
    'Position',[0.75 0.2 0.2 0.1],'FontSize',16); %replace the 0 with callback function
display.lickOutRWTitleSingle = uicontrol(f,'Style','text','Units','normalized',...
    'Position',[0.75 0.35 0.2 0.17],'String','lick out RW times    single trial','BackgroundColor',[1 0 0],...
    'FontSize',16);

%% 30 seconds countdown 
countDown;

%% start tic 
totalTic = tic;
display.counterTic = tic;  % tic of the lick counter 
display.inRWCounter = 0;
display.outRWCounter = 0;
display.inOrOutRW = 0; 
display.outRWCounterSingle = 0;
display.lickInRWOneTrial = 0;

%% main loop
start(display.tLickCounter);   %start the lick counter
for trialNum = 1:1000
display.outRWCounterSingle = 0;
display.lickInRWOneTrial = 0;
set(display.lickInRWsingle,'String',num2str(display.lickInRWOneTrial));
set(display.lickOutRWSingle,'String',num2str(display.outRWCounterSingle));
    if display.licktrial <= lickTrialLimit  %50min * 50 seconds / 10.1s (one trial) is approximately 297 trials
        %display.licktrial < lickTrialLimit + 1
    disp('------------------new trial-----------------------')
    fprintf('trialNum = %s\n',num2str(trialNum))
    set(display.totalTrialNumUI,'String',num2str(trialNum));
    %trialCue;      %play the auditory cue of the single trial
    trialCueControlPeriod;
    postCuePeriod; %1 second after the auditory cue is given
    visiStim;      %present the visual stimulation
    responseWindow;
    ITIperiod;      %intertrial interval
    fprintf('In this trial, lick in RW = %s times! ',num2str(display.lickInRWOneTrial));
    fprintf('lick out of RW = %s times! \n',num2str(display.outRWCounterSingle));
    display.inVSOutData(trialNum,1) = trialNum;
    display.inVSOutData(trialNum,2) = display.lickInRWOneTrial;
    display.inVSOutData(trialNum,3) = display.outRWCounterSingle;
    else
        break
    end
end
stop(display.tLickCounter);
delete(display.tLickCounter);
disp('---------------------finished: 50 licked trials!---------------')
totalTime = toc(totalTic);
totalLickTimes = 0;
for i = 1 : numel(display.lickdata)
    totalLickTimes = totalLickTimes + length(display.lickdata{i});
end
fprintf('>> total time cost:  %s minutes %s seconds \n',num2str(floor((totalTime)/60)),num2str(mod(totalTime,60)));
fprintf('>> total lick times: %s times \n',num2str(display.inRWCounter));
display.lickdata
display.inVSOutData
save display

%% functions
function infoUI(~,~)
 global display
 prompt = {'mouseID', 'trainStage', 'dayNumber', 'saveDir'};
 dlgtitle = 'mouse information';
 dims = [1 35];
 definput = {'', '', '', '/Users/liuqr/files/MATLAB相关/code ref/test code'};
 display.mouseID = inputdlg(prompt, dlgtitle, dims, definput);
end

function updateVbl(~,~)
 global display
 display.vbl = Screen('Flip',display.window);
 display.vblt0 = display.vbl;
end

function trialCue(~,~)
global display
display.audioHandle = PsychPortAudio('Open',0,1,1,display.sampleFrequency,2); %use PsychPortAudio('GetDevices') to find UR12, and change the first number with UR12 number
PsychPortAudio('Volume',display.audioHandle,0.1);  %last number represents volume ratio
[myBeep,samplingRate] = MakeBeep(10000,0.1,display.sampleFrequency); %first number is beep frequency, second number is time length
PsychPortAudio('FillBuffer',display.audioHandle,[myBeep;myBeep]);
PsychPortAudio('Start',display.audioHandle,1,0,1);
[startTime, endPositionSecs, xruns, estStopTime] =PsychPortAudio('Stop',display.audioHandle,1,1);
PsychPortAudio('Close',display.audioHandle);
disp('>>Trial Cue ended!! Post-cue period starts!!')
end

function visiStim(~,~)
  global display
  updateVbl;
  VSLength = 1; %visual stimulation in the first second
  while display.vbl - display.vblt0 < VSLength
  Screen('DrawTextures', display.window, display.gabortex, [], [], display.orientationTarget, [], [], [], [],...
        kPsychDontDoRotation, display.propertiesMat');
  display.vbl = Screen('Flip', display.window, display.vbl + (display.waitframes - 0.5) * display.ifi);
  display.propertiesMat(1) = display.propertiesMat(1) + display.phasePerFrame;
  end
  updateVbl;
  disp('>>Visual stimulation ended!! Response window starts!!')
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

function responseWindow(~,~)
global display
 display.rwTime = tic;
 display.inOrOutRW = 1;  %set as true
 RWLength = 4;    %the RW last for 4 seconds
  while toc(display.rwTime) < RWLength
%      lick = readDigitalPin(display.a,'D13');
%      if lick == true && lickFlag == true
%          writeDigitalPin(display.a,'D9',1);
%          lickFlag = false;
%          writeDigitalPin(display.a,'D9',0);
%          pause(0.1);  %refractory period of water pump 
%      end
%      if lickFlag == false     
%          if trialFlag == true %this if block is used for licktrial increment
%             trialFlag = false;
%          display.licktrial = display.licktrial + 1;
%          fprintf('licktrial = %s\n',num2str(display.licktrial));
%          end
%         lickFlag = true;
%         lickTimesReporter = lickTimesReporter + 1; %count the lick times in a single licked trial
%         tocReporter = toc(rwTime);
%         fprintf('licktime = %s  @%s second \n',num2str(lickTimesReporter),num2str(tocReporter));
% 
%         %save the data in pre-allocating matrix
%         display.lickdata{display.licktrial}(lickTimesReporter,1) = lickTimesReporter;
%         display.lickdata{display.licktrial}(lickTimesReporter,2) = tocReporter;
%      end        
  end
  if display.lickInRWOneTrial > 0
      display.licktrial = display.licktrial + 1;
  end
display.inOrOutRW = 0;   %reset the inOrOutRW
disp('>>Response window ended!! ITI start!')
end

function pinStatusChanged(~,~)
global display
    RWflag = display.inOrOutRW;
    lickFlag = true;
    trialFlag = true;
    lickTimesReporter = 0;
    pinValue = readDigitalPin(display.a,display.sensorPin);
    if pinValue == true && lickFlag == true
        switch RWflag
            case 0
                display.outRWCounter = display.outRWCounter + 1;
                display.outRWCounterSingle = display.outRWCounterSingle + 1;
                set(display.lickOutRWtotal,'String',num2str(display.outRWCounter));
                set(display.lickOutRWSingle,'String',num2str(display.outRWCounterSingle));
                fprintf('Lick out of RW in this trial: %s  total: %s \n',...
                    num2str(display.outRWCounterSingle),num2str(display.outRWCounter));               
                start(display.tRefractory);
            case 1
                display.inRWCounter = display.inRWCounter + 1;
                set(display.lickInRWtotal,'String',num2str(display.inRWCounter));
                if display.lickInRWOneTrial < 1   %only the first two licks are rewarded
                   writeDigitalPin(display.a,'D9',1);
                end
                fprintf('lick in RW %s ',num2str(display.inRWCounter));
                start(display.tRefractory);
                lickFlag = false;     
           if lickFlag == false
             if trialFlag == true
             trialFlag = false;
             fprintf('licktrial = %s ',num2str(display.licktrial));
             set(display.lickTrialNumUI,'String',num2str(display.licktrial));
             end
             lickTimesReporter = lickTimesReporter + 1;
             display.lickInRWOneTrial = display.lickInRWOneTrial + lickTimesReporter;
             tocReporter = toc(display.rwTime);
             set(display.lickInRWsingle,'String',num2str(display.lickInRWOneTrial));
             fprintf('licktime = %s  @%s seconds \n',num2str(display.lickInRWOneTrial),num2str(tocReporter));
             display.lickdata{display.licktrial}(display.lickInRWOneTrial,1) = display.lickInRWOneTrial;
             display.lickdata{display.licktrial}(display.lickInRWOneTrial,2) = tocReporter;
          end
        end
    end
end

function refStart(~,~)
    global display
      stop(display.tLickCounter);
      %disp('timer 1 stopped by timer-2 StartFcn');
      writeDigitalPin(display.a,'D9',0);
end

function refEnd(~,~)
    global display
    start(display.tLickCounter);
    stop(display.tRefractory);
end

function postCuePeriod(~,~)
    postCueDelay = 1;
    postCueTime = tic;
    while toc(postCueTime) <= postCueDelay
    end
    disp('>>post-cue period finished!!!')
end

function trialCueControlPeriod(~,~)
   cueControlPeriod = 0.1;
    cueControl = tic;
    while toc(cueControl) <= cueControlPeriod
    end
    disp('>>trail cue control period finished!!!')
end

function ITIperiod(~,~)
    ITIdelay = 4;
    ITITime = tic;
    while toc(ITITime) <= ITIdelay
    end
    disp('>> ITI period finished!!!')
end

function audioPreparation
  global display
   for i = 1:5
pahandle = PsychPortAudio('Open', 0, 1, 1, display.sampleFrequency, 2);

%the first number represents individual devices, use PsychPortAudio('GetDevices') to
%check which is the UR12

% Set the volume
PsychPortAudio('Volume', pahandle, 0.1);

% Make a beep which we will play back to the user
 [myBeep, samplingRate] = MakeBeep(i*1000, 0.1, display.sampleFrequency);
 PsychPortAudio('FillBuffer', pahandle, [myBeep; myBeep]);

% Show audio playback
 PsychPortAudio('Start', pahandle, 1, 0, 1);
 [startTime, endPositionSecs, xruns, estStopTime] = PsychPortAudio('Stop', pahandle, 1, 1);

% Close the audio device
 PsychPortAudio('Close', pahandle);
end
end