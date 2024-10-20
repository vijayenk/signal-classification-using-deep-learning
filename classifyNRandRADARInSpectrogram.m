%"Copyright 2023 - 2024 The MathWorks, Inc."

function [labeledSpectrogram,predictedLabels] = classifyNRandRADARInSpectrogram(spectrogram, classNames)
%classNames = ["NR" "RADAR" "Noise"];
rxSpectrogram  = spectrogram;
net = evalin('base','net');
predictedLabels = semanticseg(rxSpectrogram,net);
labeledSpectrogram = helperSpecSenseGetIdentifiedSignals(rxSpectrogram,predictedLabels, ...
    classNames);

end