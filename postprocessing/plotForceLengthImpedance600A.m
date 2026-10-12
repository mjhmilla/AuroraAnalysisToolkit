function [figH,figHindiv,figHPub] = ...
            plotForceLengthImpedance600A(...
                              figH,...
                              figHindiv,...
                              figHPub,...
                              experimentList, ...
                              segmentSeries,...
                              categories, ...
                              modeNormalization,...
                              projectFolders,... 
                              appendToFileName,...
                              flag_0Presentation_1Publication,...
                              flag_savePlot)


numberOfHorizontalPlotColumnsGeneric  = 3;
numberOfVerticalPlotRowsGeneric       = length(segmentSeries);
nominalForceWindowInMs = 100;

forceUnit='mN';
lengthUnit='mm';
timeUnit='ms';

cs=getPaulTolColourSchemes('vibrant');

switch flag_0Presentation_1Publication
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
    assert(0,'Error: flag_0Presentation_1Publication should be 0 or 1');
end

[subPlotPanelZi, pageWidthZi,pageHeightZi]= ...
  plotConfigGeneric(  numberOfHorizontalPlotColumnsGeneric,...
                      numberOfVerticalPlotRowsGeneric,...
                      plotWidth,...
                      plotHeight,...
                      plotHorizMarginCm,...
                      plotVertMarginCm,...
                      baseFontSize); 

subPlotPanelZg = subPlotPanelZi;
pageWidthZg    = pageWidthZi;
pageHeightZg   = pageHeightZi;

numberOfHorizontalPlotColumnsGeneric  = 6;
numberOfVerticalPlotRowsGeneric       = 4;
nominalForceWindowInMs = 100;

switch flag_0Presentation_1Publication
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
    assert(0,'Error: flag_0Presentation_1Publication should be 0 or 1');
end

