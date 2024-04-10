function out_flag = isflat_mm(data, window)
% if data in any channel is flat, data is marked 
% 
% Inputs:
%   data:   EEG data with size (channel X time X number of epochs)
%   window: length of the samples to check for consistency 
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
out_flag = zeros(size(data,3),1);

for idx = 1:size(data,3)
    % find diff along time 
    diff_X = diff(data(:,:,idx),1,2);
    
    % find if window-1 consecutive elements are 0's
    % this entails similar values of length window in the original epoch 
    % one of these is sufficient for this epoch 
    for ik = 1:size(diff_X,1)
        for ij = 1:size(diff_X,2)-window-1
            temp = diff_X(ik,ij:ij+window-2);
            if sum(abs(temp))==0
                out_flag(idx)=1;
            end
        end
    end
end
