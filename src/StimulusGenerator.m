%   Class for generating loudness-matched stimuli with random vibrato.
%
%   For use in the experiment "Directing attention in contemporary
%   composition with timbre," Henry, Bao and Regnier for the Music
%   Perception and Cognition Lab, McGill University. Summer, 2020.
%
%   StimulusGenerator(Filename1, Filename2)
%
%   This class expects wavefiles named according to the following
%   convention:
%
%   "M[melody number]_P[part number]_[instrument abbreviation].wav"
%
%   where:
%
%   melody number       -->     Unique identifier for duet melody.
%   part number         -->     1 or 2, to indicate "top" or "bottom" of
%                               staff.
%   instrument abbr.    -->     For the original experiment, either "Tpt"
%                               for trumpet, or "Vln" for violin. 
%
%           e.g., "M1_P1_Tpt.wav"

classdef StimulusGenerator < handle
    %   TODO:   Add desctructor.
    %           Make probes. (string parsing? maybe external)
    
    properties
        
        Filename1;
        Filename2;

        MelodyNum;
        PartNum1;
        PartNum2;
        Instrument1;
        Instrument2;
        
        x1;
        x2;
        fs;
        
        x1Vib;
        x2Vib;
        
        GainChange1;
        GainChange2;
        x1VibStart;
        x2VibStart;
        
        MixNoVib;
        MixVib1;
        MixVib2;
        
        Cue1;
        Cue2;
        
        Probe1;
        Probe2;
        
        VibGenerator;
    end
    
    properties (Constant)
        
        % Settings for artificial vibrato.
        VIB_RATE = 11;
        VIB_ALPHA = 0.01;
        VIB_CYCLES = 3;
        NO_VIB_BUFFER = 1.5;
        
        % Settings for cues.
        CUE_LENGTH = 1.5;
        CUE_FADE = 0.1;
        
        % Output ceiling.
        MAGNITUDE_REF = 5e4
        EPS = 0.01;
        
        % Directory with individual tracks.
        STIM_DIR = "audio/processed/";
        LOG_DIR = "logs/";
    end
    
    methods
        
        % Constructor.
        function obj = StimulusGenerator(Filename1, Filename2)
            
            obj.Filename1 = Filename1;
            obj.Filename2 = Filename2;
                        
            [obj.x1, obj.fs] = audioread(Filename1);
            [obj.x2, ~] = audioread(Filename2);
            
            obj.inputCheck();
            obj.matchLoudness();
            
            obj.VibGenerator = RandomVibrato(obj.fs, obj.VIB_RATE, ...
                obj.VIB_ALPHA, obj.VIB_CYCLES, obj.NO_VIB_BUFFER);
            
        end
        
