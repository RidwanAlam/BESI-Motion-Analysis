%% Motion Data Pre-Processing %%
% Filtering, Synchronization, and Imputation

%%
% load the tables "PblDdd" from "PblDays.mat" 
% INPUT: PblDdd

Pebble_sampling_rate = 50;
depID = 8;
saveAsFile = ['Results\p2d' num2str(depID,'%1d') '\prepDays.mat'];
save(saveAsFile, depID,'-v7.3');

varnames = whos('PblD*');

for i = 1:length(varnames)

    % Magnitude Adjustment  
    % Clipping out-of-range values
    
    eval(['agi_table' '=' varnames(i).name ';']);
    agi_table.x(abs(agi_table.x)>3999) = sign(agi_table.x(abs(agi_table.x)>3999))*4000;
    agi_table.y(abs(agi_table.y)>3999) = sign(agi_table.y(abs(agi_table.y)>3999))*4000;
    agi_table.z(abs(agi_table.z)>3999) = sign(agi_table.z(abs(agi_table.z)>3999))*4000;

    % Time Synchronization
    % Aligning timestamps from watch to sampling rate based time slots
    % Finding missing data packets
    
    hour_range = agi_table.timeIndex(1).Hour:agi_table.timeIndex(end).Hour;
    minute_range = 0:59;
    second_range = 0:1/Pebble_sampling_rate:60-(1/Pebble_sampling_rate);
    d1year = agi_table.timeIndex(1).Year;
    d1month = agi_table.timeIndex(1).Month;
    d1day = agi_table.timeIndex(1).Day;

    table_length = length(second_range)*length(minute_range)*length(hour_range);
    d1hour = zeros(table_length,1);
    d1minute = zeros(table_length,1);
    d1second = zeros(table_length,1);
    hlen = (length(second_range)*length(minute_range));
    mlen = length(second_range);
    for k = 1:length(hour_range)
        d1hour((hlen*(k-1))+1:(hlen*(k-1))+hlen) = hour_range(k);
        for j = 1:length(minute_range)
            d1minute((hlen*(k-1))+(mlen*(j-1))+1:(hlen*(k-1))+(mlen*(j-1))+mlen) ...
                = minute_range(j);
            d1second((hlen*(k-1))+(mlen*(j-1))+1:(hlen*(k-1))+(mlen*(j-1))+mlen) ...
                = second_range;
        end
    end

    % value assigned to missing data points = -4000
    new_agi_timeIndex = datetime([d1year*ones(table_length,1),d1month*ones(table_length,1),...
        d1day*ones(table_length,1), d1hour, d1minute, d1second]);
    new_agi_accx = -4000*ones(table_length,1);
    new_agi_accy = -4000*ones(table_length,1);
    new_agi_accz = -4000*ones(table_length,1);


    khour = agi_table.timeIndex.Hour - new_agi_timeIndex(1).Hour;
    kminute = agi_table.timeIndex.Minute;
    ksecond = round(max(agi_table.timeIndex.Second-(1/(2*Pebble_sampling_rate)),0)*Pebble_sampling_rate);

    kindex = khour*hlen + kminute*mlen + ksecond +1;

    new_agi_accx(kindex) = agi_table.x;
    new_agi_accy(kindex) = agi_table.y;
    new_agi_accz(kindex) = agi_table.z;
    
    % new_agi_* contain the synced data
    
    clear agi_table khour kminute ksecond hour_range minute_range second_range;
    clear d1year d1month d1day d1hour d1minute d1second hlen mlen;
    
    % Filter-out noisy clipped data
    % Median filtering for reducing speckle noise
    
    zind_accx = find(abs(new_agi_accx)==4000);
    for k = 1:length(zind_accx)
        if (zind_accx(k)>2 && zind_accx(k)<length(new_agi_accx)-2)
            new_agi_accx(zind_accx(k)) = median(new_agi_accx(zind_accx(k)-2:zind_accx(k)+2));
        end
    end
    
    zind_accy = find(abs(new_agi_accy)==4000);
    for k = 1:length(zind_accy)
        if (zind_accy(k)>2 && zind_accy(k)<length(new_agi_accy)-2)
            new_agi_accy(zind_accy(k)) = median(new_agi_accy(zind_accy(k)-2:zind_accy(k)+2));
        end
    end

    zind_accz = find(abs(new_agi_accz)==4000);
    for k = 1:length(zind_accz)
        if (zind_accz(k)>2 && zind_accz(k)<length(new_agi_accz)-2)
            new_agi_accz(zind_accz(k)) = median(new_agi_accz(zind_accz(k)-2:zind_accz(k)+2));
        end
    end
    
    % Impute missing data
    % Imputed with the local mean value
    
    ind_accx = find(new_agi_accx~=-4000);
    % find the data points with atleast one-minute gaps in between
    indind_accx = find(ind_accx(2:end)-ind_accx(1:end-1)>1 & ...
        ind_accx(2:end)-ind_accx(1:end-1)<50*60*1)+1;
    zind_accx_1 = ind_accx(indind_accx);
    zind_accx_2 = ind_accx(indind_accx-1);
    for k = 1:length(zind_accx_1)
        new_agi_accx(zind_accx_2(k)+1:zind_accx_1(k)-1) = ...
            mean([new_agi_accx(zind_accx_2(k)),new_agi_accx(zind_accx_1(k))]);
    end

    ind_accy = find(new_agi_accy~=-4000);
    indind_accy = find(ind_accy(2:end)-ind_accy(1:end-1)>1 & ...
        ind_accy(2:end)-ind_accy(1:end-1)<50*60*1)+1;
    zind_accy_1 = ind_accy(indind_accy);
    zind_accy_2 = ind_accy(indind_accy-1);
    for k = 1:length(zind_accy_1)
        new_agi_accy(zind_accy_2(k)+1:zind_accy_1(k)-1) = ...
            mean([new_agi_accy(zind_accy_2(k)),new_agi_accy(zind_accy_1(k))]);
    end

    ind_accz = find(new_agi_accz~=-4000);
    indind_accz = find(ind_accz(2:end)-ind_accz(1:end-1)>1 & ...
        ind_accz(2:end)-ind_accz(1:end-1)<50*60*1)+1;
    zind_accz_1 = ind_accz(indind_accz);
    zind_accz_2 = ind_accz(indind_accz-1);
    for k = 1:length(zind_accz_1)
        new_agi_accz(zind_accz_2(k)+1:zind_accz_1(k)-1) = ...
            mean([new_agi_accz(zind_accz_2(k)),new_agi_accz(zind_accz_1(k))]);
    end
    
    clear ind_accx ind_accy ind_accz indind_accx indind_accy indind_accz;
    clear zind_accx zind_accx_1 zind_accx_2 zind_accy zind_accy_1 zind_accy_2 zind_accz zind_accz_1 zind_accz_2;

    % save and store pre-processed data
    % as p2dS_dDD
    processedtable = table;
    processedtable.timeIndex = new_agi_timeIndex; 
    processedtable.accx = new_agi_accx;
    processedtable.accy = new_agi_accy;
    processedtable.accz = new_agi_accz;

    dateNumber = split(varnames(i).name,'D');
    tname = ['p2d' num2str(depID,'%1d') '_d' dateNumber{2}];
    eval([ tname '=' 'processedtable;']);
    clear processedtable;
    
    saveAsFile = ['Results\p2d' num2str(depID,'%1d') '\prepDays.mat'];
    save(saveAsFile, tname,'-append');
    eval(['clear ' tname ';']);
    clear tname new_agi_timeIndex new_agi_accx new_agi_accy new_agi_accz;
    
end

% OUTPUT: day-wise preprocessed table "p2dS_dDD" in prepDays.mat
