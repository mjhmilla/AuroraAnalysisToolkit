function setOfVerifiedTrials=...
            verifyExperimentDataIntegrityCompletness610A(...
                    experimentFolder,...
                    settings,...
                    projectFolders)

fidLogFile = fopen(fullfile(projectFolders.data610A,...
                    experimentFolder,...
                    ['log_dataIntegrity_',experimentFolder,'.txt']),'w');


fprintf('%s\n','Preprocessing: ');
fprintf('%s\n',...
  '  :Checking that the files are listed in the order of collection');
fprintf('%s\n',...
  '  :Checking the sha256 values of the data against the stored value');

fprintf(fidLogFile,'%s\n','Preprocessing: ');
fprintf(fidLogFile,'%s\n',...
  '  :Checking that the files are listed in the order of collection');
fprintf(fidLogFile,'%s\n',...
  '  :Checking the sha256 values of the data against the stored value');

setOfVerifiedTrials = [];

expFolder = fullfile(projectFolders.data610A,...
                            experimentFolder);

expStr = fileread(fullfile(expFolder,...
                           [experimentFolder,'.json']));
expJson = jsondecode(expStr);

metaDataCache = [];
isLastMeasurement=0;

idxFile = 0;
while(isLastMeasurement == 0)
    metaDataCache = ...
      getNextMeasurement610A(expJson,expFolder,metaDataCache);

    isLastMeasurement = metaDataCache.isLastMeasurement;

    output = verifyFileIntegrityCompletness610A(...
                      metaDataCache.dataFilePath,...
                      metaDataCache.dataSha256Sum,...
                      metaDataCache.protocolFilePath);

    idxFile=idxFile+1;
    idxM = metaDataCache.indexMeasurement;
    idxS  = metaDataCache.indexSequence;

    if(settings.setSha256Sum==0)
      seqMetaDataFile = '';
      if(contains(expJson.measurements{idxM},'.seq'))
        [~,seqMetaDataFile] = fileparts(metaDataCache.metaDataFilePath);
      end

      comment = 'passed';
      if(~isempty(output.comment))
        comment = output.comment;
      end

      fprintf('%i.\t%s\t%s\t%i\t%s\n',...
        idxFile,...
        comment,...
        expJson.measurements{idxM},...
        idxS,...
        seqMetaDataFile);
    else

      fprintf('%i.\t%s\t%s\t%i\n',...
        idxFile,...
        'Setting-SHA256',...
        expJson.measurements{idxM},...
        idxS);

    end

    if(settings.setSha256Sum==1)
      if(contains(expJson.measurements{idxM},'.seq')) 
        metaDataCache.sequenceJson.sequence.data.sha256{idxS} = ...
          output.sha256;
        seqStr = jsonencode(metaDataCache.sequenceJson);
        fidSeq = fopen(metaDataCache.sequenceFilePath,'w');
        fprintf(fidSeq,seqStr);
        fclose(fidSeq);

      else
  
        metaDataCache.metaDataJson.data.sha256 = output.sha256;  
        trialStr = jsonencode(metaDataCache.metaDataJson);
        fidTrial = fopen(metaDataCache.metaDataFilePath,'w');        
        fprintf(fidTrial,trialStr);
        fclose(fidTrial);        
      end
    end

end




