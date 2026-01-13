function delayBest = calcDelayToZeroPhaseResponseSlope(...
                        modelParams,...
                        expData,...
                        delayDeltaMax,...
                        fittingBandwidth,...
                        numberOfIterations)




signOfDelta = [1;-1];

errorBest = inf;
delayBest = modelParams.delay;

frequencyLB = fittingBandwidth(1,1);
frequencyUB = fittingBandwidth(1,2);
npts = 100;

freqHz = [0:(1/(npts-1)):1]' .* (frequencyUB-frequencyLB) + frequencyLB;


for i=1:1:numberOfIterations

    jMax = 2;

    if(i==1)
        deltaMag = 0;
        jMax = 1;
    end
    if(i==2)
        deltaMag = delayDeltaMax;        
    end

    for j=1:1:jMax
        delta = delayBest + deltaMag*signOfDelta(j,1);
        timeDelayedVec  = expData.time + delta;
        
        yDelayed        = interp1(  expData.time, ...
                                    expData.y,...
                                    timeDelayedVec,...
                                    'linear','extrap');
        
        expResponse = evaluateGainPhaseCoherenceSq(  ...
                            expData.x,...
                            yDelayed,...
                            expData.bandwidth,...
                            expData.sampleFrequency);  
                
        phaseExp = interp1(expResponse.frequencyHz,...
                          expResponse.phase,...
                          freqHz);
        
        A = [freqHz,ones(size(freqHz))];

        xExp = (A'*A)\(A'*phaseExp);
        
        phaseSlopeError = abs(xExp(1,1));

        if(phaseSlopeError < errorBest)
            errorBest = phaseSlopeError;            
            delayBest = delta;
        end


    end

    deltaMag = deltaMag*0.5;

end