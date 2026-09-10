function success = ...
  runPipelineAnalyzeSinusoidalAnalysisFiberData600A_json(...
    folderName, fileKeyWord,specimenType, trialType, ...
    modelSeries, settings,projectFolders)

success=0;
mm2m = 0.001;


assert(strcmp(settings.daqDelayModel,'frequency-domain'),...
     ['Error: the DAQ delay can only be compensated',...
    ' in the frequency-domain using this implementation']);

flag_readHeader       = 1;
flag_checkSha256Sum   = 1; %Might not work on Windows

setOfSpecimenTypes = {'spring','fiber'};
foundSpecimenType=0;
for i=1:1:length(setOfSpecimenTypes)
  if(strcmp(setOfSpecimenTypes{i},specimenType))
    foundSpecimenType=1;
  end
end
assert(foundSpecimenType,...
  ['Error: specimen name does not contain one of the following'...
      ' keywords: spring or fiber']);


setOfTrialTypes = {'impedance','impedance calibration'};
foundTrialType=0;
for i=1:1:length(setOfTrialTypes)
  if(strcmp(setOfTrialTypes{i},trialType))
    foundTrialType=1;
  end
end
assert(foundTrialType,...
  ['Error: folder name does not contain one of the following'...
      ' keywords: spring, impedance, or degradation']);



keyword.label      = 'Larb-Stochastic';
keyword.controlFunction= 'Length-Arb';
