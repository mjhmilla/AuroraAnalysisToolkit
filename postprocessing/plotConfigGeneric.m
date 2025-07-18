%%
% SPDX-FileCopyrightText: 2024 Matthew Millard <millard.matthew@gmail.com>
%
% SPDX-License-Identifier: MIT
%%
function [subPlotPanel,pageWidth,pageHeight]  = ...
    plotConfigGeneric(numberOfHorizontalPlotColumns, ...
                      numberOfVerticalPlotRows,...
                      plotWidth,...
                      plotHeight,...
                      plotHorizMarginCm,...
                      plotVertMarginCm,...
                      baseFontSize)

pageWidth = plotHorizMarginCm;
for i=1:1:numberOfHorizontalPlotColumns
    pageWidth   = pageWidth ...
                    + plotWidth(1,i)+plotHorizMarginCm;
end
pageWidth = pageWidth +plotHorizMarginCm;

pageHeight = plotVertMarginCm;
for i=1:1:numberOfVerticalPlotRows
    pageHeight   = pageHeight ...
                    + plotHeight(i,1)+plotVertMarginCm;
end
pageHeight = pageHeight +plotVertMarginCm;


plotWidthNorm  = plotWidth./pageWidth;
plotHeightNorm = plotHeight./pageHeight;

plotHorizMargin = plotHorizMarginCm/pageWidth;
plotVertMargin  = plotVertMarginCm/pageHeight;

topLeft = [0/pageWidth pageHeight/pageHeight];

subPlotPanel=zeros(numberOfVerticalPlotRows,numberOfHorizontalPlotColumns,4);
subPlotPanelIndex = zeros(numberOfVerticalPlotRows,numberOfHorizontalPlotColumns);



idx=1;
for ai=1:1:numberOfVerticalPlotRows
  vertOffset=0;
  if(ai > 1)
      for i=1:1:(ai-1)
        vertOffset=vertOffset+ plotHeightNorm(i,1) + plotVertMargin;
      end
  end

  for aj=1:1:numberOfHorizontalPlotColumns

      horizOffset=0;
      if(aj > 1)
          for i=1:1:(aj-1)
            horizOffset=horizOffset+ plotWidthNorm(1,i) + plotHorizMargin;
          end
      end

      subPlotPanelIndex(ai,aj) = idx;
      subPlotPanel(ai,aj,1) = topLeft(1) + plotHorizMargin...
                            + horizOffset;
      %-plotVertMargin*scaleVerticalMargin ...                             
      subPlotPanel(ai,aj,2) = topLeft(2) - vertOffset;
      subPlotPanel(ai,aj,3) = (plotWidthNorm(1,aj));
      subPlotPanel(ai,aj,4) = (plotHeightNorm(ai,1));
      idx=idx+1;
  end
end


plotFontName = 'latex';

set(groot, 'defaultAxesFontSize',baseFontSize);
set(groot, 'defaultTextFontSize',baseFontSize);
set(groot, 'defaultAxesLabelFontSizeMultiplier',1.1);
set(groot, 'defaultAxesTitleFontSizeMultiplier',1.1);
set(groot, 'defaultAxesTickLabelInterpreter','latex');
%set(groot, 'defaultAxesFontName',plotFontName);
%set(groot, 'defaultTextFontName',plotFontName);
set(groot, 'defaultLegendInterpreter','latex');
set(groot, 'defaultTextInterpreter','latex');
set(groot, 'defaultAxesTitleFontWeight','normal');  
set(groot, 'defaultFigurePaperUnits','centimeters');
set(groot, 'defaultFigurePaperSize',[pageWidth pageHeight]);
set(groot,'defaultFigurePaperType','A4');


