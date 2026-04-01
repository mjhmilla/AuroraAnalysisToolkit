function success = plotExperimentalDataOverview610A_json(...
                          experimentsToProcess,...
                          keyWordFilter,...
                          settings,...
                          projectFolders)





for idxExp = 1:1:length(experimentsToProcess)

  disp(experimentsToProcess{idxExp});
  %
  % Scan through the data and count the number of trials and segments
  %
  expFolder = fullfile(projectFolders.data610A,...
                      experimentsToProcess{idxExp});

  expStr = fileread(fullfile(projectFolders.data610A,...
                              experimentsToProcess{idxExp},...
                             [experimentsToProcess{idxExp},'.json']));
  expJson = jsondecode(expStr);

  verbose=0;
  scanSummary = scanExperiment610A(experimentsToProcess{idxExp},...
                                   keyWordFilter,...
                                   projectFolders,...
                                   verbose);   
  


  colors.SV = ([210,105,30]./255).*0.5 + [1,1,1].*0.5;
  colors.SC = ([165,42,42]./255).*0.5 + [1,1,1].*0.5;
  colors.F  = [1,0,0];
  
  data.S.ch = 'Sample';
  data.S.settings = [];  
  data.L.ch = 'AI0';
  data.L.settings = [];
  data.F.ch  = 'AI1';
  data.F.settings = [];
  data.SV.ch  = 'A12';
  data.SV.settings = [];
  data.SC.ch  = 'A13';
  data.SC.settings = [];
  data.SS.ch  = 'Stim';
  data.SS.settings = [];

  stimV = [];
  stimA = [];
  
  if(isfield(expJson,'data'))
    for k=1:1:length(expJson.data)
      if(strcmp(expJson.data(k).name,'Stimulation Voltage'))
        stimV = expJson.data(k);
      end
      if(strcmp(expJson.data(k).name,'Stimulation Current'))
        stimA = expJson.data(k);
      end
      switch expJson.data(k).name
        case 'Sample'
          data.S.ch = expJson.data(k).channel;
          data.S.settings = expJson.data(k);
        case 'Length'
          data.L.ch = expJson.data(k).channel;
          data.L.settings = expJson.data(k);          
        case 'Force'
          data.F.ch = expJson.data(k).channel;
          data.F.settings = expJson.data(k);
        case 'Stimulation Voltage'
          data.SV.ch = expJson.data(k).channel;
          data.SV.settings = expJson.data(k);
        case 'Stimulation Current'
          data.SC.ch = expJson.data(k).channel;
          data.SC.settings = expJson.data(k);
        case 'Stimulation Signal'
          data.SS.ch = expJson.data(k).channel;
          data.SS.settings = expJson.data(k);
      end
    end    
  end

  %
  % Loop through the data and plot it
  %
  yLeftDataLimits = [inf,-inf];
  yRightDataLimits = [inf,-inf];  

  %
  % Plot the trial data
  %
  segmentCount=0;
  trialCount = 0;

  isLastMeasurement=0;
  metaDataCache = [];

  countFiguresGenerated = 0;
  targetTrialCount = 0;
  targetSegmentCount =0;


  indexFigTrial   =1;
  indexFigSegment =2;
  
  figureStruct(2) = struct('h',[],'name','','pageWidth',0,'pageHeight',0);
  figureStruct(1).h = figure;
  figureStruct(2).h = figure;
  
  figureStruct(1).name = ...
    ['fig_trialTimeSeries_',num2str(countFiguresGenerated)];
  figureStruct(2).name = ...
    ['fig_segmentTimeSeries_',num2str(countFiguresGenerated)];

  subPlotPanelTrial = [];
  subPlotPanelSegment = [];

  while(isLastMeasurement==0)


    metaDataCache=getNextMeasurement610A(expJson,expFolder,metaDataCache);
    isLastMeasurement = metaDataCache.isLastMeasurement;  

    if(isLastMeasurement==1)
      here=1;
    end
    if(scanSummary.doesFileNamePassFilter(metaDataCache.indexTrial)==1)

      idxM = metaDataCache.indexMeasurement;
      idxS = metaDataCache.indexSequence;  
      idxT = metaDataCache.indexTrial;

      trialCount=trialCount+1;
      
      fprintf('%i\t%i\t%s\n',...
          metaDataCache.indexMeasurement,...
          metaDataCache.indexSequence,...
          metaDataCache.measurementFileName);
  
      %
      % Take care of setting up the next figure
      %
      if(trialCount == 1)
        if(settings.breakPlotsAtSequences==1)
          found=0;
          k=idxT;
          currentMeasurementId = 0;
          targetTrialCount     = 0;
          targetSegmentCount   = 0;
          while(found==0 && k <= length(scanSummary.trialId))
            if(currentMeasurementId~=0 ...
                && scanSummary.measurementId(k) ~= currentMeasurementId)
              found=1;
            elseif((scanSummary.measurementId(k) == currentMeasurementId ...
                || scanSummary.sequenceId(k) == 0 ...
                || currentMeasurementId == 0) ...          
                && scanSummary.doesFileNamePassFilter(k)==1 ...
                && scanSummary.numberOfSegmentsPassingFilter(k) > 0)
      
              targetTrialCount = targetTrialCount+1;
              targetSegmentCount = targetSegmentCount...
                                 + scanSummary.numberOfSegmentsPassingFilter(k);
              if(scanSummary.sequenceId(k) ~= 0 && currentMeasurementId==0)
                currentMeasurementId=scanSummary.measurementId(k);
              end
            end
      
            k=k+1;
          end
        elseif(overviewPlotSettings.breakPlotsAfterTrialCount>0)

          k=idxT;
          targetTrialCount     = 0;
          targetSegmentCount   = 0;

          while(targetTrialCount < settings.breakPlotsAfterTrialCount ...
              && k < length(scanSummary.trialId))

            if( scanSummary.doesFileNamePassFilter(k)==1 ...
                && scanSummary.numberOfSegmentsPassingFilter(k) > 0)
      
              targetTrialCount = targetTrialCount+1;
              targetSegmentCount = targetSegmentCount...
                           + scanSummary.numberOfSegmentsPassingFilter(k);
            end      
            k=k+1;
          end          
        else
          assert(0,['Error: either settings.breakPlotsAtSequences or ',...
                    'settings.breakPlotsAfterTrialCount must be set']);
        end
        %
        % Set up the next figure
        %
      
        numberOfHorizontalPlotColumnsGeneric  = 1;
        numberOfVerticalPlotRowsGeneric       = targetTrialCount;
          
        plotWidth              = ones(1,numberOfHorizontalPlotColumnsGeneric).*15;
        plotHeight             = ones(numberOfVerticalPlotRowsGeneric,1).*6;
        plotHorizMarginCm      = 3;
        plotVertMarginCm       = 2;
        baseFontSize           = 12;
        
        [subPlotPanelTrial, pageWidthTrial,pageHeightTrial]= ...
          plotConfigGeneric(  numberOfHorizontalPlotColumnsGeneric,...
                    numberOfVerticalPlotRowsGeneric,...
                    plotWidth,...
                    plotHeight,...
                    plotHorizMarginCm,...
                    plotVertMarginCm,...
                    baseFontSize); 
        
        figureStruct(indexFigTrial).rows = numberOfVerticalPlotRowsGeneric;
        figureStruct(indexFigTrial).cols = numberOfHorizontalPlotColumnsGeneric;
        figureStruct(indexFigTrial).pageWidth=pageWidthTrial;
        figureStruct(indexFigTrial).pageHeight=pageHeightTrial;
        
        figureStruct(indexFigTrial).name = ...
          ['fig_trialTimeSeries_',num2str(countFiguresGenerated)];               
        %
        % Segment data plot layout
        %  
          
        segmentPlotColumns=3;
        
        numberOfHorizontalPlotColumnsGeneric  = segmentPlotColumns;
        numberOfVerticalPlotRowsGeneric       = ...
          ceil(targetSegmentCount/segmentPlotColumns);
        
        
        plotWidth               = ones(1,numberOfHorizontalPlotColumnsGeneric).*6;
        plotHeight              = ones(numberOfVerticalPlotRowsGeneric,1).*6;
        plotHorizMarginCm       = 3;
        plotVertMarginCm        = 2;
        baseFontSize            = 12;
        
        [subPlotPanelSegment, pageWidthSegment,pageHeightSegment]= ...
          plotConfigGeneric(  numberOfHorizontalPlotColumnsGeneric,...
                    numberOfVerticalPlotRowsGeneric,...
                    plotWidth,...
                    plotHeight,...
                    plotHorizMarginCm,...
                    plotVertMarginCm,...
                    baseFontSize); 
        
        figureStruct(indexFigSegment).rows      = numberOfVerticalPlotRowsGeneric;
        figureStruct(indexFigSegment).cols      = numberOfHorizontalPlotColumnsGeneric;
        figureStruct(indexFigSegment).pageWidth = pageWidthSegment;
        figureStruct(indexFigSegment).pageHeight=pageHeightSegment;

        figureStruct(indexFigSegment).name = ...
                  ['fig_segmentTimeSeries_',num2str(countFiguresGenerated)]; 


      end

      if(targetTrialCount>0)
        %
        % Fetch the trial data and plot it
        % 
        trialJson = metaDataCache.metaDataJson;  
        
        ddfData610 = readAuroraData610A(metaDataCache.dataFilePath,...
                        settings.readProtocolArray);
      
        %Get the default time unit
        defaultTimeUnit = '';
        defaultTimeUnitFound =0;
        for idxSeg = 1:1:length(trialJson.segments)
          segmentFields = fields(trialJson.segments(idxSeg));
          for idxF = 1:1:length(segmentFields)
            if(defaultTimeUnitFound==0)
              if(strcmp(segmentFields{idxF},'time_s'))
                defaultTimeUnit = 's';
                defaultTimeUnitFound =1;
              end
              if(strcmp(segmentFields{idxF},'time_ms'))
                defaultTimeUnit = 'ms';
                defaultTimeUnitFound =1;
              end      
            end
          end
        end
        assert(defaultTimeUnitFound==1,...
              'Error: cound not find the default time unit');
      
        if(~isempty(data.L.settings))
          lengthUnit = data.L.settings.unit;
          lengthScale = data.L.settings.scale_units_per_V;
        else
          lengthUnit = ddfData610.Units{end-1};
          lengthScale = ddfData610.Scale_units_V(end-1);
          if(lengthScale==1000)
            lengthUnit = lengthUnit(1,2:end);
          end
        end
        if(~isempty(data.F.settings))
          forceUnit = data.F.settings.unit;
          forceScale = data.F.settings.scale_units_per_V;
        else
          forceUnit  = ddfData610.Units{end};
          forceScale = ddfData610.Scale_units_V(end);
          if(forceScale==1000)
            forceUnit = forceUnit(1,2:end);
          end
        end
        
        %
        % Plot the trial data
        %
        figure(figureStruct(indexFigTrial).h);
        subplot('Position',reshape(subPlotPanelTrial(trialCount,:),1,4));
        
        timeSeries = ddfData610.data.(data.S.ch).Values...
                    /ddfData610.Sample_Frequency_Hz;
        
  
    
        yyaxis left;
      
          plot(timeSeries, ddfData610.data.(data.L.ch).Values);  
          hold on;
          ylabel(['Length (',lengthUnit,')']);
      
          if(yLeftDataLimits(1,1)>min(ddfData610.data.(data.L.ch).Values))
            yLeftDataLimits(1,1)=min(ddfData610.data.(data.L.ch).Values);
          end
          if(yLeftDataLimits(1,2)<max(ddfData610.data.(data.L.ch).Values))
            yLeftDataLimits(1,2)=max(ddfData610.data.(data.L.ch).Values);
          end
      
      
        yyaxis right;  
  
          for idxSeg = 1:1:length(trialJson.segments)   
            timeStim =[];
            switch trialJson.segments(idxSeg).type
              case "Stimulus-Twitch"
                timeStim=trialJson.segments(idxSeg).time_s;
              case "Stimulus-Tetanus"
                timeStim=trialJson.segments(idxSeg).time_s;
            end
            if(~isempty(timeStim))
                if(strcmp(trialJson.segments(idxSeg).type,...
                          'Stimulus-Tetanus'))
                  fill([timeStim(1),timeStim(2),timeStim(2),...
                                    timeStim(1),timeStim(1)],...
                       [0,0,1,1,0].*settings.stimulusCommandScale,...
                       [1,1,1].*0.9);
                  hold on;
  
                  text(timeStim(2),settings.stimulusCommandScale,...
                    sprintf('%1.2f Hz',...
                    trialJson.segments(idxSeg).meta_data.pulse_frequency_Hz),...
                    'FontSize',6,...
                    'HorizontalAlignment','left',...
                    'VerticalAlignment','bottom');
                  hold on;                
                end
                if(strcmp(trialJson.segments(idxSeg).type,'Stimulus-Twitch'))
                  plot([1,1].*mean(timeStim),...
                       [0,1].*settings.stimulusCommandScale,...
                       '-','Color',[0,0,0]);
                  hold on;
                  plot([1].*mean(timeStim),...
                       [1].*settings.stimulusCommandScale,...
                       'o','Color',[0,0,0],'MarkerFaceColor',[0,0,0]);
                  hold on;
                end
            end
          end    
          if(sum(ddfData610.data.(data.SS.ch).Values)>0)  
            plot(timeSeries, ...
                ddfData610.data.(data.SS.ch).Values.*settings.stimulusDataScale,...
                 '-','Color',[1,1,1].*0.25);
            hold on;
          end          
        
          if(~isempty(data.SV.ch))
            plot(timeSeries, ...
                ddfData610.data.(data.SV.ch).Values...
                .*settings.stimulusVoltageDataScale,...
                 '-','Color',colors.SV);                     
            hold on;
            [maxV,idxMaxV]=max(abs(ddfData610.data.(data.SV.ch).Values));
  
            idxMid = round(length(timeSeries)*0.5);
            text(timeSeries(end),...
                 maxV.*settings.stimulusVoltageDataScale,...
                 sprintf('%s%1.1f%s','$$\pm$$',maxV*data.SV.settings.scale_units_per_V,...
                                   data.SV.settings.unit),...
                 'FontSize',6,...
                 'HorizontalAlignment','right',...
                 'VerticalAlignment','bottom',...
                 'Color',colors.SV);
            hold on;
          end
          if(~isempty(data.SC.ch))
            plot(timeSeries, ...
                ddfData610.data.(data.SC.ch).Values...
                .*settings.stimulusCurrentDataScale,...
                 '-','Color',colors.SC);   
            hold on;      
  
            idxMid = round(length(timeSeries)*0.5);
  
            [maxA,idxMaxA]=max(abs(ddfData610.data.(data.SC.ch).Values));
            text(timeSeries(end),...
                 -maxA.*settings.stimulusCurrentDataScale,...
                 sprintf('%s%1.1f%s','$$\pm$$',maxA*data.SC.settings.scale_units_per_V,...
                                   data.SC.settings.unit),...
                 'FontSize',6,...
                 'HorizontalAlignment','right',...
                 'VerticalAlignment','bottom',...
                 'Color',colors.SC);
            hold on;
          end
  
          if(~isempty(data.SS.ch))
            plot(timeSeries, ...
                ddfData610.data.(data.SS.ch).Values...
                .*settings.stimulusDataScale,...
                 '-','Color',[1,1,1].*0.5);    
            hold on;          
          end
  
          plot(timeSeries, ddfData610.data.(data.F.ch).Values,'-',...
            'Color',colors.F);
          hold on;
  
          if(settings.annotateMinMaxTrialForce==1)
            [maxF, idxMax] = max(ddfData610.data.(data.F.ch).Values);
            plot(timeSeries(idxMax),...
              ddfData610.data.(data.F.ch).Values(idxMax),...
              'xk','MarkerFaceColor',[0,0,0]);
            hold on;
            text(timeSeries(idxMax),...
                 ddfData610.data.(data.F.ch).Values(idxMax),...
                 sprintf('%1.2f%s',...
                  ddfData610.data.(data.F.ch).Values(idxMax),...
                  forceUnit),...
                 'FontSize',6,...
                 'HorizontalAlignment','center',...
                 'VerticalAlignment','top');
            hold on;
  
            [minF, idxMin] = min(ddfData610.data.(data.F.ch).Values);
            plot(timeSeries(idxMin),...
              ddfData610.data.(data.F.ch).Values(idxMin),...
              'xk','MarkerFaceColor',[0,0,0]);
            hold on;
            text(timeSeries(idxMin),...
                 ddfData610.data.(data.F.ch).Values(idxMin),...
                 sprintf('%1.2f%s',...
                  ddfData610.data.(data.F.ch).Values(idxMin),...
                  forceUnit),...
                 'FontSize',6,...
                 'HorizontalAlignment','center',...
                 'VerticalAlignment','bottom');
            hold on;
          end
  
          ylabel(['Force (',forceUnit,')']);
      
          minYValues = zeros(3,1);
          maxYValues = zeros(3,1);
          chLabel = {'F','SV','SC'};
          for k=1:1:length(chLabel)
            minYValues(k)=min(ddfData610.data.(data.(chLabel{k}).ch).Values);
            maxYValues(k)=max(ddfData610.data.(data.(chLabel{k}).ch).Values);
            
            switch chLabel{k}              
              case 'SV'
                minYValues(k)=minYValues(k)*settings.stimulusVoltageDataScale;
                maxYValues(k)=maxYValues(k)*settings.stimulusVoltageDataScale;
              case 'SA'
                minYValues(k)=minYValues(k)*settings.stimulusCurrentDataScale;
                maxYValues(k)=maxYValues(k)*settings.stimulusCurrentDataScale;              
            end
          end
  
          if(yRightDataLimits(1,1)>min(minYValues))
            yRightDataLimits(1,1)=min(minYValues);
          end
          if(yRightDataLimits(1,2)<max(maxYValues))
            yRightDataLimits(1,2)=max(maxYValues);
          end
        
        
        xlabel(['Time (',defaultTimeUnit,')']);
          
        box off;
        titleStr = strrep(expJson.measurements{idxM},'_',' ');
        fileNameStr = strrep(expJson.measurements{idxM},'_','\_');
  
        titleStr = sprintf('(%i,%i) T%i %s',...
                    idxM,idxS,idxSeg, ...
                    trialJson.segments(idxSeg).type);
  
        title({titleStr,fileNameStr});
      
        %
        % Plot the segment data
        %    
        for idxSeg = 1:1:length(trialJson.segments)
  
          isSegmentValid = ...
            applyKeywordFilter(trialJson.segments(idxSeg).type,...
                               keyWordFilter.segment);
          if(isSegmentValid)
            segmentCount=segmentCount+1;
      
            [idxRow, idxCol] = getRowAndColumnInGrid(segmentCount, ...
                                figureStruct(indexFigSegment).rows, ...
                                figureStruct(indexFigSegment).cols);
      
            figure(figureStruct(indexFigSegment).h);
            subplot('Position',reshape(subPlotPanelSegment(idxRow,idxCol,:),1,4));
      
              startTime = trialJson.segments(idxSeg).time_s(1);
              endTime = trialJson.segments(idxSeg).time_s(2);
      
              if(strcmp(trialJson.segments(idxSeg).type,'Stimulus-Tetanus') ...
                 || strcmp(trialJson.segments(idxSeg).type,'Stimulus-Twitch') )
      
                preTimeAdj = startTime + settings.preStimulusPlotTime;
      
                if(preTimeAdj>=0)
                  startTime = startTime + settings.preStimulusPlotTime;
                  endTime   = endTime   + settings.postStimulusPlotTime;
                else
                  endTime   = endTime   + settings.postStimulusPlotTime;
                end
              end
      
              idxTime = find(timeSeries >=(startTime) & timeSeries <= (endTime));
        
              segmentTime = timeSeries(idxTime);
                
            yyaxis left;
          
            
              plot(timeSeries(idxTime), ddfData610.data.(data.L.ch).Values(idxTime));  
              hold on;
              ylabel(['Length (',lengthUnit,')']);
          
  
              %
              % Plot the forces 
              %
              yyaxis right;
                if(~isempty(data.SV.ch))
                  plot(timeSeries(idxTime), ...
                      ddfData610.data.(data.SV.ch).Values(idxTime)...
                      .*settings.stimulusVoltageDataScale,...
                       '-','Color',colors.SV);   
                  hold on;
                  idxMid = round(length(timeSeries(idxTime))*0.5);
                  [maxV,idxMaxV]=max(ddfData610.data.(data.SV.ch).Values(idxTime));
                  text(timeSeries(idxTime(end)),...
                       maxV.*settings.stimulusVoltageDataScale,...
                       sprintf('%s%1.1f%s','$$\pm$$',maxV*data.SV.settings.scale_units_per_V,...
                                         data.SV.settings.unit),...
                       'FontSize',6,...
                       'HorizontalAlignment','right',...
                       'VerticalAlignment','bottom',...
                       'Color',colors.SV);
                  hold on;                
                end
                if(~isempty(data.SC.ch))
                  plot(timeSeries(idxTime), ...
                      ddfData610.data.(data.SC.ch).Values(idxTime)...
                      .*settings.stimulusCurrentDataScale,...
                       '-','Color',colors.SC);    
                  hold on;
                  idxMid = round(length(timeSeries(idxTime))*0.5);
                  [maxA,idxMaxA]=max(ddfData610.data.(data.SC.ch).Values(idxTime));
                  text(timeSeries(idxTime(end)),...
                       -maxA.*settings.stimulusCurrentDataScale,...
                       sprintf('%s%1.1f%s','$$\pm$$',maxA*data.SC.settings.scale_units_per_V,...
                                         data.SC.settings.unit),...
                       'FontSize',6,...
                       'HorizontalAlignment','right',...
                       'VerticalAlignment','bottom',...
                       'Color',colors.SC);
                  hold on;                 
                end
  
                if(~isempty(data.SS.ch))
                  plot(timeSeries(idxTime), ...
                      ddfData610.data.(data.SS.ch).Values(idxTime)...
                      .*settings.stimulusDataScale,...
                       '-','Color',[1,1,1].*0.5);    
                  hold on;
                end
      
                plot(timeSeries(idxTime), ...
                  ddfData610.data.(data.F.ch).Values(idxTime),'-',...
                  'Color',colors.F);
                hold on;
  
                if(settings.annotateMinMaxSegmentForce==1)
                  [maxF, idxMax] = max(ddfData610.data.(data.F.ch).Values(idxTime));
                  plot(timeSeries(idxTime(idxMax)),...
                    ddfData610.data.(data.F.ch).Values(idxTime(idxMax)),...
                    'xk','MarkerFaceColor',[0,0,0]);
                  hold on;
                  text(timeSeries(idxTime(idxMax)),...
                       ddfData610.data.(data.F.ch).Values(idxTime(idxMax)),...
                       sprintf('%1.2f%s',...
                          ddfData610.data.(data.F.ch).Values(idxTime(idxMax)),...
                          forceUnit),...
                       'FontSize',6,...
                       'HorizontalAlignment','center',...
                       'VerticalAlignment','top');
                  hold on;
  
                  [minF, idxMin] = min(ddfData610.data.(data.F.ch).Values(idxTime));
                  plot(timeSeries(idxTime(idxMin)),...
                    ddfData610.data.(data.F.ch).Values(idxTime(idxMin)),...
                    'xk','MarkerFaceColor',[0,0,0]);
                  hold on;
                  text(timeSeries(idxTime(idxMin)),...
                       ddfData610.data.(data.F.ch).Values(idxTime(idxMin)),...
                       sprintf('%1.2f%s',...
                          ddfData610.data.(data.F.ch).Values(idxTime(idxMin)),...
                          forceUnit),...
                       'FontSize',6,...
                       'HorizontalAlignment','center',...
                       'VerticalAlignment','bottom');
                  hold on;
                end              
  
                ylabel(['Force (',forceUnit,')']); 
  
              %
              % Plot commanded twitch/tetanus blocks
              %
              timeStim =[];
              switch trialJson.segments(idxSeg).type
                case "Stimulus-Twitch"
                  timeStim = trialJson.segments(idxSeg).time_s;
                case "Stimulus-Tetanus"
                  timeStim = trialJson.segments(idxSeg).time_s;
              end
      
    
              if(~isempty(timeStim))
    
                dt = 1/ddfData610.Sample_Frequency_Hz;
                if(diff(timeStim)>dt)
                  if(  timeStim(1) < segmentTime(1) ...
                    || timeStim(2) > segmentTime(end))
                    idxTmp = find(segmentTime >= timeStim(1) ...
                                        & segmentTime <= timeStim(2));
                    if(~isempty(idxTmp))
                      timeStim = [segmentTime(idxTmp(1)),segmentTime(idxTmp(end))];
                    else
                      timeStim = [];
                    end
                  end
                end
    
                if(~isempty(timeStim))
                  if(   timeStim(1) < segmentTime(1)...
                     && timeStim(2) > segmentTime(end))
                    timeStim=[];
                  end
                end
    
              end
      
              if(~isempty(timeStim))          
                yyaxis right; 
                if(strcmp(trialJson.segments(idxSeg).type,'Stimulus-Tetanus'))
                  fill([timeStim(1),timeStim(2),timeStim(2),...
                                    timeStim(1),timeStim(1)],...
                       [0,0,1,1,0].*settings.stimulusCommandScale,...
                       [1,1,1].*0.9);
                  hold on;
                  hax = gca;
                  hax.Children = circshift(hax.Children, -1);
  
                  text(timeStim(2),settings.stimulusCommandScale,...
                    sprintf('%1.2f Hz',...
                    trialJson.segments(idxSeg).meta_data.pulse_frequency_Hz),...
                    'FontSize',6,...
                    'HorizontalAlignment','left',...
                    'VerticalAlignment','bottom');
                  hold on;
                  
                end
                if(strcmp(trialJson.segments(idxSeg).type,'Stimulus-Twitch'))
                  plot([1,1].*mean(timeStim),...
                       [0,1].*settings.stimulusCommandScale,...
                       '-','Color',[0,0,0]);
                  hold on;
                  plot([1].*mean(timeStim),...
                       [1].*settings.stimulusCommandScale,...
                       'o','Color',[0,0,0],'MarkerFaceColor',[0,0,0]);
                  hold on;
                end
    
              end          
  
            
            xlabel(['Time (',defaultTimeUnit,')']);
              
            box off;
            fileNameStr = strrep(expJson.measurements{idxM},'_','\_');
      
            titleStr = sprintf('(%i,%i) T%i S%i %s %s',...
                        idxRow,idxCol,idxM,idxSeg, ...
                        trialJson.segments(idxSeg).type);
            title({titleStr,fileNameStr});  
          end
    
        end
  
        %
        % Save a plot
        %      
        if(trialCount == targetTrialCount)
  
          for i=1:1:targetTrialCount
            figure(figureStruct(indexFigTrial).h);
            subplot('Position',reshape(subPlotPanelTrial(i,:),1,4));
            yyaxis left;
              ylim(yLeftDataLimits);
            yyaxis right;
              ylim(yRightDataLimits);      
          end
        
        
           for i=1:1:targetSegmentCount
        
              [idxRow, idxCol] = getRowAndColumnInGrid(i, ...
                                  figureStruct(indexFigSegment).rows, ...
                                  figureStruct(indexFigSegment).cols);
          
              figure(figureStruct(indexFigSegment).h);
              subplot('Position',reshape(subPlotPanelSegment(idxRow,idxCol,:),1,4));      
              yyaxis left;
                ylim(yLeftDataLimits);
              yyaxis right;
                ylim(yRightDataLimits);      
          end
                
          if(settings.savePlots==1)          
            for i=1:1:length(figureStruct)  
          
              outputPlotDir = fullfile(projectFolders.output610A_plots,...
                                      experimentsToProcess{idxExp});  
              figure(figureStruct(i).h);
              figureStruct(i).h=configPlotExporter(...
                                    figureStruct(i).h, ...
                                    figureStruct(i).pageWidth,...
                                    figureStruct(i).pageHeight);
            
              if(~isempty(keyWordFilter.metaDataFileName.include))
                print('-dpdf', ...
                      fullfile(outputPlotDir,...
                          [figureStruct(i).name,'keyWord_',...
                          keyWordFilter.metaDataFileName.include,'.pdf']));  
                saveas(figureStruct(i).h,...
                        fullfile(outputPlotDir,...
                          [figureStruct(i).name,'keyWord_',...
                          keyWordFilter.metaDataFileName.include,'.fig']));
              else
                print('-dpdf', ...
                      fullfile(outputPlotDir,...
                         [figureStruct(i).name,'.pdf']));  
                saveas(figureStruct(i).h,...
                        fullfile(outputPlotDir,...
                          [figureStruct(i).name,'.fig']));
              end
            end
          end
        
          for i=1:1:length(figureStruct)
            clf(figureStruct(i).h);
            figureStruct(i).pageWidth=nan;
            figureStruct(i).pageHeight=nan;
            figureStruct(i).rows=nan;
            figureStruct(i).cols=nan;    
          end   
          countFiguresGenerated=countFiguresGenerated+1;
          trialCount=0;
          segmentCount=0;
          yLeftDataLimits = [inf,-inf];
          yRightDataLimits = [inf,-inf];  
        end
      end
    end
  end
end


success=1;