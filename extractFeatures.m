function outData = extractFeatures(inData,Fs)

    % Feature Extraction from Motion Data
    % the feature list is hard-coded here, make changes if needed
    % needs 'interQrange.m', 'meanCross.m', 'mean_der.m', 'teager_calc.m',
    %       'fftpower.m', and 'corrCoefficients.m'
    
    % INPUT: inData -> a table containing a time-window of 
    %                  motion data (accx, accy, accz) and time-indices;
    %        Fs -> sampling rate of motion data
    
    % Features for each axes of motion data and their vector magnitude
    % Statistical: Mean, Median, Max, Variance, RMS, Inter-Quartile Range,
    %              Cross-Correlations among the 3 axes signal
    % Frequency: Mean Crossing Rate, Mean and Max of Derivative, and 
    %            Mean and Max in Freq Bands defined in 'fftpower.m'
    % Power: Mean, Std, and Max of Teager Energy
    
    ind_feature_list = {'mean','median','max','var','rms',...
        'qqr','mxr','mean_der','max_der',...
        'teager_mean','teager_std','teager_max',...
        'f0_mean','f0_max','f1_mean','f1_max','f2_mean','f2_max'}; % 18 x 4 = 72
    other_feature_list = {'corrxy','corrzx','corryz'}; % 72 + 3 = 75
    ind_feature_function = {'mean','median','max','var','rms',...
        'interQrange','meanCross','mean_der','teager_calc','fftpower'}; % 
    % other_feature_function = {'corrCoefficients'};
    
    xdata = (inData.accx + 4000)/8000 * 100;
    ydata = (inData.accy + 4000)/8000 * 100;
    zdata = (inData.accz + 4000)/8000 * 100;
    mdata = sqrt((xdata.^2) + (ydata.^2) + (zdata.^2)); % vector magnitude
    
    outData = zeros(1,(length(ind_feature_list)*4)+length(other_feature_list));
    % (18 x 4) + 3 = 75 features;
    
    for f = 1:length(ind_feature_function)-3
        eval(['outData(f)' '=' ind_feature_function{f} '(xdata);']);
        eval(['outData(f+1*length(ind_feature_list))' '=' ind_feature_function{f} '(ydata);']);
        eval(['outData(f+2*length(ind_feature_list))' '=' ind_feature_function{f} '(zdata);']);
        eval(['outData(f+3*length(ind_feature_list))' '=' ind_feature_function{f} '(mdata);']);
    end
    
    f = length(ind_feature_function)-3;
    [outData(f+1),outData(f+2)] = mean_der(xdata);
    [outData(f+1*length(ind_feature_list)+1),...
        outData(f+1*length(ind_feature_list)+2)] = mean_der(ydata);
    [outData(f+2*length(ind_feature_list)+1),...
        outData(f+2*length(ind_feature_list)+2)] = mean_der(zdata);
    [outData(f+3*length(ind_feature_list)+1),...
        outData(f+3*length(ind_feature_list)+2)] = mean_der(mdata);
    
    f = f+2;
    [outData(f+1),outData(f+2),outData(f+3)] = teager_calc(xdata);
    [outData(f+1*length(ind_feature_list)+1),outData(f+1*length(ind_feature_list)+2),...
        outData(f+1*length(ind_feature_list)+3)] = teager_calc(ydata);
    [outData(f+2*length(ind_feature_list)+1),outData(f+2*length(ind_feature_list)+2),...
        outData(f+2*length(ind_feature_list)+3)] = teager_calc(zdata);
    [outData(f+3*length(ind_feature_list)+1),outData(f+3*length(ind_feature_list)+2),...
        outData(f+3*length(ind_feature_list)+3)] = teager_calc(mdata);
    
    f = f+3;
    [outData(f+1),outData(f+2),outData(f+3),outData(f+4),...
        outData(f+5),outData(f+6)] = fftpower(xdata,Fs);
    [outData(f+1*length(ind_feature_list)+1),...
        outData(f+1*length(ind_feature_list)+2),...
        outData(f+1*length(ind_feature_list)+3),...
        outData(f+1*length(ind_feature_list)+4),...
        outData(f+1*length(ind_feature_list)+5),...
        outData(f+1*length(ind_feature_list)+6)] = fftpower(ydata,Fs);
    [outData(f+2*length(ind_feature_list)+1),...
        outData(f+2*length(ind_feature_list)+2),...
        outData(f+2*length(ind_feature_list)+3),...
        outData(f+2*length(ind_feature_list)+4),...
        outData(f+2*length(ind_feature_list)+5),...
        outData(f+2*length(ind_feature_list)+6)] = fftpower(zdata,Fs);
    [outData(f+3*length(ind_feature_list)+1),...
        outData(f+3*length(ind_feature_list)+2),...
        outData(f+3*length(ind_feature_list)+3),...
        outData(f+3*length(ind_feature_list)+4),...
        outData(f+3*length(ind_feature_list)+5),...
        outData(f+3*length(ind_feature_list)+6)] = fftpower(mdata,Fs);
    
    f = length(outData);
    [outData(f-2),outData(f-1),outData(f)] = corrCoefficients(xdata,ydata,zdata);
    
    % OUTPUT: outData -> 1x75 feature vector for the input time-window 
    
end
