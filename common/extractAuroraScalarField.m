function [fieldNameStr, fieldValueStr, fieldUnitStr] = ...
                    extractAuroraScalarField(line)

i0 = strfind(line,':')-1;

%%
%Extract the field name and convert it to a snake-case name with no
%special characters
%%

fieldNameStr = line(1,1:i0);

fieldNameStr = convertStringToValidStructFieldName(fieldNameStr);

% charsToReplace = [{' '}, {'/'}, {'('},{')'}, {'-'}];
% replacementChars=[{'_'}, {'_'}, {''}, {''}, {'_'}];
% 
% for i=1:1:length(charsToReplace)
% 
%     r0 = strfind(fieldNameStr, charsToReplace{i});
% 
%     r0p = -1;
%     if(isempty(r0) == 0)
%         for j=1:1:length(r0)
%             if( (r0(1,j)-r0p)==1)
%                 fieldNameStr(1,r0(1,j))= '!';
%             else
%                 if(isempty(replacementChars{i})==0)
%                     fieldNameStr(1,r0(1,j)) = replacementChars{i};
%                 else
%                     fieldNameStr(1,r0(1,j)) = '!';
%                 end
%             end
%             r0p = r0(1,j);
%         end
%     end
% 
% end
% 
% 
% d0 = strfind(fieldNameStr,'!');
% if(isempty(d0)==0)
%     fieldNameStr = erase(fieldNameStr,'!');    
% end

%%
% Extract the value and unit
%%

i0 = i0+2;

fieldValueUnit = strtrim(line(1,i0:end));
r0 = strfind(fieldValueUnit,' ');


if(isempty(r0)==1)
    fieldValueStr = strtrim(fieldValueUnit);
    fieldUnitStr = '';
else

    if(length(r0)==1)
        s0 = r0(1,1)-1;
        fieldValueStr = strtrim(fieldValueUnit(1,1:s0));

        s0 = s0+2;
        fieldUnitStr  = strtrim(fieldValueUnit(1,s0:end));
    else
        fieldValueStr = strtrim(fieldValueUnit);
        fieldUnitStr  = '';
    end
end
