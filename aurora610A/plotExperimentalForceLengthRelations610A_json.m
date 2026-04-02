function success = plotExperimentalForceLengthRelations610A_json(...
                          experimentsToProcess,...
                          keyWordFilter,...
                          settings,...
                          projectFolders)

success = 0;

fprintf('\n\nForce-Length Relation Plots\n\n');

indexFigExpFl   =1;

figureStruct(1) = struct('h',[],'name','','pageWidth',0,'pageHeight',0);
figureStruct(1).h = figure;

figureStruct(1).name = ['fig_forceLengthRelations'];

%
% Count the number of trials and the number of segments
%
forceLengthExperimentCount=0;
for idxExp =1:1:length(experimentsToProcess)
  expFolder = fullfile(projectFolders.data610A,...
                       experimentsToProcess{idxExp});
  expStr = fileread(fullfile(expFolder,...
                             [experimentsToProcess{idxExp},'.json']));
  expJson = jsondecode(expStr);
  
  verbose=0;
  scanSummary = scanExperiment610A(experimentsToProcess{idxExp},...
                                   keyWordFilter,...
                                   projectFolders,...
                                   verbose);    
 
  if(sum(scanSummary.passesAllFilters) > 0)
    forceLengthExperimentCount=forceLengthExperimentCount+1;
  end

end

if(forceLengthExperimentCount==0)
  return;
