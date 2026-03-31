clc;
close all;
clear all;

experimentsToProcess = {'20260109_impedance_temperature_pilot'};
flag_backupOriginals = 1;


% experimentsToProcess = {
%   '20260116_impedance_larb_spring',...
%   '20260108_impedance_larb_spring',...   
%   '20251118_impedance_larb_1',...
%   '20251118_impedance_larb_2',...
%   '20251120_impedance_larb_3',...
%   '20251121_impedance_larb_4',...
%   '20251121_impedance_larb_5',...
%   '20251128_impedance_larb_6',...
%   '20251203_impedance_larb_7',...
%   '20251114_degradation_larb_1',...
%   '20251119_degradation_larb_2',...
%   '20251121_degradation_larb_3',...
%   '20251121_degradation_larb_4'...
% };

rootDir         = getRootProjectDirectory();
projectFolders  = getProjectFolders(rootDir);

expMetaData.find = {'"number": "540349998",'};
expMetaData.replace  = {'"number": ["540349998","405834662"],'};

trialMetaData.find     = {'"duration"','"amplitude"','"bandwidth"'};
trialMetaData.replace  = {'"time_ms"','"amplitude_Lo"','"bandwidth_Hz"',};
trialMetaData.add.name = 'units';
trialMetaData.add.struct = struct('time','ms','bandwidth','Hz','amplitude','Lo');



for idxExp = 1:1:length(experimentsToProcess)
  %%
  % Back up the experiment meta data file if necessary
  %%


  folderName      = experimentsToProcess{idxExp};
  dataFolder      = fullfile(projectFolders.data600A,folderName);
  depFolder       = fullfile(dataFolder,'deprecated');   

  if(~exist(depFolder,'dir'))
    mkdir(depFolder);
    flag_backupOriginals=1;
  end

  dirDep = dir(fullfile(dataFolder,depFolder));

  if(flag_backupOriginals==1 && length(dirDep)==2)  
    experimentStr   = fileread(fullfile(dataFolder,[folderName,'.json']));
    fidExpOrig = fopen(fullfile(depFolder,[folderName,'.json.orig']),'w');
    fprintf(fidExpOrig,experimentStr);
    fclose(fidExpOrig);
  end

  %%
  %Read in the backup file 
  %%
  experimentStr   = fileread(fullfile(depFolder,[folderName,'.json.orig']));

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
    if(flag_backupOriginals==1 && length(dirDep)==2)
      trialFileName = fullfile(dataFolder,experimentJson.trials{idxTrial});
      trialStr      = fileread(trialFileName);          
      fidTrialOrig = fopen(fullfile(depFolder,...
                           [experimentJson.trials{idxTrial},'.orig']),'w');
      fprintf(fidTrialOrig,trialStr);
      fclose(fidTrialOrig);
    end

    % Read in the original
    trialOrigFileName = fullfile(depFolder,[experimentJson.trials{idxTrial},'.orig']);
    trialStr      = fileread(trialOrigFileName); 

    % Update the fields
    for idxFR = 1:1:length(trialMetaData.find)
      trialStr = replace(trialStr,trialMetaData.find{idxFR},...
                                  trialMetaData.replace{idxFR});
    end
    
    trialFileName = fullfile(dataFolder,experimentJson.trials{idxTrial});    

    fidTrialUpdate = fopen(trialFileName,'w');
    fprintf(fidTrialUpdate,trialStr);
    fclose(fidTrialUpdate);
  end

end