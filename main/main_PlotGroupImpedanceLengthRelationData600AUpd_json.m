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

flag_createDataSet            = 0;
flag_makeResultsPlotsTables   = 1;

flag_0Presentation_1Publication = 1;


%
% Data set configuration
%
experimentList = {  '20251118_impedance_larb_1',...
                    '20251118_impedance_larb_2',...
                    '20251120_impedance_larb_3',...
                    '20251121_impedance_larb_4',...
                    '20251121_impedance_larb_5',...
                    '20251128_impedance_larb_6',...
                    '20251203_impedance_larb_7'};

categories.length.value = ...
  [0.55,0.70,0.85,1.00,1.15,1.30,1.45];
categories.isLo = ...
  [   0,   0,   0,   1,   0,   0,   0];

categories.length.str   = ...
  {'055Lo','070Lo','085Lo','100Lo','115Lo','130Lo','145Lo'};  
categories.length.indexLopt=4;
categories.active.str   ={'active','passive'};

segmentSeries = [1,2,3,4];

settingsDataSet.numberOfTableRows=150; %should be bigger than the longest vector
settingsDataSet.keyWordActive='active';
settingsDataSet.keyWordPassive='passive';  
settingsDataSet.minimumBandwidthFractionForPassiveInclusion=0.75;
settingsDataSet.forceUnit='mN';
settingsDataSet.lengthUnit='mm';
settingsDataSet.timeUnit='ms';    
settingsDataSet.normalizationSegment=1; 

%
% Create/load the dataset
%
if(flag_createDataSet==1)
  dataSet = createImpedanceLengthDataSet600A(...
                          experimentList,...
                          segmentSeries,...
                          categories,...
                          projectFolders,...
                          settingsDataSet);
  save(fullfile(projectFolders.output600A_structs,...
        'impedance_length_relation_larb',...
        'dataSet_impedanceLengthRelationLarb.mat'),'dataSet');

else
  tmp=load(fullfile(projectFolders.output600A_structs,...
        'impedance_length_relation_larb',...
        'dataSet_impedanceLengthRelationLarb.mat'));
  dataSet=tmp.dataSet;
end


%
% Create the main results plots and tables
%
if(flag_makeResultsPlotsTables==1)
  settingsZLvsFL.individualTrialNumber=[4];
  settingsZLvsFL.flag_0Presentation_1Publication=1;
  success=createZLvsFLPlotTable600A(...
                    dataSet,...
                    segmentSeries,...
                    categories,...
                    projectFolders,...
                    settingsZLvsFL);
end

