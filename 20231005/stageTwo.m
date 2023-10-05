clear all
sca
clc

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


%% start communication
display.a = arduino("/dev/ttyACM0",'Leonardo','BaudRate',115200);

%% Gabor presetting
%size of the gabor patch, full of the height in this case
display.gaborDimPix = display.windowRect(4);
display.width = display.windowRect(3);
display.height = display.windowRect(4);

%center of diplay position
display.center = [(display.width-display.height)/2,0,(display.width+display.height)/2,display.height];

%other parameters
display.sigma = display.gaborDimPix / 7;
display.orientationTarget = 0; %vertical
display.orientationNontarget = 90; %horizontal
display.contrast = 0.5;
display.aspectRatio = 1.0;
display.phase = 0; 

%spatial frequency
display.numCycles = 10;
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
display.phasePerFrame = 4 * pi;  %change the speed of grating moving

%% program variables
display.licktrial = 0;

%set the trial limit and the empty data
display.lickdata = cell(100,1);
lickTrialLimit = 100;
display.totalLickTimes = 0;

%% display UI, waiting for the initialization
infoUI();

%% 30 seconds countdown 
countDown;

%% start tic and main loop
totalTic = tic;
%main loop
for trialNum = 1:1000 
    if display.licktrial < lickTrialLimit
    disp('------------------new trial-----------------------')
    fprintf('trialNum = %s\n',num2str(trialNum))
    trialCue; %play the auditory cue of the single trial
    pause(1);%1 second after the auditory cue is given
    visiStim; %present the visual stimulation
    responseWindow;
    pause(4); %intertrial interval
    
    else
        break
    end
end

disp('---------------------finished: 150 time licked!---------------')
totalTime = toc(totalTic);
totalLickTimes = 0;
for i = 1 : numel(display.lickdata)
    totalLickTimes = totalLickTimes + length(display.lickdata{i});
end
fprintf('>> total time cost:  %s minutes %s seconds \n',num2str(floor((totalTime)/60)),num2str(mod(totalTime,60)));
fprintf('>> total lick times: %s times \n',num2str(totalLickTimes));

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
display.audioHandle = PsychPortAudio('Open',11,1,1,display.sampleFrequency,2);
PsychPortAudio('Volume',display.audioHandle,0.1);  %last number represents volume ratio
[myBeep,samplingRate] = MakeBeep(10000,0.1,display.sampleFrequency); %first number is beep frequency, second number is time length
PsychPortAudio('FillBuffer',display.audioHandle,[myBeep;myBeep]);
PsychPortAudio('Start',display.audioHandle,1,0,1);
[startTime, endPositionSecs, xruns, estStopTime] =PsychPortAudio('Stop',display.audioHandle,1,1);
PsychPortAudio('Close',display.audioHandle);
end

function visiStim(~,~)
  global display
  updateVbl;
  VSLength = 1; %visual stimulation in the first second
  while display.vbl - display.vblt0 < VSLength
  Screen('DrawTextures', display.window, display.gabortex, [], display.center, display.orientationTarget, [], [], [], [],...
        kPsychDontDoRotation, display.propertiesMat');
  display.vbl = Screen('Flip', display.window, display.vbl + (display.waitframes - 0.5) * display.ifi);
  display.propertiesMat(1) = display.propertiesMat(1) + display.phasePerFrame;
  end
  updateVbl;
end

function countDown(~,~)
 countdownDuration = 10;
 disp('---------Countdown started...check the mouse and lick spout!!!--------------------')

 for remainingSeconds = countdownDuration :-1 :0
     fprintf('Time remaining: %d seconds \n',remainingSeconds);
     pause(1);
 end
 disp('Countdown finished! Start conditioning!')
end

function responseWindow(~,~)
global display
 lickFlag = true;
 rwTime = tic;
 trialFlag = true;
 lickTimesReporter = 0;
 RWLength = 4;    %the RW last for 4 seconds

  while toc(rwTime) < RWLength
     lick = readDigitalPin(display.a,'D13');
     if lick == true && lickFlag == true
         writeDigitalPin(display.a,'D9',1);
         lickFlag = false;
         writeDigitalPin(display.a,'D9',0);
         pause(0.1);  %refractory period of water pump 
     end
     if lickFlag == false     
         if trialFlag == true %this if block is used for licktrial increment
            trialFlag = false;
         display.licktrial = display.licktrial + 1;
         fprintf('licktrial = %s\n',num2str(display.licktrial));
         end
        lickFlag = true;
        lickTimesReporter = lickTimesReporter + 1; %count the lick times in a single licked trial
        tocReporter = toc(rwTime);
        fprintf('licktime = %s  @%s second \n',num2str(lickTimesReporter),num2str(tocReporter));

        %save the data in pre-allocating matrix
        display.lickdata{display.licktrial}(lickTimesReporter,1) = lickTimesReporter;
        display.lickdata{display.licktrial}(lickTimesReporter,2) = tocReporter;
     end        

  end
display.totalLickTimes = display.totalLickTimes + lickTimesReporter;
end
