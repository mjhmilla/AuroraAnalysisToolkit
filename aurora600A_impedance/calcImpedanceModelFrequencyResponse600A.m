function modelResponse = calcImpedanceModelFrequencyResponse600A(params)


%
% Time domain signal
%
switch params.type
    case 0
        y = params.k.*params.x + params.beta.*params.xdot;
    case 1
        assert(0,'Error: model type not yet implemented');
%         freq = params.frequency;
%         Xfd  = fft(x);
%         X1fd = beta.*(Xfd .* (complex(0,1).*freq) )./(k+beta);
%         Ffd  = k.*X1fd;
%         ftest    = ifft(Ffd,'symmetric');
%         x1    = ifft(X1fd,'symmetric');
%         x1dot = ifft(X1fd .* (complex(0,1).*freq),'symmetric'); 
%         x2dot = xdot-x1dot;
%         f1 = x1.*k;
%         f2 = x2dot.*beta;
%         f12rerr = 0.5.*(f1-f2)./(f1+f2);
%         f1rerr = 0.5.*(f1-ftest)./(f1+ftest);
%         y = f1;
%         here=1;
        
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
idxMax = find(Hs.frequencyHz <= params.bandwidth,1,"last");
modelResponse.idxBandwidth  = [1:1:idxMax]';

