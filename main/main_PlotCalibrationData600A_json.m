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

flag_0Presentation_1Publication = 1;

flag_createDataSet = 0;

flag_makeCalibrationPlots               = 1;
flag_makeFrequencyResponsePlots         = 0;
flag_makeForceLengthImpedancePlots      = 0;
flag_makeImpedanceModelPlots            = 0;
flag_makeImpedanceLengthArbSinusoidPlots= 0;

flag_savePlot=1;

if(flag_makeCalibrationPlots==1)
  calibrationExperiment = {'20260116_impedance_larb_spring'};
  calibrationTrials = {...
    'analysis_Passive_06_spring_020mN_100Lo_20260116_air.json',...
    'analysis_Passive_06_spring_020mN_100Lo_20260116_h2o.json'};
    
  for i=1:1:length(calibrationTrials)
    figCal = figure;
    figCal = plotCalibrationData600A(figCal,...
                                     calibrationExperiment, ...
                                     calibrationTrials{i},...
                                     projectFolders,...
                                     flag_0Presentation_1Publication,...
                                     flag_savePlot);
    close(figCal);
  end
end