[subPlotPanelZp, pageWidthZp,pageHeightZp]= ...
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
fieldsToPlot = {'storageActive','lossActive'};
  
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
  xySeries(idx).xLabel = 'Norm. Length ($$\ell/\ell_o^M$$)';
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
  xySeries(idx).xLabel = 'Norm. Length ($$\ell/\ell_o^M$$)';
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
  xySeries(idx).xLabel = 'Norm. Length ($$\ell/\ell_o^M$$)';
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
  %
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
                             max(categories.length.value)] + [-1,1].*0.1;
  xySeriesPub(idx).xLabel = 'Norm. Length ($$\ell/\ell_o^M$$)';

  xySeriesPub(idx).left.y      = 'storage';
  xySeriesPub(idx).left.yTicks = [0:0.2:1.8];
  xySeriesPub(idx).left.yLim   = [0,1.8] + [-1,1].*sqrt(eps);
  xySeriesPub(idx).left.yLabel = 'Norm. Storage ($$(\mathrm{mN}/\mathrm{mm})/(S_o^M)$$)';
  xySeriesPub(idx).left.color  = cs.magenta;
  xySeriesPub(idx).left.legend = '$$\tilde{S}^A + \tilde{S}^P$$';
  
  xySeriesPub(idx).right.y      = 'force';
  xySeriesPub(idx).right.yTicks = [0:0.2:1.8];
  xySeriesPub(idx).right.yLim   = [0,1.8] + [-1,1].*sqrt(eps);
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
  xySeriesPub(idx).left.yTicks = [0:0.2:1.8];
  xySeriesPub(idx).left.yLim   = [0,1.8] + [-1,1].*sqrt(eps);
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
  xySeriesPub(idx).left.yLim   = [0,0.6] + [-1,1].*sqrt(eps);
  xySeriesPub(idx).right.yTicks = [0:0.1:0.6];
  xySeriesPub(idx).right.yLim   = [0,0.6] + [-1,1].*sqrt(eps);
 
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

  xySeriesPub(idx).left.yTicks = [0:0.1:0.6];
  xySeriesPub(idx).left.yLim   = [0,0.6] + [-1,1].*sqrt(eps);
  xySeriesPub(idx).right.yTicks = [0:0.1:0.6];
  xySeriesPub(idx).right.yLim   = [0,0.6] + [-1,1].*sqrt(eps);
  
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
                   'meanForce',[],...
                   'meanForceActive',[],...
                   'meanForcePassive',[],...
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
                   'lossPassive',[]);
  
  for i=1:1:length(categories.length.value)
    expDataSet(i) = struct('lengthNominal',categories.length.value(i),...
                           'forceAtLo',[],...
                           'storageAtLo',[],...
                           'lossAtLo',[],...                            
                           'meanForce',[],...
                           'meanForceActive',[],...
                           'meanForcePassive',[],...
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
                           'lossPassive',[]);
  end
  
  for idxExp = 1:1:length(experimentList)
  
    trialList = dir(fullfile(projectFolders.output600A_json,...
                      experimentList{idxExp}));
  
  
    trialDataSet(length(categories.length.value)) ...
              = struct('lengthNominal',nan,...
                       'forceAtLo',[],...
                       'storageAtLo',[],...
                       'lossAtLo',[],...              
                       'meanForce',[],...
                       'meanForceActive',nan,...
                       'meanForcePassive',[],...
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
                       'lossPassive',[]);  
    
    for i=1:1:length(categories.length.value)
      trialDataSet(i) = ...
            struct('lengthNominal',categories.length.value(i),...
                   'forceAtLo',[],...
                   'storageAtLo',[],...
                   'lossAtLo',[],...            
                   'meanForce',nan,...
                   'meanForceActive',nan,...
                   'meanForcePassive',[],...
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
                   'lossPassive',[]);  
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
                        ' at segment %i which is (%1.2f Hz, %1.4f Lo) \n'],...
                        relErrorType{idxErr},segId,bandwidthHz,amplitudeLo);
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
          tB = aJsonData(1).segment.pre.filter.time(end);
          idxB = length(aJsonData(1).segment.pre.filter.time);
          assert(strcmp(aJsonData(1).segment.unit.time,'ms'));
          idxA=find(aJsonData(1).segment.pre.filter.time ...
                   > tB-nominalForceWindowInMs,1,'first');
          
  
          trialDataSet(idxL).lengthNominal=categories.length.value(idxL); 
  
          trialDataSet(idxL).meanForce=...
            mean(aJsonData(segId).segment.pre.filter.force(idxA:idxB));
  
          trialDataSet(idxL).meanForceActive=...
            trialDataSet(idxL).meanForce;  
  
          trialDataSet(idxL).meanForcePassive=[];
  
          if(~isempty(pJsonData(segId).segment.force))
            idxB = length(pJsonData(segId).segment.pre.filter.time);
            tB   = pJsonData(segId).segment.pre.filter.time(end);
            assert(strcmp(aJsonData(segId).segment.unit.time,'ms'));          
            idxA = find(pJsonData(segId).segment.pre.filter.time ...
                      > (tB-nominalForceWindowInMs),1,'first');
    
            trialDataSet(idxL).meanForcePassive=...
              mean(pJsonData(segId).segment.pre.filter.force(idxA:idxB));
            trialDataSet(idxL).meanForceActive=...
              trialDataSet(idxL).meanForceActive ...
              -trialDataSet(idxL).meanForcePassive;
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
      assert(~isnan(trialDataSet(idxC).meanForce));
    end
  
    %Adjust the passive forces so that 0.55 Lo is zero, and then
    %evaluate the nominal active force
    %
    % No longer necessary: this is done when processing the data.
    %
  %   for idxC=1:1:length(trialDataSet)
  %     trialDataSet(idxC).meanForcePassive= ...
  %       trialDataSet(idxC).meanForcePassive ...
  %       -trialDataSet(1).meanForcePassive;
  %     trialDataSet(idxC).meanForceActive = ...
  %       trialDataSet(idxC).meanForce ...
  %       -trialDataSet(idxC).meanForcePassive;
  %   end
  
    %Normalize the data
    normTrialDataSet(length(categories.length.value)) ...
              = struct('lengthNominal',[],...  
                       'forceAtLo',[],...
                       'storageAtLo',[],...
                       'lossAtLo',[],...
                       'meanForce',[],...
                       'meanForceActive',[],...
                       'meanForcePassive',[],...
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
                       'lossPassive',[]);  
    
    iN = categories.length.indexLopt;
  
    for i=1:1:length(trialDataSet)

      isStorageLossDataValid=0;
      if(~isempty(trialDataSet(iN).loss) ...
          && ~isempty(trialDataSet(iN).storage))
        isStorageLossDataValid=1;
      end

      if(isStorageLossDataValid==1)
        normTrialDataSet(i).lengthNominal=trialDataSet(i).lengthNominal;
    
        lopt = trialDataSet(iN).lengthNominal;
        fiso = trialDataSet(iN).meanForceActive;
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
      
        normTrialDataSet(i).forceAtLo=fiso;
        normTrialDataSet(i).storageAtLo=median(trialDataSet(iN).storageActive);
        normTrialDataSet(i).lossAtLo=median(trialDataSet(iN).lossActive);
    
        normTrialDataSet(i).meanForceActive = ...
          trialDataSet(i).meanForceActive / fiso;
        normTrialDataSet(i).meanForce = ...
          trialDataSet(i).meanForce / fiso;
        normTrialDataSet(i).meanForcePassive = ...
          trialDataSet(i).meanForcePassive / fiso;
        
        normTrialDataSet(i).length = ...
          trialDataSet(i).length ./ lopt;
        normTrialDataSet(i).lengthActive = ...
          trialDataSet(i).lengthActive ./ lopt;
        normTrialDataSet(i).lengthPassive = ...
          trialDataSet(i).lengthPassive ./ lopt;

        normTrialDataSet(i).force = ...
          trialDataSet(i).force ./ fiso;
        normTrialDataSet(i).forceActive = ...
          trialDataSet(i).forceActive ./ fiso;
        normTrialDataSet(i).forcePassive = ...
          trialDataSet(i).forcePassive ./ fiso;        

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
    for i=1:2:(length(xySeries)-2)

      xySeries(i).row   = indexSegment;
      xySeries(i).title = sprintf(['Storage-Length-Relation',...
                                    ' (%1.1f Hz, %1.4f Lo)'],...
                                    bandwidthHz,amplitudeLo);   
      xySeries(i+1).row   = indexSegment;
      xySeries(i+1).title = sprintf(['Loss-Length-Relation',...
                                    ' (%1.1f Hz, %1.4f Lo)'],...
                                    bandwidthHz,amplitudeLo);
    end
    i=length(xySeries)-1;
    xySeries(i).row   = indexSegment;
    xySeries(i).title = sprintf(['Force-Length-Relation',...
                                  ' (%1.1f Hz, %1.4f Lo)'],...
                                  bandwidthHz,amplitudeLo);   
    xySeries(i+1).row   = indexSegment;
    xySeries(i+1).title = sprintf(['Force-Length-Relation',...
                                  ' (%1.1f Hz, %1.4f Lo)'],...
                                  bandwidthHz,amplitudeLo);    

    n=0;
    if(length(experimentList)>1)
      n = (idxExp-1)/(length(experimentList)-1);
    end
    expColor = ([1,1,1].*0.5).*n + [0,0,0].*(1-n);
    pColor =    [0.5,0.5,1].*n + [0,0,1].*(1-n);
    nColor =    expColor;
    aColor =    [1,0.5,0.5].*n + [1,0,0].*(1-n);
    
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
        aData.l=[aData.l,normTrialDataSet(j).lengthNominal];
        aData.f = [aData.f,mean(normTrialDataSet(j).meanForceActive)];
    
        nData.l=[nData.l,normTrialDataSet(j).lengthNominal];
        nData.f = [nData.f,mean(normTrialDataSet(j).meanForce)];
        
        pTmp = normTrialDataSet(j).meanForcePassive;
        %idxP = find(pTmp >=0);
        %if(~isempty(idxP))
          pData.f = [pData.f,mean(pTmp)];
          pData.l = [pData.l,normTrialDataSet(j).lengthNominal];
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
        text(0.7,0.1,'$$f^L(\ell^M)$$','HorizontalAlignment','right',...
                     'FontSize',6);
        hold on;
        text(1.25,0.1,'$$f^{P}(\ell^M)$$','HorizontalAlignment','right',...
                     'FontSize',6);
        hold on;
        
      end
      box off;
      here=1;
    end

    %
    % Accumulate this into the experiment data set
    %
    fieldsToAccmulate = ...
      {'meanForce','meanForceActive','meanForcePassive',....
       'length','force',...
       'lengthActive','forceActive',...
       'lengthPassive','forcePassive',...
       'storage','loss',...
       'storageActive','lossActive',...
       'storagePassive','lossPassive',...
       'forceAtLo','storageAtLo','lossAtLo'};
    
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
  for i=1:2:length(xySeries)
    xySeries(i).row   = indexSegment;
    xySeries(i).title = sprintf(['Storage-Length-Relation',...
                                  ' (%1.1f Hz, %1.4f Lo)'],...
                                  bandwidthHz,amplitudeLo);      
    xySeries(i+1).row   = indexSegment;
    xySeries(i+1).title = sprintf(['Loss-Length-Relation',...
                                  ' (%1.1f Hz, %1.4f Lo)'],...
                                  bandwidthHz,amplitudeLo);
  end  
  
  
  for i=1:1:length(xySeries)
    figure(figH);
    subplot('Position',reshape(subPlotPanelZg(xySeries(i).row,xySeries(i).col,:),1,4));
    
    %Plot the force-length relation in the background


    nData.l=[];
    nData.fmin=[];
    nData.fmax=[];
    nData.fmed=[];
    nData.fmean=[];



    aData.l=[];
    aData.fmin=[];  
    aData.fmax=[];  
    aData.fmed=[];  
    aData.fmean=[];  
    

    pData.l=[];
    pData.fmin=[];  
    pData.fmax=[];  
    pData.fmed=[];  
    pData.fmean=[];  

    for j=1:1:length(expDataSet)
      aData.l=[aData.l,expDataSet(j).lengthNominal];
      aData.fmin = [aData.fmin, min(expDataSet(j).meanForceActive)];
      aData.fmax = [aData.fmax, max(expDataSet(j).meanForceActive)];
      aData.fmean= [aData.fmean,mean(expDataSet(j).meanForceActive)];
      aData.fmed = [aData.fmed, median(expDataSet(j).meanForceActive)];
  
      nData.l=[nData.l,expDataSet(j).lengthNominal];
      nData.fmin = [nData.fmin, min(expDataSet(j).meanForce)];
      nData.fmax = [nData.fmax,  max(expDataSet(j).meanForce)];
      nData.fmean= [nData.fmean,mean(expDataSet(j).meanForce)];
      nData.fmed = [nData.fmed, median(expDataSet(j).meanForce)];
      
      if(~isempty(expDataSet(j).meanForcePassive))        
        pData.l    = [pData.l,expDataSet(j).lengthNominal];
        pData.fmax = [pData.fmax, max(expDataSet(j).meanForcePassive)];
        pData.fmin = [pData.fmin, min(expDataSet(j).meanForcePassive)];
        pData.fmean= [pData.fmean,mean(expDataSet(j).meanForcePassive)];
        pData.fmed = [pData.fmed, median(expDataSet(j).meanForcePassive)];
      end
    end
  
    if(i==1 || i==2)
      yMax = median(expDataSet(categories.length.indexLopt).(xySeries(i).y));
      fill([aData.l, fliplr(aData.l)],...
           [aData.fmin,fliplr(aData.fmax)].*yMax,...
           [1,0.75,0.75],'EdgeColor','none','FaceAlpha',0.5);
      hold on;
      fill([pData.l, fliplr(pData.l)],...
           [pData.fmin,fliplr(pData.fmax)].*yMax,...
           [0.75,0.75,1],'EdgeColor','none','FaceAlpha',0.5);
      hold on;
      fill([nData.l, fliplr(nData.l)],...
           [nData.fmin,fliplr(nData.fmax)].*yMax,...
           [1,1,1].*0.75,'EdgeColor','none','FaceAlpha',0.5);
      hold on;

      plot(nData.l,nData.fmean.*yMax,'--','Color',[0,0,0]);
      hold on;      
      plot(aData.l,aData.fmean.*yMax,'--','Color',[1,0,0]);
      hold on;      
      plot(pData.l,pData.fmean.*yMax,'--','Color',[0,0,1]);
      hold on;      
      
      %fill([min(aData.l),max(aData.l),fliplr(aData.l)],...
      %      [0,0,fliplr(aData.f)].*yMax, [1,1,1].*0.9,'EdgeColor','none');
      %hold on;
      %fill([min(pData.l),max(pData.l),fliplr(pData.l)],...
      %      [0,0,fliplr(pData.f)].*yMax, [1,1,1].*0.7,'EdgeColor','none');
      %hold on;
      %plot(nData.l,nData.f.*yMax,'-','Color',[1,1,1].*0.8,'LineWidth',1);
      %hold on;
    end
  
  
    %Plot the stiffness / loss data
    for j=1:1:length(expDataSet)
  
      if(~isempty(expDataSet(j).(xySeries(i).y)))
        lineColor = xySeries(i).color;
        boxColor  = [1,1,1].*0.5 + lineColor.*0.5;
        bwWidth = 0.025;
        bwOffset=bwWidth;
        addPlot = 1;
        if(contains((xySeries(i).y),'Active'))
          bwOffset=0;
          %Check if there is passive data at this length, otherwise
          %do not add the active trial
          passiveTrialName=xySeries(i).y;
          i0=strfind(passiveTrialName,'Active');
          passiveTrialName = [passiveTrialName(1:(i0-1)),'Passive' ];
          if(~isempty(expDataSet(j).(passiveTrialName)))
            addPlot=1;
          else
            addPlot=0;
          end
        end
        if(contains((xySeries(i).y),'Passive'))
          bwOffset=-bwWidth;
        end

        if(addPlot==1)
          summaryStatistics = getSummaryStatistics(expDataSet(j).(xySeries(i).y));
          plotBoxWhiskerData(expDataSet(j).lengthNominal+bwOffset,...
                             summaryStatistics,...
                             bwWidth,lineColor,boxColor);
        end
      end
  
    end
    xlabel(xySeries(i).xLabel);
    ylabel(xySeries(i).yLabel);
    title(xySeries(i).title);
    ylim(xySeries(i).yLim);
    xlim(xySeries(i).xLim);
    xticks(xySeries(i).xTicks);
    yticks(xySeries(i).yTicks);  
    if(i==1)
      text(0.7,0.1,'$$f^L(\ell^M)$$','HorizontalAlignment','right',...
                   'FontSize',6);
      hold on;
      text(1.25,0.1,'$$f^{P}(\ell^M)$$','HorizontalAlignment','right',...
                   'FontSize',6);
      hold on;
      
    end
    box off;
    here=1;
  end

  %%
  % Update the plotting struct
  %%
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
    xySeriesPub(i).title = sprintf([labelMod,titleMod{i},' Storage-Length-Relation',...
                                  ' (%1.1f Hz, %1.4f Lo)'],...
                                  bandwidthHz,amplitudeLo);     
    xySeriesPub(i+1).title = sprintf([labelMod,titleMod{i+1},' Loss-Length-Relation',...
                                  ' (%1.1f Hz, %1.4f Lo)'],...
                                  bandwidthHz,amplitudeLo);    


    
  end  








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
          nPts(j)=min(lengthLeft,lengthRight);
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
    
          yS=expDataSet(j).(xySeriesPub(i).(side).y);
          if(~isempty(yS))          

            ySort=sort(yS);
            idxY = [1:1:length(ySort)]';
            idxInterpY = [1:1:nPts(j)]' .*(max(idxY)/nPts(j));
            yInterp = interp1(idxY,ySort,idxInterpY);
    
            dataSeries(idxLR).all.x=[dataSeries(idxLR).all.x;...
                  ones(size(yInterp)).*expDataSet(j).lengthNominal];
            dataSeries(idxLR).all.y=[dataSeries(idxLR).all.y;...
                                     yInterp];          
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
        xR = xySeriesPub(i).xTicks(end)-3*dx;
        yR = xySeriesPub(i).(side).yTicks(end);


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
               'Corr: med.','$$\rho$$',rho,'$$p$$',pval,length(y1)),...
               'FontSize',8,...
               'HorizontalAlignment','left',...
               'VerticalAlignment','top');
  
          hold on;
          %xR=xR-dx*4;
          yR=yR-dy*4;
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
               'Corr. all','$$\rho$$',rho,'$$p$$',pval,length(y1All)),...
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
                  text(xL,yL,...
                    sprintf('%1.2e',psr),...
                    'VerticalAlignment','bottom',...
                    'HorizontalAlignment','center',...
                    'FontSize',6);
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
        yA=yL-dy;
        text(xA,yA,sprintf('%s=%1.2f %s [%1.2f,%1.2f]\n%s=%1.2f %s [%1.2f,%1.2f]',...
             '$$S^A_o$$',...
             mean(expDataSet(1).storageAtLo),...
             [forceUnit,'/',lengthUnit],...
             min(expDataSet(1).storageAtLo),...
             max(expDataSet(1).storageAtLo),...
             '$$f^M_o$$',...
             mean(expDataSet(1).forceAtLo),...
             forceUnit,...
             min(expDataSet(1).forceAtLo),...
             max(expDataSet(1).forceAtLo)),...
             'FontSize',8,...
             'HorizontalAlignment','left',...
             'VerticalAlignment','middle');
        hold on;
      end
      if(contains(xySeriesPub(i).(side).y,'loss'))           
        xA=xL;
        yA=yL-dy;
        text(xA,yA,sprintf('%s=%1.2f %s [%1.2f,%1.2f]\n%s=%1.2f %s [%1.2f,%1.2f]',...
             '$$L^A_o$$',...
             mean(expDataSet(1).lossAtLo),...
             [forceUnit,'/',lengthUnit],...
             min(expDataSet(1).lossAtLo),...
             max(expDataSet(1).lossAtLo),...
             '$$f^M_o$$',...
             mean(expDataSet(1).forceAtLo),...
             forceUnit,...
             min(expDataSet(1).forceAtLo),...
             max(expDataSet(1).forceAtLo)),...
             'FontSize',8,...
             'HorizontalAlignment','left',...
             'VerticalAlignment','middle');
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
  here=1;


