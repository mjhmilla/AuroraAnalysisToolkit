function success = ...
  runPipelineAnalyzeIndividualLengthSineFiberData600A_01_json(...
    folderName, fileKeyWord,settings,...
    setOfTrialsOverride,setOfSegmentsOverride,...
    projectFolders)

success=0;
mm2m = 0.001;
s2ms=1000;
ms2s=0.001;

flag_readHeader       = 1;


analysisKeywords={'Impedance-Individual-Length-Sine'};
analysisKeywordsFileName = '_ImpedanceIndividualLengthSine_';

analysisKeywordsList='';
for i=1:1:length(analysisKeywords)
  if(i>1)
    analysisKeywordsList = [analysisKeywordsList,', '];
  end  
  analysisKeywordsList=analysisKeywords{i};
end


%%
% folders
%%
dataFolder      = fullfile(projectFolders.data600A,folderName);
experimentStr   = fileread(fullfile(dataFolder,[folderName,'.json']));
experimentJson  = jsondecode(experimentStr);

outputPlotDir = fullfile(projectFolders.output600A_plots,folderName);
if(~exist(outputPlotDir,'dir'))
  mkdir(outputPlotDir);
end


%%
% Check that the type of experiment is valid for this processing script
%%

specimenType=lower(experimentJson.experiment.specimen);
idxS = strfind(specimenType,' ');
specimenType(idxS)='-';

setOfSpecimenTypes = {'spring','rat-edl'};
foundSpecimenType=0;
for i=1:1:length(setOfSpecimenTypes)
  if(strcmp(setOfSpecimenTypes{i},specimenType))
    foundSpecimenType=1;
  end
end

assert(foundSpecimenType,...
  ['Error: specimen name does not contain one of the following'...
      ' keywords: spring or rat-edl']);

trialType=lower(experimentJson.experiment.type);
idxS = strfind(trialType,' ');
trialType(idxS)='_';

setOfTrialTypes = {'impedance_calibration','impedance'};
foundTrialType=0;
for i=1:1:length(setOfTrialTypes)
  if(strcmp(setOfTrialTypes{i},trialType))
    foundTrialType=1;
  end
end
assert(foundTrialType,...
  ['Error: folder name does not contain one of the following'...
      ' keywords: impedance_calibration']);



%%
%
%%
fidLogFile = fopen(fullfile(dataFolder,...
  'log_runPipelineAnalyzeIndividualLengthSineFiberData600A_json.txt'),'w');

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
                      dataFolder,...
                      experimentJson,...
                      analysisKeywords,...
                      fidLogFile,...
                      settings.checkFileOrder,...
                      settings.checkSha256Sum);


totalNumberOfSegmentsToPlot = 0;
fprintf('%s\n','Preprocessing: ');
fprintf('%s\n','  Counting the number of segments to plot');
fprintf(fidLogFile,'%s\n','Preprocessing: ');
fprintf(fidLogFile,'%s\n','  Counting the number of segments to plot');


