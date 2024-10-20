%"Copyright 2023 - 2024 The MathWorks, Inc."

function maxSampleRate = hMaxSampleRate(savedRadioSetupConfiguration)
%HMAXSAMPLERATE Returns the maximum sample rate available for the specified saved radio setup configuration.
    radioHardware = hRadioHardware(savedRadioSetupConfiguration);
    switch radioHardware
        case "USRP N310"
            maxSampleRate = 153.6e6;
        case {"USRP N320","USRP N321","USRP X410"}
            maxSampleRate = 250e6;
        case "USRP X310"
            maxSampleRate = 200e6;
    end
end