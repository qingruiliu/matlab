clear all
sca
%% open the monitor, display the gray color background
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

%% start communication
display.a = arduino("/dev/cu.usbmodem21401",'Leonardo','BaudRate',115200);

%% Gabor related variables
%size of the gabor patch, full of the height in this case
display.gaborDimPix = display.windowRect(4);
display.width = display.windowRect(3);
display.height = display.windowRect(4);

%center of diplay position
display.center = [(display.width-display.height)/2,0,(display.width+display.height)/2,display.height];

%other parameters
display.sigma = display.gaborDimPix / 7;
display.target = 0; %vertical,leftward
display.nontarget = 90; %horizontal,downward
display.orientationMatrix = [display.target,display.nontarget]; %to be indexed in the loop
display.contrast = 1;
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

%randomize the phase and make a properti es matrix
display.propertiesMat = [display.phase, display.freq, display.sigma, display.contrast, display.aspectRatio, 0, 0, 0];

updateVbl;
display.waitframes = 1;
display.phasePerFrame = 2 * pi;  %change the speed of grating moving

%% randomization of Go/NoGo visual stimulation
nTrial = 50;
nTarget = 25;  %50 trials as a block, half of them are target trials
display.stimIDs = randomSequence(nTrial,nTarget); %randomize the sequence 
display.stimIDs = display.stimIDs + 1;

%% program presetting
display.lickTrial = 0;
display.FATrial = 0;
display.CRTrial = 0;
display.missTrial = 0;

%set the trial limit and the empty data
display.blockData = cell(50,1);  %single block data
display.stageData = {};          %total stage data

%% display UI, waiting for the initialization
infoUI();

%% 15 seconds countdown 
countDown;

%% start tic and main loop
totalTic = tic;
%main loop
for trialNum = 1:50
    display.trialNum = trialNum;
    disp('------------------new trial-----------------------')
    fprintf('trialNum = %s\n',num2str(display.trialNum))
    trialCue;  %play the auditory cue of each single trial
    pause(1);  
    visiStim;  %present the visual stimulation
    responseWindow;
    intertrialInterval;
end

%% final information
disp('--------------------------------------------------------------')
disp('---------------This block is done! お疲れ様です！---------------')
totalTime = toc(totalTic);
fprintf('>> total time cost:  %s minutes %s seconds \n',num2str(floor((totalTime)/60)),num2str(mod(totalTime,60)));
fprintf('>> Hit times: %s times \n',num2str(display.lickTrial));
fprintf('>> FA times: %s times \n',num2str(display.FATrial));
fprintf('>> CR times: %s times \n',num2str(display.CRTrial));
fprintf('>> miss times: %s times \n',num2str(display.missTrial));

%calculate the correctRate of this block
correctRate = (display.lickTrial + display.CRTrial) / trialNum;
fprintf('The correct rate of this block is : %s percent!!! \n',num2str(correctRate*100));

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
  %playTone(display.a,'D3',2000,100);  %cue last for 0.1 second
  %pause(0.9);
end

