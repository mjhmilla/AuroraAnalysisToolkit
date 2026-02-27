function success=plotBoxWhiskerData(x,ySummaryStatistics, ...
                            boxWidth,lineColor,boxColor)

              
p = [0.01,0.05,0.25,0.5,0.75,0.95,0.99];

for i=1:1:length(p)
  assert(abs(ySummaryStatistics.x(1,i)-p(1,i))<sqrt(eps),...
             'Error: ySummaryStatistics.x has changed');
end

y05 = ySummaryStatistics.y(1,2);
y25 = ySummaryStatistics.y(1,3);
y50 = ySummaryStatistics.y(1,4);
y75 = ySummaryStatistics.y(1,5);
y95 = ySummaryStatistics.y(1,6);


box = [ x+boxWidth*0.5, y25;...
        x+boxWidth*0.5, y75;... 
        x-boxWidth*0.5, y75;... 
        x-boxWidth*0.5, y25;... 
        x+boxWidth*0.5, y25];

plot([x;x],[y05;y95],'-','Color',lineColor);
hold on;

fill(box(:,1),box(:,2),boxColor,'EdgeColor',lineColor);
hold on;

plot([x-0.5*boxWidth;x+0.5*boxWidth],...
     [             y50; y50        ],...
     '-','Color',lineColor);
hold on;

plot([x-0.5*boxWidth; x+0.5*boxWidth],...
     [           y95; y95           ],...
     '-','Color',lineColor);
hold on;

plot([x-0.5*boxWidth; x+0.5*boxWidth],...
     [           y05; y05           ],...
     '-','Color',lineColor);
hold on;

success=1;
