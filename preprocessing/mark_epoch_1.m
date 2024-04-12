function idx_outlier_1 = mark_epoch_1(EEG, epoch_length)
%
% Inputs:
%   EEG:   EEG data, instance of EEGLAB data structure 
%   epoch_length: epoch length  
%
% Output:
%   idx_outlier_1: epoch indices marked to be removed later  
% ------------------------------------------------------------------------
% This function is part of the intraopEEGtoolbox: 
% https://github.com/mahtamsv/intraopEEGtoolbox
%
% Author: Mahta Mousavi, 2024 
% ------------------------------------------------------------------------

% epoch EEG data with the given length 
EEG_epoched = pop_epoch( EEG, {'X'}, [0, epoch_length]);
output = double(EEG_epoched.data);

% mark epochs that contain no data (one second of flat data)
idx_outlier_1 = isflat_mm(output, round(0.5*EEG_epoched.srate));

