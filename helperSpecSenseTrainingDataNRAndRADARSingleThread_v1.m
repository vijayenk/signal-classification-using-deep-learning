%"Copyright 2023 - 2024 The MathWorks, Inc."

function [nrImg, radarImg, combImg, combTruth] =helperSpecSenseTrainingDataNRAndRADARSingleThread_v1(generalParams,nrParams, radarParams, Idx,USRPPresent, sigStoreFreq)
%helperSpecSenseTrainingData Training data for spectrum sensing
%   helperSpecSenseTrainingData(N,S,DIR,NSF,FS) generates training data for
%   the Spectrum Sensing with Deep Learning to Identify 5G and LTE Signals
%   example. Traning data is the image of the spectrogram of baseband
%   frames together with the pixel labels. The function generates N groups
%   of frames where each group has an LTE only frame, 5G only frame and a
%   frame that contains both 5G and LTE signals. Single signal images are
%   saved in DIR. Combined signal images are saved to DIR/LTE_NR. The
%   images have a size of S, which is a 1x2 vector or integers. The sample
%   rate of the signals is FS. Each frame is NSF subframes long.
%
%   5G NR signals are based on SISO configuration for frequency range 1
%   (FR1). LTE signals are based on SISO configuration with frequency
%   division duplexing (FDD).
%
%   See also helperSpecSenseNRSignal, helperSpecSenseLTESignal.

%   Copyright 2021 The MathWorks, Inc.
combinedDir = fullfile(generalParams.dataFolder,'RADAR_NR');
if ~exist(combinedDir,'dir')
    mkdir(combinedDir)
end

imageSize = generalParams.imageSize;
trainDir = generalParams.dataFolder;
numOfFrames = generalParams.numOfFrames;
% 5G Parameters
SCSVec = nrParams.SCS;
BandwidthVec = nrParams.bandwidth; % [60 80 90 100]
%SCSVec = [30];
%BandwidthVec = [30 40 50 60 80 90 100]; % [60 80 90 100]
outFs = generalParams.sampleRate*1e6; 
numSF = generalParams.frameDuration;  % Time shift in milliseconds
maxTimeShift = numSF;
SSBPeriodVec = nrParams.ssbPeriod(3); %[5 10 20 40 80 160] 20 is most frequenctly found OTA

% Channel Parameters
SNRdBVec = {60, 65, 70, 75};   % dB
%SNRdBVec = {-6, 0, 5, 10, 15, 20, 25 ,30};
DopplerVec = nrParams.doppler;
CenterFrequencyVec = generalParams.centerFreq*1e9;
Scaling = [0.25, 4]; % upto 12 dB differnce
SNRdB = SNRdBVec{randi([1 length(SNRdBVec)])};
% Generate 5G signal
scs = SCSVec(randi([1 length(SCSVec)])); %#ok<*PFBNS>
nrChBW = BandwidthVec(randi([1 length(BandwidthVec)]));
timeShift = rand()*maxTimeShift;
SSBPeriod = SSBPeriodVec(randi([1 length(SSBPeriodVec)]));
[txWave5G, waveinfo5G] = helperSpecSenseNRSignal_v1(scs,nrChBW,SSBPeriod,timeShift,numSF,outFs);
%txWave5G = txWave5G / max(abs(txWave5G));
% Decide on channel parameters

%NRGain = sqrt(pRMSRadar/pRMSNr);
%txWave5G = txWave5G*NRGain;
Doppler = DopplerVec(randi([1 length(DopplerVec)]));
Fc = CenterFrequencyVec(randi([1 length(CenterFrequencyVec)]));

% Save channel impared 5G signal spectrogram and pixel labels
sr = waveinfo5G.ResourceGrids.Info.SampleRate;
rxWave5G = multipathChannel5G(txWave5G,sr,Doppler,Fc);
rxWave5GWOFreqOffset = rxWave5G;
pRMSNr = norm(rxWave5G,2)^2/numel(rxWave5G);
if strcmp(USRPPresent, "Yes")
    transmitUsingRadio(rxWave5G);
    pause(.1);
    duration = generalParams.frameDuration;
    rxWave5G = captureUsingRadio(duration);
    stopTransmitRadio();
