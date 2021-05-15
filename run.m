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
% placement, and wether the bottom or top part is probed.
%
% Please specify the participantId at the top of the script.

clear; clc;

% Parameters.
participantId = '01';
silenceSeconds = 1;

% Debugging.
toggleVerbose = true;

% Preliminaries.
stimulusTable = readtable('data/stimulus_table.csv');

% Make participant directory.
participantDir = "audio/processed/" + participantId;
mkdir(participantDir);
addpath(fullfile(pwd, participantDir));

% Setup log.
logPath = participantDir + "/log.txt";
fid = fopen(logPath, 'wt');
today = datestr(datetime);
fprintf(fid, "\nDate:\t" + today);
fprintf(fid, "\n================================\n");


for i = 1:height(stimulusTable)

    stimulusFilename = stimulusTable.trial_id{i} + ".wav";

    melody = stimulusTable.melody_name{i};

    tmp = stimulusTable.instrument{i};
    tmp = strsplit(tmp, '-');
    topInstrument = tmp{1};
    bottomInstrument = tmp{2};

    filename1 = melody + "_P1_" + topInstrument + ".wav";
    filename2 = melody + "_P2_" + bottomInstrument + ".wav";

    whichCue = stimulusTable.cue{i};

    whichVib = stimulusTable.vib{i};
    whichVib = makeExplicit(whichVib, whichCue);

    probeTop = stimulusTable.probe_top{i};
    probeBottom = stimulusTable.probe_bottom{i};

    probeTop = convertCharsToStrings(probeTop);
    probeBottom = convertCharsToStrings(probeBottom);

    % Init stimgen object.
    generator = StimulusGenerator(filename1, filename2);

    % Generate cue from `whichCue` track.
    cueAudio = generator.makeCue(whichCue);

    % Generate mixture with vibrato in `whichVib` track.
    [mixture, vibStartSeconds] = generator.makeMixture(whichVib);

    % Randomly select probe.
    tmp = randi([1, 2]);

    tmpChoice = ["top", "bottom"];
    whichProbe = tmpChoice(tmp);

    tmpChoice = [probeTop, probeBottom];
    probeFile = tmpChoice(tmp) + ".wav";
    probeAudio = getProbeAudio(probeFile);

    numSilenceSamples = round(silenceSeconds * generator.fs);
    silence = zeros(numSilenceSamples, 1);

    x = [cueAudio; silence; mixture; silence; probeAudio];

    % Write audio to file.
    stimulusPath = participantDir + "/" + stimulusFilename;
    audiowrite(stimulusPath, x, generator.fs);
    
    % A constant to add to vib time to adjust for preceding cue and silence.
    tmpOffset = generator.CUE_LENGTH + silenceSeconds;
    
    logString = sprintf(...
        "\nfile:\t%s\nvib:\t%.2f seconds\nprobe:\t%s\n\n", ...
        stimulusFilename, vibStartSeconds + tmpOffset, whichProbe...
    )
    
    if toggleVerbose
        fprintf(logString);
    end

    % Write to log.
    fprintf(fid, logString);

end

% Close the log file.
fclose(fid);

% Helper functions.

function whichVib = makeExplicit(whichVib, whichCue)
% Translates `whichVib` from 'cued/uncued' to 'top/bottom'.

    if whichVib == "none"
        return
    end

    if strcmp(whichVib, whichCue)
        whichVib = whichCue;
    elseif whichCue == "top"
        whichVib = "bottom";
    elseif whichCue == "bottom"
        whichVib = "top";
    end
end

function [probeAudio, fs] = getProbeAudio(probeFile)
    [probeAudio, fs] = audioread(probeFile);
    if size(probeAudio, 2) ~= 1
        probeAudio = probeAudio(:, 1);
    end
end