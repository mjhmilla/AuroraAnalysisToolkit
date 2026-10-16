function summary = getSummaryStatistics(data)

summary.x = [0.01,0.05,0.25,0.5,0.75,0.95,0.99];
summary.y = getPercentiles(data, summary.x)';
summary.mean = mean(data);
summary.median = summary.y(4);        
summary.std = std(data);
summary.min = min(data);
summary.max = max(data);

%Note: the median function will return the average of the
%      two middle elements of a vector that has an even 
%      number of elements. In contrast, getPercentiles returns
%      a median value that is in the set.


