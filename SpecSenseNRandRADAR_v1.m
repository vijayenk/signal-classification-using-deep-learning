%"Copyright 2023 - 2024 The MathWorks, Inc."

function [txSpectrogram, txWave, gTruth, sig1Info, sig2Info] = SpecSenseNRandRADAR_v1(sig1FilePath, sig2FilePath, sr, ...
    SNRdB, imageSize, Nfft, sigType)

[fPath, fName] = fileparts(sig1FilePath);
fExt = '.mat';
sig1ParamsFilePath = strcat(fPath,'\',fName,fExt);
fprintf('%s\n', sig1ParamsFilePath);
waveinfosig1 = load(sig1ParamsFilePath);
%waveinfosig1.params.BW = waveinfosig1.params.BW;

[fPath, fName] = fileparts(sig2FilePath);
fExt = '.mat';
sig2ParamsFilePath = strcat(fPath,'\',fName,fExt);
fprintf('%s\n', sig2ParamsFilePath);
waveinfosig2 = load(sig2ParamsFilePath);
%sr = waveinfosig2.params.SampleRate;
bbrsig2 = comm.BasebandFileReader(sig2FilePath, SamplesPerFrame=inf);
rxWavsig2 = bbrsig2();
bbrsig1 = comm.BasebandFileReader(sig1FilePath, SamplesPerFrame=inf);
rxWavesig1 = bbrsig1();
comb = comm.MultibandCombiner("InputSampleRate",sr, ...
    "OutputSampleRateSource","Property",...
    "OutputSampleRate",sr);
% Decide on the frequency space between LTE and sig1
maxFreqSpace = (sr - waveinfosig1.params.BW - waveinfosig2.params.BW);
if maxFreqSpace < 0
    return;
end
factor = ((1 - 0.1)*rand() + 0.1); % Ensures a non-zero gap between two bands
freqSpace = round(factor*maxFreqSpace/1e6)*1e6;

freqPerPixel = sr / imageSize(2);
maxStartFreq = sr - (waveinfosig1.params.BW + waveinfosig2.params.BW + freqSpace) - freqPerPixel;

% Decide if sig1 or sig2 is on the left
sig2First = randi([0 1]);
if sig2First
    combIn = [rxWavsig2, rxWavesig1];
    if strcmp(sigType, "NR Only")
        labels = {'NR','NR'};
    elseif strcmp(sigType, "RADAR Only")
        labels = {'RADAR','RADAR'};
    else
        labels = {'RADAR','NR'};
    end
    startFreq = round(rand()*maxStartFreq/1e6)*1e6 - sr/2 + waveinfosig2.params.BW/2;
    bwMatrix = [-waveinfosig2.params.BW/2 +waveinfosig2.params.BW/2; -waveinfosig1.params.BW/2 +waveinfosig1.params.BW/2]';
else
    combIn = [rxWavesig1 rxWavsig2];
    if strcmp(sigType, "NR Only")
        labels = {'NR','NR'};
    elseif strcmp(sigType, "RADAR Only")
        labels = {'RADAR','RADAR'};
    else
        labels = {'NR','RADAR'};
    end
    startFreq = round(rand()*maxStartFreq/1e6)*1e6 - sr/2 + waveinfosig1.params.BW/2;
    bwMatrix = [-waveinfosig1.params.BW/2 +waveinfosig1.params.BW/2; -waveinfosig2.params.BW/2 +waveinfosig2.params.BW/2]';

end
comb.FrequencyOffsets = [startFreq startFreq+waveinfosig2.params.BW/2 + freqSpace + waveinfosig1.params.BW/2];
%txWave = comb(combIn);
rxWave = comb(combIn);
% Add noise
rxWave = awgn(rxWave,SNRdB);
txWave = rxWave;
txSpectrogram = helperSpecSenseSpectrogramImage(rxWave,Nfft,sr,imageSize);
paramsTest = struct();
paramsTest.sr = sr;
paramsTest.sig1BW = waveinfosig1.params.BW;
paramsTest.sig2BW = waveinfosig2.params.BW;
paramsTest.freqSpace = freqSpace;
paramsTest.freqOffset = comb.FrequencyOffsets;
fnameParams = "TestParams.mat";
save(fnameParams, "paramsTest")
release(bbrsig1);
release(bbrsig2);
freqPos = comb.FrequencyOffsets + bwMatrix;

gTruth = getPixelLabelImage({[],[]}, freqPos, labels, {'Noise','NR','RADAR'},sr,imageSize);

if strcmp(sigType, "NR Only")
    sig1Info =["Subcarrier Spacing(KHz): ";"Bandwidth(MHz): ";"SSBPeriod(ms): ";"Doppler(Hz): " ];
    sig1Info(1) = strcat(sig1Info(1),string(waveinfosig1.params.SCS));
    sig1Info(2) = strcat(sig1Info(2),string(waveinfosig1.params.BW/1e6));
    sig1Info(3) = strcat(sig1Info(3),string(waveinfosig1.params.SSBPeriod));
    sig1Info(4) = strcat(sig1Info(4),string(waveinfosig1.params.Doppler));
    sig2Info =["Subcarrier Spacing(KHz): ";"Bandwidth(MHz): ";"SSBPeriod(ms): ";"Doppler(Hz): " ];
    sig2Info(1) = strcat(sig2Info(1),string(waveinfosig2.params.SCS));
    sig2Info(2) = strcat(sig2Info(2),string(waveinfosig2.params.BW/1e6));
    sig2Info(3) = strcat(sig2Info(3),string(waveinfosig2.params.SSBPeriod));
    sig2Info(4) = strcat(sig2Info(4),string(waveinfosig2.params.Doppler));
elseif strcmp(sigType, "RADAR Only")
    sig1Info =["Pulse width(uS): ";"Bandwidth(MHz): ";"PRF(KHz): ";"Sweep Dir: " ];
    sig1Info(1) = strcat(sig1Info(1),string(waveinfosig1.params.PulseWidth*1e6));
    sig1Info(2) = strcat(sig1Info(2),string(waveinfosig1.params.BW/1e6));
    sig1Info(3) = strcat(sig1Info(3),string(waveinfosig1.params.PRF/1e3));
    sig1Info(4) = strcat(sig1Info(4),string(waveinfosig1.params.SweepDirection));
    sig2Info =["Pulse width(uS): ";"Bandwidth(MHz): ";"PRF(KHz): ";"Sweep Dir: " ];
    sig2Info(1) = strcat(sig2Info(1),string(waveinfosig2.params.PulseWidth*1e6));
    sig2Info(2) = strcat(sig2Info(2),string(waveinfosig2.params.BW/1e6));
    sig2Info(3) = strcat(sig2Info(3),string(waveinfosig2.params.PRF/1e3));
    sig2Info(4) = strcat(sig2Info(4),string(waveinfosig2.params.SweepDirection));
elseif strcmp(sigType, "NR and RADAR")
    sig1Info =["Subcarrier Spacing(KHz): ";"Bandwidth(MHz): ";"SSBPeriod(ms): ";"Doppler(Hz): " ];
    sig1Info(1) = strcat(sig1Info(1),string(waveinfosig1.params.SCS));
    sig1Info(2) = strcat(sig1Info(2),string(waveinfosig1.params.BW/1e6));
    sig1Info(3) = strcat(sig1Info(3),string(waveinfosig1.params.SSBPeriod));
    sig1Info(4) = strcat(sig1Info(4),string(waveinfosig1.params.Doppler));
    sig2Info =["Pulse width(uS): ";"Bandwidth(MHz): ";"PRF(KHz): ";"Sweep Dir: " ];
    sig2Info(1) = strcat(sig2Info(1),string(waveinfosig2.params.PulseWidth*1e6));
    sig2Info(2) = strcat(sig2Info(2),string(waveinfosig2.params.BW/1e6));
    sig2Info(3) = strcat(sig2Info(3),string(waveinfosig2.params.PRF/1e3));
    sig2Info(4) = strcat(sig2Info(4),string(waveinfosig2.params.SweepDirection));
 elseif strcmp(sigType, "RADAR and NR")
    sig1Info =["Subcarrier Spacing(KHz): ";"Bandwidth(MHz): ";"SSBPeriod(ms): ";"Doppler(Hz): " ];
    sig1Info(1) = strcat(sig1Info(1),string(waveinfosig2.params.SCS));
    sig1Info(2) = strcat(sig1Info(2),string(waveinfosig2.params.BW/1e6));
    sig1Info(3) = strcat(sig1Info(3),string(waveinfosig2.params.SSBPeriod));
    sig1Info(4) = strcat(sig1Info(4),string(waveinfosig2.params.Doppler));
    sig2Info =["Pulse width(uS): ";"Bandwidth(MHz): ";"PRF(KHz): ";"Sweep Dir: " ];
    sig2Info(1) = strcat(sig2Info(1),string(waveinfosig1.params.PulseWidth*1e6));
    sig2Info(2) = strcat(sig2Info(2),string(waveinfosig1.params.BW/1e6));
    sig2Info(3) = strcat(sig2Info(3),string(waveinfosig1.params.PRF/1e3));
    sig2Info(4) = strcat(sig2Info(4),string(waveinfosig1.params.SweepDirection));   
end
end

function data = getPixelLabelImage(timePos, freqPos, label, pixelClassNames, sr, imSize)
% Create file name
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
end