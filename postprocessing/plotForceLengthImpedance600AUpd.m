function [figHindiv,figHPub,figHSoLoPub,figFRPub] = ...
            plotForceLengthImpedance600AUpd(...
                              figHindiv,...
                              figHPub,...
                              figHSoLoPub,...
                              figFRPub,...
                              experimentList, ...
                              segmentSeries,...
                              categories, ...
                              modeNormalization,...
                              projectFolders,... 
                              appendToFileName,...
                              settings)


numberOfHorizontalPlotColumnsGeneric  = 3+length(categories.length.value);
numberOfVerticalPlotRowsGeneric       = length(segmentSeries);
frSeriesColumnStart=4;

nominalForceWindowInMs = 100;

forceUnit='mN';
lengthUnit='mm';
timeUnit='ms';

cs=getPaulTolColourSchemes('vibrant');

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

[subPlotPanelZi, pageWidthZi,pageHeightZi]= ...
  plotConfigGeneric(  numberOfHorizontalPlotColumnsGeneric,...
                      numberOfVerticalPlotRowsGeneric,...
                      plotWidth,...
                      plotHeight,...
                      plotHorizMarginCm,...
                      plotVertMarginCm,...
                      baseFontSize); 


numberOfHorizontalPlotColumnsGeneric  = 6;
numberOfVerticalPlotRowsGeneric       = 4;
nominalForceWindowInMs = 100;

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

[subPlotPanelZp, pageWidthZp,pageHeightZp]= ...
  plotConfigGeneric(  numberOfHorizontalPlotColumnsGeneric,...
                      numberOfVerticalPlotRowsGeneric,...
                      plotWidth,...
                      plotHeight,...
                      plotHorizMarginCm,...
                      plotVertMarginCm,...
                      baseFontSize); 

numberOfHorizontalPlotColumnsGeneric  = 2;
numberOfVerticalPlotRowsGeneric       = 1;
nominalForceWindowInMs = 100;

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

[subPlotPanelSoLo, pageWidthSoLo,pageHeightSoLo]= ...
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

  %
  % Individual trial
  %
  xySeries(8)=struct('x','','y','',...
                    'segment',nan,...
                    'row',nan,'col',nan,...
                    'xTicks',[],'yTicks',[],...
                    'xLim',[],'yLim',[],...
                    'xLabel','','yLabel','',...
                    'title',[],'color',[]);
  
  idx=1;
  xySeries(idx).x='lengthNominal';
  xySeries(idx).y='storage';
  %xySeries(idx).row=indexSegment;
  xySeries(idx).row=nan;
  xySeries(idx).col=1;
  xySeries(idx).xTicks = categories.length.value;
  xySeries(idx).xLim   = [min(categories.length.value),...
                          max(categories.length.value)] + [-1,1].*0.05;
  xySeries(idx).yTicks = [0:0.2:1.6];  
  xySeries(idx).yLim   = [0,1.6] + [-1,1].*sqrt(eps);
  xySeries(idx).xLabel = 'Norm. Length ($$\ell/\ell_o$$)';
  xySeries(idx).yLabel = 'Norm. Storage ($$(\mathrm{mN}/\mathrm{mm})/(S_o^M)$$)';
  xySeries(idx).title  = '';
  xySeries(idx).color = [0,0,0];
  
  idx=idx+1;
  xySeries(idx).x='lengthNominal';
  xySeries(idx).y='loss';
  xySeries(idx).row=nan;
  xySeries(idx).col=2;
  xySeries(idx).xTicks = categories.length.value;
  xySeries(idx).xLim   = [min(categories.length.value),...
                          max(categories.length.value)] + [-1,1].*0.05;
  if(modeNormalization==0)
    xySeries(idx).yTicks = [0:0.2:0.8];
    xySeries(idx).yLim   = [0,0.8] + [-1,1].*sqrt(eps);
  else
    xySeries(idx).yTicks = [0:0.2:1.6];
    xySeries(idx).yLim   = [0,1.6] + [-1,1].*sqrt(eps);
  end
  xySeries(idx).xLabel = 'Norm. Length ($$\ell/\ell_o$$)';
  if(modeNormalization==0)
    xySeries(idx).yLabel = 'Norm. Loss ($$(\mathrm{mN}/\mathrm{mm})/(S_o^M)$$)';    
  else
    xySeries(idx).yLabel = 'Norm. Loss ($$(\mathrm{mN}/\mathrm{mm})/(L_o^M)$$)';
  end
  xySeries(idx).title  = '';  
  xySeries(idx).color = [0,0,0];

  idx=idx+1;
  xySeries(idx)=xySeries(1);
  xySeries(idx).x='lengthNominal';
  xySeries(idx).y='storageActive';
  xySeries(idx).color = [1,0,0];

  idx=idx+1;
  xySeries(idx)=xySeries(2);
  xySeries(idx).x='lengthNominal';
  xySeries(idx).y='lossActive';
  xySeries(idx).color = [1,0,0];
  
  
  idx=idx+1;
  xySeries(idx)=xySeries(1);
  xySeries(idx).x='lengthNominal';
  xySeries(idx).y='storagePassive';
  xySeries(idx).color = [0,0,1];

  idx=idx+1;
  xySeries(idx)=xySeries(2);
  xySeries(idx).x='lengthNominal';
  xySeries(idx).y='lossPassive';
  xySeries(idx).color = [0,0,1];

  idx=idx+1;
  xySeries(idx).x='length';
  xySeries(idx).y='force';
  xySeries(idx).color = [1,0,0];
  xySeries(idx).row=nan;
  xySeries(idx).col=3;
  xySeries(idx).xTicks = categories.length.value;
  xySeries(idx).xLim   = [min(categories.length.value),...
                          max(categories.length.value)] + [-1,1].*0.05;
  xySeries(idx).yTicks = [0:0.2:1.6];  
  xySeries(idx).yLim   = [0,1.6] + [-1,1].*sqrt(eps);
  xySeries(idx).xLabel = 'Norm. Length ($$\ell/\ell_o$$)';
  xySeries(idx).yLabel = 'Norm. Force ($$\mathrm{mN}/f_o^M$$)';
  xySeries(idx).title  = '';
  xySeries(idx).color = [0,0,0];

   
  idx=idx+1;
  xySeries(idx)=xySeries(idx-1);
  xySeries(idx).x='lengthPassive';
  xySeries(idx).y='forcePassive';
  xySeries(idx).color = [0,0,1];



  
  if(modeNormalization==1)
    for i=1:1:length(xySeries)
      xySeries(idx).yLabel = 'Norm. Loss ($$(\mathrm{mN}/\mathrm{mm})/(L_o^M)$$)';
    end
  end

  %
  % Publication: grouped plots
  %
  xySeriesPub(6)=struct('segment',nan,'row',nan,'col',nan,...
                  'x','','xTicks',[],'xLim',[],'xLabel','','xData',[],...
                  'left',[],'right',[],...
                  'title',[],'color',[]);

  for i=1:1:6

    xySeriesPub(i)=struct('segment',nan,'row',nan,'col',nan,...
                  'x','','xTicks',[],'xLim',[],'xLabel','','xData',[],...
                  'left',[],'right',[],...
                  'title',[],'color',[]);

    xySeriesPub(i).left  = ...
      struct('y','','yTicks',[],'yLim',[],'yLabel','',...
             'color',[],'legend','');

    xySeriesPub(i).right = ...
      struct('y','','yTicks',[],'yLim',[],'yLabel','',...
             'color',[],'legend','');    
  end

  idx=1;
  %
  % Total active storage
  %
  xySeriesPub(idx).segment=nan;
  xySeriesPub(idx).row=nan;
  xySeriesPub(idx).col=nan;  

  xySeriesPub(idx).x      = 'lengthNominal';
  xySeriesPub(idx).xData  = 'length';
  xySeriesPub(idx).xTicks = categories.length.value;
  xySeriesPub(idx).xLim   = [min(categories.length.value),...
                             max(categories.length.value)] + [-1,1].*0.15;
  xySeriesPub(idx).xLabel = 'Norm. Length ($$\ell/\ell_o$$)';

  xySeriesPub(idx).left.y      = 'storage';
  xySeriesPub(idx).left.yTicks = [0:0.2:1.8];
  xySeriesPub(idx).left.yLim   = [-0.1,1.8] + [-1,1].*sqrt(eps);
  xySeriesPub(idx).left.yLabel = 'Norm. Storage ($$(\mathrm{mN}/\mathrm{mm})/(S_o^M)$$)';
  xySeriesPub(idx).left.color  = cs.magenta;
  xySeriesPub(idx).left.legend = '$$\tilde{S}^A + \tilde{S}^P$$';
  
  xySeriesPub(idx).right.y      = 'force';
  xySeriesPub(idx).right.yTicks = xySeriesPub(idx).left.yTicks;
  xySeriesPub(idx).right.yLim   = xySeriesPub(idx).left.yLim;
  xySeriesPub(idx).right.yLabel = 'Norm. Force ($$\mathrm{mN}/f_o^M$$)';
  xySeriesPub(idx).right.color  = [0,0,0];  
  xySeriesPub(idx).right.legend = '$$\tilde{f}^L+\tilde{f}^{PE}$$';

  
  %
  % Total active loss
  %  
  idx=idx+1;
  xySeriesPub(idx)=xySeriesPub(idx-1);
  xySeriesPub(idx).row=nan;
  xySeriesPub(idx).col=nan;

  xySeriesPub(idx).left.y      = 'loss';
  xySeriesPub(idx).left.yTicks = [-0.2:0.2:2];
  xySeriesPub(idx).left.yLim   = [-0.3,2.0] + [-1,1].*sqrt(eps);
  xySeriesPub(idx).right.yTicks = xySeriesPub(idx).left.yTicks;
  xySeriesPub(idx).right.yLim   = xySeriesPub(idx).left.yLim  ;

  if(modeNormalization==0)
    xySeriesPub(idx).left.yLabel = 'Norm. Loss ($$(\mathrm{mN}/\mathrm{mm})/(S_o^M)$$)';
  else
    xySeriesPub(idx).left.yLabel = 'Norm. Loss ($$(\mathrm{mN}/\mathrm{mm})/(L_o^M)$$)';
  end
  xySeriesPub(idx).left.color  = cs.magenta;
  xySeriesPub(idx).left.legend = '$$\tilde{L}^A + \tilde{L}^P$$';

  
  %
  % Passive storage
  %  
  idx=idx+1;
  xySeriesPub(idx)=xySeriesPub(1);
  xySeriesPub(idx).xData  = 'lengthPassive';
  xySeriesPub(idx).row=nan;
  xySeriesPub(idx).col=nan;
  xySeriesPub(idx).left.y      = 'storagePassive';
  xySeriesPub(idx).left.legend = '$$\tilde{S}^{P}$$';
  xySeriesPub(idx).left.color  = cs.blue;
  xySeriesPub(idx).right.y      = 'forcePassive';
  xySeriesPub(idx).right.legend = '$$\tilde{f}^{PE}$$';
  
  xySeriesPub(idx).left.yTicks = [0:0.1:0.6];
  xySeriesPub(idx).left.yLim   = [-0.05,0.65] + [-1,1].*sqrt(eps);
  xySeriesPub(idx).right.yTicks = xySeriesPub(idx).left.yTicks;
  xySeriesPub(idx).right.yLim   = xySeriesPub(idx).left.yLim;
 
  %
  % Passive loss
  %  
  idx=idx+1;
  xySeriesPub(idx)=xySeriesPub(2);
  xySeriesPub(idx).row=nan;
  xySeriesPub(idx).col=nan;
  xySeriesPub(idx).left.y      = 'lossPassive';
  xySeriesPub(idx).left.color  = cs.blue;
  xySeriesPub(idx).left.legend = '$$\tilde{L}^{P}$$';
  xySeriesPub(idx).right.y      = 'forcePassive';
  xySeriesPub(idx).right.legend = '$$\tilde{f}^{PE}$$';

  xySeriesPub(idx).left.yTicks = [-0.1:0.1:0.6];
  xySeriesPub(idx).left.yLim   = [-0.15,0.65] + [-1,1].*sqrt(eps);
  xySeriesPub(idx).right.yTicks = xySeriesPub(idx).left.yTicks;
  xySeriesPub(idx).right.yLim   = xySeriesPub(idx).left.yLim;
  
  %
  % Active storage
  %  
  idx=idx+1;
  xySeriesPub(idx)=xySeriesPub(1);
  xySeriesPub(idx).xData  = 'lengthActive';  
  xySeriesPub(idx).row=nan;
  xySeriesPub(idx).col=nan;
  xySeriesPub(idx).left.y      = 'storageActive';
  xySeriesPub(idx).left.color  = cs.red;
  xySeriesPub(idx).left.legend = '$$\tilde{S}^{A}$$';
  xySeriesPub(idx).right.y      = 'forceActive';
  xySeriesPub(idx).right.legend = '$$\tilde{f}^{L}$$';
  %
  % Active loss
  %  
  idx=idx+1;
  xySeriesPub(idx)=xySeriesPub(2);
  xySeriesPub(idx).row=nan;
  xySeriesPub(idx).col=nan;
  xySeriesPub(idx).left.y      = 'lossActive';
  xySeriesPub(idx).left.color  = cs.red;  
  xySeriesPub(idx).left.legend = '$$\tilde{L}^{A}$$';
  xySeriesPub(idx).right.y      = 'forceActive';
  xySeriesPub(idx).right.legend = '$$\tilde{f}^{L}$$';

