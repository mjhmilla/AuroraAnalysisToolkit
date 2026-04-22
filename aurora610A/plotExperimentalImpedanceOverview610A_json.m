function success = plotExperimentalImpedanceOverview610A_json(...
                          experimentsToProcess,...
                          keyWordFilter,...
                          settings,...                       
                          projectFolders,...
                          verbose)

success = 0;

fprintf('\n\nImpedance Overview Plots\n\n');

indexFigExpFl   =1;

indexOverview=1;
figureStruct(1) = struct('h',[],'name','','pageWidth',0,'pageHeight',0);
figureStruct(1).h = figure;



%
% Count the number of trials and the number of segments
%
filteredSetOfExperiments = [];

fprintf('%s\t%s\n','#Valid Trials','Experiment Name');
for idxExp =1:1:length(experimentsToProcess)
  expFolder = fullfile(projectFolders.data610A,...
                       experimentsToProcess{idxExp});
  expStr = fileread(fullfile(expFolder,...
                             [experimentsToProcess{idxExp},'.json']));
  expJson = jsondecode(expStr);
  
  scanSummary = scanExperiment610A(experimentsToProcess{idxExp},...
                                   keyWordFilter,...
                                   projectFolders,...
                                   0);    
 
  if(sum(scanSummary.passesAllFilters) > 0)
    filteredSetOfExperiments = [filteredSetOfExperiments;idxExp];
  end
    fprintf('%i\t\t%s\n',sum(scanSummary.passesAllFilters),...
                       experimentsToProcess{idxExp});

end

if(isempty(filteredSetOfExperiments))
  return;
end

csPaleDark = getPaulTolColourSchemes('paleDark');
csVibrant  = getPaulTolColourSchemes('vibrant');

colors.coherenceSq=[0,0,0];
colors.gain   = [0,0,0];%csVibrant.cyan;
colors.phase  = [0,0,0];%csVibrant.teal;
colors.F      = csVibrant.red;
colors.L      = csVibrant.blue;

