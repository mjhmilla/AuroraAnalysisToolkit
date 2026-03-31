function flag_validFile = applyKeywordFilter(fileName,keyWordFilter)

flag_validFile=nan;

if(~isempty(keyWordFilter.include))
  flag_validFile=0;
  for k=1:1:length(keyWordFilter.include)
    if(contains(fileName,...
                keyWordFilter.include{k}))
      flag_validFile=1;
    end
  end
end
if(~isempty(keyWordFilter.exclude) && isnan(flag_validFile))
  flag_validFile=1;
  for k=1:1:length(keyWordFilter.exclude)
    if(contains(fileName,...
                keyWordFilter.exclude{k}))
      flag_validFile=0;
    end
  end
end

if(isnan(flag_validFile))
  flag_validFile=1;
end