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

segId = 4; % 0-90 Hz bandwidth, 0.001 Lo perturbation
hId = 'H2';


experimentsToProcess = ...
    { '20251118_impedance_larb_1',...
      '20251118_impedance_larb_2',...
      '20251120_impedance_larb_3',...
      '20251121_impedance_larb_4',...
      '20251121_impedance_larb_5',...
      '20251128_impedance_larb_6',...
      '20251203_impedance_larb_7'};

outputFolder = 'impedance_length_relation_larb';

impedanceData(7) = struct('normLengthStr','',...
                          'normLength',0,...
                          'normStorage',[],...
                          'normLoss',[],...
                          'maxNormStorageAtLopt',0,...
                          'maxNormLossAtLopt',0);
for i=1:1:length(impedanceData)
  impedanceData(i) = struct('normLengthStr','',...
                            'normLength',0.55 + 0.15*(i-1),...
                            'normStorage',[],...
                            'normLoss',[],...
                            'maxNormStorageAtLopt',0,...
                            'maxNormLossAtLopt',0);
  impedanceData(i).normLengthStr = ...
      sprintf('_%iLo_',round(impedanceData(i).normLength*100));
  fprintf('%1.2f\t%s\n',impedanceData(i).normLength,impedanceData(i).normLengthStr);
end

%%
% Plot configuration
%%

%
% Individual
%
figImpedanceLengthIndividual = figure;

numberOfHorizontalPlotColumnsGeneric    = length(experimentsToProcess);
numberOfVerticalPlotRowsGeneric         = 2;

plotWidth                               = ones(1,numberOfHorizontalPlotColumnsGeneric).*6;
plotHeight                              = ones(numberOfVerticalPlotRowsGeneric,1).*6;
plotHorizMarginCm                       = 2;
plotVertMarginCm                        = 2.5;
baseFontSize                            = 12;

[subPlotPanelIndividual, pageWidthIndividual,pageHeightIndividual]= ...
  plotConfigGeneric(  numberOfHorizontalPlotColumnsGeneric,...
                      numberOfVerticalPlotRowsGeneric,...
                      plotWidth,...
                      plotHeight,...
                      plotHorizMarginCm,...
                      plotVertMarginCm,...
                      baseFontSize); 

%
% Group
%
figImpedanceLengthGroup = figure;

numberOfHorizontalPlotColumnsGeneric    = 1;
numberOfVerticalPlotRowsGeneric         = 2;

plotWidth                               = ones(1,numberOfHorizontalPlotColumnsGeneric).*6;
plotHeight                              = ones(numberOfVerticalPlotRowsGeneric,1).*6;

[subPlotPanelGroup, pageWidthGroup,pageHeightGroup]= ...
  plotConfigGeneric(  numberOfHorizontalPlotColumnsGeneric,...
                      numberOfVerticalPlotRowsGeneric,...
                      plotWidth,...
                      plotHeight,...
                      plotHorizMarginCm,...
                      plotVertMarginCm,...
                      baseFontSize); 



for i = 1:1:length(experimentsToProcess)
    expFolder = fullfile(projectFolders.output,'json',...
                         experimentsToProcess{i});

    folderContents = dir(expFolder);
    trialCount = 0;
    dataLoptJson = [];
    for j=1:1:length(folderContents)
        if(~folderContents(j).isdir ...
            && contains(folderContents(j).name,'.json'))
            trialCount=trialCount+1;

            if(contains(folderContents(j).name,'_100Lo_'))
              dataStr =fileread(fullfile(expFolder,folderContents(j).name));
              dataLoptJson=jsondecode(dataStr);
            end
        end
    end
    
    assert(~isempty(dataLoptJson),'Error: could not find a trial at 100Lo');

    for j=1:1:length(folderContents)
        if(~folderContents(j).isdir ...
                && contains(folderContents(j).name,'.json'))
            dataStr =fileread(fullfile(expFolder,folderContents(j).name));
            dataJson=jsondecode(dataStr);

            %dataJson(segId).segment.

            figure(figImpedanceLengthIndividual);
        end
    end



        
end

figure(figImpedanceLengthGroup);
subplot('Position',reshape(subPlotPanelGroup(1,1,:),1,4));

subplot('Position',reshape(subPlotPanelGroup(1,2,:),1,4));

    
outputPlotDir = fullfile(projectFolders.output_plots,outputFolder);
if(~exist(outputPlotDir))
    mkdir(outputPlotDir);
end

figImpedanceIndividual=...
  configPlotExporter( figImpedanceIndividual, ...
                      pageWidthIndividual, ...
                      pageHeightIndividual);

fileName =    ['fig_ImpedanceIndividual'];

print('-dpdf', fullfile(outputPlotDir,[fileName,'.pdf']));    

saveas(figImpedanceIndividual,...
       fullfile(outputPlotDir,[fileName,'.fig']));

close(figImpedanceIndividual);
