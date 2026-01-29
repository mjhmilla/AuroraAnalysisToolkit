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
    {'20251114_degradation_larb_1',...
     '20251119_degradation_larb_2',...
     '20251121_degradation_larb_3',...
     '20251121_degradation_larb_4'};

outputFolder = 'degredation_larb';

flag_subtractReferenceForce=1;

%%
% Plot configuration
%%
numberOfHorizontalPlotColumnsGeneric    = 1;
numberOfVerticalPlotRowsGeneric         = 2;

plotWidth                               = ones(1,numberOfHorizontalPlotColumnsGeneric).*16;
plotHeight                              = ones(numberOfVerticalPlotRowsGeneric,1).*10;
plotHorizMarginCm                       = 3;
plotVertMarginCm                        = 2;
baseFontSize                            = 12;

[subPlotPanelDegradation, pageWidthDegradation,pageHeightDegradation]= ...
  plotConfigGeneric(  numberOfHorizontalPlotColumnsGeneric,...
                      numberOfVerticalPlotRowsGeneric,...
                      plotWidth,...
                      plotHeight,...
                      plotHorizMarginCm,...
                      plotVertMarginCm,...
                      baseFontSize); 

figDegradation = figure;

colorA = [0,0,0];
colorB = [1,1,1].*0.75;

fpreNormStd = zeros(length(experimentsToProcess),1);
fpreStd = zeros(length(experimentsToProcess),1);

for i = 1:1:length(experimentsToProcess)
    expFolder = fullfile(projectFolders.output,'json',...
                         experimentsToProcess{i});

    folderContents = dir(expFolder);
    
    iteration = [];
    fpre = [];
    iter=1;
    previousTemperature=nan;
    dataJsonFirst=[];

    for j=1:1:length(folderContents)
        if(~folderContents(j).isdir ...
                && contains(folderContents(j).name,'.json'))
            dataStr =fileread(fullfile(expFolder,folderContents(j).name));
            dataJson=jsondecode(dataStr);
            fiso = dataJson(1).segment.pre.force;
            if(flag_subtractReferenceForce==1)
                fiso=fiso-dataJson(1).segment.forceReference;
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
        end
    end

    n = (i-1)/(length(experimentsToProcess)-1);
    lineColor = colorA.*(1-n)+colorB.*n;
    
    fpreNorm = fpre ./ mean(fpre);

    figure(figDegradation);

    subplot('Position',reshape(subPlotPanelDegradation(1,1,:),1,4));
        plot(iteration,fpreNorm,'-','Color',lineColor,'LineWidth',1);
        hold on;
        plot(iteration,fpreNorm,'o','Color',[1,1,1],...
            'MarkerFaceColor',lineColor,'LineWidth',1);
        hold on;
        
        fpreNormStd(i,1) = std(fpreNorm);

        text(iteration(end),fpreNorm(end),...
            sprintf('%i. %s=%1.2e',i,'$$\sigma$$',fpreNormStd(i,1)),...
            'HorizontalAlignment','left','VerticalAlignment','bottom',...
            'FontSize',10,...
            'Rotation',45);


    subplot('Position',reshape(subPlotPanelDegradation(2,1,:),1,4));
        plot(iteration,fpre,'-','Color',lineColor,'LineWidth',1);
        hold on;
        plot(iteration,fpre,'o','Color',[1,1,1],...
            'MarkerFaceColor',lineColor,'LineWidth',1);
        hold on;

        fpreStd(i,1) = std(fpre);
        
        text(iteration(end),fpre(end),...
            sprintf('%i. %s=%1.2e',i,'$$\sigma$$',fpreStd(i,1)),...
             'HorizontalAlignment','left','VerticalAlignment','bottom',...
            'FontSize',10,...
            'Rotation',45);

        
end



figure(figDegradation);
subplot('Position',reshape(subPlotPanelDegradation(1,1,:),1,4));
    axis tight;
    xlimits=xlim;
    ylimits=ylim;
    xDelta = diff(xlimits).*0.1;    
    yDelta = diff(ylimits).*0.1;
    ylim([ylimits(1,1),ylimits(1,2)+yDelta]);

    xlimits=xlim;
    ylimits=ylim; 
    xDelta = diff(xlimits).*0.1;    
    yDelta = diff(ylimits).*0.1;

    text(xlimits(1,2),ylimits(1,2)-0.5*yDelta,...
        sprintf('%1.1f%s\n%s=%1.2e',dataJsonFirst(1).segment.summary.temperature.mean,...
                          dataJsonFirst(1).segment.unit.temperature,...
                          '$$\mu(\sigma)$$',mean(fpreNormStd)),...
        'HorizontalAlignment','left',...
        'VerticalAlignment','bottom',...
        'FontSize',12);
    hold on;        
    box off;

    xlabel('Trial Number');
    ylabel('Norm. Force ($f_i / \overline{f})$');
    title('A. Normalized Isometric before 1$^{st}$ perturbation');

subplot('Position',reshape(subPlotPanelDegradation(2,1,:),1,4));
    axis tight;
    xlimits=xlim;
    ylimits=ylim; 
    xDelta = diff(xlimits).*0.1;    
    yDelta = diff(ylimits).*0.1;
    ylim([ylimits(1,1),ylimits(1,2)+yDelta]);

    xlimits=xlim;
    ylimits=ylim; 
    xDelta = diff(xlimits).*0.1;    
    yDelta = diff(ylimits).*0.1;

    text(xlimits(1,2),ylimits(1,2)-0.5*yDelta,...
        sprintf('%1.1f%s\n%s=%1.2e',dataJsonFirst(1).segment.summary.temperature.mean,...
                          dataJsonFirst(1).segment.unit.temperature,...
                          '$$\mu(\sigma)$$',mean(fpreStd)),...
        'HorizontalAlignment','left',...
        'VerticalAlignment','bottom',...
        'FontSize',12);
    hold on;
    box off;
    xlabel('Trial Number');
    ylabel(['Force (',dataJsonFirst(1).segment.unit.force,')']);
    title('B. Isometric force before 1$^{st}$ perturbation');
    
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
