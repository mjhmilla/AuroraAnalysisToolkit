function metaDataCache = getMeasurement610A(indexMeasurement,...
                                            indexSequence,...
                                            indexTrial,...
                                            expJson,...
                                            expFolder,...
                                            metaDataCache)

idxM = indexMeasurement;
idxS = indexSequence;

metaDataCache.indexTrial      =indexTrial;
metaDataCache.indexMeasurement=idxM;
metaDataCache.indexSequence   =idxS;

if(contains(expJson.measurements{idxM},'.seq'))

  if(idxS==0)
    idxS = 1;
    metaDataCache.indexSequence = idxS;
  end

  metaDataCache.sequenceFileName = expJson.measurements{idxM};
  metaDataCache.sequenceFilePath = fullfile(expFolder,...
                                      expJson.measurements{idxM});


  seqFile = fileread(metaDataCache.sequenceFilePath);
  seqJson = jsondecode(seqFile);

  metaDataCache.sequenceJson = seqJson;

  metaDataFolder = [];
  for i=1:1:length(seqJson.sequence.meta_data.folder)
    metaDataFolder = [metaDataFolder,filesep,...
                      seqJson.sequence.meta_data.folder{i}];
  end

  dataFolder = [];
  for i=1:1:length(seqJson.sequence.data.folder)
    dataFolder = [dataFolder,filesep,...
                  seqJson.sequence.data.folder{i}];
  end
  
  metaDataCache.measurementFileName = expJson.measurements{idxM};
  metaDataCache.metaDataFilePath = ...
    fullfile( expFolder, ...
              metaDataFolder, ...
              seqJson.sequence.meta_data.files{idxS});

  metaDataCache.metaDataFileName = seqJson.sequence.meta_data.files{idxS};
  metaDataStr = fileread(metaDataCache.metaDataFilePath);      
  metaDataCache.metaDataJson = jsondecode(metaDataStr);


  metaDataCache.dataFileName = seqJson.sequence.data.files{idxS};
  metaDataCache.dataFilePath = fullfile(expFolder, ...
                                        dataFolder, ...
                                        seqJson.sequence.data.files{idxS});

  metaDataCache.dataSha256Sum= seqJson.sequence.data.sha256{idxS};

  metaDataCache.protocolFilePath = [];

  if(isfield(seqJson.sequence,'protocols'))
    if(~isempty(seqJson.sequence.protocols.folder) ...
        && ~isempty(seqJson.sequence.protocols.files))
      if(strcmp(seqJson.sequence.protocols.files,'MISSING')==0)         
        protocolsFolder = [];
        for i=1:1:length(seqJson.sequence.protocols.folder)
          protocolsFolder = [protocolsFolder,filesep,...
                             seqJson.sequence.protocols.folder{i}];
        end

        metaDataCache.protocolFileName = ...
          seqJson.sequence.protocols.files{idxS};

        metaDataCache.protocolFilePath = ...
          fullfile( expFolder,...
                    protocolsFolder,...
                    seqJson.sequence.protocols.files{idxS});
      end        
    end
  end

  metaDataCache.isLastMeasurement=0;

  if(     idxM == length(expJson.measurements) ...
      &&  idxS == length(seqJson.sequence.meta_data.files))
    metaDataCache.isLastMeasurement=1;
  end

else

  metaDataCache.indexSequence = 0;
  metaDataCache.sequenceFilePath = '';
  metaDataCache.sequenceJson     = [];

  trialFile = fileread(fullfile(expFolder,...
                        expJson.measurements{idxM}));
  trialJson = jsondecode(trialFile);
  

  dataPath = [];
  for i=1:1:length(trialJson.data.file)
    dataPath = [dataPath,filesep,...
                trialJson.data.file{i}];
  end


  protocolPath = [];
  metaDataCache.protocolFilePath = [];  
  
  if(~isempty(trialJson.protocol))
    if(~isempty(trialJson.protocol.file))
      for i=1:1:length(trialJson.protocol.file)
        protocolPath = [protocolPath,filesep,...
                    trialJson.protocol.file{i}];
      end 
      metaDataCache.protocolFileName = trialJson.protocol.file{end};
      metaDataCache.protocolFilePath = ...
        fullfile(expFolder,...
                 protocolPath);      
    end
  end

  metaDataCache.measurementFileName = expJson.measurements{idxM};
  metaDataCache.metaDataFileName = expJson.measurements{idxM};
  metaDataCache.metaDataFilePath = fullfile(expFolder,...
                                   expJson.measurements{idxM});
    
  metaDataCache.metaDataJson = trialJson;

  metaDataCache.dataFileName = trialJson.data.file{end};
  metaDataCache.dataFilePath = fullfile(expFolder, ...
                                        dataPath);

  metaDataCache.dataSha256Sum= trialJson.data.sha256;    

  metaDataCache.isLastMeasurement=0;

  if(length(expJson.measurements) == idxM)
    metaDataCache.isLastMeasurement=1;
  end

end

%
% Extract meta data which is sometimes specific to the trial
%

if(isfield(metaDataCache.metaDataJson.experiment,'tags'))
  metaDataCache.tags = metaDataCache.metaDataJson.experiment.tags;
else
  metaDataCache.tags = {};
end

if(isfield(expJson.experiment,'manually_measured_temperature_C'))
  if(isfield(expJson.experiment.manually_measured_temperature_C,'range_C'))
    for i=1:1:length(expJson.experiment.manually_measured_temperature_C)    
      for j=1:1:length(expJson.experiment.manually_measured_temperature_C(i))
        if (abs(idxM-expJson.experiment.manually_measured_temperature_C(i).measurements(j)) < 1e-3) 
          metaDataCache.temperature_C= ...
            expJson.experiment.manually_measured_temperature_C(i).range_C;
        end
      end
    end
  else
    metaDataCache.temperature_C = ...
      expJson.experiment.manually_measured_temperature_C;
  end
else
  metaDataCache.temperature_C = nan;
end

if(isfield(expJson.experiment,'mounted_reference_state'))
  for i=1:1:length(expJson.experiment.mounted_reference_state)
    for j=1:1:length(expJson.experiment.mounted_reference_state(i))
      if (abs(idxM-expJson.experiment.mounted_reference_state(i).measurements(j)) < 1e-3) 
        fieldList = fields(expJson.experiment.mounted_reference_state(i));
        for k=1:1:length(fieldList)
          if(~strcmp(fieldList{k},'measurements'))
            metaDataCache.referenceState.(fieldList{k}) = ...
              expJson.experiment.mounted_reference_state(i).(fieldList{k});
          end
        end
      end
    end
  end  
else
  metaDataCache.referenceState = [];
end

if(isfield(expJson.experiment,'dimensions'))
  metaDataCache.dimensions = expJson.experiment.dimensions;
else
  metaDataCache.dimensions = [];
end


if(isfield(expJson.experiment,'specimen'))
  metaDataCache.specimen = expJson.experiment.specimen;
else
  metaDataCache.specimen = [];
end
