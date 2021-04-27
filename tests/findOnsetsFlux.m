% Returns locations of note onsets.

function Out = findOnsetsFlux(x, fs, Cutoff, Threshold, FiltOrder, MedianOrder, Lambda)
    arguments
        x
        fs
        Cutoff = 5
        Threshold = 0.15
        FiltOrder = 201
        MedianOrder = 20
        Lambda = 1
    end
    
    Flux = spectralFlux(x, fs);
    Flux = filter([1, -1], 1, Flux);
    Flux = Flux - mean(Flux);

    FluxFS = length(Flux)/length(x) * fs;

    b = fir1(FiltOrder, (Cutoff/FluxFS) * 2);

    Onset = filter(b, 1, Flux);
    Onset = circshift(Onset, -(FiltOrder - 1)/2);
    Onset = Onset/max(Onset);
    Onset = abs(Onset);

    ThreshFunct = Threshold + Lambda * medfilt1(Onset, MedianOrder);
    Onset = Onset - ThreshFunct;
    Onset(Onset < 0) = 0;

    [~, locs] = findpeaks(Onset);
    Out = locs * fs / FluxFS;
end