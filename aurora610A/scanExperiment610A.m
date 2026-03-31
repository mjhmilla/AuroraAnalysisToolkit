function success = scanExperiment610A(experimentName,...
                                      keyWordFilter,...
                                      projectFolders)

fidScanLog = fopen(fullfile(projectFolders.data610A,...
                            experimentName,...
                            ['log_scan_',experimentName,'.txt']),'w');

success=  0;

expStr = fileread(fullfile(projectFolders.data610A,...
                            experimentName,...
                           [experimentName,'.json']));
expJson = jsondecode(expStr);
expFolder = fullfile(projectFolders.data610A,...
                     experimentName);



idxTrial = 0;
fprintf('%s\t%s\t%s\t%s\t%s\n',...
        'File ','Meas.','Seq. ','Passes_Filter','Name');


fprintf(fidScanLog,'%s\t%s\t%s\t%s\t%s\n',...
        'File ','Meas. ','Seq. ','Passes_Filter','Name');


validCount        = 0;
isLastMeasurement = 0;
metaDataCache     = [];
idxMPrevious = 0;
while(isLastMeasurement==0)

  idxTrial=idxTrial+1;  
  metaDataCache     = ...
     getNextMeasurement610A(expJson,expFolder,metaDataCache);
  
  isLastMeasurement = metaDataCache.isLastMeasurement;

  [~,metaDataFileName] = fileparts(metaDataCache.metaDataFilePath);

  isValid = applyKeywordFilter(metaDataFileName,keyWordFilter);
  validStr = '';
  if(isValid==1)
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

  idxMPrevious=metaDataCache.indexMeasurement;

end
metaDataCache =[];
fclose(fidScanLog);
success=1;