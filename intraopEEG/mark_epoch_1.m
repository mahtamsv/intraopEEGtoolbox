function idx_outlier_1 = mark_epoch_1(EEG, epoch_length)

    % epoch 
    EEG_epoched = pop_epoch( EEG, {'X'}, [0, epoch_length]);
    output = double(EEG_epoched.data);
    
    % remove epochs that contain no data (one second of flat data)
    idx_outlier_1 = isflat_mm(output, round(0.5*EEG_epoched.srate));
    
end