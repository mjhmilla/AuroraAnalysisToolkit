function success=createZLComparisonPlot600A(...
                  dataSet,...
                  dataSetStats,...
                  segmentSeries,...
                  categories,...
                  projectFolders,...
                  settings)

assert(length(segmentSeries)==4,...
  'Error: this function has only been tested when all 4 segments are used');
assert(length(categories.length.value)==7,...
  'Error: this function has only been tested when all 7 lengths are used');

nS=size(dataSet.individual,1);
nL=size(dataSet.individual,2);
nE=size(dataSet.individual,3);
nC=size(settings.pairwiseComparison,1);

success=0;

figZLComp    = figure;

bwWidth = 0.025;


xDataMap = [2,4,1,3];
xOffsetMap = (xDataMap-2.5);
%1 0.02 35
%2 0.02 90
%3 0.002 35
%4 0.002 90


%
% Figure layout
%
numberOfHorizontalPlotColumnsGeneric  = 2;
numberOfVerticalPlotRowsGeneric       = 1;

switch settings.flag_0Presentation_1Publication
  case 0
    plotWidth                 = ones(1,numberOfHorizontalPlotColumnsGeneric).*5;
    plotHeight                = ones(numberOfVerticalPlotRowsGeneric,1).*5;
    plotHorizMarginCm         = 1;
    plotVertMarginCm          = 1.25;
    baseFontSize              = 6;
    
  case 1
    plotWidth                 = ones(1,numberOfHorizontalPlotColumnsGeneric).*7;
    plotHeight                = ones(numberOfVerticalPlotRowsGeneric,1).*7;
    plotHorizMarginCm         = 2;
    plotVertMarginCm          = 2;
    baseFontSize              = 8;

  otherwise
    assert(0,'Error: settings.flag_0Presentation_1Publication should be 0 or 1');
end

[subPlotPanelFLZ, pageWidthFLZ,pageHeightFLZ]= ...
  plotConfigGeneric(  numberOfHorizontalPlotColumnsGeneric,...
                      numberOfVerticalPlotRowsGeneric,...
                      plotWidth,...
                      plotHeight,...
                      plotHorizMarginCm,...
                      plotVertMarginCm,...
                      baseFontSize); 


%
% Figure configuration
%

nSeries=nS*2;

xySeries(nSeries)=struct('idS',nan,'idE',nan,'row',nan,'col',nan,...
                'x','','xOffset',nan,'xTicks',[],'xLim',[],'xLabel','','xData',[],...
                'y','','yTicks',[],'yLim',[],'yLabel','',...
                'lineColor',[],'fillColor',[],'legend','',...
                'title',[]);

for i=1:1:nSeries
  xySeries(i)=struct('idS',nan,'idE',nan,'row',nan,'col',nan,...
                    'x','','xOffset',nan,'xTicks',[],'xLim',[],'xLabel','','xData',[],...
                    'y','','yTicks',[],'yLim',[],'yLabel','',...
                    'lineColor',[],'fillColor',[],'legend','',...
                    'title',[]);
end

%
% Plot configuration
%


%
% Active Storage 
%

titleLabels = {'A.','B.'};




bwHzSet=[];
ampLoSet=[];


for idS=1:1:length(segmentSeries)
  
  ampLo=dataSet.individual(idS,1,1).amplitudeLo;
  bwHz =dataSet.individual(idS,1,1).bandwidthHz;

  bwHzSet=[bwHzSet,bwHz];
  ampLoSet=[ampLoSet,ampLo];
  

end

bwHz0=min(bwHzSet);
bwHz1=max(bwHzSet);
ampLo0=min(ampLoSet);
ampLo1=max(ampLoSet);

idx=0;