function visiStim(~,~)
  global display
  updateVbl;
  %index the Go/NoGo matrix using the random sequence indexed by trial
  %number
  display.orientation = display.orientationMatrix(display.stimIDs(display.trialNum));
  while display.vbl - display.vblt0 < 1
  Screen('DrawTextures', display.window, display.gabortex, [], display.center,display.orientation, [], [], [], [],...
        kPsychDontDoRotation, display.propertiesMat');
  display.vbl = Screen('Flip', display.window, display.vbl + (display.waitframes - 0.5) * display.ifi);
  display.propertiesMat(1) = display.propertiesMat(1) + display.phasePerFrame;
  end
  updateVbl;
end

function countDown(~,~)
 countdownDuration = 15;
 disp('---------Countdown started...check the mouse and lick spout!!!--------------------')

 for remainingSeconds = countdownDuration :-1 :0
     fprintf('Time remaining: %d seconds \n',remainingSeconds);
     pause(1);
 end
 disp('---------Countdown finished! Start conditioning!----------------------------------')
end

function seq = randomSequence(n, m)
seq = zeros(n, 1);
seq(1 : m) = 1;
seq(randperm(n)) = seq;
% Up to three consecutive repetitions of the same ID are allowed.
nPermit = 3;
iSame = 0;
  for i = 1 : n - 1
    if seq(i) == seq(i + 1)
        iSame = iSame + 1;
    else
        iSame = 0;
    end
    j = 0;
    while iSame > nPermit - 1
        temp = seq(end - j); 
        seq(end - j) = seq(i + 1); 
        seq(i + 1) = temp; %swap the 4th repetitive element with the end of the sequence

        if seq(i) == seq(i + 1)
            j = j + 1;
        else
            j = 0;
            iSame = 0;
        end
    end
  end
end

function responseWindow(~,~)

 global display
 lickFlag = true;
 rwTime = tic;
 trialFlag = true;
 lickTimesReporter = 0;

 if display.stimIDs(display.trialNum) == 1  %Go

  while toc(rwTime) < 4
     lick = readDigitalPin(display.a,'D8');
        if lick == true && lickFlag == true  %----------------Hit------------------------
         writeDigitalPin(display.a,'D7',1);  %water pump
         lickFlag = false;
         writeDigitalPin(display.a,'D7',0);
         pause(0.5);     %不応期
        end
        if lickFlag == false  
           if trialFlag == true %this if loop is used for licktrial increment
              trialFlag = false;
              display.lickTrial = display.lickTrial + 1;
              fprintf('>>>Licked!!!<<< licktrial = %s\n',num2str(display.lickTrial));
           end
         lickFlag = true;
         lickTimesReporter = lickTimesReporter + 1; %count the lick times in a single licked trial
         tocReporter = toc(rwTime);
         fprintf('licktime = %s  @%s second \n',num2str(lickTimesReporter),num2str(tocReporter));

         %save the data in pre-allocating matrix
         display.blockData{display.trialNum}(lickTimesReporter,1) = 1;    %hit is labeled as 1
         display.blockData{display.trialNum}(lickTimesReporter,2) = lickTimesReporter;
         display.blockData{display.trialNum}(lickTimesReporter,3) = tocReporter; 
        end 

  end
       if lickTimesReporter == 0             %-----------------Miss---------------------
        display.missTrial = display.missTrial + 1;
        display.blockData{display.trialNum} = zeros(1,3);
        display.blockData{display.trialNum}(1) = 2; %miss is labeled as 2
        fprintf('>>>Miss!!!<<< misstrial = %s \n',num2str(display.missTrial));    
       end

 elseif display.stimIDs(display.trialNum) == 2 %NoGo

   while toc(rwTime) < 4
      lick = readDigitalPin(display.a,'D8');

        if lick == true && lickFlag == true %----------------FA--------------------------
           writeDigitalPin(display.a,'D6',1); %air pump
           lickFlag = false;
           pause(0.1);
           writeDigitalPin(display.a,'D6',0);
        end

        if lickFlag == false
            if trialFlag == true
                trialFlag = false;
            display.FATrial = display.FATrial + 1;
            fprintf('>>>False alarm!!!<<< FATrial = %s \n',num2str(display.FATrial));
            end
            lickFlag = true;
            lickTimesReporter = lickTimesReporter + 1;
            tocReporter = toc(rwTime);
            fprintf('FAtime = %s, @%s second \n',num2str(lickTimesReporter),num2str(tocReporter));
            display.blockData{display.trialNum}(lickTimesReporter,1) = 3;    %FA is labeled as 3
            display.blockData{display.trialNum}(lickTimesReporter,2) = lickTimesReporter;
            display.blockData{display.trialNum}(lickTimesReporter,3) = tocReporter; 
            pause(7); %4 seconds timeout of FA
            return    %end the function, start ITI
        end
   end

    if lickTimesReporter == 0   %--------------------------CR------------------------
        display.CRTrial = display.CRTrial + 1;
        display.blockData{display.trialNum} = zeros(1,3);
        display.blockData{display.trialNum}(1) = 4; %CR is labeled as 4
        fprintf('>>>Correct rejection!!!<<< CRTrial = %s \n',num2str(display.CRTrial));  
    end

 end

end

function intertrialInterval(~,~)   %ITI is 2 s, 2 extra second is extended.
global display
  ITIflag = true;
  ITITime = tic;
  ITIlimit = 2;
  while toc(ITITime) < ITIlimit
      ITIlick = readDigitalPin(display.a,'D8');

      if ITIlick == true && ITIflag == true   %--------lick in ITI----------
          ITIflag = false;
          pause(0.1);
          fprintf('>>>lick in ITI!!!<<<ITI + 2s!!!\n');
          ITIlimit = ITIlimit + 2;
      end

      if ITIflag == false
          ITIflag = true;
      end
  end
  fprintf('>>>ITI finished!!!<<< ITI time: %s seconds \n',num2str(toc(ITITime)));
end
