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

%Requires 17 minutes on a ThinkPad laptop with
% -Intel(R) Core(TM) i7-1165G7 @ 2.80GHz, 
% -32 GiB ram, 
% -SSD hard-drive, 
% -Ubuntu 22.04
flag_processAllData                         = 1; 

%Requires 1-2 minutes
flag_analysePlotImpedanceLengthRelationData = 1;

%Requires 1-2 minutes
flag_plotSupportingMaterial                 = 1;

checkSha256Sum = 0; %Only set this to 1 if you are using Linux and have sha256sum installed

%%
% This is the function that does the first phase in processing,
% transforming 
%
%  - experimental measurements of length and force (*.dat files)
%  - into a file contains both time-domain and frequency-domain data (*.json)
%  - and also into plots that show time-domain and frequency domain data
%    from every segment of every trial
%
% 
%
% 1. processImpedanceSet: 
%     Calibrates and computes the frequency response of each fibre
%  For example:
%    Input: data/600A/20251118_impedance_larb_1/
%             Meta-data: *.json
%             Data     : data/*.dat
%    Output: output/600A/json/20251118_impedance_larb_1/
%             Analysis data in analysis_ImpedanceLengthArb_ ... .json
%             One for each file
%
%    This is currently applied to the following experiments:
% 
%         '20251118_impedance_larb_1'
%         '20251118_impedance_larb_2'
%         '20251120_impedance_larb_3'
%         '20251121_impedance_larb_4'
%         '20251121_impedance_larb_5'
%         '20251128_impedance_larb_6'
%         '20251203_impedance_larb_7'
%
% 2. processDegradationSet
%     Processes the trials that are a part of the degradation study.
%     This reads and writes similar data as in processImpedanceSet. This
%     is currently applied to the following files
%
%     '20251114_degradation_larb_1'
%     '20251119_degradation_larb_2'
%     '20251121_degradation_larb_3'
%     '20251121_degradation_larb_4'
%
% 3. processCalibrationSpring
%
%     Where processImpedanceSet and processDegradationSet use a
%     calibration model (with coefficients defined in 
%     aurora600A_impedance/getImpedanceAnalysisSettings600A) this processes
%     the spring data, calculates the phase-delay for the spring, and then
%     identifies the -3dB frequency of a inverse-low-passfilter to correct
%     the remaining phase delay. The results are written to a json file
%     stored in output/600A/json/
%
%     This is currently applied to the best spring calibration measurement
%     that we made just before our Aurora 1410A underwent maintence. This
%     calibration is the one that we used for our impedance measurements:
%
%     '20260116_impedance_larb_spring'
%
%%

if(flag_processAllData==1)
  % The function can only process 1 dataset at a time. So here goes:  
  settings00CalcImpedance.processImpedanceSet         =0;
  settings00CalcImpedance.processDegradationSet       =0;
  settings00CalcImpedance.processCalibrationSpring    =1;
  settings00CalcImpedance.processCalibrationFixedFiber=0;
  settings00CalcImpedance.checkSha256Sum              = checkSha256Sum;
  success = study_00_calcImpedance600A(settings00CalcImpedance,projectFolders);
  
  settings00CalcImpedance.processImpedanceSet         =0;
  settings00CalcImpedance.processDegradationSet       =0;
  settings00CalcImpedance.processCalibrationSpring    =0;
  settings00CalcImpedance.processCalibrationFixedFiber=1;
  settings00CalcImpedance.checkSha256Sum              = checkSha256Sum;  
  success = study_00_calcImpedance600A(settings00CalcImpedance,projectFolders);
  
  settings00CalcImpedance.processImpedanceSet         =0;
  settings00CalcImpedance.processDegradationSet       =1;
  settings00CalcImpedance.processCalibrationSpring    =0;
  settings00CalcImpedance.processCalibrationFixedFiber=0;
  settings00CalcImpedance.checkSha256Sum              = checkSha256Sum;  
  success = study_00_calcImpedance600A(settings00CalcImpedance,projectFolders);
  
  settings00CalcImpedance.processImpedanceSet         =1;
  settings00CalcImpedance.processDegradationSet       =0;
  settings00CalcImpedance.processCalibrationSpring    =0;
  settings00CalcImpedance.processCalibrationFixedFiber=0;
  settings00CalcImpedance.checkSha256Sum              = checkSha256Sum;  
  success = study_00_calcImpedance600A(settings00CalcImpedance,projectFolders);
end

%%
% This function will read in data from
%
%         '20251118_impedance_larb_1'
%         '20251118_impedance_larb_2'
%         '20251120_impedance_larb_3'
%         '20251121_impedance_larb_4'
%         '20251121_impedance_larb_5'
%         '20251128_impedance_larb_6'
%         '20251203_impedance_larb_7'
%
% And will use it to generate the 4 figures and 2 tables that appear
% in the accompanying paper. These plots and tables are stored in:
%
%   output/600A/plots/impedance_length_relation_larb
%   output/600A/tables/impedance_length_relation_larb
%
% -Table (tbl_zl_fl.tex): correlations between 
%   - the norm. storage-length and force-length relation
%   - the norm. loss-length and force-length relation
% -Table (tbl_zl_fl.tex): distance between 
%   - the norm. storage-length and force-length relation
%   - the norm. loss-length and force-length relation
%   At lengths of 0.55 and 1.45 Lo measured in units of the median of 
%   absolute difference
%
% - Figure (fig_flz_pub.pdf): Box-whisker plots comparing 
%   - the norm. storage-length and force-length relation
%   - the norm. loss-length and force-length relation
%   For each of the 4 perturbations tested. Only one pair of these
%   plots (90 Hz, 0.002) shows up in the paper
%
% - Figure (fig_flzComparison_pub.pdf): Box-whisker plot comparing 
%   - the norm. storage-length relation from each of the 4 perturbations
%   - the norm. loss-length relation from each of the 4 perturbations
%
% - Figure  (fig_zM_pub.pdf):
%           Plot showing the storage and loss normalization coefficients
%           from every fibre grouped by perturbation type
%
% - Figure (fig_frequencyResponseComparison_pub.pdf): 
%          Plot that compares the storage-frequency response and 
%           loss-frequency response from each perturbation type
%%
if(flag_analysePlotImpedanceLengthRelationData==1)

  settingsAnalysePlot.flag_createDataSet          = 1;
  settingsAnalysePlot.flag_calculateStatistics    = 1;
  settingsAnalysePlot.flag_makeResultsPlotsTables = 1;
  success=study_01_analysePlotImpedanceDataSet600A(settingsAnalysePlot,...
                                               projectFolders);
end

if(flag_plotSupportingMaterial==1)
  %%
  % These functions will generate all of the plots that show up in the
  % methods section of the impedance-length relation paper
  %% 
  
  %  See output/600A/degradation_larb
  success = supp_00_PlotDegradationData600A(projectFolders);  
  
  % See output/600A/20260116_impedance_larb_spring
  success = supp_01_PlotCalibrationData600A(projectFolders);

  %See output/600A/system_identification
  success = supp_02_PlotSystemIdentificationIntroduction600A(projectFolders);
  success = supp_03_PlotPerturbationOverview600A(projectFolders);
  success = supp_04_PlotSystemIdentificationMethodsOverview600A(projectFolders);
  
end