%Storage and loss configuration
for idS=1:1:length(segmentSeries)
  
  ampLo=dataSet.individual(idS,1,1).amplitudeLo;
  bwHz =dataSet.individual(idS,1,1).bandwidthHz;
  
  dlFormat='%1.3f';
  if(ampLo > 0.009)
    dlFormat='%1.2f';    
  end
  

  idxR=1;

  for idxSL=1:1:2

    idxC=idxSL;
    idx=idx+1;

    strLegend=sprintf(['%1.0f Hz-',dlFormat,' %s'],bwHz,ampLo,'$$\ell_o$$');

    switch idx
      case 1
        %
        %Active storage
        %
        xySeries(idx).idS=idS;
        xySeries(idx).idE=[];
        xySeries(idx).row=idxR;
        xySeries(idx).col=idxC;  
        xySeries(idx).xOffset= xOffsetMap(idS).*bwWidth;

        xySeries(idx).x      = 'lengthNominal';
        xySeries(idx).xData  = [];
        xySeries(idx).xTicks = categories.length.value;
        xySeries(idx).xLim   = [min(categories.length.value),...
                                   max(categories.length.value)] + [-1,1].*0.15;
        xySeries(idx).xLabel = 'Norm. Length ($$\ell/\ell_o$$)';
        
        xySeries(idx).y      = settings.pairwiseComparison{1,1};
        xySeries(idx).yTicks = [0:0.2:2];
        xySeries(idx).yLim   = [min(xySeries(idx).yTicks),...
                                    max(xySeries(idx).yTicks)] ...
                                    + [-1,1].*sqrt(eps)+[0,0.05];
    
        normUnit='S_{o}';
        if(contains(settings.pairwiseComparison{1,1},'Ai'))
          normUnit='S_{o}^i';
        end
        if(contains(settings.pairwiseComparison{1,1},'Ag'))
          normUnit='S_{o}';        
        end
    
        xySeries(idx).yLabel = ...
          ['Norm. Storage ($$(\mathrm{mN}/\mathrm{mm})/(',normUnit,')$$)'];
        xySeries(idx).lineColor  = ...
          settings.segmentColors(idS,idxSL).lineColor;
        xySeries(idx).fillColor  = ...
          settings.segmentColors(idS,idxSL).fillColor;
        xySeries(idx).legend = strLegend;
    
        xySeries(idx).title = ...
          sprintf(['%s Variation of %s with perturbation bandwidth and amplitude'],...
                   titleLabels{idxR,idxC},'$$\tilde{S}^{\mathrm{L}}$$');       
%         xySeries(idx).title = ...
%           sprintf(['%s Comparison of %s across perturbations: %1.0f-%1.0f Hz, %1.3f-%1.2f %s'],...
%                    titleLabels{idxR,idxC},'$$\tilde{S}^{\mathrm{L}}$$',...
%                    bwHz0,bwHz1,ampLo0,ampLo1,'$$\ell_o$$');       
        
      case 2
        %
        % Active Loss idS 1
        %
        xySeries(idx)=xySeries(idx-1);
        xySeries(idx).idS=idS;
        xySeries(idx).row=idxR;
        xySeries(idx).col=idxC;
        xySeries(idx).xOffset= xOffsetMap(idS).*bwWidth;

        xySeries(idx).y      = settings.pairwiseComparison{2,1};
        xySeries(idx).yTicks = [0:0.2:2];
        xySeries(idx).yLim   = [min(xySeries(idx).yTicks),...
                                    max(xySeries(idx).yTicks)] ...
                                    + [-1,1].*sqrt(eps)+[0,0.05];
        
        normUnit='L_{o}';
        if(contains(settings.pairwiseComparison{2,1},'Ai'))
          normUnit='L_{o}^i';
        end
        if(contains(settings.pairwiseComparison{2,1},'Ag'))
          normUnit='L_{o}';        
        end
    
        xySeries(idx).yLabel =...
          ['Norm. Loss ($$(\mathrm{mN}/\mathrm{mm})/',normUnit,'$$)'];
        xySeries(idx).lineColor  = ...
          settings.segmentColors(idS,idxSL).lineColor;
        xySeries(idx).fillColor  = ...
          settings.segmentColors(idS,idxSL).fillColor;
        xySeries(idx).legend = strLegend;
    
        xySeries(idx).title = ...
          sprintf(['%s Variation of %s with perturbation bandwidth and amplitude'],...
                   titleLabels{idxR,idxC},'$$\tilde{L}^{\mathrm{L}}$$');       
    
%         xySeries(idx).title = ...
%           sprintf(['%s Comparison of %s across perturbations: %1.0f-%1.0f Hz, %1.3f-%1.2f %s'],...
%                    titleLabels{idxR,idxC},'$$\tilde{L}^{\mathrm{L}}$$',...
%                    bwHz0,bwHz1,ampLo0,ampLo1,'$$\ell_o$$');        
      otherwise
        xySeries(idx)=xySeries(idx-2);
        xySeries(idx).idS=idS;        
        xySeries(idx).row=idxR;        
        xySeries(idx).col=idxC;
        xySeries(idx).xOffset= xOffsetMap(idS).*bwWidth;

        xySeries(idx).lineColor  = settings.segmentColors(idS,idxSL).lineColor;
        xySeries(idx).fillColor  = settings.segmentColors(idS,idxSL).fillColor;
        xySeries(idx).legend = strLegend;
        if(contains(xySeries(idx).y,'storage'))
