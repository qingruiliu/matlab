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
a = arduino("/dev/cu.usbmodem21401",'Leonardo','BaudRate',115200);

%% display UI, waiting for the initialization
infoUI();

%% variables
data = zeros(100,2);
data(:,1) = 1:100;
licktime = 0;
lickFlag = true;
timeLapse = tic;

%% main loop
while licktime < 100
    lick = readDigitalPin(a,'D8');
    if lick == true && lickFlag == true
        writeDigitalPin(a,'D7',1);
        lickFlag = false;
        licktime = licktime + 1;
        pause(0.02);
        fprintf('licktime = %s\n',num2str(licktime));
        data(licktime,2)=toc(timeLapse);
    end
    lickFlag = true;
    writeDigitalPin(a,'D7',0);
end

disp('100 time licked!')

%% functions
function infoUI()
global display
prompt = {'mouseID', 'trainStage', 'dayNumber', 'saveDir'};
dlgtitle = 'mouse information';
dims = [1 35];
definput = {'', '', '', '/Users/liuqr/files/MATLAB相关/code ref/test code'};
display.mouseID = inputdlg(prompt, dlgtitle, dims, definput);
end
