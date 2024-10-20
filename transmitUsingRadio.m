%"Copyright 2023 - 2024 The MathWorks, Inc."

function transmitUsingRadio(txData)

bbtrx = evalin('base','bbtrx');
stopTransmission(bbtrx);

%% Transmit Wireless Waveform
% Call the |transmit| function on the baseband transceiver object. Specify a
% continuous transmission.

transmit(bbtrx,txData,"continuous");

end