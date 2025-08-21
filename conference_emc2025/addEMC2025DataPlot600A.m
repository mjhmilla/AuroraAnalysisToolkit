function [figH, plotProperties]=...
        addEMC2025DataPlot600A(figH, subPlotPanel, subPlotRow, subPlotCol,...
                    configPlotItem, trialData600A, fiberProperties)

figure(figH);


%length
subPlotH = subplot('Position', ...
            reshape(subPlotPanel(subPlotRow,subPlotCol,:),1,4)); 

xField = configPlotItem.xField;
yField = configPlotItem.yField;

scaleY = 1;
unitY = trialData600A.Data.(yField).Unit;
if(strcmp('Lin',yField))
    scaleY = (1/fiberProperties.lceOptMM);
    unitY = '$$\ell_o$$';
end
if(strcmp('Fin',yField))
    scaleY = (1/fiberProperties.fmax);
    unitY = '$$f_o$$';
end        


scaleX = 1;
unitX = trialData600A.Data.(xField).Unit;
if(strcmp(trialData600A.Data.Time.Unit,'ms'))
    scaleX = 0.001;
    unitX = 's';
end

idxA = 1;
idxB = length(trialData600A.Data.(xField).Values);
indexDataInterval=[idxA,idxB];

if(isempty(configPlotItem.timeInterval)==0)
    indexDataInterval = ...
        getIndexInterval600A(trialData600A.Data.Time.Values,...
                        configPlotItem.timeInterval);
    idxA = indexDataInterval(1);
    idxB = indexDataInterval(2);
end

if(strcmp(configPlotItem.yyLeftRight,'yyaxis left'))
    yyaxis left;
    ax = gca;
    if(isempty(configPlotItem.yyLeftRightAxisColor)==0)
        ax.YColor = configPlotItem.yyLeftRightAxisColor(1,:);
    end
end
if(strcmp(configPlotItem.yyLeftRight,'yyaxis right'))
    yyaxis right;
    if(isempty(configPlotItem.yyLeftRightAxisColor)==0)
        ax.YColor = configPlotItem.yyLeftRightAxisColor(2,:);
    end         
end


plot(trialData600A.Data.(xField).Values(idxA:idxB,1).*scaleX,...
     trialData600A.Data.(yField).Values(idxA:idxB,1).*scaleY,...
     '-','Color',configPlotItem.lineColor,...
     'LineWidth',configPlotItem.lineWidth);
hold on;

if(isempty(configPlotItem.boxTimes)==0)
    for k=1:1:size(configPlotItem.boxTimes,1)
        indexBoxInterval = getIndexInterval600A(...
                            trialData600A.Data.Time.Values,...
                            configPlotItem.boxTimes(k,:));
        idxA = indexBoxInterval(1,1);
        idxB = indexBoxInterval(1,2);
        boxXMin = min(trialData600A.Data.(xField).Values(idxA,1).*scaleX);
        boxXMax = max(trialData600A.Data.(xField).Values(idxB,1).*scaleX);
        
        boxYMin = min(trialData600A.Data.(yField).Values(idxA:idxB,1).*scaleY);
        boxYMax = max(trialData600A.Data.(yField).Values(idxA:idxB,1).*scaleY);

        boxYDelta = (boxYMax-boxYMin)*0.05;
        boxYMin = boxYMin-boxYDelta;
        boxYMax = boxYMax+boxYDelta;

        plot([boxXMin,boxXMax,boxXMax,boxXMin,boxXMin],...
             [boxYMin,boxYMin,boxYMax,boxYMax,boxYMin],...
             '-','Color',configPlotItem.boxColors(k,:));
        hold on;
        text((boxXMax+boxXMin)*0.5,boxYMax,num2str(k),...
            'FontSize',8,...
            'VerticalAlignment','bottom',...
            'HorizontalAlignment','center');
        hold on;
    end
end


box off;

axis tight;


xlabel([configPlotItem.xLabel, '(',unitX,')']);
ylabel([configPlotItem.yLabel, '(',unitY,')']);
title(configPlotItem.title);

plotProperties.scaleX=scaleX;
plotProperties.scaleY=scaleY;
plotProperties.indexDataInterval=indexDataInterval;
