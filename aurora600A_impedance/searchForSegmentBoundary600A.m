function [indexStartNoPad, indexEndNoPad] = ...
           searchForSegmentBoundary600A(indexStart, indexEnd, auroraData)

indexDelta = round(0.25*(indexEnd-indexStart));

dataIndexMiddle = ...
  [(indexStart+indexDelta):1:(indexEnd-indexDelta)];

lmean = mean(auroraData.Data.Lin.Values(dataIndexMiddle));
lamp  = 0.5*(max(auroraData.Data.Lin.Values(dataIndexMiddle))...
            -min(auroraData.Data.Lin.Values(dataIndexMiddle)));
lub=lmean+0.125*lamp;
llb=lmean-0.125*lamp;


indexBoundary  = [indexStart,indexEnd];
indexBoundaryUpd=[nan,nan];
searchDirection=[1,-1];
searchLimits   =[indexStart, indexEnd;...
                 indexStart, indexEnd];

for i=1:1:length(indexBoundary)

  indexNoPad=indexBoundary(i);
  

  if(    auroraData.Data.Lin.Values(indexNoPad) > lub ...
      || auroraData.Data.Lin.Values(indexNoPad) < llb)

    while( (auroraData.Data.Lin.Values(indexNoPad) > lub ...
         || auroraData.Data.Lin.Values(indexNoPad) < llb) ...
         && (indexNoPad >= searchLimits(i,1) ...
         && indexNoPad <= searchLimits(i,2)))


      indexNoPad=indexNoPad+searchDirection(i);

    end
    assert(indexNoPad > searchLimits(i,1),...
      'Error: could not refine the start of the segment');
    assert(indexNoPad < searchLimits(i,2),...
      'Error: could not refine the start of the segment');

    dL = auroraData.Data.Lin.Values(indexNoPad-1)-lmean;
    dR = auroraData.Data.Lin.Values(indexNoPad+1)-lmean;
    while(dL*dR > 0 ...
        && (indexNoPad >= searchLimits(i,1) ...
        && indexNoPad <= searchLimits(i,2)))
      indexNoPad=indexNoPad-searchDirection(i);
      dL = auroraData.Data.Lin.Values(indexNoPad-1)-lmean;
      dR = auroraData.Data.Lin.Values(indexNoPad+1)-lmean;   
    end

  else        

    dldidx=nan;
    while(auroraData.Data.Lin.Values(indexNoPad) < lub ...
          && auroraData.Data.Lin.Values(indexNoPad) > llb ...
          && (indexNoPad >= searchLimits(i,1) ...
         && indexNoPad <= searchLimits(i,2)))

      indexNoPad=indexNoPad+searchDirection(i);          
%       dldidx = auroraData.Data.Lin.Values(indexNoPad+1) ...
%               -auroraData.Data.Lin.Values(indexNoPad);
    end
    dL = auroraData.Data.Lin.Values(indexNoPad-1)-lmean;
    dR = auroraData.Data.Lin.Values(indexNoPad+1)-lmean;
    while(dL*dR > 0 ...
        && (indexNoPad >= searchLimits(i,1) ...
        && indexNoPad <= searchLimits(i,2)))
      indexNoPad=indexNoPad-searchDirection(i);
      dL = auroraData.Data.Lin.Values(indexNoPad-1)-lmean;
      dR = auroraData.Data.Lin.Values(indexNoPad+1)-lmean;      
    end
    assert(indexNoPad > searchLimits(i,1),...
      'Error: could not refine the start of the segment');
    assert(indexNoPad < searchLimits(i,2),...
      'Error: could not refine the start of the segment');



  end
  indexBoundaryUpd(i)=indexNoPad;

end

indexStartNoPad=indexBoundaryUpd(1);
indexEndNoPad=indexBoundaryUpd(2);


