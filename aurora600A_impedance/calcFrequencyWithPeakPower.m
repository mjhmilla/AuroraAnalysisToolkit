function peakPowerFrequency_Hz=calcFrequencyWithPeakPower(x,sampleRate_Hz)


n=length(x);

fft_x=fft(x);

freq_Hz = [0:1:(n-1)].*(sampleRate_Hz/n);

%pwr2Data = abs(fftData./n).^2;
%pwr1Data = pwr2Data(1:1:(nH+1));
%pwr1Data(2:end-1)=2*pwr1Data(2:end-1);

%freq = [0:1:nH].*(sampleRate_Hz/n);

%[maxPwr,idxMaxPwr]=max(pwr1Data);
%peakPowerFrequency_Hz=freq(idxMaxPwr);

[maxMag,idxMax] = max(abs(fft_x(2:end)));
idxMax=idxMax+1;

peakPowerFrequency_Hz=freq_Hz(idxMax);

indexA=2;
indexB=round(n/2);

fig_inspect=0;
if(fig_inspect==1)
  figPwr=figure;
  subplot(1,2,1);
    plot(freq_Hz(indexA:indexB),abs(fft_x(indexA:indexB)));
    hold on;
    plot(freq_Hz(idxMax),abs(fft_x(idxMax)),'or');
    hold on;
    text(freq_Hz(idxMax),abs(fft_x(idxMax)),...
         sprintf('%1.4f Hz',freq_Hz(idxMax)));
    xlabel('Frequency (Hz)');
    ylabel('Power');
  here=1;
end