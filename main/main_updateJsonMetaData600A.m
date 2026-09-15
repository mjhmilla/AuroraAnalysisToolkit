clc;
close all;
clear all;

rootDir         = getRootProjectDirectory();
projectFolders  = getProjectFolders(rootDir);

addpath(projectFolders.aurora600A);
addpath(projectFolders.common);
addpath(projectFolders.postprocessing);
addpath(projectFolders.experiments);
addpath(fullfile(rootDir,'aurora600A_impedance'));

% '20251114_degradation_larb_1',...
% '20251119_degradation_larb_2',...
% '20251121_degradation_larb_3',...
% '20251121_degradation_larb_4',...
% '20251118_impedance_larb_1',...
% '20251118_impedance_larb_2',...
% '20251120_impedance_larb_3',...
% '20251121_impedance_larb_4',...
% '20251121_impedance_larb_5',...
% '20251128_impedance_larb_6',...
% '20251203_impedance_larb_7',...
% '20260109_impedance_temperature_pilot',...
% '20260116_impedance_larb_spring',...
%   '20260504_impedance_calibration',...
%   '20260703_impedance_calibration_larb_fiber'
experimentsToProcess =    ...
  {'20260827_impedance_calibration_rigor_fixation_01'};



flag_updateExperiment     =0;
flag_updateTrials         =1;


flag_updateExperimentKeywords =0;
flag_updateControlFunctionKeywords=1;
flag_updateLengthArb          =0;
flag_updateRelativeUnits      =0;
flag_updateBath               =0;

experimentType = 'impedance';

experiment.keywords = {'Impedance-Length-Arb',...
                       'Impedance-Individual-Length-Sine'};
experiment.controlFunctions = {'Length-Arb','Length-Sine'};

LengthArbSettings.point_count = [1,1,1,1, 1,1,1,1].*8192;
LengthArbSettings.wave_number = [2,2,2,2, 4,4,4,4];
LengthArbSettings.frequency   = [1,1,1,1, 1,1,1,1].*1000;

setBathUsingTitleKeywords=1;
bathTitleKeywords={'passive','active','rigor','fixed','karnovsky'};
bathNames        ={'passive','active','rigor','Karnovsky','Karnovsky'};

todayYMD=datevec(date);

backupFolderName = ...
  ['backup_',num2str(todayYMD(1)),num2str(todayYMD(2)),num2str(todayYMD(3))];

backupFolderPath = fullfile(projectFolders.data600A,backupFolderName);

if(~exist(backupFolderPath,'dir'))
  mkdir(backupFolderPath);
end


