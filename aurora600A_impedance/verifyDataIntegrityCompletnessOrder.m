function setOfVerifiedTrials=...
            verifyDataIntegrityCompletnessOrder(...
                    dataFolder,experimentJson,fidLogFile,...
                    flag_readHeader,flag_checkSha256Sum)

fprintf('%s\n','Preprocessing: ');
fprintf('%s\n','  :Identifying trials with Larb-Stochastic segments');
fprintf('%s\n','  :Checking that the files are listed in the order of collection');
fprintf('%s\n','  :Checking the sha256 values of the data against the stored value');

fprintf(fidLogFile,'%s\n','Preprocessing: ');
fprintf(fidLogFile,'%s\n','  :Identifying trials with Larb-Stochastic segments');
fprintf(fidLogFile,'%s\n','  :Checking that the files are listed in the order of collection');
fprintf(fidLogFile,'%s\n','  :Checking the sha256 values of the data against the stored value');

setOfVerifiedTrials = [];
trialOrdering(length(experimentJson.trials)) = struct('name','','time','');
for i=1:1:length(experimentJson.trials)
    commentStr = '';
    %%
    % Fetch the experimental data files
    %%
    trialStr = fileread(fullfile(dataFolder,experimentJson.trials{i}));
    trialJson = jsondecode(trialStr);


    %%
    % Fetch the experimental data files
    %%
    fileType = {'data','protocol'};
    filePaths = [{''};{''}];
    for j=1:1:length(fileType)
        if(length(trialJson.(fileType{j}).file)>0)
            filePaths{j} = trialJson.(fileType{j}).file{1};
            if(length(trialJson.(fileType{j}).file)>1)
                for k=2:1:length(trialJson.(fileType{j}).file)
                    filePaths{j} = [filePaths{j},filesep,trialJson.(fileType{j}).file{k}];
                end
            end
        end
    end

    dataPath = fullfile(dataFolder,filePaths{1});
    protocolPath= fullfile(dataFolder,filePaths{2});          
  
    auroraData = readAuroraData600A(dataPath,flag_readHeader); 


    %%
    % Get the time stamp of the measurement
    %%    
    dateTime = convertTimeStamp600A(auroraData.Setup_Parameters.Created.Value);
    
    dateTimeInYears= dateTime.year ...
        + ((dateTime.month-1)/12)...
        + (dateTime.day/365) ...
        + (dateTime.hour/(24*365)) ...
        + (dateTime.minute/(60*24*365)) ...
        + (dateTime.second/(60*60*24*365));

    %Check and make sure that this entry was collected after the previous
    %one
    if(i > 1)
        if(dateTimeInYears < previousDateTime)
            commentStr = [commentStr,' Out-of-order'];
        end
    end

    previousDateTime=dateTimeInYears;

    %%
    %Check the sha256sum
    %%
    if(flag_checkSha256Sum==1)
        [status,cmdout] =  system(['sha256sum ',dataPath]);
        idx = strfind(cmdout,' ');        
        idx=idx-1;
        sha256Sum = cmdout;
        sha256Sum = sha256Sum(1,1:idx);

        if(strcmp(sha256Sum,trialJson.data.sha256)==0)
            here=1;
        end
        if(strcmp(sha256Sum,trialJson.data.sha256)==0)
          commentStr = [commentStr,' SHA256-mismatch'];
        end
    end
    %%
    % Check if the protocol file exists
    %%
    if( ~exist(protocolPath,'file'))
        commentStr = [commentStr,' Protocol-file-not-found'];
    end
    %%
    % Check to see if this trial has a Larb-Stochastic segment
    %%
    isLarbStochastic = 0;    
    if(~isempty(trialJson.segments) ... 
            && strcmp(trialJson.segments(1).type,'Larb-Stochastic')==1)
        setOfVerifiedTrials = [setOfVerifiedTrials;i];        
        isLarbStochastic=1;
    else
        commentStr = [commentStr,' Skipping'];
    end

    %
    % Message to user
    %    
    
    fprintf('\t%i/%i/%i %i:%i:%i\t%s\t%s\n',...
        dateTime.year,dateTime.month,dateTime.day,...
        dateTime.hour,dateTime.minute,dateTime.second,...
        commentStr,...
        experimentJson.trials{i});

    fprintf(fidLogFile,...
        '\t%i/%i/%i %i:%i:%i\t%s\t%s\n',...
        dateTime.year,dateTime.month,dateTime.day,...
        dateTime.hour,dateTime.minute,dateTime.second,...
        commentStr,...
        experimentJson.trials{i});    

end

