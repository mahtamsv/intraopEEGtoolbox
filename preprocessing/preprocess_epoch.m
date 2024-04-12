function [clean_data, orig_epochs] = preprocess_epoch(EEG, epoch_length_l, epoch_length_s, srate_new, save_dir_fig, reref_flag, fh)
% preprocess_epoch: Preprocess EEG data by segmenting into epochs, cleaning artifacts, and resampling if necessary.
%
% Inputs:
%   EEG: EEGLAB EEG data structure
%   epoch_length_l: Length of long epochs (in seconds)
%   epoch_length_s: Length of short epochs (in seconds)
%                   note that epoch_length_s<=epoch_length_l (optional)
%   srate_new: new sampling rate to downsample into 
%   save_dir_fig: Directory path to save figures 
%   reref_flag: whether rereference to common average (1) or not (0)
%   fh: Figure handle for plotting 
%
% Outputs:
%   clean_data: Cleaned EEG data after preprocessing.
%   orig_epochs: the original number of epochs in the data before cleaning 
% 
% EXAMPLE:
%    
% ------------------------------------------------------------------------
% This function is part of the intraopEEGtoolbox: 
% https://github.com/mahtamsv/intraopEEGtoolbox
%
% Author: Mahta Mousavi, 2024 
% ------------------------------------------------------------------------

% Parse inputs
if (nargin == 0)
    help preprocess_epoch
    return
end
% if (nargin < 2) 
%     epoch_length_l = 2; 
%     epoch_length_s = epoch_length_l; 
% end
% if (nargin < 3) 
%     epoch_length_s = epoch_length_l; 
% end


% remove the first part of the files where recording is not started
start_val = zeros(size(EEG.data,1),1);
for idx_chan = 1:size(EEG.data,1)
    temp = EEG.data(idx_chan,:);
    diff_temp = diff(temp); 
    idx_temp = find(diff_temp);
    if sum(diff_temp(1:round(epoch_length_s*EEG.srate))) ==0
        start_val(idx_chan) = idx_temp(1);
    end
end

if max(start_val)>0
    EEG = eeg_eegrej( EEG, [1 max(start_val)]);
end

% remove the last part if again disconnected channels and not recording
end_val = zeros(size(EEG.data,1),1); %number of channels
for idx_chan = 1:size(EEG.data,1)
    temp = flip(EEG.data(idx_chan,:));
    diff_temp = diff(temp); 
    idx_temp = find(diff_temp);
    if sum(diff_temp(1:round(epoch_length_s*EEG.srate))) ==0
        end_val(idx_chan) = idx_temp(1);
    end
end

if max(end_val)>0
    EEG = eeg_eegrej( EEG, [size(EEG.data,2)-max(end_val)+1 size(EEG.data,2)]);
end

% put markers and epoch
EEG = eeg_regepochs(EEG,'recurrence',epoch_length_l,'eventtype', 'X', 'extractepochs', 'off'); 
EEG_e1 = pop_epoch( EEG, {'X'}, [0, epoch_length_l]);

% save the number of epochs before cleaning 
orig_epochs = size(EEG_e1.data, 3); 


% find artifactual epochs by scanning each channel separately 
% keep all indices of to be removed later 
idx_outlier_1 = 0; 
for i_chan = 1:size(EEG.data, 1)
    EEG_temp = pop_select(EEG, 'channel', i_chan);
    idx_outlier_1 = idx_outlier_1 + mark_epoch_1(EEG_temp, epoch_length_l);      
end
idx_outlier_1(idx_outlier_1>1)=1; 

% remove the outlier type 1 and then select the outlier type 2 across
idx_outlier_2 = 0; 
for i_chan = 1:size(EEG.data, 1)
    EEG_temp = pop_select(EEG, 'channel', i_chan);
    %size(epoch_and_clean_2(EEG_temp, epoch_length_l, idx_outlier_1))
    idx_outlier_2 = idx_outlier_2 + mark_epoch_2(EEG_temp, epoch_length_l, idx_outlier_1);      
end
idx_outlier_2(idx_outlier_2>1)=1; 

% remove the outlier types 1, 2 and then select the outlier type 3 across
idx_outlier_3 = 0; 
for i_chan = 1:size(EEG.data, 1)
    EEG_temp = pop_select(EEG, 'channel', i_chan);
    %size(epoch_and_clean_3(EEG_temp, epoch_length_l, idx_outlier_1))
    idx_outlier_3 = idx_outlier_3 + mark_epoch_3(EEG_temp, epoch_length_l, idx_outlier_1, idx_outlier_2);      
end
idx_outlier_3(idx_outlier_3>1)=1; 

EEG_e1 = pop_epoch(EEG, {'X'}, [0, epoch_length_l]);
% save some of the marked epochs before downsampling     
plot_epoch(EEG_e1, epoch_length_l, idx_outlier_1, idx_outlier_2, idx_outlier_3, save_dir_fig, fh)

% downsample if asked for 
if ~isempty(srate_new)
    EEG_temp = pop_resample(EEG, srate_new);
    EEG_temp = eeg_checkset(EEG_temp);
end

% high pass filter
[EEG_temp, com, b] = pop_eegfiltnew(EEG_temp, 1, 0);

% re-reference to common average 
if reref_flag
    EEG_temp = pop_reref(EEG_temp, []);
    EEG_temp = eeg_checkset(EEG_temp);
end


%epoch around X's
EEG_e2 = pop_epoch( EEG_temp, {'X'}, [0, epoch_length_s]);

% check if the number of epochs of long and short match 
if size(EEG_e1.data,3)~=size(EEG_e2.data,3)
    % the mismatch is only possible by one epoch -- remove the last
    % epoch 
    EEG_e2 = pop_select(EEG_e2, 'notrial',size(EEG_e2.data,3));
end

% remove the artifactual epochs 
EEG_e2 = pop_select(EEG_e2, 'notrial',find(idx_outlier_1==1));
EEG_e2 = pop_select(EEG_e2, 'notrial',find(idx_outlier_2==1));
EEG_e2 = pop_select(EEG_e2, 'notrial',find(idx_outlier_3==1));


clean_data = double(EEG_e2.data); %cell2mat(struct2cell(clean_data));


