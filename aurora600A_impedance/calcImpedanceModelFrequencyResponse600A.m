function modelResponse = calcImpedanceModelFrequencyResponse600A(params)


%
% Time domain signal
%
switch params.type
    case 0
        y = params.k.*params.x + params.beta.*params.xdot;
    case 1
        assert(0,'Error: model type not yet implemented');
        
    otherwise
        assert(0,['Error: params.type must be 0 (parallel ',...
                  'spring-damper) or 1 (series spring-damper)']);
end

%
% Add in a pure time delay
%
% timeDelayed = time + delay;
% yDelayed = interp1(timeDelayed,y,time,'linear','extrap');

Hs = evaluateGainPhaseCoherenceSq(  params.x,...
                                    y,...
                                    params.bandwidth,...
                                    params.sampleFrequency);

modelResponse.frequency     = Hs.frequency;
modelResponse.frequencyHz   = Hs.frequencyHz;
modelResponse.gain          = Hs.gain;
modelResponse.phase         = Hs.phase;
modelResponse.coherenceSq   = Hs.coherenceSq;
idxMax = find(Hs.frequencyHz <= params.bandwidth,1,"last");
modelResponse.idxBandwidth  = [1:1:idxMax]';

