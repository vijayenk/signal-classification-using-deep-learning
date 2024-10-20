%"Copyright 2023 - 2024 The MathWorks, Inc."

function antennaSelection = hTransmitAntennas(savedRadioSetupConfiguration)
%HTRANSMITANTENNAS Returns supported transmit antenna names available for the specified saved radio setup configuration.
    radioHardware = hRadioHardware(savedRadioSetupConfiguration);
    switch radioHardware
        case "USRP N310"
            antennaSelection = ["RF0:TX/RX","RF1:TX/RX","RF2:TX/RX","RF3:TX/RX"];
        case {"USRP N320","USRP N321"}
            antennaSelection = ["RF0:TX/RX","RF1:TX/RX"];
        case "USRP X310"
            antennaSelection = ["RFA:TX/RX","RFB:TX/RX"];
        case "USRP X410"
            antennaSelection = ["DB0:RF0:TX/RX0","DB0:RF1:TX/RX0","DB1:RF0:TX/RX0","DB1:RF1:TX/RX0"];
    end
end