end






if(flag_savePlot==1)
  outputPlotDir = fullfile(projectFolders.output600A_plots,...
                           'impedance_length_relation_larb');
  %
  % Individual plots
  %
  figHindiv=configPlotExporter(figHindiv, ...
                               pageWidthZi, pageHeightZi);
  fileName =  ['fig_impedance_length_individual',appendToFileName];

  switch flag_0Presentation_1Publication
    case 0
      fileName =  [fileName,'_pres'];
    case 1
      fileName =  [fileName,'_pub'];      
    otherwise
      assert(0,'Error: flag_0Presentation_1Publication should be 0 or 1');      
  end
  figure(figHindiv);
  print('-dpdf',fullfile(outputPlotDir,[fileName,'.pdf']));  
  saveas(figHindiv,fullfile(outputPlotDir,[fileName,'.fig']));  
  
  %
  % Group plots
  %

  figH=configPlotExporter(figH, ...
            pageWidthZi, pageHeightZi);
  fileName =  ['fig_impedance_length',appendToFileName];

  switch flag_0Presentation_1Publication
    case 0
      fileName =  [fileName,'_pres'];
    case 1
      fileName =  [fileName,'_pub'];      
    otherwise
      assert(0,'Error: flag_0Presentation_1Publication should be 0 or 1');      
  end

  figure(figH);
  print('-dpdf',fullfile(outputPlotDir,[fileName,'.pdf']));  
  saveas(figH,fullfile(outputPlotDir,[fileName,'.fig']));  

  %
  % Pub plots
  %
  figHPub=configPlotExporter(figHPub, ...
            pageWidthZp, pageHeightZp);
  fileName =  ['fig_impedance_length_split',appendToFileName];

  switch flag_0Presentation_1Publication
    case 0
      fileName =  [fileName,'_pres'];
    case 1
      fileName =  [fileName,'_pub'];      
    otherwise
      assert(0,'Error: flag_0Presentation_1Publication should be 0 or 1');      
  end

  figure(figHPub);
  print('-dpdf',fullfile(outputPlotDir,[fileName,'.pdf']));  
  saveas(figH,fullfile(outputPlotDir,[fileName,'.fig']));  

end