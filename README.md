# Attentive Tracking Experiment
Matlab scripts for generating stimuli for attentive tracking experiment based on musical duets.

Use `run.m`

```
% Generate stimuli for "Effect of Timbre on Top-Down Attention in
% Contemporary Composition" experiment.
% 
% Author: Max Henry
% 2020 – 2021.
%
% This generates stimuli from duet stems in `/audio/raw`, which should
% follow this naming convention:
%
%       `M[melody]_P[part]_[instrument].wav`
%      
% e.g., Mmin2crossing_P1_Tpt.wav --> "min2crossing," top part, trumpet.
%
% Melody names and output conditions are specified in the csv file:
%   
%   `/data/stimulus_table.csv`. 
%
% The table specifies melody names, condition names, which track to cue,
% which track to add an artificial vibrato to, and for which track to 
% generate a probe note. The script randomly determines the vibrato 
% placement, and whether the bottom or top part is probed.
%
% Please specify the participantId at the top of the script.
```
