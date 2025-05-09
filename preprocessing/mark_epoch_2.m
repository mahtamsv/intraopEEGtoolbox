function idx_outlier_2 = mark_epoch_2(EEG, epoch_length, idx_outlier_1)
%
% Inputs:
%   EEG:   EEG data, instance of EEGLAB data structure 
%   epoch_length: epoch length  
%   idx_outlier_1: epoch indices marked from mark_epoch_1.m  
%
% Output:
%   idx_outlier_2: epoch indices marked to be removed later  
% ------------------------------------------------------------------------
% This function is part of the intraopEEGtoolbox: 
% https://github.com/mahtamsv/intraopEEGtoolbox
%
% Author: Mahta Mousavi, 2024 
% ------------------------------------------------------------------------

% equivalent of 0.1 second
outlier_2_thresh = floor(EEG.srate*0.1); 

% epoch the EEG data
EEG_epoched = pop_epoch( EEG, {'X'}, [0, epoch_length]);
output = double(EEG_epoched.data);
% remove the epochs that were marked before from mark_epoch_1.m
output_v1 = output(:,:,not(idx_outlier_1));

% mark epochs that saturate at max or min of every channel 
out_flag = zeros(size(output_v1,1), size(output_v1,3)); 
for idx_chan = 1:size(output_v1,1)
    temp = squeeze(output_v1(idx_chan,:,:)); 
    maxVal = max(max(temp)); 
    minVal = min(min(temp)); 
    out_flag(idx_chan,:) = issat_mm(temp, maxVal, minVal, outlier_2_thresh); 
end

temp_idx = sum(out_flag,1);
temp_idx(temp_idx>0)=1;
idx_outlier_2 = temp_idx;

