%"Copyright 2023 - 2024 The MathWorks, Inc."

function maxInstantaneousBandwidth = hMaxBandwidth(savedRadioSetupConfiguration)
%HMAXBANDWIDTH Returns the maximum instantaneous bandwidth for the specified saved radio setup configuration.
    radioHardware = hRadioHardware(savedRadioSetupConfiguration);
    switch radioHardware
        case "USRP N310"
            maxInstantaneousBandwidth = 100e6;
        case {"USRP N320","USRP N321","USRP X410"}
            maxInstantaneousBandwidth = 200e6;
        case "USRP X310"
            maxInstantaneousBandwidth = 160e6;
    end
end