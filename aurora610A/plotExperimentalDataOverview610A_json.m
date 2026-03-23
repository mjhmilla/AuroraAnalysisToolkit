function success = plotExperimentalDataOverview610A_json(...
                          experimentsToProcess,...
                          fileKeyWord,...
                          settings,...
                          projectFolders)

success = 0;

indexFigTrial   =1;
indexFigSegment =2;

figureStruct(2) = struct('h',[],'name','','pageWidth',0,'pageHeight',0);
figureStruct(1).h = figure;
figureStruct(2).h = figure;

figureStruct(1).name = ['fig_trialTimeSeries'];
figureStruct(2).name = ['fig_segmentTimeSeries'];


segmentCount=0;
for idxExp = 1:1:length(experimentsToProcess)

  disp(experimentsToProcess{idxExp});
  %
  % Scan through the data and count the number of trials and segments
  %
  expStr = fileread(fullfile(projectFolders.data610A,...
                              experimentsToProcess{idxExp},...
                             [experimentsToProcess{idxExp},'.json']));
  expJson = jsondecode(expStr);

  trialCount = length(expJson.trials);

  setOfTrials = [];
  segmentCount=0; 

  for idxTrial=1:1:trialCount
    flag_validFile=1;
    if(~isempty(fileKeyWord))
      if(contains(expJson.trials{idxTrial},fileKeyWord))
        flag_validFile=1;
      else
        flag_validFile=0;
      end
    end


    if(flag_validFile==1)
      setOfTrials = [setOfTrials,idxTrial];
      trialStr = fileread(fullfile(projectFolders.data610A,...
                                   experimentsToProcess{idxExp},...
                                   expJson.trials{idxTrial}));
  
      trialJson = jsondecode(trialStr);
  
      segmentCount = segmentCount+length(trialJson.segments);
    end
  end  

  %
  % Configure the plots
  %

  numberOfHorizontalPlotColumnsGeneric  = 1;
  numberOfVerticalPlotRowsGeneric       = length(setOfTrials);
    
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
  
  %
  % Segment data plot layout
  %  
    
  segmentPlotColumns=3;
  
  numberOfHorizontalPlotColumnsGeneric  = segmentPlotColumns;
  numberOfVerticalPlotRowsGeneric       = ceil(segmentCount/segmentPlotColumns);
  
  
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
  
  %
  % Loop through the data and plot it
  %
  maxTrialTime = 0;
  yLeftDataLimits = [inf,-inf];
  yRightDataLimits = [inf,-inf];  

  %
  % Plot the trial data
  %
  segmentCount=0;
  for idxSetOfTrials = 1:1:length(setOfTrials)

    idxTrial = setOfTrials(idxSetOfTrials);

    flag_validFile=1;
    if(~isempty(fileKeyWord))
      if(contains(expJson.trials{idxTrial},fileKeyWord))
        flag_validFile=1;
      else
        flag_validFile=0;
      end
    end

    if(flag_validFile==1)

      fprintf('\t%s\n',expJson.trials{idxTrial});
      if(strcmp(expJson.trials{idxTrial},'17_FFR_0p.json'))
        here=1;
      end
  
      trialStr = fileread(fullfile(projectFolders.data610A,...
                                   experimentsToProcess{idxExp},...
                                   expJson.trials{idxTrial}));
      trialJson = jsondecode(trialStr);  
      
      
      ddfPath = fullfile(projectFolders.data610A,...
                         experimentsToProcess{idxExp});
      for i=1:1:length(trialJson.data.file)
        ddfPath = [ddfPath,filesep,trialJson.data.file{i}];
      end
    
      ddfData610 = readAuroraData610A(ddfPath,...
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
    
      lengthUnit = ddfData610.Units{end-1};
      lengthScale = ddfData610.Scale_units_V(end-1);
      if(lengthScale==1000)
        lengthUnit = lengthUnit(1,2:end);
      end

      forceUnit  = ddfData610.Units{end};
      forceScale = ddfData610.Scale_units_V(end);
      if(forceScale==1000)
        forceUnit = forceUnit(1,2:end);
      end
      

      tmax = ddfData610.data.Sample.Values(end)...
            /ddfData610.Sample_Frequency_Hz;
    
      if(tmax > maxTrialTime)
        maxTrialTime=tmax;
      end
    
    
    
      %
      % Plot the trial data
      %
      figure(figureStruct(indexFigTrial).h);
      subplot('Position',reshape(subPlotPanelTrial(idxSetOfTrials,:),1,4));
      
      timeSeries = ddfData610.data.Sample.Values...
                  /ddfData610.Sample_Frequency_Hz;
      

  
      yyaxis left;
    
        plot(timeSeries, ddfData610.data.AI0.Values);  
        hold on;
        ylabel(['Length (',lengthUnit,')']);
    
        if(yLeftDataLimits(1,1)>min(ddfData610.data.AI0.Values))
          yLeftDataLimits(1,1)=min(ddfData610.data.AI0.Values);
        end
        if(yLeftDataLimits(1,2)<max(ddfData610.data.AI0.Values))
          yLeftDataLimits(1,2)=max(ddfData610.data.AI0.Values);
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
              if(strcmp(trialJson.segments(idxSeg).type,'Stimulus-Tetanus'))
                fill([timeStim(1),timeStim(2),timeStim(2),...
                                  timeStim(1),timeStim(1)],...
                     [0,0,1,1,0].*settings.stimulusCommandScale,...
                     [1,1,1].*0.75,'EdgeAlpha',0,'FaceAlpha',0.5);
                hold on;

                text(timeStim(2),settings.stimulusCommandScale,...
                  sprintf('%1.2f Hz',...
                  trialJson.segments(idxSeg).meta_data.pulse_frequency_Hz),...
                  'FontSize',10,...
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
        if(sum(ddfData610.data.Stim.Values)>0)  
          plot(timeSeries, ...
              ddfData610.data.Stim.Values.*settings.stimulusDataScale,...
               '-','Color',[1,1,1].*0.25);
        end          
      
        plot(timeSeries, ddfData610.data.AI1.Values,'-');
        hold on;
        ylabel(['Force (',forceUnit,')']);
    
        if(yRightDataLimits(1,1)>min(ddfData610.data.AI1.Values))
          yRightDataLimits(1,1)=min(ddfData610.data.AI1.Values);
        end
        if(yRightDataLimits(1,2)<max(ddfData610.data.AI1.Values))
          yRightDataLimits(1,2)=max(ddfData610.data.AI1.Values);
        end
      
      
      xlabel(['Time (',defaultTimeUnit,')']);
        
      box off;
      titleStr = strrep(expJson.trials{idxTrial},'_',' ');
      fileNameStr = strrep(expJson.trials{idxTrial},'_','\_');

      titleStr = sprintf('(%i) T%i %s',...
                  idxSetOfTrials,idxTrial, ...
                  trialJson.segments(idxSeg).type);

      title({titleStr,fileNameStr});
    
      %
      % Plot the segment data
      %    
      for idxSeg = 1:1:length(trialJson.segments)
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
      
        
          plot(timeSeries(idxTime), ddfData610.data.AI0.Values(idxTime));  
          hold on;
          ylabel(['Length (',lengthUnit,')']);
      
        yyaxis right;  
          %
          % Plot commanded twitch/tetanus blocks
          %
          for idxStimSeg = 1:1:length(trialJson.segments)   
            timeStim =[];
            switch trialJson.segments(idxStimSeg).type
              case "Stimulus-Twitch"
                timeStim = trialJson.segments(idxStimSeg).time_s;
              case "Stimulus-Tetanus"
                timeStim = trialJson.segments(idxStimSeg).time_s;
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
              if(strcmp(trialJson.segments(idxStimSeg).type,'Stimulus-Tetanus'))
                fill([timeStim(1),timeStim(2),timeStim(2),...
                                  timeStim(1),timeStim(1)],...
                     [0,0,1,1,0].*settings.stimulusCommandScale,...
                     [1,1,1].*0.75,'EdgeAlpha',0,'FaceAlpha',0.5);
                hold on;
                hax = gca;
                hax.Children = circshift(hax.Children, -1);

                text(timeStim(2),settings.stimulusCommandScale,...
                  sprintf('%1.2f Hz',...
                  trialJson.segments(idxStimSeg).meta_data.pulse_frequency_Hz),...
                  'FontSize',10,...
                  'HorizontalAlignment','left',...
                  'VerticalAlignment','bottom');
                hold on;
                
              end
              if(strcmp(trialJson.segments(idxStimSeg).type,'Stimulus-Twitch'))
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
          %
          % Plot stimulation pattern
          %
          yyaxis right;
            plot(timeSeries(idxTime), ...
                ddfData610.data.Stim.Values(idxTime).*settings.stimulusDataScale,...
                 '-','Color',[1,1,1].*0.25);        
  
  
          plot(timeSeries(idxTime), ddfData610.data.AI1.Values(idxTime),'-');
          hold on;
          ylabel(['Force (',forceUnit,')']);
        
        xlabel(['Time (',defaultTimeUnit,')']);
          
        box off;
        fileNameStr = strrep(expJson.trials{idxTrial},'_','\_');
  
        titleStr = sprintf('(%i,%i) T%i S%i %s %s',...
                    idxRow,idxCol,idxTrial,idxSeg, ...
                    trialJson.segments(idxSeg).type);
        title({titleStr,fileNameStr});      
  
      end
    end
  end
  
  segmentCount=0;

  for idxSetOfTrials = 1:1:length(setOfTrials)
    idxTrial = setOfTrials(idxSetOfTrials);
    figure(figureStruct(indexFigTrial).h);
    subplot('Position',reshape(subPlotPanelTrial(idxSetOfTrials,:),1,4));
    yyaxis left;
      ylim(yLeftDataLimits);
    yyaxis right;
      ylim(yRightDataLimits);
    
    flag_validFile=1;
    if(~isempty(fileKeyWord))
      if(contains(expJson.trials{idxTrial},fileKeyWord))
        flag_validFile=1;
      else
        flag_validFile=0;
      end
    end

    if(flag_validFile==1)
      trialStr = fileread(fullfile( projectFolders.data610A,...
                                    experimentsToProcess{idxExp},...
                                    expJson.trials{idxTrial}));
      trialJson = jsondecode(trialStr);  
  
      trialSegment0 = segmentCount;
      for idxSeg = 1:1:length(trialJson.segments)
        segmentCount=segmentCount+1;
  
  
        [idxRow, idxCol] = getRowAndColumnInGrid(segmentCount, ...
                            figureStruct(indexFigSegment).rows, ...
                            figureStruct(indexFigSegment).cols);
  
  
        figure(figureStruct(indexFigSegment).h);
        subplot('Position',reshape(subPlotPanelSegment(idxRow,idxCol,:),1,4));      
        yyaxis left;
          ylim(yLeftDataLimits);
        yyaxis right;
          ylim(yRightDataLimits);      
      end
    end
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
    
      if(~isempty(fileKeyWord))
        print('-dpdf', ...
              fullfile(outputPlotDir,...
                  [figureStruct(i).name,'keyWord_',fileKeyWord,'.pdf']));  
        saveas(figureStruct(i).h,...
                fullfile(outputPlotDir,...
                  [figureStruct(i).name,'keyWord_',fileKeyWord,'.fig']));
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

end


success=1;