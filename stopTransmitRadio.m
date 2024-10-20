%"Copyright 2023 - 2024 The MathWorks, Inc."

function stopTransmitRadio()

bbtrx = evalin('base','bbtrx');
stopTransmission(bbtrx);

end