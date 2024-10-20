%"Copyright 2023 - 2024 The MathWorks, Inc."

function transmitUsingRadio_Test()
numSamples = 245760000*0.04;
txData = complex(-1 + 2.*rand(numSamples,1),-1 + 2.*rand(numSamples,1));
bbtrx = evalin('base','bbtrx');
stopTransmission(bbtrx);

%% Transmit Wireless Waveform
% Call the |transmit| function on the baseband transceiver object. Specify a
% continuous transmission.

transmit(bbtrx,txData,"continuous");

end