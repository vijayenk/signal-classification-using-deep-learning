%"Copyright 2023 - 2024 The MathWorks, Inc."

function antennaSelection = hCaptureAntennas(savedRadioSetupConfiguration)
%HCAPTUREANTENNAS Returns supported antenna names available for the specified saved radio setup configuration.
    radioHardware = hRadioHardware(savedRadioSetupConfiguration);
    switch radioHardware
        case "USRP N310"
            antennaSelection = ["RF0:RX2","RF1:RX2","RF2:RX2","RF3:RX2"];
        case {"USRP N320","USRP N321"}
            antennaSelection = ["RF0:RX2","RF1:RX2"];
        case "USRP X310"
            antennaSelection = ["RFA:RX2","RFB:RX2"];
        case "USRP X410"
            antennaSelection = ["DB0:RF0:RX1","DB0:RF1:RX1","DB1:RF0:RX1","DB1:RF1:RX1"];
    end
end