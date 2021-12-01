clc;
close all;
clearvars;

% Read Audio File
filename = "audio_files/food_is_really_tasty.mp3";
[y, Fs] = audioread(filename);
info = audioinfo(filename);

% Audio preprocessing (adding padding)
y = addPadding(y);
t = linspace(0, length(y) / Fs, length(y));

% Plot Audio Signal
plot(t, y);
title("Time domain");
xlabel("Time");
ylabel("Amplitude");

% Apply CWT
SCALE_START = 10;
SCALE_END = 60;
CWTcoeffs = cwt(y, SCALE_START:SCALE_END, 'haar');
figure();
cwt(y, SCALE_START:SCALE_END, 'haar', 'plot');

% Compute Mean Signal from CWT Coeffs
mean_signal = meanFromCWT(CWTcoeffs, SCALE_START, SCALE_END);
figure();  
plot(t, mean_signal);
title("Mean signal");

% Divide mean-signal into 20 ms frames with 10 ms frame-shift
FRAME_LENGTH_IN_MILLI_SEC = 20;
FRAME_SHIFT_IN_MILLI_SEC = 10;
frames = divideIntoFrames(mean_signal, FRAME_LENGTH_IN_MILLI_SEC, ...
    FRAME_SHIFT_IN_MILLI_SEC, Fs);

% Compute and Plot Average Absolute Magnitude
AAM = mean(abs(frames), 2);
t1 = linspace(0, length(AAM) / (Fs / 240), length(AAM));
figure();
plot(t1, AAM);
title("Average absolute magnitude values");

% Remove inconsistencies by employing mean-smoothing of window size 40 ms
WINDOW_SIZE = 0.040;
mean_smooth = smoothdata(AAM, 'movmean', round((WINDOW_SIZE * Fs) / 240));
figure();
plot(t1, mean_smooth);
title("After mean smoothing with window size 40ms");

% Remove unwanted peaks using 15% threshold of maximum AAM of mean-signal
THRESHOLD = 0.15 * max(AAM);
thresholdedSignal = applyThreshold(mean_smooth, THRESHOLD);
figure();
plot(t1, thresholdedSignal);
title("After applying threshold of 15% of max of AAM signal");

% Plotting peaks and valleys to find VOP and VEP
figure();
DISTANCE = 0.15; % Only the highest peak is kept if multiple peaks are found within "DISTANCE" duration
[peaks, peaksLocation] = findpeaks(thresholdedSignal, Fs/240, ...
    'MinPeakDistance', 0.15);
findpeaks(thresholdedSignal, Fs / 240, 'MinPeakDistance', DISTANCE);
title("Peaks");

figure();
[valleys, valleyLocation] = findpeaks(-thresholdedSignal, Fs / 240, ...
    'MinPeakDistance', 0.15);
findpeaks(-thresholdedSignal, Fs / 240, 'MinPeakDistance', DISTANCE);
set(gca, 'YDir','reverse')
title("Valleys");

% Plotting the Vowel Region
vowelRegionPlot(peaksLocation, valleyLocation, 0.3, y, t);

function paddedSignal = addPadding(signal)
    signal = signal(:, 1);
    padval = 10 - mod(length(signal), 10);
    paddedSignal = vertcat(signal, zeros(padval, 1));
end

function meanSignal = meanFromCWT(CWTcoeffs, scale_start, scale_end)
    meanSignal = zeros(1, length(CWTcoeffs));
    for i = 1:length(CWTcoeffs)
        temp = 0;
        for j = 1:((scale_end - scale_start) + 1)
            temp = temp + CWTcoeffs(j, i);
        temp = temp / ((scale_end - scale_start) + 1);
        meanSignal(i) = temp;
        end
    end
end

function frames = divideIntoFrames(signal, frame_length_ms, frame_shift_ms, Fs)
    % NO_OF_FRAMES * 1000 / Fs = TIME_IN_MILLISECONDS
    frame_length = frame_length_ms * Fs / 1000;
    frame_shift = frame_shift_ms * Fs / 1000;
    
    total_length = length(signal);
    no_of_frames = floor(((total_length - frame_length) + frame_shift) / frame_shift);
    frames = zeros(no_of_frames, frame_length);
    
    temp = 0;
    for i = 1:no_of_frames
        for j = 1:frame_length
            frames(i, j) = signal(temp + 1);
            temp = temp + 1;
        end
        temp = temp - frame_shift;
    end
end

function thresholdedSignal = applyThreshold(signal, threshold)
    thresholdedSignal = signal;
    set_to_zero = thresholdedSignal < threshold;
    thresholdedSignal(set_to_zero) = 0;
end

function vowelRegionPlot(startPoint, endPoint, amplitude, input, t) 
    COLOR = [0.9 0.9 0.9];
    y_coordinates = [0 0 amplitude amplitude];
    figure();
    
    length_end = length(endPoint);
    length_start = length(startPoint);
    pk = 0;
    vl = 0;
    
    % Mapping a peak to its corresponding valley
    for i = 1:length_start
        if pk > length_start - 1 || vl > length_end - 1
            break;
        end
        val1 = startPoint(pk + 1);
        temp = vl + 1;
        
        for j = temp:length_end
            if endPoint(j) < val1
                vl = vl + 1;
                if pk > length_start - 1 || vl > length_end - 1
                    break;
                end
            else
                x_coordinates = [startPoint(pk + 1) endPoint(vl + 1) ...
                    endPoint(vl + 1) startPoint(pk + 1)];
                patch(x_coordinates, y_coordinates, COLOR);
                
                while startPoint(pk + 1) < endPoint(vl + 1)
                    pk = pk + 1;

                    if pk > length_start-1 || vl > length_end-1
                        break;
                    end
                end
                vl = vl + 1;
                if pk > length_start - 1 || vl > length_end - 1
                    break;
                end
                break;  
            end
        end
    end
    
    hold on;
    lh = plot(t, input);
    lh.Color = [lh.Color 0.7];
    hold off;
    title("Vowel Regions");
    xlabel("Time");
    ylabel("Amplitude");
end