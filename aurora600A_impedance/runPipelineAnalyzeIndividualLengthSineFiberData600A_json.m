function success = ...
  runPipelineAnalyzeIndividualLengthSineFiberData600A_json(...
    folderName, fileKeyWord,settings,...
    projectFolders)

success=0;
mm2m = 0.001;
s2ms=1000;


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
    
      for indexIntoSetOfSegments = 1:1:length(setOfSegments)
      
        idxSeg = setOfSegments(indexIntoSetOfSegments,1);
        fprintf('\t%i/%i\tSegment count\n',indexIntoSetOfSegments,length(setOfSegments));
        %%
        %Extract the indicies to plot
        %%
        timeStartNoPad = trialJson.segments(idxSeg).time_ms(1);
        timeEndNoPad   = trialJson.segments(idxSeg).time_ms(2);
        dataIndexNoPad = find( auroraData.Data.Time.Values >= timeStartNoPad ...
                & auroraData.Data.Time.Values <= timeEndNoPad); 

        timeStart = trialJson.segments(idxSeg).time_ms(1)-settings.paddingTimeMS;
        timeEnd   = trialJson.segments(idxSeg).time_ms(2)+settings.paddingTimeMS;
        dataIndex = find( auroraData.Data.Time.Values >= timeStart ...
                & auroraData.Data.Time.Values <= timeEnd); 

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

          fittingSettings.var          = 'length';
          fittingSettings.scaling      = 1;
          fittingSettings.paramScaling = [];

          xMiddle=0.5*(max(fittingSettings.length)...
                      +min(fittingSettings.length));
          xDelta = 0.5*(max(fittingSettings.length)...
                       -min(fittingSettings.length));

          frequency_Hz = trialJson.segments(idxSeg).meta_data.frequency_Hz;
          period_ms = (1/frequency_Hz)*s2ms;

          idxStart = ...
            find(auroraData.Data.Lin.Values(dataIndex,1) ...
                                  > (xMiddle+0.1*xDelta),1,'first');

          idxStart=max(idxStart-1,1);

          timeStartA=auroraData.Data.Time.Values(dataIndex(idxStart));
          timeStartB=trialJson.segments(idxSeg).time_ms(1);

          timeStart=timeStartB;
          if(timeStartA<timeStartB)
            timeStart=timeStartA;
          end

          fittingSettings.paramOffset = ...
            [auroraData.Data.Time.Values(dataIndex(idxStart)),...
            xMiddle,...
            trialJson.segments(idxSeg).meta_data.frequency_Hz,...
            trialJson.segments(idxSeg).meta_data.length_Lo];

          fittingSettings.paramScaling = [ ...
            period_ms,...
            xMiddle*0.5,...
            trialJson.segments(idxSeg).meta_data.frequency_Hz*0.10,...
            trialJson.segments(idxSeg).meta_data.length_Lo*0.10];  

          params = [0,0,0,0];
          
          fittingSettings.var = 'length';                

          if(idxSeg==42)
            here=1;
          end          
          [errV,fittedSine] = ...
            calcErrorOfSinusoid600A(params,fittingSettings);
  
          errFcn = @(arg)calcErrorOfSinusoid600A(arg,fittingSettings);
          
          x = params;
          xDelta = 1;
          iterLsq=1;
          options = optimoptions('lsqnonlin','Display','off');

          if(indexIntoSetOfSegments==2 && indexSetOfTrials==2)
            here=1;
          end

          while(max(xDelta)>0.005 && iterLsq < 100)
            [x,resnorm,res,exitflag,output,lambda,jac] ...
              = lsqnonlin(errFcn,params,[],[],options);
            xDelta = abs(x-params);              
            params=x;
            iterLsq=iterLsq+1;
          end

          assert(max(xDelta) < 0.005, ...
            'Error: failed to fit the length sinusoid data');
          

          xUpd = x.*fittingSettings.paramScaling+fittingSettings.paramOffset;




          [errV,fittedSine] = calcErrorOfSinusoid600A(x,fittingSettings);

          sinusoidFit = ...
            struct('time_ms',xUpd(1),...
                   'length_mm',xUpd(2),...
                   'frequency_Hz',xUpd(3),...
                   'amplitude_Lo',xUpd(4),...
                   'duration_ms',trialJson.segments(idxSeg).meta_data.duration_ms,...
                   'resnorm',resnorm,...
                   'exitflag',exitflag);   

          

          if(strcmp(fittingSettings.var,'length')==1)

            figure(figSegments)
            subplot('Position',...
              reshape(subPlotPanelSegment(indexIntoSetOfSegments,1,:),1,4));

              Tperiod_ms = 1000/sinusoidFit.frequency_Hz;
              nPeriodMax = sinusoidFit.duration_ms*(0.001)*sinusoidFit.frequency_Hz;
              nPeriod = min(4,nPeriodMax);              

              indexPeriod = ...
                find(fittingSettings.time >= sinusoidFit.time_ms ... 
                   & fittingSettings.time <= (sinusoidFit.time_ms+nPeriod*Tperiod_ms));

              plot( fittingSettings.time(indexPeriod),...
                    fittingSettings.(fittingSettings.var)(indexPeriod),...
                    '-','Color',[1,1,1].*0.75,'LineWidth',1);
              hold on;

              indexPeriod = ...
                find(fittedSine.x >= sinusoidFit.time_ms ... 
                   & fittedSine.x <= (sinusoidFit.time_ms+nPeriod*Tperiod_ms));

              plot(fittedSine.x(indexPeriod),...
                   fittedSine.y(indexPeriod),'-','Color',[0,0,1]);
              hold on;
              ax = gca; 
              xlim(ax, xlim(ax) + [-1, 1] * diff(xlim(ax)) * 0.05); 
              ylim(ax, ylim(ax) + [-1, 1] * diff(ylim(ax)) * 0.05); 
              box off;

              text(fittedSine.x(indexPeriod(end)),...
                   fittedSine.y(indexPeriod(end)),...
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
                pageWidthSegment, pageHeightSegment);

      figSegmentName = ['fig',analysisKeywordsFileName,...
                      'FrequencyResponse_',...
                      experimentJson.measurements{idxTrial}];      

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


