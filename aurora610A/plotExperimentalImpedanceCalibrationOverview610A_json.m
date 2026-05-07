function success = plotExperimentalImpedanceCalibrationOverview610A_json(...
                          experimentsToProcess,...
                          keyWordFilterSinusoidal,...
                          keyWordFilterMotor,...
                          settings,...                       
                          projectFolders,...
                          verbose)

success = 0;

fprintf('\n\nImpedance Calibration Plots\n\n');

indexFigSinusoid   =1;


figureStruct(1) = struct('h',[],'name','','pageWidth',0,'pageHeight',0);
figureStruct(1).h = figure;



%
% Count the number of trials and the number of segments
%
filteredSetOfExperiments = [];

fprintf('%s\n','Impedance Calibration: Sinusoidal Analysis');
fprintf('%s\t%s\n','#Valid Trials','Experiment Name');
for idxExp =1:1:length(experimentsToProcess)
  expFolder = fullfile(projectFolders.data610A,...
                       experimentsToProcess{idxExp});
  expStr = fileread(fullfile(expFolder,...
                             [experimentsToProcess{idxExp},'.json']));
  expJson = jsondecode(expStr);
  
  scanSummary = scanExperiment610A(experimentsToProcess{idxExp},...
                                   keyWordFilterSinusoidal,...
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
% Go through each of the sinusoidal experiments
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
                                   keyWordFilterSinusoidal,...
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
    
      rows = max(3,ceil(sqrt(numberOfSegments)));
      cols = ceil((numberOfSegments)/rows);
      rows=rows+1;

      numberOfHorizontalPlotColumnsGeneric  = cols;
      numberOfVerticalPlotRowsGeneric       = rows;
        
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
    
    
      figureStruct(indexFigSinusoid).rows = numberOfVerticalPlotRowsGeneric;
      figureStruct(indexFigSinusoid).cols = numberOfHorizontalPlotColumnsGeneric;
      figureStruct(indexFigSinusoid).pageWidth=pageWidth;
      figureStruct(indexFigSinusoid).pageHeight=pageHeight;
      
      figureStruct(indexFigSinusoid).name = ...
        ['fig_impedanceCalibrationSinusoid_',...
          experimentsToProcess{idxExp},'_',...
          num2str(idxM)];

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
          applyKeywordFilter(segmentType,keyWordFilterSinusoidal.segment);

      if(isSegmentValid==1)
        segmentCount = segmentCount + 1;   
        offsetTime = (idxSeg-1)*(0.0037/9);
        period = (1/trialJson.segments(idxSeg).meta_data.frequency_Hz);

        time0 = trialJson.segments(idxSeg).time_s(1);
        time1 = (trialJson.segments(idxSeg).time_s(2)+offsetTime);

        timePadding=min(0.025, (period));
        time0 = time0-timePadding;
        time1 = time1+timePadding;
        timeRange = time1-time0;

        indicesSeg = ...
          find(  timeSeries >= time0 ... 
               & timeSeries <= time1 );
        frequencyHz = trialJson.segments(idxSeg).meta_data.frequency_Hz';
        temperatureTag ='';

        tempRange = metaDataCache.temperature_C;

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
  
        %
        % Fit a sine wave to the length profile
        %
        frequencyHz = trialJson.segments(idxSeg).meta_data.frequency_Hz;
        amplitudeMM = (max(lengthSeg)-min(lengthSeg))*0.5;
        meanValueMM = mean(lengthSeg);
      
        [maxVal,idxMax]=max(lengthSeg);
        timeOffset  = timePadding;        
        if(trialJson.segments(idxSeg).meta_data.cycles==1)
          timeOffset  = timeSeg(idxMax)-timeSeg(1)-period*0.25;
        end



        dT = timeSeg(2)-timeSeg(1);
        timeSample    = [0:dT:(timeSeg(end)-timeSeg(1))];
        dataSample    = interp1((timeSeg-timeSeg(1)),lengthSeg,timeSample);
        params.cycles = trialJson.segments(idxSeg).meta_data.cycles;
        params.type   = trialJson.segments(idxSeg).type;

        timeSegFit = timeSeg-timeSeg(1);
        errorFcn = @(arg)calcWaveError610A(...
                          arg,timeSample,dataSample,params);

       lsqOptions = optimoptions('lsqnonlin', ...
                        'Algorithm','levenberg-marquardt',...
                        'MaxFunctionEvaluations', 1000000, ...
                        'FunctionTolerance',1e-5,...
                        'MaxIterations',100,...
                        'StepTolerance',1e-5,...
                        'OptimalityTolerance',1e-4);         

        x0 = [frequencyHz;amplitudeMM;meanValueMM;timeOffset];
        lb = [frequencyHz*0.75; amplitudeMM*0.75; meanValueMM*0.75;0];
        ub = [frequencyHz*1.25; amplitudeMM*1.25; meanValueMM*1.25;timeRange];
        
        [x1,resnorm,residual,exitflag] = ...
         lsqnonlin(errorFcn,x0,lb,ub,lsqOptions);
      
        error1 = errorFcn(x1);

        lengthSinusoid.frequencyHz = x1(1);
        lengthSinusoid.amplitudeMM = x1(2);
        lengthSinusoid.timeOffset  = x1(4);
        lengthSinusoid.rmse        = sqrt(mean(error1.^2));
        lengthSinusoid.x       = timeSample;
        lengthSinusoid.y       = createWave610A(x1,timeSample,params);
        %
        % Fit a sine wave to the force profile
        %
        frequencyHz = trialJson.segments(idxSeg).meta_data.frequency_Hz;
        amplitudeN  = 0.5*(max(forceSeg)-min(forceSeg));
        meanValueN = mean(forceSeg);

        [maxVal,idxMax]=max(forceSeg);
        timeOffset  = timePadding;        
        if(trialJson.segments(idxSeg).meta_data.cycles==1)
          timeOffset  = timeSeg(idxMax)-timeSeg(1)-period*0.25;
        end

        dT = timeSeg(2)-timeSeg(1);
        timeSample    = [0:dT:(timeSeg(end)-timeSeg(1))];
        dataSample    = interp1((timeSeg-timeSeg(1)),forceSeg,timeSample);
        params.cycles = trialJson.segments(idxSeg).meta_data.cycles;
        params.type   = trialJson.segments(idxSeg).type;

        timeSegFit = timeSeg-timeSeg(1);
        errorFcn = @(arg)calcWaveError610A(...
                          arg,timeSample,dataSample,params);

       lsqOptions = optimoptions('lsqnonlin', ...
                        'Algorithm','levenberg-marquardt',...
                        'MaxFunctionEvaluations', 1000000, ...
                        'FunctionTolerance',1e-5,...
                        'MaxIterations',100,...
                        'StepTolerance',1e-5,...
                        'OptimalityTolerance',1e-4);         

        x0 = [frequencyHz;amplitudeN;meanValueN;timeOffset];
        lb = [frequencyHz*0.75; amplitudeN*0.75; meanValueN*0.75;0];
        ub = [frequencyHz*1.25; amplitudeN*1.25; meanValueN*1.25;timeRange];
        
        if(strcmp(trialJson.segments(idxSeg).type,'Step Wave'))
          amplitudeN=amplitudeN*0.75;
          x0 = [frequencyHz;amplitudeN;meanValueN;timeOffset];
          lb = [frequencyHz*0.75; amplitudeN*0.75; meanValueN*0.75;0];
          ub = [frequencyHz*1.25; amplitudeN*1.25; meanValueN*1.25;timeRange];
          
        end

        [x1,resnorm,residual,exitflag] = ...
         lsqnonlin(errorFcn,x0,lb,ub,lsqOptions);
      
        error1 = errorFcn(x1);

        forceSinusoid.frequencyHz = x1(1);
        forceSinusoid.amplitudeN  = x1(2);
        forceSinusoid.timeOffset  = x1(4);
        forceSinusoid.rmse        = sqrt(mean(error1.^2));
        forceSinusoid.x       = timeSample;
        forceSinusoid.y       = createWave610A(x1,timeSample,params);
      
        %
        % 
        %
        figure(figureStruct(indexFigSinusoid).h);

        %
        % 
        %        
        idxGainPhase = 1;
        idxFrequencyError=2;
        idxError     = 3;
        

        idxSine      = figureStruct(indexFigSinusoid).cols + segmentCount;
  
        [subPlotRow,subPlotCol]= getRowAndColumnInGrid(idxGainPhase,...
                                    figureStruct(indexFigSinusoid).rows,...
                                    figureStruct(indexFigSinusoid).cols);

        subplot('Position',reshape(subPlotPanel(subPlotRow,subPlotCol,:),1,4));
          yyaxis left;      
          frequencyHz = trialJson.segments(idxSeg).meta_data.frequency_Hz;
          plot(frequencyHz,...
               forceSinusoid.amplitudeN/lengthSinusoid.amplitudeMM,...
               'o');
          hold on;
          box off;

          xlabel('Frequency (Hz)');
          ylabel('Gain (N/mm)');

          phaseDegrees = -(forceSinusoid.timeOffset...
                          -lengthSinusoid.timeOffset)*(360) ...
                         /(1/frequencyHz);

          yyaxis right;
          plot(frequencyHz,...
               phaseDegrees,...
               'x');
          hold on;
          box off;

          ylabel('Phase (degrees)');

          titleStr = sprintf('(%i,%i) Gain and Phase',subPlotRow,subPlotCol);
          title(titleStr);

        [subPlotRow,subPlotCol]= getRowAndColumnInGrid(idxFrequencyError,...
                                    figureStruct(indexFigSinusoid).rows,...
                                    figureStruct(indexFigSinusoid).cols);

        subplot('Position',reshape(subPlotPanel(subPlotRow,subPlotCol,:),1,4));

          lengthName='Length';
          forceName='Force';        
          lengthVisible='off';
          forceVisible='off';
          if(idxSeg==1)
            lengthVisible='on';
            forceVisible='on';
          end      

          %yyaxis left;      
          frequencyHz = trialJson.segments(idxSeg).meta_data.frequency_Hz;
          plot(frequencyHz,...
               (lengthSinusoid.frequencyHz-frequencyHz)/frequencyHz,...
               'ob','MarkerFaceColor',[0,0,1],'DisplayName',lengthName,...
               'HandleVisibility',lengthVisible);
          hold on;
          box off;

          xlabel('Frequency (Hz)');
          ylabel('Frequency Error (Hz/Hz)');

          %yyaxis right;
          plot(frequencyHz,...
               (forceSinusoid.frequencyHz-frequencyHz)/frequencyHz,...
               'sr','MarkerFaceColor',[1,0,0],'DisplayName',forceName,...
               'HandleVisibility',forceVisible);
          hold on;
          box off;

          %xlabel('Frequency (Hz)');
          %ylabel('Force Frequency Error (Hz/Hz)');

          legend('Location','SouthWest');
          titleStr = sprintf('(%i,%i) Frequency Error',subPlotRow,subPlotCol);
          title(titleStr);        


        [subPlotRow,subPlotCol]= getRowAndColumnInGrid(idxError,...
                                    figureStruct(indexFigSinusoid).rows,...
                                    figureStruct(indexFigSinusoid).cols);

        subplot('Position',reshape(subPlotPanel(subPlotRow,subPlotCol,:),1,4));
        yyaxis left;
          plot(frequencyHz,lengthSinusoid.rmse/lengthSinusoid.amplitudeMM,...
               'ob','MarkerFaceColor',[0,0,1]);
          hold on;
          box off;
          xlabel('Frequency (Hz)');
          ylabel('Length Error (mm/mm)');

        yyaxis right;
          plot(frequencyHz,forceSinusoid.rmse/forceSinusoid.amplitudeN,...
               'sr','MarkerFaceColor',[1,0,0]);
          hold on;
          box off;
          ylabel('Force Error (N/N)');          
         
        titleStr = sprintf('(%i,%i) Signal-Template Error',subPlotRow,subPlotCol);
        title(titleStr);


        [subPlotRow,subPlotCol]= getRowAndColumnInGrid(idxSine,...
                                    figureStruct(indexFigSinusoid).rows,...
                                    figureStruct(indexFigSinusoid).cols);
        

        subplot('Position',reshape(subPlotPanel(subPlotRow,subPlotCol,:),1,4));

        yyaxis left;
        plot(timeSeg, lengthSeg,'-','Color',[0.75,0.75,1]);
        hold on;
        plot(lengthSinusoid.x+timeSeg(1),lengthSinusoid.y,'-','Color',[0,0,1]);
        hold on;
        box off;
        xlabel('Time (s)');
        ylabel('Length (mm)');

        yyaxis right;
        plot(timeSeg, forceSeg,'-','Color',[1,0.75,0.75]);
        hold on;
        plot(forceSinusoid.x+timeSeg(1),forceSinusoid.y,'-','Color',[1,0,0]);
        hold on;
        box off;
        ylabel('Force (N)');

        titleStr = sprintf('(%i,%i) %i Segment (%1.1f Hz)',...
                        subPlotRow,subPlotCol,segmentCount,...
                        trialJson.segments(idxSeg).meta_data.frequency_Hz);
        title(titleStr);        
  
      end  

      idxMPrevious=idxM;


      if(settings.savePlots==1 && segmentCount==numberOfSegments)          
        for i=1:1:length(figureStruct)  
          figure(figureStruct(i).h);
      
          outputPlotDir = fullfile(projectFolders.output610A_plots,...
                                  experimentsToProcess{idxExp});  
    
          outputPlotDirOverview = fullfile(outputPlotDir,'impedanceCalibration');
          if(~exist(outputPlotDirOverview,'dir'))
            mkdir(outputPlotDirOverview);
          end
    
          figure(figureStruct(i).h);
          figureStruct(i).h=configPlotExporter(...
                                figureStruct(i).h, ...
                                figureStruct(i).pageWidth,...
                                figureStruct(i).pageHeight);
        
          fullFilePathNoExt = [];
          if(~isempty(keyWordFilterSinusoidal.metaDataFileName.include))
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

end








success=1;