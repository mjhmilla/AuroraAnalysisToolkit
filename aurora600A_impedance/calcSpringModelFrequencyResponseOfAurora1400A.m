function modelResponse = calcSpringModelFrequencyResponseOfAurora1400A(params)

k           = params.k;
beta        = params.beta;
m           = params.m;
tau         = params.tau;
delay       = params.delay;
time        = params.time;

x           = params.x;
xdot        = params.xdot;


bandwidth = params.bandwidth;
sampleFrequency = params.sampleFrequency;

%
% Time domain signal
%
y = k.*x + beta.*xdot;

%
% Add in a pure time delay
%
timeDelayed = time + delay;
yDelayed = interp1(timeDelayed,y,time,'linear','extrap');

Hs = evaluateGainPhaseCoherenceSq(  x,...
                                    yDelayed,...
                                    bandwidth,...
                                    sampleFrequency);

modelResponse.frequency     = Hs.frequency;
modelResponse.frequencyHz   = Hs.frequencyHz;
modelResponse.gain          = Hs.gain;
modelResponse.phase         = Hs.phase;
idxMax = find(Hs.frequencyHz <= bandwidth,1,"last");
modelResponse.idxBandwidth  = [1:1:idxMax]';

