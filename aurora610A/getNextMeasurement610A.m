function metaDataCache = getNextMeasurement610A(...
                          expJson, ...
                          expFolder,...
                          metaDataCache)



%
% Set the indicies
%

if(isempty(metaDataCache))

  metaDataCache=getEmptyMetaDataCache610A();

  metaDataCache.indexTrial=1;
  idxM = 1;
  metaDataCache.indexMeasurement = idxM;
  if(contains(expJson.measurements{1},'.seq'))
    idxM = 1;
    metaDataCache.indexMeasurement = idxM;
    idxS = 1;
    metaDataCache.indexSequence=idxS;
  else
    idxM = 1;
    metaDataCache.indexMeasurement = idxM;
    idxS = 0;
    metaDataCache.indexSequence=idxS;  
  end

else

  metaDataCache.indexTrial=metaDataCache.indexTrial+1;
  
  if(contains(metaDataCache.measurementFileName,'.seq'))
    seqFile = fileread(fullfile(expFolder,...
                       metaDataCache.measurementFileName));
    seqJson = jsondecode(seqFile);    

    if(metaDataCache.indexSequence < length(seqJson.sequence.meta_data.files))
      metaDataCache.indexSequence = metaDataCache.indexSequence+1;
    else
      
      assert(metaDataCache.indexMeasurement ...
           <= length(expJson.measurements),...
           'Error: Attempting to read beyond last measurement');

      metaDataCache.indexMeasurement=metaDataCache.indexMeasurement+1;
      metaDataCache.indexSequence   = 0;      
    end
  else
    if(metaDataCache.indexMeasurement < length(expJson.measurements))
        metaDataCache.indexMeasurement=metaDataCache.indexMeasurement+1;
        metaDataCache.indexSequence   = 0;
    end
    assert(metaDataCache.indexMeasurement ...
         <= length(expJson.measurements),...
         'Error: Attempting to read beyond last measurement');
  end

end


%
% Populate the data
%

 metaDataCache = getMeasurement610A(metaDataCache.indexMeasurement,...
                                    metaDataCache.indexSequence,...
                                    metaDataCache.indexTrial,...
                                    expJson,...
                                    expFolder,...
                                    metaDataCache);



