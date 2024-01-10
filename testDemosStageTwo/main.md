This folder includes the demos for various purposes in stage 2 test. 
23.12.21 Qingrui Liu @UTokyo

%% 2024.1.5 **stageTwoRasterPlot.m** is added.
This demo fulfills the target of **trial raster plotting**:
1. post-cue period (1s) reset when licking;
2. early licks in the visual stimulation period are labeled as red dots;
3. hit licks (the first lick in RW without early lick in visual stimulation) are labeled as green dots;
4. licks in RW without water reward are labeled as blue dots;
5. licks in ITI are labeled as black dots.

The right axes plot the time length of individual trials.

%%2024.1.10 **stageTwoNormrnd240105.m** is added.
This demo may be the ultimate version of stage two program:
1. modified trial raster plotting
2. randomized post-cue period fitting normal distribution(mean=1, SD=0.1).
3. Criteria: get 150 times of water reward in 300 trials
