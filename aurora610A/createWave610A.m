function waveSample = createWave610A(argsVec, timeSample,params)

frequencyHz=argsVec(1);
amplitude  =argsVec(2);
meanValue  =argsVec(3);
timeOffset =argsVec(4);


period = 1/frequencyHz;
cycles = params.cycles;

switch params.type

  case 'Sine Wave'
    waveSample = meanValue ...
      + sin((timeSample-timeOffset).*(frequencyHz*2*pi)).*amplitude;
    
    waveSample(timeSample <= timeOffset) = meanValue;
    waveSample(timeSample >= (cycles*period+timeOffset)) = meanValue;
  case 'Ramp Wave'
    assert(abs(cycles-1)<(eps*100));

    rampTime =[0;(0.125);(0.375);(0.625);(0.875);(1)];
    rampTime = rampTime .* period;

    rampValue=[0;amplitude;amplitude;...
                -amplitude;-amplitude;...
                 0];

    rampValue = rampValue+meanValue;

    if(abs(timeOffset)>eps)
      rampTime = rampTime+timeOffset;
      rampTime = [0;rampTime];
      rampValue = [meanValue;rampValue];
    end

    if(rampTime(end)<timeSample(end))
      rampTime = [rampTime;timeSample(end)];
      rampValue =[rampValue;meanValue];        
    end

    waveSample=interp1(rampTime,rampValue,timeSample);

  case 'Step Wave'
    assert(abs(cycles-1)<(eps*100));
    stepTime =[0;0.005;0.495;0.505;0.995;1];
    stepTime = stepTime .* period;

    stepValue=[0;amplitude;amplitude;...
                -amplitude;-amplitude;...
                 0];

    stepValue = stepValue+meanValue;

    if(abs(timeOffset)>eps)
      stepTime = stepTime+timeOffset;
      stepTime = [0;stepTime];
      stepValue = [meanValue;stepValue];
    end

    if(stepTime(end)<timeSample(end))
      stepTime = [stepTime;timeSample(end)];
      stepValue =[stepValue;meanValue];        
    end

    waveSample=interp1(stepTime,stepValue,timeSample);    
    
  otherwise assert(0,'Error: unrecognized wave type');
end