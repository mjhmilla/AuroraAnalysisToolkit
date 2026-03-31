clc;
close all;
clear all;

rootDir         = getRootProjectDirectory();
projectFolders  = getProjectFolders(rootDir);

addpath(projectFolders.aurora600A);
addpath(projectFolders.common);
addpath(projectFolders.postprocessing);
addpath(projectFolders.experiments);
addpath(fullfile(rootDir,'aurora600A_impedance'));

segIdIso=1;
segIdPassive=2;

segId = 4; % 0-90 Hz bandwidth, 0.001 Lo perturbation
%1 0-35 Hz bandwidth, 0.01 Lo perturbation
%2 0-90 Hz bandwidth, 0.01 Lo perturbation
%3 0-35 Hz bandwidth, 0.001 Lo perturbation
%4 0-90 Hz bandwidth, 0.001 Lo perturbation
hId = 'H';
boxWidth = 0.1;


experimentsToProcess =  ...
    { '20251118_impedance_larb_1',...
      '20251118_impedance_larb_2',...
      '20251120_impedance_larb_3',...
      '20251121_impedance_larb_4',...
      '20251121_impedance_larb_5',...
      '20251128_impedance_larb_6',...
      '20251203_impedance_larb_7'};


outputFolder = 'impedance_length_relation_larb';

%
% The files on this list are at lengths short enough that no
% trial in the data set (at these lengths) has a noticeable passive
% force
%
maxNormLengthZeroPassiveForce = 0.85;

activeReferenceFiles = {...
  '_active_055Lo_',...
  '_active_070Lo_',...
  '_active_085Lo_'};

passiveReferenceFiles = {...
  '_passive_055Lo_',...
  '_passive_070Lo_',...
  '_passive_085Lo_'};


impedanceData(7) = struct('normLengthStr','',...
                          'normLength',0,...
                          'normStorage',[],...
                          'normLoss',[],...
                          'lopt',0,...
                          'fopt',0,...
                          'kopt',0,...
                          'dopt',0,...
                          'fzero',0);
for i=1:1:length(impedanceData)
  impedanceData(i) = struct('normLengthStr','',...
                            'normLength',0.55 + 0.15*(i-1),...
                            'normStorage',[],...
                            'normLoss',[],...
                            'lopt',0,...
                            'fopt',0,...
                            'kopt',0,...
                            'dopt',0,...
                            'fzero',0);
  
  if(impedanceData(i).normLength >= 1)
    impedanceData(i).normLengthStr = ...
        sprintf('_%iLo_',round(impedanceData(i).normLength*100));
  else
    impedanceData(i).normLengthStr = ...
        sprintf('_0%iLo_',round(impedanceData(i).normLength*100));
  end
  %fprintf('%1.2f\t%s\n',impedanceData(i).normLength,impedanceData(i).normLengthStr);
end

%%
% Plot configuration
%%

PaulTolColors = getPaulTolColourSchemes('bright');

color.active  = [0,0,0];
color.passive = [1,1,1].*0.5;

%
% Individual
%
figImpedanceLengthIndividual = figure;

numberOfHorizontalPlotColumnsGeneric    = 2;
numberOfVerticalPlotRowsGeneric         = length(experimentsToProcess);

plotWidth                               = ones(1,numberOfHorizontalPlotColumnsGeneric).*6;
plotHeight                              = ones(numberOfVerticalPlotRowsGeneric,1).*6;
plotHorizMarginCm                       = 2;
plotVertMarginCm                        = 2.5;
baseFontSize                            = 12;

[subPlotPanelIndividual, pageWidthIndividual,pageHeightIndividual]= ...
  plotConfigGeneric(  numberOfHorizontalPlotColumnsGeneric,...
                      numberOfVerticalPlotRowsGeneric,...
                      plotWidth,...
                      plotHeight,...
                      plotHorizMarginCm,...
                      plotVertMarginCm,...
                      baseFontSize); 

%
% Group
%
figImpedanceLengthGroup = figure;

numberOfHorizontalPlotColumnsGeneric    = 2;
numberOfVerticalPlotRowsGeneric         = 1;

plotWidth                               = ones(1,numberOfHorizontalPlotColumnsGeneric).*6;
plotHeight                              = ones(numberOfVerticalPlotRowsGeneric,1).*6;

[subPlotPanelGroup, pageWidthGroup,pageHeightGroup]= ...
  plotConfigGeneric(  numberOfHorizontalPlotColumnsGeneric,...
                      numberOfVerticalPlotRowsGeneric,...
                      plotWidth,...
                      plotHeight,...
                      plotHorizMarginCm,...
                      plotVertMarginCm,...
                      baseFontSize); 


