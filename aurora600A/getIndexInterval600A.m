function indexInterval = getIndexInterval600A(timeVector,timeInterval)

indexInterval=zeros(size(timeInterval));
for i=1:1:length(timeInterval)

    idxBest = round(length(timeVector)*0.5);
    timeErrorBest = abs(timeVector(idxBest)-timeInterval(i));

    idxDelta = round(length(timeVector)*0.25);

    while idxDelta > 1
        idxL = idxBest-idxDelta;
        idxL = max(idxL,1);
        idxL = min(idxL,length(timeVector));        
        timeErrorLeft = abs(timeVector(idxL)-timeInterval(i));

        idxR = idxBest+idxDelta;
        idxR = max(idxR,1);
        idxR = min(idxR,length(timeVector));        
        timeErrorRight = abs(timeVector(idxR)-timeInterval(i));
        
        if(timeErrorLeft < timeErrorBest ...
                && timeErrorLeft <= timeErrorRight)
            idxBest=idxL;
            timeErrorBest=timeErrorLeft;            
        end
        if(timeErrorRight < timeErrorBest ...
                && timeErrorRight < timeErrorLeft)
            idxBest=idxR;
            timeErrorBest=timeErrorRight;                        
        end

        idxDelta = round(idxDelta*0.5);
    end
    indexInterval(i)=idxBest;

end