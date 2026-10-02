function [indexStartNoPad, indexEndNoPad] = ...
           searchForSegmentBoundary600A(indexStart, ...
                                        indexEnd, ...
                                        approxFrequencyHz,...
                                        auroraData,...
                                        paddingSamples)

indexDelta = round(0.25*(indexEnd-indexStart));

samplesPerPeriod = ...
  round(auroraData.Setup_Parameters.A_D_Sampling_Rate.Value...
       /approxFrequencyHz);

dataIndexMiddle = ...
  [(indexStart+indexDelta):1:(indexEnd-indexDelta)];

lmean = mean(auroraData.Data.Lin.Values(dataIndexMiddle));
lamp  = 0.5*(max(auroraData.Data.Lin.Values(dataIndexMiddle))...
            -min(auroraData.Data.Lin.Values(dataIndexMiddle)));

ltarget = lmean;
lwindow = [lmean-0.025*lamp,lmean+0.025*lamp];

lthresh    = [lmean+0.075*lamp,lmean+0.5*lamp;...
              lmean-0.5*lamp,lmean-0.075*lamp];
dlSign = [1, 1];

indexBoundary  = [indexStart,indexEnd];
indexBoundaryUpd=[nan,nan];
searchDirection=[1,-1];
searchLimits   =[indexStart, indexEnd;...
                 indexStart, indexEnd];

thresholdY = 0.05.*(lamp); 

indexPaddingBoundary = ...
  [(indexStart+paddingSamples),(indexEnd-paddingSamples)];
indexAcceptableBoundary=[nan,nan];

%
% Start the debugging plot
%
flag_debugSegmentBoundaries=1;
if(flag_debugSegmentBoundaries==1)
  figSegBoundaries=figure;
  plot(auroraData.Data.Time.Values(indexStart:indexEnd),...
       auroraData.Data.Lin.Values(indexStart:indexEnd),...
       '-','Color',[1,1,1].*0.5);
  hold on;
  for i=1:1:size(lthresh,1)
    if(i==1)
      lineType='-r';
    else
      lineType='-b';      
    end
    for j=1:1:size(lthresh,2)
      plot([auroraData.Data.Time.Values(indexStart), ...
            auroraData.Data.Time.Values(indexEnd)],...
            [1,1].*lthresh(i,j),...
            lineType);
      hold on;
    end
  end
  for i=1:1:length(lwindow)
    plot([auroraData.Data.Time.Values(indexStart), ...
          auroraData.Data.Time.Values(indexEnd)],...
          [1,1].*lwindow(i),...
          '-c');
    hold on;
  end
end


for i=1:1:length(indexBoundary)

  interval = [indexStart:indexEnd];

  isSignCorrect = 0;
  isBoundFound = 0;

  while ~isempty(interval) > 0 ...
          && (isSignCorrect == 0 || isBoundFound==0)
    if(searchDirection(i)>0)
      idxA = find(auroraData.Data.Lin.Values(interval)...
                      > lthresh(i,1),1,'first');

      if(auroraData.Data.Lin.Values(interval(idxA)) > lthresh(i,2))
        idxB=idxA;
        idxA=idxA-1;
      else
        idxB = find(auroraData.Data.Lin.Values(interval(idxA+1):1:interval(end))...
                          > lthresh(i,2),1,'first');                  
        idxB=idxA+idxB;
      end
  
    else
      idxB = find(auroraData.Data.Lin.Values(interval)...
                      < lthresh(i,2),1,'last');

      if(auroraData.Data.Lin.Values(interval(idxB))<lthresh(i,1))
        idxA=idxB-1;
      else
        idxA = find(auroraData.Data.Lin.Values(interval(1):1:interval(idxB-1))...
                        < lthresh(i,1),1,'last');
      end
       
    end

    if(flag_debugSegmentBoundaries==1)
      plot(auroraData.Data.Time.Values(interval(idxA)),...
           auroraData.Data.Lin.Values(interval(idxA)),...
           'or');
      hold on;
      plot(auroraData.Data.Time.Values(interval(idxB)),...
           auroraData.Data.Lin.Values(interval(idxB)),...
           'xb');
      hold on;
    end

    p = polyfit(auroraData.Data.Time.Values(interval(idxA:idxB)),...
                auroraData.Data.Lin.Values(interval(idxA:idxB)),...
                1);



    if(sign(p(1))*dlSign(i)>0)
      isSignCorrect=1;
      if(searchDirection(i)>0)
        idx0=idxA;
      else
        idx0=idxB;            
      end

      idx1=idx0-searchDirection(i);
      if(idx1 >= 1 && idx1 <= length(interval))
        if(    interval(idx0) > indexStart ...
            && interval(idx0) < indexEnd ...
            && interval(idx1) > indexStart ...
            && interval(idx1) < indexEnd )
    
          d0 = auroraData.Data.Lin.Values(interval(idx0))-ltarget;
          d1 = auroraData.Data.Lin.Values(interval(idx1))-ltarget;
          
          if(d0*d1 < 0)    
            isBoundFound=1;
            if(abs(d0)<abs(d1))
              indexBoundaryUpd(i)=interval(idx0);
            else
              indexBoundaryUpd(i)=interval(idx1);            
            end
          end
  
        end
      end

      lerrBest=abs(auroraData.Data.Lin.Values(interval(idx0))-ltarget);
      idxBest=idx0;
      if(samplesPerPeriod <= 10)
        isBoundFound=1;
        indexBoundaryUpd(i)=interval(idxBest);
      end
      while(interval(idx0) > indexStart ...
          && interval(idx0) < indexEnd ...
          && samplesPerPeriod > 10 ...
          && isBoundFound==0)

        lval=auroraData.Data.Lin.Values(interval(idx0));
        lerr=abs(lval-ltarget);
        if(lval > lwindow(1,1) && lval < lwindow(1,2) && lerr<lerrBest)
          idxBest=idx0;
          lerrBest=lerr;
          isBoundFound=1;
          indexBoundaryUpd(i)=interval(idx0);
        end

        if(idx0 > 1 && idx0 < length(interval))
          idx0=idx0-searchDirection(i);        
        else
          break;
        end
      end
    end

    if(isSignCorrect==0 || isBoundFound == 0)
      samplesPerHalfPeriod=round(0.5*samplesPerPeriod);
      if(searchDirection(i)>0)        
        idxBnd=idxB+samplesPerHalfPeriod;
        if(idxBnd < length(interval))
          interval = [interval(idxBnd):indexEnd];
        else
          interval=[];
        end
      else
        idxBnd=idxA-samplesPerHalfPeriod;
        if(idxBnd > 1)
          interval = [indexStart:interval(idxBnd)];        
        else
          interval=[];
        end
      end  
    end

  end


  



  if(flag_debugSegmentBoundaries==1 && ~isnan(indexBoundaryUpd(i)))
    plot(auroraData.Data.Time.Values(indexBoundaryUpd(i)),...
         auroraData.Data.Lin.Values(indexBoundaryUpd(i)),...
         'xc');
    hold on;
  end

end

if(flag_debugSegmentBoundaries==1 && ~isnan(indexBoundaryUpd(i)))
  close(figSegBoundaries);
end

assert(sum(isnan(indexBoundaryUpd))==0,...
  'Error: failed to find valid boundary');

indexStartNoPad=indexBoundaryUpd(1);
indexEndNoPad=indexBoundaryUpd(2);



