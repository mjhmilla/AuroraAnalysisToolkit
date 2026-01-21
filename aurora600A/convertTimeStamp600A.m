function dateTime = convertTimeStamp600A(createdString)



idxSpAll = strfind(createdString,' ');

idxSp = idxSpAll(1,1);

%Merge entries that are side-by-side
for i=2:1:length(idxSpAll)
    if(idxSpAll(1,i)-idxSp(end)>1)
        idxSp =[idxSp,idxSpAll(i)];
    end
end


dayNameStr  = strtrim(createdString(1,1:idxSp(1)));
monthStr    = strtrim(createdString(1,idxSp(1):idxSp(2)));
monthDayStr = strtrim(createdString(1,idxSp(2):idxSp(3)));
timeStr     = strtrim(createdString(1,idxSp(3):idxSp(4)));
yearStr     = strtrim(createdString(1,idxSp(4):end));

months       ={'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'};
daysInMonth = [   31,   28,   31,   30,   31,   30,   31,   31,   30,   31,   30,  31];

monthNumber =nan;
for i=1:1:length(months)
    if(strcmp(monthStr,months{i})==1)
        monthNumber=i;
    end
end
assert(~isnan(monthNumber),...
    ['Error: could not convert the month string to a number: ', monthStr]);

dayNumber = str2double(monthDayStr);

yearNumber = str2double(yearStr);

idxC = strfind(timeStr,':');
hourStr = timeStr(1,1:(idxC(1)-1));
minuteStr = timeStr(1,(idxC(1)+1):(idxC(2)-1));
secondStr = timeStr(1,(idxC(2)+1):end);

hourNumber = str2double(hourStr);
minuteNumber = str2double(minuteStr);
secondNumber = str2double(secondStr);

dateTime.year  = yearNumber;
dateTime.month = monthNumber;
dateTime.day   = dayNumber;
dateTime.hour  = hourNumber;
dateTime.minute=minuteNumber;
dateTime.second=secondNumber;
% 
% dateTimeInYears= yearNumber ...
%     + ((monthNumber-1)/12)...
%     + (dayNumber/365) ...
%     + (hourNumber/(24*365)) ...
%     + (minuteNumber/(60*24*365)) ...
%     + (secondNumber/(60*60*24*365));
    