freqSample = [];



for i = 1:1:length(experimentsToProcess)
    expFolder = fullfile(projectFolders.output,'json',...
                         experimentsToProcess{i});
    fprintf('%s\n',expFolder);

    folderContents = dir(expFolder);
    trialCount = 0;
    dataLoptJson = [];
    dataLoptFzeroJson = [];
    for j=1:1:length(folderContents)
        if(~folderContents(j).isdir ...
            && contains(folderContents(j).name,'.json'))
            trialCount=trialCount+1;

            if(contains(folderContents(j).name,'_100Lo_'))
              dataStr =fileread(fullfile(expFolder,folderContents(j).name));
              dataLoptJson=jsondecode(dataStr);

              if(1 > maxNormLengthZeroPassiveForce)
                for k=j:-1:1
                  for z=1:1:length(activeReferenceFiles)
                    if(contains(folderContents(k).name,activeReferenceFiles{z}) ...
                        && isempty(dataLoptFzeroJson))
                      dataStr =fileread(fullfile(expFolder,folderContents(k).name));
                      dataLoptFzeroJson=jsondecode(dataStr);                    
                    end
                  end
                end
              else
                dataLoptFzeroJson = dataLoptJson;
              end

            end
        end
    end
    
    assert(~isempty(dataLoptJson),...
        'Error: could not find a trial at 100Lo');
    assert(~isempty(dataLoptFzeroJson),...
        'Error: could not find a fzero reference trial at 100Lo');

    storageLopt = mean(dataLoptJson(segId).segment.(hId).storage);
    lossLopt    = mean(dataLoptJson(segId).segment.(hId).loss);
    disp('Update to use the data just prior to the perturbation');
    foptFzero   = dataLoptFzeroJson(segIdIso).segment.forceReference;
    fopt        = mean(dataLoptJson(segIdIso).segment.nominal.force)-foptFzero;   
    lopt        = mean(dataLoptJson(segIdIso).segment.nominal.length);

    
    figure(figImpedanceLengthIndividual);

    %
    % Extract lopt, fopt, kopt, betaopt
    %
    subplot('Position',reshape(subPlotPanelIndividual(i,1,:),1,4));
      text(0.55, 1.7, ...
        sprintf('%s = %1.2f %s\n%s = %1.2f %s',...
          '$$\ell_o$$', lopt, dataLoptJson(segId).segment.unit.length,...
          '$$f_o$$', fopt, dataLoptJson(segId).segment.unit.force),...
          'HorizontalAlignment','left',...
          'VerticalAlignment','top',...
          'FontSize',8);
      hold on;
      text(1.5, 1.7, ...
        sprintf('%s = %1.2f %s',...
          '$$k_o^{50}$$', storageLopt, ...
            [dataLoptJson(segId).segment.unit.force,...
            '/',dataLoptJson(segId).segment.unit.length]),...
          'HorizontalAlignment','right',...
          'VerticalAlignment','top',...
          'FontSize',8);
      hold on;

    subplot('Position',reshape(subPlotPanelIndividual(i,2,:),1,4));
      text(1.5, 1.7, ...
        sprintf('%s = %1.2f %s',...
          '$$\beta_o^{50}$$', lossLopt, ...
            [dataLoptJson(segId).segment.unit.force,...
            '/(',dataLoptJson(segId).segment.unit.length,'/s)']),...
          'HorizontalAlignment','right',...
          'VerticalAlignment','top',...
          'FontSize',8);
      hold on;


    if(i==1)
      freqSample = [0.05:0.05:0.95]'.*(dataLoptJson(segId).segment.(hId).bandwidthHz(2,1));
    end

    %
    % Gather the points the plot the active and passive force length
    % areas for reference
    %
    lceNSeries= [0.55:0.15:1.45]';
    fapSeries = zeros(size(lceNSeries));
    fpeSeries = zeros(size(lceNSeries));
    for j=1:1:length(folderContents)
      if(~folderContents(j).isdir ...
              && contains(folderContents(j).name,'.json'))

        dataStr =fileread(fullfile(expFolder,folderContents(j).name));
        dataJson=jsondecode(dataStr);

        idxL = nan;
        for k=1:1:length(impedanceData)
          if(contains(folderContents(j).name, impedanceData(k).normLengthStr))
            idxL=k;
          end
        end

        fN = nan;

        if(contains(folderContents(j).name,'active'))

          lceN  = mean(dataJson(segIdIso).segment.nominal.length)./lopt;
          fzero = dataJson(segIdIso).segment.forceReference;

          %Go get the most appropriate force reference: it should be from
          %an active trial that is at a short enough length that
          %there is no passive force.
          if(lceN > maxNormLengthZeroPassiveForce)
            dataFzeroJson = [];
            for k=j:-1:1
              for z=1:1:length(activeReferenceFiles)
                if(contains(folderContents(k).name,activeReferenceFiles{z}) ...
                    && isempty(dataFzeroJson))
                  dataStr =fileread(fullfile(expFolder,folderContents(k).name));
                  dataFzeroJson=jsondecode(dataStr); 
                  fzero = dataFzeroJson(segIdIso).segment.forceReference;
                end
              end
            end
          end

          
          fN =(mean(dataJson(segIdIso).segment.nominal.force)-fzero)./fopt;
        end
        if(contains(folderContents(j).name,'passive')) 
          if(isfield(dataJson(segIdIso).segment,'nominal'))
            
            fzero = dataJson(segIdPassive).segment.forceReference;            
            lceN = mean(dataJson(segIdPassive).segment.nominal.length)./lopt;

            %Go get the most appropriate force reference: it should be from
            %an active trial that is at a short enough length that
            %there is no passive force.
            if(lceN > maxNormLengthZeroPassiveForce)
              dataFzeroJson = [];
              for k=j:-1:1
                for z=1:1:length(passiveReferenceFiles)
                  if(contains(folderContents(k).name,passiveReferenceFiles{z}) ...
                      && isempty(dataFzeroJson))
                    dataStr =fileread(fullfile(expFolder,folderContents(k).name));
                    dataFzeroJson=jsondecode(dataStr); 
                    fzeroSet = [];
                    for x=1:1:length(dataFzeroJson)
                      fzeroSet = [fzeroSet,dataFzeroJson(x).segment.forceReference];
                    end
                    fzero = mean(fzeroSet);
                    
                  end
                end
              end
            end
            fN = (dataJson(segIdPassive).segment.forceReference-fzero)./fopt;
          end
        end


        if(~isempty(fN))
          if(contains(folderContents(j).name,'active') && ~isnan(fN))
            fapSeries(idxL)=fN;
          end
          if(contains(folderContents(j).name,'passive') && ~isnan(fN))             
            fpeSeries(idxL)=fN;
          end
        end
      end
    end
    flSeries=fapSeries-fpeSeries;
    lceNSeries = lceNSeries(~isnan(flSeries));
    fpeSeries = fpeSeries(~isnan(flSeries));
    fapSeries = fapSeries(~isnan(flSeries));
    flSeries  = fapSeries-fpeSeries;

    if(~isempty(flSeries))
      figure(figImpedanceLengthIndividual);
      subplot('Position',reshape(subPlotPanelIndividual(i,1,:),1,4));    
        fill([lceNSeries(1),lceNSeries(end),fliplr(lceNSeries')],...
             [0,0,fliplr(flSeries')],...
             [1,1,1].*0.75,...
             'LineStyle','none');
        hold on;
        fill([lceNSeries(1),lceNSeries(end),fliplr(lceNSeries')],...
             [0,0,fliplr(fpeSeries')],...
             [1,1,1].*0.5,...
             'LineStyle','none');
        hold on;
      subplot('Position',reshape(subPlotPanelIndividual(i,2,:),1,4));  
        fill([lceNSeries(1),lceNSeries(end),fliplr(lceNSeries')],...
             [0,0,fliplr(flSeries')],...
             [1,1,1].*0.75,...
             'LineStyle','none');
        hold on;
        fill([lceNSeries(1),lceNSeries(end),fliplr(lceNSeries')],...
             [0,0,fliplr(fpeSeries')],...
             [1,1,1].*0.5,...
             'LineStyle','none');
        hold on;        
    end
    storageNormSSP    = [];
    lossNormSSP       = [];
    idxLengthPassive  = 0;

    for j=1:1:length(folderContents)
        if(~folderContents(j).isdir ...
                && contains(folderContents(j).name,'.json'))
  
            fprintf('\t%s\n',folderContents(j).name);

            dataStr =fileread(fullfile(expFolder,folderContents(j).name));
            dataJson=jsondecode(dataStr);

            idxL = nan;
            for k=1:1:length(impedanceData)
              if(contains(folderContents(j).name, impedanceData(k).normLengthStr))
                idxL=k;
              end
            end

            if(isfield(dataJson(segId).segment, hId))
              if(~isempty(dataJson(segId).segment.(hId).bandwidthHzC2) ...
                 && ~isempty(dataJson(segId).segment.(hId).idxBWC2) )
  
  
                idxBWC2 = dataJson(segId).segment.(hId).idxBWC2;

                nominalLength = ...
                  mean(dataJson(segId).segment.length(idxBWC2))./lopt;  

                storageNorm   = ...
                  dataJson(segId).segment.(hId).storage(idxBWC2)./storageLopt;

                lossNorm      = ...
                  dataJson(segId).segment.(hId).loss(idxBWC2)./lossLopt; 


                storageNormSS = getSummaryStatistics(storageNorm);
                lossNormSS    = getSummaryStatistics(lossNorm);
  
                storageNormSSPlot = [];
                lossNormSSPlot = [];
                
                lineColor = [];
                boxColor = [];
                if(contains(folderContents(j).name,'active'))
                  lineColor = [0,0,0];
                  boxColor  = [1,1,1];

                  if(~isempty(storageNormSSP) ...
                      && ~isempty(lossNormSSP) ...
                      && idxL == idxLengthPassive)
                    fieldsToSub = {'y','mean','median','std','min','max'};
                    storageNormSSPlot = storageNormSS;
                    lossNormSSPlot = lossNormSS;

                    for k=1:1:length(fieldsToSub)
                      storageNormSSPlot.(fieldsToSub{k}) ...
                        = storageNormSS.(fieldsToSub{k})...
                         -storageNormSSP.(fieldsToSub{k});
                      lossNormSSPlot.(fieldsToSub{k}) ...
                        = lossNormSS.(fieldsToSub{k}) ...
                         -lossNormSSP.(fieldsToSub{k});
                    end

                  else
                    storageNormSSPlot = storageNormSS;
                    lossNormSSPlot = lossNormSS;
                  end

                end
                if(contains(folderContents(j).name,'passive')) 
                  idxLengthPassive = idxL;
                  lineColor = [1,1,1].*0.25;
                  boxColor  = [1,1,1].*0.75;       
                  storageNormSSP=storageNormSS;
                  lossNormSSP=storageNormSS;
                  storageNormSSPlot = storageNormSS;
                  lossNormSSPlot = lossNormSS;
                end
                assert(~isempty(lineColor) || ~isempty(boxColor),...
                  'Error: trial is neither active nor passive');
  
  
                figure(figImpedanceLengthIndividual);
                subplot('Position',reshape(subPlotPanelIndividual(i,1,:),1,4));
                  success=plotBoxWhiskerData(nominalLength,storageNormSSPlot,...
                                             boxWidth,lineColor,boxColor);
                  hold on;
    
                  
                subplot('Position',reshape(subPlotPanelIndividual(i,2,:),1,4));
                  success=plotBoxWhiskerData(nominalLength,lossNormSSPlot,...
                                             boxWidth,lineColor,boxColor);
                  hold on;
              end
            end
              
        end
    end



        
end

figure(figImpedanceLengthIndividual);
for i = 1:1:length(experimentsToProcess)
  subplot('Position',reshape(subPlotPanelIndividual(i,1,:),1,4));
    box off;
    xlim([0.49,1.51]);
    xticks([0.55,0.70,0.85,1,1.15,1.30,1.45]);
    yticks([0:0.25:1.5]);
    ylim([-0.25,1.71]);
    xlabel('Norm. Length ($$\ell/\ell_o)$$');
    ylabel('Norm. Storage ($$k/k_o)$$');
    title(sprintf('%i. Normalized storage vs. length',i));
  
  subplot('Position',reshape(subPlotPanelIndividual(i,2,:),1,4));  
    box off;
    xlim([0.49,1.51]);
    xticks([0.55,0.70,0.85,1,1.15,1.30,1.45]);
    yticks([-0.25:0.25:1.5]);
    ylim([-0.25,1.71]);    
    xlabel('Norm. Length ($$\ell/\ell_o)$$');
    ylabel('Norm. Loss ($$\beta/\beta_o)$$');
    title(sprintf('%i. Normalized loss vs. length',i));
    
end



figure(figImpedanceLengthGroup);
subplot('Position',reshape(subPlotPanelGroup(1,1,:),1,4));

subplot('Position',reshape(subPlotPanelGroup(1,2,:),1,4));

    
outputPlotDir = fullfile(projectFolders.output_plots,outputFolder);
if(~exist(outputPlotDir))
    mkdir(outputPlotDir);
end

figImpedanceLengthIndividual=...
  configPlotExporter( figImpedanceLengthIndividual, ...
                      pageWidthIndividual, ...
                      pageHeightIndividual);

fileName =    ['fig_ImpedanceIndividual_segment_',num2str(segId)];

print('-dpdf', fullfile(outputPlotDir,[fileName,'.pdf']));    

saveas(figImpedanceLengthIndividual,...
       fullfile(outputPlotDir,[fileName,'.fig']));

close(figImpedanceLengthIndividual);
