function fieldNameStr = convertStringToValidStructFieldName(fieldNameStr)


charsToReplace = [{' '}, {'/'}, {'('},{')'}, {'-'}];
replacementChars=[{'_'}, {'_'}, {''}, {''}, {'_'}];

for i=1:1:length(charsToReplace)

    r0 = strfind(fieldNameStr, charsToReplace{i});

    r0p = -1;
    if(isempty(r0) == 0)
        for j=1:1:length(r0)
            if( (r0(1,j)-r0p)==1)
                fieldNameStr(1,r0(1,j))= '!';
            else
                if(isempty(replacementChars{i})==0)
                    fieldNameStr(1,r0(1,j)) = replacementChars{i};
                else
                    fieldNameStr(1,r0(1,j)) = '!';
                end
            end
            r0p = r0(1,j);
        end
    end

end


d0 = strfind(fieldNameStr,'!');
if(isempty(d0)==0)
    fieldNameStr = erase(fieldNameStr,'!');    
end