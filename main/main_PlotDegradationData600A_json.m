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
     '20251121_degradation_larb_3',...
     '20251119_degradation_larb_2'};

outputFolder = 'degredation_larb';

flag_subtractReferenceForce=1;
timeUnit = 'ms';

%%
% Plot configuration
%%
numberOfHorizontalPlotColumnsGeneric    = 2;
numberOfVerticalPlotRowsGeneric         = 2;

plotWidth                               = ones(1,numberOfHorizontalPlotColumnsGeneric).*6;
plotHeight                              = ones(numberOfVerticalPlotRowsGeneric,1).*6;
plotHorizMarginCm                       = 2;
plotVertMarginCm                        = 2.5;
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
actTime = [];
timeSeriesFiber=0;

for i = 1:1:length(experimentsToProcess)
    expFolder = fullfile(projectFolders.output,'json',...
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
                && contains(folderContents(j).name,'.json'))
            trialCount=trialCount+1;
            dataStr =fileread(fullfile(expFolder,folderContents(j).name));
            dataJson=jsondecode(dataStr);

            tdur = dataJson(1).segment.pre.time(end) ...
                  -dataJson(1).segment.pre.time(1);
            if(strcmp(timeUnit,'ms'))
              tdur = tdur.*0.001;
            end

            fiso = dataJson(1).segment.pre.force(end);
            if(flag_subtractReferenceForce==1)
                fiso=fiso-dataJson(1).segment.forceReference;
            end
            
            if(isempty(actTime))
              actTime=tdur;
            end
            if(abs(actTime-tdur) > 1)
              fprintf('(%i, %i). %1.2f s - %1.2f s\n',i,j,tdur, actTime);
            end


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
              subplot('Position',reshape(subPlotPanelDegradation(2,1,:),1,4));              
                colorA = [0,0,0];
                colorB = [0,0,1];
                nj=(trialCount-1)/(numTrials-1);
                lineColorj = colorA.*(1-nj) + colorB.*nj;
                if(flag_subtractReferenceForce==1)
                  plot( (dataJson(1).segment.pre.time...
                        -dataJson(1).segment.pre.time(1)).*0.001,...
                        dataJson(1).segment.pre.force...
                       -dataJson(1).segment.forceReference,...
                       '-',...
                       'Color',lineColorj,'LineWidth',0.5);
                  hold on;
                  xyEnd = [(dataJson(1).segment.pre.time(end)...
                            -dataJson(1).segment.pre.time(1)).*0.001,...
                            dataJson(1).segment.pre.force(end)...
                            -dataJson(1).segment.forceReference];
                else
                  plot( (dataJson(1).segment.pre.time ...
                         -dataJson(1).segment.pre.time(1)).*0.001,...
                        dataJson(1).segment.pre.force,...
                       '-',...
                       'Color',lineColorj,'LineWidth',0.5);
                  hold on;
                  xyEnd = [(dataJson(1).segment.pre.time(end)...
                            -dataJson(1).segment.pre.time(1)).*0.001,...
                            dataJson(1).segment.pre.force(end)];                  
                end
                if(trialCount ==1)
                  text(xyEnd(1,1),xyEnd(1,2),...
                       sprintf('%i.',trialCount),...
                       'HorizontalAlignment','right',...
                       'VerticalAlignment','bottom', ...
                       'FontSize',6);
                  hold on;
                end
                if(trialCount == numTrials)
                    text(xyEnd(1,1),xyEnd(1,2),...
                       sprintf('%i.',trialCount),...
                       'HorizontalAlignment','right',...
                       'VerticalAlignment','top', ...
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
    
    fpreNorm = fpre ./ (fpre(1,1));

    figure(figDegradation);

    subplot('Position',reshape(subPlotPanelDegradation(1,1,:),1,4));
        plot(iteration,fpreNorm,'-','Color',lineColor,'LineWidth',0.5);
        hold on;
        plot(iteration,fpreNorm,'o','Color',[1,1,1],...
            'MarkerSize',2,...
            'MarkerFaceColor',lineColor,...
            'LineWidth',0.5);
        hold on;
        
        fpreNormStd(i,1) = std(fpreNorm);

        text( iteration(end),fpreNorm(end),...
              sprintf('%i.',i),...
              'HorizontalAlignment','left',...
              'VerticalAlignment','bottom',...
              'FontSize',6,...
              'Rotation',0);

        text(2,0.8-(i-1)*0.05,...
            sprintf('%i. %1.1f-%1.1f %s',...
                     i,...
                     min(fpreNorm)*100,...
                     max(fpreNorm)*100,...
                     '\%'),...
                    'HorizontalAlignment','left',...
                    'VerticalAlignment','bottom',...
                    'FontSize',6,...
                    'Rotation',0);


    subplot('Position',reshape(subPlotPanelDegradation(1,2,:),1,4));
        plot(iteration,fpre,'-','Color',lineColor,'LineWidth',0.5);
        hold on;
        plot(iteration,fpre,'o','Color',[1,1,1],...
            'MarkerFaceColor',lineColor,...
            'MarkerSize',2,...            
            'LineWidth',0.5);
        hold on;

        fpreStd(i,1) = std(fpre);
        
        text(iteration(end),fpre(end),...
            sprintf('%i.',i),...
             'HorizontalAlignment','right',...
             'VerticalAlignment','top',...
            'FontSize',6,...
            'Rotation',0);

        text(2,0.6-((i-1)*0.05*(0.75/1.1)),...
            sprintf('%i. %1.2f-%1.2f mN',i,min(fpre),max(fpre)),...
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
    ylabel('Norm. Force ($f_i / f_1)$');
    title({sprintf('A. Norm. Isometric force after %1.1fs',actTime),...
           sprintf('of activation at %1.0f %s',...
                  dataJsonFirst(1).segment.summary.temperature.mean,...
                  dataJsonFirst(1).segment.unit.temperature)});

subplot('Position',reshape(subPlotPanelDegradation(1,2,:),1,4));
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
    title({sprintf('B. Isometric force after %1.1fs',actTime),...
           sprintf('of activation at %1.0f %s',...
                  dataJsonFirst(1).segment.summary.temperature.mean,...
                  dataJsonFirst(1).segment.unit.temperature)});
    
subplot('Position',reshape(subPlotPanelDegradation(2,1,:),1,4));
  axis tight;
  ylimits=ylim; 
  yDelta = diff(ylimits).*0.1;
  ylim([0,ylimits(1,2)+yDelta]);

  box off;
  xlabel('Time (s)');
  ylabel('Force (mN)');
    title({'C. Example time-series data',...
           sprintf('from fiber %i',timeSeriesFiber)});  

outputPlotDir = fullfile(projectFolders.output_plots,outputFolder);
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
