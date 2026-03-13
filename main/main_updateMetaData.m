clc;
close all;
clear all;


experimentsToProcess = {
  '20260116_impedance_larb_spring',...
  '20260108_impedance_larb_spring',...   
  '20251118_impedance_larb_1',...
  '20251118_impedance_larb_2',...
  '20251120_impedance_larb_3',...
  '20251121_impedance_larb_4',...
  '20251121_impedance_larb_5',...
  '20251128_impedance_larb_6',...
  '20251203_impedance_larb_7',...
  '20251114_degradation_larb_1',...
  '20251119_degradation_larb_2',...
  '20251121_degradation_larb_3',...
  '20251121_degradation_larb_4'...
};

rootDir         = getRootProjectDirectory();
projectFolders  = getProjectFolders(rootDir);

expMetaData.find = {'"number": "540349998",'};
expMetaData.replace  = {'"number": ["540349998","405834662"],'};

trialMetaData.find     = {'"time_ms"','"amplitude_Lo"','"bandwidth_Hz"',};
trialMetaData.replace  = {'"time"','"amplitude"','"bandwidth"'};
trialMetaData.add.name = 'units';
trialMetaData.add.struct = struct('time','ms','bandwidth','Hz','amplitude','Lo');



for idxExp = 1:1:length(experimentsToProcess)
  %%
  % Back up the experiment meta data file if necessary
  %%
  flag_backupOriginals = 0;
  if(~exist(depFolder,'dir'))
    mkdir(depFolder);
    flag_backupOriginals=1;
  end

  folderName      = experimentsToProcess{idxExp};
  dataFolder      = fullfile(projectFolders.data_600A,folderName);
  depFolder       = fullfile(dataFolder,'deprecated');   
  
  if(flag_backupOriginals==1)  
    experimentStr   = fileread(fullfile(dataFolder,[folderName,'.json']));
    fidExpOrig = fopen(fullfile(depFolder,[folderName,'.json.orig']),'w');
    fprintf(fidExpOrig,experimentStr);
    fclose(fidExpOrig);
  end

  %%
  %Read in the backup file 
  %%
  experimentStr   = fileread(fullfile(depFolder,[folderName,'.json']));

  %Update the experiment meta data file
  for idxFR = 1:1:length(expMetaData.find)
    experimentStr = replace(experimentStr,expMetaData.find{idxFR},...
                            expMetaData.replace{idxFR});    
  end

  fidExpUpdate = fopen(fullfile(dataFolder,[folderName,'.json']),'w');
  fprintf(fidExpUpdate,experimentStr);
  fclose(fidExpUpdate);

  experimentJson  = jsondecode(experimentStr);
  

  for idxTrial=1:1:length(experimentJson.trials)

    %%
    % Back up the original if necessary
    %%
    if(flag_backupOriginals==1)
      trialFileName = fullfile(dataFolder,experimentJson.trials{idxTrial});
      trialStr      = fileread(trialFileName);          
      fidTrialOrig = fopen(fullfile(depFolder,...
                           [experimentJson.trials{idxTrial},'.orig']),'w');
      fprintf(fidTrialOrig,trialStr);
      fclose(fidTrialOrig);
    end

    % Read in the original
    trialFileName = fullfile(depFolder,experimentJson.trials{idxTrial});
    trialStr      = fileread(trialFileName); 

    % Update the fields
    for idxFR = 1:1:length(trialMetaData.find)
      trialStr = replace(trialStr,trialMetaData.find{idxFR},...
                                  trialMetaData.replace{idxFR});
    end
    

    fidTrialUpdate = fopen(trialFileName,'w');
    fprintf(fidTrialUpdate,trialStr);
    fclose(fidTrialUpdate);
  end

end