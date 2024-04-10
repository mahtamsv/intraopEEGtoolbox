function out_flag = issat_mm(data, maxVal, minVal, threshold)
% if data in any epoch is saturated, this is marked  
% data is of size time X number of epochs 
% window is in length of samples 


out_flag = zeros(size(data,2),1);

for idx = 1:length(out_flag)
    % find diff along time 
    temp = data(:, idx); 
    idx_max = find(temp==maxVal);
    idx_min = find(temp==minVal);

    if length(idx_max)+length(idx_min)>threshold
        out_flag(idx)=1;
    end
    
end
