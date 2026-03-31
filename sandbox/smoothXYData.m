function dataSmoothed=smoothXYData(xdata,ydata,smoothingZeroToOne,flagPlot)

smoothCoefficent = 0.01 + smoothingZeroToOne*0.98;
wn=1-smoothCoefficent;

[b,a]=butter(2,wn,'low');

npts = length(xdata)*5;

xSample = min(xdata) + [0:(1/(npts-1)):1]' .* (max(xdata)-min(xdata));
ySample = interp1(xdata,ydata,xSample,'linear','extrap');

ySampleSmoothed = filtfilt(b,a,ySample);

dataSmoothed = interp1(xSample,ySampleSmoothed, xdata);
n = sqrt(length(xdata))*0.5;
[p,S]=polyfit(xdata,ydata,n);
yPoly = polyval(p,xdata);

prevRMSE = 0;
deltaRMSEBest=0;
ySplineBest=[];
for j=1:1:6

    curveName = 'linear';
    if(j > 1)
        curveName='cubic';
    end

    dx = (max(xdata)-min(xdata))/j;
    xSeg = [0:dx:max(xdata)]';
    
    ySeg = interp1(xdata,ydata,xSeg);
    
    errVec = @(ySeg)interp1(xSeg,ySeg,xdata,curveName)-ydata;
    options=optimset('Display','off');
    [x,resnorm,residual,exitflag]=lsqnonlin(errVec,ySeg,[],[],options);
    
    splineRMSE = sqrt(mean(errVec(x).^2));
    deltaRMSE = 0;
    if(j > 1)
        deltaRMSE = splineRMSE-prevRMSE;
    end
    fprintf('%e\t%e\t%i\n',splineRMSE,deltaRMSE,j);
    ySpline= interp1(xSeg,x,xdata,curveName);
    prevRMSE = splineRMSE;

    if(deltaRMSEBest < abs(deltaRMSE))
        deltaRMSEBest = abs(deltaRMSE);
        ySplineBest=ySpline;
    end

end


if(flagPlot==1)
    figTestSmoothing=figure;
    plot(xdata,ydata,'-','Color',[1,1,1].*0.5,'LineWidth',2);
    hold on;
    plot(xSample,ySample,'-','Color',[1,1,1]);
    hold on;
    plot(xSample,ySampleSmoothed,'-','Color',[0,1,0]);
    hold on;
    plot(xdata,dataSmoothed,'-','Color',[0,0,1]);
    hold on;
    plot(xdata,yPoly,'-','Color',[1,0,0]);
    hold on;
    plot(xdata,ySplineBest,'-','Color',[0,0,0],'LineWidth',1,'LineStyle','--');
    hold on;

    xlabel('X');
    ylabel('Y');
    here=1;
end