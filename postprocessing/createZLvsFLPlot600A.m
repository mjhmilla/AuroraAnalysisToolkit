function success=createZLvsFLPlot600A(...
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

figFLZ    = figure;
figFLZmag = figure;

bwWidth = 0.05;
cs=getPaulTolColourSchemes('vibrant');




%
% Figure layout
%
numberOfHorizontalPlotColumnsGeneric  = 4;
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

%nPlotColumns=length(segmentSeries)*2;
nPlots=numberOfVerticalPlotRowsGeneric*numberOfHorizontalPlotColumnsGeneric;


xyGroup(nPlots)=struct('idS',nan,'idE',nan,'row',nan,'col',nan,...
                'x','','xTicks',[],'xLim',[],'xLabel','','xData',[],...
                'left',[],'right',[],...
                'title',[]);

for i=1:1:nPlots
  xyGroup(i)=struct('idS',nan,'idE',nan,'row',nan,'col',nan,...
                'x','','xTicks',[],'xLim',[],'xLabel','','xData',[],...
                'left',[],'right',[],...
                'title',[]);

  xyGroup(i).left  = ...
    struct('y','','yTicks',[],'yLim',[],'yLabel','',...
           'lineColor',[],'fillColor',[],'legend','');

  xyGroup(i).right = ...
    struct('y','','yTicks',[],'yLim',[],'yLabel','',...
           'lineColor',[],'fillColor',[],'legend','');    
end


%
% Active Storage idS 1
%
idSSet       = [1,1,2,2;...
                3,3,4,4];
isStorageSet = [1,0,1,0;...
                1,0,1,0];
isLossSet    =  1-isStorageSet;

titleLabels = {'A.','B.','A.','B.';...
               'A.','B.','A.','B.'};

idx=0;

for idxR=1:1:numberOfVerticalPlotRowsGeneric
  for idxC=1:1:numberOfHorizontalPlotColumnsGeneric
    idx=idx+1;

    isStorage=isStorageSet(idxR,idxC);
    isLoss=isLossSet(idxR,idxC);
  
    idS=idSSet(idxR,idxC);

    ampLo=dataSet.individual(idS,1,1).amplitudeLo;
    bwHz =dataSet.individual(idS,1,1).bandwidthHz;
  
    dlFormat='%1.3f';
    if(ampLo > 0.009)
      dlFormat='%1.2f';    
    end
  
    leftColor=[];
    nSeg=0;
    if(length(segmentSeries)>1)
      nSeg=(idS-1)/(length(segmentSeries)-1);
    end
  
    if(isStorage==1)
      if(ampLo > 0.009)
        leftColor = cs.orange;
      else
        leftColor = cs.red;
      end
    end
    if(isLoss==1)
      if(ampLo > 0.009)
        leftColor = cs.cyan;
      else
        leftColor = cs.blue;
      end  
    end
  
    if(bwHz > 45)
      leftLineColor=leftColor;
      leftFillColor=leftColor.*0.25 + [1,1,1].*0.75;
    else
      leftLineColor=leftColor;
      leftFillColor=[1,1,1];
    end
  
    switch idx
      case 1
        %
        %Active storage
        %
        xyGroup(idx).idS=idS;
        xyGroup(idx).idE=[];
        xyGroup(idx).row=idxR;
        xyGroup(idx).col=idxC;  
        
        xyGroup(idx).x      = 'lengthNominal';
        xyGroup(idx).xData  = 'length';
        xyGroup(idx).xTicks = categories.length.value;
        xyGroup(idx).xLim   = [min(categories.length.value),...
                                   max(categories.length.value)] + [-1,1].*0.15;
        xyGroup(idx).xLabel = 'Norm. Length ($$\ell/\ell_o$$)';
        
        xyGroup(idx).left.y      = settings.pairwiseComparison{1,1};
        xyGroup(idx).left.yTicks = [0:0.2:2];
        xyGroup(idx).left.yLim   = [min(xyGroup(idx).left.yTicks),...
                                    max(xyGroup(idx).left.yTicks)] ...
                                    + [-1,1].*sqrt(eps);
  
        normUnit='S_o';
        if(contains(settings.pairwiseComparison{1,1},'Ai'))
          normUnit='S_o^i';
        end
        if(contains(settings.pairwiseComparison{1,1},'Ag'))
          normUnit='S_o';        
        end
  
        xyGroup(idx).left.yLabel = ['Norm. Storage ($$(\mathrm{mN}/\mathrm{mm})/(',normUnit,')$$)'];
        xyGroup(idx).left.lineColor  = leftLineColor;
        xyGroup(idx).left.fillColor  = leftFillColor;
        xyGroup(idx).left.legend = '$$\tilde{S}$$';
  
        normUnit='f_o';
        if(contains(settings.pairwiseComparison{1,2},'Ai'))
          normUnit='f_o^i';
        end
        if(contains(settings.pairwiseComparison{1,2},'Ag'))
          normUnit='f_o';        
        end
  
  
        xyGroup(idx).right.y      = settings.pairwiseComparison{1,2};
        xyGroup(idx).right.yTicks = xyGroup(idx).left.yTicks;
        xyGroup(idx).right.yLim   = xyGroup(idx).left.yLim;
        xyGroup(idx).right.yLabel = ...
          ['Norm. Force ($$\mathrm{mN}/',normUnit,'$$)'];
        xyGroup(idx).right.lineColor  = [0,0,0];  
        xyGroup(idx).right.fillColor  = [1,1,1].*0.75;        
        xyGroup(idx).right.legend = '$$\tilde{f}^L$$';
  
  
        xyGroup(idx).title = sprintf(['%s %1.0f Hz - ',dlFormat,' %s'],...
                        titleLabels{idxR,idxC}, bwHz,ampLo,'$$\ell_o$$');
      case 2
        %
        % Active Loss idS 1
        %
        xyGroup(idx)=xyGroup(idx-1);
        xyGroup(idx).idS=idS;
        xyGroup(idx).col=idxR;
        xyGroup(idx).col=idxC;
        
        xyGroup(idx).left.y      = settings.pairwiseComparison{2,1};
        xyGroup(idx).left.yTicks = [0:0.2:2];
        xyGroup(idx).left.yLim   = [min(xyGroup(idx).left.yTicks),...
                                    max(xyGroup(idx).left.yTicks)] ...
                                    + [-1,1].*sqrt(eps);
        xyGroup(idx).right.yTicks = xyGroup(idx).left.yTicks;
        xyGroup(idx).right.yLim   = xyGroup(idx).left.yLim  ;
        
        normUnit='L_o';
        if(contains(settings.pairwiseComparison{2,1},'Ai'))
          normUnit='L_o^i';
        end
        if(contains(settings.pairwiseComparison{2,1},'Ag'))
          normUnit='L_o';        
        end
  
        xyGroup(idx).left.yLabel =...
          ['Norm. Loss ($$(\mathrm{mN}/\mathrm{mm})/',normUnit,'$$)'];
        xyGroup(idx).left.lineColor  = leftLineColor;
        xyGroup(idx).left.fillColor  = leftFillColor;
        xyGroup(idx).left.legend = '$$\tilde{L}$$';
  
        xyGroup(idx).right.y      = settings.pairwiseComparison{2,2};
  
        xyGroup(idx).title = sprintf(['%s %1.0f Hz - ',dlFormat,' %s'],...
                    titleLabels{idxR,idxC}, bwHz,ampLo,'$$\ell_o$$');      
      otherwise
        xyGroup(idx)=xyGroup(idx-2);
        xyGroup(idx).idS=idS;        
        xyGroup(idx).row=idxR;        
        xyGroup(idx).col=idxC;
        xyGroup(idx).left.lineColor  = leftLineColor;
        xyGroup(idx).left.fillColor  = leftFillColor;
        xyGroup(idx).title = sprintf(['%s %1.0f Hz - ',dlFormat,' %s'],...
                   titleLabels{idxR,idxC}, bwHz,ampLo,'$$\ell_o$$');       
    end
  
  
  end
end

% xyIndividual=xyGroup;
% for idx=1:1:(nPlotColumns)
% 
%   isStorage=0;
%   isLoss=0;
%   if(mod(idx,2)==1)
%     isStorage=1;
%   else
%     isLoss=1;
%   end
% 
%   if(isStorage==1)
%     xyIndividual(idx).row=1;
%     xyIndividual(idx).idE=settings.individualTrialNumber;
%     xyIndividual(idx).title= ['A. ',xyIndividual(idx).title,...
%       '(fiber ',num2str(settings.individualTrialNumber),')'];
%     xyGroup(idx).title= ['C. ', xyGroup(idx).title,' (all)'];
%   end
%   if(isLoss==1)
%     xyIndividual(idx).row=1;
%     xyIndividual(idx).idE=settings.individualTrialNumber;
%     xyIndividual(idx).title= ['B. ',xyIndividual(idx).title,...
%       '(fiber ',num2str(settings.individualTrialNumber),')'];
%     xyGroup(idx).title= ['D. ', xyGroup(idx).title,' (all)'];
%   end
%   
% end


xySeries=xyGroup;%[xyIndividual,xyGroup];

figure(figFLZ);


for i=1:1:length(xySeries)

  subplot('Position',...
    reshape(subPlotPanelFLZ(xySeries(i).row,...
                           xySeries(i).col,:),1,4));

  for idxLR=1:1:2
    side='';    
    
    switch idxLR
      case 1
        yyaxis left;
        side ='left';     
        bwOffset=-0.6*bwWidth;
        dyLegend=0;
      case 2
        yyaxis right;        
        side ='right';          
        bwOffset=+0.6*bwWidth;        
        dyLegend=-1;
        
      otherwise
        assert(0,'Error: idxLR must be [1,2]');
    end

    idS=xySeries(i).idS;
    idE=xySeries(i).idE;

    colName=xySeries(i).(side).y;

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



      switch idxLR
        case 1
          dataL=dataSet.T.(colName)(idT);
          ss = getSummaryStatistics(dataL);
          plotBoxWhiskerData(categories.length.value(idL)+bwOffset,...
                              ss,...
                              bwWidth,...
                              xySeries(i).(side).lineColor,...
                              xySeries(i).(side).fillColor);

          ax=gca;
          ax.YAxis(idxLR).Color=xySeries(i).(side).lineColor;          
          xlabel(xySeries(i).xLabel);
          xticks(xySeries(i).xTicks);
          xlim(xySeries(i).xLim);

          ylabel(xySeries(i).(side).yLabel,...
            'Color',xySeries(i).(side).lineColor);
          yticks(xySeries(i).(side).yTicks);
          ylim(xySeries(i).(side).yLim);
          title(xySeries(i).title);
          box off;
          
          %Add the annotation for the number
          n=length(dataL);
          yL=ss.y(1);


        case 2
          dataR=dataSet.T.(colName)(idT);

          fVal=median(dataR);

%           fVal=[];
%           if(~isempty(xySeries(i).idE))
%             fVal=mean(dataR);
%           else
%             fset=[];
%             for k=1:1:nE
%               idF = dataSet.T.idS==idS ...
%                   & dataSet.T.idL==idL ...
%                   & dataSet.T.idE==k ...
%                   & ~isnan(dataSet.T.(colName));
% 
%               meanF = mean(dataSet.T.(colName)(idF));
%               fset=[fset,meanF];
%             end
%             fVal=mean(fset);
%           end

          lineX = [1,1].*categories.length.value(idL) ...
                + [0,1].*bwWidth;           
          
          boxX = [1,1,1,1,1].*categories.length.value(idL) ...
                + [0,1,1,0,0].*bwWidth;           

          fill(boxX,[0,0,1,1,0].*fVal,...
               xySeries(i).(side).lineColor,...
               'EdgeColor','none',...
               'FaceAlpha',0.5);
          hold on;

          plot(lineX,[1,1].*fVal,...
               '-','Color',[1,1,1],'LineWidth',3);
          hold on;

          plot(lineX,[1,1].*fVal,...
               '-','Color',xySeries(i).(side).lineColor);
          hold on;

          plot(ones(size(dataR)).*(categories.length.value(idL)+bwOffset),...
               dataR,'.','Color',xySeries(i).(side).lineColor,...
               'MarkerSize',0.5);
          hold on;

          xN=categories.length.value(idL)+bwWidth;
          yN=0;
          text(xN,yN,sprintf('%i',length(dataR)),...
            'FontSize',6,...
            'HorizontalAlignment','left',...
            'VerticalAlignment','bottom');
          hold on;


          ax=gca;
          ax.YAxis(idxLR).Color=xySeries(i).(side).lineColor;            
          ylabel(xySeries(i).(side).yLabel,...
            'Color',xySeries(i).(side).lineColor);
          yticks(xySeries(i).(side).yTicks);
          ylim(xySeries(i).(side).yLim);
          box off;
                  
        otherwise
          assert(0,'Error: idxLR must be [1,2]');
      end      
      

    end

    dx = diff(xySeries(i).xLim).*0.05;
    dy = diff(xySeries(i).(side).yLim).*0.05;
    xL = xySeries(i).xLim(1)+0.5*dx;
    yL = xySeries(i).(side).yTicks(end);
    
    dyLegend = dyLegend*dy;  

    plot([xL,xL+dx],...
         [yL-1.5*dy+dyLegend,yL-1.5*dy+dyLegend],...
         '-','Color',xySeries(i).(side).lineColor);
    hold on;
    text(xL+1.5*dx,yL-1*dy+dyLegend,...
         xySeries(i).(side).legend,...
         'FontSize',8,...
         'HorizontalAlignment','left',...
         'VerticalAlignment','top');
    hold on;         
    
    box off;

    if(idxLR==1)
      dx = diff(xySeries(i).xLim).*0.05;
      dy = diff(xySeries(i).(side).yLim).*0.05;
      xR = xySeries(i).xLim(2)+0.5*dx;
      yR = xySeries(i).(side).yTicks(end);

      if(~isempty(idE))

        idE=xySeries(i).idE;
        idC=nan;
        for k=1:1:nC
          if(contains(dataSetStats.corrSE(idS,idE).vars{k},xySeries(i).(side).y) )
            idC=k;
          end
        end
        assert(~isnan(idC));

        text(xR-5*dx,yR-1*dy,...
          sprintf(...
            '%s=%1.2f\n%s=%i\n\n%s=%1.2f\n%s=%i',...
            '$$\rho_{50}$$',dataSetStats.corrSE(idS,idE).corrMedian_rho(idC),...
            '$$n_{50}$$',dataSetStats.corrSE(idS,idE).corrMedian_n(idC),...
            '$$\rho$$',dataSetStats.corrSE(idS,idE).corr_rho(idC),...
            '$$n$$',dataSetStats.corrSE(idS,idE).corr_n(idC)),...
            'FontSize',8,...
            'HorizontalAlignment','left',...
            'VerticalAlignment','top');
        hold on;
          
      else

        idC=nan;
        for k=1:1:nC
          if(contains(dataSetStats.corrS(idS).vars{k},xySeries(i).(side).y) )
            idC=k;
          end
        end
        assert(~isnan(idC));

        text(xR-5*dx,yL-1*dy,...
          sprintf(...
            '%s=%1.2f\n%s=%i\n\n%s=%1.2f\n%s=%i',...
            '$$\rho_{50}$$',dataSetStats.corrS(idS).corrMedian_rho(idC),...
            '$$n_{50}$$',dataSetStats.corrS(idS).corrMedian_n(idC),...
            '$$\rho$$',dataSetStats.corrS(idS).corr_rho(idC),...
            '$$n$$',dataSetStats.corrS(idS).corr_n(idC)),...
            'FontSize',8,...
            'HorizontalAlignment','left',...
            'VerticalAlignment','top');
        hold on;

      end
    end
  

    


  end
end

outputPlotDir=fullfile(projectFolders.output600A_plots,...
                       'impedance_length_relation_larb');

figFLZ=configPlotExporter(figFLZ, ...
                          pageWidthFLZ, pageHeightFLZ);
fileName =  ['fig_flz'];

switch settings.flag_0Presentation_1Publication
  case 0
    fileName =  [fileName,'_pres'];
  case 1
    fileName =  [fileName,'_pub'];      
  otherwise
    assert(0,'Error: settings.flag_0Presentation_1Publication should be 0 or 1');      
end
figure(figFLZ);
print('-dpdf',fullfile(outputPlotDir,[fileName,'.pdf']));  
%saveas(figFLZ,fullfile(outputPlotDir,[fileName,'.fig']));  

success=1;