else    
    rxWave5G = awgn(rxWave5G,SNRdB);
end
%rxWave5G  = loopbackN320(rxWave5G, numSF);

[rxWave5G,freqOff] = shiftInFrequency(rxWave5G,waveinfo5G.Bandwidth,sr,imageSize(2));
params5G = struct();
params5G.SCS = scs;
params5G.BW = nrChBW*1e6;
params5G.SSBPeriod = SSBPeriod;
params5G.SNRdB = SNRdB;
params5G.Doppler = Doppler;
params5G.Info = waveinfo5G;
params5G.txpower = pow2db(bandpower(txWave5G));
params5G.rxpower = pow2db(bandpower(rxWave5G));
nrImg = saveSpectrogramImage(rxWave5G,sr,trainDir,'NR',imageSize, Idx);
if mod(Idx,sigStoreFreq) == 0
 saveIQ(rxWave5GWOFreqOffset,'NR',trainDir,Idx);    
end
freqPos = freqOff' + [-waveinfo5G.Bandwidth/2 +waveinfo5G.Bandwidth/2]';
freqPerPixel = sr / imageSize(2);
freqPixels = floor((sr/2 + freqPos) / freqPerPixel) + 1;
params5G.freqPixels = freqPixels;
savePixelLabelImage({[]}, freqPos, {'NR'}, {'Noise','NR','RADAR'}, sr, params5G, trainDir, imageSize, Idx);
%Generate radar signals
[txWaveRADAR, waveinfoRADAR] = helperGenerateLFMRadarWaveforms_v1(generalParams, radarParams);
sr = waveinfoRADAR.SampleRate;

rxWaveRADAR = ricianChannelRadar(txWaveRADAR, sr);
rxWaveRADAR = ricianChannelRadar(rxWaveRADAR, sr); % Emulate the RADAR echo signal
pRMSRadar = norm(rxWaveRADAR,2)^2/numel(rxWaveRADAR);
radarAttenuation = sqrt(pRMSNr/pRMSRadar);
rxWaveRADAR = rxWaveRADAR*radarAttenuation; % Normalize the power w.r.t NR
rxWaveRADAR = rxWaveRADAR*randOverInterval(Scaling);
waveinfoRADAR.rxpower = pow2db(bandpower(rxWaveRADAR));
waveinfoRADAR.txpower = pow2db(bandpower(txWaveRADAR));

rxWavRADARWOFreqOffset = rxWaveRADAR;
if strcmp(USRPPresent, "Yes")
    transmitUsingRadio(rxWaveRADAR);
    pause(.1);
    duration = generalParams.frameDuration;
    rxWaveRADAR = captureUsingRadio(duration);
    stopTransmitRadio();
else    
    rxWaveRADAR = awgn(rxWaveRADAR, SNRdB);
end

[rxWaveRADAR,waveinfoRADAR.freqOff] = shiftInFrequency(rxWaveRADAR,waveinfoRADAR.BW,sr,imageSize(2));
radarImg = saveSpectrogramImage(rxWaveRADAR,outFs,trainDir,'RADAR',imageSize,Idx);
if mod(Idx,sigStoreFreq) == 0
 saveIQ(rxWavRADARWOFreqOffset,'RADAR',trainDir,Idx);
end
freqPerPixel = sr / imageSize(2);
freqPos = waveinfoRADAR.freqOff' + [-waveinfoRADAR.BW/2 +waveinfoRADAR.BW/2]';
freqPixels = floor((sr/2 + freqPos) / freqPerPixel) + 1;
waveinfoRADAR.freqPixels = freqPixels;
savePixelLabelImage({[]}, freqPos, {'RADAR'}, {'Noise','NR','RADAR'}, outFs, waveinfoRADAR, trainDir, imageSize,Idx);
% Save combined image
assert(waveinfo5G.ResourceGrids.Info.SampleRate == waveinfoRADAR.SampleRate)

