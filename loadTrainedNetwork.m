%"Copyright 2023 - 2024 The MathWorks, Inc."

function ret = loadTrainedNetwork(netName)
ret =-1;
if isempty(netName) == 1
    return;
end    
%fileName = strcat(netName,'.mat');
fileName = netName;
netPath  = fullfile(pwd, fileName);
if exist(netPath,'file') == 0
    return;
end
evalin( 'base', 'clear net' );
evalin( 'base', 'clear netName' );
load(netName,'net');
assignin('base','net',net);
net = evalin('base','net');
if isa(net,'DAGNetwork')
    ret =1;
end
end