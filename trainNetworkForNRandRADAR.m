%"Copyright 2023 - 2024 The MathWorks, Inc."

function trainNetworkForNRandRADAR(paramsGeneral, paramsNetwork)
%% Load Training Data
trainDir = paramsGeneral.dataFolder;
imageSize = (paramsGeneral.imageSize)';
imds = imageDatastore(trainDir,'IncludeSubfolders',false,'FileExtensions','.png');
classNames = (paramsGeneral.classes)';
pixelLabelID = [127 255 0];
pxdsTruth = pixelLabelDatastore(trainDir,classNames,pixelLabelID,...
    'IncludeSubfolders',false,'FileExtensions','.hdf');
%% Analyze Dataset Statistics
 tbl = countEachLabel(pxdsTruth);

%% Prepare Training, Validation, and Test Sets
[imdsTrain,pxdsTrain,imdsVal,pxdsVal] = helperSpecSensePartitionData(imds,pxdsTruth,[80 20]);
cdsTrain = combine(imdsTrain,pxdsTrain);
cdsVal = combine(imdsVal,pxdsVal);

% Apply a transform to resize the image and pixel label data to the desired
% size.
cdsTrain = transform(cdsTrain, @(data)preprocessTrainingData(data,imageSize));
cdsVal = transform(cdsVal, @(data)preprocessTrainingData(data,imageSize));

%% Train deep neural network
baseNetwork = paramsGeneral.baseNetwork;
lgraph = deeplabv3plusLayers(imageSize,numel(classNames),baseNetwork);
%% Balance Classes Using Class Weighting
imageFreq = tbl.PixelCount ./ tbl.ImagePixelCount;
classWeights = median(imageFreq) ./ imageFreq;
pxLayer = pixelClassificationLayer('Name','labels','Classes',tbl.Name,'ClassWeights',classWeights);
lgraph = replaceLayer(lgraph,"classification",pxLayer);

%% Select Training Options
opts = trainingOptions(paramsNetwork.solverName,...
    MiniBatchSize = 40,...
    MaxEpochs = paramsNetwork.maxEpochs, ...
    LearnRateSchedule = "piecewise",...
    InitialLearnRate =  paramsNetwork.InitialLearnRate,...
    LearnRateDropPeriod = 10,...
    LearnRateDropFactor = 0.1,...
    ValidationData = cdsVal,...
    ValidationPatience = 5,...
    Shuffle="every-epoch",...
    OutputNetwork = "best-validation-loss",...
    Plots = paramsNetwork.plots);

    [net,trainInfo] = trainNetwork(cdsTrain,lgraph,opts); %#ok<UNRCH>
    save (paramsGeneral.networkName,'net');

end
%% Subroutines 
function data = preprocessTrainingData(data, imageSize)
% Resize the training image and associated pixel label image.
data{1} = imresize(data{1},imageSize);
data{2} = imresize(data{2},imageSize);
end