function figH = plotFrequencyResponse600A(...
                      figH,...
                      experimentName, ...
                      trialNames, ...
                      segmentId,...
                      activeState,...
                      legendEntries,...
                      trialColors,...                      
                      projectFolders,...
                      flag_storageLoss0_stiffnessDamping1_titles,...
                      flag_0Presentation_1Publication,...
                      flag_savePlot)


numberOfHorizontalPlotColumnsGeneric  = 3;
numberOfVerticalPlotRowsGeneric       = 2;

switch flag_0Presentation_1Publication,...
  case 0
    plotWidth                 = ones(1,numberOfHorizontalPlotColumnsGeneric).*3;
    plotHeight                = ones(numberOfVerticalPlotRowsGeneric,1).*2.25;
    plotHorizMarginCm         = 1;
    plotVertMarginCm          = 1.25;
    baseFontSize              = 6;

  case 1
    plotWidth                 = ones(1,numberOfHorizontalPlotColumnsGeneric).*4;
    plotHeight                = ones(numberOfVerticalPlotRowsGeneric,1).*4;
    plotHorizMarginCm         = 2;
    plotVertMarginCm          = 2;
    baseFontSize              = 8;

  otherwise
    assert(0,'Error: flag_0Presentation_1Publication should be 0 or 1');
end

[subPlotPanelZ, pageWidthZ,pageHeightZ]= ...
  plotConfigGeneric(  numberOfHorizontalPlotColumnsGeneric,...
            numberOfVerticalPlotRowsGeneric,...
            plotWidth,...
            plotHeight,...
            plotHorizMarginCm,...
            plotVertMarginCm,...
            baseFontSize); 
%Enlarge the first horozontal space

dx =  (subPlotPanelZ(1,2,1))...
     -(subPlotPanelZ(1,1,1)+subPlotPanelZ(1,1,3));
for i=2:1:3
  for j=1:1:2
    subPlotPanelZ(j,i,1)=subPlotPanelZ(j,i,1)+dx;
  end
end  


xySeries(6)=struct('x','','yL','','yR','',...
                  'segment',segmentId,...
                  'row',nan,'col',nan,...
                  'xScale',1,'yLScale',1,'yRScale',1,...
                  'xTicks',[],'yLTicks',[],'yRTicks',[],...
                  'xLim',[],'yLLim',[],'yRLim',[],...
                  'xLabel','','yLLabel','','yRLabel','',...
                  'idxData',[],'title','');

xySeriesEmpty=struct('x','','yL','','yR','',...
                    'segment',segmentId,...
                    'row',nan,'col',nan,...
                    'xScale',1,'yLScale',1,'yRScale',1,...
                    'xTicks',[],'yLTicks',[],'yRTicks',[],...
                    'xLim',[],'yLLim',[],'yRLim',[],...
                    'xLabel','','yLLabel','','yRLabel','',...
                    'idxData',[],'title','');




figure(figH);

