function [indexStartNoPad, indexEndNoPad] = ...
           searchForSegmentBoundary600A(indexStart, indexEnd, auroraData,...
                                        paddingSamples)

indexDelta = round(0.25*(indexEnd-indexStart));

dataIndexMiddle = ...
  [(indexStart+indexDelta):1:(indexEnd-indexDelta)];

lmean = mean(auroraData.Data.Lin.Values(dataIndexMiddle));
lamp  = 0.5*(max(auroraData.Data.Lin.Values(dataIndexMiddle))...
            -min(auroraData.Data.Lin.Values(dataIndexMiddle)));
lub=lmean+0.9*lamp;
llb=lmean-0.9*lamp;

indexBoundary  = [indexStart,indexEnd];
indexBoundaryUpd=[nan,nan];
searchDirection=[1,-1];
searchLimits   =[indexStart, indexEnd;...
                 indexStart, indexEnd];

thresholdY = 0.05.*(lamp); 

indexPaddingBoundary = ...
  [(indexStart+paddingSamples),(indexEnd-paddingSamples)];
indexAcceptableBoundary=[nan,nan];

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

    indexAcceptableBoundary(i)=indexNoPad;

    dL = auroraData.Data.Lin.Values(indexNoPad-1)-lmean;
    dR = auroraData.Data.Lin.Values(indexNoPad)-lmean;
    

    while( ( (dL*dR > 0 && deltaYUpd > 0.25*deltaY) ...
        || (  abs(auroraData.Data.Lin.Values(indexNoPad)-lmean) > thresholdY))...
        && (indexNoPad >= searchLimits(i,1) ...
        && indexNoPad <= searchLimits(i,2)))

      i0=indexNoPad;
      indexNoPad=indexNoPad-searchDirection(i);
      i1=indexNoPad;

      %deltaY = deltaYUpd;      
      deltaYUpd =abs(auroraData.Data.Lin.Values(i0) ...
                    -auroraData.Data.Lin.Values(i1));

      dL = auroraData.Data.Lin.Values(indexNoPad-1)-lmean;
      dR = auroraData.Data.Lin.Values(indexNoPad)-lmean;   

    end
    if(~(deltaYUpd > 0.25*deltaY) ...
        && indexNoPad < searchLimits(i,2) ...
        && indexNoPad > searchLimits(i,1))
      indexNoPad=indexNoPad+searchDirection(i);
    end    

    if(~(indexNoPad > searchLimits(i,1) ...
         && indexNoPad < searchLimits(i,2) ))
      if(~isnan(indexAcceptableBoundary(i)))
        indexNoPad=indexAcceptableBoundary(i);
      else
        indexNoPad=indexPaddingBoundary(i);
      end
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

    indexAcceptableBoundary(i)=indexNoPad;

    dL = auroraData.Data.Lin.Values(indexNoPad-1)-lmean;
    dR = auroraData.Data.Lin.Values(indexNoPad)-lmean;

    deltaY=abs(auroraData.Data.Lin.Values(indexNoPad) ...
              -auroraData.Data.Lin.Values(indexNoPad-searchDirection(i)));
    deltaYUpd=deltaY;



    while( ( (dL*dR > 0 && deltaYUpd > 0.25*deltaY) ...
        || (  abs(auroraData.Data.Lin.Values(indexNoPad)-lmean) > thresholdY))...
        && (indexNoPad >= searchLimits(i,1) ...
        && indexNoPad <= searchLimits(i,2)) ...
        )
      i0=indexNoPad;      
      indexNoPad=indexNoPad-searchDirection(i);
      i1=indexNoPad;

      %deltaY = deltaYUpd;      
      deltaYUpd =abs(auroraData.Data.Lin.Values(i0) ...
                    -auroraData.Data.Lin.Values(i1));
      
      dL = auroraData.Data.Lin.Values(indexNoPad-1)-lmean;
      dR = auroraData.Data.Lin.Values(indexNoPad)-lmean;      

    end
    if(~(deltaYUpd > 0.25*deltaY) ...
        && indexNoPad < searchLimits(i,2) ...
        && indexNoPad > searchLimits(i,1))
      indexNoPad=indexNoPad+searchDirection(i);
    end
    if(~(indexNoPad > searchLimits(i,1) ...
        && indexNoPad < searchLimits(i,2) ))
      if(~isnan(indexAcceptableBoundary(i)))
        indexNoPad=indexAcceptableBoundary(i);
      else
        indexNoPad=indexPaddingBoundary(i);
      end
    end



  end
  indexBoundaryUpd(i)=indexNoPad;

end

indexStartNoPad=indexBoundaryUpd(1);
indexEndNoPad=indexBoundaryUpd(2);

flag_debugSegmentBoundaries=0;
if(flag_debugSegmentBoundaries==1)
  figSegBoundaries=figure;
  plot(auroraData.Data.Time.Values(indexStart:indexEnd),...
       auroraData.Data.Lin.Values(indexStart:indexEnd),...
       '-','Color',[1,1,1].*0.5);
  hold on;
  plot(auroraData.Data.Time.Values(indexStart+paddingSamples),...
       auroraData.Data.Lin.Values(indexStart+paddingSamples),...
       'xb');
  hold on;
  plot(auroraData.Data.Time.Values(indexEnd-paddingSamples),...
       auroraData.Data.Lin.Values(indexEnd-paddingSamples),...
       'xb');
  hold on;

  
  for i=1:1:length(indexBoundaryUpd)
    plot(auroraData.Data.Time.Values(indexBoundaryUpd(i)),...
         auroraData.Data.Lin.Values(indexBoundaryUpd(i)),...
         'or','Color',[1,0,0]);
    hold on;
  end
  here=1;
end

