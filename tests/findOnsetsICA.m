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

%
% Abdallah, Samer A., and Mark D. Plumbley. "Probability as metadata: event 
%    detection in music using ICA as a conditional density model." In Proc. 
%    4th Int. Symp. Independent Component Analysis and Signal Separation 
%    (ICA2003), pp. 233-238. 2003.



FrameLength = 768;
ShortFrameLength = 512;

HopSize = ShortFrameLength;

NumFrames = ceil(size(x, 1)/HopSize);
PadSamples = (NumFrames - 1) * HopSize + FrameLength;
x = padarray(x, PadSamples - size(x, 1), 'post');

DetectArray = zeros(NumFrames, 1);

IdxIn = 1;

for k = 1:NumFrames
    if mod(k, 5) == 1
        fprintf('Analyzing frame %d of %d...\n', k - 1, NumFrames - 1);
    end
    
    IdxOut = IdxIn + FrameLength - 1;
    IdxShortIn = IdxOut - ShortFrameLength + 1;

    Frame = x(IdxIn:IdxOut);
    Mdl = rica(Frame, FrameLength);
    s = Mdl.TransformWeights;
    Surprise = norm(s);

    ShortFrame = x(IdxShortIn:IdxOut);
    Mdl = rica(ShortFrame, ShortFrameLength);
    s = Mdl.TransformWeights;
    ShortSurprise = norm(s);

    DetectArray(k) = ShortSurprise - Surprise;
    
    % Advance frame pointer.
    IdxIn = IdxIn + HopSize;
end

plot(DetectArray)

% function findOnsetsICA(x, fs)
%     
% end