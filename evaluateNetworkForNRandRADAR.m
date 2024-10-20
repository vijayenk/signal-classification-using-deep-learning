%"Copyright 2023 - 2024 The MathWorks, Inc."

function [rcvdSpectrogram,labeledSpectrogram,hist,confusion] = evaluateNetworkForNRandRADAR(paramsGeneral,paramsEvaluate)
%% Test with Synthetic Signals
trainDir =  paramsGeneral.dataFolder;
classNames = paramsGeneral.classes;
pixelLabelID = [127 255 0];
net = evalin('base','net');
dataDir = fullfile(pwd,trainDir, paramsEvaluate.evaluationFolder);
imds = imageDatastore(dataDir,'IncludeSubfolders',false,'FileExtensions','.png');
pxdsResults = semanticseg(imds,net,"WriteLocation",tempdir);
pxdsTruth = pixelLabelDatastore(dataDir,classNames,pixelLabelID,...
    'IncludeSubfolders',false,'FileExtensions','.hdf');
metrics = evaluateSemanticSegmentation(pxdsResults,pxdsTruth);
f = figure('visible','off');
cm = confusionchart(f,metrics.ConfusionMatrix.Variables, ...
    classNames, Normalization='row-normalized');
cm.Title = 'Normalized Confusion Matrix';
saveas(f,'confusion','jpg');
confusion = imread('confusion.jpg');

imageIoU = metrics.ImageMetrics.MeanIoU;
f = figure('visible','off');
histogram(imageIoU)
grid on
xlabel('IoU')
ylabel('Number of Frames')
title('Frame Mean IoU')
saveas(f,'hist','jpg');
hist = imread('hist.jpg');

%% Label the signals
imgIdx = randi(numel(imds.Files),1);
[rcvdSpectrogram, fileInfo] = readimage(imds,imgIdx);
sprintf("The received spectrogram filename: %s",fileInfo.Filename)
[trueLabels, fileInfo] = readimage(pxdsTruth,imgIdx);
sprintf("The true label filename: %s",fileInfo.Filename)
[predictedLabels, fileInfo] = readimage(pxdsResults,imgIdx);
sprintf("The predicted label filename: %s",fileInfo.Filename)
[labeledSpectrogram,~] = classifyNRandRADARInSpectrogram(rcvdSpectrogram,classNames);
end