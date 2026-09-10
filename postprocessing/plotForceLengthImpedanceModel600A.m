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


numberOfHorizontalPlotColumnsGeneric  = 3;
numberOfVerticalPlotRowsGeneric       = 6;

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

trialTypeSet={'active','passive'};
fieldTypeSet = {'forceNominal','A','B','C','alpha','beta','gamma','k'};

flag_expDataSetInitialized=0;
expDataSet(length(categories.length.value)) ...
        = struct('active',[],...
                 'passive',[]);

expNormDataSet(length(categories.length.value)) ...
        = struct('active',[],...
                 'passive',[]);

idxLopt = 4; 
assert(abs(categories.length.value(idxLopt)-1.0)<1e-6);
idxLmax = length(categories.length.value);

for i=1:1:length(categories.length.value)

  expDataSet(i).active = ...
    struct( 'lengthNominal',categories.length.value(i),...
            'forceNominal',nan,...
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
              'forceNominal',nan,...      
              'A',nan,...
              'B',nan,...
              'C',nan,...
              'alpha',nan,...
              'beta',nan,...
              'gamma',nan,...
              'k',nan,...
              'isValid',1);

  expNormDataSet(i).active = ...
    struct( 'lengthNominal',categories.length.value(i),...
            'forceNominal',nan,...
            'A',nan,...
            'B',nan,...
            'C',nan,...
            'alpha',nan,...
            'beta',nan,...
            'gamma',nan,...
            'k',nan,...
            'isValid',1);

  expNormDataSet(i).passive = ...
      struct( 'lengthNominal',categories.length.value(i),...
              'forceNominal',nan,...      
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
              'forceNominal',nan,...
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
                'forceNominal',nan,...
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
            a=nan;
            b=nan;
            c=nan;
            d=nan;
            forceNominal=nan;
            switch k
              case 1
                if(isfield(aJsonData(segId).segment,'model'))
                  if(isfield(aJsonData(segId).segment.model,'K3'))
                    if(~isempty(aJsonData(segId).segment.model.K3))                
                      a = aJsonData(segId).segment.model.K3.componentImpedance(j,2);
                      b = aJsonData(segId).segment.model.K3.componentImpedance(j,3);
                      c = aJsonData(segId).segment.model.K3.componentImpedance(j,4);
                      d = aJsonData(segId).segment.model.K3.componentImpedance(j,5);                      
                      isModelValid=1;
                    end
                  end
                end
                forceNominal=mean(aJsonData(segId).segment.force);                
                trialType='active';      

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
                forceNominal=mean(pJsonData(segId).segment.force);                
                trialType='passive';                

              otherwise
                assert(0,'Error: k must be 1 or 2, active or passive');
            end

            trialDataSet(idxL).(trialType).isValid = ...
              trialDataSet(idxL).(trialType).isValid && isModelValid;

            trialDataSet(idxL).(trialType).forceNominal=forceNominal;
            if(isModelValid==1)
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
  end

  %Check that all categories have been filled.
  for idxC=1:1:length(trialDataSet)
    for j=1:1:length(trialTypeSet)
      %Check to make sure all fields are empty, or all are populated
      if(~isnan(trialDataSet(idxC).(trialTypeSet{j}).A))
        for k=1:1:length(fieldTypeSet)
          if(isnan(trialDataSet(idxC).(trialTypeSet{j}).(fieldTypeSet{k})) ...
             && ~strcmp(fieldTypeSet{k},'forceNominal'))
            here=1;
          end
          if(~strcmp(fieldTypeSet{k},'forceNominal'))
            assert(~isnan(trialDataSet(idxC).(trialTypeSet{j}).(fieldTypeSet{k})));
          end
        end
      else
        for k=1:1:length(fieldTypeSet)
          if(~isnan(trialDataSet(idxC).(trialTypeSet{j}).(fieldTypeSet{k})) ...
              && ~strcmp(fieldTypeSet{k},'forceNominal'))
            here=1;
          end          
          if(~strcmp(fieldTypeSet{k},'forceNominal'))          
            assert(isnan(trialDataSet(idxC).(trialTypeSet{j}).(fieldTypeSet{k})));
          end
        end
      end
    end
  end

  %
  % If A has a higher frequency than C, switch these fields
  %
  for idxC=1:1:length(trialDataSet)
    for j=1:1:length(trialTypeSet)
      if(~isnan(trialDataSet(idxC).(trialTypeSet{j}).alpha) ...
          && ~isnan(trialDataSet(idxC).(trialTypeSet{j}).gamma))
        if(trialDataSet(idxC).(trialTypeSet{j}).alpha ...
            > trialDataSet(idxC).(trialTypeSet{j}).gamma)
          
          t0 = trialDataSet(idxC).(trialTypeSet{j}).A;
          t1 = trialDataSet(idxC).(trialTypeSet{j}).alpha;

          trialDataSet(idxC).(trialTypeSet{j}).A = ...
            trialDataSet(idxC).(trialTypeSet{j}).C;
          trialDataSet(idxC).(trialTypeSet{j}).alpha = ...
            trialDataSet(idxC).(trialTypeSet{j}).gamma;
          
          trialDataSet(idxC).(trialTypeSet{j}).C=t0;
          trialDataSet(idxC).(trialTypeSet{j}).gamma=t1;


        end
      end
    end
  end

  %
  % Normalize the coefficients
  %
  normTrialDataSet=trialDataSet;
  normActiveTrial = trialDataSet(idxLopt).active;
  normPassiveTrial=trialDataSet(idxLmax).passive;

  for i=1:1:length(trialDataSet)
    for j=1:1:length(trialTypeSet)
      for k=1:1:length(fieldTypeSet)
        normFactor=nan;
        switch fieldTypeSet{k}
          case 'forceNominal'
            normFactor=normActiveTrial.forceNominal;            
          case 'A' 
            normFactor=normActiveTrial.B;
          case 'B'
            normFactor=normActiveTrial.B;            
          case 'C'
            normFactor=normActiveTrial.B;            
          case 'alpha'
            normFactor=normActiveTrial.beta;                        
          case 'beta'
            normFactor=normActiveTrial.beta;                                    
          case 'gamma'
            normFactor=normActiveTrial.beta;                                    
          case 'k'
            normFactor=normPassiveTrial.k;                                    
          otherwise
            assert(0,'Error: field not found');
        end
        normTrialDataSet(i).(trialTypeSet{j}).(fieldTypeSet{k}) = ...
          trialDataSet(i).(trialTypeSet{j}).(fieldTypeSet{k})...
          ./normFactor;        
      end
    end
  end

  %
  % Accumulate this into the experiment data set
  %
  
  for i=1:1:length(expDataSet)
    for j=1:1:length(trialTypeSet)
      for k=1:1:length(fieldTypeSet)
        if(flag_expDataSetInitialized==0)
          expDataSet(i).(trialTypeSet{j}).(fieldTypeSet{k}) = ...
             trialDataSet(i).(trialTypeSet{j}).(fieldTypeSet{k});
          expNormDataSet(i).(trialTypeSet{j}).(fieldTypeSet{k}) = ...
             normTrialDataSet(i).(trialTypeSet{j}).(fieldTypeSet{k});                  
        else
          expDataSet(i).(trialTypeSet{j}).(fieldTypeSet{k}) = ...
            [expDataSet(i).(trialTypeSet{j}).(fieldTypeSet{k});...
             trialDataSet(i).(trialTypeSet{j}).(fieldTypeSet{k})];
          expNormDataSet(i).(trialTypeSet{j}).(fieldTypeSet{k}) = ...
            [expNormDataSet(i).(trialTypeSet{j}).(fieldTypeSet{k});...
             normTrialDataSet(i).(trialTypeSet{j}).(fieldTypeSet{k})];        
        end
      end
    end
  end
  flag_expDataSetInitialized=1;
  here=1;
end

%%
% Make the plots
%%



fieldsToPlot = {'A','B','C','alpha','beta','gamma','k'};

xySeries(14)=struct('x','','y','',...
                  'segment',2,...
                  'row',nan,'col',nan,...
                  'xTicks',[],'yTicks',[],...
                  'xLim',[],'yLim',[],...
                  'xLabel','','yLabel','',...
                  'title',[],'color',[]);

ptColorSeries=getPaulTolColourSchemes('vibrant');

colorSeries = zeros(length(experimentList),3);

colorFields=fields(ptColorSeries);

for i=1:1:size(colorSeries,1)
  colorSeries(i,:)=ptColorSeries.(colorFields{i});
end


idx=1;
xySeries(idx).x='lengthNominal';
xySeries(idx).y='A';
xySeries(idx).type='active';
xySeries(idx).row=1;
xySeries(idx).col=1;
xySeries(idx).xTicks = categories.length.value;
xySeries(idx).yTicks = [];%[0,20];
xySeries(idx).xLim   = [min(categories.length.value),...
                        max(categories.length.value)] + [-1,1].*0.05;
xySeries(idx).yLim   = [];%[0,20] + [-1,1].*sqrt(eps);
xySeries(idx).xLabel = 'Norm. Length ($$\ell/\ell_o^M$$)';
xySeries(idx).yLabel = 'Impedance Magnitude (mN/mm)';
xySeries(idx).title = 'A';
xySeries(idx).color = [0,0,0];

idx=idx+1;
xySeries(idx).x='lengthNominal';
xySeries(idx).y='B';
xySeries(idx).type='active';
xySeries(idx).row=1;
xySeries(idx).col=2;
xySeries(idx).xTicks = categories.length.value;
xySeries(idx).yTicks = [];%[-7,0];
xySeries(idx).xLim   = [min(categories.length.value),...
                        max(categories.length.value)] + [-1,1].*0.05;
xySeries(idx).yLim   = [];%[-7,0] + [-1,1].*sqrt(eps);
xySeries(idx).xLabel = 'Norm. Length ($$\ell/\ell_o^M$$)';
xySeries(idx).yLabel = 'Impedance Magnitude (mN/mm)';
xySeries(idx).title = 'B';
xySeries(idx).color = [0,0,0];

idx=idx+1;
xySeries(idx).x='lengthNominal';
xySeries(idx).y='C';
xySeries(idx).type='active';
xySeries(idx).row=1;
xySeries(idx).col=3;
xySeries(idx).xTicks = categories.length.value;
xySeries(idx).yTicks = [];%[0,5];
xySeries(idx).xLim   = [min(categories.length.value),...
                        max(categories.length.value)] + [-1,1].*0.05;
xySeries(idx).yLim   = [];%[0,5] + [-1,1].*sqrt(eps);
xySeries(idx).xLabel = 'Norm. Length ($$\ell/\ell_o^M$$)';
xySeries(idx).yLabel = 'Impedance Magnitude (mN/mm)';
xySeries(idx).title  = 'C';
xySeries(idx).color  = [0,0,0];


idx=idx+1;
xySeries(idx).x='lengthNominal';
xySeries(idx).y='alpha';
xySeries(idx).type='active';
xySeries(idx).row=2;
xySeries(idx).col=1;
xySeries(idx).xTicks = categories.length.value;
xySeries(idx).yTicks = [];%[0,50]./(2*pi);
xySeries(idx).xLim   = [min(categories.length.value),...
                        max(categories.length.value)] + [-1,1].*0.05;
xySeries(idx).yLim   = [];%[0,50]./(2*pi) + [-1,1].*sqrt(eps);
xySeries(idx).xLabel = 'Norm. Length ($$\ell/\ell_o^M$$)';
xySeries(idx).yLabel = 'Frequency (Hz)';
xySeries(idx).title  = '$$\alpha/(2\pi)$$';
xySeries(idx).color  = [0,0,0];

idx=idx+1;
xySeries(idx).x='lengthNominal';
xySeries(idx).y='beta';
xySeries(idx).type='active';
xySeries(idx).row=2;
xySeries(idx).col=2;
xySeries(idx).xTicks = categories.length.value;
xySeries(idx).yTicks = [];%[0,15]./(2*pi);
xySeries(idx).xLim   = [min(categories.length.value),...
                        max(categories.length.value)] + [-1,1].*0.05;
xySeries(idx).yLim   = [];%[0,15]./(2*pi) + [-1,1].*sqrt(eps);
xySeries(idx).xLabel = 'Norm. Length ($$\ell/\ell_o^M$$)';
xySeries(idx).yLabel = 'Frequency (Hz)';
xySeries(idx).title  = '$$\beta/(2\pi)$$';
xySeries(idx).color  = [0,0,0];

idx=idx+1;
xySeries(idx).x='lengthNominal';
xySeries(idx).y='gamma';
xySeries(idx).type='active';
xySeries(idx).row=2;
xySeries(idx).col=3;
xySeries(idx).xTicks = categories.length.value;
xySeries(idx).yTicks = [];%[0,600]./(2*pi);
xySeries(idx).xLim   = [min(categories.length.value),...
                        max(categories.length.value)] + [-1,1].*0.05;
xySeries(idx).yLim   = [];%[0,600]./(2*pi) + [-1,1].*sqrt(eps);
xySeries(idx).xLabel = 'Norm. Length ($$\ell/\ell_o^M$$)';
xySeries(idx).yLabel = 'Frequency (Hz)';
xySeries(idx).title  = '$$\gamma/(2\pi)$$';
xySeries(idx).color  = [0,0,0];

idx=idx+1;
xySeries(idx).x='lengthNominal';
xySeries(idx).y='k';
xySeries(idx).type='active';
xySeries(idx).row=3;
xySeries(idx).col=1;
xySeries(idx).xTicks = categories.length.value;
xySeries(idx).yTicks = [];%[0,10];
xySeries(idx).xLim   = [min(categories.length.value),...
                        max(categories.length.value)] + [-1,1].*0.05;
xySeries(idx).yLim   = [];%[0,10] + [-1,1].*sqrt(eps);
xySeries(idx).xLabel = 'Norm. Length ($$\ell/\ell_o^M$$)';
xySeries(idx).yLabel = 'Stiffness (mN/mm)';
xySeries(idx).title  = '$$k$$';
xySeries(idx).color  = [0,0,0];

for idx =1:1:7
  xySeries(idx+7)=xySeries(idx);
  xySeries(idx+7).row =  xySeries(idx+7).row + 3;
  xySeries(idx+7).type='passive';
end


for i=1:1:length(xySeries)
  figure(figH);
  subplot('Position',reshape(subPlotPanelZ(xySeries(i).row,xySeries(i).col,:),1,4));
  

  trialType=xySeries(i).type;
  %Collect the data across each length
  for n=1:1:length(experimentList)      
    dataX = [];
    dataY = [];        
    for m=1:1:length(expDataSet)
      dataX = [dataX,expDataSet(m).(trialType).(xySeries(i).x)];
      dataY = [dataY,expDataSet(m).(trialType).(xySeries(i).y)(n)];
    end
    plot(dataX,dataY,'-','Color',colorSeries(n,:),...
         'DisplayName',num2str(n));
    hold on;
  end

  box off;

  if(i==1)
    legend('Location','NorthWest');
    legend box off;
  end


  xlabel(xySeries(i).xLabel);
  ylabel(xySeries(i).yLabel);
  title(xySeries(i).title);
  if(~isempty(xySeries(i).yLim))
    ylim(xySeries(i).yLim);
  end
  xlim(xySeries(i).xLim);
  xticks(xySeries(i).xTicks);
  if(~isempty(xySeries(i).yTicks))  
    yticks(xySeries(i).yTicks);  
  end
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