function success=createFrequencyResponseComparisonPlot600A(...
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

figFRComp    = figure;

segmentOrderMap = [4,2,3,1];
%1 0.02 35
%2 0.02 90
%3 0.002 35
%4 0.002 90



%
% Figure layout
%
numberOfHorizontalPlotColumnsGeneric  = 2;
numberOfVerticalPlotRowsGeneric       = 2;

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

[subPlotPanel, pageWidth,pageHeight]= ...
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

xySeries(nSeries)=struct('idS',nan,'idE',nan,'idAB',nan,'row',nan,'col',nan,...
                'x','','xTicks',[],'xLim',[],'xLabel','','xData',[],...
                'left',[],'right',[],...
                'title',[]);

for i=1:1:nSeries
  xySeries(i)=struct('idS',nan,'idE',nan,'idAB',nan,'row',nan,'col',nan,...
                'x','','xTicks',[],'xLim',[],'xLabel','','xData',[],...
                'left',[],'right',[],...
                'title',[]);

  xySeries(i).left  = ...
    struct('y','','yTicks',[],'yLim',[],'yLabel','',...
           'lineColor',[],'fillColor',[],'axisColor',[],'legend','');

  xySeries(i).right = ...
    struct('y','','yTicks',[],'yLim',[],'yLabel','',...
           'lineColor',[],'fillColor',[],'axisColor',[],'legend','');    
end


%
% Plot configuration
%


%
% Active Storage 
%

titleLabels = {'A.','B.'; 'C.','D.'};




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

cs=getPaulTolColourSchemes('vibrant');



storageFillColor = [cs.red.*0.5;...
                    cs.red.*0.5+[1,1,1].*0.5];
lossFillColor    = [cs.blue.*0.5;...
                    cs.blue.*0.5+[1,1,1].*0.5];
storageLineColor = [1,1,1;...
                    0,0,0];
lossLineColor    = [1,1,1;...
                    0,0,0];

dataSetComp(numberOfVerticalPlotRowsGeneric,...
          numberOfHorizontalPlotColumnsGeneric,...
          nC) = struct('frequencyA',[],'dataA',[],'meanA',[],...
                       'frequencyB',[],'dataB',[],'meanB',[]);
for idxR=1:1:numberOfVerticalPlotRowsGeneric
  for idxC=1:1:numberOfHorizontalPlotColumnsGeneric
    for idxAB=1:1:nC
      dataSetComp(idxR,idxC,idxAB)=...
        struct('frequencyA',[],'dataA',[],'meanA',[],...
               'frequencyB',[],'dataB',[],'meanB',[]);
    end
  end
end

subPlotSet(numberOfVerticalPlotRowsGeneric,...
          numberOfHorizontalPlotColumnsGeneric)...
          =struct('frequencyHz',[],'amplitudeLo',[],...
                  'storageFillColor',[],'lossFillColor',[],...
                  'storageLineColor',[],'lossLineColor',[],...
                  'axisColor',[],...
                  'description',[]);

%1 0.02 35
%2 0.02 90
%3 0.002 35
%4 0.002 90

subPlotSet(1,1).frequencyHz=[90,35];
subPlotSet(1,1).amplitudeLo=[0.02,0.02];
subPlotSet(1,1).storageFillColor = [settings.segmentColors(2,1).fillColor;... 
                                    settings.segmentColors(1,1).fillColor];
subPlotSet(1,1).lossFillColor    = [settings.segmentColors(2,2).fillColor;... 
                                    settings.segmentColors(1,2).fillColor];
subPlotSet(1,1).storageLineColor = [settings.segmentColors(2,1).lineColor;... 
                                    settings.segmentColors(1,1).lineColor];
subPlotSet(1,1).lossLineColor    = [settings.segmentColors(2,2).lineColor;... 
                                    settings.segmentColors(1,2).lineColor];
subPlotSet(1,1).axisColor = [settings.segmentColors(2,1).fillColor;...
                             settings.segmentColors(2,2).fillColor];
subPlotSet(1,1).description=...
  sprintf('%s = %1.2f %s',...
    '$$A_{pp}$$',...
    subPlotSet(1,1).amplitudeLo(1,1),'$$\ell_o$$');


subPlotSet(1,2).frequencyHz=[90,35];
subPlotSet(1,2).amplitudeLo=[0.002,0.002];
subPlotSet(1,2).storageFillColor = [settings.segmentColors(4,1).fillColor;... 
                                    settings.segmentColors(3,1).fillColor];
subPlotSet(1,2).lossFillColor    = [settings.segmentColors(4,2).fillColor;... 
                                    settings.segmentColors(3,2).fillColor];
subPlotSet(1,2).storageLineColor = [settings.segmentColors(4,1).lineColor;... 
                                    settings.segmentColors(3,1).lineColor];
subPlotSet(1,2).lossLineColor    = [settings.segmentColors(4,2).lineColor;... 
                                    settings.segmentColors(3,2).lineColor];
subPlotSet(1,2).axisColor = [settings.segmentColors(4,1).fillColor;...
                             settings.segmentColors(4,2).fillColor];

%subPlotSet(1,2).storageFillColor = storageFillColor;
%subPlotSet(1,2).lossFillColor    = lossFillColor;
%subPlotSet(1,2).storageLineColor = storageLineColor;
%subPlotSet(1,2).lossLineColor    = lossLineColor;
subPlotSet(1,2).description=...
  sprintf('%s = %1.2f %s',...
    '$$A_{pp}$$',...
    subPlotSet(1,2).amplitudeLo(1,1),'$$\ell_o$$');

subPlotSet(2,1).frequencyHz=[35,35];
subPlotSet(2,1).amplitudeLo=[0.002,0.02];
subPlotSet(2,1).storageFillColor = [settings.segmentColors(3,1).fillColor;... 
                                    settings.segmentColors(1,1).fillColor];
subPlotSet(2,1).lossFillColor    = [settings.segmentColors(3,2).fillColor;... 
                                    settings.segmentColors(1,2).fillColor];
subPlotSet(2,1).storageLineColor = [settings.segmentColors(3,1).lineColor;... 
                                    settings.segmentColors(1,1).lineColor];
subPlotSet(2,1).lossLineColor    = [settings.segmentColors(3,2).lineColor;... 
                                    settings.segmentColors(1,2).lineColor];
subPlotSet(2,1).axisColor = [settings.segmentColors(1,1).fillColor;...
                             settings.segmentColors(1,2).fillColor];

% subPlotSet(2,1).storageFillColor = storageFillColor;
% subPlotSet(2,1).lossFillColor    = lossFillColor;
% subPlotSet(2,1).storageLineColor = storageLineColor;
% subPlotSet(2,1).lossLineColor    = lossLineColor;
subPlotSet(2,1).description=...
  sprintf('%s = %1.2f %s',...
    '$$\omega$$',...
    subPlotSet(2,1).frequencyHz(1,1),'Hz');

subPlotSet(2,2).frequencyHz=[90,90];
subPlotSet(2,2).amplitudeLo=[0.002,0.02];
subPlotSet(2,2).storageFillColor = [settings.segmentColors(4,1).fillColor;... 
                                    settings.segmentColors(2,1).fillColor];
subPlotSet(2,2).lossFillColor    = [settings.segmentColors(4,2).fillColor;... 
                                    settings.segmentColors(2,2).fillColor];
subPlotSet(2,2).storageLineColor = [settings.segmentColors(4,1).lineColor;... 
                                    settings.segmentColors(2,1).lineColor];
subPlotSet(2,2).lossLineColor    = [settings.segmentColors(4,2).lineColor;... 
                                    settings.segmentColors(2,2).lineColor];
subPlotSet(2,2).axisColor = [settings.segmentColors(2,1).fillColor;...
                             settings.segmentColors(2,2).fillColor];

% subPlotSet(2,2).storageFillColor = storageFillColor;
% subPlotSet(2,2).lossFillColor    = lossFillColor;
% subPlotSet(2,2).storageLineColor = storageLineColor;
% subPlotSet(2,2).lossLineColor    = lossLineColor;
subPlotSet(2,2).description=...
  sprintf('%s = %1.2f %s',...
    '$$\omega$$',...
    subPlotSet(2,2).frequencyHz(1,1),'Hz');

idx=0;

yOffset(numberOfVerticalPlotRowsGeneric,...
        numberOfHorizontalPlotColumnsGeneric)=struct('right',0,'left',0);
for idxR=1:1:numberOfVerticalPlotRowsGeneric
  for idxC=1:1:numberOfHorizontalPlotColumnsGeneric
    yOffset(idxR,idxC).left=0;
    yOffset(idxR,idxC).right=0;
    
  end
end
  

idLo=categories.length.indexLopt;
idE=1;

idxStorage=1;
idxLoss   =2;

for idxR=1:1:numberOfVerticalPlotRowsGeneric
  for idxC=1:1:numberOfHorizontalPlotColumnsGeneric
    for idxAB=1:1:length(subPlotSet(idxR,idxC).frequencyHz)
      

      bwHz  = subPlotSet(idxR,idxC).frequencyHz(idxAB);
      ampLo = subPlotSet(idxR,idxC).amplitudeLo(idxAB);

      %Go find the correct segment
      found=0;
      for i=1:1:nS
        bwErr = bwHz-dataSet.individual(i,idLo,idE).bandwidthHz;
        ampErr= ampLo-dataSet.individual(i,idLo,idE).amplitudeLo;
        if(abs(bwErr)<1e-6 && abs(ampErr)<1e-6)
          assert(found==0);
          found=1;
          idS=i;
        end
      end

      bwHzMin=min(subPlotSet(idxR,idxC).frequencyHz);
      bwHzMax=max(subPlotSet(idxR,idxC).frequencyHz);
      bwHzDiff=bwHzMax-bwHzMin;

      %Add the storage information
      idx=idx+1;
      xySeries(idx).idS=idS;
      xySeries(idx).idE=[];
      xySeries(idx).row=idxR;
      xySeries(idx).col=idxC;   
      xySeries(idx).idAB=idxAB;

      xySeries(idx).x      = 'frequencyA';
      xySeries(idx).xData  = [];
      if(abs(bwHzDiff)<1e-6)
        xySeries(idx).xTicks = [0,bwHzMax];
      else
        xySeries(idx).xTicks = [0,bwHzMin,bwHzMax];        
      end
      xySeries(idx).xLim   = ...
        [min(xySeries(idx).xTicks),max(xySeries(idx).xTicks)] ...
        + [-1,1].*sqrt(eps);
      xySeries(idx).xLabel = 'Frequency (Hz)';
      
      xySeries(idx).left.y      = 'storageA';
      xySeries(idx).left.yTicks = [0:10:90];
      xySeries(idx).left.yLim   = [min(xySeries(idx).left.yTicks),...
                                   max(xySeries(idx).left.yTicks)] ...
                                 + [-1,1].*sqrt(eps);
  
      dlFormat='%1.2f';
      if(ampLo < 0.009)
        dlFormat='%1.3f';
      end

      normUnit='f_o/\ell_o';
  

      xySeries(idx).left.yLabel = ...
        ['Norm. Storage ($$(\mathrm{mN}/\mathrm{mm})/(',normUnit,')$$)'];
      xySeries(idx).left.lineColor  = subPlotSet(idxR,idxC).storageLineColor(idxAB,:);
      xySeries(idx).left.fillColor  = subPlotSet(idxR,idxC).storageFillColor(idxAB,:);
      xySeries(idx).left.axisColor = subPlotSet(idxR,idxC).axisColor(1,:);
      if(idxAB==1)
        xySeries(idx).left.legend = ...
          sprintf([ '%s %1.0f Hz ',dlFormat],...
                    '$$\tilde{S}^A(\omega)$$:',...
                    bwHz,ampLo);
      else
        xySeries(idx).left.legend = ...
          sprintf([ '%s %1.0f Hz ',dlFormat],...
                    '$$\tilde{S}^B(\omega)$$:',...
                    bwHz,ampLo);
      end
      %Add the loss information
      xySeries(idx).right=xySeries(idx).left;
      xySeries(idx).right.y='lossA';
      xySeries(idx).right.yLabel = ...
        ['Norm. Loss ($$(\mathrm{mN}/\mathrm{mm})/(',normUnit,')$$)'];
      xySeries(idx).right.lineColor = subPlotSet(idxR,idxC).lossLineColor(idxAB,:);
      xySeries(idx).right.fillColor = subPlotSet(idxR,idxC).lossFillColor(idxAB,:);
      xySeries(idx).right.axisColor = subPlotSet(idxR,idxC).axisColor(2,:);
      if(idxAB==1)
        xySeries(idx).right.legend = ...
          sprintf([ '%s %1.0f Hz ',dlFormat],...
                    '$$\tilde{L}^A(\omega)$$:',...
                    bwHz,ampLo);
      else
        xySeries(idx).right.legend = ...
          sprintf([ '%s %1.0f Hz ',dlFormat],...
                    '$$\tilde{L}^B(\omega)$$:',...
                    bwHz,ampLo);        
      end

      xySeries(idx).title = ...
        sprintf(['%s %s and %s at %s: %s'],...
                 titleLabels{idxR,idxC},...
                 '$$\tilde{S}^i(\omega)$$','$$\tilde{L}^i(\omega)$$','$$\ell_o$$',...
                 subPlotSet(idxR,idxC).description);       
                



    end
  end
end




figure(figFRComp);


for i=1:1:length(xySeries)

  idxR=xySeries(i).row;
  idxC=xySeries(i).col;
  subplot('Position',...
    reshape(subPlotPanel(idxR,idxC,:),1,4));


  idS=xySeries(i).idS;
  idL=categories.length.indexLopt;

  for idxLR=1:1:2

    side='';
    switch idxLR
      case 1
        side='left';
        yyaxis left;
      case 2
        side='right';
        yyaxis right
      otherwise
        assert(0,'Error: unrecognized side index');
    end

    xName=xySeries(i).x;
    yName=xySeries(i).(side).y;
  
    bwHz  = dataSet.individual(idS,idL,1).bandwidthHz;
    ampLo = dataSet.individual(idS,idL,1).amplitudeLo;
  
    freqInterp=[0.5:0.5:bwHz]';
    resInterp=zeros(length(freqInterp),nE);
    meanInterpY=zeros(length(freqInterp),1);
    nExpCount=0;
    for idE=1:1:nE
      idTy = dataSet.T.idS==idS ...
          & dataSet.T.idL==idL ...
          & dataSet.T.idE==idE ...
          & ~isnan(dataSet.T.(yName));
    
      idTx = dataSet.T.idS==idS ...
          & dataSet.T.idL==idL ...
          & dataSet.T.idE==idE ...
          & ~isnan(dataSet.T.(xName));    
    
      dataX=dataSet.T.(xName)(idTx);
      dataY=dataSet.T.(yName)(idTy);
  
      dataYInterp=interp1(dataX,dataY,freqInterp);
      
      resInterp(:,idE)=dataYInterp;
      if(sum(~isnan(dataYInterp))>0)
        meanInterpY=meanInterpY+dataYInterp;
        nExpCount=nExpCount+1;
      end
    end

    meanInterpY=meanInterpY./nExpCount;
  
    switch xySeries(i).idAB
      case 1
        dataSetComp(idxR,idxC,idxLR).frequencyA=freqInterp;
        dataSetComp(idxR,idxC,idxLR).dataA=resInterp;
        dataSetComp(idxR,idxC,idxLR).meanA=meanInterpY;
      case 2
        dataSetComp(idxR,idxC,idxLR).frequencyB=freqInterp;
        dataSetComp(idxR,idxC,idxLR).dataB=resInterp;        
        dataSetComp(idxR,idxC,idxLR).meanB=meanInterpY;
      otherwise
        assert(0,'Error: unrecognized idAB')
    end
    
    %Extract outline
    idVMin=0;
    for j=1:1:round(length(freqInterp)*0.5)
      if(sum(isnan(resInterp(j,:)))==0)
        idVMin=j;
        break;
      end
    end
    idVMax=length(freqInterp);
    for j=length(freqInterp):-1:round(length(freqInterp)*0.5)
      if(sum(isnan(resInterp(j,:)))==0)
        idVMax=j;
        break;
      end
    end
    idV = [idVMin:1:idVMax];
  
    resBottom=zeros(length(freqInterp),1);
    resTop   =resBottom;
  
    for j=1:1:length(freqInterp)
      resBottom(j,1)=min(resInterp(j,:));
      resTop(j,1)=max(resInterp(j,:));
    end
  
    meanLineColor=[1,1,1];
    if(abs(sum(xySeries(i).(side).fillColor)-3)<1e-6)
      meanLineColor=xySeries(i).(side).lineColor;

    end
  
    fill([freqInterp(idV); fliplr(freqInterp(idV)')'],...
         [resBottom(idV); fliplr(resTop(idV)')'],...
         xySeries(i).(side).fillColor,...
         'EdgeColor','none');
    hold on;

    plot(freqInterp(idV),resTop(idV),...
          '-','Color',xySeries(i).(side).lineColor,...
          'LineWidth',0.5);
    hold on;
    plot(freqInterp(idV),resBottom(idV),...
          '-','Color',xySeries(i).(side).lineColor,...
          'LineWidth',0.5);
    hold on;    

    for idE=1:1:nE
      lineColor = xySeries(i).(side).fillColor.*0.5+[1,1,1].*0.5;

      plot(freqInterp(idV),resInterp(idV,idE),...
           '-','Color',lineColor,...
           'LineWidth',0.25);
      hold on;
    end
    plot(freqInterp(idV),meanInterpY(idV),...
         '-','Color',meanLineColor,...
         'LineWidth',1);
    hold on;

    ylabel(xySeries(i).(side).yLabel);
    yticks(xySeries(i).(side).yTicks);
    ylim(xySeries(i).(side).yLim);    

    switch idxLR
      case 1
        ax=gca;
        ax.YAxis(idxLR).Color=xySeries(i).left.axisColor;
      case 2
        ax=gca;
        ax.YAxis(idxLR).Color=xySeries(i).right.axisColor;        
      otherwise
        assert(0,'Error: unrecognized side index');
    end
  end


  xlabel(xySeries(i).xLabel);
  xticks(xySeries(i).xTicks);
  xlim(xySeries(i).xLim);

  for idxLR=1:1:2
    switch idxLR
      case 1
        yyaxis left;
        side='left';
        dx=diff(xySeries(i).xLim)*0.05;
        dy=diff(xySeries(i).(side).yLim)*0.05;
        xL=xySeries(i).xLim(1);
        yL=xySeries(i).(side).yLim(2)+yOffset(idxR,idxC).(side);
        
        
      case 2
        yyaxis right;
        side='right';
        dx=diff(xySeries(i).xLim)*0.05;
        dy=diff(xySeries(i).(side).yLim)*0.05;
        xL=xySeries(i).xLim(2)-dx*11;
        yL=xySeries(i).(side).yLim(2)+yOffset(idxR,idxC).(side);
        
      otherwise
        assert(0,'Error: unrecognized side index');
    end

    legendBoxX=[xL,xL,xL,xL,xL]+[0,1,1,0,0].*(dx*0.5);
    legendBoxY=[yL,yL,yL,yL,yL]...
               +[0,0,1,1,0].*(dy*0.5)...
               +[1,1,1,1,1].*(-0.7*dy);
  
    fill(legendBoxX,legendBoxY,...
      xySeries(i).(side).fillColor,...
      'EdgeColor','none');
    hold on;
    

    plot([xL,(xL+0.5*dx)],[(yL-0.7*dy),(yL-0.7*dy+dy*0.5)],'-',...
      'Color',xySeries(i).(side).lineColor,...
      'LineWidth',1);
    hold on;
  
    text(xL+0.75*dx,yL,...
         xySeries(i).(side).legend,...
         'FontSize',8,...
         'HorizontalAlignment','left',...
         'VerticalAlignment','top');
    hold on;  

    yOffset(idxR,idxC).(side)= ...
      yOffset(idxR,idxC).(side)-dy;
  end



  title(xySeries(i).title);


  box off;

end

%
% Add the statistical notes
%
for idxR=1:1:numberOfVerticalPlotRowsGeneric
  for idxC=1:1:numberOfHorizontalPlotColumnsGeneric

    subplot('Position',...
        reshape(subPlotPanel(idxR,idxC,:),1,4));    

    for idxLR=1:1:nC
      switch idxLR
        case 1
          yyaxis left;
        case 2
          yyaxis right;
        otherwise
          assert(0,'Error: unexpected idxLR');
      end

      %
      % Evaluate the correlation of the means
      %
      idxA = length(dataSetComp(idxR,idxC,idxLR).frequencyA);
      idxB = length(dataSetComp(idxR,idxC,idxLR).frequencyB);
      idxAB=[1:1:min(idxA,idxB)]';

      idxT=   ~isnan(dataSetComp(idxR,idxC,idxLR).meanA(idxAB)) ...
            & ~isnan(dataSetComp(idxR,idxC,idxLR).meanB(idxAB));

      meanA =dataSetComp(idxR,idxC,idxLR).meanA(idxT); 
      meanB =dataSetComp(idxR,idxC,idxLR).meanB(idxT); 
      [rho,pval]=corr(meanA,meanB);

      idxT0=find(idxT > 0.5,1,'first');
      xTxt=dataSetComp(idxR,idxC,idxLR).frequencyA(idxT0);

      id0=idxT0;
      id1=id0+min([20,round(length(idxAB)*0.5)]);

      yA= max(max(dataSetComp(idxR,idxC,idxLR).dataA(id0:id1,:)));
      yB= max(max(dataSetComp(idxR,idxC,idxLR).dataB(id0:id1,:)));
      yTxt=max(yA,yB);

      text(xTxt,yTxt,sprintf('%s=%1.2f','$$\rho$$',rho),...
           'HorizontalAlignment','left',...
           'VerticalAlignment','bottom',...
           'FontSize',8);
      hold on;

      %
      % Evaluate the distance between the two data sets
      %
      freqA=dataSetComp(idxR,idxC,idxLR).frequencyA(idxT,:);
      freqB=dataSetComp(idxR,idxC,idxLR).frequencyB(idxT,:);
      assert(sum(abs(freqA-freqB)) < 1e-6);
      
      dataA=dataSetComp(idxR,idxC,idxLR).dataA(idxT,:);
      dataB=dataSetComp(idxR,idxC,idxLR).dataB(idxT,:);

      rankSumAB=zeros(length(dataA),1);
      normDistAB=zeros(length(dataA),1);

      wA1 = max(dataA,[],2)-meanA;
      wA0 = min(dataA,[],2)-meanA;
      wA  = abs(wA1).*0.5 + abs(wA0).*0.5;
      wAM = median(wA);

      wB1 = max(dataB,[],2)-meanB;
      wB0 = min(dataB,[],2)-meanB;
      wB  = abs(wB1).*0.5 + abs(wB0).*0.5;
      wBM = median(wB);
      wAB = max(wAM,wBM);

      freqADiff=freqA.*nan;
      freqBDiff=freqB.*nan;
      meanADiff=meanA.*nan;
      meanBDiff=meanB.*nan;
      isABDifferent=0;
      for k=1:1:length(dataA)
        [rho,h] =ranksum(dataA(k,:),dataB(k,:));

        if(h==1)
          freqADiff(k)=freqA(k);
          freqBDiff(k)=freqB(k);
          meanADiff(k)=meanA(k);
          meanBDiff(k)=meanB(k);
          isABDifferent=1;
        end

        normDistAB(k) = (meanA(k)-meanB(k))./wAB;
        here=1;
      end

      if(isABDifferent==1)
        lineColor=[];
        fillColor=[1,1,1];
        switch idxLR
          case 1
            lineColor = [0,0,0];
          case 2
            lineColor = [0,0,0];          
          otherwise
            assert(0,'Error: unrecogized idxLR index');
        end
  
        plot(freqBDiff,meanBDiff,'-','Color',[1,1,1],...
          'LineWidth',2);
        hold on;      
        plot(freqBDiff,meanBDiff,'-','Color',lineColor,...
          'LineWidth',1);
        hold on;
  
        %Legend entries
        freqMaxA=max(dataSetComp(idxR,idxC,idxLR).frequencyA);
        freqMaxB=max(dataSetComp(idxR,idxC,idxLR).frequencyB);
        freqMax=max([freqMaxA,freqMaxB]);

        switch idxLR
          case 1
            dx=freqMax*0.05;
            dy=diff(xySeries(1).(side).yLim)*0.05;
            xL=0;
            yL=xySeries(1).(side).yLim(2)+yOffset(idxR,idxC).(side);
            legendEntry = '$$\rho < 0.05$$: $$\tilde{S}^A\,\&\,\tilde{S}^B$$';
          case 2
            dx=freqMax*0.05;
            dy=diff(xySeries(1).(side).yLim)*0.05;
            xL=freqMax-dx*11;
            yL=xySeries(1).(side).yLim(2)+yOffset(idxR,idxC).(side);
            legendEntry = '$$\rho < 0.05$$: $$\tilde{L}^A\,\&\,\tilde{L}^B$$';          
          otherwise
            assert(0,'Error: unrecognized side index');
        end      
  
        plot([xL,(xL+0.5*dx)],[(yL-0.7*dy),(yL-0.7*dy)],'-',...
          'Color',lineColor,...
          'LineWidth',1);
        hold on;
      
        text(xL+0.75*dx,yL,...
             legendEntry,...
             'FontSize',8,...
             'HorizontalAlignment','left',...
             'VerticalAlignment','top');
        hold on;        

      end

    end
  end
end


%
% Save to file
%

outputPlotDir=fullfile(projectFolders.output600A_plots,...
                       'impedance_length_relation_larb');

figFRComp=configPlotExporter(figFRComp, ...
                          pageWidth, pageHeight);
fileName =  ['fig_frequencyResponseComparison'];

switch settings.flag_0Presentation_1Publication
  case 0
    fileName =  [fileName,'_pres'];
  case 1
    fileName =  [fileName,'_pub'];      
  otherwise
    assert(0,'Error: settings.flag_0Presentation_1Publication should be 0 or 1');      
end
figure(figFRComp);
print('-dpdf',fullfile(outputPlotDir,[fileName,'.pdf']));   

success=1;

