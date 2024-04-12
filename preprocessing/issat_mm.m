function out_flag = issat_mm(data, maxVal, minVal, threshold)
% if data in any epoch is saturated (clipped), this is marked  
% 
% Inputs:
%   data:       1-channel EEG data with size (time X number of epochs)
%   maxVal:     maximum amplitude value to check for clipping  
%   minVal:     minimum amplitude value to check for clipping
%   threshold:  temporal length (samples) for clipping to mark an epoch as
%               artifactual 
%
% Output:
%   out_flag: marked data 
% ------------------------------------------------------------------------
% This function is part of the intraopEEGtoolbox: 
% https://github.com/mahtamsv/intraopEEGtoolbox
%
% Author: Mahta Mousavi, 2024 
% ------------------------------------------------------------------------

% flags are initialized to zero for all epochs 
out_flag = zeros(size(data,2),1);

for idx = 1:length(out_flag)

    temp = data(:, idx); 
    idx_max = find(temp==maxVal);
    idx_min = find(temp==minVal);

    if length(idx_max)+length(idx_min)>threshold
        out_flag(idx)=1;
    end
    
end
