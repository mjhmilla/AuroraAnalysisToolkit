function figH =...
        addEMC2025ImpedanceInputDataPlot600A(figH,...
        subPlotPanel, subPlotRow, subPlotCol,...
        configPlotItem, timeVec, xData, yData,plotProperties)

figure(figH);

subPlotH = subplot('Position', ...
            reshape(subPlotPanel(subPlotRow, ...
                                 subPlotCol,:),1,4)); 

yyaxis left;
ax = gca;
ax.YColor = configPlotItem.yyLeftRightAxisColor(1,:);            
plot(timeVec,...
     xData,...
     '-','Color',configPlotItem.impedance.xColor,...
     'LineWidth',configPlotItem.lineWidth);
hold on;   
xlabel('Time (s)');
ylabel(['Length ',plotProperties.unitXImp]);
axis tight;

yyaxis right;
ax = gca;
ax.YColor = configPlotItem.yyLeftRightAxisColor(2,:);            
plot(timeVec,...
     yData,...
     '-','Color',configPlotItem.impedance.yColor,...
     'LineWidth',configPlotItem.lineWidth);
hold on;   
xlabel('Time (s)');
ylabel(['Force ',plotProperties.unitYImp]);
box off;
axis tight;

title([configPlotItem.title]);