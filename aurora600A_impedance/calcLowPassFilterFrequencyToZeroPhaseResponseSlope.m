function fittingResults=calcLowPassFilterFrequencyToZeroPhaseResponseSlope(...
                            modelParams,...
                            expResponse,...
                            filterFrequencyHzDeltaMax,...
                            fittingBandwidth,...
                            numberOfIterations,...
                            flag_plotFinalFit)



omegaHzBest=nan;

xLsqBest=[];
Hbest=[];
errorBest   = inf;
omegaHzBest = modelParams.delayFilterFrequencyHz;

signOfDelta = [1;-1];

indexFit = find(  expResponse.frequencyHz >= fittingBandwidth(1,1) ...
                & expResponse.frequencyHz <= fittingBandwidth(1,2));

for i=1:1:numberOfIterations
    jMax = 2;
    if(i==1)
        deltaMag = 0;
        jMax = 1;
    end
    if(i==2)
        deltaMag = filterFrequencyHzDeltaMax;
    end

    for j=1:1:jMax
        omega   = (omegaHzBest + deltaMag*signOfDelta(j,1)).*(2*pi);        
        lpfInv  = ((omega + complex(0,1).*expResponse.frequency(indexFit))./omega);
        H       = lpfInv.*expResponse.H(indexFit);
        phase   = angle(H);
    
        A    = [expResponse.frequencyHz(indexFit),ones(size(indexFit))];
        xLsq = (A'*A)\(A'*phase);

        phaseSlopeError = abs(xLsq(1,1));

        if(phaseSlopeError < errorBest)
            errorBest=phaseSlopeError;
            omegaHzBest = omega/(2*pi);
            lpfInvBest=lpfInv;
            Hbest=H;
            xLsqBest=xLsq;
        end
    end
    deltaMag = deltaMag*0.5;
end

fittingResults.filterFrequencyHz    = omegaHzBest;
fittingResults.inverseLowPassFilter = lpfInvBest;



if(flag_plotFinalFit==1)
    figTest=figure;

    phaseLsq = [expResponse.frequencyHz(indexFit),ones(size(indexFit))]*xLsqBest;

    subplot(1,2,1);
        plot(expResponse.frequencyHz(indexFit),...
             abs(expResponse.H(indexFit)),'-','Color',[1,1,1].*0.5);
        hold on;
        plot(expResponse.frequencyHz(indexFit),...
             abs(Hbest),'-','Color',[0,0,1]);
        box off;
        xlabel('Frequency (Hz)');
        ylabel('Gain (mN/mm)');
    subplot(1,2,2);
        plot(expResponse.frequencyHz(indexFit),...
             angle(expResponse.H(indexFit)).*(180/pi),'-','Color',[1,1,1].*0.5);
        hold on;
        plot(expResponse.frequencyHz(indexFit),...
             phaseLsq.*(180/pi),'-','Color',[1,0,0]);
        hold on;        
        plot(expResponse.frequencyHz(indexFit),...
             angle(Hbest).*(180/pi),'-','Color',[0,0,1]);
        box off;

        xlabel('Frequency (Hz)');
        ylabel('Phase (degrees)');
    here=1;
end

