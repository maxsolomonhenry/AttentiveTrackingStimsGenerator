% Max Henry, for MPCL/McGill Attentive Tracking Experiment. 2020/2021.
%
% This generates stimuli from all audio in '/audio/raw'
%
% For the moment, this assumes that only matched pairs are in the raw audio
% folder: i.e., only one instrument per melody/part. In this case the pairs
% should line up nicely in the dir order. Otherwise the automatic pairing 
% will get messed up.
%
% This script is old and the API is whack. Sorry. It's expecting a few
% things:
%
% Input file naming convention: 
%
%       M[melody]_P[part]_[instrument].wav
%      
% e.g., M1_P1_Tpt.wav --> melody #1, top part, trumpet.
%
% The output names are equally cryptic. For each pair, it outputs 5 files:
% (n.b., "cues" are the first ~1.5 seconds of a file, as specified in the
% StimulusGenerator script. Gross, I know.)
%
%   [whole filename 1]_q.wav --> a short cue for the first instrument.   
%   [whole filename 2]_q.wav --> a short cue for the second instrument.
%
%   M[melody]_P1_[inst1]_P2_[inst2]_N.wav    -->    mixture, no vibrato
%   M[melody]_P1_[inst1]_P2_[inst2]_V_P1.wav -->    mixture, vibrato in 1st 
%   M[melody]_P1_[inst1]_P2_[inst2]_N.wav    -->    mixture, vibrato in 2nd
%

AUDIO_DIR = './audio';
RawPath = fullfile(AUDIO_DIR, 'raw/*.wav');
RawFiles = dir(RawPath);

% Process every pair (every second entry).
for k = 1:2:length(rawFiles)
    StimulusGenerator(RawFiles(k).name, RawFiles(k+1).name);
end