sr = waveinfoRADAR.SampleRate;
comb = comm.MultibandCombiner("InputSampleRate",sr, ...
    "OutputSampleRateSource","Property",...
    "OutputSampleRate",sr);
% Decide on the frequency space between LTE and 5G
maxFreqSpace = (sr - waveinfo5G.Bandwidth - waveinfoRADAR.BW);
if maxFreqSpace < 0
    return;
end
factor = ((1 - 0.1)*rand() + 0.1); % Ensures a non-zero gap between two bands
freqSpace = round(factor*maxFreqSpace/1e6)*1e6;
maxStartFreq = sr - (waveinfo5G.Bandwidth + waveinfoRADAR.BW + freqSpace) - freqPerPixel;

% Decide if 5G or RADAR is on the left

RADARFirst = randi([0 1]);
if RADARFirst
    combIn = [rxWavRADARWOFreqOffset, rxWave5GWOFreqOffset];
    %combIn = [txWaveRADAR, txWave5G];
    labels = {'RADAR','NR'};
    startFreq = round(rand()*maxStartFreq/1e6)*1e6 - sr/2 + waveinfoRADAR.BW/2;
    bwMatrix = [-waveinfoRADAR.BW/2 +waveinfoRADAR.BW/2; -waveinfo5G.Bandwidth/2 +waveinfo5G.Bandwidth/2]';
else
    combIn = [rxWave5GWOFreqOffset rxWavRADARWOFreqOffset];
    %combIn = [txWave5G txWaveRADAR];
    labels = {'NR','RADAR'};
    startFreq = round(rand()*maxStartFreq/1e6)*1e6 - sr/2 + waveinfo5G.Bandwidth/2;
    bwMatrix = [-waveinfo5G.Bandwidth/2 +waveinfo5G.Bandwidth/2; -waveinfoRADAR.BW/2 +waveinfoRADAR.BW/2]';
end
comb.FrequencyOffsets = [startFreq startFreq+waveinfoRADAR.BW/2 + freqSpace + waveinfo5G.Bandwidth/2];
%txWave = comb(combIn);

rxWave = comb(combIn);

% Pass through channel
%rxWaveChan = multipathChannel5G(txWave, sr, Doppler, Fc);

% Add noise
if strcmp(USRPPresent, "Yes")
    transmitUsingRadio(rxWave);
    pause(.1);
    duration = generalParams.frameDuration;
    rxWave = captureUsingRadio(duration);
    stopTransmitRadio();
else    
    rxWave = awgn(rxWave,SNRdB);
end

%rxWave  = loopbackN320(rxWave, numSF);

% Create spectrogram image
paramsComb = struct();
paramsComb.SCS = scs;
paramsComb.BW = nrChBW;
paramsComb.SNRdB = SNRdB;
paramsComb.Doppler = Doppler;
paramsComb.SNRdB = SNRdB;
paramsComb.Doppler = Doppler;

paramsComb.RADARBandwidth =  waveinfoRADAR.BW;
paramsComb.PulseWidth = waveinfoRADAR.PulseWidth;
paramsComb.PRF = waveinfoRADAR.PRF;
paramsComb.SweepDirection = waveinfoRADAR.SweepDirection;
paramsComb.freqOff = waveinfoRADAR.freqOff;
paramsComb.SampleRate = waveinfoRADAR.SampleRate;
paramsComb.Labels = labels;
paramsComb.freqPos = comb.FrequencyOffsets + bwMatrix;
freqPixels = floor((sr/2 + freqPos) / freqPerPixel) + 1;
paramsComb.freqPixels = freqPixels;


combImg = saveSpectrogramImage(rxWave,sr,fullfile(trainDir,'RADAR_NR'),...
    'RADAR_NR',imageSize,Idx);
freqPos = comb.FrequencyOffsets + bwMatrix;

