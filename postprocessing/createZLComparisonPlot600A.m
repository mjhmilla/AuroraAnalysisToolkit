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
cs=getPaulTolColourSchemes('vibrant');

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

nPlots=nS*2;

xySeries(nPlots)=struct('idS',nan,'idE',nan,'row',nan,'col',nan,...
                'x','','xOffset',nan,'xTicks',[],'xLim',[],'xLabel','','xData',[],...
                'y','','yTicks',[],'yLim',[],'yLabel','',...
                'lineColor',[],'fillColor',[],'legend','',...
                'title',[]);

for i=1:1:nPlots
  xySeries(i)=struct('idS',nan,'idE',nan,'row',nan,'col',nan,...
                    'x','','xOffset',nan,'xTicks',[],'xLim',[],'xLabel','','xData',[],...
                    'y','','yTicks',[],'yLim',[],'yLabel','',...
                    'lineColor',[],'fillColor',[],'legend','',...
                    'title',[]);
end

%
% Plot configuration
%
segmentColors(4,2)=struct('lineColor',[],'fillColor',[]);
idCS=1;
idCL=2;
for idS=1:1:length(segmentSeries)
  ampLo=dataSet.individual(idS,1,1).amplitudeLo;
  bwHz =dataSet.individual(idS,1,1).bandwidthHz;
   
  for idC=1:1:2
    switch idC
      case 1
        if(ampLo > 0.009)
          segmentColors(idS,idC).lineColor=cs.orange;
        else
          segmentColors(idS,idC).lineColor=cs.red;
        end
      case 2
        if(ampLo > 0.009)
          segmentColors(idS,idC).lineColor=cs.cyan;
        else
          segmentColors(idS,idC).lineColor=cs.blue;
        end        
      otherwise 
        assert(0,'Error: unrecognized idC value');
    end
    
    if(bwHz > 45)
      segmentColors(idS,idC).fillColor= ...
        segmentColors(idS,idC).lineColor.*0.25 + [1,1,1].*0.75;
    else
      segmentColors(idS,idC).fillColor= [1,1,1];
    end      

  end  
end

%
% Active Storage 
%

titleLabels = {'A.','B.'};





bwHz0=35;
bwHz1=90;
ampLo0=0.002;
ampLo1=0.02;

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
                                    + [-1,1].*sqrt(eps);
    
        normUnit='S_o';
        if(contains(settings.pairwiseComparison{1,1},'Ai'))
          normUnit='S_o^i';
        end
        if(contains(settings.pairwiseComparison{1,1},'Ag'))
          normUnit='S_o';        
        end
    
        xySeries(idx).yLabel = ['Norm. Storage ($$(\mathrm{mN}/\mathrm{mm})/(',normUnit,')$$)'];
        xySeries(idx).lineColor  = segmentColors(idS,idxSL).lineColor;
        xySeries(idx).fillColor  = segmentColors(idS,idxSL).fillColor;
        xySeries(idx).legend = strLegend;
    
        xySeries(idx).title = ...
          sprintf(['%s Comparison of %s across perturbations: %1.0f-%1.0f Hz, %1.3f-%1.2f %s'],...
                   titleLabels{idxR,idxC},'$$\tilde{S}^{\mathrm{L}}$$',...
                   bwHz0,bwHz1,ampLo0,ampLo1,'$$\ell_o$$');       
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
                                    + [-1,1].*sqrt(eps);
        
        normUnit='L_o';
        if(contains(settings.pairwiseComparison{2,1},'Ai'))
          normUnit='L_o^i';
        end
        if(contains(settings.pairwiseComparison{2,1},'Ag'))
          normUnit='L_o';        
        end
    
        xySeries(idx).yLabel =...
          ['Norm. Loss ($$(\mathrm{mN}/\mathrm{mm})/',normUnit,'$$)'];
        xySeries(idx).lineColor  = segmentColors(idS,idxSL).lineColor;
        xySeries(idx).fillColor  = segmentColors(idS,idxSL).fillColor;
        xySeries(idx).legend = strLegend;
    
    
        xySeries(idx).title = ...
          sprintf(['%s Comparison of %s across perturbations: %1.0f-%1.0f Hz, %1.3f-%1.2f %s'],...
                   titleLabels{idxR,idxC},'$$\tilde{L}^{\mathrm{L}}$$',...
                   bwHz0,bwHz1,ampLo0,ampLo1,'$$\ell_o$$');        
      otherwise
        xySeries(idx)=xySeries(idx-2);
        xySeries(idx).idS=idS;        
        xySeries(idx).row=idxR;        
        xySeries(idx).col=idxC;
        xySeries(idx).xOffset= xOffsetMap(idS).*bwWidth;

        xySeries(idx).lineColor  = segmentColors(idS,idxSL).lineColor;
        xySeries(idx).fillColor  = segmentColors(idS,idxSL).fillColor;
        xySeries(idx).legend = strLegend;
        if(contains(xySeries(idx).y,'storage'))
          xySeries(idx).title = ...
            sprintf(['%s Comparison of %s across perturbations: %1.0f-%1.0f Hz, %1.3f-%1.2f %s'],...
                     titleLabels{idxR,idxC},'$$\tilde{S}^{\mathrm{L}}$$',...
                     bwHz0,bwHz1,ampLo0,ampLo1,'$$\ell_o$$');       
        else
          xySeries(idx).title = ...
            sprintf(['%s Comparison of %s across perturbations: %1.0f-%1.0f Hz, %1.3f-%1.2f %s'],...
                     titleLabels{idxR,idxC},'$$\tilde{L}^{\mathrm{L}}$$',...
                     bwHz0,bwHz1,ampLo0,ampLo1,'$$\ell_o$$');       
        end
    end
  end
end
  




figure(figZLComp);


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
    ss = getSummaryStatistics(dataL);
    plotBoxWhiskerData(categories.length.value(idL)+xySeries(i).xOffset,...
                        ss,...
                        bwWidth,...
                        xySeries(i).lineColor,...
                        xySeries(i).fillColor);

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
  xL = xySeries(i).xLim(1)+0.5*dx;
  yL = xySeries(i).yTicks(end);
  
  dyLegend = -dy*(xDataMap(idS)-1);  

  plot([xL,xL+dx],...
       [yL-1.5*dy+dyLegend,yL-1.5*dy+dyLegend],...
       '-','Color',xySeries(i).lineColor);
  hold on;
  text(xL+1.5*dx,yL-1*dy+dyLegend,...
       xySeries(i).legend,...
       'FontSize',8,...
       'HorizontalAlignment','left',...
       'VerticalAlignment','top');
  hold on;         
  
  box off;

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

