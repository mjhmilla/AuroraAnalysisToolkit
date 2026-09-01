function figH = plotForceLengthImpedanceModel600A(...
                      figH,...
                      experimentList, ...
                      segId,...
                      categories, ...
                      modeNormalization,...
                      projectFolders,... 
                      appendToFileName,...
                      flag_0Presentation_1Publication,...
                      flag_savePlot)


numberOfHorizontalPlotColumnsGeneric  = 2;
numberOfVerticalPlotRowsGeneric       = 1;

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
nLengths = length(categories.length.str);

expDataSet(length(categories.length.value)) ...
        = struct('active',[],...
                 'passive',[]);

for i=1:1:length(categories.length.value)

  expDataSet(i).active = ...
    struct( 'lengthNominal',categories.length.value(i),...
            'A',nan,...
            'B',nan,...
            'C',nan,...
            'alpha',nan,...
            'beta',nan,...
            'gamma',nan,...
            'k',nan,...
            'isValid',1);

  expDataSet(i).passive = ...
      struct( 'lengthNominal',categories.length.value(i),...
              'A',nan,...
              'B',nan,...
              'C',nan,...
              'alpha',nan,...
              'beta',nan,...
              'gamma',nan,...
              'k',nan,...
              'isValid',1);

end

for idxExp = 1:1:length(experimentList)

  trialList = dir(fullfile(projectFolders.output600A_json,...
                    experimentList{idxExp}));

  trialDataSet(length(categories.length.value)) ...
    = struct('active',[],'passive',[]);  
  
  for i=1:1:length(categories.length.value)

    trialDataSet(i).active = ...
      struct( 'lengthNominal',categories.length.value(i),...
              'A',nan,...
              'B',nan,...
              'C',nan,...
              'alpha',nan,...
              'beta',nan,...
              'gamma',nan,...
              'k',nan,...
              'isValid',1);
  
    trialDataSet(i).passive = ...
        struct( 'lengthNominal',categories.length.value(i),...
                'A',nan,...
                'B',nan,...
                'C',nan,...
                'alpha',nan,...
                'beta',nan,...
                'gamma',nan,...
                'k',nan,...
                'isValid',1);
  end


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

        fprintf('\n\n(%i,%i)\t%s\n\t%s\n',...
            idxExp,idxTrialA,aFilePath,pFilePath);
        
        assert(size(aJsonData(segId).segment.model.K3.componentImpedance,1)==4,...
               'Error: expected to see 4 components in the K3 model');

        for j=1:1:4
          for k=1:1:2
            trialType='';
            isModelValid=0;
            switch k
              case 1
                a = aJsonData(segId).segment.model.K3.componentImpedance(j,2);
                b = aJsonData(segId).segment.model.K3.componentImpedance(j,3);
                c = aJsonData(segId).segment.model.K3.componentImpedance(j,4);
                d = aJsonData(segId).segment.model.K3.componentImpedance(j,5);
                trialType='active';
                isModelValid=1;
              case 2
                if(isfield(pJsonData(segId).segment,'model'))
                  if(isfield(pJsonData(segId).segment.model,'K3'))
                    if(~isempty(pJsonData(segId).segment.model.K3))
                      a = pJsonData(segId).segment.model.K3.componentImpedance(j,2);
                      b = pJsonData(segId).segment.model.K3.componentImpedance(j,3);
                      c = pJsonData(segId).segment.model.K3.componentImpedance(j,4);
                      d = pJsonData(segId).segment.model.K3.componentImpedance(j,5);
                      isModelValid=1;                    
                    end
                  end
                end
                trialType='passive';                

              otherwise
                assert(0,'Error: k must be 1 or 2, active or passive');
            end

            trialDataSet(idxL).(trialType).isValid =...
              trialDataSet(idxL).(trialType).isValid && isModelValid;
            
            switch j
              case 1
                assert(abs(a)<1e-6);
                trialDataSet(idxL).(trialType).A    = b/d;
                trialDataSet(idxL).(trialType).alpha= c/d;
              case 2                
                assert(abs(a)<1e-6);
                trialDataSet(idxL).(trialType).B    = b/d;
                trialDataSet(idxL).(trialType).beta = c/d;              

              case 3
                assert(abs(a)<1e-6);              
                trialDataSet(idxL).(trialType).C    = b/d;
                trialDataSet(idxL).(trialType).gamma = c/d;
              case 4
                assert(abs(b)<1e-6);              
                assert(abs(d)<1e-6);              
                trialDataSet(idxL).(trialType).k    = a/c;  
              otherwise
                assert(0,'Error: attempted to access an invalid component');
            end
          end
        end

      end
    end
  end

  %Check that all categories have been filled.
  for idxC=1:1:length(trialDataSet)
    trialType={'active'};%,'passive'};
    fieldType = {'A','B','C','alpha','beta','gamma','k'};
    for j=1:1:length(trialType)
      for k=1:1:length(fieldType)
        assert(~isnan(trialDataSet(idxC).(trialType{j}).(fieldType{k})));
      end
    end
  end

  %
  % You are here
  %
  assert(0,'You are here');

  %Adjust the passive forces so that 0.55 Lo is zero, and then
  %evaluate the nominal active force
  for idxC=1:1:length(trialDataSet)
    trialDataSet(idxC).forceNominalPassive= ...
      trialDataSet(idxC).forceNominalPassive ...
      -trialDataSet(1).forceNominalPassive;
    trialDataSet(idxC).forceNominalActive = ...
      trialDataSet(idxC).forceNominal ...
      -trialDataSet(idxC).forceNominalPassive;
  end

  %Normalize the data
  normTrialDataSet(length(categories.length.value)) ...
            = struct('lengthNominal',nan,...
                     'forceNominal',[],...
                     'forceNominalActive',nan,...
                     'forceNominalPassive',[],...
                     'storage',[],...
                     'loss',[]);  
  
  iN = categories.length.indexLopt;

  for i=1:1:length(trialDataSet)
    normTrialDataSet(i).lengthNominal=trialDataSet(i).lengthNominal;

    lopt = trialDataSet(iN).lengthNominal;
    fiso = trialDataSet(iN).forceNominalActive;
    siso=nan;
    liso=nan;
    if(modeNormalization==0)
      siso = median(trialDataSet(iN).storage);
      liso = siso;      
    end
    if(modeNormalization==1)
      siso = median(trialDataSet(iN).storage);
      liso = median(trialDataSet(iN).loss);      
    end


    normTrialDataSet(i).forceNominalActive = ...
      trialDataSet(i).forceNominalActive / fiso;
    normTrialDataSet(i).forceNominal = ...
      trialDataSet(i).forceNominal / fiso;
    normTrialDataSet(i).forceNominalPassive = ...
      trialDataSet(i).forceNominalPassive / fiso;

    normTrialDataSet(i).storage = ...
      trialDataSet(i).storage / siso;
    normTrialDataSet(i).loss = ...
      trialDataSet(i).loss / liso;

  end

  %
  % Accumulate this into the experiment data set
  %
  fieldsToAccmulate = ...
    {'forceNominal','forceNominalActive','forceNominalPassive',....
     'storage','loss'};
  
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



