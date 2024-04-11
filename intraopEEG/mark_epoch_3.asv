function idx_outlier_3 = mark_epoch_3(EEG, epoch_length, idx_outlier_1, idx_outlier_2)
%
% Inputs:
%   EEG:   EEG data, instance of EEGLAB data structure 
%   epoch_length: epoch length  
%   idx_outlier_1: epoch indices marked from mark_epoch_1.m  
%   idx_outlier_2: epoch indices marked from mark_epoch_2.m  
%
% Output:
%   idx_outlier_3: epoch indices marked to be removed later  
% ------------------------------------------------------------------------
% This function is part of the intraopEEGtoolbox: 
% https://github.com/mahtamsv/intraopEEGtoolbox
%
% Author: Mahta Mousavi, 2024 
% ------------------------------------------------------------------------

% apply a high-pass filter at 1 Hz to the original EEG data 
[EEG, com, b] = pop_eegfiltnew(EEG, 1, 0);
% re-reference to common average 
%EEG = pop_reref(EEG, []);
% epoch again and remove the marked epochs from the first sets of
% criteria 
EEG_epoched = pop_epoch( EEG, {'X'}, [0, epoch_length]);
EEG_epoched = pop_select(EEG_epoched, 'notrial',find(idx_outlier_1==1));
EEG_epoched = pop_select(EEG_epoched, 'notrial',find(idx_outlier_2==1));
output_v2 = double(EEG_epoched.data);

% find the PSD of the remaining epochs 
PSD_epoch_avg = zeros(size(output_v2,3),1);
for idx = 1:size(output_v2,3)
    sig = squeeze(output_v2(:,:,idx));
    [power, w] = pwelch(sig', length(sig), 0, length(sig), EEG_epoched.srate);
    PSD_epoch_avg(idx) = mean(power(:));
end


% remove the epochs with very high or very low power 
idx_outlier_3 = double(isoutlier(PSD_epoch_avg, "quartiles"));
%idx_outlier_3 = isoutlier(PSD_epoch_avg, "percentiles",[0 95]);