for idxTrial=1:1:length(trialNames)

  filePath = fullfile(projectFolders.output600A_json,...
                      experimentName,...
                      trialNames{idxTrial});
  fileData = fileread(filePath{1});
  jsonData = jsondecode(fileData);

  %%
  % configure the plot
  %%
  idx=1;
  for i=1:1:3
    for j=1:1:2
      xySeries(idx)=xySeriesEmpty;
      xySeries(idx).row=j;
      xySeries(idx).col=i;
      xySeries(idx).xScale=1;
      xySeries(idx).yLScale=1;
      xySeries(idx).yRScale=1;
      segId = xySeriesEmpty.segment;
      if(idx>1)
        idxMin = round(length(jsonData(segId).segment.H.coherenceSq)*0.5);
        idxMax = idxMin;
    
        while(jsonData(segId).segment.H.coherenceSq(idxMin)>= ...
              jsonData(segId).segment.H.coherenceSquaredThreshold ...
              && idxMin > 1)
          idxMin =idxMin-1;
        end
        idxMin=idxMin+1;
        while(jsonData(segId).segment.H.coherenceSq(idxMax)>= ...
              jsonData(segId).segment.H.coherenceSquaredThreshold ...
              && idxMax < length(jsonData(segId).segment.H.coherenceSq))
          idxMax =idxMax+1;
        end
        idxMax=idxMax-1;
        jsonData(segId).segment.H.idxBWC2=[idxMin,idxMax];
  
        jsonData(segId).segment.H.bandwidthHzC2 = ...
          [jsonData(segId).segment.H.frequencyHz(idxMin),...
           jsonData(segId).segment.H.frequencyHz(idxMax)];
  
        xySeries(idx).xTicks=round(jsonData(segId).segment.H.bandwidthHzC2,1)';
        xySeries(idx).xLim  =jsonData(segId).segment.H.bandwidthHz' + [-1,1].*(sqrt(eps));    
        xySeries(idx).x = 'frequencyHz';
        xySeries(idx).xLabel='Frequency (Hz)';      
      end
  
      switch idx
        case 1
          xySeries(idx).x = 'time';
          xySeries(idx).yL = 'x';
          xySeries(idx).yR = 'y';
          xySeries(idx).xLabel='Time (s)';
          xySeries(idx).yLLabel= 'Length($$\Delta$$mm)';
          xySeries(idx).yRLabel='Force ($$\Delta$$mN)';  
  
          xySeries(idx).xLim = [min(jsonData(segId).segment.H.time),...
                                max(jsonData(segId).segment.H.time)];
          xySeries(idx).yLLim = [min(jsonData(segId).segment.H.x),...
                                max(jsonData(segId).segment.H.x)];
          xySeries(idx).yRLim = [min(jsonData(segId).segment.H.y),...
                                max(jsonData(segId).segment.H.y)];
  
          %Make y lim symmetric;
          xySeries(idx).yLLim = [-1,1].*max(abs(xySeries(idx).yLLim));
          xySeries(idx).yRLim = [-1,1].*max(abs(xySeries(idx).yRLim));
  
  
          xySeries(idx).idxData = [1:1:length(jsonData(segId).segment.H.time)];
          ampl = (jsonData(segId).segment.summary.length.max...
                 -jsonData(segId).segment.summary.length.min)*0.5;
          xySeries(idx).title='A.';
  %         xySeries(idx).title=...
  %           {sprintf('A. Fiber (%1.1f Lo at %1.1f %s)',...
  %             jsonData(segId).segment.summary.length.mean,...
  %             jsonData(segId).segment.summary.temperature.mean,...
  %             '$$^\circ$$C'),...
  %           sprintf('Wave (0-%i Hz %1.2f Lo)',...
  %             jsonData(segId).segment.H.bandwidthHz(2),...
  %             ampl)};
        case 2
          xySeries(idx).yL = 'coherenceSq';
          xySeries(idx).yLLabel='Coherence-Sq';
          xySeries(idx).yLTicks=[0,jsonData(segId).segment.H.coherenceSquaredThreshold,1];
          xySeries(idx).yLLim=[0,1]+[-1,1].*sqrt(eps);
          xySeries(idx).idxData=...
            [jsonData(segId).segment.H.idxBWC2(1):1:jsonData(segId).segment.H.idxBWC2(2)];
          xySeries(idx).title={'B.'};
          
        case 3
          xySeries(idx).yL = 'gain';
          xySeries(idx).yLLabel='Gain (mN/mm)';      
          xySeries(idx).idxData=...
            [jsonData(segId).segment.H.idxBWC2(1):1:jsonData(segId).segment.H.idxBWC2(2)];
          xySeries(idx).title={'C. Gain (G)'};
          xySeries(idx).yLLim=[0,12.5]+[-1,1].*sqrt(eps);
        case 4
          xySeries(idx).yL = 'phase';
          xySeries(idx).yLScale=(180/pi);
          xySeries(idx).yLLabel='Phase ($$^\circ$$)';
          xySeries(idx).idxData=...
            [jsonData(segId).segment.H.idxBWC2(1):1:jsonData(segId).segment.H.idxBWC2(2)];
          xySeries(idx).title={'D. Phase ($$\theta$$)'};
          xySeries(idx).yLLim=[0,22.5]+[-1,1].*sqrt(eps);
  
        case 5
          xySeries(idx).yL = 'storage';
          xySeries(idx).yLLabel='Storage (mN/mm)';     
          xySeries(idx).idxData=...
            [jsonData(segId).segment.H.idxBWC2(1):1:jsonData(segId).segment.H.idxBWC2(2)];
          xySeries(idx).title={'E. Storage  ($$S = G \cos \theta$$)'};
          xySeries(idx).yLLim=[0,12.5]+[-1,1].*sqrt(eps);
  
          if(flag_storageLoss0_stiffnessDamping1_titles==1)
            xySeries(idx).yLLabel='Stiffness (mN/mm)';     
            xySeries(idx).idxData=...
              [jsonData(segId).segment.H.idxBWC2(1):1:jsonData(segId).segment.H.idxBWC2(2)];
            xySeries(idx).title={'E. Stiffness  ($$K = G \cos \theta$$)'};
          end
  
        case 6
          xySeries(idx).yL = 'loss';
          xySeries(idx).yLLabel='Loss (mN/mm)';  
          xySeries(idx).idxData=...
            [jsonData(segId).segment.H.idxBWC2(1):1:jsonData(segId).segment.H.idxBWC2(2)];
          xySeries(idx).title={'F. Loss ($$L = G \sin \theta$$)'};
          xySeries(idx).yLLim=[0,3.5]+[-1,1].*sqrt(eps);
  
          if(flag_storageLoss0_stiffnessDamping1_titles==1)
            xySeries(idx).yLLabel='Damping (mN/mm)';     
            xySeries(idx).idxData=...
              [jsonData(segId).segment.H.idxBWC2(1):1:jsonData(segId).segment.H.idxBWC2(2)];
            xySeries(idx).title={'F. Damping  ($$\beta = G \sin \theta$$)'};
          end
  
  
        otherwise
          assert(0,'Error: unrecognized subplot index');
      end
  
      idx=idx+1;
    end
  end

  
  %%
  % Plot the data
  %%
  for idx = 1:1:length(xySeries)
  
    segId = xySeries(idx).segment;
    subplot('Position',...
            reshape(subPlotPanelZ(...
                      xySeries(idx).row,xySeries(idx).col,:),1,4));
  
    xSeriesColor=trialColors(idxTrial,:);
    if(~isempty(xySeries(idx).yR))
      yyaxis left;
      xSeriesColor=[0,0,0];
    end
  
    idxData=xySeries(idx).idxData;
  
    if(~(idxTrial > 1 && strcmp(xySeries(idx).x,'time')))
      plot(jsonData(segId).segment.H.(xySeries(idx).x)(idxData).*xySeries(idx).xScale,...
           jsonData(segId).segment.H.(xySeries(idx).yL)(idxData).*xySeries(idx).yLScale,...
           '-','Color',xSeriesColor,'HandleVisibility','off',...
           'LineWidth',0.5);
      hold on;
    end
  
    if(~isempty(xySeries(idx).xTicks))
      xticks(xySeries(idx).xTicks);
    end
    if(~isempty(xySeries(idx).xLim))
      xlim(xySeries(idx).xLim);
    end
  
    if(~isempty(xySeries(idx).yLLim))
      ylim(xySeries(idx).yLLim);
    else
      yLimits = [min(0,min(jsonData(segId).segment.H.(xySeries(idx).yL)(idxData))),...
                 max(0,max(jsonData(segId).segment.H.(xySeries(idx).yL)(idxData)))];
      yLimits=yLimits.*xySeries(idx).yLScale;
      ylim(yLimits);   
    end
    if(~isempty(xySeries(idx).yLTicks))
      yticks(xySeries(idx).yLTicks);
    end
  
    xlabel(xySeries(idx).xLabel);
    ylabel(xySeries(idx).yLLabel);
  
    if(~isempty(xySeries(idx).yR))
      yyaxis right;
      plot(jsonData(segId).segment.H.(xySeries(idx).x)(idxData).*xySeries(idx).xScale,...
           jsonData(segId).segment.H.(xySeries(idx).yR)(idxData).*xySeries(idx).yRScale,...
           '-','Color',trialColors(idxTrial,:),'DisplayName',legendEntries{idxTrial},...
           'LineWidth',0.5);
      hold on;
      if(~isempty(xySeries(idx).yRLim))
        ylim(xySeries(idx).yRLim);
      else
        yLimits = [min(0,min(jsonData(segId).segment.H.(xySeries(idx).yR)(idxData))),...
                   max(0,max(jsonData(segId).segment.H.(xySeries(idx).yR)(idxData)))];
        yLimit=yLimits.*xySeries(idx).yRScale;
        ylim(yLimits);   
      end
      if(~isempty(xySeries(idx).yRTicks))
        yticks(xySeries(idx).yRTicks);
      end
  
  
      ylabel(xySeries(idx).yRLabel);
  
      legend;
  
      ax = gca;
      ax.YAxis(1).Color = [0,0,0];
      ax.YAxis(2).Color = trialColors(idxTrial,:);    
    end
  
    if(strcmp(xySeries(idx).yL,'storage') || strcmp(xySeries(idx).yL,'loss'))
      switch(activeState(idxTrial))
        case 0
          pJsonData=jsonData;
        case 1
          tJsonData=jsonData;        
        otherwise
          assert(0,'Error: unrecognized activeState');
      end
      if(idxTrial == length(trialNames))
        if(~isempty(pJsonData(segId).segment.H.bandwidthHzC2))
          bwp=diff(pJsonData(segId).segment.H.bandwidthHzC2);
          bwt=diff(tJsonData(segId).segment.H.bandwidthHzC2);
          bwf = bwp/bwt;
  
          if(bwf > 0.75)
            aData =  tJsonData(segId).segment.H.(xySeries(idx).yL)(xySeries(idx).idxData) ...
                    - interp1(pJsonData(segId).segment.H.frequencyHz,...
                        pJsonData(segId).segment.H.(xySeries(idx).yL),...
                        tJsonData(segId).segment.H.frequencyHz(xySeries(idx).idxData));
            plot(tJsonData(segId).segment.H.frequencyHz(xySeries(idx).idxData),...
                 aData.*xySeries(idx).yLScale,...
                 '-','Color',[0,0,0]);
            hold on;
  
            summaryStatistics=getSummaryStatistics(aData);
            w = 0.05*diff(xySeries(idx).xLim);
            x = max(xySeries(idx).xLim)-w;
            plotBoxWhiskerData(x,summaryStatistics,w*0.5,[0,0,0],[1,1,1].*0.75);
            hold on;
          end
        end
      end
    end
  
    if(strcmp(xySeries(idx).x,'frequencyHz'))
      yLimits = ylim;
  
      for idxBW=1:1:2
        plot([1,1].*jsonData(segId).segment.H.bandwidthHzC2(idxBW),...
             yLimits,...
             '-','Color',[1,1,1].*0.5,...
             'HandleVisibility','off');
        hold on;
      end
  
    end
  
    if(~isempty(xySeries(idx).title))
      title(xySeries(idx).title,'HorizontalAlignment','center');
    end
  
    box off
  
  end
end

if(flag_savePlot==1)
  outputPlotDir = fullfile(projectFolders.output600A_plots,...
                           experimentName{1});
  
  figH=configPlotExporter(figH, ...
            pageWidthZ, pageHeightZ);
  fileName =  ['fig_',experimentName{1}];
  if(flag_storageLoss0_stiffnessDamping1_titles==0)
    fileName=[fileName,'_storageLoss'];    
  else
    fileName=[fileName,'_stiffnessDamping'];
  end

  switch flag_0Presentation_1Publication
    case 0
      fileName =  [fileName,'_pres'];
    case 1
      fileName =  [fileName,'_pub'];      
    otherwise
      assert(0,'Error: flag_0Presentation_1Publication should be 0 or 1');      
  end

  print('-dpdf',fullfile(outputPlotDir,[fileName,'.pdf']));  
  saveas(figH,fullfile(outputPlotDir,[fileName,'.fig']));  
end