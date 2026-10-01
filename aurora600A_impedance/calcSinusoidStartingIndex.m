function indexSineStart = calcSinusoidStartingIndex(frequencyHz,...
                                          indexStartInterval,...
                                          indexStart,...
                                          indexEnd,...
                                          auroraData)

sampleFrequency_Hz=auroraData.Setup_Parameters.A_D_Sampling_Rate.Value;

maxCorrel=nan;
indexMaxCorrel = nan;

duration = (indexEnd-indexStart)/sampleFrequency_Hz;
cycles = round(frequencyHz*duration);

n = min(cycles,5);

indexDelta = round((indexEnd-indexStart)*0.25);
indexMiddleA = indexStart+indexDelta;
indexMiddleB = indexEnd-indexDelta;

lmed = median(auroraData.Data.Lin.Values(indexStart:indexEnd));


for i=indexStartInterval(1):1:indexStartInterval(2)
  %Make the wave


end