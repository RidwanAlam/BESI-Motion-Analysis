%% Motion Data Parsing %%

% Import, Sort Day-wise, and Save/Store 
% uses "importPebbleData.m"

%%
% initialize day-wise indices for the specific deployment/study

% INPUT deployment/study information here
depID = 8;
depFolder = ['C:\Users\Ridwan\Documents\Deployment Temp\p2d' num2str(depID)];
depStartDate = '2017-08-10 00:00:00'; % deployment start-date 
depEndDate = '2017-09-14 11:59:59'; % deployment end-date
%

startUnixTime = posixtime(datetime(depStartDate,'TimeZone','America/New_York'))*1000;
endUnixTime = posixtime(datetime(depEndDate,'TimeZone','America/New_York'))*1000;

startDate = datetime((startUnixTime)./1000,'ConvertFrom','posixtime',...
    'TimeZone','America/New_York');
endDate = datetime((endUnixTime)./1000,'ConvertFrom','posixtime',...
    'TimeZone','America/New_York');

startDateNum = floor(datenum(startDate));

startdayindex = 0;
enddayindex = floor(datenum(endDate))-startDateNum;

%%
% read data files from appropriate folders
% sort as day-wise tables and save as MATLAB objects

% INPUT: "depFolder\Pebble X\rYYY\*.csv"

%nindx_length = 0;
%indx_length = 0;