%           xySeries(idx).title = ...
%             sprintf(['%s Comparison of %s across perturbations: %1.0f-%1.0f Hz, %1.3f-%1.2f %s'],...
%                      titleLabels{idxR,idxC},'$$\tilde{S}^{\mathrm{L}}$$',...
%                      bwHz0,bwHz1,ampLo0,ampLo1,'$$\ell_o$$');       
            xySeries(idx).title = ...
              sprintf(['%s Variation of %s with perturbation bandwidth and amplitude'],...
                       titleLabels{idxR,idxC},'$$\tilde{S}^{\mathrm{L}}$$');       

        else
%           xySeries(idx).title = ...
%             sprintf(['%s Comparison of %s across perturbations: %1.0f-%1.0f Hz, %1.3f-%1.2f %s'],...
%                      titleLabels{idxR,idxC},'$$\tilde{L}^{\mathrm{L}}$$',...
%                      bwHz0,bwHz1,ampLo0,ampLo1,'$$\ell_o$$');       
            xySeries(idx).title = ...
              sprintf(['%s Variation of %s with perturbation bandwidth and amplitude'],...
                       titleLabels{idxR,idxC},'$$\tilde{L}^{\mathrm{L}}$$');       

        end
    end
  end
end
  




figure(figZLComp);

dataStats(nL,nS)=struct(settings.pairwiseComparison{1,1},[],...
                        settings.pairwiseComparison{2,1},[]);

dataStatsLim(nL)=struct(settings.pairwiseComparison{1,1},[],...
                        settings.pairwiseComparison{2,1},[]);

assert(size(settings.pairwiseComparison,1)==2);

for i=1:1:length(xySeries)

  subplot('Position',...
    reshape(subPlotPanelFLZ(xySeries(i).row,...
                            xySeries(i).col,:),1,4));


  idS=xySeries(i).idS;
  idE=xySeries(i).idE;

  colName=xySeries(i).y;

  for idL=1:1:length(categories.length.value)
    if(~isempty(xySeries(i).idE))
      idT = dataSet.T.idS==idS ...
          & dataSet.T.idL==idL ...
          & dataSet.T.idE==idE ...
          & ~isnan(dataSet.T.(colName));
    else
      idT = dataSet.T.idS==idS ...
          & dataSet.T.idL==idL ...
          & ~isnan(dataSet.T.(colName));
    end

    dataL=dataSet.T.(colName)(idT);

    idC=nan;
    for k=1:1:size(settings.pairwiseComparison,1)
      if(strcmp(settings.pairwiseComparison{k,1},colName))
        idC=k;
      end
    end
    assert(~isnan(idC));

    dataStats(idL,idS).(colName)=dataL;

    ss = getSummaryStatistics(dataL);
    plotBoxWhiskerData(categories.length.value(idL)+xySeries(i).xOffset,...
                        ss,...
                        bwWidth,...
                        xySeries(i).lineColor,...
                        xySeries(i).fillColor);

    if(~isempty(dataStatsLim(idL).(colName)))
      minData=[dataStatsLim(idL).(colName)(1,1),ss.y(2)];
      maxData=[dataStatsLim(idL).(colName)(1,2),ss.y(6)];
    else
      minData=[ss.y(2)];
      maxData=[ss.y(6)];
    end
    
    dataStatsLim(idL).(colName)=[min(minData),max(maxData)];
     

    xlabel(xySeries(i).xLabel);
    xticks(xySeries(i).xTicks);
    xlim(xySeries(i).xLim);

    ylabel(xySeries(i).yLabel);
    yticks(xySeries(i).yTicks);
    ylim(xySeries(i).yLim);
    title(xySeries(i).title);
    box off;
    
  end

  dx = diff(xySeries(i).xLim).*0.05;
  dy = diff(xySeries(i).yLim).*0.05;
  xL = xySeries(i).xLim(2)-dx*6;
  yL = xySeries(i).yLim(2);%-0.5*dy;
  
  dyLegend = -dy*0.75*(xDataMap(idS)-1);  

