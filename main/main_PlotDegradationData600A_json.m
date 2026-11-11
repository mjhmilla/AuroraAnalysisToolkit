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

experimentsToProcess = ...
    {'20251121_degradation_larb_4',...
     '20251114_degradation_larb_1',...
     '20251121_degradation_larb_3'};
% Fibre 2 (below) is so weak that Sven would have rejected it
% '20251119_degradation_larb_2'
%
outputFolder = 'degredation_larb';

flag_subtractReferenceForce=0;
timeUnit = 'ms';
ms2s = 0.001;

idxNorm=4;
idxSet=[1:7];

%%
% Plot configuration
%%
numberOfHorizontalPlotColumnsGeneric    = 2;
numberOfVerticalPlotRowsGeneric         = 2;

plotWidth                               = ones(1,numberOfHorizontalPlotColumnsGeneric).*5;
plotHeight                              = ones(numberOfVerticalPlotRowsGeneric,1).*5;
plotHorizMarginCm                       = 2;
plotVertMarginCm                        = 2;
baseFontSize                            = 10;

[subPlotPanelDegradation, pageWidthDegradation,pageHeightDegradation]= ...
  plotConfigGeneric(  numberOfHorizontalPlotColumnsGeneric,...
                      numberOfVerticalPlotRowsGeneric,...
                      plotWidth,...
                      plotHeight,...
                      plotHorizMarginCm,...
                      plotVertMarginCm,...
                      baseFontSize); 

figDegradation = figure;

degradationColors = [0,0,0;...
                     0.25,0.25,0.25;...
                     0.5,0.5,0.5;...
                     0.75,0.75,0.75];

fpreNormStd = zeros(length(experimentsToProcess),1);
fpreStd = zeros(length(experimentsToProcess),1);
maxIter = 0;
timeSeriesFiber=0;

iterationSet= zeros(length(experimentsToProcess),length(idxSet));
fpreNormSet = zeros(length(experimentsToProcess),length(idxSet));
fpreSet     = zeros(length(experimentsToProcess),length(idxSet));