%
% Go through each of the experiments
%
for idxExpList = 1:1:length(filteredSetOfExperiments)
  idxExp = filteredSetOfExperiments(idxExpList);

  fprintf('\n\nProcessing %s\n\n',experimentsToProcess{idxExp});

  expFolder = fullfile(projectFolders.data610A,...
                       experimentsToProcess{idxExp});

  expStr = fileread(fullfile(expFolder,...
                             [experimentsToProcess{idxExp},'.json']));
  expJson = jsondecode(expStr);
  
  scanSummary = scanExperiment610A(experimentsToProcess{idxExp},...
                                   keyWordFilter,...
                                   projectFolders,...
                                   0); 
  dataInfo = getDataColumnLabelsSettings(expJson);

  validTrials = find(scanSummary.passesAllFilters==1);

    
  metaDataCache = [];
  
  idxMPrevious = -1;
  for idxTrialList=1:1:length(validTrials)
    idxT = validTrials(idxTrialList);
    idxM = scanSummary.indexMeasurement(idxT);
    idxS = scanSummary.indexSequence(idxT);

    %
    % Set up a new plot if necessary
    %
    if(idxMPrevious~=idxM)
      segmentCount=0;
      i=idxT;
      numberOfSegments=0;
      while( i <= length(scanSummary.indexMeasurement))

        if(scanSummary.indexMeasurement(i)==idxM)
          if(scanSummary.passesAllFilters(i)==1)
            numberOfSegments    = numberOfSegments...
              +scanSummary.numberOfSegmentsPassingFilter(i);
          end
        end
        i=i+1;
      end
    
      numberOfHorizontalPlotColumnsGeneric  = 4;
      numberOfVerticalPlotRowsGeneric       = numberOfSegments;
        
      plotWidth              = ones(1,numberOfHorizontalPlotColumnsGeneric).*6;
      plotHeight             = ones(numberOfVerticalPlotRowsGeneric,1).*6;
      plotHorizMarginCm      = 3;
      plotVertMarginCm       = 2;
      baseFontSize           = 10;
      
      [subPlotPanel, pageWidth,pageHeight]= ...
        plotConfigGeneric(  numberOfHorizontalPlotColumnsGeneric,...
                  numberOfVerticalPlotRowsGeneric,...
                  plotWidth,...
                  plotHeight,...
                  plotHorizMarginCm,...
                  plotVertMarginCm,...
                  baseFontSize);   
    
    
      figureStruct(indexOverview).rows = numberOfVerticalPlotRowsGeneric;
      figureStruct(indexOverview).cols = numberOfHorizontalPlotColumnsGeneric;
      figureStruct(indexOverview).pageWidth=pageWidth;
      figureStruct(indexOverview).pageHeight=pageHeight;
      
      figureStruct(indexOverview).name = ...
        ['fig_impedanceOverivew_',experimentsToProcess{idxExp},'_',num2str(idxM)];

      yAxisLimits(5)=struct('min',inf,'max',-inf);
      for i=1:1:length(yAxisLimits)
        yAxisLimits(i).min=inf;
        yAxisLimits(i).max=-inf;
      end
    end

    metaDataCache = getMeasurement610A(idxM,idxS,idxT,...
                                    expJson,expFolder,...
                                    metaDataCache);

    trialJson = metaDataCache.metaDataJson;  
    
    ddfData610 = readAuroraData610A(metaDataCache.dataFilePath,...
                    settings.readProtocolArray);

    units = getUnits610A(expJson,trialJson,ddfData610);

    timeSeries = ddfData610.data.(dataInfo.S.ch).Values...
                /ddfData610.Sample_Frequency_Hz;


    for idxSeg = 1:1:length(trialJson.segments)
      segmentType = trialJson.segments(idxSeg).type;
      isSegmentValid = ...
          applyKeywordFilter(segmentType,keyWordFilter.segment);

      if(isSegmentValid==1)
        segmentCount = segmentCount + 1;        
        indicesSeg = ...
          find(  timeSeries >= trialJson.segments(idxSeg).time_s(1) ... 
               & timeSeries <= trialJson.segments(idxSeg).time_s(2) );
        bandwidth = trialJson.segments(idxSeg).meta_data.bandwidth_Hz';
        temperatureTag ='';

        tempRange = metaDataCache.temperature_C;
        %tempRange=getTemperatureRangeInCelsius610A(idxM,...
        %                                    expJson,...
        %                                    experimentsToProcess{idxExp});
        for j=1:1:length(tempRange)
          tmpStr = '';
          if(j>1)
            tmpStr='-';
          end
          temperatureTag = [temperatureTag, ...
                            sprintf('%s%1.1f',tmpStr,tempRange(j))];
        end
        temperatureTag = [temperatureTag,'$$^o$$C'];

        activeTag = '';
        if(trialJson.segments(idxSeg).meta_data.is_active==1)
          activeTag = 'active';          
        else
          activeTag = 'passive';          
        end

        timeSeg   = timeSeries(indicesSeg);
        lengthSeg = ddfData610.data.(dataInfo.L.ch).Values(indicesSeg);
        forceSeg  = ddfData610.data.(dataInfo.F.ch).Values(indicesSeg);
  

        freqRes = evaluateGainPhaseCoherenceSq(...
                        timeSeg,...
                        lengthSeg,...
                        forceSeg,...
                        bandwidth,...
                        ddfData610.Sample_Frequency_Hz,...
                        settings.minCoherenceSquared,...
                        settings.minAcceptableBandwidthFraction);

        %
        % Column 1: length and force time-series data
        %
        figure(figureStruct(indexOverview).h);
        if(segmentCount > size(subPlotPanel,1))
          here=1;
        end
        subplot('Position',reshape(subPlotPanel(segmentCount,1,:),1,4));

        yyaxis left;        
        plot(timeSeg,...
             lengthSeg,...
             '-','Color',colors.L);
        hold on;
        xlabel(['Time (',units.time,')']);
        ylabel(['Length (',units.length,')']);

        if(min(lengthSeg)<yAxisLimits(1).min)
          yAxisLimits(1).min=min(lengthSeg);
        end
        if(max(lengthSeg)>yAxisLimits(1).max)
          yAxisLimits(1).max=max(lengthSeg);
        end

        yyaxis right;        
        plot(timeSeg,...
             forceSeg,...
             '-','Color',colors.F);
        hold on;

        if(min(forceSeg)<yAxisLimits(2).min)
          yAxisLimits(2).min=min(forceSeg);
        end
        if(max(forceSeg)>yAxisLimits(2).max)
          yAxisLimits(2).max=max(forceSeg);
        end


        ylabel(['Force (',units.force,')']);
        here=1;
        box off;

        fileNameStr = strrep(metaDataCache.dataFileName,'_','\_');
  
        titleStr = sprintf('(%i,%i) T%i %s',...
                    idxM,idxS,idxSeg, ...
                    trialJson.segments(idxSeg).type);
  
        title({titleStr,fileNameStr,[activeTag,' ',temperatureTag]});    

        %
        % Column 2: coherence-sq
        %
        idxBW = freqRes.idxBW;
        idxBWC2 = freqRes.idxBWC2;
        bandwidthC2 = freqRes.bandwidthHzC2;
        subplot('Position',reshape(subPlotPanel(segmentCount,2,:),1,4));
        plot(freqRes.frequencyHz(idxBW),...
             freqRes.coherenceSq(idxBW),...
             '-','Color',colors.coherenceSq);        
        hold on;

        if(~isempty(bandwidthC2))
          plot([1,1].*bandwidthC2(1),[0,1],'-','Color',[1,1,1].*0.5);
          hold on;
          plot([1,1].*bandwidthC2(2),[0,1],'-','Color',[1,1,1].*0.5);
          hold on;
        end
        
        box off;        
        xlabel(['Frequency (Hz)']);
        ylabel(sprintf('%s','Coherence-Sq'));
        title('Coherence-Squared');

        yAxisLimits(3).min=0;
        yAxisLimits(3).max=1;

        %
        % Column 3: gain
        %
        subplot('Position',reshape(subPlotPanel(segmentCount,3,:),1,4));
        plot(freqRes.frequencyHz(idxBW),...
             freqRes.gain(idxBW),...
             '-','Color',colors.gain);
        hold on;

        if(~isempty(bandwidthC2))
          plot([1,1].*bandwidthC2(1),[0,1].*max(freqRes.gain(idxBW)),...
               '-','Color',[1,1,1].*0.5);
          hold on;
          plot([1,1].*bandwidthC2(2),[0,1].*max(freqRes.gain(idxBW)),...
               '-','Color',[1,1,1].*0.5);
          hold on;
        end
        
        box off;        

        xlabel(['Frequency (Hz)']);
        ylabel(sprintf('%s (%s/%s)','Gain',units.force,units.length));
        title('Gain');

        if(~isempty(idxBWC2))
          if(min(freqRes.gain(idxBWC2))<yAxisLimits(4).min)
            yAxisLimits(4).min=min(freqRes.gain(idxBWC2));
          end
          if(max(freqRes.gain(idxBWC2))>yAxisLimits(4).max)
            yAxisLimits(4).max=max(freqRes.gain(idxBWC2));
          end
        end
        
        %
        % Column 4: phase
        %
        phaseDeg = freqRes.phase(idxBW).*(180/pi);
        subplot('Position',reshape(subPlotPanel(segmentCount,4,:),1,4));
        plot(freqRes.frequencyHz(idxBW),...
             phaseDeg,...
             '-','Color',colors.phase);
        hold on;

        if(~isempty(bandwidthC2))
          plot([1,1].*bandwidthC2(1),[0,1].*max(phaseDeg),...
               '-','Color',[1,1,1].*0.5);
          hold on;
          plot([1,1].*bandwidthC2(2),[0,1].*max(phaseDeg),...
               '-','Color',[1,1,1].*0.5);
          hold on;
        end
        
        box off;        
        xlabel(['Frequency (Hz)']);
        ylabel(sprintf('%s (%s)','Phase','$$^o$$'));
        title('Phase');
        
        if(~isempty(idxBWC2))
          phaseDegC2 = freqRes.phase(idxBWC2).*(180/pi);
          if(min(phaseDegC2)<yAxisLimits(5).min)
            yAxisLimits(5).min=min(phaseDegC2);
          end
          if(max(phaseDegC2)>yAxisLimits(5).max)
            yAxisLimits(5).max=max(phaseDegC2);
          end        
        end
      end
    end  

    idxMPrevious=idxM;

    if(settings.savePlots==1 && segmentCount==numberOfSegments)          
      for i=1:1:length(figureStruct)  
        figure(figureStruct(i).h);
        for j=1:1:numberOfSegments
          subplot('Position',reshape(subPlotPanel(j,1,:),1,4));
          yyaxis left;
          if(~isinf(yAxisLimits(1).min) && ~isinf(yAxisLimits(1).max))
            ylim([yAxisLimits(1).min,yAxisLimits(1).max]);
          end
          yyaxis right;
          if(~isinf(yAxisLimits(2).min) && ~isinf(yAxisLimits(2).max))          
            ylim([yAxisLimits(2).min,yAxisLimits(2).max]);
          end
          subplot('Position',reshape(subPlotPanel(j,2,:),1,4));
          if(~isinf(yAxisLimits(3).min) && ~isinf(yAxisLimits(3).max))
            ylim([yAxisLimits(3).min,yAxisLimits(3).max]);
          end

          subplot('Position',reshape(subPlotPanel(j,3,:),1,4));
          if(~isinf(yAxisLimits(4).min) && ~isinf(yAxisLimits(4).max))          
            ylim([yAxisLimits(4).min,yAxisLimits(4).max]);
          end
          
          subplot('Position',reshape(subPlotPanel(j,4,:),1,4));
          if(~isinf(yAxisLimits(5).min) && ~isinf(yAxisLimits(5).max))
            ylim([yAxisLimits(5).min,yAxisLimits(5).max]);
          end
          
        end
    
        outputPlotDir = fullfile(projectFolders.output610A_plots,...
                                experimentsToProcess{idxExp});  
  
        outputPlotDirOverview = fullfile(outputPlotDir,'impedance');
        if(~exist(outputPlotDirOverview,'dir'))
          mkdir(outputPlotDirOverview);
        end
  
        figure(figureStruct(i).h);
        figureStruct(i).h=configPlotExporter(...
                              figureStruct(i).h, ...
                              figureStruct(i).pageWidth,...
                              figureStruct(i).pageHeight);
      
        fullFilePathNoExt = [];
        if(~isempty(keyWordFilter.metaDataFileName.include))
          fullFilePathNoExt = ...
            fullfile(outputPlotDirOverview,...
                    [figureStruct(i).name,'keyWord_',...
                    keyWordFilter.metaDataFileName.include]);
        else
          fullFilePathNoExt = ...
            fullfile(outputPlotDirOverview,...
                    [figureStruct(i).name]);
        end
  
        for k=1:1:length(settings.saveFormat)
          switch settings.saveFormat{k}
            case 'pdf'
              print('-dpdf',[fullFilePathNoExt,'.pdf']);  
            case 'fig'                      
              saveas(figureStruct(i).h,[fullFilePathNoExt,'.fig']);
            case 'png'
              saveas(figureStruct(i).h,[fullFilePathNoExt,'.png']);
            otherwise
              assert(0,'Error: unrecognized type in settings.saveFormat');
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
  
 

  end


end








success=1;