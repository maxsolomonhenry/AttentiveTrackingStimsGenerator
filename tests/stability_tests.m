% Experimenting for stability criteria in audio file. I.e., where to place 
% artificial vibrato in "stable" portion of audio file.

% Have to use full path because f%%% Matlab.
AUDIO_DIR = '/Users/maxsolomonhenry/Documents/MATLAB/AttentiveTrackingStimsGenerator/audio';  
RawPath = fullfile(AUDIO_DIR, 'raw/*.wav');
RawFiles = dir(RawPath);

k = round(rand()*length(RawFiles)); 

[x, fs] = audioread(RawFiles(k).name);
x = x/max(x);
x = x(:, 1);

plot(x)
hold on

Cutoff = 5;
Threshold = 0.2;
FiltOrder = 201;
MedianOrder = 20;
Lambda = 0.5;

locs = findOnsetsFlux(x, fs, Cutoff, Threshold, FiltOrder, MedianOrder, Lambda);

scatter(locs, ones(size(locs)));
hold off

soundsc(x, fs);

VibRate = 11;
NumCycles = 3;
VibLength = floor(fs / VibRate * NumCycles);