for i = 1:1:length(experimentsToProcess)
    expFolder = fullfile(projectFolders.output600A,'json',...
                         experimentsToProcess{i});

    folderContents = dir(expFolder);
    
    iteration = [];
    fpre = [];

    iter=1;
    previousTemperature=nan;
    dataJsonFirst=[];

    numTrials=0;
    for j=1:1:length(folderContents)
        if(~folderContents(j).isdir ...
                && contains(folderContents(j).name,'.json'))
          numTrials=numTrials+1;
        end
    end
    trialCount=0;

    for j=1:1:length(folderContents)
        if(~folderContents(j).isdir ...
                && contains(folderContents(j).name,'.json') ...
                && trialCount < length(idxSet) )
            trialCount=trialCount+1;
            dataStr =fileread(fullfile(expFolder,folderContents(j).name));
            dataJson=jsondecode(dataStr);

            dataPath=projectFolders.data600A;
            for k=1:1:length(dataJson(1).segment.dataFile)
              dataPath = [dataPath,filesep,...
                          dataJson(1).segment.dataFile{k}];
            end
            flag_readHeader=1;
            auroraData = readAuroraData600A(dataPath,flag_readHeader);
            
            timeA=dataJson(1).segment.bias.time;
            timeB=dataJson(1).segment.pre.time(1);

            actTime = timeB-timeA;
            if(strcmp(timeUnit,'ms'))
              actTime = actTime.*ms2s;
            end

            fiso = dataJson(1).segment.pre.force(1);
            
            fprintf('(%i, %i). %1.2f s - %1.2f s\n',i,j,timeA*ms2s, timeB*ms2s);


            fpre = [fpre;fiso];
            iteration=[iteration;iter];
            iter=iter+1;

            if(isempty(dataJsonFirst))
                dataJsonFirst=dataJson;
            end

            if(isnan(previousTemperature))
                previousTemperature=dataJson(1).segment.summary.temperature.mean;
            end
            temperature = dataJson(1).segment.summary.temperature.mean;
            tempErr = abs(temperature-previousTemperature) ...
                      / (0.5*(temperature+previousTemperature));
            assert(tempErr < 0.05,...
                'Error: temperature varied by more than 5% between trials');

            if(i==1)
              subplot('Position',reshape(subPlotPanelDegradation(1,2,:),1,4));              
                colorA = [0,0,0];
                colorB = [0,0,1];
                if(~isempty(idxSet))
                  numTrials=length(idxSet);
                end
                nj=(trialCount-1)/(numTrials-1);
                lineColorj = colorA.*(1-nj) + colorB.*nj;
                
                idxAB = find(auroraData.Data.Time.Values >= timeA ...
                             & auroraData.Data.Time.Values <= timeB);



                plot( (auroraData.Data.Time.Values(idxAB)-timeA).*ms2s,...
                      auroraData.Data.Fin.Values(idxAB),...
                     '-',...
                     'Color',lineColorj,'LineWidth',0.5);
                hold on;
                xyEnd = [(auroraData.Data.Time.Values(idxAB(end))-timeA).*ms2s,...
                          auroraData.Data.Fin.Values(idxAB(end))];                  
                if(trialCount ==1)
                  text(xyEnd(1,1),xyEnd(1,2),...
                       sprintf('%i.',trialCount),...
                       'HorizontalAlignment','right',...
                       'VerticalAlignment','middle', ...
                       'FontSize',6);
                  hold on;
                end
                if(trialCount == numTrials)
                    text(xyEnd(1,1),xyEnd(1,2),...
                       sprintf('%i.',trialCount),...
                       'HorizontalAlignment','right',...
                       'VerticalAlignment','middle', ...
                       'FontSize',6);
                  hold on;

                  %plot([1,1].*timeB*ms2s,[0,0.9],...
                  %     '-','Color',[1,1,1],'LineWidth',2);
                  %hold on;
                  plot([1,1].*(timeB-timeA)*ms2s,[0.4,0.6],...
                      '-','Color',[0,0,0],'LineWidth',1);
                  hold on;
                


                  text((timeB-timeA)*ms2s,0.4,sprintf(['Sample time for %s after',...
                    ' \n%1.1f s of activation'],'$$f_o^i$$',actTime),...
                    'HorizontalAlignment','right',...
                    'VerticalAlignment','top',...
                    'FontSize',6);
                  hold on;                  
                end
                timeSeriesFiber=i;

            end
        end
    end
    if(length(fpre)>maxIter)
      maxIter=length(fpre);
    end

    n = (i-1)/(length(experimentsToProcess)-1);
    lineColor = degradationColors(i,:);%colorA.*(1-n)+colorB.*n;
    
    fpreNorm = fpre ./ (fpre(idxNorm,1));

    figure(figDegradation);

    idxIteration=[1:1:length(iteration)];
    if(~isempty(idxSet))
      idxIteration=[idxSet];
    end

    iterationSet(i,:)=iteration(idxIteration);
    fpreNormSet(i,:) =fpreNorm(idxIteration);
    fpreSet(i,:)=fpre(idxIteration);

    subplot('Position',reshape(subPlotPanelDegradation(1,1,:),1,4));
        plot(iteration(idxIteration),...
             fpreNorm(idxIteration),'-','Color',lineColor,'LineWidth',0.5);
        hold on;
        plot(iteration(idxIteration),...
             fpreNorm(idxIteration),'o','Color',[1,1,1],...
            'MarkerSize',2,...
            'MarkerFaceColor',lineColor,...
            'LineWidth',0.5);
        hold on;
        
        fpreNormStd(i,1) = std(fpreNorm(idxIteration));

        text( iteration(idxIteration(1)),fpreNorm(idxIteration(1)),...
              sprintf('%i.',i),...
              'HorizontalAlignment','right',...
              'VerticalAlignment','middle',...
              'FontSize',6,...
              'Rotation',0);

        if(i==1)