for i=1:1:length(experimentsToProcess)
  
   
  fprintf('\n\n%s\n',experimentsToProcess{i});

  folderName=experimentsToProcess{i};
  dataFolder      = fullfile(projectFolders.data600A,folderName);
  experimentStr   = fileread(fullfile(dataFolder,[folderName,'.json']));
  experimentJson  = jsondecode(experimentStr);

  backupFolderExpPath = fullfile(backupFolderPath,folderName);
  if(~exist(backupFolderExpPath,'dir'))
    mkdir(backupFolderExpPath);
  end  

  if(flag_updateExperiment==1)
    jsonFilePath=fullfile(dataFolder,[folderName,'.json']);
    jsonFileBackupPath=fullfile(backupFolderExpPath,...
                                [folderName,'.json']);    
    [statusBkup,msgBkup]=copyfile(jsonFilePath,jsonFileBackupPath);

    experimentJson.experiment.type = experimentType;
    trialJsonStr = jsonencode(experimentJson);
    fidJson = fopen(jsonFilePath,'w');
    fprintf(fidJson,trialJsonStr);        
    fclose(fidJson);  
    here=1;
  end

  if(flag_updateTrials==1)
    for j=1:1:length(experimentJson.measurements)
      fprintf('\t%s\n',experimentJson.measurements{j});
      commentStr = '';
      %%
      % Fetch the experimental data files
      %%
      jsonFilePath=fullfile(dataFolder,experimentJson.measurements{j});
      jsonFileBackupPath=fullfile(backupFolderExpPath,...
                                  experimentJson.measurements{j});
  
      [statusBkup,msgBkup]=copyfile(jsonFilePath,jsonFileBackupPath);
  
      trialStr = fileread(fullfile(dataFolder,experimentJson.measurements{j}));
      trialJson = jsondecode(trialStr);
  
      %%
      % Update the fields
      %%
      if(flag_updateExperimentKeywords==1)
        trialJson.experiment.keywords=experiment.keywords;
    
        if(isfield(trialJson,'experiments'))
          trialJson=rmfield(trialJson,'experiments');
        end
      end

      if(flag_updateControlFunctionKeywords==1)

        for k=1:1:length(trialJson.segments)
          foundControlFunction=0;
          foundKeywords = 0;
          cf='';
          kw='';
          idxCF=0;
          for idxA = 1:1:length(experiment.controlFunctions)
            if(strcmp(trialJson.segments(k).type,...
                      experiment.controlFunctions{idxA}) == 1)
              assert(foundControlFunction==0);
              foundControlFunction=1;
              cf=experiment.controlFunctions{idxA};
              idxCF=idxA;
            end
          end
          if(foundControlFunction==1)
            for idxA = 1:1:length(trialJson.experiment.keywords)
              if(strcmp(trialJson.experiment.keywords{idxA},...
                        experiment.keywords{idxCF}) == 1)
                assert(foundKeywords==0);
                assert(idxA==idxCF);
                foundKeywords=1;
                kw = experiment.keywords{idxA};              
              end
            end
    
            if(foundControlFunction==1 && foundKeywords==1)
              if(isfield(trialJson.segments(k).meta_data,'keywords'))
                %Check to see if the keyword already exists
                foundExistingEntry=0;
                for idxA = 1:1:length(trialJson.segments(k).meta_data.keywords)
                  if(strcmp(trialJson.segments(k).meta_data.keywords{idxA},...
                            kw)==1)
                    foundExistingEntry=1;
                  end
                end
                if(foundExistingEntry==0)
                  trialJson.segments(k).meta_data.keywords = ...
                    [trialJson.segments(k).meta_data.keywords,{kw}];
                end
              else
                trialJson.segments(k).meta_data.keywords = {kw};
              end
            end
          end
        end
      end
  
      if(flag_updateLengthArb==1)
        for k=1:1:length(trialJson.segments)
          trialJson.segments(k).is_recorded=1;      
          if(strcmp(trialJson.segments(k).type,'Larb-Stochastic') ...
              || strcmp(trialJson.segments(k).type,'Length-Arb'))
            trialJson.segments(k).type='Length-Arb';
            trialJson.segments(k).meta_data.wave_number=...
              LengthArbSettings.wave_number(j);
            trialJson.segments(k).meta_data.point_count=...
              LengthArbSettings.point_count(j);
            trialJson.segments(k).meta_data.frequency_Hz=...
              LengthArbSettings.frequency(j);
          end
        end
      end
  
      if(flag_updateRelativeUnits==1)
        if(strcmp(trialJson.segments(k).type,'Length-Ramp') ...
            || strcmp(trialJson.segments(k).type,'Length-Step') ...
            || strcmp(trialJson.segments(k).type,'Force-Ramp') ...
            || strcmp(trialJson.segments(k).type,'Force-Step'))
          trialJson.segments(k).meta_data.is_relative=0;
        end      
      end
  
      if(flag_updateBath==1)
        if(isfield(trialJson.segments(k).meta_data,'is_active'))
          if(trialJson.segments(k).meta_data.is_active==1)
            trialJson.segments(k).meta_data.bath='active';
          else
            trialJson.segments(k).meta_data.bath='passive';
          end
          trialJson.segments(k).meta_data=...
            rmfield(trialJson.segments(k).meta_data,'is_active'); 
        end
  
        if(setBathUsingTitleKeywords==1)
          found=0;
          for idxKeyword=1:1:length(bathTitleKeywords)
            
            if(contains(experimentJson.measurements{j},...
                        bathTitleKeywords{idxKeyword}))
              assert(found==0,'Error: found more than one bath keyword in title');
              trialJson.segments(k).meta_data.bath = bathNames{idxKeyword};
              found=1;
            end
          end
        end
      end  
  
  
    trialJsonStr = jsonencode(trialJson);
    fidJson = fopen(jsonFilePath,'w');
    fprintf(fidJson,trialJsonStr);        
    fclose(fidJson);    
    here=1;
    end  
  end
end