for indexSetOfTrials=16:1:length(setOfTrialsVerified)

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
  % Count the number of segments to analyze
  %%
  setOfSegments=[];
  numSegmentsToPlot = 0;
  for j=1:1:length(trialJson.segments)

    if(isfield(trialJson.segments(j).meta_data,'keywords'))
      foundKeyword=0;
      for idxA = 1:1:length(trialJson.segments(j).meta_data.keywords)
        for idxB = 1:1:length(analysisKeywords)
          if(strcmp(trialJson.segments(j).meta_data.keywords{idxA},...
                    analysisKeywords{idxB}))
            foundKeyword=1;
          end
        end
      end
      if(foundKeyword==1)
        if(isempty(setOfSegments)==1)
          setOfSegments = j;
        else
          setOfSegments = [setOfSegments;j];
        end

      end
    end    

  end  

  if(isempty(setOfSegments))
    fprintf(fidLogFile,'%s\n', ...
        ['Error: could not find segment with ',analysisKeywordsList]);
  end

  assert(~isempty(setOfSegments),...
      ['Error: could not find segment with ',analysisKeywordsList]);
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
  % Plot the time series domain data
  %
  numberOfHorizontalPlotColumnsGeneric  = 1;
  numberOfVerticalPlotRowsGeneric       = length(setOfTrials);

  plotWidth           = ones(1,numberOfHorizontalPlotColumnsGeneric).*25;
  plotHeight          = ones(numberOfVerticalPlotRowsGeneric,1).*10;
  plotHorizMarginCm   = 3;
  plotVertMarginCm    = 2;
  baseFontSize        = 12;
  
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
  for indexKeyword =1:1:length(settings.biasForce.keywords)  
  
    found=0;
    for idxTrial=1:1:length(experimentJson.measurements)
      if(~isempty(settings.biasForce.keywords{indexKeyword}))
        if(contains(experimentJson.measurements{idxTrial},...
                    settings.biasForce.keywords{indexKeyword}))
          %assert(found==0,'Error: 1 bias force keyword has matched to two files');
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
  % -Extract the individual sine curves from the length and force data.
  % -Fit curves to the data and extract out the frequency, amplitude, and
  %  start time of best fit.
  % -Evaluate the gain and phase shift and store this data in the
  %  analysis json file.
  %%

  
  fprintf('%s\n','Processing: gain, phase, coherence-sq + model fit');
  fprintf(fidLogFile,'%s\n','Processing: gain, phase, coherence-sq + model fit');
  
  if(~isempty(setOfTrialsOverride))
    setOfTrials=setOfTrialsOverride;
  end

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
  
    dataPath    = fullfile(dataFolder,filePaths{1});
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
    % Get the length-sine segments
    %%
    setOfSegments=[];
    for j=1:1:length(trialJson.segments)
      
      if(isfield(trialJson.segments(j).meta_data,'keywords'))
        foundKeyword=0;
        for idxA = 1:1:length(trialJson.segments(j).meta_data.keywords)
          for idxB=1:1:length(analysisKeywords)
            if(strcmp(trialJson.segments(j).meta_data.keywords{idxA},...
                      analysisKeywords{idxB}))
              foundKeyword=1;
            end
          end
        end
        if(foundKeyword==1)
          if(isempty(setOfSegments)==1)
            setOfSegments = j;
          else
            setOfSegments = [setOfSegments;j];
          end
        end
      end
    end  

    if(isempty(setOfSegments))
      isValid=0;    
      

      fprintf(fidLogFile,'%s\n', ...
          ['Warning: could not find segment with ',analysisKeywordsList, ...
           ' in ', experimentJson.measurements{idxTrial}]);
      fprintf('%s\n', ...
          ['Warning: could not find segment with ',analysisKeywordsList, ...
           ' in ', experimentJson.measurements{idxTrial}]);

    end  
  
    if(isValid==1)      

 
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
  
  
      ylabel(['Force (',auroraData.Data.Fin.Unit,')']);
      titleStr = strrep(experimentJson.measurements{idxTrial},'_','\_');        
      title(titleStr);
      axis tight;
      box off;
  
  
  
    
      %%
      % Process each of the segments
      %%
    
      %
      % Plot the segment data
      %  
      numberOfHorizontalPlotColumnsGeneric  = 6;
      numberOfVerticalPlotRowsGeneric       = length(setOfSegments);
    
      % 1. Time domain
      % 2. length-time-force
      % 3. gain-time-phase
      % 4. rel-mag
      % 5. coherence-sq
      plotWidth                 = ones(1,numberOfHorizontalPlotColumnsGeneric).*6;
      plotHeight                = ones(numberOfVerticalPlotRowsGeneric,1).*6;
      plotHorizMarginCm         = 3;
      plotVertMarginCm          = 2;
      baseFontSize              = 8;
      
      [subPlotPanelSegment, pageWidthSegment, pageHeightSegment]= ...
        plotConfigGeneric(  numberOfHorizontalPlotColumnsGeneric,...
                            numberOfVerticalPlotRowsGeneric,...
                            plotWidth,...
                            plotHeight,...
                            plotHorizMarginCm,...
                            plotVertMarginCm,...
                            baseFontSize); 
      figSegments = figure;
    
      %
      % Over the course of many segments, there is drift in the start
      % time of each segment. For this protocol we can identify each
      % segment using the envelope because there is some time where 
      % nothing is done between
      %


      dTime = [0;diff(auroraData.Data.Time.Values)];
      indexEnableDisable = find(dTime > 2);


      flag_highlightSegments=0;
      if(flag_highlightSegments==1)
        success = inspectDataAndSegments600A(...
                    setOfSegments,trialJson,auroraData);
      end

      if(~isempty(setOfSegmentsOverride))
        setOfSegments=setOfSegments(setOfSegmentsOverride);
      end

      for indexIntoSetOfSegments = 1:1:length(setOfSegments)
      
        idxSeg = setOfSegments(indexIntoSetOfSegments,1);
        fprintf('\t%i/%i\tSegment count\n',indexIntoSetOfSegments,length(setOfSegments));
        %%
        %Extract the indicies to plot
        %%
        timeStartNoPad = trialJson.segments(idxSeg).time_ms(1);
        timeEndNoPad   = trialJson.segments(idxSeg).time_ms(2);

        %
        % Adjust the starting and ending times of each segment: there
        % is drift between the desired beginning and ending of each 
        % segment. I'm not quite sure why, but I suspect it is because the
        % data enable and data disable commands are costing more time
        % than I had expected.
        %
        % Lucky for me I can use the jump in time between the data disable
        % and data enable to easily segment the data.
        %
        timeMid = 0.5*(timeEndNoPad+timeStartNoPad);
        indexMid = find(auroraData.Data.Time.Values > timeMid,1,'first');

        indexStart=nan;
        indexEnd=nan;
        if(indexMid < indexEnableDisable(end))
          for idxED=2:1:(length(indexEnableDisable))
            if(   indexMid > indexEnableDisable(idxED-1)...
               && indexMid < indexEnableDisable(idxED))
              indexStart = indexEnableDisable(idxED-1)+1;
              indexEnd   = indexEnableDisable(idxED)-1;
            end
          end
        else
          indexStart=indexEnableDisable(end);
          indexEnd  = length(auroraData.Data.Time.Values);
        end

        assert(~isnan(indexStart) && ~isnan(indexEnd),...
               ['Error: could not refine segments using',...
               ' the difference in time method']);
        dataIndex = [indexStart:1:indexEnd]; 

        %
        % Solve for the no-padding interval
        %   This assumes that the segment data 
        %   - begins and end with some padding
        %   - the signal values in the padding are much smaller than the
        %     data
        %   - the data has a constant mean value  
        %
        %paddingSamples=...
        %  settings.paddingTimeSinusoidMS*ms2s*auroraData.Setup_Parameters.A_D_Sampling_Rate.Value;

        duration_s = diff(trialJson.segments(idxSeg).time_ms)*ms2s;

        [indexStartNoPad, indexEndNoPad ] = ...
          searchForSegmentBoundary600A(...
             indexStart, indexEnd, ...
             trialJson.segments(idxSeg).meta_data.frequency_Hz,...
             duration_s,...
             auroraData);     
        
        fftFrequencyHz=...
          calcFrequencyWithPeakPower(...
           auroraData.Data.Lin.Values(indexStart:indexEnd),...
           auroraData.Setup_Parameters.A_D_Sampling_Rate.Value);



        timeStart = auroraData.Data.Time.Values(indexStartNoPad);
        timeEnd   = auroraData.Data.Time.Values(indexEndNoPad);

        dataIndexNoPad=[indexStartNoPad:1:indexEndNoPad];

        isSegmentValid=nan;
        if(length(dataIndex)>10)
          if(    length(auroraData.Data.Lin.Values(dataIndex,1))>10 ...
              && length(auroraData.Data.Fin.Values(dataIndex,1))>10)
            isSegmentValid=1;
          else
            isSegmentValid=0;
          end
        else
          isSegmentValid=0;
        end
        
        assert(isSegmentValid);

        %%
        %Get the meta data
        %%
        assert(isfield(trialJson.segments(idxSeg).meta_data,'keywords'));
        foundKeywords=0;
        for idxA=1:1:length(trialJson.segments(idxSeg).meta_data.keywords)
          for idxB=1:1:length(analysisKeywords)
            if(strcmp(trialJson.segments(idxSeg).meta_data.keywords{idxA},...
                      analysisKeywords{idxB}))
              foundKeywords=1;
            end
          end
        end
        assert(foundKeywords);        

        %
        % Check that all of the fields have been populated
        %
        assert(trialJson.segments(idxSeg).is_recorded==1);
        assert(isfield(trialJson.segments(idxSeg).meta_data,'bath'));
        assert(isfield(trialJson.segments(idxSeg).meta_data,'frequency_Hz'));
        assert(isfield(trialJson.segments(idxSeg).meta_data,'length_Lo'));
        assert(isfield(trialJson.segments(idxSeg).meta_data,'duration_ms'));
        
        
       
        %%
        % Fit a sinusoid to the length data to extract the amplitude
        % and fundamental frequency and process the data using the 
        % exact same approach as Kawai
        %%
        if(isSegmentValid==1)


    
          fittingSettings.indexSegment=[dataIndex(1),dataIndex(end)];
          fittingSettings.time        = auroraData.Data.Time.Values(dataIndex);
          fittingSettings.length      = auroraData.Data.Lin.Values(dataIndex,1);
          fittingSettings.force       = auroraData.Data.Fin.Values(dataIndex,1);
          fittingSettings.timeScaling = 0.001; %Convert to seconds
          fittingSettings.duration_ms = ...
            trialJson.segments(idxSeg).meta_data.duration_ms;
          fittingSettings.number_of_elements = length(dataIndexNoPad);
          fittingSettings.Lo = experimentJson.experiment.length_mm;

          fittingSettings.optInterval  = [dataIndexNoPad(1)-dataIndex(1),...
                                          dataIndexNoPad(end)-dataIndex(1)];
          fittingSettings.var          = 'length';
          fittingSettings.paramScaling = [];
          fittingSettings.lambda       = 0.1;

          numberOfPaddingSamples = ...
            round(auroraData.Setup_Parameters.A_D_Sampling_Rate.Value ...
                  *settings.paddingTimeMS*ms2s);

          numberOfNoiseSamples=round(0.25*numberOfPaddingSamples);

          fittingSettings.lengthNoiseFit = ...
            polyfit(fittingSettings.time(1:numberOfNoiseSamples),...
                    fittingSettings.length(1:numberOfNoiseSamples),1);

          fittingSettings.lengthNoiseStd = ...
            std(fittingSettings.length(1:numberOfNoiseSamples));

          fittingSettings.forceNoiseFit = ...
            polyfit(fittingSettings.time(1:numberOfNoiseSamples),...
                    fittingSettings.force(1:numberOfNoiseSamples),1);

          fittingSettings.forceNoiseStd = ...
            std(fittingSettings.force(1:numberOfNoiseSamples));
          

          fittingSettings.scaling      = 1;

          %
          % Identify a good initial solution for mean length
          %
          lengthMean=mean(auroraData.Data.Lin.Values(dataIndexNoPad,1));

          %
          % Identify a good initial solution for the length change
          %
          lengthChange= ...
            0.5*(max(auroraData.Data.Lin.Values(dataIndexNoPad,1))...
                -min(auroraData.Data.Lin.Values(dataIndexNoPad,1)));
 
          %
          % Scan through and pick off all of the positve peaks. Then divide
          % the duration by the number of peaks to get an accurate initial
          % estimate of the frequency.
          %


          frequency_Hz=trialJson.segments(idxSeg).meta_data.frequency_Hz;

          period                = 1/frequency_Hz;
          period_ms             = (1/frequency_Hz).*s2ms;
          scaleOfFrequencyError = 0.2;
          numberOfCyclesToFit   = 1;%ceil(0.5/scaleOfFrequencyError);

          numberOfSamplesPerPeriod = ...
            ceil(period*auroraData.Setup_Parameters.A_D_Sampling_Rate.Value);



          fittingSettings.algorithm = {...
            'scan',...
            'lsqnonlin',...
            'lsqnonlin',...
            'lsqnonlin',...
            'scan'};  

          fittingSettings.applyAlgorithm = {...
            'all',...
            'all',...
            'all',...
            'all',...
            'last'};            

          fittingSettings.paramOffset = ...
            [indexStartNoPad-indexStart+1,...
            lengthMean,...
            frequency_Hz,...
            lengthChange,...
            fittingSettings.number_of_elements];

          if(numberOfSamplesPerPeriod*numberOfCyclesToFit ...
              < diff(fittingSettings.optInterval))
            fittingSettings.optInterval = ...
              [fittingSettings.paramOffset(1),...
               (fittingSettings.paramOffset(1) ...
               + numberOfSamplesPerPeriod*numberOfCyclesToFit)];
          end


          fittingSettings.paramScaling = [ ...
            1,...
            lengthMean,...
            frequency_Hz*scaleOfFrequencyError,...
            lengthChange,...
            1];  

          timeDelta = max(settings.paddingTimeMS*0.5,period_ms);

          %lbTime =...
          %  max(auroraData.Data.Time.Values(indexStartNoPad)-timeDelta,...
          %      auroraData.Data.Time.Values(indexStart));
    
          


          indexTol = min(round(numberOfSamplesPerPeriod*0.5),...
                         round(numberOfPaddingSamples*0.25));

          lb = [1,...
                lengthMean*0.5,...
                frequency_Hz.*0.75,...
                lengthChange*0,...
                (fittingSettings.number_of_elements-numberOfSamplesPerPeriod)];

          lbS = (lb-fittingSettings.paramOffset)...
               ./fittingSettings.paramScaling;

          idxTimeMax = max(1,length(fittingSettings.time)...
                             -fittingSettings.number_of_elements);

          ubTime = min(fittingSettings.paramOffset(1)+2*timeDelta,...
                       fittingSettings.time(idxTimeMax));
          ub = [min(fittingSettings.paramOffset(1)+indexTol,...
                   dataIndex(end)-length(dataIndexNoPad)),...
                lengthMean*1.5,...
                frequency_Hz.*1.25,...
                lengthChange.*5,...
                (fittingSettings.number_of_elements+numberOfSamplesPerPeriod)];

          ubS = (ub-fittingSettings.paramOffset)./fittingSettings.paramScaling;
          

          %
          % If the frequency is not accurately identified the rest of the
          % fitting falls apart. However, identifying the frequency is
          % a nasty problem:
          %
          % - The actual and programmed frequency might differ by 10%
          % - At high frequencies the signal does not have a lot of samples
          % - For long samples, there could be 1000's of cycles. As a
          %   result, the frequency has to be identified to 1/1000th to 
          %   avoid aliasing. If you start with a signal that is off by
          %   1 cycle, then any grandient based method will converge to a
          %   local minima.
          %
          % And so, we do this interatively:
          %
          % Fit the first 5 cycles. If the signal has more than five cycles
          % then next solve for 10 cycles, then 20, etc. until the interval
          % is completely fit.
          %

          nCycles = round(frequency_Hz*(fittingSettings.duration_ms*ms2s));
          assert(nCycles > 0, 'Error: this segment has less than 1 cycle');

          fitCycles = numberOfCyclesToFit;
          if(fitCycles > nCycles)
            fitCycles = min(1, round(nCycles/2));
          end

          options = optimoptions( 'lsqnonlin',...
                                  'Algorithm','levenberg-marquardt',...
                                  'Display','off',...
                                  'FunctionTolerance',1e-9);
          
          flag_completeIntervalFitted=0;
          idxOpt=3;
          idxSamples=5;

          lbSIter = lbS;
          ubSIter = ubS;
          optParams=zeros(1,length(ubS));

          optVarSchedule(1).vars=1;
          optVarSchedule(1).algorithm ='scan';
          optVarSchedule(1).exitflag=nan;
          optVarSchedule(1).resnorm=nan;

          optVarSchedule(2).vars=[2,3,4];
          optVarSchedule(2).algorithm ='lsqnonlin';
          optVarSchedule(2).exitflag=nan;   
          optVarSchedule(2).resnorm=nan;

          optVarSchedule(3).vars=1;
          optVarSchedule(3).algorithm ='scan';
          optVarSchedule(3).exitflag=nan;
          optVarSchedule(3).resnorm=nan;

          optVarSchedule(4).vars=[2,3,4];
          optVarSchedule(4).algorithm ='lsqnonlin';
          optVarSchedule(4).exitflag=nan;   
          optVarSchedule(4).resnorm=nan;          
          
          iterCycle=1;

          fittingSettings.optVarIndex=[1,2,3,4,5];
          %fittingSettings.scaling=1;
          x0=[0,0,0,0,0];

          [errVA,errDotA,mdlA]=...
            calcErrorOfSinusoid600A(x0,fittingSettings);   

          rmseA=sqrt(mean(errVA.^2));

          index0=fittingSettings.paramOffset(1);
          index1=index0+fittingSettings.paramOffset(5);
          lengthStd = std(fittingSettings.length(index0:index1));

          varNames={'i0','y0','frequency_Hz','amplitude','numberElements'};

          fprintf('\tInitial Guess\n');
          fprintf('\t\t%1.3e\t%1.3e\tNRMSE\n',...
              rmseA/fittingSettings.lengthNoiseStd,...
              rmseA/lengthStd);
          xInitial=zeros(size(fittingSettings.paramOffset));
          for idxV=1:1:length(varNames)            
            fprintf('\t\t%1.3e\t%s\n',fittingSettings.paramOffset(idxV),...
                                  varNames{idxV});
            xInitial(idxV)=fittingSettings.paramOffset(idxV);
          end


          while(flag_completeIntervalFitted == 0 )
            
            if(fitCycles==nCycles)
              flag_completeIntervalFitted=1;
            end


            for i=1:1:length(optVarSchedule)
              
              idxOpt=optVarSchedule(i).vars;
              fittingSettings.optVarIndex=idxOpt;
                     
              enableFitting=1;

              if(enableFitting==1)
                fittingSettings.optVarIndex=idxOpt;

                x0=zeros(size(idxOpt));                

                [errVA,errDotA,mdlA]=...
                  calcErrorOfSinusoid600A(x0,fittingSettings);
                errFcn = ...
                  @(argX)calcErrorOfSinusoid600A(argX,fittingSettings);
    

                [errV0,errDot0,mdl0]=errFcn(x0);
                
                
    
                switch optVarSchedule(i).algorithm 
                  case 'scan'
                    varName=fittingSettings.var;

                    frequency_Hz=fittingSettings.paramOffset(3);
                    period_S = 1/frequency_Hz;
                    samplesPerPeriod = ...
                      period_S*auroraData.Setup_Parameters.A_D_Sampling_Rate.Value;

                    idxMdlA = 1;
                    idxMdlB = max(2,round(samplesPerPeriod*(45/360)));


                    lsqV = zeros(ub(1)-lb(1)+1,1);
                    idxLsqV=zeros(size(lsqV));

                    for idxLUB=1:1:((ub(1)-lb(1))+1)
                      idxOffset=lb(1)-1+idxLUB;

                      idxDataA = idxOffset;
                      idxDataB = idxOffset + (idxMdlB-idxMdlA);
                      
                      ydiff = mdl0.y(idxMdlA:idxMdlB) ...
                             -fittingSettings.(varName)(idxDataA:idxDataB);

                      idxLsqV(idxLUB)=idxOffset;
                      lsqV(idxLUB)=norm(ydiff);

                      fig_debugDot=0;
                      if(fig_debugDot==1 && mod(idxLUB,100)==0)
                        figDebugDot=figure;
                          plot(mdl0.y(idxMdlA:idxMdlB));
                          hold on;
                          plot(fittingSettings.(varName)(idxDataA:idxDataB));
                          hold on;
                          pause(0.01);
                        close(figDebugDot);
                      end

                    end

                    [maxLsq, idxLsqMax]=min(lsqV);
                    timeBest=fittingSettings.time(idxLsqMax);

                    fittingSettings.paramOffset(1)=idxLsqMax;


                    idxSegStart=idxLsqMax;
                    idxSegEnd  = ...
                      min(idxLsqMax+diff(fittingSettings.optInterval),...
                          length(fittingSettings.time));
                    duration_ms = fittingSettings.time(idxSegEnd) ...
                                - fittingSettings.time(idxSegStart);
                    duration_S = duration_ms*ms2s;

                    frequency_Hz = fittingSettings.paramOffset(3);
                    period_S=1/frequency_Hz;
                    
                    idxSegEnd = ...
                      min(idxSegStart + round(samplesPerPeriod*fitCycles),...
                          length(fittingSettings.time));
                    

                    fittingSettings.optInterval = [idxLsqMax,idxSegEnd];
                    fittingSettings.paramOffset(5)=(idxSegEnd-idxLsqMax);

                    errFcn = ...
                      @(argX)calcErrorOfSinusoid600A(argX,fittingSettings);                    

                    x0=zeros(size(idxOpt));

                    [errV0,errDot0,mdl0]=errFcn(x0);


                    fig_debugScan=0;
                    if(fig_debugScan==1)
                      figScan=figure;
                      subplot(1,2,1);
                        plot(fittingSettings.time,...
                             fittingSettings.(varName),...
                             '-','Color',[1,1,1].*0.5);                        
                        hold on;
                        plot(fittingSettings.time(idxLsqMax),...
                             fittingSettings.(varName)(idxLsqMax),...
                             'o','Color',[1,0,0]);                        
                        hold on;                       
                        plot(mdl0.x-mdl0.x(1)+timeBest,...
                             mdl0.y,'-b');
                        xlabel('Time');
                        ylabel(varName);
                      subplot(1,2,2);
                        plot(idxLsqV,lsqV);
                        hold on;
                        plot(idxLsqV(idxLsqMax),lsqV(idxLsqMax),'or');
                        xlabel('Starting Index');
                        ylabel('Norm(err)');
                      close(figScan);
                    end                    
  
  
                  case 'lsqnonlin'
                    

                    optParams=zeros(1,length(idxOpt));

                    [x,resnorm,res,exitflag,output,lambda,jac] ...
                      = lsqnonlin(errFcn,optParams,...
                                  lbSIter(idxOpt),ubSIter(idxOpt),...
                                  options); 
                    optVarSchedule(i).exitflag=exitflag;
                    %Update the offset, scaling, and bounds
                    fittingSettings.paramOffset(idxOpt)=...
                      x.*fittingSettings.paramScaling(idxOpt)...
                      +fittingSettings.paramOffset(idxOpt);                        
                
                    fittingSettings.paramScaling(idxOpt) = ...
                      fittingSettings.paramScaling(idxOpt).*0.5;
        
                    lbSIter(idxOpt) = ...
                      (lb(idxOpt)-fittingSettings.paramOffset(idxOpt))...
                      ./fittingSettings.paramScaling(idxOpt);
        
                    ubSIter(idxOpt) = ...
                      (ub(idxOpt)-fittingSettings.paramOffset(idxOpt))...
                      ./fittingSettings.paramScaling(idxOpt); 

                  otherwise
                    assert(0,'Error: unrecognized optimization algorithm')
                end

                errFcn = ...
                  @(argX)calcErrorOfSinusoid600A(argX,fittingSettings);                    

                x0=zeros(size(idxOpt));                
                [errV1,errDot1,mdl1]=errFcn(x0);
    
                here=1;
  

              end

            end
            %
            % Update
            %
            if(flag_completeIntervalFitted==0)
              fitCycles = fitCycles*2;
              if(fitCycles > nCycles)
                fitCycles = nCycles;              
              end
  
              index1    = min(round(fitCycles*numberOfSamplesPerPeriod),...
                              length(dataIndexNoPad));              
              
              fittingSettings.optInterval(2)=...
                   [dataIndexNoPad(index1)-dataIndex(1)];
              
              fittingSettings.number_of_elements = ...
                diff(fittingSettings.optInterval);
  
              if(idxOpt ~= idxSamples)
                fittingSettings.paramOffset(idxSamples)=...
                  fittingSettings.number_of_elements;
  
                lbSIter(idxSamples) = ...
                  (lb(idxSamples)-fittingSettings.paramOffset(idxSamples))...
                  ./fittingSettings.paramScaling(idxSamples);
    
                ubSIter(idxSamples) = ...
                  (ub(idxSamples)-fittingSettings.paramOffset(idxSamples))...
                  ./fittingSettings.paramScaling(idxSamples);              
              end
            end

            iterCycle=iterCycle+1;
          end 

          %fittingSettings.scaling=1;

          x=[0,0,0,0,0];
          fittingSettings.optVarIndex=[1,2,3,4,5];
          [errV,errDot,fittedSine]=calcErrorOfSinusoid600A(x,fittingSettings);

          rmseB=sqrt(mean(errV.^2));

          index0 = fittingSettings.paramOffset(1);
          index1 = index0+fittingSettings.paramOffset(5);

          lengthStd = std(fittingSettings.length(index0:index1));

          fprintf('\tFitting\n');
          fprintf('\t\t%1.3e\t%1.3e\tError\n',...
            rmseB/fittingSettings.lengthNoiseStd,...
            rmseB/lengthStd);
          for idxV=1:1:length(varNames)            
            fprintf('\t\t%1.3e\t%1.3e\t%s\n',...
              fittingSettings.paramOffset(idxV),...
              fittingSettings.paramOffset(idxV)-xInitial(idxV),...
                                  varNames{idxV});
          end



          indexA0=index0+indexStart-1;
          indexA1=index1+indexStart-1;

          time0=auroraData.Data.Time.Values(indexA0);
          time1=auroraData.Data.Time.Values(indexA1);

          sinusoidFit = ...            
            struct('time_ms',time0,...
                   'indexSegment',fittingSettings.indexSegment,...
                   'indexSine',[indexA0,indexA1],...  
                   'indexSineLocal',[index0,index1],...
                   'length_mm',fittingSettings.paramOffset(2),...
                   'frequency_Hz',fittingSettings.paramOffset(3),...
                   'amplitude_Lo',fittingSettings.paramOffset(4),...
                   'duration_ms',time1-time0,...
                   'rmse',rmseB,...
                   'rmse_noise_std',rmseB/fittingSettings.lengthNoiseStd,...
                   'rmse_signal_std',rmseB/lengthStd,...                   
                   'noise_std',fittingSettings.lengthNoiseStd,...
                   'signal_std',lengthStd,...
                   'snr',lengthStd.^2 / fittingSettings.lengthNoiseStd.^2,...
                   'snr_db',10*log10(lengthStd.^2 / fittingSettings.lengthNoiseStd.^2),...                   
                   'objscale',fittingSettings.scaling,...
                   'exitflag',optVarSchedule(end).exitflag);   

          %fprintf('\n%1.3f Hz Error\n',fftFrequencyHz-fittingSettings.paramOffset(3));
          

          if(strcmp(fittingSettings.var,'length')==1)

            figure(figSegments)
            subplot('Position',...
              reshape(subPlotPanelSegment(indexIntoSetOfSegments,1,:),1,4));

              period_s   = 1/sinusoidFit.frequency_Hz;
              nPeriodMax = sinusoidFit.duration_ms*ms2s*sinusoidFit.frequency_Hz;
              nPeriod    = min(4,nPeriodMax);              
              
              numberOfSamplesPerPeriod = ...
                period_s*auroraData.Setup_Parameters.A_D_Sampling_Rate.Value;

              indexA=sinusoidFit.indexSineLocal(1);
              indexB=indexA+round(nPeriod*numberOfSamplesPerPeriod)-1;

              plot( fittingSettings.time(indexA:indexB),...
                    fittingSettings.(fittingSettings.var)(indexA:indexB),...
                    '-','Color',[1,1,1].*0.75,'LineWidth',1);
              hold on;

              
              plot(fittedSine.x(1:(indexB-indexA+1)),...
                   fittedSine.y(1:(indexB-indexA+1)),'-','Color',[0,0,1]);
              hold on;
              ax = gca; 
              xlim(ax, xlim(ax) + [-1, 1] * diff(xlim(ax)) * 0.05); 
              ylim(ax, ylim(ax) + [-1, 1] * diff(ylim(ax)) * 0.05); 
              box off;


              text(fittedSine.x(indexB-indexA+1),...
                   fittedSine.y(indexB-indexA+1),...
                   sprintf('%1.4f Hz',sinusoidFit.frequency_Hz),...
                   'HorizontalAlignment','right',...
                   'VerticalAlignment','bottom');
              hold on;
  
              xlabel(sprintf('Time (%s)',auroraData.Data.Time.Unit));
              ylabel(sprintf('Length (%s)',auroraData.Data.Lin.Unit));
              title(sprintf('(%i,1). Length-Sine',idxSeg));
          end
  
        end



        %%
        % Extract the segment and process it using Welch's method. This
        % will include the higher harmonics and give us a measure of
        % the linearity of the response.
        %%
        nHarmonics = 10; 
        nyquistFrequency = auroraData.Setup_Parameters.A_D_Sampling_Rate.Value*0.5;
        if((nHarmonics*sinusoidFit.frequency_Hz) > nyquistFrequency)
          nHarmonics = floor(nyquistFrequency/sinusoidFit.frequency_Hz);
        end

        if(isSegmentValid==1)

          timeStart= auroraData.Data.Time.Values(sinusoidFit.indexSine(1));
          timeEnd  = auroraData.Data.Time.Values(sinusoidFit.indexSine(2));

          dataIndex =[sinusoidFit.indexSine(1):1:sinusoidFit.indexSine(2)]; 

          preDataIndex=[];
          if(sinusoidFit.indexSine(1)>sinusoidFit.indexSegment(1))
            preDataIndex = ...
              [sinusoidFit.indexSegment(1):1:sinusoidFit.indexSine(1)];
          end

          x     = auroraData.Data.Lin.Values(dataIndex,1);
          xMean = mean(x);
          x     = x - xMean;      
  
          y = auroraData.Data.Fin.Values(dataIndex,1);
  
          yBias=0;        
          switch trialJson.segments(idxSeg).meta_data.bath
            case 'active'
              if(~isnan(biasForce.active.force))
                yBias = biasForce.active.force;
              end
            case 'passive'
              if(~isnan(biasForce.passive.force))
                yBias = biasForce.passive.force;
              end
          end
          y     = y-yBias;        
          yMean = mean(y);
          y     = y-yMean;
          
          
          segData.x      = x;
          segData.y      = y;
          segData.yBias  = yBias;
          segData.xMean  = xMean;
          segData.yMean  = yMean;     

          segData.xPrior = [];
          segData.yPrior = [];
          if(~isempty(preDataIndex))
            segData.timePrior=auroraData.Data.Time.Values(preDataIndex,1);
            segData.xPrior = auroraData.Data.Lin.Values(preDataIndex,1);
            segData.yPrior = auroraData.Data.Fin.Values(preDataIndex,1);            
          end
          
          segData.time            = auroraData.Data.Time.Values(dataIndex);
          segData.bandwidth_Hz    = [0,sinusoidFit.frequency_Hz*nHarmonics];
          segData.sampleFrequency = auroraData.Setup_Parameters.A_D_Sampling_Rate.Value;   

          if(max(segData.bandwidth_Hz)>0.5*segData.sampleFrequency)
            segData.bandwidth_Hz = [0,0.5*segData.sampleFrequency];
          end

   
          %%
          %
          % Evaluate the frequency response using Welch's method
          %
          %%
          segData.H0 = evaluateGainPhaseCoherenceSq(...
                          segData.time,...
                          segData.x,...
                          segData.y,...
                          segData.bandwidth_Hz,...
                          segData.sampleFrequency,...
                          settings.coherenceSquaredThreshold,...
                          0);



          if(settings.useManuallySetDaqDelay==1)
            assert(strcmp(settings.daqDelayModel,'frequency-domain')==1,...
                   ['Error: Only the frequency-domain delay',...
                   ' model has been evaluated']);
          end    

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
  
            delay = calcPhaseDelayOfElasticMedium(...
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
            %  Between 0-90 Hz the delay is negligible. It is 
            %  negligible for the fiber but not the spring because
            %  the fiber is ~1/100th the mass of the spring.
            %
            %%
            segData.H1=segData.H0;
            delayModel.phaseDelayCompensated=0;
          end

          delayModel.phaseDelay = delay;

          assert(settings.useManuallySetDaqDelay==1 ...
                 && strcmp(settings.daqDelayModel,'frequency-domain'),...
                 ['Error: this script is not setup to solve for the ',...
                  'inverse filter of best fit to the DAQ system']);

          delayModel.daqFilterFrequencyHz = settings.daqFilterFrequencyHz;

          %
          % Compensate for the filtering effect of the DAQ
          %
          n = length(segData.H1.x);
          omega = delayModel.daqFilterFrequencyHz*2*pi;
          frequencyHz = [0:(1/(n)): (1-(1/n)) ]'...
                          .* (segData.sampleFrequency);
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
          %
          % Use Kawai's approach of just extracting out the Fourier
          % coefficients directly
          %
          %%          
          setOfSignals={'H0','H1','H2'};

          for idxS=1:1:length(setOfSignals)
            ms2s = 0.001;        
            Hs = setOfSignals{idxS};
            segData.FS.(Hs).frequency   = zeros(nHarmonics,1);
            segData.FS.(Hs).frequencyHz = zeros(nHarmonics,1);          
            segData.FS.(Hs).length.L    = zeros(nHarmonics,1);
            segData.FS.(Hs).length.hk   = zeros(nHarmonics,1);
            segData.FS.(Hs).length.I    = 0;          
            segData.FS.(Hs).length.D    = 0;
            segData.FS.(Hs).length.LinvFT = [];
  
            segData.FS.(Hs).force.F     = zeros(nHarmonics,1);
            segData.FS.(Hs).force.hk    = zeros(nHarmonics,1);
            segData.FS.(Hs).force.I     = 0;          
            segData.FS.(Hs).force.D     = 0;
            segData.FS.(Hs).force.FinvFT = [];
            
            for idxN =1:1:nHarmonics
              segData.FS.(Hs).frequency(idxN)   = ...
                sinusoidFit.frequency_Hz*(2*pi)*idxN;
              segData.FS.(Hs).frequencyHz(idxN) = ...
                sinusoidFit.frequency_Hz*idxN;
              
              omega_Hz= sinusoidFit.frequency_Hz*idxN;
              omega   = omega_Hz*(2*pi);
              
              Tcyc    = 1/omega_Hz;
              nCycles = (sinusoidFit.duration_ms.*ms2s)/Tcyc;
              A      = (2/(nCycles*Tcyc));
              timeSeg = (segData.time-sinusoidFit.time_ms).*ms2s;
  
              %Real component
              sineWt = sin( omega.*(timeSeg) );
              l_dot_sineWt = sineWt.*segData.(Hs).x;
              f_dot_sineWt = sineWt.*segData.(Hs).y;
  
              flag_useIntegrate=0;
  
              if(flag_useIntegrate==1)
                fcnSineL = @(argX)interp1(timeSeg,l_dot_sineWt,argX,'linear');
                L_real = integral(fcnSineL,timeSeg(1),timeSeg(end)); 
              else
                L_real = trapz(timeSeg,l_dot_sineWt);
              end
              L_real = A.*L_real;
  
              if(flag_useIntegrate==1)
                fcnSineF = @(argX)interp1(timeSeg,f_dot_sineWt,argX,'linear');
                F_real = integral(fcnSineF,timeSeg(1),timeSeg(end)); 
              else
                F_real = trapz(timeSeg,f_dot_sineWt);
              end
              F_real = A.*F_real;
  
              %Complex component
              cosWt = cos( omega.*(timeSeg) );
              l_dot_cosWt = cosWt.*segData.(Hs).x;
              f_dot_cosWt = cosWt.*segData.(Hs).y;
  
              if(flag_useIntegrate==1)
                fcnCosL = @(argX)interp1(timeSeg,l_dot_cosWt,argX,'linear');
                L_imag = integral(fcnCosL,timeSeg(1),timeSeg(end)); 
              else
                L_imag = trapz(timeSeg,l_dot_cosWt);
              end
              L_imag = A.*L_imag;
  
              if(flag_useIntegrate==1)
                fcnCosF = @(argX)interp1(timeSeg,f_dot_cosWt,argX,'linear');
                F_imag = integral(fcnCosF,timeSeg(1),timeSeg(end)); 
              else
                F_imag = trapz(timeSeg,f_dot_cosWt);
              end
              F_imag = A.*F_imag;        
              
              %Save the complex coefficients
              segData.FS.(Hs).length.L(idxN) = complex(L_real,L_imag);
              segData.FS.(Hs).force.F(idxN)  = complex(F_real,F_imag);
              
              segData.FS.(Hs).length.I= ...
                segData.FS.(Hs).length.I + (L_real*L_real + L_imag*L_imag);
  
              segData.FS.(Hs).force.I= ...
                segData.FS.(Hs).force.I + (F_real*F_real + F_imag*F_imag);
  
              %Build the FS time domain signals
              if(isempty(segData.FS.(Hs).length.LinvFT))
                segData.FS.(Hs).length.LinvFT = L_real.*sineWt + L_imag.*cosWt;
              else
                segData.FS.(Hs).length.LinvFT =  segData.FS.(Hs).length.LinvFT ...
                                          + L_real.*sineWt + L_imag.*cosWt;
              end
  
              if(isempty(segData.FS.(Hs).force.FinvFT))
                segData.FS.(Hs).force.FinvFT = F_real.*sineWt + F_imag.*cosWt;
              else
                segData.FS.(Hs).force.FinvFT =  segData.FS.(Hs).force.FinvFT ...
                                          + F_real.*sineWt + F_imag.*cosWt;
              end
  
  
            end
  
            for idxN=1:1:nHarmonics
              segData.FS.(Hs).force.hk(idxN) = abs(segData.FS.(Hs).force.F(idxN))...
                                          ./sqrt(segData.FS.(Hs).force.I);
              segData.FS.(Hs).length.hk(idxN) = abs(segData.FS.(Hs).length.L(idxN))...
                                           ./sqrt(segData.FS.(Hs).length.I);
            end
  
            h1F = segData.FS.(Hs).force.hk(1);
            segData.FS.(Hs).force.D = sqrt(1-h1F'*h1F);
  
            h1L = segData.FS.(Hs).length.hk(1);
            segData.FS.(Hs).length.D = sqrt(1-h1L'*h1L);
  
  
            segData.FS.(Hs).H = (segData.FS.(Hs).force.F .* segData.FS.(Hs).length.L)...
                         ./(segData.FS.(Hs).length.L .* segData.FS.(Hs).length.L);
  
            segData.FS.(Hs).gain = abs(segData.FS.(Hs).H);
            segData.FS.(Hs).phase= angle(segData.FS.(Hs).H);
            segData.FS.(Hs).storage = segData.FS.(Hs).gain .* cos(segData.FS.(Hs).phase);
            segData.FS.(Hs).loss    = segData.FS.(Hs).gain .* sin(segData.FS.(Hs).phase);

          end
          %%
          % Populate and save the json structure
          %%
          if(isSegmentValid==1)

            sinusoidJson.interval = [timeStart,timeEnd];
            sinusoidJson.index    = idxSeg;
            sinusoidJson.type     = trialJson.segments(idxSeg).type;
            sinusoidJson.indexData= [dataIndex(1),dataIndex(end)];

            %sinusoidJson.time     = [auroraData.Data.Time.Values(dataIndex(1),1)];
            %sinusoidJson.length   = auroraData.Data.Lin.Values(dataIndex,1);
            %sinusoidJson.force    = auroraData.Data.Fin.Values(dataIndex,1);  

            sinusoidJson.lengthFit= sinusoidFit;
            sinusoidJson.lengthMean  = segData.xMean;
            sinusoidJson.forceMean   = segData.yMean;
            sinusoidJson.forceBias   = segData.yBias; 
            sinusoidJson.indexNominal=[preDataIndex(1),preDataIndex(end)];
            
            %sinusoidJson.nominal.time    = segData.timePrior;
            %sinusoidJson.nominal.length  = segData.xPrior;
            %sinusoidJson.nominal.force   = segData.yPrior; 

            analysisNames ={'H0','H1','H2'};

            fieldsToRemove = {'H','x','y','time'};
            fieldsToUpdate = {'frequency',...
                              'frequencyHz',...
                              'H',...
                              'gain',...
                              'phase',...
                              'storage',...
                              'loss',...
                              'coherenceSq'};



            for idxH=1:1:length(analysisNames)
              Hs=analysisNames{idxH};
              sinusoidJson.(Hs)  = segData.(Hs);   
  
              idxBW = sinusoidJson.(Hs).idxBW;
              for idxF=1:1:length(fieldsToUpdate)
                sinusoidJson.(Hs).(fieldsToUpdate{idxF}) = ...
                  sinusoidJson.(Hs).(fieldsToUpdate{idxF})(idxBW);
              end

              for idxR=1:1:length(fieldsToRemove)
                Fr=fieldsToRemove{idxR};
                sinusoidJson.(Hs) = rmfield(sinusoidJson.(Hs),Fr);
              end              
            end

            %Remove the H field, since we cannot encode complex numbers 
            %into json
            for idxH=1:1:length(analysisNames)
              Hs=analysisNames{idxH};


              sinusoidJson.(Hs).units.gain = ...
                [auroraData.Data.Fin.Unit,'/',auroraData.Data.Lin.Unit];
              sinusoidJson.(Hs).units.phase = 'radians';
              sinusoidJson.(Hs).units.storage = ...
                [auroraData.Data.Fin.Unit,'/',auroraData.Data.Lin.Unit];
              sinusoidJson.(Hs).units.loss = ...
                [auroraData.Data.Fin.Unit,'s/',auroraData.Data.Lin.Unit];
              sinusoidJson.(Hs).units.coherenceSq = '';
            end

            for idxH=1:1:length(analysisNames)
              Hs=analysisNames{idxH};
              sinusoidJson.FS.(Hs) = segData.FS.(Hs);
              sinusoidJson.FS.(Hs) = rmfield(sinusoidJson.FS.(Hs),'H');


              
              sinusoidJson.FS.(Hs).length = ...
                rmfield(sinusoidJson.FS.(Hs).length,'L');
              sinusoidJson.FS.(Hs).length = ...
                rmfield(sinusoidJson.FS.(Hs).length,'LinvFT');
              
              sinusoidJson.FS.(Hs).force  = ...
                rmfield(sinusoidJson.FS.(Hs).force,'F');
              sinusoidJson.FS.(Hs).force  = ...
                rmfield(sinusoidJson.FS.(Hs).force,'FinvFT');
            end

            lengthSummary = ...
              getSummaryStatistics(auroraData.Data.Lin.Values(dataIndex,1));
            forceSummary = ...
              getSummaryStatistics(auroraData.Data.Fin.Values(dataIndex,1));
            temperatureSummary = ...
              getSummaryStatistics(auroraData.Data.Aux1_C.Values(dataIndex,1));

            sinusoidJson.summary.length       = lengthSummary;
            sinusoidJson.summary.force        = forceSummary;
            sinusoidJson.summary.temperature  = temperatureSummary;
            sinusoidJson.unit.length          = auroraData.Data.Lin.Unit;
            sinusoidJson.unit.force           = auroraData.Data.Fin.Unit;
            sinusoidJson.unit.temperature     = 'C';
            sinusoidJson.unit.time            = auroraData.Data.Time.Unit;
            sinusoidJson.channel.length       = 'Lin';
            sinusoidJson.channel.force        = 'Fin';
            sinusoidJson.channel.temperature  = 'Aux 1';


            setSinusoidJson(indexIntoSetOfSegments).sinusoid = sinusoidJson;
             

          end
          %%
          % Inspect Fourier series
          %%
          flag_inspectFourierFit=0;
          Hs='H2';
          if(flag_inspectFourierFit==1)
            fig_FS=figure;

            Tperiod_ms = 1000/sinusoidFit.frequency_Hz;
            nPeriodMax = sinusoidFit.duration_ms*(0.001)*sinusoidFit.frequency_Hz;
            nPeriod = min(4,nPeriodMax);

            indexPeriod = ...
              find(segData.time >= sinusoidFit.time_ms ... 
                 & segData.time <= (sinusoidFit.time_ms+nPeriod*Tperiod_ms));

            subplot(1,2,1)
              plot(segData.time(indexPeriod),segData.(Hs).x(indexPeriod),...
                '-','Color',[1,1,1].*0.75,...
                'LineWidth',1);
              hold on;
              plot(segData.time(indexPeriod),...
                   segData.FS.(Hs).length.LinvFT(indexPeriod),'-k');
              hold on;
              box off;
              xlabel(sprintf(  'Time (%s)',auroraData.Data.Time.Unit));
              ylabel(sprintf('Length (%s)',auroraData.Data.Lin.Unit));

            subplot(1,2,2);
              plot(segData.time(indexPeriod),segData.(Hs).y(indexPeriod),'-',...
                'Color',[1,1,1].*0.75,...
                 'LineWidth',1);
              hold on;
              plot(segData.time(indexPeriod),...
                   segData.FS.(Hs).force.FinvFT(indexPeriod),'-k');
              hold on;
              box off;
              xlabel(sprintf(  'Time (%s)',auroraData.Data.Time.Unit));
              ylabel(sprintf('Force (%s)',auroraData.Data.Fin.Unit));

            close(fig_FS);
          end
          %%
          % Plot
          %%
            figure(figSegments)

            Tperiod_ms = 1000/sinusoidFit.frequency_Hz;
            nPeriodMax = sinusoidFit.duration_ms...
                        *ms2s*sinusoidFit.frequency_Hz;
            nPeriod = min(4,nPeriodMax);            

            indexPeriod = ...
              find(segData.time >= sinusoidFit.time_ms ... 
                 & segData.time <= (sinusoidFit.time_ms+nPeriod*Tperiod_ms));

            subplot('Position',...
              reshape(subPlotPanelSegment(indexIntoSetOfSegments,2,:),1,4));

              plot(segData.time(indexPeriod),...
                   segData.x(indexPeriod),'-','Color',[1,1,1].*0.75,...
                   'LineWidth',1);
              hold on;
              plot(segData.time(indexPeriod),...
                   segData.FS.(Hs).length.LinvFT(indexPeriod),'-k');
              hold on;
              box off;

              ax = gca; 
              xlim(ax, xlim(ax) + [-1, 1] * diff(xlim(ax)) * 0.05); 
              ylim(ax, ylim(ax) + [-1, 1] * diff(ylim(ax)) * 0.05); 

              xlabel(sprintf(  'Time (%s)',auroraData.Data.Time.Unit));
              ylabel(sprintf('Length (%s)',auroraData.Data.Lin.Unit));
            
            title(sprintf('(%i,2). Length Data and FS',idxSeg));

            subplot('Position',...
              reshape(subPlotPanelSegment(indexIntoSetOfSegments,3,:),1,4));

              plot(segData.time(indexPeriod),...
                   segData.(Hs).y(indexPeriod),'-','Color',[1,1,1].*0.75,...
                   'LineWidth',1);
              hold on;
              plot(segData.time(indexPeriod),...
                   segData.FS.(Hs).force.FinvFT(indexPeriod),'-k');
              hold on;
              box off;
              
              ax = gca; 
              xlim(ax, xlim(ax) + [-1, 1] * diff(xlim(ax)) * 0.05); 
              ylim(ax, ylim(ax) + [-1, 1] * diff(ylim(ax)) * 0.05); 

              xlabel(sprintf(  'Time (%s)',auroraData.Data.Time.Unit));
              ylabel(sprintf('Force (%s)',auroraData.Data.Fin.Unit));

            title(sprintf('(%i,3). Force Data and FS',idxSeg));

            subplot('Position',...
              reshape(subPlotPanelSegment(indexIntoSetOfSegments,4,:),1,4));

              idxA = find(segData.(Hs).frequencyHz ...
                          < sinusoidFit.frequency_Hz,1,'last');

              idxB = find(segData.(Hs).frequencyHz ...
                          > sinusoidFit.frequency_Hz,1,'first');
              
              if(indexIntoSetOfSegments==15)
                here=1;
              end

              if(idxA==idxB)
                idxBWK2=[1;1;1].*idxA + [-1;0;-1].*idxA;
              else
                idxBWK2=[idxA:idxB]';
              end



              yyaxis left;
                plot(segData.(Hs).frequencyHz(idxBWK2),...
                     segData.(Hs).gain(idxBWK2),...
                     'DisplayName','Welch');
                hold on;
                plot(segData.FS.(Hs).frequencyHz(1),...
                     segData.FS.(Hs).gain(1),...
                     'o','Color',[0,0,1],'MarkerFaceColor',[0,0,1],...
                     'DisplayName','FT');
                hold on;
                box off;

                ax = gca; 
                xlim(ax, xlim(ax) + [-1, 1] * diff(xlim(ax)) * 0.05); 
                ylim(ax, ylim(ax) + [-1, 1] * diff(ylim(ax)) * 0.05);                 

                ylimits =ylim;
                if(max(ylimits)>0)
                  ylim([0,max(ylimits)]);
                else
                  ylim([min(ylimits),0]);
                end
                xlabel('Frequency (Hz)');
                ylabel(sprintf('Gain (%s/%s)',...
                        auroraData.Data.Fin.Unit,...
                        auroraData.Data.Lin.Unit));
              
              yyaxis right;
                plot(segData.(Hs).frequencyHz(idxBWK2),...
                     segData.(Hs).phase(idxBWK2).*(180/pi),...
                     'DisplayName','Welch');
                hold on;
                plot(segData.FS.(Hs).frequencyHz(1),...
                     segData.FS.(Hs).phase(1).*(180/pi),...
                     'd','Color',[1,0,0],'MarkerFaceColor',[1,0,0],...
                     'DisplayName','FT');
                hold on;
                box off;      

                ax = gca; 
                xlim(ax, xlim(ax) + [-1, 1] * diff(xlim(ax)) * 0.05); 
                ylim(ax, ylim(ax) + [-1, 1] * diff(ylim(ax)) * 0.05);  

                ylimits =ylim;
                if(max(ylimits)>0)
                  ylim([0,max(ylimits)]);
                else
                  ylim([min(ylimits),0]);
                end
                ylabel('Phase (deg)');
                %legend;

              title(sprintf('(%i,4). Frequency-Response',idxSeg));                         

            subplot('Position',...
              reshape(subPlotPanelSegment(indexIntoSetOfSegments,5,:),1,4));              

              plot(segData.FS.(Hs).frequencyHz,...
                   segData.FS.(Hs).force.hk,'-','Color',[0,0,0]);
              hold on;
              plot(segData.FS.(Hs).frequencyHz,...
                   segData.FS.(Hs).force.hk,'o','Color',[0,0,0],...
                   'MarkerFaceColor',[1,1,1]);
              hold on;
              text(segData.FS.(Hs).frequencyHz(end),...
                   segData.FS.(Hs).force.hk(1),...
                   sprintf('hk(1): %1.3f\nD: %1.6f',...
                   segData.FS.(Hs).force.hk(1),segData.FS.(Hs).force.D),...
                   'HorizontalAlignment','right',...
                   'VerticalAlignment','top',...
                   'FontSize',7);
              hold on;
              box off;
              xlabel('Frequency (Hz)');
              ylabel('Relative Magnitude');
              ylim([0,1]);
              title(sprintf('(%i,5). Fourier-Coeff. Rel. Mag',idxSeg))

            subplot('Position',...
              reshape(subPlotPanelSegment(indexIntoSetOfSegments,6,:),1,4));                  
              plot(segData.(Hs).frequencyHz(idxBWK2),...
                   segData.(Hs).coherenceSq(idxBWK2));
              box off;
              xlabel('Frequency (Hz)');
              ylabel('Coherence-Sq');
              ylim([0,1]);
              hold on;
              title(sprintf('(%i,6). Coherence-Sq',idxSeg))              
                

        end
        clear('segData');

        
      end
    
      %
      % Save the segment plot
      %  
      figSegments=configPlotExporter(figSegments, ...
                                     pageWidthSegment, ...
                                     pageHeightSegment);

      idxJsonExt  = strfind(experimentJson.measurements{idxTrial},'.json');
      idxJsonExt = idxJsonExt-1;
      figFileName = experimentJson.measurements{idxTrial}(1:idxJsonExt);

      figSegmentName = ['fig',analysisKeywordsFileName,...
                      'FrequencyResponse_',...
                      figFileName];      

      print('-dpdf', fullfile(outputPlotDir,[figSegmentName,'.pdf']));  
      saveas(figSegments,fullfile(outputPlotDir,[figSegmentName,'.fig']));      
      close(figSegments);
      

      %
      % Save the json file
      %  

      outputJsonDir = fullfile(projectFolders.output600A_json,folderName);
      if(~exist(outputJsonDir,'dir'))
        mkdir(outputJsonDir);
      end
      
      
      setSinusoidStr = jsonencode(setSinusoidJson);

      jsonFileName = ['analysis',analysisKeywordsFileName,...
                      experimentJson.measurements{idxTrial}];
      jsonFilePath=fullfile(outputJsonDir,jsonFileName);

      fidJson         = fopen(jsonFilePath,'w');
      fprintf(fidJson,setSinusoidStr);
      fclose(fidJson);  
   
    
      clear('setSinusoidJson');
      clear('sinusoidJson');
  
      pause(1);
  
    end
  end
  
  fclose(fidLogFile);
  

  figTimeSeries=configPlotExporter(figTimeSeries, ...
            pageWidthTimeSeries, pageHeightTimeSeries);
  fileName =  ['fig',analysisKeywordsFileName,...
               'TimeSeries_',folderName];
  print('-dpdf', fullfile(outputPlotDir,[fileName,'.pdf']));  
  saveas(figTimeSeries,fullfile(outputPlotDir,[fileName,'.fig']));
  close(figTimeSeries);  
end
success=1;


