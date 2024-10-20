%"Copyright 2023 - 2024 The MathWorks, Inc."

function [wav, paramsRADAR] = helperGenerateLFMRadarWaveforms_v1(generalParams, radarParams)
%% Setup Simulation Parameters
Fs = generalParams.sampleRate*1e6;
Ts = 1/Fs; % Sampling period (sec)
duration = generalParams.frameDuration*1e-3;
%% Generate training data
rangeN = alldivisors(Fs);
rangeN = rangeN(rangeN > 245 & rangeN < 245760); % these limits are choosen to vary pulse width form 1 us to 1 ms
rangeB = [Fs/25, Fs/5]; % Bandwidth (Hz) range
sweepDirections = radarParams.sweepDirection;


hLfm = phased.LinearFMWaveform(...
    'SampleRate',Fs,...
    'OutputFormat','Samples');
%Get randomized parameters
B = randOverInterval(rangeB);
Ncc = round(randOverInterval(rangeN));
% Generate LFM
hLfm.SweepBandwidth = B;
hLfm.SweepInterval = radarParams.sweepInterval;
hLfm.PulseWidth = Ncc*Ts; %pulse width form 1 us to 1 ms
hLfm.NumSamples = Fs*duration;
factor = randi([1 2],1);
hLfm.PRF = 1/(Ncc*Ts*factor);
hLfm.SweepDirection = sweepDirections{randi(2)};
wav = hLfm();
paramsRADAR = struct();
paramsRADAR.BW =  hLfm.SweepBandwidth;
paramsRADAR.PulseWidth = hLfm.PulseWidth;
paramsRADAR.PRF = hLfm.PRF;
paramsRADAR.SweepDirection = hLfm.SweepDirection;
paramsRADAR.SampleRate = Fs;
end
%% Subroutines
function val = randOverInterval(interval)
% Expect interval to be <1x2> with format [minVal maxVal]
val = (interval(2) - interval(1)).*rand + interval(1);
end
