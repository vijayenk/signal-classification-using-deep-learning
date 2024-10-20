%"Copyright 2023 - 2024 The MathWorks, Inc."

function radioHardware = hRadioHardware(savedRadioSetupConfiguration)
%HRADIOHARDWARE Returns the physical radio hardware name associated with the saved radio setup configuration.
    radios = radioConfigurations;
    savedConfigurations = [string({radios.Name})];
    radioIndex = savedConfigurations == savedRadioSetupConfiguration;
    radioHardware = radios(radioIndex).Hardware;
end