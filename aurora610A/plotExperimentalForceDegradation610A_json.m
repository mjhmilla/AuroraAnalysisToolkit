function success = plotExperimentalForceDegradation610A_json(...
                          experimentsToProcess,...
                          keyWordFilter,...
                          settings,...
                          projectFolders, ...
                          verbose)

success = 0;

fprintf('\n\nDegradation Data Plots\n\n');

indexFigExpFl   =1;

figureStruct(1)   = struct('h',[],'name','','pageWidth',0,'pageHeight',0);
figureStruct(1).h = figure;
figureStruct(1).name = ['fig_degradation'];

csVibrant = getPaulTolColourSchemes('vibrant');
lineInfo.colours = [csVibrant.blue;csVibrant.teal];
lineInfo.measurement = [];
lineInfo.indexColor  = 1;
%
% Count the number of trials and the number of segments
%
experimentCount=0;
for idxExp =1:1:length(experimentsToProcess)
  expFolder = fullfile(projectFolders.data610A,...
                       experimentsToProcess{idxExp});
  expStr = fileread(fullfile(expFolder,...
                             [experimentsToProcess{idxExp},'.json']));
  expJson = jsondecode(expStr);
  
  scanSummary = scanExperiment610A(experimentsToProcess{idxExp},...
                                   keyWordFilter,...
                                   projectFolders,...
                                   verbose);    
 
  if(sum(scanSummary.passesAllFilters) > 0)
    experimentCount=experimentCount+1;
  end

end

if(experimentCount==0)
  return;
end
%
% Degradation plots
%  
numberOfHorizontalPlotColumnsGeneric  = 2;
numberOfVerticalPlotRowsGeneric       = experimentCount;


plotWidth              = ones(1,numberOfHorizontalPlotColumnsGeneric).*6;
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

figureStruct(indexFigExpFl).rows = numberOfVerticalPlotRowsGeneric;
figureStruct(indexFigExpFl).cols = numberOfHorizontalPlotColumnsGeneric;
figureStruct(indexFigExpFl).pageWidth=pageWidthTrial;
figureStruct(indexFigExpFl).pageHeight=pageHeightTrial;


%
% Loop through the data and plot it
%
yLeftDataLimits = [inf,-inf];
yRightDataLimits = [inf,-inf];