end
%
% Experiment force-length plots
%  
numberOfHorizontalPlotColumnsGeneric  = 2;
numberOfVerticalPlotRowsGeneric       = forceLengthExperimentCount;


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

  verbose=0;
  scanSummary = scanExperiment610A(experimentsToProcess{idxExp},...
                                   keyWordFilter,...
                                   projectFolders,...
                                   verbose);    

  setOfTrials = find(scanSummary.passesAllFilters > 0);
   
  %
  % Extract and plot the force-length data
  %
  meanActiveForceLength.length = [];
  meanActiveForceLength.force = [];

  %Populate the metaDataStruct
  metaDataCache = getEmptyMetaDataCache610A();

  for idxSetOfTrials = 1:1:length(setOfTrials)
    if(idxSetOfTrials==1)
      fprintf('\t%s\n',experimentsToProcess{idxExp});
    end

    idxTrial = setOfTrials(idxSetOfTrials);
    idxM = scanSummary.indexMeasurement(idxTrial);
    idxS = scanSummary.indexSequence(idxTrial);
    metaDataCache = getMeasurement610A(idxM,idxS,idxTrial,expJson,expFolder,...
                                       metaDataCache);
    assert(metaDataCache.indexTrial == idxTrial ...
           && metaDataCache.indexMeasurement == idxM ...
           && metaDataCache.indexSequence == idxS, ...
           'Error: incorrect metadata cache retrieved');

    fprintf('\t\t%s\n',expJson.measurements{idxTrial});

    trialJson = metaDataCache.metaDataJson; 
      
    ddfData610 = readAuroraData610A(metaDataCache.dataFilePath,...
                    settings.readProtocolArray);
  
    %
    %Get the default time unit
    %
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
  
    %
    % Get the length unit
    %
    lengthUnit  = ddfData610.Units{end-1};
    lengthScale = ddfData610.Scale_units_V(end-1);
    if(lengthScale==1000)
      lengthUnit = lengthUnit(1,2:end);
    end

    %
    % Get the force unit
    %
    forceUnit  = ddfData610.Units{end};
    forceScale = ddfData610.Scale_units_V(end);
    if(forceScale == 1000)
      forceUnit = forceUnit(1,2:end);
    end
      
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

    trialLength = mean(ddfData610.data.AI0.Values);

    activePassiveForceSS = ...
      getSummaryStatistics(...
                      ddfData610.data.AI1.Values(...
                        indices.active(1,1):1:indices.active(1,2)));
    passiveForceSS = ...
      getSummaryStatistics(...
                     [ddfData610.data.AI1.Values(...
                        indices.passive(1,1):1:indices.passive(1,2));...
                      ddfData610.data.AI1.Values(...
                        indices.passive(2,1):1:indices.passive(2,2))]);

    activeForceSS = activePassiveForceSS;
    fieldsToUpdate = {'y','mean','median','min','max'};
    for i=1:1:length(fieldsToUpdate)
      activeForceSS.(fieldsToUpdate{i}) = ...
         activeForceSS.(fieldsToUpdate{i}) ...
        -passiveForceSS.mean;
    end

    meanActiveForceLength.length = [meanActiveForceLength.length,...
                                    trialLength];
    meanActiveForceLength.force = [meanActiveForceLength.force,...
                                    activeForceSS.median];    
    %
    % Plot the trial data
    %
    figure(figureStruct(indexFigExpFl).h);
    subplot('Position',reshape(subPlotPanelTrial(idxExp,1,:),1,4));
      plotBoxWhiskerData(trialLength,activePassiveForceSS,0.5,...
                          [1,1,1].*0.5,[1,1,1].*0.75);
      hold on;
      plotBoxWhiskerData(trialLength,activeForceSS,0.5,...
                          [0,0,1],[0.5,0.5,1]);
      hold on;
      text(trialLength, activeForceSS.min,sprintf('%i',idxTrial),...
           'HorizontalAlignment','center',...
           'VerticalAlignment','top',...
           'FontSize',8);
      hold on;
      plotBoxWhiskerData(trialLength,passiveForceSS,0.5,...
                          [1,1,1].*0,[1,1,1].*0.5);
      hold on;
    
    if(idxTrial==setOfTrials(end))
      axis tight;
      yAxis = ylim;
      ylim([0,max(yAxis)]);
      box off;
      xlabel(['Length (',lengthUnit,')']);
      ylabel(['Force (',forceUnit,')']);

      titleStr = strrep(experimentsToProcess{idxExp},'_','\_');
      title({'Force-Length-Relation', titleStr});
      box off;
    end
    

    if(idxTrial==setOfTrials(1))
      subplot('Position',reshape(subPlotPanelTrial(idxExp,2,:),1,4));
      plot(timeSeries,ddfData610.data.AI1.Values,'-','Color',[0,0,0]);
      hold on;
      
      axis tight;
      yAxis = ylim;
      ylim([0,max(yAxis)]);
      yAxis = ylim;

      text(0,max(yAxis),sprintf('%1.1f %s',trialLength, lengthUnit),...
           'HorizontalAlignment','left',...
           'VerticalAlignment','top',...
           'FontSize',10);
      hold on;

      idxA = indices.active(1,1);
      idxB = indices.active(1,2);
      plot([timeSeries(idxA),timeSeries(idxB),timeSeries(idxB),timeSeries(idxA),timeSeries(idxA)],...
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
      plot([timeSeries(idxA),timeSeries(idxB),timeSeries(idxB),timeSeries(idxA),timeSeries(idxA)],...
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
      plot([timeSeries(idxA),timeSeries(idxB),timeSeries(idxB),timeSeries(idxA),timeSeries(idxA)],...
           [0,0,max(yAxis),max(yAxis),0],...
           '-','Color',[0,0,1]);
      box off;
      text(timeSeries(idxA),0,'Passive',...
          'HorizontalAlignment','left',...
          'VerticalAlignment','bottom',...
          'FontSize',6,...
          'Color',[0,0,1]);
      hold on;

      xlabel(['Time (',defaultTimeUnit,')']);
      ylabel(['Force (',forceUnit,')']);

      titleStr = strrep(experimentsToProcess{idxExp},'_','\_');
      title({'Time Series', titleStr});
      
    end
  end

  %
  % Fit a line to the descending limb
  %
  [lengthSorted, idxLengthSort] = sort(meanActiveForceLength.length);
  meanActiveForceLength.length  = lengthSorted;
  meanActiveForceLength.force   = meanActiveForceLength.force(idxLengthSort);
  
  idxD0 = 2;
  df = inf;
  while df > 0 
    idxD0 =idxD0+1;
    df = meanActiveForceLength.force(idxD0) ...
        -meanActiveForceLength.force(idxD0-1);  
  end
  
  idxOpt = idxD0-1;
  
  idxD1 = length(meanActiveForceLength.force);
  
  Av = meanActiveForceLength.length(idxD0:idxD1)';
  b  = meanActiveForceLength.force(idxD0:idxD1)';
  A  = [Av,ones(size(Av))];
  x  = (A'*A)\(A'*b);
  
  
  lopt = meanActiveForceLength.length(idxOpt);
  lzero = -x(2)/x(1);
  
  lfit = [meanActiveForceLength.length(idxD0);lzero];
  
  A0 = [lfit(1),1];
  b0 = A0*x;
  A1 = [lfit(2),1];
  b1 = A1*x;
  
  ffit = [b0;b1];
  
  optimalFiberLength = (lzero-lopt)/0.6;
  
  xt = xticks;
  xt = [xt, round(lzero,1)];
  xticks(xt);
  
  xl = xlim;
  xlim([min(xt)-0.01,max(xt)+0.01]);
  
  yt = yticks;
  dy = (max(yt)-min(yt))*0.1;
  
  figure(figureStruct(indexFigExpFl).h);
      subplot('Position',reshape(subPlotPanelTrial(idxExp,1,:),1,4));
        plot(lfit,ffit,'-','Color',[1,0,0]);
        hold on;
        plot([1,1].*lopt,[0,1].*(max(meanActiveForceLength.force)+dy),...
            '-','Color',[1,1,1].*0.5);
        hold on;
        text(lopt,max(meanActiveForceLength.force)+2*dy,'$$\ell_{max}$$',...
            'HorizontalAlignment','center',...
            'VerticalAlignment','top',...
            'FontSize',8);
        hold on;
        plot([1,1].*lopt,[0,1].*dy,...
            '-','Color',[1,1,1].*0.5);
        hold on;      
        text(lzero,dy*2,'$$\ell_{zero}$$',...
            'HorizontalAlignment','center',...
            'VerticalAlignment','top',...
            'FontSize',8);
        hold on;
  
        hold on;
        text(min(xt),max(yt),...
              sprintf('%s\n%s%1.1f %s',...
              '$$\ell_o = \frac{\ell_{zero}-\ell_{max}}{0.6}$$',...
              '$$\ell_o = $$',optimalFiberLength,lengthUnit),...
              'HorizontalAlignment','left',...
              'VerticalAlignment','top',...
              'FontSize',8);
        hold on;
  
        xAxis = xlim;
        dx = diff(xAxis)*0.1;
        xlim([xAxis(1)-dx,xAxis(2)+dx]);    
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