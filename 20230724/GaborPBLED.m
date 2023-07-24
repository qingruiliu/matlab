%%This demo presents a drifting Gabor patch at the left side of the screen 4 times
%%The combination of PTB-3 functions and the 'timer' function in MATLAB is the point of this demo.
%% 2023.7.13 Qingrui Liu @UTokyo

%PTB-3 presetting
%-------------------------------
sca;
close all;
clear;

global display 
PsychDefaultSetup(2);
Screen('Preference','SkipSyncTests',1);
display.screenNumber = max(Screen('Screens'));
display.white = WhiteIndex(display.screenNumber);
display.grey = display.white / 2;

[display.window, display.windowRect] = PsychImaging('OpenWindow', display.screenNumber, display.grey,...
    [], 32, 2, [], [], kPsychNeedRetinaResolution); 
display.ifi = Screen('GetFlipInterval',display.window);
display.topPriorityLevel = MaxPriority(display.window);
Priority(display.topPriorityLevel);

%Initialize serial communication
display.s = serialport("COM10",115200); 
configureTerminator(display.s,"CR/LF");  %both input and output

%open the UI and wait for the initialization of PTB-3 and serial
%communication
infoUI();

%Gabor information
%-----------------

%size of the gabor patch
display.gaborDimPix = display.windowRect(4)/3;

%center of diplay position
display.dstRectLeft = [display.gaborDimPix,display.gaborDimPix,display.gaborDimPix*2,display.gaborDimPix*2];
display.dstRectRight = [display.windowRect(3)/3 + display.gaborDimPix, display.gaborDimPix, display.windowRect(3)/3 + display.gaborDimPix*2,display.gaborDimPix*2];

%other parameters
display.sigma = display.gaborDimPix / 7;
display.orientationTarget = 0; %vertical
display.orientationNontarget = 90; %horizontal
display.contrast = 0.8;
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

%randomize the phase and make a property matrix
display.propertiesMat = [display.phase, display.freq, display.sigma, display.contrast, display.aspectRatio, 0, 0, 0];

%draw stuff on the screen
%------------------------
updateVbl;
display.waitframes = 1;
display.phasePerFrame = 2 * pi;  %change the grating movement speed

%timer setting
%-------------------------


display.t1 = timer('StartDelay',1,'Period',2,'TasksToExecute',10,'ExecutionMode','fixedSpacing');
display.t1.startFcn = @timer1output;
display.t1.TimerFcn = @timer1display;
display.t1.StopFcn = @timer1end;

display.visiPeriod = 4;
start(display.t1)

function timer1output(~,~)
 global display
 write(display.s,'1','char'); %send Arduino the seqID = 1 (stay)
 disp('>>>seqID = 1')
 display.seqID = 1; 
end

function timer1display(~,~)
 global display
 write(display.s,'2','char'); %send Arduino the seqID = 2 (pre-RW)
 display.seqID = 2;
 trialNum = get(display.t1,'TasksExecuted');%get the number of the executed task
 fprintf('>>>seqID = 2, trial number = %s\n',num2str(trialNum))
 updateVbl;%visual stimulation
 flagRW = true;
  while display.vbl - display.vblt0 < display.visiPeriod
      if display.vbl - display.vblt0 > 1 && flagRW == true %make the write/disp event happen only once
          write(display.s,'3','char'); %send Arduino the seqID = 3 (RW)
          disp('>>>seqID = 3')  
          flagRW = false;
      end
    Screen('DrawTextures', display.window, display.gabortex, [], display.dstRectLeft, display.orientationTarget, [], [], [], [],...
        kPsychDontDoRotation, display.propertiesMat');

    display.vbl = Screen('Flip', display.window, display.vbl + (display.waitframes - 0.5) * display.ifi);

    display.propertiesMat(1) = display.propertiesMat(1) + display.phasePerFrame;
    %outdum = readline(display.s);
  end
  updateVbl;
  write(display.s,'2','char');
end

function timer1end(~,~)
 global display
 disp('>>>seqID = 4')
 write(display.s,'4','char'); %send Arduino the seqID = 4
 display.seqID = 4;
 %sca
 %clear all
end

function updateVbl(~,~)   %flip to the gray background and update the vbl
global display
display.vbl = Screen('Flip',display.window);
display.vblt0 = display.vbl;
end

function infoUI()
global display
prompt = {'mouseID', 'trainStage', 'dayNumber', 'saveDir'};
dlgtitle = 'mouse information';
dims = [1 35]; %size of the UI
definput = {'', '', '', '/Users/liuqr/files/MATLAB相关/code ref/test code'};
display.mouseID = inputdlg(prompt, dlgtitle, dims, definput);
end