%
% Plot configuration
%
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
slSeriesPub(idx).xValue=1;
slSeriesPub(idx).xTicks = [1,2,3,4];
slSeriesPub(idx).xTicksText = {};
slSeriesPub(idx).xLim = [0,5];
slSeriesPub(idx).xLabel= 'Perturbation Series';
slSeriesPub(idx).xData =[];

slSeriesPub(idx).y = 'storageAtLoNorm';
slSeriesPub(idx).yTicks = [0:10:70];
slSeriesPub(idx).yLim=...
  [min(slSeriesPub(idx).yTicks),...
   max(slSeriesPub(idx).yTicks)]+[-1,1].*0.5;
slSeriesPub(idx).yLabel='Norm. Storage ($$S^A_o/(f_o/\ell_o)$$)';
slSeriesPub(idx).yData=[];
slSeriesPub(idx).title={'A. Variation of normalized storage with perturbation',...
                            'bandwidth and amplitude'};
slSeriesPub(idx).color = [];

idx=idx+1;
slSeriesPub(idx).segment=1;
slSeriesPub(idx).row=1;
slSeriesPub(idx).col=2;
slSeriesPub(idx).xValue=1;
slSeriesPub(idx).xTicks = [1,2,3,4];
slSeriesPub(idx).xTicksText = {};
slSeriesPub(idx).xLim = [0,5];
slSeriesPub(idx).xLabel= 'Perturbation Series';
slSeriesPub(idx).xData =[];

slSeriesPub(idx).y = 'lossAtLoNorm';
slSeriesPub(idx).yTicks = [0:5:35];
slSeriesPub(idx).yLim=...
  [min(slSeriesPub(idx).yTicks),...
   max(slSeriesPub(idx).yTicks)]+[-1,1].*0.5;
slSeriesPub(idx).yLabel='Norm. Loss ($$L^A_o/(f_o/\ell_o)$$)';
slSeriesPub(idx).yData=[];
slSeriesPub(idx).title={'B. Variation of normalized loss with perturbation',...
                            'bandwidth and amplitude'};
slSeriesPub(idx).color = [];



idx=idx+1;
slSeriesPub(idx)=slSeriesPub(1);
slSeriesPub(idx).segment =2;
slSeriesPub(idx).xValue  =2;


idx=idx+1;
slSeriesPub(idx)=slSeriesPub(2);
slSeriesPub(idx).segment =2;
slSeriesPub(idx).xValue  =2;

idx=idx+1;
slSeriesPub(idx)=slSeriesPub(1);
slSeriesPub(idx).segment =3;
slSeriesPub(idx).xValue  =3;

idx=idx+1;
slSeriesPub(idx)=slSeriesPub(2);
slSeriesPub(idx).segment =3;
slSeriesPub(idx).xValue  =3;

idx=idx+1;
slSeriesPub(idx)=slSeriesPub(1);
slSeriesPub(idx).segment =4;
slSeriesPub(idx).xValue  =4;

idx=idx+1;
slSeriesPub(idx)=slSeriesPub(2);
slSeriesPub(idx).segment =4;
slSeriesPub(idx).xValue  =4;

%%
% Frequency Response Series
%%


frSeries(length(categories.length.value))=...
  struct('bandwidthHz',nan, ...
         'amplitudeLo',nan, ...
         'lengthNominal', nan,...             
         'forceAtLo', zeros(1,length(experimentList)),...
         'lengthAtLo', zeros(1,length(experimentList)),...
         'frequencyHz',zeros(settings.numberOfInterpolationPoints,1),...
         'storageActive',zeros(settings.numberOfInterpolationPoints,...
                             length(experimentList)),...
         'lossActive',zeros(settings.numberOfInterpolationPoints,...
                             length(experimentList)),...
         'storagePassive',zeros(settings.numberOfInterpolationPoints,...
                             length(experimentList)),...
         'lossPassive',zeros(settings.numberOfInterpolationPoints,...
                             length(experimentList)));

for idxL=1:1:length(frSeries)
  frSeries(idxL)=...
    struct('bandwidthHz',nan, ...
           'amplitudeLo',nan, ...
           'lengthNominal', nan,...
           'forceAtLo', zeros(1,length(experimentList)),...
           'lengthAtLo', zeros(1,length(experimentList)),...    
           'frequencyHz',zeros(settings.numberOfInterpolationPoints,1),...
           'storageActive',zeros(settings.numberOfInterpolationPoints,...
                               length(experimentList)),...
           'lossActive',zeros(settings.numberOfInterpolationPoints,...
                               length(experimentList)),...
           'storagePassive',zeros(settings.numberOfInterpolationPoints,...
                               length(experimentList)),...
           'lossPassive',zeros(settings.numberOfInterpolationPoints,...
                               length(experimentList)));  

end

setFRSeries(length(segmentSeries))=struct('frSeries',[]);
for idxFR=1:1:length(setFRSeries)
  setFRSeries(idxFR).frSeries=frSeries;
end


%%
% Go through the experimental data, normalize it, and accumulate it
%%

