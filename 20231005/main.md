This is the demo of using PTB-3 to generate auditory stimulation(cue of each single trial).
And also the tested program for animal conditioning test.

Environment: Ubuntu 22.04, MATLAB R2022b, PTB-3
2023.10.5 Qingrui Liu @UTokyo

-----------------------------------------------
% 2023.10.20 update

To confirm the licking status and lick in vs. out RW, a new structure of lick reporter is added. 
pinStatusChangedDemo.m applied a two-timer interaction method, one is for continuously detecting the status of the sensors,
another timer was used to generate the refractory period after each lick.
This demo will be further integrated into the stageTwo program.

Qingrui Liu @UTokyo