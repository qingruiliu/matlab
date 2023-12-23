
clear;
clc;

InitializePsychSound;


% Open Psych-Audio port
freq = 48000;

for i = 1:5
   
beepDemotic = tic;
pahandle = PsychPortAudio('Open', 0, 1, 1, freq, 2);

%the first number represents individual devices, use PsychPortAudio('GetDevices') to
%check which is the UR12

% Set the volume
PsychPortAudio('Volume', pahandle, 0.04);

% Make a beep which we will play back to the user
 [myBeep, samplingRate] = MakeBeep(1000, 0.1, freq);
 PsychPortAudio('FillBuffer', pahandle, [myBeep; myBeep]);

% Show audio playback
 PsychPortAudio('Start', pahandle, 1, 0, 1);
 [startTime, endPositionSecs, xruns, estStopTime] = PsychPortAudio('Stop', pahandle, 1, 1);

% Close the audio device
 PsychPortAudio('Close', pahandle);
 toc(beepDemotic)
end

%% chatGPT low latency solution
clear 
clc
InitializePsychSound;

% Open Psych-Audio port
freq = 48000;
pahandle = PsychPortAudio('Open', 0, 1, 1, freq, 2);
PsychPortAudio('Volume', pahandle, 0.04);

% Preallocate audio buffer
[myBeep, samplingRate] = MakeBeep(10000, 0.1, freq);
buffer = [myBeep; myBeep];
PsychPortAudio('FillBuffer', pahandle, buffr);

for i = 1:5
    beepDemotic = tic;

    % Show audio playback
    PsychPortAudio('Start', pahandle, 1, 0, 1);
    [startTime, endPositionSecs, xruns, estStopTime] = PsychPortAudio('Stop', pahandle, 1, 1);

    toc(beepDemotic);
end

% Close the audio device outside the loop
PsychPortAudio('Close', pahandle);

