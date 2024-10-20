%"Copyright 2023 - 2024 The MathWorks, Inc."

function ret = InitSpecSense(sampleRate, centerFreq, gain, txgain)

%%
% hardware init
%% Set Up Radio
% Call the |radioConfigurations| function. The function returns all available
% radio setup configurations that you saved using the Radio Setup wizard. For
% more information, see <docid:wt_ug#mw_89442a8e-cf6d-402b-8bab-8b1978624290 Connect
% and Set Up NI(TM) USRP(TM) Radios>.
evalin( 'base', 'clear bbtrx' )
savedRadioConfigurations = radioConfigurations;
%%
% To update the dropdown menu with your saved radio setup configuration names,
% click *Update*. Then select the radio to use with this example.
ret =-1;
savedRadioConfigurationNames = [string({savedRadioConfigurations.Name})];
radio = savedRadioConfigurationNames(1) ;
if exist('bbtrx','var') == 0
    bbtrx = basebandTransceiver(radio);
end
%%
% * Set the |SampleRate| property to the sample rate of the generated waveform.
% * Set the |CenterFrequency| property to a value in the frequency spectrum
% indicating the position of the waveform transmission.
%sr = 245.76e6;     % MHz
%Fc = 4e9;
Fc = centerFreq*1e9;
sr = sampleRate*1e6;
bbtrx.SampleRate = sr;
bbtrx.TransmitCenterFrequency = Fc;
bbtrx.CaptureCenterFrequency = bbtrx.TransmitCenterFrequency;
bbtrx.CaptureDataType = 'double';
%%
% Set the |TransmitRadioGain| and |CaptureRadioGain| properties according to
% the local wireless channel.

bbtrx.TransmitRadioGain = txgain;
bbtrx.CaptureRadioGain = gain;
transmitAntennaSelection = hTransmitAntennas(radio);
captureAntennaSelection = hCaptureAntennas(radio);
bbtrx.TransmitAntennas = transmitAntennaSelection(1);
bbtrx.CaptureAntennas = captureAntennaSelection(1);
assignin('base','bbtrx',bbtrx);

ret = 1;
end