%   plot([xL,xL+dx],...
%        [yL-1.5*dy+dyLegend,yL-1.5*dy+dyLegend],...
%        '-','Color',xySeries(i).lineColor);
%   hold on;
  legendBoxX=[xL,xL,xL,xL,xL]+[0,1,1,0,0].*(dx*0.5);
  legendBoxY=[yL,yL,yL,yL,yL]...
             +[0,0,1,1,0].*(dy*0.5)...
             +[1,1,1,1,1].*(-0.7*dy+dyLegend);

  fill(legendBoxX,legendBoxY,xySeries(i).fillColor,'EdgeColor','none');
  hold on;
  plot(legendBoxX,legendBoxY,'-','Color',xySeries(i).lineColor);
  hold on;

  text(xL+0.75*dx,yL+dyLegend,...
       xySeries(i).legend,...
       'FontSize',8,...
       'HorizontalAlignment','left',...
       'VerticalAlignment','top');
  hold on;         
  
  box off;

end

%
% Make comparisons
%
segComparison = [3,1; 4,2; 3,4; 1,2];
%1 0.02 35
%2 0.02 90
%3 0.002 35
%4 0.002 90

dataStatsRankSum(nL,length(segComparison))=...
    struct(settings.pairwiseComparison{1,1},[],...
           settings.pairwiseComparison{2,1},[]);

yOffset(nL)=struct(settings.pairwiseComparison{1,1},[],...
                   settings.pairwiseComparison{2,1},[]);

for idL=1:1:nL
  for idC=1:1:nC
    varName=settings.pairwiseComparison{idC,1};
    yOffset(idL).(varName)=0;
  end
end

for idC=1:1:nC
  varName=settings.pairwiseComparison{idC,1};

  subplot('Position',...
    reshape(subPlotPanelFLZ(1,idC,:),1,4));

  dy=diff(ylim)*0.025;

  for idSC=1:1:size(segComparison,1)

    idSA=segComparison(idSC,1);
    idSB=segComparison(idSC,2);

  
    for idL=1:1:7
      if(abs(yOffset(idL).(varName))<1e-6)
        yOffset(idL).(varName)=dy;
      end
      dataA=dataStats(idL,idSA).(varName);
      dataB=dataStats(idL,idSB).(varName);
      
      [p,h,stats]=ranksum(dataA,dataB);
      dataStatsRankSum(idL,idSC).(varName)=p;
      
      if(h==1)
        xA=categories.length.value(idL)+xOffsetMap(idSA)*bwWidth;
        xB=categories.length.value(idL)+xOffsetMap(idSB)*bwWidth;

        yA = dataStatsLim(idL).(varName)(1,2)+yOffset(idL).(varName);
        yB = yA;
        
        if(idL <= categories.length.indexLopt)
          xTxt=categories.length.value(idL)+min(xOffsetMap)*bwWidth-bwWidth;
        else
          xTxt=categories.length.value(idL)+max(xOffsetMap)*bwWidth+bwWidth;
        end
        plot([xTxt,xA],[yA,yB],'-','Color',[1,1,1].*0.75);
        hold on        
        plot([xA,xA,xB,xB],[(yA-dy*0.5),yA,yB,(yB-0.5*dy)],'-k');
        hold on;
        text(xTxt,yA+dy*0.375,'*',...
          'FontSize',8,...
          'HorizontalAlignment','right',...
          'VerticalAlignment','top');
        hold on;

        yOffset(idL).(varName)=yOffset(idL).(varName)+dy;
      end

    end
  
  end
end


outputPlotDir=fullfile(projectFolders.output600A_plots,...
                       'impedance_length_relation_larb');

figZLComp=configPlotExporter(figZLComp, ...
                          pageWidthFLZ, pageHeightFLZ);
fileName =  ['fig_flzComparison'];

switch settings.flag_0Presentation_1Publication
  case 0
    fileName =  [fileName,'_pres'];
  case 1
    fileName =  [fileName,'_pub'];      
  otherwise
    assert(0,'Error: settings.flag_0Presentation_1Publication should be 0 or 1');      
end
figure(figZLComp);
print('-dpdf',fullfile(outputPlotDir,[fileName,'.pdf']));   

success=1;

