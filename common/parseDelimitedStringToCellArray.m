function cellArray = parseDelimitedStringToCellArray(str,delimiter)


%char(9) is a tab
strUpd = strtrim(str);
sp0 = strfind(strUpd,delimiter);

cellArray = [{''}];

idx=1;
while(length(strUpd) > 0)

    if(isempty(sp0)==0)
        i0 =1;    
        i1 = sp0(1,1)-1;
    
    
        fieldName = strtrim(strUpd(1,i0:i1));
        if(idx==1)
            cellArray = [{fieldName}];
        else
            cellArray = [cellArray, {fieldName}];
        end
    
        i1 = i1+2;
        strUpd = strtrim(strUpd(1,i1:end));
    
        if(length(strUpd) >0)
            sp0 = strfind(strUpd,delimiter);
        end
    else
        fieldName = strtrim(strUpd);
        if(length(fieldName)>0)
            cellArray = [cellArray, {fieldName}];
        end
        strUpd = [];
    end
    idx=idx+1;
end