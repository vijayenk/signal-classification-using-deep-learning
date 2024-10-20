# ​​Signal Classification Using Deep Learning ​ 

[![View Signal Classification Using Deep Learning on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://www.mathworks.com/matlabcentral/fileexchange/####-Signal-Classification-Using-Deep-Learning)  

​​The goal of this MATLAB&reg; code is to accurately identify and classify 5G and RADAR signals within a wideband spectrum by training a deep learning network that can effectively estimate the positions of 5G and RADAR signals in both time and frequency domains.
This involves the use of semantic segmentation applied to spectrograms of wideband wireless signals, aiming to distinguish between these signal types. This code implements the following workflow of signal classifocation using deep learning. 

1. Generate Training Data
2. Train and validate the deep learning network
3. Test the trained network in simulation
4. Test the trained network using SDR Hardware       

## Setup 
To Run:
1. Launch the SpecSenseApp and press collect signal button  
2. Go to Train and Evaluate tab browse the folder where signals are collected
3. Press train button and then press load Network button to load the trained network
4. Press evalate to vsiualize the performance of the trained network 
5. Go to Software test tab, load the trained network and press loop to see the signal classification of stored signals
6. Go to Hardware test tab, configure the radio hardware load the trained network and press loop to see the signal classifcation of live signals 
    

Additional information about set up

### MathWorks Products (https://www.mathworks.com)

- [5G Toolbox&trade;](https://www.mathworks.com/products/5g.html)
- [Phased Array System Toolbox&trade;](https://www.mathworks.com/products/phased-array.html)
- [Communications Toolbox&trade;](https://www.mathworks.com/products/communications.html)
- [Computer Vision Toolbox&trade;](https://www.mathworks.com/products/computer-vision.html)
- [Deep Learning Toolbox&trade;](https://www.mathworks.com/products/deep-learning.html)
- [Wireless Testbench&trade;](https://www.mathworks.com/products/wireless-testbench.html)

### 3rd Party Products:
3p:
- [USRP&reg;](https://www.ettus.com/all-products/x310-kit/)

## Community Support
[MATLAB Central](https://www.mathworks.com/matlabcentral)

Copyright 2024 The MathWorks, Inc.