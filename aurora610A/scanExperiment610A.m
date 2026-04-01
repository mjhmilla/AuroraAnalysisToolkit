function scanResult = scanExperiment610A(experimentName,...
                                      keyWordFilter,...
                                      projectFolders,...
                                      verbose)


if(verbose==1)
  fidScanLog = fopen(fullfile(projectFolders.data610A,...
                              experimentName,...
                              ['log_scan_',experimentName,'.txt']),'w');
end


expStr = fileread(fullfile(projectFolders.data610A,...
                            experimentName,...
                           [experimentName,'.json']));
expJson = jsondecode(expStr);
expFolder = fullfile(projectFolders.data610A,...
                     experimentName);



idxTrial = 0;

if(verbose==1)
  fprintf('%s\t%s\t%s\t%s\t%s\n',...
          'File ','Meas.','Seq. ','Passes_Filter','Name');
  
  
  fprintf(fidScanLog,'%s\t%s\t%s\t%s\t%s\n',...
          'File ','Meas. ','Seq. ','Passes_Filter','Name');
end

validCount        = 0;
isLastMeasurement = 0;
metaDataCache     = [];
idxMPrevious = 0;

scanResult = struct('trialId',zeros(100,1),...
                    'measurementId',zeros(100,1),...
                    'sequenceId',zeros(100,1),...
                    'doesFileNamePassFilter',zeros(100,1),...
                    'numberOfSegmentsPassingFilter',zeros(100,1));



while(isLastMeasurement==0)

  idxTrial=idxTrial+1;  
  metaDataCache     = ...
     getNextMeasurement610A(expJson,expFolder,metaDataCache);
  
  isLastMeasurement = metaDataCache.isLastMeasurement;

  [~,metaDataFileName] = fileparts(metaDataCache.metaDataFilePath);

  isFileNameValid = applyKeywordFilter(metaDataFileName,...
                        keyWordFilter.metaDataFileName);

  if(verbose==1)    
    validStr = '';
    if(isFileNameValid==1)
      validCount=validCount+1;
      validStr = num2str(validCount);
    else
      validStr = ' ';
    end
      
    if(idxMPrevious ~= metaDataCache.indexMeasurement)
      fprintf('\n');
    end
    fprintf('%i\t%i\t%i\t%s\t%s\n',idxTrial,...
      metaDataCache.indexMeasurement, ...
      metaDataCache.indexSequence, ...
      validStr,...
      metaDataFileName);
  
    if(idxMPrevious ~= metaDataCache.indexMeasurement)
      fprintf(fidScanLog,'\n');
    end
  
    fprintf(fidScanLog,'%i\t%i\t%i\t%s\t%s\n',idxTrial,...
      metaDataCache.indexMeasurement, ...
      metaDataCache.indexSequence, ...
      validStr,...
      metaDataFileName);
  end

  idxMPrevious=metaDataCache.indexMeasurement;


  if(idxTrial > length(scanResult.trialId))    
    scanResult.trialId       = [scanResult.trialId;zeros(100,1)];
    scanResult.measurementId = [scanResult.measurementId;zeros(100,1)];
    scanResult.sequenceId    = [scanResult.sequenceId;zeros(100,1)];
    scanResult.doesFileNamePassFilter= ...
      [scanResult.doesFileNamePassFilter;zeros(100,1)];
    scanResult.numberOfSegmentsPassingFilter = ...
      [scanResult.numberOfSegmentsPassingFilter;zeros(100,1)];
  end



  scanResult.trialId(idxTrial,1)       = idxTrial;
  scanResult.measurementId(idxTrial,1) = metaDataCache.indexMeasurement;
  scanResult.sequenceId(idxTrial,1)    = metaDataCache.indexSequence;
  scanResult.doesFileNamePassFilter(idxTrial,1)= isFileNameValid;

  countOfValidSegments=0;
  for idxSeg = 1:1:length(metaDataCache.metaDataJson.segments)
    isSegmentValid = ...
      applyKeywordFilter(metaDataCache.metaDataJson.segments(idxSeg).type,...
                         keyWordFilter.segment);
    if(isSegmentValid==1)
      countOfValidSegments=countOfValidSegments+1;
    end
  end

  scanResult.numberOfSegmentsPassingFilter(idxTrial,1)=countOfValidSegments;
  

end


scanResult.trialId               = scanResult.trialId(1:idxTrial);
scanResult.measurementId         = scanResult.measurementId(1:idxTrial);
scanResult.sequenceId            = scanResult.sequenceId(1:idxTrial);
scanResult.doesFileNamePassFilter= ...
  scanResult.doesFileNamePassFilter(1:idxTrial);
scanResult.numberOfSegmentsPassingFilter = ...
    scanResult.numberOfSegmentsPassingFilter(1:idxTrial);

metaDataCache =[];

if(verbose==1)
  fclose(fidScanLog);
end


success=1;