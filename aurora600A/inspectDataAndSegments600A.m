function success = inspectDataAndSegments600A(...
                    auroraData)


nyquistFrequency=0.5*auroraData.Setup_Parameters.A_D_Sampling_Rate.Value;

[bLow,aLow]=butter(2,0.25/nyquistFrequency,'low');
[bMed,aMed]=butter(2,5/nyquistFrequency,'low');
[bHigh,aHigh]=butter(2,30/nyquistFrequency,'low');

lengthLowFreq = filtfilt(bLow,aLow,auroraData.Data.Lin.Values);

lengthEnvelope = filtfilt(bMed,aMed,...
  abs(auroraData.Data.Lin.Values-lengthLowFreq));

lengthEnvelopeFilt = filtfilt(bHigh,aHigh,...
  lengthEnvelope);      

dlengthEnvelope= calcCentralDifferenceDataSeries(...
                    auroraData.Data.Time.Values,...
                    lengthEnvelopeFilt).*1000;

figSegmentWindow=figure;
lmean = mean(auroraData.Data.Lin.Values); 
lamp  = max(auroraData.Data.Lin.Values)...
       -min(auroraData.Data.Lin.Values);
fmean = mean(auroraData.Data.Fin.Values); 
famp  = max(auroraData.Data.Fin.Values)...
       -min(auroraData.Data.Fin.Values);
tmean = mean(dTime);
tamp  = max(dTime)-min(dTime);

subplot(1,2,1);
plot(auroraData.Data.Time.Values,auroraData.Data.Lin.Values);
hold on;
plot(auroraData.Data.Time.Values,...
     (dTime-tmean).*(lamp/tamp)+lmean,'-c');   
hold on
plot(auroraData.Data.Time.Values,...
    lengthEnvelope+lmean,'-c');
hold on;
plot(auroraData.Data.Time.Values,...
    dlengthEnvelope+lmean,'-m');
hold on;
xlabel('Time');
ylabel('Length');
subplot(1,2,2);
plot(auroraData.Data.Time.Values,auroraData.Data.Fin.Values);
hold on;       
plot(auroraData.Data.Time.Values,...
     lengthEnvelope.*(famp/lamp)+fmean,'-c');
hold on;
plot(auroraData.Data.Time.Values,...
     dlengthEnvelope.*(famp/lamp)+fmean,'-m');
hold on;
plot(auroraData.Data.Time.Values,...
     (dTime-tmean).*(famp/tamp)+fmean,'-c');
hold on;
xlabel('Time');
ylabel('Force');

l0 = min(auroraData.Data.Lin.Values);
l1 = max(auroraData.Data.Lin.Values);
f0 = min(auroraData.Data.Fin.Values);
f1 = max(auroraData.Data.Fin.Values);

idxSegStart=setOfSegments(1);
idxSegEnd = setOfSegments(end);

for idxSeg = idxSegStart:1:idxSegEnd
  t0=trialJson.segments(idxSeg).time_ms(1);
  t1=trialJson.segments(idxSeg).time_ms(2);
  lbox=[t0,t1,t1,t0,t0;...
        l0,l0,l1,l1,l0];
  fbox=[t0,t1,t1,t0,t0;...
        f0,f0,f1,f1,f0];
  lineType='-k';
  switch trialJson.segments(idxSeg).type
    case 'Length-Sine'
      lineType='-r';
    case 'Length-Ramp'
      lineType='-b';              
    otherwise
      assert(0,'Error: unexpected segment type');
  end

  subplot(1,2,1);
    plot(lbox(1,:),lbox(2,:),lineType);
    hold on;            
    plot(auroraData.Data.Time.Values,...
         dTime,'-k');
    hold on;
    text(lbox(1,3),lbox(2,3),...
      sprintf('%i. %f ms',idxSeg,...
      trialJson.segments(idxSeg).meta_data.duration_ms),...
      'VerticalAlignment','bottom',...
      'Rotation',90);
    ylim([l0,l1]);
  subplot(1,2,2);
    plot(fbox(1,:),fbox(2,:),lineType);
    hold on;
    plot(auroraData.Data.Time.Values,...
         dTime,'-k');
    hold on;
    text(fbox(1,3),fbox(2,3),...
      sprintf('%i. %f ms',idxSeg,...
      trialJson.segments(idxSeg).meta_data.duration_ms), ...
      'VerticalAlignment','bottom',...
      'Rotation',90);
    ylim([f0,f1]);

end

success=1;
