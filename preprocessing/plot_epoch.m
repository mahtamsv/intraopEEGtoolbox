function plot_epoch(EEG, t_max, idx_outlier_1, idx_outlier_2, idx_outlier_3, save_dir, fh)
% plot_epoch: plots examples of the epochs marked to be removed or the ones
%             marked to be kept for further analyses 
%
% Inputs:
%   EEG: EEGLAB EEG data structure
%   t_max: time limit for plotting in seconds 
%   idx_outlier_1: indices of epochs marked with mark_epoch_1.m 
%   idx_outlier_2: indices of epochs marked with mark_epoch_2.m
%   idx_outlier_3: indices of epochs marked with mark_epoch_3.m 
%   save_dir: Directory path to save figures 
%   fh: Figure handle for plotting 
%
%    
% ------------------------------------------------------------------------
% This function is part of the intraopEEGtoolbox: 
% https://github.com/mahtamsv/intraopEEGtoolbox
%
% Author: Mahta Mousavi, 2024 
% ------------------------------------------------------------------------


EEG_temp = EEG; 
t_vect = linspace(0,t_max, size(EEG_temp.data,2));

outlier_vect_1 = find(idx_outlier_1==1);
outlier_vect_2 = find(idx_outlier_2==1);
outlier_vect_3 = find(idx_outlier_3==1);
% two examples of idx_outlier_1

if ~isempty(outlier_vect_1)
    for ik = 1:min(2, length(outlier_vect_1))
        set(0, 'CurrentFigure', fh);
        clf reset;
        pos = randi(length(outlier_vect_1)); 
        idx_temp = outlier_vect_1(pos);
        plot(t_vect, EEG_temp.data(:,:,idx_temp), 'LineWidth',1.4)
        title(['Outlier type 1, srate: ',num2str(EEG_temp.srate)])
        xlabel ('time (s)')
        xlim([0, t_max])
        saveas(gcf,[save_dir, 'M1_',num2str(ik), '.png'])
        %close all
    end
end

% remove the outlier 1 indices and plot for outlier 2
EEG_temp = pop_select(EEG_temp, 'notrial',find(idx_outlier_1==1));
if ~isempty(outlier_vect_2)
    for ik = 1:2
        set(0, 'CurrentFigure', fh);
        clf reset;
        pos = randi(length(outlier_vect_2)); 
        idx_temp = outlier_vect_2(pos);
        plot(t_vect, EEG_temp.data(:,:,idx_temp), 'LineWidth',1.4)
        title(['Outlier type 2, srate: ',num2str(EEG_temp.srate)])
        xlabel ('time (s)')
        xlim([0, t_max])
        saveas(gcf,[save_dir, 'M2_',num2str(ik), '.png'])
    end
end


% remove the outlier 2 indices and plot for outlier 3
EEG_temp = pop_select(EEG_temp, 'notrial',find(idx_outlier_2==1));
if ~isempty(outlier_vect_3)
    for ik = 1:2
        set(0, 'CurrentFigure', fh);
        clf reset;
        pos = randi(length(outlier_vect_3)); 
        idx_temp = outlier_vect_3(pos);
        plot(t_vect, EEG_temp.data(:,:,idx_temp), 'LineWidth',1.4)
        title(['Outlier type 3, srate: ',num2str(EEG_temp.srate)])
        xlabel ('time (s)')
        xlim([0, t_max])
        saveas(gcf,[save_dir, 'M3_',num2str(ik), '.png'])
    end
end

% remove the outlier 3 indices and plot for the kept epochs
EEG_temp = pop_select(EEG_temp, 'notrial',find(idx_outlier_3==1));
for ik = 1:2
    set(0, 'CurrentFigure', fh);
    clf reset;
    pos = randi(size(EEG_temp.data,3)); 
    plot(t_vect, EEG_temp.data(:,:,pos), 'LineWidth',1.4)
    title(['Clean epoch, srate: ',num2str(EEG_temp.srate)])
    xlabel ('time (s)')
    xlim([0, t_max])
    saveas(gcf,[save_dir, 'Clean_',num2str(ik), '.png'])
end