for idxExp = 1:1:length(experimentsToProcess)

  expFolder = fullfile(projectFolders.data610A,...
                       experimentsToProcess{idxExp});
  expStr = fileread(fullfile(expFolder,...
                            [experimentsToProcess{idxExp},'.json']));
  expJson = jsondecode(expStr);

  dataInfo = getDataColumnLabelsSettings(expJson);
  
  verbose=0;
  scanSummary = scanExperiment610A(experimentsToProcess{idxExp},...
                                   keyWordFilter,...
                                   projectFolders,...
                                   verbose);    

  setOfTrials = find(scanSummary.passesAllFilters > 0);
  setOfUniqueMeasurements = [];
  for i=1:1:length(scanSummary.indexTrial)
    if(scanSummary.passesAllFilters(i)==1)
      if(isempty(setOfUniqueMeasurements))
        setOfUniqueMeasurements = scanSummary.indexMeasurement(i);
      else
        isUnique = 1;
        for j=1:1:length(setOfUniqueMeasurements)
          if(setOfUniqueMeasurements(j)==scanSummary.indexMeasurement(i))
            isUnique=0;
          end
        end
        if(isUnique==1)
          setOfUniqueMeasurements=[setOfUniqueMeasurements;...
                                   scanSummary.indexMeasurement(i)];
        end
      end
    end
  end
   
  %
  % Extract and plot the force-length data
  %

  degradationSet = ...
    struct('indexMeasurement',[],'activationCount',[],'force',[]);

  %Populate the metaDataStruct
  metaDataCache = getEmptyMetaDataCache610A();
  activationCount=0;
  labelVerticalAlignment = 'top';
  labelOffset = -0.1;
  measurementStart=0;

  lineInfo.measurement = [];
  
  for idxSetOfTrials = 1:1:length(setOfTrials)
    if(idxSetOfTrials==1)
      fprintf('\t%s\n',experimentsToProcess{idxExp});
      fprintf('\t\t%s\t%s\t%s\n',...
        'Tr.',...
        'Mea.',...
        'Seq.');
    end

    idxTrial = setOfTrials(idxSetOfTrials);
    idxM = scanSummary.indexMeasurement(idxTrial);
    idxS = scanSummary.indexSequence(idxTrial);
    metaDataCache = getMeasurement610A(idxM,idxS,idxTrial,...
                                       expJson,expFolder,...
                                       metaDataCache);

    assert(metaDataCache.indexTrial == idxTrial ...
           && metaDataCache.indexMeasurement == idxM ...
           && metaDataCache.indexSequence == idxS, ...
           'Error: incorrect metadata cache retrieved');

    fprintf('\t\t%i\t%i\t%i\t%s\n',...
            idxTrial,...
            idxM,...
            idxS,...
            expJson.measurements{idxM});

    trialJson = metaDataCache.metaDataJson; 
      
    ddfData610 = readAuroraData610A(metaDataCache.dataFilePath,...
                    settings.readProtocolArray);
  
    %
    %Get the default time unit
    %
    units = getUnits610A(expJson,trialJson,ddfData610);

    %
    % Extract the data to plot
    %
    timeSeries = ddfData610.data.Sample.Values ...
               ./ddfData610.Sample_Frequency_Hz;  

    indices.active =[];
    indices.passive=[];

    flag_stimulusFound = 0;
    for idxSeg = 1:1:length(trialJson.segments)
      if(strcmp(trialJson.segments(idxSeg).type,'Stimulus-Tetanus'))

        assert(flag_stimulusFound==0,...
          'Error: only one stimulus should be present in this trial');
        flag_stimulusFound = 1;
        timeA0 =  trialJson.segments(idxSeg).time_s(1) ...
                + settings.activationTime;
        timeA1 = trialJson.segments(idxSeg).time_s(2);

        idxA0 = find(timeSeries >= timeA0,1,'first');
        idxA1 = find(timeSeries <= timeA1,1,'last');

        activationCount=activationCount+1;
        indices.active = [idxA0,idxA1];

        timeP0 =  trialJson.segments(idxSeg).time_s(1);
        timeP1 = trialJson.segments(idxSeg).time_s(2) ...
                 + settings.deactivationTime;        

        idxP0 =  1;
        idxP1 = find(timeSeries <= timeP0,1,'last');

        idxP2 = find(timeSeries >= timeP1,1,'first');
        idxP3 = length(timeSeries);

        indices.passive = [idxP0,idxP1; idxP2,idxP3];
      end
    end

    trialLength = mean(ddfData610.data.(dataInfo.L.ch).Values);

    activePassiveForceSS = ...
      getSummaryStatistics(...
                      ddfData610.data.(dataInfo.F.ch).Values(...
                        indices.active(1,1):1:indices.active(1,2)));
    passiveForceSS = ...
      getSummaryStatistics(...
                     [ddfData610.data.(dataInfo.F.ch).Values(...
                        indices.passive(1,1):1:indices.passive(1,2));...
                      ddfData610.data.(dataInfo.F.ch).Values(...
                        indices.passive(2,1):1:indices.passive(2,2))]);

    activeForceSS = activePassiveForceSS;
    fieldsToUpdate = {'y','mean','median','min','max'};
    for i=1:1:length(fieldsToUpdate)
      activeForceSS.(fieldsToUpdate{i}) = ...
         activeForceSS.(fieldsToUpdate{i}) ...
        -passiveForceSS.mean;
    end

    degradationSet.indexMeasurement = ...
      [degradationSet.indexMeasurement; ...
       idxM];
    degradationSet.activationCount = ...
      [degradationSet.activationCount;...
       activationCount];
    degradationSet.force = [degradationSet.force;...
                            activeForceSS.max];    


    %
    % Plot the trial data
    %
    lineColor = [0,0,0];
    if(isempty(lineInfo.measurement))
      lineInfo.measurement=idxM;
    end
    if(lineInfo.measurement~=idxM)
      if(lineInfo.indexColor==1)
        lineInfo.indexColor=2;
      else
        lineInfo.indexColor=1;
      end
    end
    lineColorA = lineInfo.colours(lineInfo.indexColor,:);
    lineColorB = lineColorA.*(0.5) + [0.5,0.5,0.5];

    figure(figureStruct(indexFigExpFl).h);
    subplot('Position',reshape(subPlotPanelTrial(idxExp,1,:),1,4));
      plotBoxWhiskerData(activationCount,activeForceSS,0.5,...
                          lineColorA,lineColorB);
      hold on;
      text(activationCount, activeForceSS.median+labelOffset,...
        sprintf('%i',activationCount),...
           'HorizontalAlignment','center',...
           'VerticalAlignment',labelVerticalAlignment,...
           'FontSize',6);
      hold on;
      plotBoxWhiskerData(activationCount,passiveForceSS,0.5,...
                          [1,1,1].*0,[1,1,1].*0.5);
      hold on;
    
      labelOffset=labelOffset*-1;
      if(strcmp(labelVerticalAlignment,'top'))
        labelVerticalAlignment='bottom';
      else
        labelVerticalAlignment='top';
      end

    if(idxTrial==setOfTrials(end))
      axis tight;
      yAxis = ylim;
      ylim([0,max(yAxis)]);
      box off;
      xlabel(['Length (',units.length,')']);
      ylabel(['Force (',units.force,')']);

      titleStr = strrep(experimentsToProcess{idxExp},'_','\_');
      title({'Force-Length-Relation', titleStr});
      box off;
    end
    

    if(idxTrial==setOfTrials(1))
      subplot('Position',reshape(subPlotPanelTrial(idxExp,2,:),1,4));
      plot( timeSeries,...
            ddfData610.data.(dataInfo.F.ch).Values,...
            '-','Color',[0,0,0]);
      hold on;
      
      axis tight;
      yAxis = ylim;
      ylim([0,max(yAxis)]);
      yAxis = ylim;

      text(0,max(yAxis),sprintf('%1.1f %s',trialLength, units.length),...
           'HorizontalAlignment','left',...
           'VerticalAlignment','top',...
           'FontSize',10);
      hold on;

      idxA = indices.active(1,1);
      idxB = indices.active(1,2);
      plot([timeSeries(idxA),timeSeries(idxB),timeSeries(idxB),...
            timeSeries(idxA),timeSeries(idxA)],...
           [0,0,max(yAxis),max(yAxis),0],...
           '-','Color',[1,0,0]);
      hold on;
      text(timeSeries(idxA),0,'Active',...
          'HorizontalAlignment','left',...
          'VerticalAlignment','bottom',...
          'FontSize',6,...
          'Color',[1,0,0]);
      hold on;
      idxA = indices.passive(1,1);
      idxB = indices.passive(1,2);
      plot([timeSeries(idxA),timeSeries(idxB),timeSeries(idxB),...
            timeSeries(idxA),timeSeries(idxA)],...
           [0,0,max(yAxis),max(yAxis),0],...
           '-','Color',[0,0,1]);
      hold on;
      text(timeSeries(idxA),0,'Passive',...
          'HorizontalAlignment','left',...
          'VerticalAlignment','bottom',...
          'FontSize',6,...
          'Color',[0,0,1]);
      hold on;

      idxA = indices.passive(2,1);
      idxB = indices.passive(2,2);
      plot([timeSeries(idxA),timeSeries(idxB),timeSeries(idxB),...
            timeSeries(idxA),timeSeries(idxA)],...
           [0,0,max(yAxis),max(yAxis),0],...
           '-','Color',[0,0,1]);
      box off;
      text(timeSeries(idxA),0,'Passive',...
          'HorizontalAlignment','left',...
          'VerticalAlignment','bottom',...
          'FontSize',6,...
          'Color',[0,0,1]);
      hold on;

      xlabel(['Time (',units.time,')']);
      ylabel(['Force (',units.force,')']);

      titleStr = strrep(experimentsToProcess{idxExp},'_','\_');
      title({'Time Series', titleStr});
      
    end
  end

  here=1;
  %
  % Fit a degradation model to the data
  %
  setOfMeasurements = unique(degradationSet.indexMeasurement);

  for idxM = 1:1:length(setOfUniqueMeasurements)
    idxData = find(degradationSet.indexMeasurement ...
      == setOfUniqueMeasurements(idxM));

    y = degradationSet.force(idxData);
    a = degradationSet.activationCount(idxData);
    aMin = min(a)-1;
    a = a-aMin;

    A = [a ones(size(a))];
    x = (A'*A)\(A'*y);

    yMdl = A*x;
    figure(figureStruct(indexFigExpFl).h);
    subplot('Position',reshape(subPlotPanelTrial(idxExp,1,:),1,4));
      plot((a+aMin),yMdl,'-','Color',[1,0,0]);
      hold on;


    xTxt=0;
    yTxt=0;
    if(rem(idxM,2)==0)
      xTxt = a(1)+aMin;
      yTxt = yMdl(1)+6*abs(labelOffset);

    else
      xTxt = a(1)+aMin;
      yTxt = yMdl(end)-6*abs(labelOffset);
      if(yTxt < 2*abs(labelOffset))
        yTxt=abs(labelOffset)*2;
      end

    end

    yNorm=x(2);

    text( xTxt, yTxt,...
          sprintf('y=(%1.3e)a + (%1.3e)',x(1),x(2)),...
          'HorizontalAlignment','left',...
          'VerticalAlignment','top',...
          'FontSize',6);
    text( xTxt, yTxt-abs(labelOffset),...
          sprintf('%s=(%1.3e)a + (%1.3e)','$$\tilde{y}$$',...
                   x(1)/yNorm,x(2)/yNorm),...
          'HorizontalAlignment','left',...
          'VerticalAlignment','top',...
          'FontSize',6);
    
    hold on;

  end

end





      

if(settings.savePlots==1)

  for i=1:1:length(figureStruct)  


    outputPlotDir = fullfile(projectFolders.output610A_plots,...
                            '00_degradation');

    if(~exist(outputPlotDir,'dir'))
      mkdir(outputPlotDir);
    end

    figure(figureStruct(i).h);
    figureStruct(i).h=configPlotExporter(...
                          figureStruct(i).h, ...
                          figureStruct(i).pageWidth,...
                          figureStruct(i).pageHeight);
  
    fullFilePathNoExt = [];
    if(~isempty(keyWordFilter.metaDataFileName.include))
      fullFilePathNoExt = ...
        fullfile(outputPlotDir,...
                      [figureStruct(i).name,'keyWord_',...
                      keyWordFilter.metaDataFileName.include]);
    else
      fullFilePathNoExt = ...
        fullfile(outputPlotDir,...
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
end

for i=1:1:length(figureStruct)
  clf(figureStruct(i).h);
  figureStruct(i).pageWidth=nan;
  figureStruct(i).pageHeight=nan;
  figureStruct(i).rows=nan;
  figureStruct(i).cols=nan;    
end



success=1;