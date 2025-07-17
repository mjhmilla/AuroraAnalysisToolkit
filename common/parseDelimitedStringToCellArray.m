function cellArray = parseDelimitedStringToCellArray(str,delimiter)


%char(9) is a tab
sp0 = strfind(str,delimiter);
cellArray = [{''}];

for i=1:1:(length(sp0)+1)

    if(i==1)
        i0 = 1;
    else
        i0 = sp0(1,i-1)+1;        
    end
    if(i==length(sp0)+1)
        i1 = length(str);
    else
        i1 = sp0(1,i)-1;        
    end
    
    fieldName = str(1,i0:i1);
    if(i==1)
        cellArray = [{fieldName}];
    else
        cellArray = [cellArray, {fieldName}];
    end
end