for indexSegment=1:1:length(segmentSeries)
  segId=segmentSeries(indexSegment);
  
  expDataSet(length(categories.length.value)) ...
          = struct('lengthNominal',[],...
                   'forceAtLo',[],...
                   'storageAtLo',[],...
                   'lossAtLo',[],...    
                   'storageAtLoNorm',[],...
                   'lossAtLoNorm',[],...                       
                   'medianForce',[],...
                   'medianForceActive',[],...
                   'medianForcePassive',[],...
                   'length',[],...
                   'force',[],...                       
                   'lengthActive',[],...
                   'forceActive',[],...
                   'lengthPassive',[],...
                   'forcePassive',[],...
                   'storage',[],...
                   'loss',[], ...
                   'storageActive',[],...
                   'lossActive',[], ...
                   'storagePassive',[],...
                   'lossPassive',[],...
                   'amplitudeActive',[],...
                   'amplitudePassive',[],...
                   'bandwidthActive',[],...
                   'bandwidthPassive',[],...
                   'amplitudeTarget',[],...
                   'bandwidthTarget',[]);
  
  for i=1:1:length(categories.length.value)
    expDataSet(i) = struct('lengthNominal',categories.length.value(i),...
                           'forceAtLo',[],...
                           'storageAtLo',[],...
                           'lossAtLo',[],... 
                           'storageAtLoNorm',[],...
                           'lossAtLoNorm',[],... 
                           'medianForce',[],...
                           'medianForceActive',[],...
                           'medianForcePassive',[],...
                           'length',[],...
                           'force',[],...                       
                           'lengthActive',[],...
                           'forceActive',[],...
                           'lengthPassive',[],...
                           'forcePassive',[],...
                           'storage',[],...
                           'loss',[], ...
                           'storageActive',[],...
                           'lossActive',[], ...
                           'storagePassive',[],...
                           'lossPassive',[],...
                           'amplitudeActive',[],...
                           'amplitudePassive',[],...
                           'bandwidthActive',[],...
                           'bandwidthPassive',[],...
                           'amplitudeTarget',[],...
                           'bandwidthTarget',[]);
  end
  
  for idxExp = 1:1:length(experimentList)
  
    trialList = dir(fullfile(projectFolders.output600A_json,...
                      experimentList{idxExp}));
  
  
    trialDataSet(length(categories.length.value)) ...
              = struct('lengthNominal',nan,...
                       'forceAtLo',[],...
                       'storageAtLo',[],...
                       'lossAtLo',[],...              
                       'medianLength',[],...
                       'medianLengthActive',[],...
                       'medianLengthPassive',[],...
                       'medianForce',[],...
                       'medianForceActive',nan,...
                       'medianForcePassive',[],...
                       'length',[],...
                       'force',[],...                       
                       'lengthActive',[],...
                       'forceActive',[],...
                       'lengthPassive',[],...
                       'forcePassive',[],...
                       'storage',[],...
                       'loss',[], ...
                       'storageActive',[],...
                       'lossActive',[], ...
                       'storagePassive',[],...
                       'lossPassive',[],...
                       'amplitudeActive',[],...
                       'amplitudePassive',[],...
                       'bandwidthActive',[],...
                       'bandwidthPassive',[],...
                       'amplitudeTarget',[],...
                       'bandwidthTarget',[]);  
    
    for i=1:1:length(categories.length.value)
      trialDataSet(i) = ...
            struct('lengthNominal',categories.length.value(i),...
                   'forceAtLo',[],...
                   'storageAtLo',[],...
                   'lossAtLo',[],...    
                   'medianLength',nan,...
                   'medianLengthActive',[],...
                   'medianLengthPassive',[],...
                   'medianForce',nan,...
                   'medianForceActive',nan,...
                   'medianForcePassive',[],...
                   'length',[],...
                   'force',[],...                       
                   'lengthActive',[],...
                   'forceActive',[],...
                   'lengthPassive',[],...
                   'forcePassive',[],...
                   'storage',[],...
                   'loss',[], ...
                   'storageActive',[],...
                   'lossActive',[], ...
                   'storagePassive',[],...
                   'lossPassive',[],...
                   'amplitudeActive',[],...
                   'amplitudePassive',[],...
                   'bandwidthActive',[],...
                   'bandwidthPassive',[],...
                   'amplitudeTarget',[],...
                   'bandwidthTarget',[]);  
    end
  
    bandwidthHz=nan;
    amplitudeLo=nan;
  
    for idxTrialA=1:1:length(trialList)
  
      if(contains(trialList(idxTrialA).name,'.json'))
        %If this is an active trial, get its data, then get the 
        %corresponding passive data
        if(contains(trialList(idxTrialA).name,'_active_'))
          idxL = nan;
          for i = 1:1:length(categories.length.str)
            if(contains(trialList(idxTrialA).name,categories.length.str{i}))
              assert(isnan(idxL),'Error: there appear to be two valid active trials');
              idxL=i;
            end
          end
          assert(~isnan(idxL),'Error: could not find a valid length category');
                    
          aFilePath = fullfile(projectFolders.output600A_json,...
                              experimentList{idxExp},...
                              trialList(idxTrialA).name);
          aFileData = fileread(aFilePath);
          aJsonData = jsondecode(aFileData);
 
          assert(strcmp(aJsonData(segId).segment.unit.length,lengthUnit));
          assert(strcmp(aJsonData(segId).segment.unit.force,forceUnit));
          assert(strcmp(aJsonData(segId).segment.unit.time,timeUnit));
  
          %Go and get the passive data
          idxTrialP=nan;
          for idxTmp=1:1:length(trialList)
            if(   contains(trialList(idxTmp).name,'_passive_') ...
               && contains(trialList(idxTmp).name,categories.length.str{idxL}))
              assert(isnan(idxTrialP),'Error: there appear to be two valid passive trials');
              idxTrialP=idxTmp;
            end
          end
          assert(~isnan(idxTrialP),'Error: could not find a matching passive trial');
          pFilePath = fullfile(projectFolders.output600A_json,...
                              experimentList{idxExp},...
                              trialList(idxTrialP).name);
          pFileData = fileread(pFilePath);
          pJsonData = jsondecode(pFileData);        

          assert(strcmp(pJsonData(segId).segment.unit.length,lengthUnit));
          assert(strcmp(pJsonData(segId).segment.unit.force,forceUnit));
          assert(strcmp(pJsonData(segId).segment.unit.time,timeUnit));
          
          bandwidthTarget=max(aJsonData(segId).segment.H.bandwidthHz);
          %Peak-to-peak
          amplitudeTarget=aJsonData(segId).segment.H.amplitudeLo*2;

          if(~isempty(pJsonData(segId).segment.H.bandwidthHzC2))

            if(abs(max(aJsonData(segId).segment.H.bandwidthHz)...
                      -max(pJsonData(segId).segment.H.bandwidthHz))>1e-6)
              here=1;
            end
            if(abs(aJsonData(segId).segment.H.amplitudeLo...
                       -pJsonData(segId).segment.H.amplitudeLo)>1e-6)
              here=1;
            end
            assert(abs(max(aJsonData(segId).segment.H.bandwidthHz)...
                      -max(pJsonData(segId).segment.H.bandwidthHz))<1e-6);
            assert(abs(aJsonData(segId).segment.H.amplitudeLo...
                      -pJsonData(segId).segment.H.amplitudeLo)<1e-6);
          end

          if(isnan(bandwidthHz) && isnan(amplitudeLo))
            bandwidthHz=max(aJsonData(segId).segment.H.bandwidthHz);
            amplitudeLo=     ( max(aJsonData(segId).segment.H.x) ...
                              -min(aJsonData(segId).segment.H.x));
          else
            bandwidthHzA=max(aJsonData(segId).segment.H.bandwidthHz);
            amplitudeLoA= ( max(aJsonData(segId).segment.H.x) ...
                           -min(aJsonData(segId).segment.H.x));
            bandwidthHzP=max(pJsonData(segId).segment.H.bandwidthHz);
            amplitudeLoP=   ( max(pJsonData(segId).segment.H.x) ...
                              -min(pJsonData(segId).segment.H.x));
  
            bwARerr=(bandwidthHz-bandwidthHzA)...
              /(0.5*(bandwidthHz+bandwidthHzA));
            bwPRerr=(bandwidthHz-bandwidthHzP)...
              /(0.5*(bandwidthHz+bandwidthHzP));
  
            ampARerr=(amplitudeLo-amplitudeLoA)...
              /(0.5*(amplitudeLo+amplitudeLoA));
            ampPRerr=(amplitudeLo-amplitudeLoP)...
              /(0.5*(amplitudeLo+amplitudeLoP));

            relErrors=[bwARerr;bwPRerr;ampARerr;ampPRerr];
            relErrorType = ...
              {'BW-Active','BW-Passive','Amp-Active','Amp-Passive'};
            for idxErr=1:1:length(relErrors)
              if(abs(relErrors(idxErr)) > 0.2)
                fprintf(['Warning: Relative %s error exceeds threshold',...
                        ' at segment %i which is (%1.2f Hz, %1.4f %s) \n'],...
                        relErrorType{idxErr},segId,...
                        bandwidthHz,amplitudeLo,'$$\ell_o$$');
              end
            end

            
            
          end
  
          fprintf('\n\n(%i,%i)\t%s\n\t%s\n',...
              idxExp,idxTrialA,aFilePath,pFilePath);
  
          %If the passive data has a large valid bandwidth, then
          %subtract the passive storage from the active storage, 
          %and also for the loss
  
          idxBWC2 = aJsonData(segId).segment.H.idxBWC2;
  
          %
          % The nominal force is taken from the first segment. The
          % segments that follow might contain higher/lower forces
          % as the fiber returns to is equilbrium force after being
          % perturbed
          %
          tB = aJsonData(1).segment.pre.raw.time(end);
          idxB = length(aJsonData(1).segment.pre.raw.time);
          assert(strcmp(aJsonData(1).segment.unit.time,'ms'));
          idxA=find(aJsonData(1).segment.pre.raw.time ...
                   > tB-nominalForceWindowInMs,1,'first');
          
  
          trialDataSet(idxL).lengthNominal=categories.length.value(idxL); 
  
          trialDataSet(idxL).medianForce=...
            median(aJsonData(segId).segment.pre.raw.force(idxA:idxB));

          trialDataSet(idxL).medianLength = ...
              median(aJsonData(segId).segment.pre.raw.length(idxA:idxB));

          trialDataSet(idxL).medianLengthActive = ...
            trialDataSet(idxL).medianLength;

          trialDataSet(idxL).medianForceActive=...
            trialDataSet(idxL).medianForce;  
  
          trialDataSet(idxL).medianForcePassive=[];

          trialDataSet(idxL).amplitudeTarget=amplitudeTarget;
          trialDataSet(idxL).bandwidthTarget=bandwidthTarget;
        

          if(   exist('amplitudeLoA','var') && exist('bandwidthHzA','var')...
             && exist('amplitudeLoP','var') && exist('bandwidthHzP','var'))
            trialDataSet(idxL).amplitudeActive  =amplitudeLoA;
            trialDataSet(idxL).amplitudePassive =amplitudeLoP;
            trialDataSet(idxL).bandwidthActive  =bandwidthHzA;
            trialDataSet(idxL).bandwidthPassive =bandwidthHzP;  
          end
          if(~isempty(pJsonData(segId).segment.force))
            idxB = length(pJsonData(segId).segment.pre.raw.time);
            tB   = pJsonData(segId).segment.pre.raw.time(end);
            assert(strcmp(aJsonData(segId).segment.unit.time,'ms'));          
            idxA = find(pJsonData(segId).segment.pre.raw.time ...
                      > (tB-nominalForceWindowInMs),1,'first');
    
            trialDataSet(idxL).medianLengthPassive=...
              median(pJsonData(segId).segment.pre.raw.length(idxA:idxB));

            trialDataSet(idxL).medianForcePassive=...
              median(pJsonData(segId).segment.pre.raw.force(idxA:idxB));

            trialDataSet(idxL).medianForceActive=...
              trialDataSet(idxL).medianForceActive ...
              -trialDataSet(idxL).medianForcePassive;
          end
  


          trialDataSet(idxL).lengthActive= ...
            aJsonData(segId).segment.pre.raw.length;

          trialDataSet(idxL).forceActive= ...
            aJsonData(segId).segment.pre.raw.force;
          
          trialDataSet(idxL).length = trialDataSet(idxL).lengthActive;
          trialDataSet(idxL).force  = trialDataSet(idxL).forceActive;

          trialDataSet(idxL).lengthPassive = [];
          trialDataSet(idxL).forcePassive = [];          

          if(~isempty(pJsonData(segId).segment.force))
            trialDataSet(idxL).lengthPassive = ...
              pJsonData(segId).segment.pre.raw.length;
  
            trialDataSet(idxL).forcePassive = ...
              pJsonData(segId).segment.pre.raw.force;

            trialDataSet(idxL).forceActive = ...
              trialDataSet(idxL).forceActive ...
              - mean(trialDataSet(idxL).forcePassive);
          end

          flag_debugNominalForce=0;
          if(flag_debugNominalForce==1)
            figNForce=figure;

            yMin = min(0,min(trialDataSet(idxL).forcePassive));
            yMin = min(yMin,min(trialDataSet(idxL).force));
            yMin = min(yMin,min(trialDataSet(idxL).forceActive));
            
            yMax = max(0,max(trialDataSet(idxL).forcePassive));
            yMax = max(yMax,max(trialDataSet(idxL).force));
            yMax = max(yMax,max(trialDataSet(idxL).forceActive));

            subplot(1,3,1);
              plot(trialDataSet(idxL).force);
              ylim([yMin,yMax]);
              ylabel('Total Force');
            subplot(1,3,2);              
              plot(trialDataSet(idxL).forcePassive);
              ylim([yMin,yMax]);
              ylabel('Passive Force');              
            subplot(1,3,3);
              plot(trialDataSet(idxL).forceActive);
              ylim([yMin,yMax]);
              ylabel('Active Force');
            close(figNForce);
          end

          trialDataSet(idxL).storage = ...
            aJsonData(segId).segment.H.storage(idxBWC2);

          if(sum(isnan(aJsonData(segId).segment.H.storage(idxBWC2)))>0)
            here=1;
          end
  
          trialDataSet(idxL).loss = ...
            aJsonData(segId).segment.H.loss(idxBWC2);
          
          if(sum(isnan(aJsonData(segId).segment.H.loss(idxBWC2)))>0)
            here=1;
          end

          trialDataSet(idxL).storageActive=...
            trialDataSet(idxL).storage;
  
          trialDataSet(idxL).lossActive = ...
            trialDataSet(idxL).loss;
  

          nIPts=settings.numberOfInterpolationPoints;
          frSeries(idxL).bandwidthHz=bandwidthTarget;
          frSeries(idxL).amplitudeLo=amplitudeTarget;          
          frSeries(idxL).lengthNominal=categories.length.value(idxL);
          frSeries(idxL).frequencyHz = ...
            ([1:1:(nIPts)]').*(bandwidthTarget/nIPts);          

          freqResFieldsActive=...
            {'storageActive','lossActive'};
          freqResFieldsPassive=...
            {'storagePassive','lossPassive'};
          analysisFields=...
            {'storage','loss'};

          for idxF=1:1:length(freqResFieldsActive)
            aField = analysisFields{idxF};

            fieldActive=freqResFieldsActive{idxF};
            frSeries(idxL).(fieldActive)(:,idxExp)=...
              ones(settings.numberOfInterpolationPoints,1).*nan;

            bandwidthHzC2A=aJsonData(segId).segment.H.bandwidthHzC2;

            %Active fields
            if(~isempty(bandwidthHzC2A))
              idxFRSA = find(frSeries(idxL).frequencyHz >= bandwidthHzC2A(1) ...
                           & frSeries(idxL).frequencyHz <= bandwidthHzC2A(2));
  
              frSeries(idxL).(fieldActive)(idxFRSA,idxExp) = ...
                interp1(aJsonData(segId).segment.H.frequencyHz,...
                        aJsonData(segId).segment.H.(aField),...
                        frSeries(idxL).frequencyHz(idxFRSA));
            else
              disp('Odd: this active trial does not have any bandwidth that');
              disp('     meets the coherence squared requirement');              
            end
            %Passive fields
            fieldPassive=freqResFieldsPassive{idxF};
            frSeries(idxL).(fieldPassive)(:,idxExp)=...
              ones(settings.numberOfInterpolationPoints,1).*nan;
            
            bandwidthHzC2P=pJsonData(segId).segment.H.bandwidthHzC2;   
            if(~isempty(bandwidthHzC2P))
              idxFRSP = find(frSeries(idxL).frequencyHz >= bandwidthHzC2P(1) ...
                           & frSeries(idxL).frequencyHz <= bandwidthHzC2P(2));
          
              frSeries(idxL).(fieldPassive)(idxFRSP,idxExp) = ...
                interp1(pJsonData(segId).segment.H.frequencyHz,...
                        pJsonData(segId).segment.H.(aField),...
                        frSeries(idxL).frequencyHz(idxFRSP));

              %Subtract off the passive component from the active
              frSeries(idxL).(fieldActive)(idxFRSP,idxExp) = ...
                frSeries(idxL).(fieldActive)(idxFRSP,idxExp) ...
                -frSeries(idxL).(fieldPassive)(idxFRSP,idxExp);
              
            end
            
            
          end



          

          if(~isempty(pJsonData(segId).segment.H.bandwidthHzC2))          
            bwA = diff(aJsonData(segId).segment.H.bandwidthHzC2);
            bwP = diff(pJsonData(segId).segment.H.bandwidthHzC2);
            bwN = bwP/bwA;
            if(bwN > 0.75)
              storageP = interp1(pJsonData(segId).segment.H.frequencyHz,...
                                 pJsonData(segId).segment.H.storage,...
                                 aJsonData(segId).segment.H.frequencyHz(idxBWC2));
              lossP = interp1(pJsonData(segId).segment.H.frequencyHz,...
                              pJsonData(segId).segment.H.loss,...
                              aJsonData(segId).segment.H.frequencyHz(idxBWC2));
  
              if(sum(isnan(storageP))>0)
                here=1;
              end
              if(sum(isnan(lossP))>0)
                here=1;
              end
              
              trialDataSet(idxL).storagePassive = storageP;
              trialDataSet(idxL).lossPassive    = lossP;
  
              trialDataSet(idxL).storageActive = ...
                trialDataSet(idxL).storageActive - storageP;
              trialDataSet(idxL).lossActive    = ...
                trialDataSet(idxL).lossActive - lossP;
            end
          end
        end
      end
    end
  
    %Check that all categories have been filled.
    for idxC=1:1:length(trialDataSet)
      assert(~isnan(trialDataSet(idxC).medianForce));
    end
  
    %Adjust the passive forces so that 0.55 Lo is zero, and then
    %evaluate the nominal active force
    %
    % No longer necessary: this is done when processing the data.
    %
  %   for idxC=1:1:length(trialDataSet)
  %     trialDataSet(idxC).medianForcePassive= ...
  %       trialDataSet(idxC).medianForcePassive ...
  %       -trialDataSet(1).medianForcePassive;
  %     trialDataSet(idxC).medianForceActive = ...
  %       trialDataSet(idxC).medianForce ...
  %       -trialDataSet(idxC).medianForcePassive;
  %   end
  
    %Normalize the data
    normTrialDataSet(length(categories.length.value)) ...
              = struct('lengthNominal',[],...  
                       'lengthAtLo',[],...
                       'forceAtLo',[],...
                       'storageAtLo',[],...
                       'lossAtLo',[],...
                       'storageAtLoNorm',[],...
                       'lossAtLoNorm',[],...                       
                       'medianLength',[],...
                       'medianLengthActive',[],...
                       'medianLengthPassive',[],...
                       'medianForce',[],...
                       'medianForceActive',[],...
                       'medianForcePassive',[],...
                       'length',[],...
                       'force',[],...
                       'lengthActive',[],...
                       'forceActive',[],...
                       'lengthPassive',[],...
                       'forcePassive',[],...                       
                       'storage',[],...
                       'loss',[],...
                       'storageActive',[],...
                       'lossActive',[],...
                       'storagePassive',[],...
                       'lossPassive',[],...
                       'amplitudeActive',[],...
                       'amplitudePassive',[],...
                       'bandwidthActive',[],...
                       'bandwidthPassive',[],...
                       'amplitudeTarget',[],...
                       'bandwidthTarget',[]);  
    
    iN = categories.length.indexLopt;
  
    for i=1:1:length(trialDataSet)

      isStorageLossDataValid=0;
      if(~isempty(trialDataSet(iN).loss) ...
          && ~isempty(trialDataSet(iN).storage))
        isStorageLossDataValid=1;
      end

      if(isStorageLossDataValid==1)
        normTrialDataSet(i).lengthNominal=trialDataSet(i).lengthNominal;    
        normTrialDataSet(i).amplitudeTarget=trialDataSet(i).amplitudeTarget;
        normTrialDataSet(i).bandwidthTarget=trialDataSet(i).bandwidthTarget;
        
        lopt = median(trialDataSet(iN).length);
        fiso = trialDataSet(iN).medianForceActive;
        siso=nan;
        liso=nan;
        if(modeNormalization==0)
          siso = median(trialDataSet(iN).storageActive);
          liso = siso;      
        end
        if(modeNormalization==1)
          siso = median(trialDataSet(iN).storageActive);
          liso = median(trialDataSet(iN).lossActive);      
        end

        for idxFR=1:1:length(frSeries)
          frSeries(idxFR).forceAtLo(1,idxExp)=fiso;
          frSeries(idxFR).lengthAtLo(1,idxExp)=lopt;
        end

        normTrialDataSet(i).medianLength=...
          trialDataSet(iN).medianLength;
        normTrialDataSet(i).medianLengthActive=...
          trialDataSet(iN).medianLengthActive;
        normTrialDataSet(i).medianLengthPassive=...
          trialDataSet(iN).medianLengthPassive;

        normTrialDataSet(i).lengthAtLo=liso;
        normTrialDataSet(i).forceAtLo=fiso;
        normTrialDataSet(i).storageAtLo=median(trialDataSet(iN).storageActive);
        normTrialDataSet(i).lossAtLo=median(trialDataSet(iN).lossActive);
    
        normFactor = fiso/lopt;

        normTrialDataSet(i).storageAtLoNorm = ...
          normTrialDataSet(i).storageAtLo/normFactor;
        normTrialDataSet(i).lossAtLoNorm = ...
          normTrialDataSet(i).lossAtLo/normFactor;

        normTrialDataSet(i).medianForceActive = ...
          trialDataSet(i).medianForceActive / fiso;
        normTrialDataSet(i).medianForce = ...
          trialDataSet(i).medianForce / fiso;
        normTrialDataSet(i).medianForcePassive = ...
          trialDataSet(i).medianForcePassive / fiso;
        
        nPtsActive=length(trialDataSet(i).storageActive);
        nPtsPassive=length(trialDataSet(i).storagePassive);
        nPtsTotal=length(trialDataSet(i).storage);

        normTrialDataSet(i).length = ...
          trialDataSet(i).length(1:nPtsTotal) ./ lopt;
        normTrialDataSet(i).lengthActive = ...
          trialDataSet(i).lengthActive(1:nPtsActive) ./ lopt;
        normTrialDataSet(i).lengthPassive = ...
          trialDataSet(i).lengthPassive(1:nPtsPassive) ./ lopt;

        normTrialDataSet(i).force = ...
          trialDataSet(i).force(1:nPtsTotal) ./ fiso;
        normTrialDataSet(i).forceActive = ...
          trialDataSet(i).forceActive(1:nPtsActive) ./ fiso;
        normTrialDataSet(i).forcePassive = ...
          trialDataSet(i).forcePassive(1:nPtsPassive) ./ fiso;        

        normTrialDataSet(i).storage = ...
          trialDataSet(i).storage / siso;
        normTrialDataSet(i).loss = ...
          trialDataSet(i).loss / liso;
       
        normTrialDataSet(i).storageActive = ...
          trialDataSet(i).storageActive / siso;
        normTrialDataSet(i).lossActive = ...
          trialDataSet(i).lossActive / liso;  
      
        normTrialDataSet(i).storagePassive = ...
          trialDataSet(i).storagePassive / siso;
        normTrialDataSet(i).lossPassive = ...
          trialDataSet(i).lossPassive / liso;    
    
        normTrialDataSet(i).bandwidthActive=...
          trialDataSet(i).bandwidthActive;
        normTrialDataSet(i).bandwidthPassive=...
          trialDataSet(i).bandwidthPassive;
        normTrialDataSet(i).amplitudeActive=...
          trialDataSet(i).amplitudeActive;
        normTrialDataSet(i).amplitudePassive=...
          trialDataSet(i).amplitudePassive;


        fieldsToTest=fields(normTrialDataSet(i));
        for idxF=1:1:length(fieldsToTest)
          if(sum(isnan(normTrialDataSet(i).(fieldsToTest{idxF})))>0)
            here=1;
          end
        end

      end
    end
  
    %
    % Plot the individual data
    %
    bwAmpFormat = '(%1.1f Hz, %1.3f %s)';
    if(amplitudeTarget > 0.009)
      bwAmpFormat = '(%1.1f Hz, %1.2f %s)';
    end

    for i=1:2:(length(xySeries)-2)




      xySeries(i).row   = indexSegment;
      xySeries(i).title = sprintf(['Storage-Length-Relation ',...
                                    bwAmpFormat],...
                                    bandwidthTarget,amplitudeTarget,'$$\ell_o$$');   
      xySeries(i+1).row   = indexSegment;
      xySeries(i+1).title = sprintf(['Loss-Length-Relation ',...
                                    bwAmpFormat],...
                                    bandwidthTarget,amplitudeTarget,'$$\ell_o$$');
    end
    i=length(xySeries)-1;
    xySeries(i).row   = indexSegment;
    xySeries(i).title = sprintf(['Force-Length-Relation ',...
                                  bwAmpFormat],...
                                  bandwidthTarget,amplitudeTarget,'$$\ell_o$$');   
    xySeries(i+1).row   = indexSegment;
    xySeries(i+1).title = sprintf(['Force-Length-Relation ',...
                                  bwAmpFormat],...
                                  bandwidthTarget,amplitudeTarget,'$$\ell_o$$');    

    n=0;
    if(length(experimentList)>1)
      n = (idxExp-1)/(length(experimentList)-1);
    end
    expColor = ([1,1,1].*0.5).*n + [0,0,0].*(1-n);
    pColor =    [0.5,0.5,1].*n + [0,0,1].*(1-n);
    nColor =    expColor;
    aColor =    [1,0.5,0.5].*n + [1,0,0].*(1-n);
    
    if(settings.addPlotBoxAndWhiskerIndividual==1)
      for i=1:1:length(xySeries)
        figure(figHindiv);
        subplot('Position',...
          reshape(subPlotPanelZi(xySeries(i).row,...
                                xySeries(i).col,:),1,4));
        
        %Plot the force-length relation in the background
        nData.l=[];
        nData.f=[];
        aData.l=[];
        aData.f=[];  
        pData.l=[];
        pData.f=[];
        for j=1:1:length(normTrialDataSet)
          if(~isnan(mean(normTrialDataSet(j).medianForceActive)))
            aData.l=[aData.l,normTrialDataSet(j).lengthNominal];
            aData.f = [aData.f,mean(normTrialDataSet(j).medianForceActive)];
          end
          if(~isnan(mean(normTrialDataSet(j).medianForce)))
            nData.l=[nData.l,normTrialDataSet(j).lengthNominal];
            nData.f = [nData.f,mean(normTrialDataSet(j).medianForce)];
          end
          
          pTmp = normTrialDataSet(j).medianForcePassive;
          %idxP = find(pTmp >=0);
          %if(~isempty(idxP))
          if(~isnan(mean(pTmp)))
            pData.f = [pData.f,mean(pTmp)];
            pData.l = [pData.l,normTrialDataSet(j).lengthNominal];
          end
          %end
        end
      
  
  %       if(i==1 || i==2)
  %         yMax = median(normTrialDataSet(categories.length.indexLopt).(xySeries(i).y));
  %         plot(pData.l,pData.f.*yMax,'-','Color',pColor);
  %         hold on;
  %         plot(nData.l,nData.f.*yMax,'-','Color',nColor);
  %         hold on;          
  %       end    
      
        %Plot the stiffness / loss data
        for j=1:1:length(normTrialDataSet)
      
          if(~isempty(normTrialDataSet(j).(xySeries(i).y)))
            bwWidth = 0.010;
            bwOffset= bwWidth*1.5*idxExp;
            isActive=0;
            if(contains((xySeries(i).y),'Active'))
              isActive=1;
              lineColor = aColor;
              boxColor  = [1,1,1];
              
            elseif(contains((xySeries(i).y),'Passive'))
              bwOffset= bwWidth*1.1*idxExp;
              lineColor = pColor;
              boxColor  = [1,1,1];
              
            else
              lineColor = nColor;
              boxColor  = [1,1,1];
            end
  
            if(isActive==0)
              summaryStatistics = getSummaryStatistics(normTrialDataSet(j).(xySeries(i).y));
              plotBoxWhiskerData(normTrialDataSet(j).lengthNominal+bwOffset,...
                                 summaryStatistics,...
                                 bwWidth,lineColor,boxColor);
  
            end
          end
      
        end
  
        if(idxExp==1)
          xlabel(xySeries(i).xLabel);
          ylabel(xySeries(i).yLabel);
          title(xySeries(i).title);
          ylim(xySeries(i).yLim);
          xlim([xySeries(i).xLim(1),xySeries(i).xLim(2)+0.15]);
          xticks(xySeries(i).xTicks);
          yticks(xySeries(i).yTicks);  
        end
        if(i==1 && idxExp==1)
          text(0.7,0.1,'$$f^L(\ell)$$','HorizontalAlignment','right',...
                       'FontSize',6);
          hold on;
          text(1.25,0.1,'$$f^{P}(\ell)$$','HorizontalAlignment','right',...
                       'FontSize',6);
          hold on;
          
        end
        box off;
        here=1;
      end

      nExp = (idxExp-1)/(length(experimentList)-1);
      storageColor  = cs.red.*(1-nExp*0.5)+[1,1,1].*(nExp*0.5);
      lossColor     = cs.blue.*(1-nExp*0.5)+[1,1,1].*(nExp*0.5);

      %Add frSeries data
      for idxFR=1:1:length(frSeries)
        figure(figHindiv);
        subplot('Position',...
          reshape(subPlotPanelZi(segId,frSeriesColumnStart+idxFR-1,:),1,4));
  
          normFactor = frSeries(idxFR).forceAtLo(1,idxExp) ...
                      /frSeries(idxFR).lengthAtLo(1,idxExp);
  
          yyaxis left;
  
          idxV = find(~isnan(frSeries(idxFR).storageActive(:,idxExp)));          
          plot(frSeries(idxFR).frequencyHz(idxV),...
               frSeries(idxFR).storageActive(idxV,idxExp)./normFactor,...
               '-','Color',storageColor);
          hold on;
          ylim([0,80]);
          
          xlabel('Frequency (Hz)');
          ylabel(sprintf('Storage (%s/%s)',forceUnit,lengthUnit));
  
          yyaxis right;
          idxV = find(~isnan(frSeries(idxFR).lossActive(:,idxExp)));          
          plot(frSeries(idxFR).frequencyHz(idxV),...
               frSeries(idxFR).lossActive(idxV,idxExp)/normFactor,...
               '-','Color',lossColor);
          hold on;
          ylim([0,80]);
          ylabel(sprintf('Loss (%s/%s)',forceUnit,lengthUnit));
          box off;
          title(sprintf('%1.2f %s',frSeries(idxFR).lengthNominal(idxFR)));
          
          ax=gca;
          ax.YAxis(1).Color=cs.red;
          ax.YAxis(2).Color=cs.blue;
      end


    end


    %
    % Accumulate this into the experiment data set
    %
    setFRSeries(segId).frSeries=frSeries;
    
    fieldsToAccmulate = ...
      {'medianForce','medianForceActive','medianForcePassive',....
       'length','force',...
       'lengthActive','forceActive',...
       'lengthPassive','forcePassive',...
       'storageAtLo','lossAtLo',...
       'storageAtLoNorm','lossAtLoNorm',...       
       'storage','loss',...
       'storageActive','lossActive',...
       'storagePassive','lossPassive',...
       'forceAtLo','storageAtLo','lossAtLo',...
       'amplitudeActive','amplitudePassive',...
       'bandwidthActive','bandwidthPassive',...
       'amplitudeTarget','bandwidthTarget'};
    
    for i=1:1:length(expDataSet)
      for j=1:1:length(fieldsToAccmulate)
        expDataSet(i).(fieldsToAccmulate{j}) = ...
          [expDataSet(i).(fieldsToAccmulate{j});...
           normTrialDataSet(i).(fieldsToAccmulate{j})];
        if(sum(isnan(expDataSet(i).(fieldsToAccmulate{j})))>0)
          here=1;
        end
      end
    end
    here=1;
  end
  
  %%
  % Make the plots
  %%
  
 
  %%
  % Update the plotting struct
  %%
  bwAmpFormat = '(%1.1f Hz, %1.3f %s)';
  if(amplitudeTarget > 0.009)
    bwAmpFormat = '(%1.1f Hz, %1.2f %s)';
  end

  titleMod = {'Total','Total','Passive','Passive','Active','Active'};
  rowStartStorage=[1,1,1,1,1,1];
  colStartStorage=[5,5,3,3,1,1];
  rowStartLoss   =[3,3,3,3,3,3];
  colStartLoss   =[5,5,3,3,1,1];
  
  %Update the titles
  for i=1:2:length(xySeriesPub)

    labelMod='';

    xySeriesPub(i).row=rowStartStorage(i);
    xySeriesPub(i).col=colStartStorage(i);      
    xySeriesPub(i+1).row=rowStartLoss(i);
    xySeriesPub(i+1).col=colStartLoss(i);   

    storageColor=[];
    lossColor =[];
    switch i
      case 1
        storageColor=[cs.red; cs.magenta].*0.75;                
        lossColor   =[cs.blue; cs.teal].*0.75;                        
      case 2
        storageColor=[cs.red; cs.magenta].*0.75;                
        lossColor   =[cs.blue; cs.teal].*0.75;                
      case 3
        storageColor=[cs.red; cs.magenta].*0.5 + [0,0,0; 0,0,0];                
        lossColor   =[cs.blue; cs.teal].*0.5 + [0,0,0; 0,0,0];                
      case 4
        storageColor=[cs.red; cs.magenta].*0.5 + [0,0,0; 0,0,0];                
        lossColor   =[cs.blue; cs.teal].*0.5 + [0,0,0; 0,0,0];                
      case 5
        storageColor=[cs.red; cs.magenta];                
        lossColor   =[cs.blue; cs.teal];                
      case 6
        storageColor=[cs.red; cs.magenta];                
        lossColor   =[cs.blue; cs.teal];                
        
      otherwise
        assert(0,'Error: invalid index');
    end

    nSeg = (segId-1)/(3);

    xySeriesPub(i).left.color = ...
       storageColor(1,:).*nSeg ...
      +storageColor(2,:).*(1-nSeg);

    xySeriesPub(i+1).left.color = ...
       lossColor(1,:).*nSeg ...
      +lossColor(2,:).*(1-nSeg);

    for idxSL = 1:1:length(slSeriesPub)
      if(abs(slSeriesPub(idxSL).segment-segId)<1e-6)
        if(contains(slSeriesPub(idxSL).y,'storage'))
          slSeriesPub(idxSL).color =xySeriesPub(i).left.color;
        else
          slSeriesPub(idxSL).color =xySeriesPub(i+1).left.color;
        end
      end
    end
    
    switch segId
      case 1
        xySeriesPub(i).row=xySeriesPub(i).row+0;
        xySeriesPub(i).col=xySeriesPub(i).col+0;
        xySeriesPub(i+1).row=xySeriesPub(i+1).row+0;
        xySeriesPub(i+1).col=xySeriesPub(i+1).col+0;
        labelMod='A. ';
        
      case 2
        xySeriesPub(i).row=xySeriesPub(i).row+0;
        xySeriesPub(i).col=xySeriesPub(i).col+1;
        xySeriesPub(i+1).row=xySeriesPub(i+1).row+0;
        xySeriesPub(i+1).col=xySeriesPub(i+1).col+1;
        labelMod='B. ';
        
      case 3
        xySeriesPub(i).row=xySeriesPub(i).row+1;
        xySeriesPub(i).col=xySeriesPub(i).col+0;
        xySeriesPub(i+1).row=xySeriesPub(i+1).row+1;
        xySeriesPub(i+1).col=xySeriesPub(i+1).col+0;
        labelMod='C. ';
        
      case 4
        xySeriesPub(i).row=xySeriesPub(i).row+1;
        xySeriesPub(i).col=xySeriesPub(i).col+1;
        xySeriesPub(i+1).row=xySeriesPub(i+1).row+1;
        xySeriesPub(i+1).col=xySeriesPub(i+1).col+1;
        labelMod='D. ';
        
      otherwise
        assert(0,'Error: invalid segment');
    end    
    
    bwAmpFormat = '(%1.1f Hz, %1.3f %s)';
    if(amplitudeTarget > 0.009)
      bwAmpFormat = '(%1.1f Hz, %1.2f %s)';
    end    
    xySeriesPub(i).title = sprintf([labelMod,titleMod{i},' Storage-Length-Relation ',...
                                  bwAmpFormat],...
                                  bandwidthTarget,amplitudeTarget,'$$\ell_o$$');     
    xySeriesPub(i+1).title = sprintf([labelMod,titleMod{i+1},' Loss-Length-Relation ',...
                                  bwAmpFormat],...
                                  bandwidthTarget,amplitudeTarget,'$$\ell_o$$');    


    
  end  





  if(settings.addPlotBoxAndWhiskerGroup==1)

    %Box and whisker plots
    for i=1:1:length(xySeriesPub)
      figure(figHPub);
      subplot('Position',...
        reshape(subPlotPanelZp(xySeriesPub(i).row,...
                               xySeriesPub(i).col,:),1,4));
  
  
      dataSeries(2)=struct('median',[],'all',[]);
      idxLRData=1;
      idxLRForce=2;
      for idxD=1:1:2
        dataSeries(idxD).median=struct('x',[],'y',[]);
        dataSeries(idxD).all=struct('x',[],'y',[]);    
      end
    
      for idxLR=1:1:2
        side='';
        switch idxLR
          case 1
            side ='left';     
          case 2
            side ='right';          
          otherwise
            assert(0,'Error: idxLR must be [1,2]');
        end
    
        %Plot the median line
        dataSeries(idxLR).median=struct('x',[],'y',[]);
        dataSeries(idxLR).all=struct('x',[],'y',[]);    
  
        nPts = zeros(length(expDataSet),1);
        for j=1:1:length(expDataSet)
          %Peek to get the minimum number of points
          nPts(j)=nan;
          if(~isempty(expDataSet(j).(xySeriesPub(i).left.y)) ...
              && ~isempty(expDataSet(j).(xySeriesPub(i).right.y)))
            lengthLeft=length(expDataSet(j).(xySeriesPub(i).left.y));
            lengthRight=length(expDataSet(j).(xySeriesPub(i).right.y));
            if(lengthLeft~=lengthRight)
              here=1;
            end
            assert(lengthLeft==lengthRight);
            
            nPts(j)=min(lengthLeft,lengthRight);
            assert((nPts(j)-lengthLeft)==0);
          end
        end
  
        for j=1:1:length(expDataSet)
  
          if(~isempty(expDataSet(j).(xySeriesPub(i).(side).y)) && ~isnan(nPts(j)))
            dataSeries(idxLR).median.x=[dataSeries(idxLR).median.x;...
                                expDataSet(j).lengthNominal];
      
            yM = median(expDataSet(j).(xySeriesPub(i).(side).y));
            if(isempty(yM))
              yM=nan;
            end
            dataSeries(idxLR).median.y=[dataSeries(idxLR).median.y;...
                                        yM];
      
            if(~isempty(expDataSet(j).(xySeriesPub(i).(side).y)))              
  
              yS=expDataSet(j).(xySeriesPub(i).(side).y)(1:nPts(j));
  
              dataSeries(idxLR).all.x=[dataSeries(idxLR).all.x;...
                    ones(size(yS)).*expDataSet(j).lengthNominal];
              dataSeries(idxLR).all.y=[dataSeries(idxLR).all.y;...
                                       yS];          
            else
              dataSeries(idxLR).all.x=[dataSeries(idxLR).all.x;...
                         ones(nPts(j),1).*expDataSet(j).lengthNominal];
              dataSeries(idxLR).all.y=[dataSeries(idxLR).all.y;...
                         ones(nPts(j),1).*nan];          
  
            end
          elseif (~isnan(nPts(j)))
              dataSeries(idxLR).all.x=[dataSeries(idxLR).all.x;...
                         ones(nPts(j),1).*expDataSet(j).lengthNominal];
              dataSeries(idxLR).all.y=[dataSeries(idxLR).all.y;...
                         ones(nPts(j),1).*nan];          
              dataSeries(idxLR).median.x=[dataSeries(idxLR).median.x;...
                                  expDataSet(j).lengthNominal];
              dataSeries(idxLR).median.y=[dataSeries(idxLR).median.y;...
                                          nan];               
          else
            dataSeries(idxLR).median.x=[dataSeries(idxLR).median.x;...
                                expDataSet(j).lengthNominal];
            dataSeries(idxLR).median.y=[dataSeries(idxLR).median.y;...
                                        nan];          
          end
        end
      end
  
      if(length(dataSeries(1).all.x) ~= length(dataSeries(2).all.x))
        here=1;
      end    
  
      for idxLR=1:1:2
        
        side='';
        addCorrelation=0;
        switch idxLR
          case 1
            side ='left';
            yyaxis left;          
          case 2
            side ='right';          
            yyaxis right;
            addCorrelation=1;
          otherwise
            assert(0,'Error: idxLR must be [1,2]');
        end
        
  
        if(~isempty(dataSeries(idxLR).median.x))
  
          idxV = find(~isnan(dataSeries(idxLR).median.y));
  
          if(~isempty(idxV))
            plot(dataSeries(idxLR).median.x(idxV),...
                 dataSeries(idxLR).median.y(idxV),...
                 '-','Color',xySeriesPub(i).(side).color);
            hold on;
          end
        end
  
        if(addCorrelation==1)
  
          flag_checkScatterPlot=0;
          if(flag_checkScatterPlot==1)
            figScatter=figure;
            plot(dataSeries(1).median.y,dataSeries(2).median.y,'.');
            hold on;
            xlabel('Norm. Storage/Loss');
            ylabel('Norm. Force');
            here=1;
          end
  
          dx = diff(xySeriesPub(i).xLim).*0.05;
          dy = diff(xySeriesPub(i).(side).yLim).*0.05;
          xR = xySeriesPub(i).xTicks(end)-2.675*dx;
          yR = xySeriesPub(i).(side).yLim(end);
  
          if(contains((xySeriesPub(i).(side).y),'Passive'))
            dx = diff(xySeriesPub(i).xLim).*0.05;
            dy = diff(xySeriesPub(i).(side).yLim).*0.05;
            xR = xySeriesPub(i).xLim(1)+0.5*dx;
            yR = xySeriesPub(i).(side).yTicks(end)-6*dy;          
          end
  
          y1 = [];
          y2 = [];
          for idxY=1:1:length(dataSeries(1).median.x)
            if(~isnan(dataSeries(1).median.y(idxY)) ...
                 && ~isnan(dataSeries(2).median.y(idxY)))
              y1=[y1;dataSeries(1).median.y(idxY)];
              y2=[y2;dataSeries(2).median.y(idxY)];
            end
          end
          if(length(y1) > 2)
            [rho,pval] = corr(y1,y2,'Type','Pearson');
            text(xR,yR,...
                 sprintf('%s\n%s=%1.2f\n%s=%1.2e\nn=%i',...
                 '\underline{Corr: median}','$$\rho$$',rho,'$$p$$',pval,length(y1)),...
                 'FontSize',8,...
                 'HorizontalAlignment','left',...
                 'VerticalAlignment','top');
    
            hold on;
            %if(contains(xySeriesPub(i).(side).y,'Passive'))
            %  xR=xR-dx*5;
            %else
            yR=yR-dy*4;
            %end
          end
  
  
          y1All = [];
          y2All = [];
          assert(length(dataSeries(1).all.x) == length(dataSeries(1).all.y));        
          assert(length(dataSeries(1).all.x) == length(dataSeries(2).all.x));
          assert(length(dataSeries(1).all.y) == length(dataSeries(2).all.y));
          
          for idxY=1:1:length(dataSeries(1).all.x)
            if(~isnan(dataSeries(1).all.y(idxY)) ...
                 && ~isnan(dataSeries(2).all.y(idxY)))
              y1All=[y1All;dataSeries(1).all.y(idxY)];
              y2All=[y2All;dataSeries(2).all.y(idxY)];
            end
          end
  
          if(length(y1) > 2)
            [rho,pval] = corr(y1All,y2All,'Type','Pearson');
            text(xR,yR,...
                 sprintf('%s\n%s=%1.2f\n%s=%1.2e\nn=%i',...
                 '\underline{Corr. all}','$$\rho$$',rho,'$$p$$',pval,length(y1All)),...
                 'FontSize',8,...
                 'HorizontalAlignment','left',...
                 'VerticalAlignment','top');  
            hold on;
          end        
  
  
        end
  
        %Add the box and whisker plot
        for j=1:1:length(expDataSet)  
          if(~isempty(expDataSet(j).(xySeriesPub(i).(side).y)))
            lineColor = xySeriesPub(i).(side).color;
            boxColor  = [1,1,1].*0.5 + lineColor.*0.5;
            bwWidth   = 0.05;          
            addBoxWhiskerPlot   = 1;
            switch side
              case 'left'
                bwOffset  = -0.5*bwWidth;
              case 'right'
                bwOffset  = 0.5*bwWidth;
              otherwise
                assert(0,'Error: side must be either left or right');
            end         
    
            if(addBoxWhiskerPlot==1)
  
              summaryStatistics = ...
                getSummaryStatistics(expDataSet(j).(xySeriesPub(i).(side).y));
              plotBoxWhiskerData(expDataSet(j).lengthNominal+bwOffset,...
                                 summaryStatistics,...
                                 bwWidth,lineColor,boxColor);            
              hold on;
              
              xL=expDataSet(j).lengthNominal+bwOffset;
              yL=summaryStatistics.y(1,2);
              text(xL,yL,...
                sprintf('%i',length((expDataSet(j).(xySeriesPub(i).(side).y)))),...
                'VerticalAlignment','top',...
                'HorizontalAlignment','center',...
                'FontSize',6);
              hold on;
  
              if(~isempty(expDataSet(j).(xySeriesPub(i).(side).y)) ...
                 && ~isnan(dataSeries(idxLRForce).median.y(j)))
                if(strcmp(side,'left'))
                  xL=expDataSet(j).lengthNominal+bwOffset;
                  yL=summaryStatistics.y(1,6);              
    
                  [psr,hsr,statssr]=...
                      signrank(expDataSet(j).(xySeriesPub(i).(side).y),...
                               dataSeries(idxLRForce).median.y(j));
                  here=1;
                  if(hsr==1)
  %                   text(xL,yL,...
  %                     sprintf('%1.2e\n*',psr),...
  %                     'VerticalAlignment','bottom',...
  %                     'HorizontalAlignment','center',...
  %                     'FontSize',6);
                    text(xL,yL,'*','VerticalAlignment','bottom',...
                                   'HorizontalAlignment','center',...
                                   'FontSize',8);
                    hold on; 
                  end
                end
              end
            end
          end
        end
        
        dyLegend=0;
        switch idxLR
          case 1
            ax=gca;
            ax.YAxis(idxLR).Color=xySeriesPub(i).(side).color;          
            xlabel(xySeriesPub(i).xLabel);
            xticks(xySeriesPub(i).xTicks);
            xlim(xySeriesPub(i).xLim);
  
            ylabel(xySeriesPub(i).(side).yLabel,...
              'Color',xySeriesPub(i).(side).color);
            yticks(xySeriesPub(i).(side).yTicks);
            ylim(xySeriesPub(i).(side).yLim);
            title(xySeriesPub(i).title);
            dyLegend=0;
          case 2
            ax=gca;
            ax.YAxis(idxLR).Color=xySeriesPub(i).(side).color;            
            ylabel(xySeriesPub(i).(side).yLabel,...
              'Color',xySeriesPub(i).(side).color);
            yticks(xySeriesPub(i).(side).yTicks);
            ylim(xySeriesPub(i).(side).yLim);
            dyLegend=-1;
          otherwise
            assert(0,'Error: idxLR must be [1,2]');
        end
  
        dx = diff(xySeriesPub(i).xLim).*0.05;
        dy = diff(xySeriesPub(i).(side).yLim).*0.05;
        xL = xySeriesPub(i).xLim(1)+0.5*dx;
        yL = xySeriesPub(i).(side).yTicks(end);
        dyLegend = dyLegend*dy;
     
        if(contains(xySeriesPub(i).(side).y,'storage'))    
          xA=xL;
          if(contains(xySeriesPub(i).(side).y,'Passive'))
            yA=xySeriesPub(i).(side).yLim(2)-2*dy;
          else          
            yA=xySeriesPub(i).(side).yLim(1);
          end
          text(xA,yA,sprintf('%s=%1.2f %s [%1.2f,%1.2f]\n%s=%1.2f %s [%1.2f,%1.2f]',...
               '$$S^A_o$$',...
               mean(expDataSet(1).storageAtLo),...
               [forceUnit,'/',lengthUnit],...
               min(expDataSet(1).storageAtLo),...
               max(expDataSet(1).storageAtLo),...
               '$$f_o$$',...
               mean(expDataSet(1).forceAtLo),...
               forceUnit,...
               min(expDataSet(1).forceAtLo),...
               max(expDataSet(1).forceAtLo)),...
               'FontSize',8,...
               'HorizontalAlignment','left',...
               'VerticalAlignment','bottom');
          hold on;
        end
        if(contains(xySeriesPub(i).(side).y,'loss'))           
          xA=xL;
          if(contains(xySeriesPub(i).(side).y,'Passive'))
            yA=xySeriesPub(i).(side).yLim(2)-2*dy;
          else
            yA=xySeriesPub(i).(side).yLim(1);
          end
  
          text(xA,yA,sprintf('%s=%1.2f %s [%1.2f,%1.2f]\n%s=%1.2f %s [%1.2f,%1.2f]',...
               '$$L^A_o$$',...
               mean(expDataSet(1).lossAtLo),...
               [forceUnit,'/',lengthUnit],...
               min(expDataSet(1).lossAtLo),...
               max(expDataSet(1).lossAtLo),...
               '$$f_o$$',...
               mean(expDataSet(1).forceAtLo),...
               forceUnit,...
               min(expDataSet(1).forceAtLo),...
               max(expDataSet(1).forceAtLo)),...
               'FontSize',8,...
               'HorizontalAlignment','left',...
               'VerticalAlignment','bottom');
          hold on;
          
        end      
        
        plot([xL,xL+dx],...
             [yL-3*dy+dyLegend,yL-3*dy+dyLegend],...
             '-','Color',xySeriesPub(i).(side).color);
        hold on;
        text(xL+1.5*dx,yL-3*dy+dyLegend,...
             xySeriesPub(i).(side).legend,...
             'FontSize',8,...
             'HorizontalAlignment','left',...
             'VerticalAlignment','middle');
        hold on;         
        
        box off;
  
  
      end
  
    end
  end

  if(settings.addPlotStorageLossMagnitude==1)
    figure(figHSoLoPub);
    iN = categories.length.indexLopt;
    for idxSL=1:1:length(slSeriesPub)
  
      if(abs(slSeriesPub(idxSL).segment-segId)<1e-6)
        row=slSeriesPub(idxSL).row;
        col=slSeriesPub(idxSL).col;
        
        subplot('Position',reshape(subPlotPanelSoLo(row,col,:),1,4));
    
        
        slSeriesColorLight=slSeriesPub(idxSL).color.*0.5 + [1,1,1].*0.5;
  
        plot(slSeriesPub(idxSL).xValue,...
             expDataSet(iN).(slSeriesPub(idxSL).y),...
             'o','Color',slSeriesPub(idxSL).color,...
             'MarkerFaceColor',slSeriesColorLight);
  
        hold on;
  
        slSeriesPub(idxSL).yData=expDataSet(iN).(slSeriesPub(idxSL).y);
  
  
        bwAmpFormat = '%1.1f Hz %1.3f %s';
        if(amplitudeTarget > 0.009)
          bwAmpFormat = '%1.1f Hz %1.2f %s';
        end
  
        slSeriesPub(idxSL).xTickText = sprintf(bwAmpFormat,...
                                         expDataSet(iN).bandwidthTarget(1),...
                                         expDataSet(iN).amplitudeTarget(1),...
                                         '$$\ell_o$$');
  
        medValue = median(expDataSet(iN).(slSeriesPub(idxSL).y));
        medLineX = [1,1].*slSeriesPub(idxSL).xValue+[-0.25,0.25];
        medLineY = [1,1].*medValue;
        plot(medLineX,medLineY,'-','Color',[1,1,1],'LineWidth',2);
        hold on;
        plot(medLineX,medLineY,'-',...
             'Color',slSeriesPub(idxSL).color,'LineWidth',1);
        hold on;
  
        dy = diff(slSeriesPub(idxSL).yLim)*0.05;
  
        text(slSeriesPub(idxSL).xValue,...
             min(expDataSet(iN).(slSeriesPub(idxSL).y))-dy,...
             sprintf('%i',length(expDataSet(iN).(slSeriesPub(idxSL).y)) ),...
             'VerticalAlignment','top',...
             'HorizontalAlignment','center',...
             'FontSize',8);
        hold on;
  
        box off;
        xlabel(slSeriesPub(idxSL).xLabel);      
        ylabel(slSeriesPub(idxSL).yLabel);
        %xticks(slSeriesPub(idxSL).xTicks);
        %xticklabels(slSeriesPub(idxSL).xTicksText);
        %xtickangle(45);
        yticks(slSeriesPub(idxSL).yTicks);
        xlim(slSeriesPub(idxSL).xLim);
        ylim(slSeriesPub(idxSL).yLim);      
        title(slSeriesPub(idxSL).title);
      end
      
  
  
  
  
    end
  end

end

%
% Update the x-ticks
%
if(settings.addPlotStorageLossMagnitude==1)
  figure(figHSoLoPub);
  xTickTextStorage=[];
  xTickTextLoss=[];
  
  for i=1:1:length(slSeriesPub)
    if(contains(slSeriesPub(i).y,'storage'))
      xTickTextStorage = [xTickTextStorage, {slSeriesPub(i).xTickText}];
    end
    if(contains(slSeriesPub(i).y,'loss'))
      xTickTextLoss = [xTickTextLoss, {slSeriesPub(i).xTickText}];
    end
  end
  
  subplot('Position',reshape(subPlotPanelSoLo(1,1,:),1,4));
    xticks(slSeriesPub(1).xTicks);
    xticklabels(xTickTextStorage);
    xtickangle(45);
  
  subplot('Position',reshape(subPlotPanelSoLo(1,2,:),1,4));
    xticks(slSeriesPub(2).xTicks);
    xticklabels(xTickTextLoss);
    xtickangle(45);
  
  %
  % Add the pair-wise comparisions to the storage and loss modulus
  %
  figure(figHSoLoPub);
  
  
  
  segComparison = [1,2; 3,4; 1,3; 2,4];
  
  for idxC=1:1:length(segComparison)
  
    idxA=segComparison(idxC,1);
    idxB=segComparison(idxC,2);
  
    segSeries=[idxA,idxB];
  
    dataStorage=[];
    dataLoss  = [];
    xStorage=[];
    xLoss =[];
    rcStorage=[];
    rcLoss=[];
  
   
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
  
    yStorage = 30-(idxC-1)*5;
    yLoss    = 5-(idxC-1)*1;
  
    
    subplot('Position',reshape(subPlotPanelSoLo(rcStorage(1),rcStorage(2),:),1,4));
    [pS,hS,statS]=ranksum(dataStorage(:,1),dataStorage(:,2));
    if(hS==1)
      xS=sort(xStorage);
      xS=[xS(1),xS(1),xS(2),xS(2)];
      yS=[1,1,1,1].*yStorage + [1,0,0,1].*dyS;
      plot(xS,yS,'-k');
      hold on;
      text(mean(xStorage),yStorage(1),...
           sprintf('*\n%1.2e',pS),...
           'HorizontalAlignment','center',...
           'VerticalAlignment','middle');
      hold on;
    end
    subplot('Position',reshape(subPlotPanelSoLo(rcLoss(1),rcLoss(2),:),1,4));
    [pL,hL,statL]=ranksum(dataLoss(:,1),dataLoss(:,2));
    if(hL==1)
      xL=sort(xLoss);
      xL=[xL(1),xL(1),xL(2),xL(2)];
      yL=[1,1,1,1].*yLoss + [1,0,0,1].*dyL;    
      plot(xL,yL,'-k');
      hold on;
      text(mean(xLoss),yLoss(1),...
           sprintf('*\n%1.2e',pL),...
           'HorizontalAlignment','center',...
           'VerticalAlignment','middle');
      hold on;
    end
    
  end
end


%
% Plot the frequency-response-length data
%
if(settings.addPlotFrequencResponseGroup==1)
  numberOfHorizontalPlotColumnsGeneric  = 3;
  numberOfVerticalPlotRowsGeneric       = 2;
    
  plotWidth                 = ones(1,numberOfHorizontalPlotColumnsGeneric).*7;
  plotHeight                = ones(numberOfVerticalPlotRowsGeneric,1).*7;
  plotHorizMarginCm         = 2;
  plotVertMarginCm          = 2;
  baseFontSize              = 8;

  [subPlotPanelFR, pageWidthFR,pageHeightFR]= ...
    plotConfigGeneric(  numberOfHorizontalPlotColumnsGeneric,...
                        numberOfVerticalPlotRowsGeneric,...
                        plotWidth,...
                        plotHeight,...
                        plotHorizMarginCm,...
                        plotVertMarginCm,...
                        baseFontSize); 

  figure(figFRPub);

  idxLSeries=[1,4,7];
  segSeries = [2,1;4,3];

  plotLabels = {'A.','B.','C.';'D.','E.','F.'};

  storageColorSeries=[cs.red; cs.magenta];                
  lossColorSeries   =[cs.blue; cs.teal];     
        
  for idxSegRow = 1:1:size(segSeries,1)
    for idxSegCol = 1:1:size(segSeries,2)
      segId=segSeries(idxSegRow,idxSegCol);
      nSegId=(segId-1)/(length(segmentSeries)-1);
      storageColor = storageColorSeries(1,:).*nSegId...
                    +storageColorSeries(1,:).*(1-nSegId);
      lossColor = lossColorSeries(1,:).*nSegId...
                 +lossColorSeries(1,:).*(1-nSegId);
      
      for idxLCol=1:1:length(idxLSeries)        

        idxL=idxLSeries(idxLCol);
        subplot('Position',reshape(subPlotPanelFR(idxSegRow,idxLCol,:),1,4));
        
        %Get the min. and max index at which all rows have data
        %Note: storage and loss fields will have identical valid bandwidths
        idxExpV = [];
        for idxExp=1:1:size(setFRSeries(segId).frSeries(idxL).storageActive,2)
          entryCount= ...
            sum(~isnan(setFRSeries(segId).frSeries(idxL).storageActive(:,idxExp)));
          if entryCount > 10
            idxExpV=[idxExpV,idxExp];
          else
            here=1;
          end

        end


        idxMin = 1;
        idxMax = length(setFRSeries(segId).frSeries(idxL).frequencyHz);
        found=0;
        while idxMin < idxMax && found==0
          nanCount=sum(isnan(setFRSeries(segId).frSeries(idxL).storageActive(idxMin,idxExpV)));
          if(nanCount==0)
            found=1;
          else
            idxMin=idxMin+1;
          end
        end
        if(idxMin == idxMax)
          break;
        end
        found=0;
        while idxMax > idxMin && found==0
          nanCount=sum(isnan(setFRSeries(segId).frSeries(idxL).storageActive(idxMax,idxExpV)));
          if(nanCount==0)
            found=1;
          else
            idxMax=idxMax-1;
          end
        end
        if(idxMin == idxMax)
          break;
        end

        idxV = [idxMin:idxMax];
        %Plot envelope as a fill
        %Add white lines for each trial series
        %Plot the mean curve
        storageFillColor=storageColor.*0.5 + [1,1,1].*0.5;
        lossFillColor = lossColor.*0.5 +[1,1,1].*0.5;

        lineColor=[storageColor;lossColor];
        fillColor=[storageFillColor;lossFillColor];

        fieldsToPlot = {'storageActive','lossActive'};
        for idxF=1:1:length(fieldsToPlot)
          if(idxF==1)
            yyaxis left;
          else
            yyaxis right
          end

          fieldName=fieldsToPlot{idxF};
          dataSeries=setFRSeries(segId).frSeries(idxL).(fieldName)(idxV,idxExpV);
          for idxExp=1:1:size(dataSeries,2)
            normFactor = setFRSeries(segId).frSeries(idxL).forceAtLo ...
                        /setFRSeries(segId).frSeries(idxL).lengthAtLo;
            dataSeries(:,idxExp)=dataSeries(:,idxExp)./normFactor;
          end
          dataMax  = max(dataSeries,[],2);
          dataMin  = min(dataSeries,[],2);
          dataMean = mean(dataSeries,2);
          
          freqHz = setFRSeries(segId).frSeries(idxL).frequencyHz(idxV);



          
          if(idxSegCol==1)
            fill([freqHz; fliplr(freqHz')'],...
                 [dataMin; fliplr(dataMax')'],...
                 fillColor(idxF,:),'EdgeColor','none');
            hold on;
            text(freqHz(end),dataMax(end),...
                 sprintf('n=%i',length(idxExpV)),...
                 'VerticalAlignment','bottom',...
                 'HorizontalAlignment','right',...
                 'FontSize',8,...
                 'Color',lineColor(idxF,:));
            hold on;
            for idxE=1:1:length(idxExpV)
              plot(freqHz,...
                   setFRSeries(segId).frSeries(idxL).(fieldName)(idxV,idxExpV(idxE)),...
                   '-','Color',[1,1,1],'LineWidth',0.5);
              hold on;
            end            
            plot(freqHz, dataMean, '-','Color',lineColor(idxF,:),...
                 'LineWidth',1);
            hold on;
            box off
          else
            fill([freqHz; fliplr(freqHz')'],...
                 [dataMin; fliplr(dataMax')'],...
                 [1,1,1],'EdgeColor',lineColor(idxF,:),...
                 'FaceAlpha',0.5,'LineStyle','-','LineWidth',1);
            hold on;
            text(freqHz(end),dataMax(end),...
                 sprintf('n=%i',length(idxExpV)),...
                 'VerticalAlignment','bottom',...
                 'HorizontalAlignment','right',...
                 'FontSize',8,...
                 'Color',lineColor(idxF,:));
            hold on;            
            for idxE=1:1:length(idxExpV)
              plot(freqHz,...
                   setFRSeries(segId).frSeries(idxL).(fieldName)(idxV,idxExpV(idxE)),...
                   '-','Color',[1,1,1],'LineWidth',0.5);
              hold on;
            end                        
            plot(freqHz, dataMean, '-','Color',lineColor(idxF,:),...
                 'LineWidth',1);
            hold on;
            box off

          end

          xlabel('Frequency (Hz)');
          xticks([0:10:90]);
          xlim([-0.01,90.01]);
          yticks([0:20:120]);
          ylim([-0.01,120.01]);

          if(idxF==1)
            ylabel(sprintf('Norm. Storage Modulus (%s/%s)/(%s)',...
                           forceUnit,lengthUnit,'$$f_o/\ell_o$$'));
          else
            ylabel(sprintf('Norm. Loss Modulus (%s/%s)/(%s)',...
                           forceUnit,lengthUnit,'$$f_o/\ell_o$$'));
          end
          amplitude = setFRSeries(segId).frSeries(idxL).amplitudeLo;
          ampFormat='%1.3f';
          if(amplitude > 0.009)
           ampFormat='%1.2f';            
          end

          plotLabel=plotLabels{idxSegRow,idxLCol};

          title(sprintf([plotLabel,' Response at %1.2f %s to ',ampFormat,' %s Perturbation (n=%i)'],...
                setFRSeries(segId).frSeries(idxL).lengthNominal(1),...
                '$$\ell_o$$',...
                setFRSeries(segId).frSeries(idxL).amplitudeLo(1),...
                '$$\ell_o$$',length(idxExpV)));


        end
        ax=gca;
        ax.YAxis(1).Color=lineColor(1,:);
        ax.YAxis(2).Color=lineColor(2,:);        
      end
    end
  end
end

%
% Save the plots
%
if(settings.savePlots==1)
  outputPlotDir = fullfile(projectFolders.output600A_plots,...
                           'impedance_length_relation_larb');

  %
  % Frequency Response
  %
  if(settings.addPlotFrequencResponseGroup==1)
    figFRPub=configPlotExporter(figFRPub, ...
                                 pageWidthFR, pageHeightFR);
    fileName =  ['fig_frequency_response',appendToFileName];
  
    switch settings.flag_0Presentation_1Publication
      case 0
        fileName =  [fileName,'_pres'];
      case 1
        fileName =  [fileName,'_pub'];      
      otherwise
        assert(0,'Error: settings.flag_0Presentation_1Publication should be 0 or 1');      
    end
    figure(figFRPub);
    print('-dpdf',fullfile(outputPlotDir,[fileName,'.pdf']));  
    saveas(figFRPub,fullfile(outputPlotDir,[fileName,'.fig']));  

  end

  %
  % Individual plots
  %
  if(settings.addPlotBoxAndWhiskerIndividual==1)
    figHindiv=configPlotExporter(figHindiv, ...
                                 pageWidthZi, pageHeightZi);
    fileName =  ['fig_impedance_length_individual',appendToFileName];
  
    switch settings.flag_0Presentation_1Publication
      case 0
        fileName =  [fileName,'_pres'];
      case 1
        fileName =  [fileName,'_pub'];      
      otherwise
        assert(0,'Error: settings.flag_0Presentation_1Publication should be 0 or 1');      
    end
    figure(figHindiv);
    print('-dpdf',fullfile(outputPlotDir,[fileName,'.pdf']));  
    saveas(figHindiv,fullfile(outputPlotDir,[fileName,'.fig']));  
  end

  %
  % Pub plots
  %
  if(settings.addPlotBoxAndWhiskerGroup==1)
    figHPub=configPlotExporter(figHPub, ...
              pageWidthZp, pageHeightZp);
    fileName =  ['fig_impedance_length_split',appendToFileName];
  
    switch settings.flag_0Presentation_1Publication
      case 0
        fileName =  [fileName,'_pres'];
      case 1
        fileName =  [fileName,'_pub'];      
      otherwise
        assert(0,'Error: settings.flag_0Presentation_1Publication should be 0 or 1');      
    end
  
    figure(figHPub);
    print('-dpdf',fullfile(outputPlotDir,[fileName,'.pdf']));  
    saveas(figH,fullfile(outputPlotDir,[fileName,'.fig']));  
  end
  %
  % Pub So and Lo plots
  %
  if(settings.addPlotStorageLossMagnitude==1)
    figHSoLoPub = configPlotExporter(figHSoLoPub, ...
                    pageWidthSoLo, pageHeightSoLo);
    fileName =  ['fig_SoLo',appendToFileName];
  
    switch settings.flag_0Presentation_1Publication
      case 0
        fileName =  [fileName,'_pres'];
      case 1
        fileName =  [fileName,'_pub'];      
      otherwise
        assert(0,'Error: settings.flag_0Presentation_1Publication should be 0 or 1');      
    end
  
    figure(figHSoLoPub);
    print('-dpdf',fullfile(outputPlotDir,[fileName,'.pdf']));  
    saveas(figHSoLoPub,fullfile(outputPlotDir,[fileName,'.fig']));    
  end
end