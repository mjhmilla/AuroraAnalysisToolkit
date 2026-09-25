function figH = plotForceLengthImpedance600A(...
                      figH,...
                      experimentList, ...
                      segmentSeries,...
                      categories, ...
                      modeNormalization,...
                      projectFolders,... 
                      appendToFileName,...
                      flag_0Presentation_1Publication,...
                      flag_savePlot)


numberOfHorizontalPlotColumnsGeneric  = 2;
numberOfVerticalPlotRowsGeneric       = length(segmentSeries);
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

[subPlotPanelZ, pageWidthZ,pageHeightZ]= ...
  plotConfigGeneric(  numberOfHorizontalPlotColumnsGeneric,...
            numberOfVerticalPlotRowsGeneric,...
            plotWidth,...
            plotHeight,...
            plotHorizMarginCm,...
            plotVertMarginCm,...
            baseFontSize); 

%%
% Go through the experimental data, normalize it, and accumulate it
%%

for indexSegment=1:1:length(segmentSeries)
  segId=segmentSeries(indexSegment);

  nLengths = length(categories.length.str);
  
  
  
  expDataSet(length(categories.length.value)) ...
          = struct('lengthNominal',[],...
                   'meanForce',[],...
                   'meanForceActive',[],...
                   'meanForcePassive',[],...
                   'storage',[],...
                   'loss',[], ...
                   'storageActive',[],...
                   'lossActive',[], ...
                   'storagePassive',[],...
                   'lossPassive',[]);
  
  for i=1:1:length(categories.length.value)
    expDataSet(i) = struct('lengthNominal',categories.length.value(i),...
                           'meanForce',[],...
                           'meanForceActive',[],...
                           'meanForcePassive',[],...
                           'storage',[],...
                           'loss',[],...
                           'storageActive',[],...
                           'lossActive',[],...
                           'storagePassive',[],...
                           'lossPassive',[]);
  end
  
  for idxExp = 1:1:length(experimentList)
  
    trialList = dir(fullfile(projectFolders.output600A_json,...
                      experimentList{idxExp}));
  
  
    trialDataSet(length(categories.length.value)) ...
              = struct('lengthNominal',nan,...
                       'meanForce',[],...
                       'meanForceActive',nan,...
                       'meanForcePassive',[],...
                       'storage',[],...
                       'loss',[],...                 
                       'storageActive',[],...
                       'lossActive',[],...
                       'storagePassive',[],...
                       'lossPassive',[]);  
    
    for i=1:1:length(categories.length.value)
      trialDataSet(i) = ...
            struct('lengthNominal',categories.length.value(i),...
                   'meanForce',nan,...
                   'meanForceActive',nan,...
                   'meanForcePassive',[],...
                   'storage',[],...
                   'loss',[],...
                   'storageActive',[],...
                   'lossActive',[],...
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
  
          %Fetch the meta data

          %Fetch the auroraData


  
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
            
            assert(abs(bwARerr) < 0.2,'Error: bandwidth inconsistency');
            assert(abs(bwPRerr) < 0.2,'Error: bandwidth inconsistency');
            assert(abs(ampARerr) < 0.2,'Error: amplitude inconsistency');
            assert(abs(ampPRerr) < 0.2,'Error: amplitude inconsistency');
            
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
          tB = aJsonData(1).segment.pre.time(end);
          idxB = length(aJsonData(1).segment.pre.time);
          assert(strcmp(aJsonData(1).segment.unit.time,'ms'));
          idxA=find(aJsonData(1).segment.pre.time ...
                   > tB-nominalForceWindowInMs,1,'first');
          
  
          trialDataSet(idxL).lengthNominal=categories.length.value(idxL); 
  
          trialDataSet(idxL).meanForce=...
            mean(aJsonData(segId).segment.pre.force(idxA:idxB));
  
          trialDataSet(idxL).meanForceActive=...
            trialDataSet(idxL).meanForce;  
  
          trialDataSet(idxL).meanForcePassive=nan;
  
          if(~isempty(pJsonData(segId).segment.force))
            idxB = length(pJsonData(segId).segment.pre.time);
            tB   = pJsonData(segId).segment.pre.time(end);
            assert(strcmp(aJsonData(segId).segment.unit.time,'ms'));          
            idxA = find(pJsonData(segId).segment.pre.time ...
                      > (tB-nominalForceWindowInMs),1,'first');
  
  
            trialDataSet(idxL).meanForcePassive=...
              mean(pJsonData(segId).segment.pre.force(idxA:idxB));
            trialDataSet(idxL).meanForceActive=...
              trialDataSet(idxL).meanForceActive ...
              -trialDataSet(idxL).meanForcePassive;
          end
  
          trialDataSet(idxL).storage = ...
            aJsonData(segId).segment.H.storage(idxBWC2);
  
          trialDataSet(idxL).loss = ...
            aJsonData(segId).segment.H.loss(idxBWC2);
  
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
              = struct('lengthNominal',nan,...
                       'meanForce',[],...
                       'meanForceActive',nan,...
                       'meanForcePassive',[],...
                       'storage',[],...
                       'loss',[],...
                       'storageActive',[],...
                       'lossActive',[],...
                       'storagePassive',[],...
                       'lossPassive',[],...
                       'meanForceAtLo',[],...
                       'storageAtLo',[],...
                       'lossAtLo',[]);  
    
    iN = categories.length.indexLopt;
  
    for i=1:1:length(trialDataSet)
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
    
      normTrialDataSet(i).meanForceAtLo=fiso;
      normTrialDataSet(i).storageAtLo=median(trialDataSet(iN).storageActive);
      normTrialDataSet(i).lossAtLo=median(trialDataSet(iN).lossActive);
  
      normTrialDataSet(i).meanForceActive = ...
        trialDataSet(i).meanForceActive / fiso;
      normTrialDataSet(i).meanForce = ...
        trialDataSet(i).meanForce / fiso;
      normTrialDataSet(i).meanForcePassive = ...
        trialDataSet(i).meanForcePassive / fiso;
  
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
  
    end
  
    %
    % Accumulate this into the experiment data set
    %
    fieldsToAccmulate = ...
      {'meanForce','meanForceActive','meanForcePassive',....
       'storage','loss',...
       'storageActive','lossActive',...
       'storagePassive','lossPassive'};
    
    for i=1:1:length(expDataSet)
      for j=1:1:length(fieldsToAccmulate)
        expDataSet(i).(fieldsToAccmulate{j}) = ...
          [expDataSet(i).(fieldsToAccmulate{j});...
           normTrialDataSet(i).(fieldsToAccmulate{j})];
      end
    end
    here=1;
  end
  
  %%
  % Make the plots
  %%
  
  
  
  fieldsToPlot = {'storageActive','lossActive'};
  
  xySeries(6)=struct('x','','y','',...
                    'segment',2,...
                    'row',nan,'col',nan,...
                    'xTicks',[],'yTicks',[],...
                    'xLim',[],'yLim',[],...
                    'xLabel','','yLabel','',...
                    'title',[],'color',[]);
  
  idx=1;
  xySeries(idx).x='lengthNominal';
  xySeries(idx).y='storage';
  xySeries(idx).row=indexSegment;
  xySeries(idx).col=1;
  xySeries(idx).xTicks = categories.length.value;
  xySeries(idx).yTicks = [0,1];
  xySeries(idx).xLim   = [min(categories.length.value),...
                          max(categories.length.value)] + [-1,1].*0.05;
  xySeries(idx).yLim   = [0,1.6] + [-1,1].*sqrt(eps);
  xySeries(idx).xLabel = 'Norm. Length ($$\ell/\ell_o^M$$)';
  xySeries(idx).yLabel = 'Norm. Storage ($$(\mathrm{mN}/\mathrm{mm})/(S_o^M)$$)';
  xySeries(idx).title = sprintf(['Storage-Length-Relation',...
                                 ' (%1.1f Hz, %1.4f Lo)'],...
                                 bandwidthHz,amplitudeLo);
  xySeries(idx).color = [0,0,0];
  
  idx=idx+1;
  xySeries(idx).x='lengthNominal';
  xySeries(idx).y='loss';
  xySeries(idx).row=indexSegment;
  xySeries(idx).col=2;
  xySeries(idx).xTicks = categories.length.value;
  xySeries(idx).yTicks = [0,1];
  xySeries(idx).xLim   = [min(categories.length.value),...
                          max(categories.length.value)] + [-1,1].*0.05;
  xySeries(idx).yLim   = [0,1.6] + [-1,1].*sqrt(eps);
  xySeries(idx).xLabel = 'Norm. Length ($$\ell/\ell_o^M$$)';
  xySeries(idx).yLabel = 'Norm. Loss ($$(\mathrm{mN}/\mathrm{mm})/(S_o^M)$$)';
  xySeries(idx).title = sprintf(['Loss-Length-Relation',...
                                 ' (%1.1f Hz, %1.4f Lo)'],...
                                 bandwidthHz,amplitudeLo);
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


  if(modeNormalization==1)
    for i=1:1:length(xySeries)
      xySeries(idx).yLabel = 'Norm. Loss ($$(\mathrm{mN}/\mathrm{mm})/(L_o^M)$$)';
    end
  end
  
  
  
  for i=1:1:length(xySeries)
    figure(figH);
    subplot('Position',reshape(subPlotPanelZ(xySeries(i).row,xySeries(i).col,:),1,4));
    
    %Plot the force-length relation in the background
    nData.l=[];
    nData.f=[];
    aData.l=[];
    aData.f=[];  
    pData.l=[];
    pData.f=[];
    for j=1:1:length(expDataSet)
      aData.l=[aData.l,expDataSet(j).lengthNominal];
      aData.f = [aData.f,mean(expDataSet(j).meanForceActive)];
  
      nData.l=[nData.l,expDataSet(j).lengthNominal];
      nData.f = [nData.f,mean(expDataSet(j).meanForce)];
      
      pTmp = expDataSet(j).meanForcePassive;
      %idxP = find(pTmp >=0);
      %if(~isempty(idxP))
        pData.f = [pData.f,mean(pTmp)];
        pData.l = [pData.l,expDataSet(j).lengthNominal];
      %end
    end
  
    if(i==1 || i==2)
      yMax = median(expDataSet(categories.length.indexLopt).(xySeries(i).y));
      fill([min(aData.l),max(aData.l),fliplr(aData.l)],...
            [0,0,fliplr(aData.f)].*yMax, [1,1,1].*0.9,'EdgeColor','none');
      hold on;
      fill([min(pData.l),max(pData.l),fliplr(pData.l)],...
            [0,0,fliplr(pData.f)].*yMax, [1,1,1].*0.7,'EdgeColor','none');
      hold on;
      plot(nData.l,nData.f.*yMax,'-','Color',[1,1,1].*0.8,'LineWidth',1);
      hold on;
    end
  
  
    %Plot the stiffness / loss data
    for j=1:1:length(expDataSet)
  
      if(~isempty(expDataSet(j).(xySeries(i).y)))
        lineColor = xySeries(i).color;
        boxColor  = [1,1,1].*0.5 + lineColor.*0.5;
        bwWidth = 0.025;
        bwOffset=0;
        if(contains((xySeries(i).y),'Active'))
          bwOffset=bwWidth;
        end
        if(contains((xySeries(i).y),'Passive'))
          bwOffset=-bwWidth;
        end
        summaryStatistics = getSummaryStatistics(expDataSet(j).(xySeries(i).y));
        plotBoxWhiskerData(expDataSet(j).lengthNominal+bwOffset,...
                           summaryStatistics,...
                           bwWidth,lineColor,boxColor);
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
end






if(flag_savePlot==1)
  outputPlotDir = fullfile(projectFolders.output600A_plots,...
                           'impedance_length_relation_larb');
  
  figH=configPlotExporter(figH, ...
            pageWidthZ, pageHeightZ);
  fileName =  ['fig_impedance_length',appendToFileName];

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