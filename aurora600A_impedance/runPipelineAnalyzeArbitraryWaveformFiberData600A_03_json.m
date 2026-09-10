function success = ...
  runPipelineAnalyzeArbitraryWaveformFiberData600A_03_json(...
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


setOfTrialTypes = {'delay','degradation','impedance',...
                   'impedance temperature','impedance calibration',...
                   'impedance calibration rigor fixation'};
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





%% 
% Delay model
%
%   There are two sources of delay:
%   1. The longitudinal wave takes time to propagate down the fiber to 
%    the sensor.
%   2. The sensor has a bandwidth of 800 Hz (from Aurora) and the little
%    wire hooks that we use apparently reduce this bandwidth further.
%    For the purpose of simplicity I'm going to model this assuming that
%    it behaves like a low-pass filter
%
% 1. Propagation delay
% - spring: from CE Mungan
%
%      v = L sqrt(k/m)
%      L: length
%      k: stiffness
%      m: mass
%
% - fiber: Each frequency has its own specific delay described 
%     in Pritz 1981 as
%       
%       v  = ve sqrt(2) D / sqrt(D+1)
%       ve = L sqrt(k/m)
%       D  = sqrt(1+ne^2)
%       ne = E''/E'
%
%     : A more detailed derivation from Google Gemini has something a bit
%     different, and unlike Pritz, I can follow all of the steps of the
%     the Gemini derivation. It's quite possible that the two are
%     equivalent. 
%
%
%%
modelSettings.daqDelayModel             = settings.daqDelayModel;
modelSettings.zeroPhaseResponseSlope    = 1;
modelSettings.useManuallySetDaqDelay    = settings.useManuallySetDaqDelay;
modelSettings.coherenceSquaredThreshold = settings.coherenceSquaredThreshold;


%%
% folders
%%
dataFolder      = fullfile(projectFolders.data600A,folderName);
experimentStr   = fileread(fullfile(dataFolder,[folderName,'.json']));
experimentJson  = jsondecode(experimentStr);

fidLogFile = fopen(fullfile(dataFolder,...
  'log_runPipelineAnalyzeArbitraryWaveformFiberData600A_01_json.txt'),'w');

currentDateTime  = datestr(now, 'dd/mm/yy-HH:MM:SS');

fprintf(fidLogFile,'%s\n',currentDateTime);
fprintf('%s\n',currentDateTime);

indexSegmentLarb = 1;
%%
% Default setting
%%
setOfTrialsDefault = [1:1:length(experimentJson.measurements)];
setOfTrialsVerified =[];

%%
% Plot settings
%%
lineColors = getPaulTolColourSchemes('bright');





%%
% Scan through the meta data 
% - check the sha256 value
% - count the total number of segments to plot. 
%%

   
setOfTrialsVerified=verifyDataIntegrityCompletnessOrder600A(...
                      dataFolder,experimentJson,fidLogFile,...
                      settings.checkFileOrder,settings.checkSha256Sum);


totalNumberOfSegmentsToPlot = 0;
fprintf('%s\n','Preprocessing: ');
fprintf('%s\n','  Counting the number of segments to plot');
fprintf(fidLogFile,'%s\n','Preprocessing: ');
fprintf(fidLogFile,'%s\n','  Counting the number of segments to plot');

for indexSetOfTrials=1:1:length(setOfTrialsVerified)

  i = setOfTrialsVerified(indexSetOfTrials);

  %%
  % Read in the meta data
  %%  
  %fprintf('\t%s\n',experimentJson.measurements{i});
  trialStr = fileread(fullfile(dataFolder,experimentJson.measurements{i}));
  if(exist('trialJson','var'))
    clear('trialJson');
  end
  trialJson = jsondecode(trialStr);


  %%
  % Count the number of segments to plot and check if wave files exist
  %%
  setOfSegments=[];
  numSegmentsToPlot = 0;
  for j=1:1:length(trialJson.segments)
    if(strcmp(trialJson.segments(j).type,keyword.label) ...
        || strcmp(trialJson.segments(j).type,keyword.controlFunction) )
      %assert(idxSeg==0,['Error: multiple segments have the name ',...
      %          keyword.label]);
      if(isempty(setOfSegments)==1)
        setOfSegments = j;
      else
        setOfSegments = [setOfSegments;j];
      end      
    end
    if(strcmp(trialJson.segments(j).type,'Larb-Stochastic') ...
        || strcmp(trialJson.segments(j).type,keyword.controlFunction) )
      waveFile = '';
      fileField = '';
      if(isfield(trialJson.segments(j).meta_data,'file'))
        fileField='file';
      end
      if(isfield(trialJson.segments(j).meta_data,'file_name'))
        fileField='file_name';        
      end
      

      for k=1:1:length(trialJson.segments(j).meta_data.(fileField))
        if(k==1)
          waveFile = trialJson.segments(j).meta_data.(fileField){k};
        else
          waveFile = [waveFile,filesep,...
                trialJson.segments(j).meta_data.(fileField){k}];
        end
      end
      waveFilePath = fullfile(dataFolder, waveFile);
      if( ~exist(waveFilePath,'file'))
        fprintf('%s\n','  Error: wave file not found: ');
        fprintf('%s\n',['  ', waveFilePath]);
        fprintf(fidLogFile,'%s\n','  Error: wave file not found: ');
        fprintf(fidLogFile,'%s\n',['  ', waveFilePath]);
      end

    end
  end  

  if(isempty(setOfSegments))
    fprintf(fidLogFile,'%s\n', ...
        ['Error: could not find segment with ',keyword.label]);
  end

  assert(~isempty(setOfSegments),...
      ['Error: could not find segment with ',keyword.label]);
  if(length(setOfSegments) > totalNumberOfSegmentsToPlot)
    totalNumberOfSegmentsToPlot = length(setOfSegments);
  end  
end

fprintf('\t%i segments found\n',totalNumberOfSegmentsToPlot);
fprintf(fidLogFile,'\t%i segments found\n',totalNumberOfSegmentsToPlot);



if(settings.processData==1)
  
  setOfTrials = [];
  if(~isempty(setOfTrialsVerified))
    if(~isempty(fileKeyWord))      
      for idxSoT=1:1:length(setOfTrialsVerified)
        i = setOfTrialsVerified(idxSoT);
        disp(experimentJson.measurements{i});
        if(contains(experimentJson.measurements{i},fileKeyWord))
          setOfTrials = [setOfTrials; i];
        end
      end
    else
      setOfTrials = setOfTrialsVerified;
    end
  else
    if(~isempty(fileKeyWord))
      for i=1:1:length(setOfTrialsVerified)
        if(contains(experimentJson.measurements{i},fileKeyWord))
          setOfTrials = [setOfTrials; i];
        end
      end      
    else
      setOfTrials = setOfTrialsDefault;
    end    
  end
  


  %
  % Plot the segment data
  %  
  numberOfHorizontalPlotColumnsGeneric  = length(setOfTrials);
  numberOfVerticalPlotRowsGeneric       = 7*totalNumberOfSegmentsToPlot;
  % 1. Time domain
  % 2. gain
  % 3. phase
  % 4. coherence
  
  plotWidth                 = ones(1,numberOfHorizontalPlotColumnsGeneric).*6;
  plotHeight                = ones(numberOfVerticalPlotRowsGeneric,1).*6;
  plotHorizMarginCm         = 3;
  plotVertMarginCm          = 2;
  baseFontSize              = 12;
  
  [subPlotPanelSegment, pageWidthSegment,pageHeightSegment]= ...
    plotConfigGeneric(  numberOfHorizontalPlotColumnsGeneric,...
              numberOfVerticalPlotRowsGeneric,...
              plotWidth,...
              plotHeight,...
              plotHorizMarginCm,...
              plotVertMarginCm,...
              baseFontSize); 
  
  figSegments = figure;
  
  %
  % Intra-segments
  %
  numberOfHorizontalPlotColumnsGeneric  = 1;
  numberOfVerticalPlotRowsGeneric     = 2;
  
  plotWidth                 = ones(1,numberOfHorizontalPlotColumnsGeneric).*20;
  plotHeight                = ones(numberOfVerticalPlotRowsGeneric,1).*10;
  plotHorizMarginCm             = 3;
  plotVertMarginCm            = 2;
  baseFontSize              = 12;
  
  [subPlotPanelIntraSegment, pageWidthIntraSegment,pageHeightIntraSegment]= ...
    plotConfigGeneric(  numberOfHorizontalPlotColumnsGeneric,...
              numberOfVerticalPlotRowsGeneric,...
              plotWidth,...
              plotHeight,...
              plotHorizMarginCm,...
              plotVertMarginCm,...
              baseFontSize); 
  
  figIntraSegments = figure;

  %
  % Plot the time series domain data
  %
  numberOfHorizontalPlotColumnsGeneric  = 1;
  numberOfVerticalPlotRowsGeneric     = length(setOfTrials);

  
  plotWidth      = ones(1,numberOfHorizontalPlotColumnsGeneric).*25;
  plotHeight     = ones(numberOfVerticalPlotRowsGeneric,1).*10;
  plotHorizMarginCm  = 3;
  plotVertMarginCm   = 2;
  baseFontSize     = 12;
  
  [subPlotPanelTimeSeries, pageWidthTimeSeries,pageHeightTimeSeries]= ...
    plotConfigGeneric(  numberOfHorizontalPlotColumnsGeneric,...
              numberOfVerticalPlotRowsGeneric,...
              plotWidth,...
              plotHeight,...
              plotHorizMarginCm,...
              plotVertMarginCm,...
              baseFontSize); 

  figTimeSeries = figure;

  %%
  % Extract the passive and active bias forces
  %%
  fprintf('%s\n','Extracting the passive and active bias forces');
  fprintf(fidLogFile,'%s\n','Extracting the passive and active bias forces');
  
  biasForce.passive.indexWindow=[];
  biasForce.passive.time  = nan;
  biasForce.passive.force = nan;
  biasForce.active.indexWindow = [];  
  biasForce.active.time   = nan;
  biasForce.active.force  = nan;
  biasForce.active.forceThreshold=nan;
  biasForce.trials=[];
  biasForce.trialIndex=[];  
  biasForce.isActive=[];

  foundBiasTrials=1;
  for indexSetOfTrials = 1:1:length(setOfTrials)
  
    idxTrial = setOfTrials(indexSetOfTrials);

    found=0;
    for indexKeyword =1:1:length(settings.biasForce.keywords)
      if(~isempty(settings.biasForce.keywords{indexKeyword}))
        if(contains(experimentJson.measurements{idxTrial},...
                    settings.biasForce.keywords{indexKeyword}))
          assert(found==0,'Error: 1 bias force keyword has matched to two files');
          found=1;
          biasForce.trials = ...
            [biasForce.trials,experimentJson.measurements(idxTrial)];
          biasForce.isActive= ...
            [biasForce.isActive,settings.biasForce.isActive(indexKeyword)];
          biasForce.trialIndex = ...
            [biasForce.trialIndex,idxTrial];          
        end
      end
    end
    foundBiasTrials=foundBiasTrials & found;
  end
  if(foundBiasTrials==1)
    biasForce=extractBiasForce600A(biasForce,experimentJson,...
                                   dataFolder,settings,fidLogFile);
  else
    fprintf('%s\n','Warning: cound not find passive and active bias files');
    fprintf(fidLogFile,'%s\n','Warning: cound not find passive and active bias files');
  end

  %%
  % Process the gain, phase, coherence squared, and a model fit
  %%
  fprintf('%s\n','Processing: gain, phase, coherence-sq + model fit');
  fprintf(fidLogFile,'%s\n','Processing: gain, phase, coherence-sq + model fit');
  
  for indexSetOfTrials = 1:1:length(setOfTrials)
  
    idxTrial = setOfTrials(indexSetOfTrials);
    isValid=1;    
    %%
    % Read in the meta data
    %%   
    fprintf('\t%s\n',experimentJson.measurements{idxTrial});
    fprintf(fidLogFile,'\t%s\n',experimentJson.measurements{idxTrial});
    
    trialStr = fileread(fullfile(dataFolder,experimentJson.measurements{idxTrial}));
    trialJson = jsondecode(trialStr);
    
  
    %%
    % Add missing fields in the trial json file from the experiments
    % section
    %%
    experimentFields = fields(experimentJson.experiment);
    trialExperimentFields = fields(trialJson.experiment);
    for j=1:1:length(experimentFields)
      if(~isfield(trialJson.experiment,experimentFields{j}))
        trialJson.experiment.(experimentFields{j}) = ...
          experimentJson.experiment.(experimentFields{j});
      end
    end
  
    
  
    %%
    % Fetch the experimental data files
    %%
    fileType = {'data','protocol'};
    filePaths = [{''};{''}];
    for j=1:1:length(fileType)
      if(length(trialJson.(fileType{j}).file)>0)
        filePaths{j} = trialJson.(fileType{j}).file{1};
        if(length(trialJson.(fileType{j}).file)>1)
          for k=2:1:length(trialJson.(fileType{j}).file)
            filePaths{j} = [filePaths{j},filesep,trialJson.(fileType{j}).file{k}];
          end
        end
      end
    end
  
    dataPath = fullfile(dataFolder,filePaths{1});
    protocolPath= fullfile(dataFolder,filePaths{2});
      
    auroraData = readAuroraData600A(dataPath,flag_readHeader);
    
    %%
    % Identify the active interval, if it exists
    %%
    activeIntervals = [];
    for j=1:1:length(auroraData.Test_Protocol.Time.Value)
      isBathFunction = ...
        strcmp(auroraData.Test_Protocol.Control_Function.Value{j},'Bath');
      isActivation = ...
        contains(auroraData.Test_Protocol.Options.Value{j},...
        sprintf('%i ',settings.activationBathNumber));
      isDeactivation = ...
        contains(auroraData.Test_Protocol.Options.Value{j},...
        sprintf('%i ',settings.deactivationBathNumber));
      isPreactivation = ...
        contains(auroraData.Test_Protocol.Options.Value{j},...
        sprintf('%i ',settings.preactivationBathNumber));
      if(isBathFunction==1 && isActivation==1)
        if(isempty(activeIntervals))
          activeIntervals = ...
            [auroraData.Test_Protocol.Time.Value(j,1),nan];
        else
          activeIntervals = ...
            [activeIntervals;...
             auroraData.Test_Protocol.Time.Value(j,1),nan];
        end
      end

      if(isBathFunction && isDeactivation==1)
        activeIntervals(end,2) = auroraData.Test_Protocol.Time.Value(j,1);
      end
    end

    %%
    % Get the perturbation segment intervals
    %%
    setOfSegments=[];
    numSegmentsToPlot = 0;
    for j=1:1:length(trialJson.segments)
      if(strcmp(trialJson.segments(j).type,keyword.label) ...
           ||  strcmp(trialJson.segments(j).type,keyword.controlFunction))
        %assert(idxSeg==0,['Error: multiple segments have the name ',...
        %          keyword.label]);
        if(isempty(setOfSegments)==1)
          setOfSegments = j;
        else
          setOfSegments = [setOfSegments;j];
        end
      end
    end  
  

    if(isempty(setOfSegments))
      isValid=0;    

      fprintf(fidLogFile,'%s\n', ...
          ['Warning: could not find segment with ',keyword.label, ...
           ' in ', experimentJson.measurements{idxTrial}]);
      fprintf('%s\n', ...
          ['Warning: could not find segment with ',keyword.label, ...
           ' in ', experimentJson.measurements{idxTrial}]);

    end  
  
    if(isValid==1)
      %%
      % 
      % 1. Extract the active times that are
      %  between segments. For the first segment, ignore all data that
      %  occurs before the the max (this happens early)
      % 2. Fit lines to these segments. 
      % 3. Save 
      %  a. Data: initial value, final value
      %  b. Line: initial value, final value, slope
      % 4. Evaluate defect between segments: difference between
      %  the new starting value and the expected value from the slope
      %%
      
  
      intraSegmentData(length(setOfSegments)) = ...
        struct('time',[],'model',[],'xyMax',[],...
        'filtered',[],'forceReference',0);
      for j=1:1:length(setOfSegments)
        intraSegmentData(j).filtered.time = [];
        intraSegmentData(j).filtered.length = [];
        intraSegmentData(j).filtered.force = [];
      end
      
      if(~isempty(setOfSegments))
  
        for j=1:1:(length(setOfSegments))
          
          t0              = nan;
          t1              = nan;
          forceReference  = nan;
          fref            = nan;
          
          if(~isempty(activeIntervals) && j==1)
            assert(strcmp(auroraData.Data.Time.Unit,'ms'),...
                 ['Error: Assumed time unit is ms, not ',...
                   auroraData.Data.Time.Unit]);
  
            idSeg=setOfSegments(j,1);
            t0 = activeIntervals(1,1);          
            t1 = trialJson.segments(idSeg).time_ms(1,1);
          
  %           We want to find the first measured force that does
  %           not contain any vibration. This will be our
  %           refernence force for this trial
  %           
            intraSegmentIndex = find( auroraData.Data.Time.Values >= t0 ...
                                    & auroraData.Data.Time.Values <= t1);
  
  
            flagPlotReference=0;
            [forceReference, indexReference] ...
              = identifyActiveFiberReferenceForce600A(...
                  auroraData.Data.Fin.Values(intraSegmentIndex,1), ...
                  settings.forceNoiseThresholdmN,...
                  settings.isometricNoiseFilterCutoffFrequencyHz,...
                  auroraData.Setup_Parameters.A_D_Sampling_Rate.Value,...
                  flagPlotReference);
  
            f0 = forceReference;
            t0 = auroraData.Data.Time.Values(intraSegmentIndex(indexReference));  
          elseif( j > 1)
              idSeg=setOfSegments(j-1,1);
              t0 = trialJson.segments(idSeg).time_ms(2,1);
              idSeg=setOfSegments(j,1);        
              t1 = trialJson.segments(idSeg).time_ms(1,1);
          else
              t0 = nan; 
              t1 = nan;
          end
    
  
          intraSegmentData(j).time=[t0,t1];
          intraSegmentIndex = find( auroraData.Data.Time.Values >= t0 ...
                                  & auroraData.Data.Time.Values <= t1);
  
          
          intraSegmentData(j).filtered.time   = zeros(size(intraSegmentIndex,1),1);
          intraSegmentData(j).filtered.length = zeros(size(intraSegmentIndex,1),1);
          intraSegmentData(j).filtered.force  = zeros(size(intraSegmentIndex,1),1);
  
          intraSegmentData(j).filtered.time = ...
            auroraData.Data.Time.Values(intraSegmentIndex,1);
  
          nyquistFrequency = ...
            auroraData.Setup_Parameters.A_D_Sampling_Rate.Value*0.5;
          cutoffFrequency = settings.isometricNoiseFilterCutoffFrequencyHz;
  
          [b,a]=butter(2,cutoffFrequency/nyquistFrequency);
          intraSegmentData(j).filtered.force =...
            filtfilt(b,a, auroraData.Data.Fin.Values(intraSegmentIndex,1));
          intraSegmentData(j).filtered.length =...
            filtfilt(b,a, auroraData.Data.Lin.Values(intraSegmentIndex,1));
  
          if(isempty(activeIntervals))
            forceReference = mean(intraSegmentData(j).filtered.force);
          end
 

          intraSegmentData(j).forceReference=forceReference;
          here=1;
          
        end
      end
  
      %%
      % Plot the time series data
      %%
      figure(figTimeSeries);
  
      subplot('Position',...
        reshape(subPlotPanelTimeSeries(indexSetOfTrials,1,:),1,4));
  
      yyaxis left;
      plot(auroraData.Data.Time.Values,...
        auroraData.Data.Lin.Values,...
        '-','Color',lineColors.grey);
      hold on;
      xlabel(['Time (',auroraData.Data.Time.Unit,')']);
      ylabel(['Length (',auroraData.Data.Lin.Unit,')']);
  
      yyaxis right;
      plot(auroraData.Data.Time.Values,...
         auroraData.Data.Fin.Values,...
         '-','Color',[0,0,0]);
      hold on;
  
  
      if(~isempty(activeIntervals))
        for j=1:1:length(intraSegmentData)
          n = 0;
          if(length(intraSegmentData)>1)
            n = (j-1)/(length(intraSegmentData)-1);
          end
          
          plot(intraSegmentData(j).filtered.time,...
             intraSegmentData(j).filtered.force,...
             '-','Color',lineColors.cyan);
          hold on;
  
          text(intraSegmentData(j).filtered.time(1),...
             intraSegmentData(j).filtered.force(1),...
             sprintf('%1.3e = yMax', ...
               intraSegmentData(j).forceReference),...
               'HorizontalAlignment','right',...
               'VerticalAlignment','top',...
               'FontSize',8,...
               'Rotation',45);
          hold on;
  
        end
      end
  
      ylabel(['Force (',auroraData.Data.Fin.Unit,')']);
      titleStr = strrep(experimentJson.measurements{idxTrial},'_','\_');        
      title(titleStr);
      axis tight;
      box off;
  
      %%
      % Plot the intra segments, if this is a degredation trial
      %%
      if(strcmp(trialType,'degradation'))
        figure(figIntraSegments);
        subplot('Position',...
          reshape(subPlotPanelIntraSegment(1,1,:),1,4));
        colorA = [0,0,0];
        colorB = [0,0,1];
  
        n=0;
        if(length(setOfTrials)>1)
          n = (indexSetOfTrials-1)/(length(setOfTrials)-1);
        end
        lineColor = colorA.*(n-1) + colorB.*n;  
       
        for j=1:1:length(intraSegmentData)        
          plot(intraSegmentData(j).filtered.time,...
             intraSegmentData(j).filtered.force,...
             '-','Color',lineColor);
          hold on;  
          if(j==1)
            plot(intraSegmentData(j).filtered.time(end),...
               intraSegmentData(j).filtered.force(end),...
               '.','Color',lineColor);
            hold on;            
          end
        end
        text(intraSegmentData(end).filtered.time(end),...
           intraSegmentData(end).filtered.force(end),...
           sprintf('%i',indexSetOfTrials),...
           'HorizontalAlignment','left',...
           'FontSize',6);
        hold on      
        box off;
        xlabel(['Time (',auroraData.Data.Time.Unit,')']);
        ylabel(['Force (',auroraData.Data.Fin.Unit,')']); 
        %titleStr = strrep(folderName,'_','\_'); 
        title('Isometric intra-segment force');
  
        subplot('Position',...
          reshape(subPlotPanelIntraSegment(2,1,:),1,4));
        plot(indexSetOfTrials,intraSegmentData(1).filtered.force(end),...
           'o','Color',lineColor,'MarkerFaceColor',lineColor);
        hold on;
        forceReference = intraSegmentData(1).forceReference; 
        plot(indexSetOfTrials,...
          (intraSegmentData(1).filtered.force(end)-forceReference),...
           'x','Color',[1,0,0],'MarkerFaceColor',[1,0,0]);
        hold on;
        box off;
        xlabel(['Trial Number']);
        ylabel(['Force (',auroraData.Data.Fin.Unit,')']); 
        title('Force prior to first perturbation');
        
      end
  
  
    
      %%
      % Process each of the segments
      %%
    
    
      for indexIntoSetOfSegments = 1:1:length(setOfSegments)
      
        idxSeg = setOfSegments(indexIntoSetOfSegments,1);
    
        %%
        %Extract the indicies to plot
        %%
        timeStart = trialJson.segments(idxSeg).time_ms(1);
        timeEnd   = trialJson.segments(idxSeg).time_ms(2);
        dataIndex = find( auroraData.Data.Time.Values >= timeStart ...
                & auroraData.Data.Time.Values <= timeEnd); 
        preTimeStart = timeStart-settings.prePerburationWindowMs;
        preTimeEnd   = timeStart;
        preDataIndex = [];
  
        if(preTimeEnd > 0)
          preDataIndex = find( auroraData.Data.Time.Values >= preTimeStart ...
                  & auroraData.Data.Time.Values <= preTimeEnd); 
        end
        
        %%
        %Find the wave number
        %%
        %idxWave = trialJson.waveform.id;
        segmentType=trialJson.segments(idxSeg).type;
    
        if(strcmp('Larb-Stochastic',segmentType)==0 ...
             && strcmp('Length-Arb',segmentType)==0)
          fprintf(fidLogFile,'%s\n',...
            ['Error: expected Larb-Stochastic or Length-Arb at segment ',num2str(idxSeg)]);
        end
        assert(strcmp('Larb-Stochastic',segmentType) ...
            || strcmp('Length-Arb',segmentType),...
            ['Error: expected Larb-Stochastic or Length-Arb at segment ',...
              num2str(idxSeg)]);
  
        bandwidth = trialJson.segments(idxSeg).meta_data.bandwidth_Hz';
        if(length(bandwidth)==1)
          bandwidth=[0,bandwidth];
        end
        amplitude = trialJson.segments(idxSeg).meta_data.amplitude_Lo;
        
        if(isempty(bandwidth))
          fprintf(fidLogFile,'%s\n',...
            ['Error: could not find larb-segment property bandwidth']);
        end
        assert(isempty(bandwidth)==0,...
          'Error: could not find larb-segment property bandwidth');
    
        if(isempty(amplitude))
          fprintf(fidLogFile,'%s\n',...
            ['Error: could not find larb-segment property amplitude']);
        end
        assert(isempty(amplitude)==0,...
          'Error: could not find larb-segment property amplitude');
       
        %%
        % Evaluate frequency response   
        %%
        x = auroraData.Data.Lin.Values(dataIndex,1);
        xMean = mean(x);
        x = x - xMean;
      
        y = auroraData.Data.Fin.Values(dataIndex,1);


        bathName = '';
        if(isfield(trialJson.segments(idxSeg).meta_data,'is_active'))
          if(trialJson.segments(idxSeg).meta_data.is_active == 1)
            bathName='active';
          else 
            bathName='passive';
          end
        elseif(isfield(trialJson.segments(idxSeg).meta_data,'bath'))
          bathName=trialJson.segments(idxSeg).meta_data.bath;
        else
          assert(0,['Error: expected meta_data to contain either is_active',...
                    ' or bath fields']);
        end

        yBias=0;        
        switch bathName
          case 'active'
            if(~isnan(biasForce.active.force))
              yBias = biasForce.active.force;
            end
          case 'passive'
            if(~isnan(biasForce.passive.force))
              yBias = biasForce.passive.force;
            end
        end
        y=y-yBias;
        
        yMean = mean(y);
        y = y-yMean;
        
        xPre=[];
        yPre=[];
        timePre=[];
        if(~isempty(preDataIndex))
          timePre = auroraData.Data.Time.Values(preDataIndex,1);
          xPre = auroraData.Data.Lin.Values(preDataIndex,1);
          yPre = auroraData.Data.Fin.Values(preDataIndex,1);
        end
        xyDataIsValid =0;
  
  
  
  
    
        if(length(y)>10 && length(x)>10)
          xyDataIsValid=1;
    
          sampleFrequency = auroraData.Setup_Parameters.A_D_Sampling_Rate.Value;
          assert(strcmp(auroraData.Setup_Parameters.A_D_Sampling_Rate.Unit,'Hz'),...
               'Error: A_D_Sampling_Rate should be in Hz');
        
          samples   = length(x);
          timeVec   = [0:(1/(samples-1)):1]' .* (samples/sampleFrequency);
        
          segData.x      = x;
          segData.y      = y;
          segData.yBias  = yBias;
          segData.xMean  = xMean;
          segData.yMean  = yMean;        
          
          segData.timePrior=timePre;
          segData.xPrior = xPre;
          segData.yPrior = yPre;
  
          segData.time=timeVec;
          segData.bandwidth_Hz = bandwidth;
          segData.sampleFrequency = sampleFrequency;
  
          %[freqHz, gain, phase,coherenceSq] = ...
          segData.H0 = evaluateGainPhaseCoherenceSq(...
                          timeVec,...
                          x,...
                          y,...
                          bandwidth,...
                          sampleFrequency,...
                          settings.coherenceSquaredThreshold,...
                          settings.minAcceptableBandwidthFraction);
  
        end
      
  
  
        %%
        % Fit a first order low pass model to the response
        %%
      
        if(xyDataIsValid==1)
  
          delayModel.phaseDelayElasticRod=0;
          delayModel.daqDelay    = settings.daqDelay; %in seconds
          delayModel.daqFilterFrequencyHz = settings.daqFilterFrequencyHz;
          delayModel.daqDelayModel   = settings.daqDelayModel;
           
  
          %%
          % Compensate for the propagation delay
          %
          %
          % Compensating for the delay changes the gain
          % and thus the estimated stiffness of the spring. 
          % Here we iterate over candidate delays until
          % the difference between subsequent delays is small
          %
          % This delay is also present in a muscle fiber, but it is
          % so small (2.27 e-5 s) that it does not really affect the 
          % phase in our bandwidth of 0-90 Hz: at 90 Hz one period is
          % 11 ms, and the biggest delay incurred by the
          % viscoelascity of the fiber is 0.0227 ms which amounts to
          % 0.11 degrees.
          %
          % Note, however, that there are publications in the
          % literature that examine the frequency response of fibers
          % upto 40 kHz. At such high frequencies these delays would 
          % be noticeable: at 40,000 Hz one period is 0.025 ms, and
          % the transmission delay would amount to 52 degrees
          %
          % De Winkel ME, Blangé T, Treijtel BW. The complex Young's 
          % modulus of skeletal muscle fibre segments in the high 
          % frequency range determined from tension transients. 
          % Journal of Muscle Research & Cell Motility. 1993 
          % Jun;14(3):302-10.
          %%
  
          
          H = segData.H0;
          delayError = inf;
          delayP = 0;
          delay = 0;
          iter=1;
  
          while delayError > settings.phaseDelayTolerance ...
              && iter < settings.phaseDelayMaxIteration ...
              && ~isnan(delay)
  
            idxFit =find(H.frequencyHz >= segData.bandwidth_Hz(1,1)...
                   & H.frequencyHz <= segData.bandwidth_Hz(1,2));
  
            delay = calcPhaseDelayOfThinElasticRod(...
                        H.frequencyHz(idxFit),...
                        H.gain(idxFit),...
                        H.phase(idxFit),...
                        auroraData.Data.Lin.Values(dataIndex,1),...
                        experimentJson,...
                        mm2m);
  
            if(~isnan(delay))
              timeDelayedVec  = segData.time + delay;
              y01    = interp1( segData.time, ...
                                segData.y,...
                                timeDelayedVec,...
                                'linear','extrap');
              
              H = evaluateGainPhaseCoherenceSq(  ...
                      timeDelayedVec,...
                      segData.x,...
                      y01,...
                      segData.bandwidth_Hz,...
                      segData.sampleFrequency,...
                      settings.coherenceSquaredThreshold,...
                      settings.minAcceptableBandwidthFraction);
    
              if(iter > 1)
                delayError = abs(delay-delayP);
              end
              delayP = delay;
            end
            iter=iter+1;
          end
          if(iter > settings.phaseDelayMaxIteration)
            fprintf(['  Warning: delay tolerance not met\n',...
                 '  %1.2e > %1.2e\t error\n',...
                 '  %i \t iterations'],...
                 delayError, ...
                 settings.phaseDelayTolerance,...
                 settings.phaseDelayMaxIteration);
          end      
  
          if(strcmp(experimentJson.experiment.material,'stainless steel'))    
            segData.H1=H;
            delayModel.phaseDelayCompensated=1;
          else
            %%
            % For now, I'm not compensating for any of the delay
            % that is present in the fiber for two reasons:
            %
            % 1. Between 0-90 Hz the delay is negligible. It is 
            %  negligible for the fiber but not the spring because
            %  the fiber is ~1/100th the mass of the spring.
            %
            % 2. The delay varies with frequency. To correctly 
            %  capture this delay you need to have an accurate
            %  model of the frequency response of the fiber,
            %  which I currently do not have: a Kelvin-Voigt
            %  model captures the gain, but not the phase correctly
            %
            %  A muscle fiber is viscoelastic, and the damping causes
            %  the higher frequency waves to travel faster. To
            %  correctly compensate for this dispersion, you need an
            %  accurate model of the frequency response of the fiber, 
            %  which I currently do not have.
            %%
            segData.H1=segData.H0;
            delayModel.phaseDelayCompensated=0;
          end
  
          delayModel.phaseDelayElasticRod = delay;
          
          %%
          % Compensate for delay introduced by the low-pass-filter
          %                 
          % Identify the filter frequency:
          %
          % Fit the delay to the phase response by fitting an 
          % inverse-low-pass filter until the phase response of
          % the spring is flat.
          %%
          if(modelSettings.useManuallySetDaqDelay==0 ...
              && strcmp(modelSettings.daqDelayModel,'frequency-domain'))
            
            expResponse = evaluateGainPhaseCoherenceSq(  ...
                            segData.H1.time,...
                            segData.H1.x,...
                            segData.H1.y,...
                            segData.bandwidth_Hz,...
                            segData.sampleFrequency,...
                            settings.coherenceSquaredThreshold,...
                            settings.minAcceptableBandwidthFraction);  
            
            fittingResults = ...
              calcLowPassFilterFrequencyToZeroPhaseResponseSlope(...
                delayModel.daqFilterFrequencyHz,...
                expResponse,...
                delayModel.daqFilterFrequencyHz*0.5,...
                expResponse.bandwidthHzC2,...
                100,...
                0);  
  
            delayModel.daqFilterFrequencyHz = ...
                fittingResults.filterFrequencyHz;
  
          end
          if(modelSettings.useManuallySetDaqDelay==1 ...
              && strcmp(modelSettings.daqDelayModel,'frequency-domain'))
            delayModel.daqFilterFrequencyHz = settings.daqFilterFrequencyHz;
          end
  
          %
          % Compensate for the filtering effect of the DAQ
          %
          n = length(segData.H1.x);
          omega = delayModel.daqFilterFrequencyHz*2*pi;
          frequencyHz = [0:(1/(n)): (1-(1/n)) ]'...
                          .* (sampleFrequency);
          frequency=frequencyHz.*(2*pi);
          lpfInv = ((omega + complex(0,1).*frequency)./omega);
          yUpd = ifft(lpfInv.*fft(segData.H1.y),...
              'symmetric');
          
          segData.H2 = evaluateGainPhaseCoherenceSq(  ...
                          segData.H1.time,...
                          segData.H1.x,...
                          yUpd,...
                          segData.bandwidth_Hz,...
                          segData.sampleFrequency,...
                          settings.coherenceSquaredThreshold,...
                          settings.minAcceptableBandwidthFraction);
  
          delayModel.daqDelayCompensated=1;
          
          %%
          % If this is an impedance-temperature study, then try to remove
          % any variation in the low frequency mean. This sometimes happens
          % because fibers at the higher temperature do not maintain a
          % stable force for long.
          %%
          if(strcmp(trialType,'impedance temperature'))
            wn = settings.impedanceTemperatureBaseLineFilterHz ...
                 / (0.5*segData.sampleFrequency);
            [b,a] = butter(2,wn,'low');
            yBase0 = filtfilt(b,a,segData.H2.y);
            yFlat = segData.H2.y-yBase0;
            yBase1= filtfilt(b,a,yFlat);
            segData.H3 = evaluateGainPhaseCoherenceSq(  ...
                          segData.H2.time,...
                          segData.H2.x,...
                          yFlat,...
                          segData.bandwidth_Hz,...
                          segData.sampleFrequency,...
                          settings.coherenceSquaredThreshold,...
                          settings.minAcceptableBandwidthFraction); 
            flag_debugH3=0;
            if(flag_debugH3==1)
              figDebugFlat = figure;
              subplot(1,4,1);
                plot(segData.H2.time,segData.H2.y,'-','Color',[1,1,1].*0.75);
                hold on;
                plot(segData.H2.time,yFlat,'-','Color',[1,1,1].*0.25);            
                hold on;
                plot(segData.H2.time,yBase0,'-','Color',[0,0,1]);            
                hold on;
                plot(segData.H2.time,yBase1,'-','Color',[1,0,0]);            
                hold on;
                xlabel('Time (ms)');
                ylabel('Force (mN)');
              subplot(1,4,2);
                plot(segData.H2.frequencyHz(segData.H2.idxBW),...
                     segData.H2.gain(segData.H2.idxBW),...
                     '-','Color',[1,1,1].*0.5);
                hold on;
                plot(segData.H3.frequencyHz(segData.H3.idxBW),...
                     segData.H3.gain(segData.H3.idxBW),...
                     '-','Color',[0,0,0]);
                hold on;
                xlabel('Frequency (Hz)');
                ylabel('Gain (mN/mm)');
              subplot(1,4,3);
                plot(segData.H2.frequencyHz(segData.H2.idxBW),...
                     segData.H2.phase(segData.H2.idxBW).*(180/pi),...
                     '-','Color',[1,1,1].*0.5);
                hold on;
                plot(segData.H3.frequencyHz(segData.H3.idxBW),...
                     segData.H3.phase(segData.H3.idxBW).*(180/pi),...
                     '-','Color',[0,0,0]);
                hold on;
                xlabel('Frequency (Hz)');
                ylabel('Phase (degrees)');
              subplot(1,4,4);
                plot(segData.H2.frequencyHz(segData.H2.idxBW),...
                     segData.H2.coherenceSq(segData.H2.idxBW),...
                     '-','Color',[1,1,1].*0.5);
                hold on;
                plot(segData.H3.frequencyHz(segData.H3.idxBW),...
                     segData.H3.coherenceSq(segData.H3.idxBW),...
                     '-','Color',[0,0,0]);
                hold on;
                xlabel('Frequency (Hz)');
                ylabel('Coherence Sq');
            end
  
          end
        
          switch trialType
            case 'delay'
              segData.H = segData.H2;
            case 'degradation'
              segData.H = segData.H2;
            case 'impedance'
              segData.H = segData.H2;
            case 'impedance temperature'
              segData.H = segData.H3;
            case 'impedance calibration'
              segData.H = segData.H2;
            case 'impedance calibration rigor fixation'
              segData.H = segData.H2;              
            otherwise
              assert(0,'Error: invalid trialType');
          end
  
  
          %%
          % Fit the impedance model(s)
          %%
        
          lsqnonlinOptions =...
            optimoptions('lsqnonlin','MaxFunctionEvaluations',2000,...
                         'MaxIterations',2000,...
                         'Display','none');
  
          optSettings.objScaling = [1,1]; %gain and phase error
          
          if(~isempty(segData.H.idxBWC2))
            modelSeriesToFit = [];
            fittedModelSeries = modelSeries;
  
            for idxMdl = 1:1:length(modelSeries)
  
              assert(strcmp(modelSeries(idxMdl).model.abbreviation,'K3'),...
                     'Error: expecting a Kawai 3-state model');
  
              isModelSpecimenTypeValid = 0;
              isModelTrialTypeValid  = 0;
              isModelActivityTypeValid = 0;
  
              for idxT = 1:1:length(modelSeries(idxMdl).model.specimenTypes)
                if(strcmp(modelSeries(idxMdl).model.specimenTypes{idxT},specimenType))
                  isModelSpecimenTypeValid=1;
                end
              end
              for idxT = 1:1:length(modelSeries(idxMdl).model.trialTypes)
                if(strcmp(modelSeries(idxMdl).model.trialTypes{idxT},trialType))
                  isModelTrialTypeValid=1;
                end
              end
  
              if(strcmp(specimenType,setOfSpecimenTypes{2}))
                for idxT=1:1:length(modelSeries(idxMdl).model.activityTypes)
                  switch modelSeries(idxMdl).model.activityTypes{idxT}
                  case 'active'
                    if(strcmp(bathName,'active'))
                      isModelActivityTypeValid=1;
                    end
                  case 'passive'
                    if(strcmp(bathName,'passive'))
                      isModelActivityTypeValid=1;
                    end
                  case 'rigor'
                    if(strcmp(bathName,'rigor'))
                      isModelActivityTypeValid=0;
                      assert(0,['Error: the model should not be fit to a',...
                         ' fiber in the rigor bath. ']);                      
                    end
                  case 'Karnovsky'
                    if(strcmp(bathName,'Karnovsky'))
                      isModelActivityTypeValid=0;
                      assert(0,['Error: the model should not be fit to a',...
                         ' fiber in the Karnovsky bath. ']);
                    end
                  otherwise
                    assert(0,['Error: modelSeries(idxMdl).activityTypes{idxT}.',...
                          ' entry is invalid. ']);
                  end
                end
              else
                isModelActivityTypeValid=1;
              end
  
              if(isModelSpecimenTypeValid ...
                  && isModelTrialTypeValid ...
                  && isModelActivityTypeValid)
                modelSeriesToFit = [modelSeriesToFit;idxMdl];
              else
                fittedModelSeries(idxMdl).model = [];
              end
            end
  
            for idxMdlFit = 1:1:length(modelSeriesToFit)
  
              idxMdl = modelSeriesToFit(idxMdlFit,1);
              assert(strcmp(modelSeries(idxMdl).model.abbreviation,'K3'),...
                     'Error: expecting a Kawai 3-state model');
  
  
              if(trialJson.segments(idxSeg).meta_data.is_active==1)
                ttype='active';
              else
                ttype='passive';              
              end
  
              x0 = zeros(size(modelSeries(idxMdl).model.settings.(ttype).parameterMap,1),1);
              
              for i=1:1:length(x0)              
                  row   = modelSeries(idxMdl).model.settings.(ttype).parameterMap(i,1);
                  col   = modelSeries(idxMdl).model.settings.(ttype).parameterMap(i,3);
      
                  assert(col > 1, ['Error: the first column in ',...
                          'model.settings.parameterMap is reserved',...
                          ' for the branch number']);                
                  x0(i,1) = modelSeries(idxMdl).model.(ttype).parameters(row,col);
              end
  
              % Using an adapted version of the fitting method from
              % Kawai & Brandt 1980
              %
              % Kawai M, Brandt PW. Sinusoidal analysis: a high resolution 
              % method for correlating biochemical reactions with 
              % physiological processes in activated skeletal muscles of 
              % rabbit, frog and crayfish. Journal of Muscle Research & 
              % Cell Motility. 1980 Sep;1(3):279-303.
              %
              %
              
              %Get the first local maximum in the loss modulus
              foundLocalMax=0;
              idx=2;
              idxMax=max(segData.H.idxBW);
              while(foundLocalMax==0 && idx < idxMax)
                dL = segData.H.loss(idx)-segData.H.loss(idx-1);
                dR = segData.H.loss(idx+1)-segData.H.loss(idx);
                if(dL > 0 && dL*dR<0)
                  foundLocalMax=1;
                else
                  idx=idx+1;
                end
              end
              alpha = segData.H.frequency(idx);
              
              [minLoss,idxMin] = min(segData.H.loss(segData.H.idxBW(idx:end)));
              beta = segData.H.frequency(segData.H.idxBW(idx+idxMin-1));
  
              [maxLoss,idxMax] = max(segData.H.loss(segData.H.idxBW(idxMin:end)));
              gamma = segData.H.frequency(segData.H.idxBW(idxMin+idxMax-1));
  
              defaultFrequencies.active=[alpha;beta;gamma];
              defaultFrequencies.passive=[alpha;gamma];
  
              idxFrequency=1;
              for i=1:1:length(x0)
                  if(modelSeries(idxMdl).model.settings.(ttype).parameterMap(i,3) ...
                      == modelSeries(idxMdl).model.settings.(ttype).elementTypes.frequency)
                    
                      x0(i)=defaultFrequencies.(ttype)(idxFrequency);
                      idxFrequency=idxFrequency+1;
                  end
              end
  
              %
              % Amplitudes and frequencies are fitted separately. Break
              % out separate settings for each
              %
  
              idxAmplitude = ...
                modelSeries(idxMdl).model.settings.(ttype).parameterMapAmplitude;
              idxFrequency = ...
                modelSeries(idxMdl).model.settings.(ttype).parameterMapFrequency;              
  
  
              settingsAmplitude = modelSeries(idxMdl).model.settings.(ttype);
  
              settingsAmplitude.parameterMap = ...
                settingsAmplitude.parameterMap(idxAmplitude,:);
              settingsAmplitude.parameterBounds = ...
                settingsAmplitude.parameterBounds(idxAmplitude,:);
  
              settingsFrequency = modelSeries(idxMdl).model.settings.(ttype);
              settingsFrequency.parameterMap = ...
                settingsFrequency.parameterMap(idxFrequency,:);
              settingsFrequency.parameterBounds = ...
                settingsFrequency.parameterBounds(idxFrequency,:);
  
              x0Amplitude=x0(idxAmplitude);
              x0Frequency=x0(idxFrequency);
  
              for idxF=1:1:length(x0Frequency)
                if(idxF ==1 )
                  lb = 0;
                  ub = x0Frequency(idxF) ...
                    + (1/3)*(x0Frequency(idxF+1)-x0Frequency(idxF));
                  settingsFrequency.parameterBounds(idxF,:)=[lb,ub];
                elseif(idxF == length(x0Frequency))
                  lb = x0Frequency(idxF) ...
                    - (1/3)*(x0Frequency(idxF)-x0Frequency(idxF-1));                
                  ub = x0Frequency(idxF)*1.5;
                  settingsFrequency.parameterBounds(idxF,:)=[lb,ub];              
                else
                  lb = x0Frequency(idxF) ...
                    - (1/3)*(x0Frequency(idxF)-x0Frequency(idxF-1));  
                  ub = x0Frequency(idxF) ...
                    + (1/3)*(x0Frequency(idxF+1)-x0Frequency(idxF));
                  settingsFrequency.parameterBounds(idxF,:)=[lb,ub];              
  
                end
              end
  
              xFinal=x0;
              %
              % Fit amplitude and frequency separately
              %
              settingsAmplitude.applyParameterMap=1;
              settingsFrequency.applyParameterMap=1;
              modelSeries(idxMdl).model.settings.(ttype).applyParameterMap=1;
  
              flag_debugFitting=0;
              if(flag_debugFitting==1)
                figFitting=figure;
                subplot(1,3,1);
                plot(segData.H.frequency(segData.H.idxBWC2),...
                     segData.H.storage(segData.H.idxBWC2),...
                     '-','Color',[1,1,1].*0.5);
                hold on;
                xlabel('Frequency');
                ylabel('Storage Modulus (mN/mm)');
                subplot(1,3,2);
                plot(segData.H.frequency(segData.H.idxBWC2),...
                     segData.H.loss(segData.H.idxBWC2),...
                     '-','Color',[1,1,1].*0.5);
                hold on;
                xlabel('Frequency');
                ylabel('Loss Modulus');
                subplot(1,3,3);
                xlabel('Iteration');
                ylabel('Res. Norm.');
                
              end
  
              xPrevious=xFinal;
              xRelErrorMax = 1;
              iterOptLoop=1;
              while xRelErrorMax > 0.005 && iterOptLoop < 100
                n = (iterOptLoop-1)/99;
                seriesColor = [0,0,1].*(1-n) + [1,0,0].*n;
                for idxType=1:1:2
                  
                  switch idxType
                    case 1
                      errFcn = @(argX)calcErrorOfImpedanceModel600A(...
                                argX, ...
                                settingsAmplitude, ...                  
                                segData.H,...
                                optSettings);
                      errVec = errFcn(x0Amplitude);
                      lb = settingsAmplitude.parameterBounds(:,1);
                      ub = settingsAmplitude.parameterBounds(:,2);
                      xStart=x0Amplitude;
  
                      n=length(errVec);
                      errStorage = errVec(1:1:(n/2));
                      errLoss = errVec(((n/2)+1):1:n);
                      optSettings.objScaling = [1,1];%...
  %                      [1/sqrt(mean(errStorage.^2)) 1/sqrt(mean(errStorage.^2))];  
  
                      errFcn = @(argX)calcErrorOfImpedanceModel600A(...
                                argX, ...
                                settingsAmplitude, ...                  
                                segData.H,...
                                optSettings);
                    case 2 
                      errFcn = @(argX)calcErrorOfImpedanceModel600A(...
                                argX, ...
                                settingsFrequency, ...                  
                                segData.H,...
                                optSettings);                  
                      errVec = errFcn(x0Frequency);
                      lb = settingsFrequency.parameterBounds(:,1);
                      ub = settingsFrequency.parameterBounds(:,2);
                      xStart=x0Frequency;
  
                      n=length(errVec);
                      errStorage = errVec(1:1:(n/2));
                      errLoss= errVec(((n/2)+1):1:n);
                      optSettings.objScaling = [1,1];...
                       % [1/sqrt(mean(errStorage.^2)) 1/sqrt(mean(errStorage.^2))];
  
                      errFcn = @(argX)calcErrorOfImpedanceModel600A(...
                                argX, ...
                                settingsFrequency, ...                  
                                segData.H,...
                                optSettings);                     
                    otherwise
                      assert(0,'Error: unrecognized fitting type');
                  end
        
  
        
                  [xFit, resnorm, residual,exitflag,output] = ...
                    lsqnonlin(errFcn,xStart,lb,ub,lsqnonlinOptions);
                  
    
    
                  switch idxType
                    case 1
                      [componentImpedanceParams, modelParams] = ...
                        getMaxwellKelvinVoigtNetworkParameters(xFit,...
                          settingsAmplitude);                  
                      x0Amplitude=xFit;
                      xFinal(idxAmplitude)=xFit;
                      modelResponse = ...
                        calcMaxwellKelvinVoigtNetworkImpedance(...
                            segData.H.frequency(segData.H.idxBWC2),...
                            xFinal,...
                            modelSeries(idxMdl).model.settings.(ttype));
                    case 2 
                      [componentImpedanceParams, modelParams] = ...
                        getMaxwellKelvinVoigtNetworkParameters(xFit,...
                          settingsFrequency);   
                      x0Frequency=xFit;                    
                      xFinal(idxFrequency)=xFit;
                      modelResponse = ...
                        calcMaxwellKelvinVoigtNetworkImpedance(...
                            segData.H.frequency(segData.H.idxBWC2),...
                            xFinal,...
                            modelSeries(idxMdl).model.settings.(ttype));
                    otherwise
                      assert(0,'Error: unrecognized fitting type');
                  end              
                  settingsAmplitude.defaultParameters=modelParams;
                  settingsFrequency.defaultParameters=modelParams; 
  
                  if(flag_debugFitting)
                    figure(figFitting);
                    subplot(1,3,1);
                    plot(modelResponse.frequency,...
                         modelResponse.storage,...
                         '-','Color',seriesColor);
                    hold on;
    
                    subplot(1,3,2);
                    plot(modelResponse.frequency,...
                         modelResponse.loss,...
                         '-','Color',seriesColor);
                    hold on;
    
                    subplot(1,3,3);
                    plot(iterOptLoop,resnorm,'x');
                    hold on;                                  
                  end
  
  
                end
  
                xDelta=xPrevious-xFinal;
                xRelError = abs(xDelta)./max(abs(xFinal), ones(size(xFinal)));
                xRelErrorMax=max(xRelError);
                xPrevious=xFinal;
                iterOptLoop=iterOptLoop+1;
  
              end
  
              
              %
              % Evaluate the fitted model response
              %
   
              fittedModelSeries(idxMdl).model.componentImpedance ...
                = componentImpedanceParams;
  
              fittedModelSeries(idxMdl).model.parameters ...
                = modelParams;
              
              fittedModelSeries(idxMdl).model.response ...
                = calcMaxwellKelvinVoigtNetworkImpedance(...
                    segData.H.frequency(segData.H.idxBWC2),...
                    xFinal,...
                    modelSeries(idxMdl).model.settings.(ttype));
    
              idxBWC2 = segData.H.idxBWC2;
                
              fittedModelSeries(idxMdl).model.rmse.gain =...
                sqrt( mean( ...
                (fittedModelSeries(idxMdl).model.response.gain ...
                 -segData.H.gain(idxBWC2)).^2 ));
              fittedModelSeries(idxMdl).model.rmse.phase = ...
                sqrt( mean( ...
                (fittedModelSeries(idxMdl).model.response.phase ...
                -segData.H.phase(idxBWC2)).^2 ));
              fittedModelSeries(idxMdl).model.rmse.storage = ...
                sqrt( mean(... 
                (fittedModelSeries(idxMdl).model.response.storage ...
                -segData.H.storage(idxBWC2)).^2 ));
              fittedModelSeries(idxMdl).model.rmse.loss = ...
                sqrt( mean( ...
                (fittedModelSeries(idxMdl).model.response.loss ...
                -segData.H.loss(idxBWC2)).^2 ));
               
            end
          end
        
          %disp('*** Future: update the viscoelastic rod model ***');
          %
          % Check the transmission delays
          %
          %   2026/2/19: Commenting this out for now. Muscle fibers
          %        behave more like a Maxwell element in series
          %        with a Kelvin-Voigt element. The frequency 
          %        dependent delay times below are estimated only
          %        for a Kelvin-Voigt rod which is the wrong model.
          %
          % kelvinVoigtRodModel = [];
          % if(strcmp(experimentJson.experiment.material,'muscle'))
          %     
          %   if(~isempty(experimentJson.experiment.width_mm) ...
          %       && ~isempty(experimentJson.experiment.height_mm) ...
          %       && ~isempty(experimentJson.experiment.rho_kg_m3))
          %   
          %     k_Nm    = modelParams.k;
          %     beta_Nms  = modelParams.beta;
          %     length_MM   = mean(auroraData.Data.Lin.Values(dataIndex,1));
          %     length_M  = length_MM*mm2m;
          %     area_MM2  = (pi/4)*experimentJson.experiment.width_mm ...
          %               *experimentJson.experiment.height_mm;
          %     area_M2   = area_MM2*mm2m*mm2m;
          %     rho_kgm3  = experimentJson.experiment.rho_kg_m3;
          %     flag_plot   = 0;
          %     kelvinVoigtRodModel = ...
          %       evaluateDelayModelThinKelvinVoigtRod(...
          %             k_Nm,beta_Nms,length_M,area_M2,...
          %             rho_kgm3,segData.H.frequency,...
          %             flag_plot);
          %     
          %   end
          % end
          %%
          % Evaluate errors
          %%
  
      
        end
        %%
        % Record the analysis to a segment json file
        %%
        lengthSummary = ...
          getSummaryStatistics(auroraData.Data.Lin.Values(dataIndex,1));
        forceSummary = ...
          getSummaryStatistics(auroraData.Data.Fin.Values(dataIndex,1));
        if(experimentJson.experiment.temperature_control)
          temperatureSummary = ...
          getSummaryStatistics(auroraData.Data.Aux1_C.Values(dataIndex,1));
        else
          temp = experimentJson.experiment.temperature_C;       
          temperatureSummary.percentiles.x=[];
          temperatureSummary.percentiles.y=[];
          temperatureSummary.mean = temp;
          temperatureSummary.median=temp;
          temperatureSummary.std = 0;
          temperatureSummary.min = temp;
          temperatureSummary.max = temp;
        end
    
        segmentJson.interval= [timeStart,timeEnd];
        segmentJson.index   = idxSeg;
        segmentJson.type  = trialJson.segments(idxSeg).type; 
  
        segmentJson.time  = auroraData.Data.Time.Values(dataIndex,1);
        segmentJson.length  = auroraData.Data.Lin.Values(dataIndex,1);
        segmentJson.force   = auroraData.Data.Fin.Values(dataIndex,1);  
        segmentJson.lengthMean  = segData.xMean;
        segmentJson.forceMean   = segData.yMean;
        segmentJson.forceBias   = segData.yBias;      
        segmentJson.nominal.time    = segData.timePrior;
        segmentJson.nominal.length  = segData.xPrior;
        segmentJson.nominal.force   = segData.yPrior;
        
        segmentJson.forceReference = nan;
  
        if(~isempty(activeIntervals))
          segmentJson.forceReference = ...
            intraSegmentData(indexIntoSetOfSegments).forceReference;          
          segmentJson.pre.filterFrequencyHz=settings.isometricNoiseFilterCutoffFrequencyHz;
          segmentJson.pre.fitlerType = 'Dual-pass 2nd order Butterworth low-pass filter';
          segmentJson.pre.time_ms= intraSegmentData(indexIntoSetOfSegments).time;
          segmentJson.pre.time  = intraSegmentData(indexIntoSetOfSegments).filtered.time;
          segmentJson.pre.length  = intraSegmentData(indexIntoSetOfSegments).filtered.length;
          segmentJson.pre.force   = intraSegmentData(indexIntoSetOfSegments).filtered.force;        
        end
  
        segmentJson.summary.length    = lengthSummary;
        segmentJson.summary.force     = forceSummary;
        segmentJson.summary.temperature = temperatureSummary;
        segmentJson.unit.length     = auroraData.Data.Lin.Unit;
        segmentJson.unit.force      = auroraData.Data.Fin.Unit;
        segmentJson.unit.temperature  = 'C';
        segmentJson.unit.time         = auroraData.Data.Time.Unit;
        segmentJson.channel.length    = 'Lin';
        segmentJson.channel.force     = 'Fin';
        segmentJson.channel.temperature = 'Aux 1';
    
        scaleTime = 1;
        if(strcmp(auroraData.Data.Time.Unit,'ms'))
          scaleTime=1000;
        end
      
    
        hStages = {'H','H0','H1','H2','H3'};
  
        for idxH = 1:1:length(hStages)
          hStr = hStages{idxH};
  
          if(isfield(segData,hStr))
            idxBW = segData.(hStr).idxBW;
            
            responseFields = fields(segData.(hStr));
            idxBW = segData.(hStr).idxBW;
            fieldsToSkip ={'H'};
            fieldsToBWLimit = ...
              {'frequencyHz','frequency','gain','phase',...
               'storage','loss','coherenceSq'};
            for idxF = 1:1:length(responseFields)
              fStr = responseFields{idxF};
              flag_skip = 0;
              for idxS = 1:1:length(fieldsToSkip)
                if(strcmp(responseFields{idxF},fieldsToSkip{idxS}))
                  flag_skip=1;
                end
              end
              
              flag_bwlimit=0;
              for idxL = 1:1:length(fieldsToBWLimit)
                if(strcmp(responseFields{idxF},fieldsToBWLimit{idxL}))
                  flag_bwlimit=1;
                end
              end
    
              if(flag_skip==0)
                if(flag_bwlimit==0)
                  segmentJson.(hStr).(fStr)=segData.(hStr).(fStr);
                else
                  segmentJson.(hStr).(fStr)=segData.(hStr).(fStr)(idxBW);
                end
              end
    
            end
            %
            % There is no way to encode complex numbers, so we must
            % cut H out.
            %
    %         segmentJson.(hStr) = segData.(hStr);         
    %         segmentJson.(hStr).H = [];
    
            
            segmentJson.(hStr).summary.gain = ...
              getSummaryStatistics(segData.(hStr).gain(idxBW));      
            segmentJson.(hStr).summary.phase = ...
              getSummaryStatistics(segData.(hStr).phase(idxBW));
            segmentJson.(hStr).summary.storage = ...
              getSummaryStatistics(segData.(hStr).storage(idxBW));      
            segmentJson.(hStr).summary.loss = ...
              getSummaryStatistics(segData.(hStr).loss(idxBW));
            segmentJson.(hStr).summary.coherenceSq = ...
              getSummaryStatistics(segData.(hStr).coherenceSq(idxBW));
    
            segmentJson.(hStr).units.gain = ...
              [auroraData.Data.Fin.Unit,'/',auroraData.Data.Lin.Unit];
            segmentJson.(hStr).units.phase = 'radians';
            segmentJson.(hStr).units.storage = ...
              [auroraData.Data.Fin.Unit,'/',auroraData.Data.Lin.Unit];
            segmentJson.(hStr).units.loss = ...
              [auroraData.Data.Fin.Unit,'s/',auroraData.Data.Lin.Unit];
            segmentJson.(hStr).units.coherenceSq = '';
          end
        end
  
    
        segmentJson.delayModel.settings = modelSettings;
        segmentJson.delayModel.phaseDelayElasticRod  ...
                = delayModel.phaseDelayElasticRod;
  
        segmentJson.delayModel.phaseDelayCompensated ...
          = delayModel.phaseDelayCompensated;
        segmentJson.delayModel.daqDelayModel ...
          = delayModel.daqDelayModel;
        segmentJson.delayModel.daqDelay    ...
          = delayModel.daqDelay;
        segmentJson.delayModel.daqFilterFrequencyHz ...
          = delayModel.daqFilterFrequencyHz;
        segmentJson.delayModel.daqDelayCompensated ...
          = delayModel.daqDelayCompensated;
  
        if(~isempty(segData.H.idxBWC2))
          for idxMdl = 1:1:length(fittedModelSeries)
    
            abb = modelSeries(idxMdl).model.abbreviation;
  
            if(~isempty(fittedModelSeries(idxMdl).model))
              
      
              segmentJson.model.(abb) = ...
                fittedModelSeries(idxMdl).model;
      
              %
              % There is no standard way to encode complex numbers,
              % and so, we must set H to be empty.
              %
              segmentJson.model.(abb).response.H = [];
      
            else
              segmentJson.model.(abb) = [];
            end
          end
        end
            
  
        %%
        % Plot time-length-force  
        %%
        figure(figSegments);
      
        idxRow = (indexIntoSetOfSegments-1)*7 + 1;
        subplot('Position',reshape(...
          subPlotPanelSegment(idxRow,indexSetOfTrials,:),1,4));    
        yyaxis left;
     
        plot(auroraData.Data.Time.Values(dataIndex,1),...
           auroraData.Data.Lin.Values(dataIndex,1),...
           '-','Color',lineColors.grey);...
        hold on;
  
        box off;  
        xlabel(sprintf('Time (%s)',auroraData.Data.Time.Unit));
        ylabel(sprintf('Length (%s)',auroraData.Data.Lin.Unit));
      
        yyaxis right;
     
        plot(auroraData.Data.Time.Values(dataIndex,1),...
           auroraData.Data.Fin.Values(dataIndex,1),...
           '-','Color',[0,0,0]);...
        hold on;
  
        box off;  
        ylabel(sprintf('Force (%s)',auroraData.Data.Fin.Unit));
        
        titleStrA = trialJson.experiment.title;
        titleStrB = sprintf('%i Hz, %1.3f Lo',bandwidth(1,2),amplitude);    
        titleId   = sprintf('(%i,%i). ',idxRow,indexSetOfTrials);    
        title([titleId, titleStrA,':', titleStrB]);
      
        %%
        % Plot the gain response 
        %%  
        if(xyDataIsValid==1)
          idxRow = (indexIntoSetOfSegments-1)*7 + 2;
          subplot('Position',reshape(...
            subPlotPanelSegment(idxRow,indexSetOfTrials,:),1,4)); 
  
  
          plot(segData.H0.frequencyHz(segData.H0.idxBW),...
             segData.H0.gain(segData.H0.idxBW),...
            '-','Color',settings.colorData0);
          hold on;
          plot(segData.H1.frequencyHz(segData.H1.idxBW),...
             segData.H1.gain(segData.H1.idxBW),...
            '-','Color',settings.colorData1);
          hold on;
          plot(segData.H2.frequencyHz(segData.H2.idxBW),...
            segData.H2.gain(segData.H2.idxBW),...
            '-','Color',settings.colorData2);
          hold on;
          if(isfield(segData,'H3'))
            plot(segData.H3.frequencyHz(segData.H3.idxBW),...
              segData.H3.gain(segData.H3.idxBW),...
              '-','Color',settings.colorData3);
            hold on;
          end
            
          if(~isempty(segData.H.idxBWC2))
            for idxMdl=1:1:length(fittedModelSeries)  
              if(~isempty(fittedModelSeries(idxMdl).model))
                plot(fittedModelSeries(idxMdl).model.response.frequencyHz,...
                   fittedModelSeries(idxMdl).model.response.gain,...
                   fittedModelSeries(idxMdl).model.lineType,...
                   'Color', fittedModelSeries(idxMdl).model.color);
                hold on;  
              end
            end
            for j=1:1:2
              plot([segData.H.bandwidthHzC2(j);...
                    segData.H.bandwidthHzC2(j)],...
                   [min(segData.H.gain(segData.H.idxBW)),...
                    max(segData.H.gain(segData.H.idxBW))],...
                   '-','Color',lineColors.grey);
              hold on;
            end
          end
          box off;  
          xlabel('Frequency (Hz)');
          ylabel(sprintf('Gain (%s/%s)',...
              auroraData.Data.Fin.Unit,auroraData.Data.Lin.Unit));
          titleId = sprintf('(%i,%i). ',idxRow,indexSetOfTrials);
          title(titleId);
        end
      
        %%
        % Plot the phase response 
        %%      
        if(xyDataIsValid==1)   
  
          idxRow = (indexIntoSetOfSegments-1)*7 + 3;
          subplot('Position',reshape(...
            subPlotPanelSegment(idxRow,indexSetOfTrials,:),1,4));
  
          plot(segData.H0.frequencyHz(segData.H0.idxBW),...
             segData.H0.phase(segData.H0.idxBW).*(180/pi),...
             '-','Color',settings.colorData0);
          hold on;
          plot(segData.H1.frequencyHz(segData.H1.idxBW),...
             segData.H1.phase(segData.H1.idxBW).*(180/pi),...
             '-','Color',settings.colorData1);
          hold on;
          plot(segData.H2.frequencyHz(segData.H.idxBW),...
               segData.H2.phase(segData.H.idxBW).*(180/pi),...
               '-','Color',settings.colorData2);
          hold on;
          if(isfield(segData,'H3'))
            plot(segData.H3.frequencyHz(segData.H3.idxBW),...
                 segData.H3.phase(segData.H3.idxBW).*(180/pi),...
                 '-','Color',settings.colorData3);
            hold on;
          end
  
          if(~isempty(segData.H.idxBWC2))          
            for idxMdl=1:1:length(fittedModelSeries)
              if(~isempty(fittedModelSeries(idxMdl).model))
                plot(fittedModelSeries(idxMdl).model.response.frequencyHz,...
                   fittedModelSeries(idxMdl).model.response.phase.*(180/pi),...
                   fittedModelSeries(idxMdl).model.lineType,...
                   'Color', fittedModelSeries(idxMdl).model.color);
                hold on;  
              end
            end
            for j=1:1:2
              plot([segData.H.bandwidthHzC2(j);...
                  segData.H.bandwidthHzC2(j)],...
                 [0,45],...
                 '-','Color',lineColors.grey);
              hold on;
            end
          end
          
          
          
          box off;  
          xlabel('Frequency (Hz)');
          ylabel('Phase ($$^o$$)');
      
          titleId = sprintf('(%i,%i). ',idxRow,indexSetOfTrials);
          title(titleId);
        end
        %%
        % Plot storage vs frequency
        %%      
        if(xyDataIsValid==1)   
  
          idxRow = (indexIntoSetOfSegments-1)*7 + 4;
          subplot('Position',reshape(...
            subPlotPanelSegment(idxRow,indexSetOfTrials,:),1,4));
  
          plot(segData.H0.frequencyHz(segData.H0.idxBW),...
             segData.H0.storage(segData.H0.idxBW),...
             '-','Color',settings.colorData0);
          hold on;
          plot(segData.H1.frequencyHz(segData.H1.idxBW),...
             segData.H1.storage(segData.H1.idxBW),...
             '-','Color',settings.colorData1);
          hold on;
          plot(segData.H2.frequencyHz(segData.H.idxBW),...
               segData.H2.storage(segData.H.idxBW),...
               '-','Color',settings.colorData2);
          hold on;
          if(isfield(segData,'H3'))
            plot(segData.H3.frequencyHz(segData.H3.idxBW),...
                 segData.H3.storage(segData.H3.idxBW),...
                 '-','Color',settings.colorData3);
            hold on;
          end
  
          if(~isempty(segData.H.idxBWC2))          
            for idxMdl=1:1:length(fittedModelSeries)
              if(~isempty(fittedModelSeries(idxMdl).model))
                plot(fittedModelSeries(idxMdl).model.response.frequencyHz,...
                   fittedModelSeries(idxMdl).model.response.storage,...
                   fittedModelSeries(idxMdl).model.lineType,...
                   'Color', fittedModelSeries(idxMdl).model.color);
                hold on;  
              end
            end
            for j=1:1:2
              plot([segData.H.bandwidthHzC2(j);...
                  segData.H.bandwidthHzC2(j)],...
                 [0,10],...
                 '-','Color',lineColors.grey);
              hold on;
            end
          end
                         
          box off;  
          xlabel('Frequency (Hz)');
          ylabel(sprintf('Storage (%s/%s)',...
              auroraData.Data.Fin.Unit,auroraData.Data.Lin.Unit));    
          titleId = sprintf('(%i,%i). ',idxRow,indexSetOfTrials);
          title(titleId);
        end
        
        %%
        % Plot storage vs frequency
        %%      
        if(xyDataIsValid==1)   
  
          idxRow = (indexIntoSetOfSegments-1)*7 + 5;
          subplot('Position',reshape(...
            subPlotPanelSegment(idxRow,indexSetOfTrials,:),1,4));
  
          plot(segData.H0.frequencyHz(segData.H0.idxBW),...
             segData.H0.loss(segData.H0.idxBW),...
             '-','Color',settings.colorData0);
          hold on;
          plot(segData.H1.frequencyHz(segData.H1.idxBW),...
             segData.H1.loss(segData.H1.idxBW),...
             '-','Color',settings.colorData1);
          hold on;
          plot(segData.H2.frequencyHz(segData.H.idxBW),...
               segData.H2.loss(segData.H.idxBW),...
               '-','Color',settings.colorData2);
          hold on;
          if(isfield(segData,'H3'))
            plot(segData.H3.frequencyHz(segData.H3.idxBW),...
                 segData.H3.loss(segData.H3.idxBW),...
                 '-','Color',settings.colorData3);
            hold on;
          end
  
          if(~isempty(segData.H.idxBWC2))          
            for idxMdl=1:1:length(fittedModelSeries)
              if(~isempty(fittedModelSeries(idxMdl).model))
                plot(fittedModelSeries(idxMdl).model.response.frequencyHz,...
                   fittedModelSeries(idxMdl).model.response.loss,...
                   fittedModelSeries(idxMdl).model.lineType,...
                   'Color', fittedModelSeries(idxMdl).model.color);
                hold on;  
              end
            end
            for j=1:1:2
              plot([segData.H.bandwidthHzC2(j);...
                  segData.H.bandwidthHzC2(j)],...
                 [0,10],...
                 '-','Color',lineColors.grey);
              hold on;
            end
          end
          
          
          
          box off;  
          xlabel('Frequency (Hz)');
          ylabel(sprintf('Loss (%s/(%s/%s))',...
              auroraData.Data.Fin.Unit,auroraData.Data.Lin.Unit,'s'));    
          titleId = sprintf('(%i,%i). ',idxRow,indexSetOfTrials);
          title(titleId);
        end
        %%
        % Plot storage vs loss
        %%      
        if(xyDataIsValid==1)   
  
          idxRow = (indexIntoSetOfSegments-1)*7 + 6;
          subplot('Position',reshape(...
            subPlotPanelSegment(idxRow,indexSetOfTrials,:),1,4));
  
          plot(segData.H0.storage(segData.H0.idxBW),...
             segData.H0.loss(segData.H0.idxBW),...
             '-','Color',settings.colorData0);
          hold on;
          plot(segData.H1.storage(segData.H1.idxBW),...
             segData.H1.loss(segData.H1.idxBW),...
             '-','Color',settings.colorData1);
          hold on;
          plot(segData.H2.storage(segData.H.idxBW),...
               segData.H2.loss(segData.H.idxBW),...
               '-','Color',settings.colorData2);
          hold on;
          if(isfield(segData,'H3'))
            plot(segData.H3.storage(segData.H3.idxBW),...
                 segData.H3.loss(segData.H3.idxBW),...
                 '-','Color',settings.colorData3);
            hold on;
          end
  
          if(~isempty(segData.H.idxBWC2))          
            for idxMdl=1:1:length(fittedModelSeries)
              if(~isempty(fittedModelSeries(idxMdl).model))
                plot(fittedModelSeries(idxMdl).model.response.storage,...
                   fittedModelSeries(idxMdl).model.response.loss,...
                   fittedModelSeries(idxMdl).model.lineType,...
                   'Color', fittedModelSeries(idxMdl).model.color);
                hold on;  
              end
            end
          end
          
          
          
          box off;  
          xlabel('Storage (mm/mN)');
          ylabel('Loss (mN/(mm/s))');
      
          titleId = sprintf('(%i,%i). ',idxRow,indexSetOfTrials);
          title(titleId);
        end
  
        %%
        % Plot the coherence-sq response 
        %%      
        if(xyDataIsValid==1)
          idxRow = (indexIntoSetOfSegments-1)*7 + 7;
          subplot('Position',reshape(...
            subPlotPanelSegment(idxRow,indexSetOfTrials,:),1,4));
  
          plot(segData.H0.frequencyHz(segData.H0.idxBW),...
            segData.H0.coherenceSq(segData.H0.idxBW),...
            '-','Color',settings.colorData0);
          hold on;
          plot(segData.H1.frequencyHz(segData.H1.idxBW),...
            segData.H1.coherenceSq(segData.H1.idxBW),...
            '-','Color',settings.colorData1);
          hold on;
          plot(segData.H2.frequencyHz(segData.H2.idxBW),...
            segData.H2.coherenceSq(segData.H2.idxBW),...
            '-','Color',settings.colorData2);
          hold on;
  
          if(~isempty(segData.H.idxBWC2))                    
            for j=1:1:2
              plot([segData.H.bandwidthHzC2(j);...
                  segData.H.bandwidthHzC2(j)],...
                 [min(segData.H.coherenceSq(segData.H.idxBW)),...
                  max(segData.H.coherenceSq(segData.H.idxBW))],...
                 '-','Color',lineColors.grey);
              hold on;
            end
          end
  
          box off;  
          xlabel('Frequency (Hz)');
          ylabel('Coherence-Sq');
      
          titleId = sprintf('(%i,%i). ',idxRow,indexSetOfTrials);
          title(titleId);  
        end
    
        setSegmentJson(indexIntoSetOfSegments).segment = segmentJson;
      end
    
      
      outputJsonDir = fullfile(projectFolders.output600A_json,folderName);
      if(~exist(outputJsonDir,'dir'))
        mkdir(outputJsonDir);
      end
      
      setSegmentJsonEncode = jsonencode(setSegmentJson);
      jsonFileName = ['analysis_',experimentJson.measurements{idxTrial}];
      fidJson = fopen(fullfile(outputJsonDir,jsonFileName),'w');
      fprintf(fidJson,setSegmentJsonEncode);
    
      clear('setSegmentJson');
      clear('segmentJson');
  
      pause(1);
  
    end
  end
  
  fclose(fidLogFile);
  
  outputPlotDir = fullfile(projectFolders.output600A_plots,folderName);
  if(~exist(outputPlotDir,'dir'))
    mkdir(outputPlotDir);
  end
  
  fileNameMod =['_daqDelayModel_',settings.daqDelayModel];
  fileNameMod = strrep(fileNameMod,'-','_');
  switch settings.daqDelayModel
    case 'time-domain'
      if(modelSettings.useManuallySetDaqDelay==1)
        fileNameMod = [fileNameMod,'_fixedDelay'];
      else
        fileNameMod = [fileNameMod,'_fitDelayRmsePhase'];
        if(modelSettings.zeroPhaseResponseSlope==1)
          fileNameMod = [fileNameMod,'_fitDelayZeroPhaseSlope'];
        end
      end      
    case 'frequency-domain'
      if(modelSettings.useManuallySetDaqDelay==1)
        fileNameMod = [fileNameMod,'_fixedInvLpfFrequency'];
      else
        fileNameMod = [fileNameMod,'_fitInvLpfFrequency'];
        if(modelSettings.zeroPhaseResponseSlope==1)
          fileNameMod = [fileNameMod,'_fitInvLpfFrequencyZeroPhaseSlope'];
        end
      end      
    otherwise
      assert(0,'Error: delayModel must be either time-domain or frequency-domain');
  end
  
  figSegments=configPlotExporter(figSegments, ...
            pageWidthSegment, pageHeightSegment);
  fileName =  ['fig_FrequencyResponse_',folderName,fileNameMod];
  print('-dpdf', fullfile(outputPlotDir,[fileName,'.pdf']));  
  saveas(figSegments,fullfile(outputPlotDir,[fileName,'.fig']));
  close(figSegments);

  figIntraSegments=configPlotExporter(figIntraSegments, ...
            pageWidthIntraSegment, pageHeightIntraSegment);
  fileName =  ['fig_IntraSegmentDegradation_',folderName,fileNameMod];
  print('-dpdf', fullfile(outputPlotDir,[fileName,'.pdf']));  
  saveas(figIntraSegments,fullfile(outputPlotDir,[fileName,'.fig']));
  close(figIntraSegments);


  figTimeSeries=configPlotExporter(figTimeSeries, ...
            pageWidthTimeSeries, pageHeightTimeSeries);
  fileName =  ['fig_TimeSeries_',folderName,fileNameMod];
  print('-dpdf', fullfile(outputPlotDir,[fileName,'.pdf']));  
  saveas(figTimeSeries,fullfile(outputPlotDir,[fileName,'.fig']));
  close(figTimeSeries);  
end
success=1;


