%"Copyright 2023 - 2024 The MathWorks, Inc."

function data = captureUsingRadio(duration)

bbtrx = evalin('base','bbtrx');
captureLength = milliseconds(duration);
data = capture(bbtrx,captureLength);

end