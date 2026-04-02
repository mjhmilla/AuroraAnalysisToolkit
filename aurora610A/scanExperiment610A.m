function scanResult = scanExperiment610A(experimentName,...
                                      keyWordFilter,...
                                      projectFolders,...
                                      verbose)


if(verbose==1)
  fprintf('\n\nScanning the experiment\n\n');
  
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
  fprintf('%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n',...
          'No. ','Meas.','Seq. ','f(name)',...
          'f(seq)','f(tag)','f(all)','Name');
  
  fprintf(fidScanLog,'%s,%s,%s,%s,%s,%s,%s,%s\n',...
          'No. ','Meas.','Seq. ','f(name)','f(seq)',...
          'f(tag)','f(all)','Name');
  

end

validCount        = 0;
isLastMeasurement = 0;
metaDataCache     = [];
idxMPrevious = 0;

scanResult = struct('indexTrial',zeros(100,1),...
                    'indexMeasurement',zeros(100,1),...
                    'indexSequence',zeros(100,1),...
                    'doesFileNamePassFilter',zeros(100,1),...
                    'numberOfSegmentsPassingFilter',zeros(100,1),...
                    'numberOfTagsPassingFilter',zeros(100,1),...
                    'passesAllFilters',zeros(100,1));



while(isLastMeasurement==0)

  idxTrial=idxTrial+1;  
  metaDataCache     = ...
     getNextMeasurement610A(expJson,expFolder,metaDataCache);
  
  isLastMeasurement = metaDataCache.isLastMeasurement;

  [~,metaDataFileName] = fileparts(metaDataCache.metaDataFilePath);

  isFileNameValid = applyKeywordFilter(metaDataFileName,...
                        keyWordFilter.metaDataFileName);

  validSegmentCount=0;
  for idxSeg = 1:1:length(metaDataCache.metaDataJson.segments)
    isSegmentValid = ...
      applyKeywordFilter(metaDataCache.metaDataJson.segments(idxSeg).type,...
                         keyWordFilter.segment);
    if(isSegmentValid==1)
      validSegmentCount=validSegmentCount+1;
    end
  end

  validTagCount = 0;
  for idxTag = 1:1:length(metaDataCache.metaDataJson.experiment.tags)
    isTagValid = ...
      applyKeywordFilter(metaDataCache.metaDataJson.experiment.tags{idxTag},...
                         keyWordFilter.tags);
    if(isTagValid==1)
      validTagCount=validTagCount+1;
    end
  end

  isPassingAllFilters = ...
    (isFileNameValid == 1 && validSegmentCount > 0 && validTagCount > 0);
  
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
    fprintf('%i\t%i\t%i\t%i\t%i\t%i\t%i\t%s\n',...
      idxTrial,...
      metaDataCache.indexMeasurement, ...
      metaDataCache.indexSequence, ...
      isFileNameValid,...
      validSegmentCount,...      
      validTagCount,...
      isPassingAllFilters,...
      metaDataFileName);
  
    if(idxMPrevious ~= metaDataCache.indexMeasurement)
      fprintf(fidScanLog,'\n');
    end
  
    fprintf(fidScanLog,'%i,%i,%i,%i,%i,%i,%i,%s\n',...
      idxTrial,...
      metaDataCache.indexMeasurement, ...
      metaDataCache.indexSequence, ...
      isFileNameValid,...      
      validSegmentCount,...
      validTagCount,...
      isPassingAllFilters,...
      metaDataFileName);
  end

  idxMPrevious=metaDataCache.indexMeasurement;


  if(idxTrial > length(scanResult.indexTrial))    
    scanResult.indexTrial       = [scanResult.indexTrial;zeros(100,1)];
    scanResult.indexMeasurement = [scanResult.indexMeasurement;zeros(100,1)];
    scanResult.indexSequence    = [scanResult.indexSequence;zeros(100,1)];
    scanResult.doesFileNamePassFilter= ...
      [scanResult.doesFileNamePassFilter;zeros(100,1)];
    scanResult.numberOfSegmentsPassingFilter = ...
      [scanResult.numberOfSegmentsPassingFilter;zeros(100,1)];
    scanResult.numberOfTagsPassingFilter = ...
      [scanResult.numberOfTagsPassingFilter;zeros(100,1)];
    scanResult.passesAllFilters = ...
      [scanResult.passesAllFilters;zeros(100,1)];
  end



  scanResult.indexTrial(idxTrial,1)       = idxTrial;
  scanResult.indexMeasurement(idxTrial,1) = metaDataCache.indexMeasurement;
  scanResult.indexSequence(idxTrial,1)    = metaDataCache.indexSequence;
  scanResult.doesFileNamePassFilter(idxTrial,1)= isFileNameValid;
  scanResult.numberOfSegmentsPassingFilter(idxTrial,1)=validSegmentCount;
  scanResult.numberOfTagsPassingFilter(idxTrial,1)=validTagCount;
  scanResult.passesAllFilters(idxTrial,1) = isPassingAllFilters;


end


scanResult.indexTrial               = scanResult.indexTrial(1:idxTrial);
scanResult.indexMeasurement         = scanResult.indexMeasurement(1:idxTrial);
scanResult.indexSequence            = scanResult.indexSequence(1:idxTrial);
scanResult.doesFileNamePassFilter= ...
  scanResult.doesFileNamePassFilter(1:idxTrial);
scanResult.numberOfSegmentsPassingFilter = ...
    scanResult.numberOfSegmentsPassingFilter(1:idxTrial);
scanResult.numberOfTagsPassingFilter = ...
    scanResult.numberOfTagsPassingFilter(1:idxTrial);
scanResult.passesAllFilters = ...
    scanResult.passesAllFilters(1:idxTrial);

metaDataCache =[];

if(verbose==1)
  fclose(fidScanLog);
end


success=1;