%drifting gabor patch presetting
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

%Gabor information
%-----------------

%size of the gabor patch
display.gaborDimPix = display.windowRect(4)/3;

%center of diplay position

display.dstRectLeft = [display.gaborDimPix,display.gaborDimPix,display.gaborDimPix*2,display.gaborDimPix*2];
display.dstRectRight = [display.windowRect(3) - 2 * display.gaborDimPix, display.gaborDimPix, display.windowRect(3) - display.gaborDimPix,display.gaborDimPix*2];

%other parameters
display.sigma = display.gaborDimPix / 7;
display.orientationTarget = 0; %vertical
display.orientationNontarget = 90; %horizontal
display.contrast = 0.8;
display.aspectRatio = 1.0;
display.phase = 0; 
display.visiMatrix = {display.dstRectLeft, display.orientationTarget;
                      display.dstRectRight, display.orientationTarget;
                      display.dstRectLeft, display.orientationNontarget;
                      display.dstRectRight, display.orientationNontarget};
%spatial frequency
display.numCycles = 10;
display.freq = display.numCycles / display.gaborDimPix;

%make procedural gabor texture
display.backgroundOffset = [0.5 0.5 0.5 0.0];
display.disableNorm = 1;
display.preContrastMultiplier = 0.5;
display.gabortex = CreateProceduralGabor(display.window, display.gaborDimPix, display.gaborDimPix, [],...
    display.backgroundOffset, display.disableNorm, display.preContrastMultiplier);

%randomize the phase and make a properti es matrix
display.propertiesMat = [display.phase, display.freq, display.sigma, display.contrast, display.aspectRatio, 0, 0, 0];

%draw stuff on the screen
%------------------------
updateVbl;
display.waitframes = 1;
display.phasePerFrame = 2 * pi;  %change the grating movement speed

%timer setting
%-------------------------


display.t1 = timer('StartDelay',1,'Period',2,'TasksToExecute',4,'ExecutionMode','fixedSpacing');
display.t1.startFcn = @timer1output;
display.t1.TimerFcn = @timer1display;
display.t1.StopFcn = @timer1end;

display.visiPeriod = 4;
start(display.t1)

function timer1output(~,~)
 global display
 disp('seqID = 1')
 display.seqID = 1; %stay
end

function timer1display(~,~)
 global display
 disp('sedID = 2')
 display.seqID = 2;
 tasksExecuted = get(display.t1,'TasksExecuted');%get the number of the executed task
 updateVbl;%visual stimulation
  while display.vbl - display.vblt0 < display.visiPeriod
      %~KbCheck
      centerPosition = cell2mat(display.visiMatrix(tasksExecuted,1));
      targetOrNot = cell2mat(display.visiMatrix(tasksExecuted,2));

    Screen('DrawTextures', display.window, display.gabortex, [], centerPosition, targetOrNot, [], [], [], [],...
        kPsychDontDoRotation, display.propertiesMat');

    display.vbl = Screen('Flip', display.window, display.vbl + (display.waitframes - 0.5) * display.ifi);

    display.propertiesMat(1) = display.propertiesMat(1) + display.phasePerFrame;
  end
  updateVbl;
end

function timer1end(~,~)
 global display
 disp('seqID = 3')
 display.seqID = 3;
 %sca
 %clear all
end

function updateVbl(~,~)   %flip to the gray background and update the vbl
global display
display.vbl = Screen('Flip',display.window);
display.vblt0 = display.vbl;
end
