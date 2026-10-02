function success = ...
  runPipelineAnalyzeIndividualLengthSineFiberData600A_json(...
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

setOfTrialTypes = {'impedance_calibration'};
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
        setOfSegments=setOfSegmentsOverride;
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
        for idxED=2:1:(length(indexEnableDisable))
          if(   indexMid > indexEnableDisable(idxED-1)...
             && indexMid < indexEnableDisable(idxED))
            indexStart = indexEnableDisable(idxED-1)+1;
            indexEnd   = indexEnableDisable(idxED)-1;
          end
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

        [indexStartNoPad, indexEndNoPad ] = ...
          searchForSegmentBoundary600A(...
             indexStart, indexEnd, ...
             trialJson.segments(idxSeg).meta_data.frequency_Hz,...
             settings.paddingTimeSinusoidMS,...
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
          fittingSettings.scaling      = 1;
          fittingSettings.paramScaling = [];
          fittingSettings.lambda       = 0.1;


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
            round(period*auroraData.Setup_Parameters.A_D_Sampling_Rate.Value);



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
    
          indexTol = min(round(numberOfSamplesPerPeriod*0.5),20);

          lb = [max(fittingSettings.paramOffset(1)-indexTol,...
                    1),...
                lengthMean*0.5,...
                frequency_Hz.*0.75,...
                lengthChange*0,...
                (fittingSettings.number_of_elements-numberOfSamplesPerPeriod)];

          lbS = (lb-fittingSettings.paramOffset)...
               ./fittingSettings.paramScaling;

          idxTimeMax = length(fittingSettings.time)...
                      -fittingSettings.number_of_elements;

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

          nCycles = ceil(frequency_Hz*(fittingSettings.duration_ms*ms2s));
          assert(nCycles > 0, 'Error: this segment has less than 1 cycle');

          fitCycles = numberOfCyclesToFit;
          if(fitCycles > nCycles)
            fitCycles = min(1, round(nCycles/2));
          end

          options = optimoptions( 'lsqnonlin',...
                                  'Algorithm','trust-region-reflective',...
                                  'Display','off');
          
          flag_completeIntervalFitted=0;
          idxOpt=3;
          idxSamples=5;

          lbSIter = lbS;
          ubSIter = ubS;
          optParams=zeros(1,length(ubS));

          optVarSchedule=[3,2,4,1,3,2,4,1];
          iterCycle=1;


          while(flag_completeIntervalFitted == 0 )
            
            if(fitCycles==nCycles)
              flag_completeIntervalFitted=1;
            end


            for i=1:1:length(optVarSchedule)
              
              idxOpt=optVarSchedule(i);
                     
              enableFitting=0;
              switch fittingSettings.applyAlgorithm{idxOpt}
                case 'first'
                  if(iterCycle==1)
                    enableFitting=1;
                  end
                case 'all'
                  enableFitting=1;
                case 'last'
                  if(fitCycles==nCycles)
                    enableFitting=1;
                  end
                otherwise
                  assert(0,'Error: unrecognized application condition');
              end

              if(enableFitting==1)
                fittingSettings.optVarIndex=idxOpt;
    
                errFcn = ...
                  @(argX)calcErrorOfSinusoid600A(argX,fittingSettings);
    
                x0=0;
                [errV0,errDot0,mdl0]=errFcn(x0);
    
                switch fittingSettings.algorithm{idxOpt}                
                  case 'scan'
                    varName=fittingSettings.var;

                    idxDataMax = fittingSettings.optInterval(2);

                    idxDotMax = idxDataMax-length(mdl0.y);
                    idxStartV=zeros(idxDotMax,1);
                    dotStartV=zeros(idxDotMax,1);
                    yMean = fittingSettings.paramOffset(2);

                    mdlY=mdl0.y-yMean;
                    dataY=fittingSettings.(varName)-yMean;

                    for idxDot=lb(1):1:ub(1)
                      idxStartV(idxDot)=idxDot;                      
                      idxB=length(mdl0.y)+idxDot-1;
                      dotStartV(idxDot)=dot(mdlY,...
                                            dataY(idxDot:idxB));   
                      fig_debugDot=0;
                      if(fig_debugDot==1)
                        figDebugDot=figure;
                          plot(mdlY);
                          hold on;
                          plot(dataY(idxDot:idxB));
                          hold on;
                          pause(0.01);
                        close(figDebugDot);
                      end

                    end

                    [maxDot, idxDotMax]=max(dotStartV);
                    timeBest=fittingSettings.time(idxDotMax);

                    fittingSettings.paramOffset(1)=idxDotMax;
                    x=0;

                    fig_debugScan=1;
                    if(fig_debugScan==1)
                      figScan=figure;
                      subplot(1,2,1);
                        plot(fittingSettings.time,...
                             fittingSettings.(varName),...
                             '-','Color',[1,1,1].*0.5);                        
                        hold on;
                        plot(fittingSettings.time(idxDotMax),...
                             fittingSettings.(varName)(idxDotMax),...
                             'o','Color',[1,0,0]);                        
                        hold on;                       
                        plot(mdl0.x-mdl0.x(1)+timeBest,...
                             mdl0.y,'-b');
                        xlabel('Time');
                        ylabel(varName);
                      subplot(1,2,2);
                        plot(idxStartV,dotStartV);
                        hold on;
                        plot(idxDotMax,maxDot,'or');
                        xlabel('Starting Index');
                        ylabel('Dot Product');
                      close(figScan);
                    end                    

%                     %Used for identifying the starting index of the 
%                     %data.
%                     errDotBest=errDot0;
%                     argBest=x0;
%                     indexBest=fittingSettings.paramOffset(idxOpt);
%                     indexV = [];
%                     errDotV=[];
%                     for j = lb(idxOpt):1:ub(idxOpt)
%                       arg = (j-fittingSettings.paramOffset(idxOpt)) ...
%                            /fittingSettings.paramScaling(idxOpt);
%                       [errV,errDot,mdl]=errFcn(arg);
%                       indexV=[indexV,arg];
%                       errDotV=[errDotV,errDot];
%                       fprintf('%i\t%1.3e\n',j,errDot);
%                       if(errDot > errDotBest)
%                         errDotBest=errDot;
%                         argBest=arg;
%                         indexBest=j;
%                         fprintf('\t*%i\t%1.3e\n',j,errDot);
%                       end
%                     end
%                     fittingSettings.paramOffset(idxOpt)=indexBest;
% 

  
  
                  case 'lsqnonlin'
                    [x,resnorm,res,exitflag,output,lambda,jac] ...
                      = lsqnonlin(errFcn,optParams(idxOpt),...
                                  lbSIter(idxOpt),ubSIter(idxOpt),...
                                  options); 
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
                [errV1,errDot1,mdl1]=errFcn(x);
    
  

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
  
              index1    = round(fitCycles*numberOfSamplesPerPeriod);
              if(index1>length(dataIndexNoPad))
                index1=length(dataIndexNoPad);
              end
              
              
              fittingSettings.optInterval(2)=...
                   [dataIndexNoPad(index1)-dataIndex(1)];
              
              fittingSettings.number_of_elements = ...
                diff(fittingSettings.optInterval)+1;
  
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

       

          x=[0,0,0,0,0];
          fittingSettings.optVarIndex=[1,2,3,4,5];
          [errV,errDot,fittedSine]=calcErrorOfSinusoid600A(x,fittingSettings);

          index0 = fittingSettings.paramOffset(1);
          index1 = index0+fittingSettings.paramOffset(5);

          time0=auroraData.Data.Time.Values(index0+indexStart-1);
          time1=auroraData.Data.Time.Values(index1+indexStart-1);

          sinusoidFit = ...            
            struct('time_ms',time0,...
                   'indexStart',index0,...
                   'indexEnd',index1,...
                   'length_mm',fittingSettings.paramOffset(2),...
                   'frequency_Hz',fittingSettings.paramOffset(3),...
                   'amplitude_Lo',fittingSettings.paramOffset(4),...
                   'duration_ms',time1-time0,...
                   'resnorm',resnorm,...
                   'exitflag',exitflag);   

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

              indexA=sinusoidFit.indexStart;
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

          timeStart = sinusoidFit.time_ms;
          timeEnd   = timeStart+sinusoidFit.duration_ms;

          dataIndex = find( auroraData.Data.Time.Values >= timeStart ...
                          & auroraData.Data.Time.Values <= timeEnd); 

          preTimeStart = timeStart-settings.paddingTimeMS;
          preTimeEnd   = timeStart;
          preDataIndex = [];
    
          if(preTimeEnd > 0)
            preDataIndex = find( auroraData.Data.Time.Values >= preTimeStart ...
                    & auroraData.Data.Time.Values <= preTimeEnd); 
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
          segData.H = evaluateGainPhaseCoherenceSq(...
                          segData.time,...
                          segData.x,...
                          segData.y,...
                          segData.bandwidth_Hz,...
                          segData.sampleFrequency,...
                          settings.coherenceSquaredThreshold,...
                          0);


          %%
          %
          % Use Kawai's approach of just extracting out the Fourier
          % coefficients directly
          %
          %%          
          
          ms2s = 0.001;          
          segData.FS.frequency   = zeros(nHarmonics,1);
          segData.FS.frequencyHz = zeros(nHarmonics,1);          
          segData.FS.length.L    = zeros(nHarmonics,1);
          segData.FS.length.hk   = zeros(nHarmonics,1);
          segData.FS.length.I    = 0;          
          segData.FS.length.D    = 0;
          segData.FS.length.LinvFT = [];

          segData.FS.force.F     = zeros(nHarmonics,1);
          segData.FS.force.hk    = zeros(nHarmonics,1);
          segData.FS.force.I     = 0;          
          segData.FS.force.D     = 0;
          segData.FS.force.FinvFT = [];
          
          for idxN =1:1:nHarmonics
            segData.FS.frequency(idxN)   = ...
              sinusoidFit.frequency_Hz*(2*pi)*idxN;
            segData.FS.frequencyHz(idxN) = ...
              sinusoidFit.frequency_Hz*idxN;
            
            omega_Hz= sinusoidFit.frequency_Hz*idxN;
            omega   = omega_Hz*(2*pi);
            
            Tcyc    = 1/omega_Hz;
            nCycles = (sinusoidFit.duration_ms.*ms2s)/Tcyc;
            A      = (2/(nCycles*Tcyc));
            timeSeg = (segData.time-sinusoidFit.time_ms).*ms2s;

            %Real component
            sineWt = sin( omega.*(timeSeg) );
            l_dot_sineWt = sineWt.*segData.x;
            f_dot_sineWt = sineWt.*segData.y;

            fcnSineL = @(argX)interp1(timeSeg,l_dot_sineWt,argX,'linear');
            L_real = integral(fcnSineL,timeSeg(1),timeSeg(end)); 
            L_real = A.*L_real;

            fcnSineF = @(argX)interp1(timeSeg,f_dot_sineWt,argX,'linear');
            F_real = integral(fcnSineF,timeSeg(1),timeSeg(end)); 
            F_real = A.*F_real;

            %Complex component
            cosWt = cos( omega.*(timeSeg) );
            l_dot_cosWt = cosWt.*segData.x;
            f_dot_cosWt = cosWt.*segData.y;

            fcnCosL = @(argX)interp1(timeSeg,l_dot_cosWt,argX,'linear');
            L_imag = integral(fcnCosL,timeSeg(1),timeSeg(end)); 
            L_imag = A.*L_imag;

            fcnCosF = @(argX)interp1(timeSeg,f_dot_cosWt,argX,'linear');
            F_imag = integral(fcnCosF,timeSeg(1),timeSeg(end)); 
            F_imag = A.*F_imag;        
            
            %Save the complex coefficients
            segData.FS.length.L(idxN) = complex(L_real,L_imag);
            segData.FS.force.F(idxN)  = complex(F_real,F_imag);
            
            segData.FS.length.I= ...
              segData.FS.length.I + (L_real*L_real + L_imag*L_imag);

            segData.FS.force.I= ...
              segData.FS.force.I + (F_real*F_real + F_imag*F_imag);

            %Build the FS time domain signals
            if(isempty(segData.FS.length.LinvFT))
              segData.FS.length.LinvFT = L_real.*sineWt + L_imag.*cosWt;
            else
              segData.FS.length.LinvFT =  segData.FS.length.LinvFT ...
                                        + L_real.*sineWt + L_imag.*cosWt;
            end

            if(isempty(segData.FS.force.FinvFT))
              segData.FS.force.FinvFT = F_real.*sineWt + F_imag.*cosWt;
            else
              segData.FS.force.FinvFT =  segData.FS.force.FinvFT ...
                                        + F_real.*sineWt + F_imag.*cosWt;
            end


          end

          for idxN=1:1:nHarmonics
            segData.FS.force.hk(idxN) = abs(segData.FS.force.F(idxN))...
                                        ./sqrt(segData.FS.force.I);
            segData.FS.length.hk(idxN) = abs(segData.FS.length.L(idxN))...
                                         ./sqrt(segData.FS.length.I);
          end

          h1F = segData.FS.force.hk(1);
          segData.FS.force.D = sqrt(1-h1F'*h1F);

          h1L = segData.FS.length.hk(1);
          segData.FS.length.D = sqrt(1-h1L'*h1L);


          segData.FS.H = (segData.FS.force.F .* segData.FS.length.L)...
                       ./(segData.FS.length.L .* segData.FS.length.L);

          segData.FS.gain = abs(segData.FS.H);
          segData.FS.phase= angle(segData.FS.H);
          segData.FS.storage = segData.FS.gain .* cos(segData.FS.phase);
          segData.FS.loss    = segData.FS.gain .* sin(segData.FS.phase);

          %%
          % Populate and save the json structure
          %%
          if(isSegmentValid==1)

            sinusoidJson.interval = [timeStart,timeEnd];
            sinusoidJson.index    = idxSeg;
            sinusoidJson.type     = trialJson.segments(idxSeg).type;
            sinusoidJson.time     = auroraData.Data.Time.Values(dataIndex,1);
            sinusoidJson.length   = auroraData.Data.Lin.Values(dataIndex,1);
            sinusoidJson.force    = auroraData.Data.Fin.Values(dataIndex,1);  
            sinusoidJson.lengthMean  = segData.xMean;
            sinusoidJson.forceMean   = segData.yMean;
            sinusoidJson.forceBias   = segData.yBias;      
            sinusoidJson.nominal.time    = segData.timePrior;
            sinusoidJson.nominal.length  = segData.xPrior;
            sinusoidJson.nominal.force   = segData.yPrior; 


            sinusoidJson.H  = segData.H;   
            %Remove the H field, since we cannot encode complex numbers 
            %into json
            sinusoidJson.H = rmfield(sinusoidJson.H,'H');

            sinusoidJson.H.units.gain = ...
              [auroraData.Data.Fin.Unit,'/',auroraData.Data.Lin.Unit];
            sinusoidJson.H.units.phase = 'radians';
            sinusoidJson.H.units.storage = ...
              [auroraData.Data.Fin.Unit,'/',auroraData.Data.Lin.Unit];
            sinusoidJson.H.units.loss = ...
              [auroraData.Data.Fin.Unit,'s/',auroraData.Data.Lin.Unit];
            sinusoidJson.H.units.coherenceSq = '';

            sinusoidJson.FS = segData.FS;
            sinusoidJson.FS = rmfield(sinusoidJson.FS,'H');
            sinusoidJson.FS.length = rmfield(sinusoidJson.FS.length,'L');
            sinusoidJson.FS.force  = rmfield(sinusoidJson.FS.force,'F');
            sinusoidJson.FS.lengthSinusoidFit = sinusoidFit;
            
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
          if(flag_inspectFourierFit==1)
            fig_FS=figure;

            Tperiod_ms = 1000/sinusoidFit.frequency_Hz;
            nPeriodMax = sinusoidFit.duration_ms*(0.001)*sinusoidFit.frequency_Hz;
            nPeriod = min(4,nPeriodMax);

            indexPeriod = ...
              find(segData.time >= sinusoidFit.time_ms ... 
                 & segData.time <= (sinusoidFit.time_ms+nPeriod*Tperiod_ms));

            subplot(1,2,1)
              plot(segData.time(indexPeriod),segData.x(indexPeriod),...
                '-','Color',[1,1,1].*0.75,...
                'LineWidth',1);
              hold on;
              plot(segData.time(indexPeriod),...
                   segData.FS.length.LinvFT(indexPeriod),'-k');
              hold on;
              box off;
              xlabel(sprintf(  'Time (%s)',auroraData.Data.Time.Unit));
              ylabel(sprintf('Length (%s)',auroraData.Data.Lin.Unit));

            subplot(1,2,2);
              plot(segData.time(indexPeriod),segData.y(indexPeriod),'-',...
                'Color',[1,1,1].*0.75,...
                 'LineWidth',1);
              hold on;
              plot(segData.time(indexPeriod),...
                   segData.FS.force.FinvFT(indexPeriod),'-k');
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
            nPeriodMax = sinusoidFit.duration_ms*(0.001)*sinusoidFit.frequency_Hz;
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
                   segData.FS.length.LinvFT(indexPeriod),'-k');
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
                   segData.y(indexPeriod),'-','Color',[1,1,1].*0.75,...
                   'LineWidth',1);
              hold on;
              plot(segData.time(indexPeriod),...
                   segData.FS.force.FinvFT(indexPeriod),'-k');
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

              idxA = find(segData.H.frequencyHz < sinusoidFit.frequency_Hz,1,'last');

              idxB = find(segData.H.frequencyHz > sinusoidFit.frequency_Hz,1,'first');
              
              if(indexIntoSetOfSegments==15)
                here=1;
              end

              if(idxA==idxB)
                idxBWK2=[1;1;1].*idxA + [-1;0;-1].*idxA;
              else
                idxBWK2=[idxA:idxB]';
              end



              yyaxis left;
                plot(segData.H.frequencyHz(idxBWK2),...
                     segData.H.gain(idxBWK2),...
                     'DisplayName','Welch');
                hold on;
                plot(segData.FS.frequencyHz(1),...
                     segData.FS.gain(1),...
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
                plot(segData.H.frequencyHz(idxBWK2),...
                     segData.H.phase(idxBWK2).*(180/pi),...
                     'DisplayName','Welch');
                hold on;
                plot(segData.FS.frequencyHz(1),...
                     segData.FS.phase(1).*(180/pi),...
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

              plot(segData.FS.frequencyHz,...
                   segData.FS.force.hk,'-','Color',[0,0,0]);
              hold on;
              plot(segData.FS.frequencyHz,...
                   segData.FS.force.hk,'o','Color',[0,0,0],...
                   'MarkerFaceColor',[1,1,1]);
              hold on;
              text(segData.FS.frequencyHz(end),...
                   segData.FS.force.hk(1),...
                   sprintf('hk(1): %1.3f\nD: %1.6f',segData.FS.force.hk(1),segData.FS.force.D),...
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
              plot(segData.H.frequencyHz(idxBWK2),...
                   segData.H.coherenceSq(idxBWK2));
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


