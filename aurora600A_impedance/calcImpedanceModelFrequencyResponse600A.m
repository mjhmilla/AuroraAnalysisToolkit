function modelResponse = calcImpedanceModelFrequencyResponse600A(params)

modelResponse = [];
%
% Time domain signal
%
switch params.type
    case 0
%         y = params.k.*params.x + params.beta.*params.xdot;
%         modelResponseTime = evaluateGainPhaseCoherenceSq(  ...
%                             params.time,...
%                             params.x,...
%                             y,...
%                             params.bandwidth,...
%                             params.sampleFrequency);
        z = params.k + (params.beta*complex(0,1)).*params.frequency;
        modelResponse.H             = z;
        modelResponse.idxBW         = find(params.frequencyHz <= params.bandwidth);
        modelResponse.frequency     = params.frequency;
        modelResponse.frequencyHz   = params.frequencyHz;
        modelResponse.gain          = abs(z);
        modelResponse.phase         = angle(z);
        modelResponse.storage       = real(z);
        modelResponse.loss          = imag(z);

        here=1;
    case 1
        assert(0,'Error: model type not yet implemented');
        
    otherwise
        assert(0,['Error: params.type must be 0 (parallel ',...
                  'spring-damper) or 1 (series spring-damper)']);
end




% Hs = evaluateGainPhaseCoherenceSq(  params.time,...
%                                     params.x,...
%                                     y,...
%                                     params.bandwidth,...
%                                     params.sampleFrequency);
% modelResponse.time          = params.time;
% modelResponse.x             = params.x;
% modelResponse.y             = y;
% modelResponse.frequency     = Hs.frequency;
% modelResponse.frequencyHz   = Hs.frequencyHz;
% modelResponse.H             = Hs.H;
% modelResponse.gain          = Hs.gain;
% modelResponse.phase         = Hs.phase;
% modelResponse.coherenceSq   = Hs.coherenceSq;
% 
% idxMax = find(Hs.frequencyHz <= params.bandwidth,1,"last");
% modelResponse.idxBandwidth  = [1:1:idxMax]';