%           text(1.8, 0.55,sprintf('Range of %s','$$f_i/f_1$$'),...
%                     'HorizontalAlignment','left',...
%                     'VerticalAlignment','bottom',...
%                     'FontSize',6,...
%                     'Rotation',0);

          text(1.8, 0.25,sprintf('Values of %s','$$f_o^4$$'),...
                    'HorizontalAlignment','left',...
                    'VerticalAlignment','bottom',...
                    'FontSize',6,...
                    'Rotation',0);
          
        end
%         text(2,0.50-(i-1)*0.05,...
%             sprintf('%i. %1.1f-%1.1f %s',...
%                      i,...
%                      min(fpreNorm(idxIteration))*100,...
%                      max(fpreNorm(idxIteration))*100,...
%                      '\%'),...
%                     'HorizontalAlignment','left',...
%                     'VerticalAlignment','bottom',...
%                     'FontSize',6,...
%                     'Rotation',0);

        text(2,0.20-(i-1)*0.05,...
            sprintf('%i. %1.3f mN',...
                     i,fpre(idxNorm,1)),...
                    'HorizontalAlignment','left',...
                    'VerticalAlignment','bottom',...
                    'FontSize',6,...
                    'Rotation',0);


    subplot('Position',reshape(subPlotPanelDegradation(2,1,:),1,4));
        plot(iteration(idxIteration),...
             fpre(idxIteration),'-','Color',lineColor,'LineWidth',0.5);
        hold on;
        plot(iteration(idxIteration),...
             fpre(idxIteration),'o','Color',[1,1,1],...
            'MarkerFaceColor',lineColor,...
            'MarkerSize',2,...            
            'LineWidth',0.5);
        hold on;

        fpreStd(i,1) = std(fpre(idxIteration(end)));
        
        text(iteration(idxIteration(end)),...
             fpre(idxIteration(end)),...
            sprintf('%i.',i),...
             'HorizontalAlignment','right',...
             'VerticalAlignment','middle',...
            'FontSize',6,...
            'Rotation',0);

        text(2,0.6-((i-1)*0.05*(0.75/1.1)),...
            sprintf('%i. %1.2f-%1.2f mN',...
            i,min(fpre(idxIteration)),max(fpre(idxIteration))),...
                    'HorizontalAlignment','left',...
                    'VerticalAlignment','bottom',...
                    'FontSize',6,...
                    'Rotation',0);

        
end