fieldsToPlot = {'storage','loss'};

xySeries(2)=struct('x','','y','',...
                  'segment',2,...
                  'row',nan,'col',nan,...
                  'xTicks',[],'yTicks',[],...
                  'xLim',[],'yLim',[],...
                  'xLabel','','yLabel','',...
                  'title',[],'color',[]);

idx=1;
xySeries(idx).x='lengthNominal';
xySeries(idx).y='storage';
xySeries(idx).row=1;
xySeries(idx).col=1;
xySeries(idx).xTicks = categories.length.value;
xySeries(idx).yTicks = [0,1];
xySeries(idx).xLim   = [min(categories.length.value),...
                        max(categories.length.value)] + [-1,1].*0.05;
xySeries(idx).yLim   = [0,1.6] + [-1,1].*sqrt(eps);
xySeries(idx).xLabel = 'Norm. Length ($$\ell/\ell_o^M$$)';
xySeries(idx).yLabel = 'Norm. Storage ($$(\mathrm{mN}/\mathrm{mm})/(S_o^M)$$)';
xySeries(idx).title = 'Storage-Length-Relation';
xySeries(idx).color = [0,0,0];

idx=idx+1;
xySeries(idx).x='lengthNominal';
xySeries(idx).y='loss';
xySeries(idx).row=1;
xySeries(idx).col=2;
xySeries(idx).xTicks = categories.length.value;
xySeries(idx).yTicks = [0,1];
xySeries(idx).xLim   = [min(categories.length.value),...
                        max(categories.length.value)] + [-1,1].*0.05;
