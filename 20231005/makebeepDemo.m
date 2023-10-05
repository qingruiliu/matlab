
clear;
clc;

InitializePsychSound;

% Open Psych-Audio port
freq = 48000;
for i = 1:10
pahandle = PsychPortAudio('Open', 11, 1, 1, freq, 2);

%the first number represents individual devices, use PsychPortAudio('GetDevices') to
%check which is the UR12

% Set the volume
PsychPortAudio('Volume', pahandle, 0.1);

% Make a beep which we will play back to the user
[myBeep, samplingRate] = MakeBeep(1000, 0.1, freq);
PsychPortAudio('FillBuffer', pahandle, [myBeep; myBeep]);

% Show audio playback
PsychPortAudio('Start', pahandle, 1, 0, 1);
[startTime, endPositionSecs, xruns, estStopTime] = PsychPortAudio('Stop', pahandle, 1, 1);

% Close the audio device
PsychPortAudio('Close', pahandle);
end
