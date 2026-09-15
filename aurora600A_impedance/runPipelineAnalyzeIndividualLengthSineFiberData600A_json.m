function success = ...
  runPipelineAnalyzeIndividualLengthSineFiberData600A_json(...
    folderName, fileKeyWord,modelSeries, ...
    analysisJsonSetting_fopen,settings,...
    projectFolders)

success=0;
mm2m = 0.001;



flag_readHeader       = 1;


analysisKeywords={'Impedance-Individual-Length-Sine'};
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
  % Plot the segment data
  %  
  numberOfHorizontalPlotColumnsGeneric  = length(setOfTrials);
  numberOfVerticalPlotRowsGeneric       = 2*totalNumberOfSegmentsToPlot;

  % 1. Time domain
  % 2. gain
  % 3. phase
  % 4. coherence  
  plotWidth                 = ones(1,numberOfHorizontalPlotColumnsGeneric).*6;
  plotHeight                = ones(numberOfVerticalPlotRowsGeneric,1).*6;
  plotHorizMarginCm         = 3;
  plotVertMarginCm          = 2;
  baseFontSize              = 12;
  
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
      % Process each of the segments
      %%
    
    
      for indexIntoSetOfSegments = 1:1:length(setOfSegments)
      
        idxSeg = setOfSegments(indexIntoSetOfSegments,1);
    
        %%
        %Extract the indicies to plot
        %%
        timeStart = trialJson.segments(idxSeg).time_ms(1)-settings.paddingTimeMS;
        timeEnd   = trialJson.segments(idxSeg).time_ms(2)+settings.paddingTimeMS;
        dataIndex = find( auroraData.Data.Time.Values >= timeStart ...
                & auroraData.Data.Time.Values <= timeEnd); 

        
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
        % Evaluate frequency response   
        %%
        x = auroraData.Data.Lin.Values(dataIndex,1);
        xMean = mean(x);
        x = x - xMean;      

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
        y=y-yBias;
        
        yMean = mean(y);
        y = y-yMean;

        xyDataIsValid =0;
  
  
        flag_peekXY=0;
        if(flag_peekXY==1)
          flag_peekXY=figure;
          yyaxis left;
          plot(auroraData.Data.Time.Values(dataIndex),x);
          hold on;
          xlabel('Time (ms)');
          ylabel('Length (mm)');
          
          yyaxis right;
          plot(auroraData.Data.Time.Values(dataIndex),y);
          hold on;
          ylabel('Force (mN)');
          here=1;
        end
  
    
        if(length(y)>10 && length(x)>10)
          xyDataIsValid=1;
    
          fittingSettings.time  = auroraData.Data.Time.Values(dataIndex);
          fittingSettings.length=auroraData.Data.Lin.Values(dataIndex,1);
          fittingSettings.force =auroraData.Data.Fin.Values(dataIndex,1);
          fittingSettings.timeScaling=0.001; %Convert to seconds
          fittingSettings.duration_ms= ...
            trialJson.segments(idxSeg).meta_data.duration_ms;

          fittingSettings.var = 'length';
          fittingSettings.scaling=1;
          fittingSettings.paramScaling=[];

          sinusoidFit.length = ...
            struct('time_ms',nan,...
                   'length_mm',nan,...
                   'frequency_Hz',nan,...
                   'amplitude_mm',nan,...
                   'duration_ms',nan);

          sinusoidFit.force = ...
            struct('time_ms',nan,...
                   'force_mN',nan,...
                   'frequency_Hz',nan,...
                   'amplitude_mN',nan,...
                   'duration_ms',nan);

          vars = {'length','force'};

          for idxV = 1:1:length(vars)
            switch idxV 
              case 1
                Lo = experimentJson.experiment.length_mm;
                fittingSettings.paramScaling = [ ...
                  trialJson.segments(idxSeg).time_ms(1),...
                  xMean,...
                  trialJson.segments(idxSeg).meta_data.frequency_Hz,...
                  trialJson.segments(idxSeg).meta_data.length_Lo*Lo];  
                params = ones(size(fittingSettings.paramScaling));
                fittingSettings.var = 'length';                
              case 2
                amplitude = (max(y)-min(y)).*0.5;
                fittingSettings.paramScaling = [ ...
                  trialJson.segments(idxSeg).time_ms(1),...
                  yMean,...
                  trialJson.segments(idxSeg).meta_data.frequency_Hz,...
                  amplitude];  
                params = ones(size(fittingSettings.paramScaling));
                fittingSettings.var = 'force';                
              otherwise
                assert(0,'Error: unexpected value of idxV');
            end
              
            [errV,fittedSine] = calcErrorOfSinusoid600A(params,fittingSettings);
    
            %fittingSettings.scaling = norm(errV);
  
            errFcn = @(arg)calcErrorOfSinusoid600A(arg,fittingSettings);
            
            x = params;
            xDelta = 1;
            iterLsq=1;
            while(max(xDelta)>0.005 && iterLsq < 100)
              [x,resnorm,res,exitflag,output,lambda,jac] ...
                = lsqnonlin(errFcn,params);
              xDelta = abs(x-params);              
              params=x;
              iterLsq=iterLsq+1;
            end

            xUpd = x.*fittingSettings.paramScaling;

            switch idxV
              case 1
                sinusoidFit.length = ...
                  struct('time_ms',xUpd(1),...
                         'length_mm',xUpd(2),...
                         'frequency_Hz',xUpd(3),...
                         'amplitude_mm',xUpd(4),...
                         'duration_ms',trialJson.segments(idxSeg).meta_data.duration_ms,...
                         'resnorm',resnorm,...
                         'exitflag',exitflag);                
              case 2
                sinusoidFit.force = ...
                  struct('time_ms',xUpd(1),...
                         'force_mN',xUpd(2),...
                         'frequency_Hz',xUpd(3),...
                         'amplitude_mN',xUpd(4),...
                         'duration_ms',trialJson.segments(idxSeg).meta_data.duration_ms,...
                         'resnorm',resnorm,...
                         'exitflag',exitflag);
                
              otherwise
                assert(0,'Error: unexpected value of idxV')
            end
            [errV,fittedSine] = calcErrorOfSinusoid600A(x,fittingSettings);
  

            
            flag_checkFit=1;
            if(flag_checkFit==1)
              fig_checkFit=figure;
              plot( fittingSettings.time,...
                    fittingSettings.(fittingSettings.var),...
                    '-','Color',[1,1,1].*0.5);
              hold on;

              switch idxV
                case 1
                  lineColor=[0,0,1];
                case 2
                  lineColor=[1,0,0];                  
                otherwise
                  assert(0,'Error: unexpected value for idxV');
              end
              plot(fittedSine.x,fittedSine.y,'-','Color',lineColor);
              hold on;
              xlabel('Time (ms)');
              ylabel(fittingSettings.var);
              here=1;
            end
          end
  
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
      jsonFileName = [settings.prependToJsonFileName,...
                      experimentJson.measurements{idxTrial}];
      fidJson = fopen(fullfile(outputJsonDir,jsonFileName),...
                      analysisJsonSetting_fopen);
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


