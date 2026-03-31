function summary = getSummaryStatistics(data)

summary.x = [0.01,0.05,0.25,0.5,0.75,0.95,0.99];
summary.y = getPercentiles(data, summary.x)';
summary.mean = mean(data);
summary.median = median(data);        
summary.std = std(data);
summary.min = min(data);
summary.max = max(data);
