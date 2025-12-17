function dataConfig = getImpedanceExperimentConfiguration600A_usingJson(...
                            experimentJson,folderName,projectFolders)

nTrials = length(experimentJson.trials);

dataConfig.folder           = folderName;
dataConfig.path             = fullfile(projectFolders.data_600A,dataConfig.folder);
dataConfig.numberOfTrials   = nTrials;

dataConfig.fileNameKeywords     = [];
dataConfig.numberOfTrials       = 0;
dataConfig.isActive             = [];
dataConfig.titleTrial           = [];
dataConfig.amplitude            = [];
dataConfig.bandwidthHz          = [];
dataConfig.bandwidthHzPlot      = [];
dataConfig.perturbationType     = [];
dataConfig.titleBlock           = [];
dataConfig.data                 = [];
dataConfig.protocol             = [];
dataConfig.labels               = [];
dataConfig.waveform             = [];

for i=1:1:length(experimentJson.trials)
    disp(experimentJson.trials{i});
    trialStr = fileread(fullfile(dataConfig.path,experimentJson.trials{i}));
    trialJson = jsondecode(trialStr);

    pathTypes = {'data','labels','protocol','waveform'};

    for j=1:1:length(pathTypes)
        localPath = trialJson.(pathTypes{j}).file{1};
        if(length(trialJson.(pathTypes{j}).file) >= 2 )
            for k=2:1:length(trialJson.(pathTypes{j}).file)
                localPath = [localPath,filesep,trialJson.(pathTypes{j}).file{k}];
            end
        end
        dataConfig.(pathTypes{j}) = [dataConfig.(pathTypes{j});{localPath}]; 
    end

%     if(length(trialJson.data.file)>=1)
%         dataLocalPath = trialJson.data.file{1};
%         if(length(trialJson.data.file)>=2)
%             for j=2:1:length(trialJson.data.file)
%                 dataLocalPath =[dataLocalPath,filesep,trialJson.data.file{j}];
%             end
%         end
%     end
% 
%     dataConfig.dataFiles = [dataConfig.fileNameKeywords;{dataLocalPath}];


    dataConfig.isActive     = [dataConfig.isActive;...
                               trialJson.waveform.is_active];
    dataConfig.titleTrial   = [dataConfig.titleTrial;...
                               {trialJson.experiment.title}];
    dataConfig.amplitude    = [dataConfig.amplitude;...
                               trialJson.waveform.amplitude'];
    dataConfig.bandwidthHz  = [dataConfig.bandwidthHz;...
                               trialJson.waveform.bandwidth'];

    bandwidthPlot = trialJson.waveform.bandwidth+[-1,1];
    if(bandwidthPlot(1,1)<0)
        bandwidthPlot(1,1)=0;
    end

    dataConfig.bandwidthHzPlot  = [dataConfig.bandwidthHzPlot;...
                                   bandwidthPlot];
    dataConfig.perturbationType = [dataConfig.perturbationType;...
                                   trialJson.waveform.label];

    dataConfig.titleBlock = [dataConfig.titleBlock,{''}];
end


lossPerTrial     = 0.0;
idxTrialFmax     = 1;
normalizeData    = 0;

dataConfig.fmaxScaling = ones(nTrials,1);
dataConfig.trialUsedForFmax    = nan;

%
% Plot settings 
%
dataConfig.lengthLimitsOffset = [-ones(nTrials,1),ones(nTrials,1)].*0.025;
dataConfig.forceLimitsOffset  = [-ones(nTrials,1),ones(nTrials,1)].*3;        
dataConfig.timeIntervalOffset =  ones(nTrials,2).*([0.750,0.950].*1000);

dataConfig.coherenceSqYLim      = [0,1].*ones(nTrials,2);
dataConfig.gainNormYLim         = [0,110].*ones(nTrials,2);
dataConfig.phaseYLim            = [-45,45].*ones(nTrials,2);
dataConfig.addStressStrainPlot  = 1;        
dataConfig.normalizeData        = 0; 
dataConfig.trialPlotColumn      = [1:nTrials];