freqPixels = floor((sr/2 + freqPos) / freqPerPixel) + 1;
paramsComb.freqPixels = freqPixels;
combTruth = savePixelLabelImage({[],[]}, freqPos, labels, {'Noise','NR','RADAR'}, ...
    sr, paramsComb, fullfile(trainDir,'RADAR_NR'), imageSize,Idx);

end


% Helper Functions
function [y,freqOff] = shiftInFrequency(x, bw, sr, numFreqPixels)
freqOffset = comm.PhaseFrequencyOffset(...
    'SampleRate',sr);

maxFreqShift = (sr-bw) / 2 - sr/numFreqPixels;
freqOff = (2*rand()-1)*maxFreqShift;
freqOffset.FrequencyOffset = freqOff;
y = freqOffset(x);
end

function y = multipathChannel5G(x, sr, doppler, fc)
% Pass through channel
chan = nrCDLChannel('DelayProfile','Custom',... % one path with
    'SampleRate',sr,...
    'MaximumDopplerShift',doppler,...
    'CarrierFrequency',fc,...
    'Seed', randi(10e3,1,1)); % Random seed to create varying doppler
chan.TransmitAntennaArray.Size = [1 1 1 1 1];
chan.TransmitAntennaArray.Element = 'isotropic';
chan.ReceiveAntennaArray.Size = [1 1 1 1 1];
y = chan(x);
end

function y = ricianChannelRadar(x, Fs)
multipathChannel = comm.RicianChannel(...
    'SampleRate', Fs, ...
    'PathDelays', [0 1.8 3.4]/Fs, ...
    'AveragePathGains', [0 -2 -10], ...
    'KFactor', 4, ...
    'MaximumDopplerShift', 4);
y = multipathChannel(x);
end
function rxSpectrogram = saveSpectrogramImage(rxWave,sr,folder,label,imageSize, idx)
Nfft = 4096;

rxSpectrogram = helperSpecSenseSpectrogramImage(rxWave,Nfft,sr,imageSize);

% Create file name
fname = fullfile(folder, [label '_frame_' strrep(num2str(idx),' ','')]);
fname = fname + ".png";
imwrite(rxSpectrogram, fname)
end

function img = savePixelLabelImage(timePos, freqPos, label, pixelClassNames, sr, params, folder, imSize, idx)
% Create file name
if numel(label) == 1
    lbl = label{1};
else
    lbl = 'RADAR_NR';
end
fname = fullfile(folder, [lbl '_frame_' strrep(num2str(idx),' ','')]);
fnameParams = fname + ".mat";
save(fnameParams, "params");
data = uint8(zeros(imSize(1), imSize(2)));
for p=1:length(label)
    pixelValue = floor((find(strcmp(label{p}, pixelClassNames))-1)*255/(numel(pixelClassNames)-1));

    freqPerPixel = sr / imSize(2);
    freqPixels = floor((sr/2 + freqPos(:,p)) / freqPerPixel) + 1;

    if isempty(timePos{p})
        timePixels = 1:imSize(1);
    end
    if freqPixels(1) < 1
        freqPixels(1) = 1;
    end
    if freqPixels(2) > 256
        freqPixels(2) = 256;
    end
    data(timePixels,freqPixels(1):freqPixels(2)) = uint8(pixelValue);
end
img = data;

fnameLabels = fname + ".hdf";
data = imresize(data,[imSize(1), imSize(2)]);
imwrite(data,fnameLabels,'hdf');

fnameLabelsImage = fname + "_label" +".jpg";
imwrite(data,fnameLabelsImage,'jpg');


end
function saveIQ(iq,label,folder, idx)
fname = fullfile(folder, [label '_frame_' strrep(num2str(idx),' ','')]);
fname = fname + ".bb";
bbw = comm.BasebandFileWriter(fname);
bbw(iq);
end
function val = randOverInterval(interval)
% Expect interval to be <1x2> with format [minVal maxVal]
val = (interval(2) - interval(1)).*rand + interval(1);
end