figure(figDegradation);
subplot('Position',reshape(subPlotPanelDegradation(1,1,:),1,4));
    

    axis tight;
    xlimits=xlim;
    ylimits=ylim;
    xDelta = 0.5;    
    yDelta = 0.1;
    xlim([xlimits(1)-xDelta,xlimits(2)+xDelta]);
    ylim([0,1.3]);

 
    xticks([1:maxIter]);
    
    hold on;        
    box off;
  
    dy=0.05;
    y0=0.85;
    y1=y0-dy;
    y2=y1-2*dy;
    y3=y2-dy;

    for i=1:1:size(iterationSet,2)
      if(i==1)
        text(iterationSet(1,i),y0,'Max. Abs Error',...
          'HorizontalAlignment','left',...
          'VerticalAlignment','top',...
          'FontSize',6);
        hold on;
        text(iterationSet(1,i),y2,'Avg. Abs Error',...
          'HorizontalAlignment','left',...
          'VerticalAlignment','top',...
          'FontSize',6);
        hold on;
        
      end

      txt=sprintf('%1.1f%s',max(abs(fpreNormSet(:,i)-1))*100,'\%');
      text(iterationSet(1,i),y1,txt,...
        'HorizontalAlignment','center',...
        'VerticalAlignment','top',...
        'FontSize',6);
      hold on;
      txt=sprintf('%1.1f%s',mean(abs(fpreNormSet(:,i)-1))*100,'\%');
      text(iterationSet(1,i),y3,txt,...
        'HorizontalAlignment','center',...
        'VerticalAlignment','top',...
        'FontSize',6);
      hold on;        

    end

    dfpreNormSet= fpreNormSet(:,2:end)-fpreNormSet(:,1:(end-1));
    dy=0.05;
    y0=0.25;
    text(5,y0,'Trial-to-trial error',...
      'HorizontalAlignment','left',...
      'VerticalAlignment','bottom',...
      'FontSize',6);
    text(5,y0-1*dy,'Max. Abs. Error',...
      'HorizontalAlignment','left',...
      'VerticalAlignment','bottom',...
      'FontSize',6);
    text(5.2,y0-2*dy,sprintf('%1.1f%s',max(abs(dfpreNormSet),[],'all')*100,'\%'),...
      'HorizontalAlignment','left',...
      'VerticalAlignment','bottom',...
      'FontSize',6);
    text(5,y0-3*dy,'Avg. Abs. Error',...
      'HorizontalAlignment','left',...
      'VerticalAlignment','bottom',...
      'FontSize',6);    
    text(5.2,y0-4*dy,sprintf('%1.1f%s',mean(abs(dfpreNormSet),'all')*100,'\%'),...
      'HorizontalAlignment','left',...
      'VerticalAlignment','bottom',...
      'FontSize',6);

    hold on;

    xlabel('Trial Number');
    ylabel('Norm. Force ($f_o^i / f_o^4)$');
    title({sprintf('A. Normalized isometric force after repeated'),...
           sprintf('perturbation trials at %s and %1.0f %s',...
                  '$$\ell_o$$',...
                  dataJsonFirst(1).segment.summary.temperature.mean,...
                  dataJsonFirst(1).segment.unit.temperature)});

subplot('Position',reshape(subPlotPanelDegradation(2,1,:),1,4));
    axis tight;
    xlimits=xlim;
    ylimits=ylim; 
    xDelta = diff(xlimits).*0.1;    
    yDelta = diff(ylimits).*0.1;
    ylim([0,ylimits(1,2)+yDelta]);

    xlimits=xlim;
    ylimits=ylim; 
    xDelta = diff(xlimits).*0.1;    
    yDelta = diff(ylimits).*0.1;

    xticks([1:maxIter]);    

    hold on;
    box off;
    xlabel('Trial Number');
    ylabel(['Force (',dataJsonFirst(1).segment.unit.force,')']);
    title({sprintf('C. Isometric force after %1.1fs',actTime),...
           sprintf('of activation at %1.0f %s',...
                  dataJsonFirst(1).segment.summary.temperature.mean,...
                  dataJsonFirst(1).segment.unit.temperature)});
    
subplot('Position',reshape(subPlotPanelDegradation(1,2,:),1,4));
  axis tight;
  ylimits=ylim; 
  yDelta = diff(ylimits).*0.1;
  ylim([0,ylimits(1,2)+yDelta]);
  
  box off;
  xlabel('Time (s)');
  ylabel('Force (mN)');
    title({sprintf('B. Example time-series data from fiber %i',timeSeriesFiber),''});  

outputPlotDir = fullfile(projectFolders.output600A_plots,outputFolder);
if(~exist(outputPlotDir))
    mkdir(outputPlotDir);
end

figDegradation=configPlotExporter(figDegradation, ...
                    pageWidthDegradation, pageHeightDegradation);
fileName =    ['fig_Degradation'];
if(flag_subtractReferenceForce==1)
    fileName =    [fileName,'_RelativeToForceReference'];
end
print('-dpdf', fullfile(outputPlotDir,[fileName,'.pdf']));    
saveas(figDegradation,fullfile(outputPlotDir,[fileName,'.fig']));
close(figDegradation);
