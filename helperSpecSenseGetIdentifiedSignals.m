%"Copyright 2023 - 2024 The MathWorks, Inc."

function maskedImg = helperSpecSenseGetIdentifiedSignals(rcvdSpect,segResults,classNames)
%helperSpecSenseDisplayIdentifiedSignals Label identified signals
%   helperSpecSenseDisplayIdentifiedSignals(P,SEG,C,FS,FC,TF) displays the
%   identified signals and their bands over the spectrogram, P. SEG is the
%   semantic segmentation results, C is the possible class names, FS is the
%   sampling rate, FC is the center frequency, and TF is the frame time.
%
%   FB = helperSpecSenseDisplayIdentifiedSignals(...) returns the estimated
%   frequency bands as a cell array, where the first cell contains results
%   for C(1) and the second cell contains the results for C(2). Each cell
%   contains a 1x2 array where the first element is the minimum frequency
%   and the second element is the maximum frequency for the corresponding
%   class.

%   Copyright 2021 The MathWorks, Inc.

imageSize = size(segResults);
if strcmp(classNames(1), "NR-1")
    labelNames = ["NR", "RADAR", "Noise", "NRSIG-1", "NRSIG-2"];
    segResults = preprocessSegResults(segResults,classNames);
elseif strcmp(classNames(1), "RADAR-1")
    labelNames = ["NR", "RADAR", "Noise", "RADARSIG-1", "RADARSIG-2"];
    segResults = preprocessSegResults(segResults,classNames);
else   
    labelNames = ["NR", "RADAR", "Noise"];
end    

numClasses = numel(labelNames);
cmap = cool(numClasses);


freqDim = 2;  % Put frequency on the x-axis
timeDim = 1;  % Put time on the y-axis

maskedImg = rcvdSpect;
for p=1:numel(labelNames)
    % Find the frequency band that contains pth class most probably. Assumes
    % a single band with type p
    if p == 3 % Do not include Noise
        continue;
    end    
    results = double(segResults);
    regionOfInterest = mode(results==p,timeDim);
    % Find the starting frequency of the band
    fminPixel = find(regionOfInterest, 1, 'first');
    % Find the ending frequency of the band
    fmaxPixel = find(regionOfInterest, 1, 'last');
    % Add mask with label
    if ~isempty(fminPixel)
        maskSig = false(imageSize);
        if freqDim == 2
            loc = [fminPixel+5 10];
            maskSig(:,fminPixel:fmaxPixel) = true;
        else
            loc = [10 fminPixel+5];
            maskSig(fminPixel:fmaxPixel,:) = true;
        end
        maskedImg = insertObjectMask(maskedImg,maskSig,'Color',cmap(p,:),'Opacity',0.3,'LineWidth',3);
        maskedImg = insertText(maskedImg,loc,labelNames(p),'BoxColor','w','BoxOpacity',0.3);
    end
end
end
function res = preprocessSegResults(segResults,classNames)
tDim =1;
catIndex  = 1;
if strcmp(classNames(1), "RADAR-1")
    catIndex =2;
end    

roi = mode(double(segResults)==catIndex,tDim);
roi = [zeros(1,1) roi ];
diffroi = diff(roi);

index = find(abs(diffroi)==1);
if numel(index) <= 2
    res  = segResults;
    return; % AI classified two bands as one 
elseif mod (numel(index),2) ~= 0 % the last band lies at the edge of the spectrogram
    index = [index 256];
end
filteredIndex = index;
segResults(:,filteredIndex(1):filteredIndex(2)) = classNames(1);
segResults(:,filteredIndex(3):filteredIndex(4)) = classNames(2);
    
res = segResults;
end