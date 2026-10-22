function success=createZLMagnitudePlot600A(...
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

figFLZmag    = figure;


bwWidth = 0.05;
cs=getPaulTolColourSchemes('vibrant');


xDataMap = [2,4,1,3];
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

[subPlotPanelFLZmag, pageWidthFLZmag,pageHeightFLZmag]= ...
  plotConfigGeneric(  numberOfHorizontalPlotColumnsGeneric,...
                      numberOfVerticalPlotRowsGeneric,...
                      plotWidth,...
                      plotHeight,...
                      plotHorizMarginCm,...
                      plotVertMarginCm,...
                      baseFontSize); 

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


slSeriesPub(8)=struct('segment',nan,'row',nan,'col',nan,...
                  'xValue','','xTicks',[],'xTicksText',[],'xLim',[],'xLabel','','xData',[],...
                  'y','','yTicks',[],'yLim',[],'yLabel','','yData',[],...
                  'title',[],'color',[]);

for i=1:1:length(slSeriesPub)
  slSeriesPub(i)=struct('segment',nan,'row',nan,'col',nan,...
                    'xValue','','xTicks',[],'xTicksText',[],'xLim',[],'xLabel','','xData',[],...
                    'y','','yTicks',[],'yLim',[],'yLabel','','yData',[],...
                    'title',[],'color',[]);
end
idx=1;
slSeriesPub(idx).segment=1;
slSeriesPub(idx).row=1;
slSeriesPub(idx).col=1;
slSeriesPub(idx).xValue=xDataMap(slSeriesPub(idx).segment);
slSeriesPub(idx).xTicks = [1,2,3,4];
slSeriesPub(idx).xTicksText = {};
slSeriesPub(idx).xLim = [0,5];
slSeriesPub(idx).xLabel= 'Perturbation Series';
slSeriesPub(idx).xData = xDataMap(slSeriesPub(idx).segment);

slSeriesPub(idx).y = 'storageNormAtLo';
slSeriesPub(idx).yTicks = [0:10:70];
slSeriesPub(idx).yLim=...
  [min(slSeriesPub(idx).yTicks),...
   max(slSeriesPub(idx).yTicks)]+[-1,1].*0.5;
slSeriesPub(idx).yLabel='Norm. Storage ($$S^A_o/(f_o/\ell_o)$$)';
slSeriesPub(idx).yData=[];
slSeriesPub(idx).title={'A. Median Active Storage Modulus at $$\ell_o$$'};
slSeriesPub(idx).color = ...
  segmentColors(slSeriesPub(idx).segment,idCS);

idx=idx+1;
slSeriesPub(idx).segment=1;
slSeriesPub(idx).row=1;
slSeriesPub(idx).col=2;
slSeriesPub(idx).xValue=xDataMap(slSeriesPub(idx).segment);
slSeriesPub(idx).xTicks = [1,2,3,4];
slSeriesPub(idx).xTicksText = {};
slSeriesPub(idx).xLim = [0,5];
slSeriesPub(idx).xLabel= 'Perturbation Series';
slSeriesPub(idx).xData = xDataMap(slSeriesPub(idx).segment);

slSeriesPub(idx).y = 'lossNormAtLo';
slSeriesPub(idx).yTicks = [0:5:35];
slSeriesPub(idx).yLim=...
  [min(slSeriesPub(idx).yTicks),...
   max(slSeriesPub(idx).yTicks)]+[-1,1].*0.5;
slSeriesPub(idx).yLabel='Norm. Loss ($$L^A_o/(f_o/\ell_o)$$)';
slSeriesPub(idx).yData=[];
slSeriesPub(idx).title={'B. Median Active Loss Modulus at $$\ell_o$$'};
slSeriesPub(idx).color = ...
  segmentColors(slSeriesPub(idx).segment,idCL);



idx=idx+1;
slSeriesPub(idx)=slSeriesPub(1);
slSeriesPub(idx).segment =2;
slSeriesPub(idx).xValue=xDataMap(slSeriesPub(idx).segment);
slSeriesPub(idx).color = ...
  segmentColors(slSeriesPub(idx).segment,idCS);
slSeriesPub(idx).xData = xDataMap(slSeriesPub(idx).segment);


idx=idx+1;
slSeriesPub(idx)=slSeriesPub(2);
slSeriesPub(idx).segment =2;
slSeriesPub(idx).xValue=xDataMap(slSeriesPub(idx).segment);
slSeriesPub(idx).color = ...
  segmentColors(slSeriesPub(idx).segment,idCL);
slSeriesPub(idx).xData = xDataMap(slSeriesPub(idx).segment);

idx=idx+1;
slSeriesPub(idx)=slSeriesPub(1);
slSeriesPub(idx).segment =3;
slSeriesPub(idx).xValue=xDataMap(slSeriesPub(idx).segment);
slSeriesPub(idx).color = ...
  segmentColors(slSeriesPub(idx).segment,idCS);
slSeriesPub(idx).xData = xDataMap(slSeriesPub(idx).segment);

idx=idx+1;
slSeriesPub(idx)=slSeriesPub(2);
slSeriesPub(idx).segment =3;
slSeriesPub(idx).xValue=xDataMap(slSeriesPub(idx).segment);
slSeriesPub(idx).color = ...
  segmentColors(slSeriesPub(idx).segment,idCL);
slSeriesPub(idx).xData = xDataMap(slSeriesPub(idx).segment);

idx=idx+1;
slSeriesPub(idx)=slSeriesPub(1);
slSeriesPub(idx).segment =4;
slSeriesPub(idx).xValue=xDataMap(slSeriesPub(idx).segment);
slSeriesPub(idx).color = ...
  segmentColors(slSeriesPub(idx).segment,idCS);
slSeriesPub(idx).xData = xDataMap(slSeriesPub(idx).segment);

idx=idx+1;
slSeriesPub(idx)=slSeriesPub(2);
slSeriesPub(idx).segment =4;
slSeriesPub(idx).xValue=xDataMap(slSeriesPub(idx).segment);
slSeriesPub(idx).color = ...
  segmentColors(slSeriesPub(idx).segment,idCL);
slSeriesPub(idx).xData = xDataMap(slSeriesPub(idx).segment);
%
% Figure configuration
%
figure(figFLZmag);

xTickTextStorage=cell(1,4);
xTickTextLoss=cell(1,4);

for i=1:1:length(slSeriesPub)
  idS = slSeriesPub(i).segment;
  idL = categories.length.indexLopt;
  for idE=1:1:nE
    lengthAtLo  = dataSet.individual(idS,idL,idE).lengthAtLo;
    forceAtLo   = dataSet.individual(idS,idL,idE).forceAtLo;    
    storageAtLo = dataSet.individual(idS,idL,idE).storageAtLo;
    lossAtLo    = dataSet.individual(idS,idL,idE).lossAtLo;
    
    switch slSeriesPub(i).y
      case 'storageNormAtLo'

        value= storageAtLo/(forceAtLo/lengthAtLo);
        slSeriesPub(i).yData=[slSeriesPub(i).yData;value];
        slSeriesPub(i).xData=ones(size(slSeriesPub(i).yData)).*xDataMap(idS);
        slSeriesPub(i).xValue=xDataMap(idS);
      case 'lossNormAtLo'

        value= lossAtLo/(forceAtLo/lengthAtLo);
        slSeriesPub(i).yData=[slSeriesPub(i).yData;value];
        slSeriesPub(i).xData=ones(size(slSeriesPub(i).yData)).*xDataMap(idS);
        slSeriesPub(i).xValue=xDataMap(idS);
      otherwise
        assert(0,'Error: unrecognized quantity');
    end
  end

  
  ampLo=dataSet.individual(idS,1,1).amplitudeLo;
  bwHz =dataSet.individual(idS,1,1).bandwidthHz;

  ampFmt='%1.3f';
  if(ampLo > 0.009)
    ampFmt='%1.2f';    
  end
  slSeriesPub(i).xTickText = sprintf([ampFmt,'%s %1.0f Hz'],...
                               ampLo,'$$\ell_o$$', bwHz);
  if(contains(slSeriesPub(i).y,'storage'))
    idxX = xDataMap(idS);
    xTickTextStorage(idxX) = {slSeriesPub(i).xTickText};
  end
  if(contains(slSeriesPub(i).y,'loss'))
    idxX = xDataMap(idS);
    xTickTextLoss(idxX) = {slSeriesPub(i).xTickText};
  end
end



%
% Plot the data
%
for i=1:1:length(slSeriesPub)  
  idS=slSeriesPub(i).segment;

  row=slSeriesPub(i).row;
  col=slSeriesPub(i).col;
  subplot('Position',reshape(subPlotPanelFLZmag(row,col,:),1,4));
  plot(slSeriesPub(i).xData,slSeriesPub(i).yData,...
       'o','Color',segmentColors(idS,col).lineColor,...
       'MarkerFaceColor',segmentColors(idS,col).fillColor,...
       'MarkerSize',5);
  hold on;


end


subplot('Position',reshape(subPlotPanelFLZmag(1,1,:),1,4));
  box off;
  xlim(slSeriesPub(1).xLim);
  ylim(slSeriesPub(1).yLim);

  xlabel(slSeriesPub(1).xLabel);
  ylabel(slSeriesPub(1).yLabel);
  title(slSeriesPub(1).title);
  
  xticks(slSeriesPub(1).xTicks);
  xticklabels(xTickTextStorage);
  xtickangle(45);
  yticks(slSeriesPub(1).yTicks);

subplot('Position',reshape(subPlotPanelFLZmag(1,2,:),1,4));
  box off;
  xlim(slSeriesPub(2).xLim);
  ylim(slSeriesPub(2).yLim);

  xlabel(slSeriesPub(2).xLabel);
  ylabel(slSeriesPub(2).yLabel);
  title(slSeriesPub(2).title);

  xticks(slSeriesPub(2).xTicks);
  xticklabels(xTickTextLoss);
  xtickangle(45);
  yticks(slSeriesPub(2).yTicks);  


%
% Make the comparisons
%
segComparison = [1,3; 2,4; 1,2; 3,4];
% 1. 0.02 35
% 2. 0.02 90
% 3. 0.002 35
% 4. 0.002 90
ySOffset=0;
yLOffset=0;

for idxC=1:1:length(segComparison)

  idxA=segComparison(idxC,1);
  idxB=segComparison(idxC,2);

  segSeries   = [idxA,idxB];  
  dataStorage = [];
  dataLoss    = [];
  rcStorage   = [];
  rcLoss      = [];
  xStorage    = [];
  xLoss       = [];

  for idxS=1:1:length(segSeries)
    foundS=0;
    foundL=0;  
    for idxSL=1:1:length(slSeriesPub)
      if(abs(slSeriesPub(idxSL).segment-segSeries(idxS))==0)
        if(contains(slSeriesPub(idxSL).y,'storage'))
          dataStorage=[dataStorage, slSeriesPub(idxSL).yData];
          xStorage = [xStorage,slSeriesPub(idxSL).xValue];
          rcStorage=[slSeriesPub(idxSL).row,slSeriesPub(idxSL).col];
          dyS = diff(slSeriesPub(idxSL).yLim)*0.025;
          assert(foundS==0);
          foundS=1;
        end
        if(contains(slSeriesPub(idxSL).y,'loss'))
          dataLoss=[dataLoss, slSeriesPub(idxSL).yData];
          xLoss = [xLoss,slSeriesPub(idxSL).xValue];
          rcLoss=[slSeriesPub(idxSL).row,slSeriesPub(idxSL).col];
          dyL = diff(slSeriesPub(idxSL).yLim)*0.025;
          assert(foundL==0);
          foundL=1;
        end
      end      
    end
    assert(foundS==1 && foundL==1);    
  end

  yStorage = 30-ySOffset;
  yLoss    = 5-yLOffset;

  subplot('Position',...
    reshape(subPlotPanelFLZmag(rcStorage(1),rcStorage(2),:),1,4));  

  [pS,hS,statS]=ranksum(dataStorage(:,1),dataStorage(:,2));
  if(hS==1)
    xS=sort(xStorage);
    xS=[xS(1),xS(1),xS(2),xS(2)];
    yS=[1,1,1,1].*yStorage + [1,0,0,1].*dyS;
    plot(xS,yS,'-k');
    hold on;
    text(mean(xS),yStorage(1)-dyS*0.5,...
         sprintf('*\n%1.2e',pS),...
         'HorizontalAlignment','center',...
         'VerticalAlignment','middle');
    hold on;
    ySOffset=ySOffset+2*dyS;
  end  

  subplot('Position',...
    reshape(subPlotPanelFLZmag(rcLoss(1),rcLoss(2),:),1,4));
  
  [pL,hL,statL]=ranksum(dataLoss(:,1),dataLoss(:,2));
  if(hL==1)
    xL=sort(xLoss);
    xL=[xL(1),xL(1),xL(2),xL(2)];
    yL=[1,1,1,1].*yLoss + [1,0,0,1].*dyL;    
    plot(xL,yL,'-k');
    hold on;
    text(mean(xLoss),yLoss(1)-dyL*0.5,...
         sprintf('*\n%1.2e',pL),...
         'HorizontalAlignment','center',...
         'VerticalAlignment','middle');
    hold on;
    yLOffset=yLOffset+2*dyL;

  end
  
end


%
% Save the plot
%

outputPlotDir=fullfile(projectFolders.output600A_plots,...
                       'impedance_length_relation_larb');

figFLZmag=configPlotExporter(figFLZmag, ...
                          pageWidthFLZmag, pageHeightFLZmag);
fileName =  ['fig_zM'];

switch settings.flag_0Presentation_1Publication
  case 0
    fileName =  [fileName,'_pres'];
  case 1
    fileName =  [fileName,'_pub'];      
  otherwise
    assert(0,'Error: settings.flag_0Presentation_1Publication should be 0 or 1');      
end
figure(figFLZmag);
print('-dpdf',fullfile(outputPlotDir,[fileName,'.pdf']));  
%saveas(figFLZ,fullfile(outputPlotDir,[fileName,'.fig']));  

success=1;