%             
%             obj.parseFilenames();
%             
%             
%             obj.makeVibStim();
%             
%             obj.makeMixes();
%             obj.makeCues();
%             
%             obj.writeStimuli();
        
        function obj = parseFilenames(obj)
            Basename1 = obj.getBasename(obj.Filename1);
            Basename2 = obj.getBasename(obj.Filename2);
            
            Split1 = split(Basename1, '_');
            Split2 = split(Basename2, '_');
            
            if string(Split1(1)) ~= string(Split2(1))
                error("Melody numbers don\'t match. Please check the files and try again.");
            end
            
            obj.MelodyNum = string(Split1(1));
            
            obj.PartNum1 = string(Split1(2));
            obj.Instrument1 = string(Split1(3));
            
            obj.PartNum2 = string(Split2(2));
            obj.Instrument2 = string(Split2(3));
        end
        
        function obj = makeMixes(obj)
            obj.MixNoVib = obj.x1 + obj.x2;
            obj.MixVib1 = obj.x1Vib + obj.x2;
            obj.MixVib2 = obj.x1 + obj.x2Vib;
        end
        
        function cueAudio = makeCue(obj, whichCue)
            CueLengthInSamps = floor(obj.CUE_LENGTH * obj.fs);
            FadeSamps = floor(obj.CUE_FADE * obj.fs);
            Window = hamming(2 * FadeSamps);
            
            tmp = NaN;
            
            if whichCue == "top"
                tmp = obj.x1;
            elseif whichCue == "bottom"
                tmp = obj.x2;
            end
            
            cueAudio = tmp(1:CueLengthInSamps);
            
            %   Apply fade-out
            cueAudio(end-FadeSamps + 1:end) = ...
                cueAudio(end-FadeSamps+1:end) .* Window(FadeSamps+1:end);
        end
        
        function writeStimuli(obj)
            disp('Writing files...')
            obj.writeCues();
            obj.writeMixes();
            
            obj.makeLog();
            disp('Done.')
        end
        
        function writeCues(obj, WhichCue)
            DoBoth = false;
            
            if nargin == 1
                DoBoth = true;
                WhichCue = 0;
            end
            
            if (WhichCue == 1 || DoBoth)
                Basename1 = obj.getBasename(obj.Filename1);
                audiowrite(obj.STIM_DIR + Basename1 + "_q.wav", obj.Cue1, obj.fs);
            end
            
            if (WhichCue == 2 || DoBoth)
                Basename2 = obj.getBasename(obj.Filename2); 
                audiowrite(obj.STIM_DIR + Basename2 + "_q.wav", obj.Cue2, obj.fs);
            end
        end
        
        function writeMixes(obj, WhichMix)
            DoAll = false;
            
            MixName = obj.MelodyNum + "_" + obj.PartNum1 + "_" + obj.Instrument1 + ...
                "_" + obj.PartNum2 + "_" + obj.Instrument2;
            
            
            if nargin == 1
                DoAll = true;
                WhichMix = 0;
            end
            
            if (WhichMix == 1 || DoAll)
                audiowrite(obj.STIM_DIR + MixName + "_V_" + obj.PartNum1 + ".wav", ...
                    obj.MixVib1, obj.fs);
            end
            
            if (WhichMix == 2 || DoAll)
                audiowrite(obj.STIM_DIR + MixName + "_V_" + obj.PartNum2 + ".wav", ...
                    obj.MixVib2, obj.fs);
            end
            
            if (WhichMix == 3 || DoAll)
                audiowrite(obj.STIM_DIR + MixName + "_N.wav", obj.MixNoVib, obj.fs);
            end
            
            
        end

        function makeLog(obj)
            LogFilename = obj.MelodyNum + "_" + obj.Instrument1 + ...
                "_" + obj.Instrument2 + "_log.txt";
            
            LogPath = fullfile(obj.LOG_DIR, LogFilename);
            
            Today = datestr(datetime);
            
            fid = fopen(LogPath, 'wt');
            fprintf(fid, "Gain change x1:\t%s\n", obj.GainChange1);
            fprintf(fid, "Gain change x2:\t%s\n", obj.GainChange2);
            fprintf(fid, obj.Filename1 + "\t vib start:\t%s\n", obj.x1VibStart);
            fprintf(fid, obj.Filename2 + "\t vib start:\t%s\n", obj.x2VibStart);
            fprintf(fid, "\nDate:\t" + Today);
            fclose(fid);
        end
        
        function obj = inputCheck(obj) 
            obj.makeColumns();
            obj.checkMono();
            obj.matchLength();
        end
        
        function obj = makeColumns(obj)
            if size(obj.x1, 1) < size(obj.x1, 2)
                obj.x1 = obj.x1';
            end
            
            if size(obj.x2, 1) < size(obj.x2, 2)
                obj.x2 = obj.x2';
            end
        end
        
        function obj = checkMono(obj)
            if size(obj.x1, 2) ~= 1
                warning('%s is not a mono file. Taking first channel.', obj.Filename1);
                obj.x1 = obj.x1(:, 1);
            end
            
            if size(obj.x2, 2) ~= 1
                warning('%s is not a mono file. Taking first channel.', obj.Filename2);
                obj.x2 = obj.x2(:, 1);
            end
        end
        
        function obj = matchLength(obj)
            if length(obj.x1) > length(obj.x2)
                obj.x2 = [obj.x2; zeros(length(obj.x1) - length(obj.x2), 1)];
            else
                obj.x1 = [obj.x1; zeros(length(obj.x2) - length(obj.x1), 1)];
            end
        end
        
        function obj = matchLoudness(obj)
            % Match gains of both stimuli to magnitude reference.
            Mag1 = obj.calcPerceptMag(obj.x1);
            Mag2 = obj.calcPerceptMag(obj.x2);

            obj.x1 = obj.x1 * obj.MAGNITUDE_REF/Mag1;
            obj.x2 = obj.x2 * obj.MAGNITUDE_REF/Mag2;

            %   Divide gain by half to avoid clipping in mixes.
            obj.x1 = obj.x1/2;
            obj.x2 = obj.x2/2;
        end
        
        function [mixture, vibStartSeconds] = makeMixture(obj, whichVib)
            
            vibAudio = NaN;
            passAudio = NaN;
            
            if whichVib == "none"
                mixture = obj.x1 + obj.x2;
                vibStartSeconds = NaN;
                return
            end
            
            if whichVib == "top"                
                vibAudio = obj.x1;
                passAudio = obj.x2;
            elseif whichVib == "bottom"  
                vibAudio = obj.x2;
                passAudio = obj.x1;
            end
            
            
            vibAudio = obj.VibGenerator.addVibrato(vibAudio);
            
            mixture = vibAudio + passAudio;
            vibStartSeconds = obj.VibGenerator.VibStart / obj.fs;
            
        end
        
        function PerceptMag = calcPerceptMag(obj, x)
            Sones = acousticLoudness(x, obj.fs);
            Phons = obj.sones2phons(Sones);
            PerceptMag = db2mag(Phons);
        end
        
    end
    
    methods(Static)
        
        function Basename = getBasename(Filename)
            Splitname = split(Filename, '.');
            Basename = Splitname(1);
        end
        
        function Phons = sones2phons(Sones)
            Phons = 40 + 10*log2(Sones);
        end
        
    end
end