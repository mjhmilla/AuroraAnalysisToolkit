function segmentColors=getImpedanceLengthSegmentColors600A(...
                          segmentSeries,dataSet)

idCS=1;
idCL=2;

%1 0.02 35
%2 0.02 90
%3 0.002 35
%4 0.002 90
assert(length(segmentSeries)==4);

cs=getPaulTolColourSchemes('sunset');
%cs.blue0=[0,0,0];

segmentColors(4,2)=struct('lineColor',[],'fillColor',[]);

for idS=1:1:4
  idStr='';
  n=1;
  switch idS
    case 1
      idStr='2';
      n=1;
    case 2
      idStr='0';
    case 3
      idStr='3';      
      n=1;
    case 4
      idStr='1';
    otherwise
      assert(0,'Error: Unrecognized segment')
  end
  for idC=1:2
    segmentColors(idS,idC)=struct('lineColor',[],'fillColor',[]);
    switch idC
      case 1
        baseColor = cs.(['red',idStr]);
        segmentColors(idS,idC).lineColor = baseColor;
        segmentColors(idS,idC).fillColor = baseColor.*n + ([1,1,1])*(1-n);
      case 2
        baseColor = cs.(['blue',idStr]);
        segmentColors(idS,idC).lineColor = baseColor;
        segmentColors(idS,idC).fillColor = baseColor.*n + ([1,1,1])*(1-n);        
      otherwise
        assert(0,'Error: unrecognized idC');
    end
  end
end

%segmentColors(4,1)=


% for idS=1:1:length(segmentSeries)
%   ampLo=dataSet.individual(idS,1,1).amplitudeLo;
%   bwHz =dataSet.individual(idS,1,1).bandwidthHz;   
%   for idC=1:1:2
%     switch idC
%       case 1
%         if(ampLo > 0.009)
%           segmentColors(idS,idC).lineColor=cs.orange;
%         else
%           segmentColors(idS,idC).lineColor=cs.red;
%         end
%       case 2
%         if(ampLo > 0.009)
%           segmentColors(idS,idC).lineColor=cs.cyan;
%         else
%           segmentColors(idS,idC).lineColor=cs.blue;
%         end        
%       otherwise 
%         assert(0,'Error: unrecognized idC value');
%     end
%     
%     if(bwHz > 45)
%       segmentColors(idS,idC).fillColor= ...
%         segmentColors(idS,idC).lineColor.*0.25 + [1,1,1].*0.75;
%     else
%       segmentColors(idS,idC).fillColor= [1,1,1];
%     end      
%   end  
% end