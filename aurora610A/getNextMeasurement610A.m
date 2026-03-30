function metaDataCache = getNextMeasurement610A(...
                          experimentJson, ...
                          experimentFolder,...
                          metaDataCache)

emptyMetaDataCache = struct('indexMeasurement',0,...
                            'indexSequence',0,...
                            'sequenceFilePath','',...
                            'sequenceJson',[],...
                            'metaDataJson',[],...
                            'metaDataFilePath','',...
                            'dataFilePath','',...
                            'dataSha256Sum','',...
                            'protocolFilePath','',...
                            'isLastMeasurement',0);

%
% Set the indicies
%

if(isempty(metaDataCache))

  metaDataCache = emptyMetaDataCache;
  idxM = 1;
  metaDataCache.indexMeasurement = idxM;
  if(contains(experimentJson.measurements{1},'.seq'))
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

  if(contains(metaDataCache.measurementFileName,'.seq'))
    seqFile = fileread(fullfile(experimentFolder,...
                       metaDataCache.measurementFileName));
    seqJson = jsondecode(seqFile);    

    if(metaDataCache.indexSequence < length(seqJson.sequence.meta_data.files))
      metaDataCache.indexSequence = metaDataCache.indexSequence+1;
    else
      
      assert(metaDataCache.indexMeasurement ...
           <= length(experimentJson.measurements),...
           'Error: Attempting to read beyond last measurement');

      metaDataCache.indexMeasurement=metaDataCache.indexMeasurement+1;
      metaDataCache.indexSequence   = 0;      
    end
  else
    if(metaDataCache.indexMeasurement < length(experimentJson.measurements))
        metaDataCache.indexMeasurement=metaDataCache.indexMeasurement+1;
        metaDataCache.indexSequence   = 0;
    end
    assert(metaDataCache.indexMeasurement ...
         <= length(experimentJson.measurements),...
         'Error: Attempting to read beyond last measurement');
  end

end


%
% Populate the data
%
idxM = metaDataCache.indexMeasurement;
idxS = metaDataCache.indexSequence;

if(contains(experimentJson.measurements{idxM},'.seq'))

  if(idxS==0)
    idxS = 1;
    metaDataCache.indexSequence = idxS;
  end

  metaDataCache.sequenceFilePath = fullfile(experimentFolder,...
                                      experimentJson.measurements{idxM});


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
  
  metaDataCache.measurementFileName = experimentJson.measurements{idxM};
  metaDataCache.metaDataFilePath = ...
    fullfile( experimentFolder, ...
              metaDataFolder, ...
              seqJson.sequence.meta_data.files{idxS});

  metaDataStr = fileread(metaDataCache.metaDataFilePath);      
  metaDataCache.metaDataJson = jsondecode(metaDataStr);

  metaDataCache.dataFilePath = fullfile(experimentFolder, ...
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
        metaDataCache.protocolFilePath = ...
          fullfile( experimentFolder,...
                    protocolsFolder,...
                    seqJson.sequence.protocols.files{idxS});
      end        
    end
  end

  metaDataCache.isLastMeasurement=0;

  if(     idxM == length(experimentJson.measurements) ...
      &&  idxS == length(seqJson.sequence.meta_data.files))
    metaDataCache.isLastMeasurement=1;
  end

else

  metaDataCache.indexSequence = 0;
  metaDataCache.sequenceFilePath = '';
  metaDataCache.sequenceJson     = [];

  trialFile = fileread(fullfile(experimentFolder,...
                        experimentJson.measurements{idxM}));
  trialJson = jsondecode(trialFile);
  

  dataPath = [];
  for i=1:1:length(trialJson.data.file)
    dataPath = [dataPath,filesep,...
                trialJson.data.file{i}];
  end


  protocolPath = [];
  if(~isempty(trialJson.protocol))
    for i=1:1:length(trialJson.protocol.file)
      protocolPath = [protocolPath,filesep,...
                  trialJson.protocol.file{i}];
    end 
    metaDataCache.protocolFilePath = ...
      fullfile(experimentFolder,...
               protocolPath);      
  else
    metaDataCache.protocolFilePath = [];
  end

  metaDataCache.measurementFileName = experimentJson.measurements{idxM};
  metaDataCache.metaDataFilePath = fullfile(experimentFolder,...
                                   experimentJson.measurements{idxM});
    
  metaDataCache.metaDataJson = trialJson;

  metaDataCache.dataFilePath = fullfile(experimentFolder, ...
                                        dataPath);

  metaDataCache.dataSha256Sum= trialJson.data.sha256;    

  metaDataCache.isLastMeasurement=0;

  if(length(experimentJson.measurements) == idxM)
    metaDataCache.isLastMeasurement=1;
  end

end




