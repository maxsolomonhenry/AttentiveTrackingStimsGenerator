clear

%% parameter
noteMax = 8; % in ref to 440 Hz (half note semitone) - range of music
noteMin = -7; % -10~10 by Jonas

durFrame = 0.02;
minN_frameStable = 15;
thrVarNote = 0.5; % (semitone)
thrVarSPL = 3;   % (db)
fn = 'Jonas-Max Examples_TptMono.wav';

%% i/o and etc.
[wav, fs] = audioread(fn);
[len, I] = max(size(wav));
if I > 1, wav = wav(1, :)';else, wav = wav(:, 1); end

lenFrame = round(fs * durFrame);
nFrame = floor(numel(wav) / lenFrame) - 1;
r_XC_peak = nan(nFrame, 1);
lag_XC_peak = nan(nFrame, 1);
rms_XC = nan(nFrame, 1);


fMax = 2 ^ (noteMax / 12) * 440; 
fMin = 2 ^ (noteMin / 12) * 440; 
minN_Lag = floor(1 / fMax * fs); 
maxN_Lag = ceil(1 / fMin * fs);
nLag = maxN_Lag - minN_Lag + 1;

%% frame-by-frame processing of pitch and energy
idx = 0;
thisFrame = wav(idx + (1:lenFrame));    % initialize thisFrame as the first frame
countFrame = 0;
while idx + lenFrame < len    
    countFrame = countFrame + 1;
    lastFrame = thisFrame;    
    idx = idx + lenFrame;
    thisFrame = wav(idx + (1:lenFrame));
    
    twoFrame = [lastFrame; thisFrame]; 
    r_lag = nan(nLag, 1);
    for lag = minN_Lag : maxN_Lag
        r_lag(lag - minN_Lag + 1) = corr(lastFrame, twoFrame(lag  + (0:lenFrame-1)));
    end
    
    [r_XC_peak(countFrame), lag_XC_peak(countFrame)] = max(r_lag);
    rms_XC(countFrame) = rms(twoFrame);
    
%     subplot(2, 1, 1);
%     plot(fs ./ (minLag:maxLag), r, 'k'); 
%     subplot(2, 1, 2);
%     plot((1:lenFrame * 2) / fs, [lastFrame; wavFrame], 'k'); 
%     if max(r) > 0,     pause; end

end
%% convert to note and sound level
figure; hold on;
f0 = 1 ./(minN_Lag - 1 +lag_XC_peak)  * fs;
note = log2(f0 / 440) * 12;
note(~(r_XC_peak > 0.05)) = inf;
SPL = pow2db(rms_XC); 

%% generating figures
hold on
% errorbar(f0, f0_Var, 'r-', 'CapSize', 1); hold on
bar(50 + SPL);
frameFilter = false(size(note));
% f0_included = f0;
% f0_excluded = nan(size(f0));



%% frame-by-frame processing of variation 
env = wav * 0;
var_note = nan(size(note));
var_SPL = nan(size(SPL));
countFrameOffset = (minN_frameStable - 1) / 2 - 1;
idx = countFrameOffset * lenFrame;
countFrame = countFrameOffset;
while countFrame + countFrameOffset + 2 < nFrame
    countFrame = countFrame + 1;
    idx = idx + lenFrame;
    idxFrame = countFrame-countFrameOffset:countFrame+countFrameOffset+1;
    var_note(countFrame) = max(note(idxFrame)) - min(note(idxFrame));
    var_SPL(countFrame) = max(SPL(idxFrame)) - min(SPL(idxFrame));
    if var_note(countFrame) < thrVarNote && var_SPL(countFrame) < thrVarSPL
        env(idx + (1:lenFrame)) = 1;
    end
end

var_note(countFrame) < thrVarNote && var_SPL(countFrame) < thrVarSPL
lenRamp = round(0.01 * fs);
envRamp = conv(env, ones(lenRamp, 1) / lenRamp);
envRamp = envRamp(1:len);
save([fn(1:end-4) '.mat'], 'wav', 'env', 'envRamp', 'note', 'SPL', 'var_note', 'var_SPL', 'thrVarNote', 'thrVarSPL'); 
% same dimention between env and wav

%% visualization
figure; 
hold on;
t = (1:numel(note)) * lenFrame / fs;
plot(t, note, 'k-');
scatter(t(var_note < 0.5), note(var_note < 0.5), 'ko', 'filled');
scatter(t(var_note > 0.5), note(var_note > 0.5), 'ko');
% plot
% scatter(note, 

% for j = 6:countFrame-5
%     if max(note(j-5:j+5)) - min(note((j-5:j+5))) > 0.5 || max(SPL(j-5:j+5)) - min(SPL(j-5:j+5)) > 3
%         frameFilter(j) = false;
%     else
%         frameFilter(j) = true;
%     end
% end
% t = 1:countFrame;
% plot(t(~frameFilter), 50 + note(~frameFilter), 'o', 'color', [0.6 0.6 0.6], 'markersize', 4, 'MarkerFaceColor', [0.6 0.6 0.6])
% plot(t(frameFilter), 50 + note(frameFilter), 'o', 'color', [0 0 0], 'markersize', 4, 'markerfacecolor', [0 0 0]);
% 
% 
% %% saving file
% wavNew = zeros(size(wav));
% envRise = (1:lenFrame)' / lenFrame * 0.9 + 0.1;
% envFall = (lenFrame:-1:1)' / lenFrame * 0.9 + 0.1;
% for j = 2:idxFrame-2
%     if frameFilter(j-1) && frameFilter(j) &&  ~frameFilter(j+1) 
%         wavNew(j * lenFrame + (1: lenFrame)) = wav(j * lenFrame + (1: lenFrame)) .* envFall;
%     elseif ~frameFilter(j-1) && frameFilter(j) &&  frameFilter(j+1) 
%         wavNew(j * lenFrame + (1: lenFrame)) = wav(j * lenFrame + (1: lenFrame)) .* envRise;
%     elseif frameFilter(j-1) && frameFilter(j) &&  frameFilter(j+1) 
%         wavNew(j * lenFrame + (1: lenFrame)) = wav(j * lenFrame + (1: lenFrame));
%     else
%         wavNew(j * lenFrame + (1: lenFrame)) = wav(j * lenFrame + (1: lenFrame)) * 0.1;
%     end
% end
% audiowrite('newwav.wav', wavNew, fs);