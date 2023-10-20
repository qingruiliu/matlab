% Create Arduino object and specify pin number
global h
h.a = arduino("/dev/ttyACM0", "Leonardo","BaudRate",115200);
h.pinNumber = 'D13';
h.lickTime = tic;

% Create global lick timer with a 100 ms period
h.tLick = timer('ExecutionMode', 'fixedRate', 'Period', 0.05,'TimerFcn',@(src,event)pinStatusChanged); % 1 milliseconds
h.tRefractory = timer('BusyMode','error','TasksToExecute',1,'StartDelay',0.1,...
                       'StartFcn',@(src,event)refStart,...
                       'TimerFcn',@(src,event)refEnd);
% Start the lick timer
start(h.tLick);

% Define the callback function for lick timer
function pinStatusChanged(~,~)
  global h
    pinValue = readDigitalPin(h.a, h.pinNumber);
    if pinValue == true
            writeDigitalPin(h.a,'D9',1); % Pump the water
            fprintf('Licked @ %s \n', num2str(toc(h.lickTime)));
            start(h.tRefractory);
            disp('timer 2 started by timer-1 TimerFcn');
    end
end

function refStart(~,~)
  global h
    stop(h.tLick);
    disp('timer 1 stopped by timer-2 StartFcn');
    writeDigitalPin(h.a,'D9',0);
end

function refEnd(~,~)
    global h 
    start(h.tLick);
    disp('timer 1 restarted by timer-2 TimerFcn');
    stop(h.tRefractory);
    disp('timer 2 stopped after the if structure');
end


%% 
%stop(t)      remember use stop(t) to stop the counter timer in each block