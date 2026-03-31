function [fiberModulusSample,...
          gainSample,...
          stressSample]=...
            calcFiberModulus600A(...
                                        xTimeDomain,...
                                        yTimeDomain,...
                                        frequencyHzSubBand,...
                                        gainSubBand,...
                                        coherenceSqSubBand,...
                                        fiberForceMean,...
                                        fiberProperties)

A = [frequencyHzSubBand, ones(size(frequencyHzSubBand))];
b = gainSubBand;
%Ax = b
%A'Ax = A'b
%x = pinv(A'A)A'b
x = (A'*A)\(A'*b);
k = x(2,1);
gainLinear = A*x;
%gain is in units of mN/mm = N/m
freqAvg = mean(frequencyHzSubBand);
%[val,idxAvg] = min(abs(frequencyHzSubBand-freqAvg));

%gainAvg = [frequencyHzSubBand(1,1), 1]*x;
%coherenceSqAvg = coherenceSqSubBand(1,1);

idxSample=1;
gainSample.Value=gainSubBand(idxSample,1);
gainSample.Unit='mN/mm';


flag_plotLinearGainModel=0;
if(flag_plotLinearGainModel==1)
    figTest=figure;

    yyaxis left;
    plot(frequencyHzSubBand,gainSubBand);
    hold on;
    xlabel('Frequency (Hz)');
    ylabel('Gain (mN/mm)');

    plot(frequencyHzSubBand,gainLinear,'-k');                
    hold on;
    plot(frequencyHzSubBand(idxSample,1),gainSample.Value,'*k');                

    yyaxis right;
    plot(frequencyHzSubBand,coherenceSqSubBand);
    hold on;
    plot(frequencyHzSubBand(idxSample,1),coherenceSqAvg(idxSample,1),'*');
    ylabel('Coherence$$^2$$');
    box off;

    hold on;
    box off;
    
end

%If the coherence of the signal is high, evaluate the
%propagation delay            

fiberAreaM = fiberProperties.areaMM*(0.001*0.001);
fiberLengthM = fiberProperties.lceMM*0.001;
fiberForcemN    = fiberForceMean;                
fiberForceN     = fiberForcemN/1000;

fiberStress = fiberForceN/fiberAreaM;
stressSample.Value = fiberStress;
stressSample.Unit = 'Pa';
dl = (fiberStress*fiberAreaM)/gainSample.Value;
fiberE00 = fiberStress/ (dl/fiberLengthM); %Strain to develop this stress

%Using the definition of elastic modulus:
% https://en.wikipedia.org/wiki/Elastic_modulus
fiberE01 = gainSample.Value*(1/fiberAreaM)/(1/fiberLengthM);

yTimeDomainPos = yTimeDomain(yTimeDomain>0);
yTimeDomainNeg = yTimeDomain(yTimeDomain<0);
xTimeDomainPos = xTimeDomain(xTimeDomain>0);
xTimeDomainNeg = xTimeDomain(xTimeDomain<0);

dyN = (mean(yTimeDomainPos)-mean(yTimeDomainNeg))/1000;
dsigmaNPM2 = dyN / fiberAreaM;
dxM = (mean(xTimeDomainPos)-mean(xTimeDomainNeg))/1000;
dxN = dxM / fiberLengthM;
fiberE02 = dsigmaNPM2/dxN;

relError01 = abs(fiberE00-fiberE01)/(0.5*(fiberE00+fiberE01));
relError02 = abs(fiberE01-fiberE02)/(0.5*(fiberE01+fiberE02));

fiberModulusSample.Value = fiberE01;
fiberModulusSample.Unit  = 'Pa';