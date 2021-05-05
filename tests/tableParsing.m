% Preliminaries.
stimulusTable = readtable('data/stimulus_table.csv');

% Parameters.
participantId = '001';
silenceSeconds = 0.6;

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

    numSilenceSamples = round(silenceSeconds * fs);
    silence = zeros(numSilenceSamples, 1);

    x = [cueAudio; silence; mixture; silence; probeAudio];

    % Write audio to file.
    stimulusPath = participantDir + "/" + stimulusFilename;
    audiowrite(stimulusPath, x, fs);

    % Write to log.
    fprintf(fid, "\nfile:\t%s\nvib:\t%.2f seconds\nprobe:\t%s\n\n", ...
        stimulusFilename, vibStartSeconds, whichProbe);

end

fclose(fid);


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