for r = 1:2
    pebbleID = r-1;
    pebbleName = ['Pebble ' num2str(pebbleID,'%1d')];
    
    % INPUT appropriate relayIDs here
    if r==1 
        relayID = [112,114,116,118,120]; %
    else
        relayID = [113,115,117,119];
    end
    %

    for k = 1:length(relayID)
        relayName = ['r' num2str(relayID(k))];
        fileDirName = fullfile(depFolder,pebbleName,relayName);
        filenames = dir(fullfile(fileDirName,'*.csv'));
        
        % save as "Results\p2dS\PblXrYY.mat"
        
        saveAsFileName = ['Results\p2d' num2str(depID,'%1d') '\Pbl' ...
            num2str(pebbleID,'%1d') 'r' num2str(k,'%02d') '.mat'];
        rTableName = ['Pbl' num2str(pebbleID,'%1d') 'r' num2str(k,'%02d')];
        relayT = table;
        eval([ rTableName '=' 'relayT ;']);
        eval(['save(''' saveAsFileName ''',''' rTableName ''',''-v7.3'');']);

        % load files to a relay-wise table PblXrYY
        for i=1:length(filenames)
            
            pblFile = fullfile(fileDirName,filenames(i).name);
            % call importPebbleData.m in the same folder
            pblData = importPebbleData(pblFile); 
            times=pblData.timestamp;
            indx = find(times<endUnixTime & times>startUnixTime);
            %indx_length = indx_length + length(indx);
            %nindx_length = nindx_length + (height(pblData)-length(indx));
            pblData = pblData(indx,:);
            pblData.t0 = pblData.timestamp + pblData.offset;
            pblData.timestamp = [];
            pblData.offset = [];
            pblData.timeIndex = datetime((pblData.t0)./1000,'ConvertFrom',...
                'posixtime','TimeZone','America/New_York');
            pblData.t0=[];

            relayT = [relayT;pblData];
            
            % sort data to day-wise tables
            while(1)
                if height(pblData)==0
                    break;
                end
                tempDateNum = floor(datenum(pblData.timeIndex(1)));
                tempInd = find(floor(datenum(pblData.timeIndex))==tempDateNum);
                if (~isempty(tempInd))
                    % day-wise table: dDDpblXrYYfZZZ
                    % save the table in "PblXrYY.mat" 
                    newTableName = ['d' num2str(tempDateNum-startDateNum,'%02d') ...
                        'pbl' num2str(pebbleID,'%1d') 'r' num2str(k,'%02d') ...
                        'f' num2str(i)];
                    eval([newTableName '=' 'pblData(tempInd,:);']);
                    eval(['save(''' saveAsFileName ''',''' newTableName ''',''-append'');']);
                    % eval(['clear ' newTableName ';']);
                    pblData(tempInd,:) = [];
                end
            end
            
            clear pblData pblFile indx times tempDateNum tempInd newTableName;
        end

        eval([ rTableName '=' 'relayT ;']);
        clear relayT;
        %eval(['save(''' saveAsFileName ''',''' rTableName ''',''-append'');']);
        % NOT saving the whole relay-wise table -- TOO BIG!
        eval(['clear ' rTableName ';']);
        clear i filenames fileDirName relayName saveAsFileName rTableName;

    end
    clear pebbleName pebbleID relayID k;

end

% OUTPUT: day-wise tables "dDDpblXrYYfZZZ" in "PblXrYY.mat"
% for each day DD, each Pebble X , and each relay YY, 
% there are multiple tables corresponding to the hourly files

%%
% read day-wise tables "dDDpblXrYYfZZZ"
% sort as day-wise tables across relays and Pebbles
% output tables contain day-wise continuous motion data

% first manually load the day-wise tables
% should be on the workspace from the last section
% NB: Can't do this operation in the previous section,
% as multiple Pebbles and relays have data from the same day;

% INPUT: "dDDpblXrYYfZZZ"

for r = 0:1
    
    pebbleID = r;
    
    for dayindex = startdayindex:1:enddayindex
        
        % day-wise tables: dDDpblXrYYfZZZ
        varprefix = ['d' num2str(dayindex,'%02d') 'pbl' num2str(pebbleID,'%1d') '*']; 
        varnames = whos(varprefix);
        if ~(isempty(varnames))
            for i = 1:length(varnames)
                tempDay = eval([varnames(i).name '.timeIndex(1)']);
                tempDateNum = floor(datenum(tempDay));
                % combined day-wise table: pblXdDD
                daytablename = ['pbl' num2str(pebbleID,'%1d') 'd' ...
                    num2str(tempDateNum-startDateNum,'%02d')];
                if ~(exist(daytablename,'var')==1)
                    eval([daytablename '=' 'table;']);
                end          
                eval([daytablename '=' '[' daytablename ';' varnames(i).name '];']);
                eval([daytablename '=' 'sortrows(' daytablename ',{''timeIndex''});']);
                
                clear daytablename;
            end
        end
        clear varprefix varnames;
    end
    
    % OUTPUT: pblXdDD for each day and each Pebble
    
    % save the tables in "PblXDays.mat"
    
    saveAsFile = ['Results\p2d' num2str(depID,'%1d') '\Pbl' ...
        num2str(pebbleID,'%1d') 'Days.mat'];
    varnames_1 = whos(['pbl' num2str(pebbleID,'%1d') 'd*']);
    save(saveAsFile,'startDate','endDate','-v7.3');
    if ~(isempty(varnames_1))
        for j = 1:length(varnames_1)
            save(saveAsFile,varnames_1(j).name,'-append');
        end
    end
    clear varnames_1 saveAsFile;

end


%%
% Save figures for each day and each Pebble 
% Helpful for manual inspection

for dayindex = startdayindex:1:enddayindex
    pbl0name = ['pbl0' 'd' num2str(dayindex,'%02d')];
    pbl1name = ['pbl1' 'd' num2str(dayindex,'%02d')];
    f = figure(1);
    if (exist(pbl0name,'var')==1)
        subplot(2,1,1);
        eval(['plot(' pbl0name '.timeIndex,' pbl0name '.x);hold on;']);
        eval(['plot(' pbl0name '.timeIndex,' pbl0name '.y);hold on;']);
        eval(['plot(' pbl0name '.timeIndex,' pbl0name '.z);ylim([-4000 4000]);']);
    end
    if (exist(pbl1name,'var')==1)
        subplot(2,1,2);
        eval(['plot(' pbl1name '.timeIndex,' pbl1name '.x);hold on;']);
        eval(['plot(' pbl1name '.timeIndex,' pbl1name '.y);hold on;']);
        eval(['plot(' pbl1name '.timeIndex,' pbl1name '.z);ylim([-4000 4000]);']);
    end 
    filename = ['Results\p2d' num2str(depID,'%1d') '\figs\f' num2str(dayindex,'%02d') '.fig'];
    savefig(f,filename);
    close(f);
end


%%
% Manually filter out erroneous data for each day

saveAsFile = ['Results\p2d' num2str(depID,'%1d') '\PblDays.mat'];
save(saveAsFile,'startDate','endDate','-v7.3');

% the following section is for manually selecting accidental data
% the time window selected will be excluded from the clean data
% for each Pebble, excluded time-windows: [H11:M11 H12:M12] and [H21:M21 H22:M22] 
%%
% INPUT: the day-wise Pebble-wise tables pblXdDD

dayNum = 03;

PebbleID1 = 0;
H11 = 0; M11 = 0;
H12 = 20; M12 = 52;
H21 = 0; M21 = 0;
H22 = 20; M22 = 52;

eval(['table0' '=' 'pbl' num2str(PebbleID1) 'd' num2str(dayNum,'%02d') ';']);
t11 = find(table0.timeIndex.Hour>=H11 & table0.timeIndex.Minute>=M11,1,'first');
t12 = find(table0.timeIndex.Hour<=H12 & table0.timeIndex.Minute<=M12,1,'last');
t21 = find(table0.timeIndex.Hour>=H21 & table0.timeIndex.Minute>=M21,1,'first');
t22 = find(table0.timeIndex.Hour<=H22 & table0.timeIndex.Minute<=M22,1,'last');
table0([t11:t12,t21:t22],:) = [];

clear H11 H12 H21 H22 M11 M12 M21 M22 t11 t12 t21 t22;

PebbleID2 = 1;
H11 = 8; M11 = 43;
H12 = 21; M12 = 36;
H21 = 8; M21 = 43;
H22 = 21; M22 = 36;

eval(['table1' '=' 'pbl' num2str(PebbleID2) 'd' num2str(dayNum,'%02d') ';']);
t11 = find(table1.timeIndex.Hour>=H11 & table1.timeIndex.Minute>=M11,1,'first');
t12 = find(table1.timeIndex.Hour<=H12 & table1.timeIndex.Minute<=M12,1,'last');
t21 = find(table1.timeIndex.Hour>=H21 & table1.timeIndex.Minute>=M21,1,'first');
t22 = find(table1.timeIndex.Hour<=H22 & table1.timeIndex.Minute<=M22,1,'last');
table1([t11:t12,t21:t22],:) = [];

clear H11 H12 H21 H22 M11 M12 M21 M22 t11 t12 t21 t22;

% combined day-wise table: PblDdd for all Pebbles
% OUTPUT: PblDdd for each day

daytablename = ['PblD' num2str(dayNum,'%02d')];
eval([ daytablename '=' '[table0;table1];']); % 'table1;']); % 
eval([daytablename '=' 'sortrows(' daytablename ',{''timeIndex''});']);

% save the table PblDdd in "PblDays.mat" 

saveAsFile = ['Results\p2d' num2str(depID,'%1d') '\PblDays.mat'];
eval(['save(saveAsFile,''' daytablename ''',''-append'');']);

clear table0 table1;
clear dayNum daytablename; 

%%
