function env = findStable(wav, fs)
    % Returns an N-length logical array indicating where an N-length audio
    % signal is pitch-stable. (Rebuilding Xiaohan script as function.)
    
    % Parameters.
    noteMax = 8;  % in ref to 440 Hz (half note semitone) - range of music
    noteMin = -7; % -10~10 by Jonas

    durFrame = 0.02;
    minN_frameStable = 15;
    thrVarNote = 0.5; % (semitone)
    thrVarSPL = 3;   % (db)
    
    % Calculations.
    len = length(wav);
    
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
    
    % Process frame pitch and energy.
    idx = 0;
    thisFrame = wav(idx + (1:lenFrame));
    countFrame = 0;
    
    while idx + lenFrame < len    
        countFrame = countFrame + 1;
        lastFrame = thisFrame;    
        idx = idx + lenFrame;
        thisFrame = wav(idx + (1:lenFrame));

        twoFrame = [lastFrame; thisFrame]; 
        r_lag = nan(nLag, 1);
        for lag = minN_Lag : maxN_Lag
            r_lag(lag - minN_Lag + 1) = ...
                corr(lastFrame, twoFrame(lag  + (0:lenFrame-1)));
        end

        [r_XC_peak(countFrame), lag_XC_peak(countFrame)] = max(r_lag);
        rms_XC(countFrame) = rms(twoFrame);
    end
    
    % Convert outputs to sound level and pitch.
    f0 = 1 ./(minN_Lag - 1 +lag_XC_peak)  * fs;
    note = log2(f0 / 440) * 12;
    note(~(r_XC_peak > 0.05)) = inf;
    SPL = pow2db(rms_XC); 
    
    % Calculate difference in pitch.
    
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
    
    % Returns env.
end