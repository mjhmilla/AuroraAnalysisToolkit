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
        'File #','Meas. #','Seq. #','Valid','Name');


fprintf(fidScanLog,'%s\t%s\t%s\t%s\t%s\n',...
        'File #','Meas. #','Seq. #','Valid','Name');


validCount        = 0;
isLastMeasurement = 0;
metaDataCache     = [];

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


  fprintf('%i\t%i\t%i\t%s\t%s\n',idxTrial,...
    metaDataCache.indexMeasurement, ...
    metaDataCache.indexSequence, ...
    validStr,...
    metaDataFileName);


  fprintf(fidScanLog,'%i\t%i\t%i\t%s\t%s\n',idxTrial,...
    metaDataCache.indexMeasurement, ...
    metaDataCache.indexSequence, ...
    validStr,...
    metaDataFileName);

end
metaDataCache =[];
fclose(fidScanLog);
success=1;