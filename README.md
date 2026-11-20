# Description

This repository contains the data and Matlab scripts that accompany the paper:

Millard M, Weidner S, Siebert T, Tomalka A. The variation of impedance with sarcomere length in mammalian muscle fibres. Royal Socieity Philosophical Transactions B. (under review)


# Quick Start: 

This quick start guide will guide you through the data and scripts that come with this repository. In addition, there are a final set of instructions to guide you through re-running the processing of the results and generation of the figures and tables that appear in the publication.

## Running the analysis

While you do not have to run the analysis (this zip file comes with both the input and output data), you can run the analysis and generate all of the plots and tables in the paper if you would like to. Here's how:

  - Start Matlab
  - Change to folder *study_impedanceLengthRelationMuscleFibre600A*
  - Run main_study_impedanceLengthRelationMuscleFibre600A.m
    - Processing all of the data requires 17 minutes on a fairly modern laptop
    - Once the data is processed, it is only a few minutes to generate all of the tables and plots


## Data overview

There are data from three diffent types of experiments in AuroraAnalysisToolkit/data/600A

  - <b>Degradation data</b>
    - 20251114_degradation_larb_1
    - 20251119_degradation_larb_2
    - 20251121_degradation_larb_3
    - 20251121_degradation_larb_4    
  - <b>Calibration data</b>
    - 20260116_impedance_larb_spring
    - 20260930_impedance_calibration_rigor_fixation  
  - <b>Impedance-length data</b>
    - 20251118_impedance_larb_1
    - 20251118_impedance_larb_2
    - 20251120_impedance_larb_3
    - 20251121_impedance_larb_4
    - 20251121_impedance_larb_5
    - 20251128_impedance_larb_6
    - 20251203_impedance_larb_7

The data in each folder have the same layout. Using 20251118_impedance_larb_1 as an example

  - <b>Experiment meta-data file</b>
    - Has the same name as the folder : 20251118_impedance_larb_1/20251118_impedance_larb_1.json
    - Field description
      - *measurements*: a list of all of the trials measured in the experiment
      - *experiment*: data about the experiment and specimen
      - *solutions*: a description of all of the solutions used in the experiment 
        - Note: 20260930_impedance_calibration_rigor_fixation is missing the solution fields
      - *funding*: information about the granting agency and project number
      - *ethics*: information about the ethics board and approval number
  - <b>Trial meta-data file</b>
    - Has the same name as the data file, protocol file,
      -  <b>meta-data </b>: 20251118_impedance_larb_1/larb_01_passive_055Lo_20251118.json
      -  <b>data </b>: 20251118_impedance_larb_1/data/larb_01_passive_055Lo_20251118.dat
      -  <b>protocol </b>: 20251118_impedance_larb_1/protocols/larb_01_passive_055Lo_20251118
    - Field description
      -  <b>data</b>: contains the local path to the data file and its sha256
      -  <b>protocol</b>: contains the local path to the protocol file
      - <b>segments</b>: contains meta-data for each time-segment of interest in the data. At a minimum each segment has the following fields
        - *type* : a name that usually matches the command
        - *time_ms* : the start and end time of this block of commands
        - *is_recorded* : whether or not the data was actually recorded (we make use of the data-enable and data-disable commands to reduce the size of the .dat files)
        - *meta_data* : meta-data related to this segment. This can be empty or quite full of data as in the case of a perturbation
        - *experiment* : contains keywords to help automatically classify the trial type as well as a title to help with plotting
    - <b>data</b> folder
      - Contains the raw data file produced by the Aurora 1410A used in this experiment
    - <b>protocols</b> folder
      - Contains the protocol files used to run the Aurora 1410A used in this experiment
    - <b>segmentLabels</b> folder
      - Contains an older format for the segment-meta data. This can be safely ignored
    - <b>wave</b> folder
      - Contains the wave files that are used in the protocols. These wave files contain the perturbation waveform.
    - <b>waveMetadata</b> folder
      - Contains an older format for the wave meta-data. This can be safely ignored


## Script overview

To get a quick overview of the code used in the processing of the impedance-length relation data, see the following folders and files

  - <b>study_impedanceLengthRelationMuscleFibre600A</b>
    - *main_study_impedanceLengthRelationMuscleFibre600A*: runs everything
    - *study_00_calcImpedance600A.m*: reads in the experimental data and writes frequency-response data to json files
    - *study_01_analysePlotImpedanceDataSet600A.m* : reads in the experimental data and frequency-response data and writes a large table suitable for statistical processing. Also produces all of the results plots
    - *supp_00_PlotDegradationData600A.m* : produces the degradation plot that appear in the methods section
    - *supp_01_PlotCalibrationData600A.m* : produces the calibration plot that appears in the methods section
    - *supp_02_PlotSystemIdentificationIntroduction600A.m* : produces the introductory system-identification figure in the methods section
    - *supp_03_PlotPerturbationOverview600A.m* : produces the perturbation signal plot that apperas in the methods
    - *supp_04_PlotSystemIdentificationMethodsOverview600A.m* : produces the plot that gives an overview of the system identification process 
  
  - <b>aurora600A</b>  
    - All of the common functions that might be used in a fibre experiment that uses the Aurora 600A DAQ system are in this folder. Some highlights include
      -*readAuroraData600A.m* : reads in a .dat file produced by the Aurora 600A into a struct
      -*verifyDataIntegrityCompletnessOrder600A.m* 
  - <b>aurora600A_impedance</b>
    - There are a lot of files in this folder, which cannot all be described. However there are a few of particular interest
    - *runPipelineAnalyzeArbitraryWaveformFiberData600A_03_json.m* : this is the processing pipeline that is used to process all of the raw data to extract the frequency response of each segment    
    - *verifyDataIntegrityCompletnessOrder.m* : this function will evaluate the sha256 value of a data file (linux-only) and will compare it to the one stored in the meta-data file to ensure that the data has not changed
    - *calcPhaseDelayOfElasticMedium.m*: this is the function used to evaluate the phase-delay of the specific specimen (muscle fibre/spring/nitrile fibre). Note that we never ended up using the nitrile fibre as a calibration material because it has too much viscosity
    - *createImpedanceLengthDataSet600A.m* : Creates the table that contains all of the processed data. This is the table that is used for the subsequent statistical analysis and the plots
    - *calcImpedanceLengthStatistics600A.m* : Evaluates the various correlations and m-scores used in the paper
  - <b>common</b>
    - *evaluateGainPhaseCoherenceSq.m* : is the function that reads in time-domain data x(t) and y(t) and evaluates $X(\omega)$, $Y(\omega)$, $\phi_{XY}(\omega)$, $H(\omega)$ and the quantities derived from $H(\omega)$.
  - <b>postprocessing</b>
    - This probably should only contain generic generally useful functions, but now includes some plotting functions specific to this study. Of the generic functions, these would probably be useful to others:
      - *plotConfigAdvanced.m*
      - *configPlotExporter.m*
      - *getPaulTolColourScheme.m*






      