xySeries(idx).yLim   = [0,1.6] + [-1,1].*sqrt(eps);
xySeries(idx).xLabel = 'Norm. Length ($$\ell/\ell_o^M$$)';
xySeries(idx).yLabel = 'Norm. Loss ($$(\mathrm{mN}/\mathrm{mm})/(S_o^M)$$)';
xySeries(idx).title = 'Loss-Length-Relation';
xySeries(idx).color = [0,0,0];

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
    idxA = find(expDataSet(j).forceNominalActive >=0);
    aData.f = [aData.f,mean(expDataSet(j).forceNominalActive(idxA))];

    nData.l=[nData.l,expDataSet(j).lengthNominal];
    idxN = find(expDataSet(j).forceNominal >=0);
    nData.f = [nData.f,mean(expDataSet(j).forceNominal(idxN))];
    
    idxP0 = find(~isnan(expDataSet(j).forceNominalPassive));
    pTmp = expDataSet(j).forceNominalPassive(idxP0);
    idxP = find(pTmp >=0);
    if(~isempty(idxP))
      pData.f = [pData.f,mean(pTmp(idxP))];
      pData.l = [pData.l,expDataSet(j).lengthNominal];
    end
  end
  switch i
    case 1
      yMax = median(expDataSet(categories.length.indexLopt).storage);
    case 2
      yMax = median(expDataSet(categories.length.indexLopt).loss);
  end

  if(i==1 && modeNormalization==0 || modeNormalization==1)
    fill([min(aData.l),max(aData.l),fliplr(aData.l)],...
          [0,0,fliplr(aData.f)].*yMax, [1,1,1].*0.9,'EdgeColor','none');
    hold on;
    fill([min(pData.l),max(pData.l),fliplr(pData.l)],...
          [0,0,fliplr(pData.f)].*yMax, [1,1,1].*0.7,'EdgeColor','none');
    hold on;
    plot(nData.l,nData.f,'-','Color',[1,1,1].*0.8,'LineWidth',1);
  end


  %Plot the stiffness / loss data
  for j=1:1:length(expDataSet)

    lineColor = xySeries(i).color;
    boxColor  = [1,1,1].*0.5 + lineColor.*0.5;
    summaryStatistics = getSummaryStatistics(expDataSet(j).(xySeries(i).y));
    plotBoxWhiskerData(expDataSet(j).lengthNominal,...
                       summaryStatistics,...
                       0.05,lineColor,boxColor);
    here=1;
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
    text(1.3,0.1,'$$f^{P}(\ell^M)$$','HorizontalAlignment','right',...
                 'FontSize',6);
    hold on;
    
  end
  box off;
  here=1;
end







if(flag_savePlot==1)
  outputPlotDir = fullfile(projectFolders.output600A_plots,...
                           'impedance_length_relation_larb');
  
  figH=configPlotExporter(figH, ...
            pageWidthZ, pageHeightZ);
  fileName =  ['fig_impedance_length_',appendToFileName];

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