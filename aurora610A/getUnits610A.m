function units = getUnits610A(expJson,trialJson,ddfData610)

units.time    = '';
units.length  = '';
units.force   = '';
units.voltage = '';
units.current = '';

%Get the default time unit
units.time = '';
defaultTimeUnitFound =0;
for idxSeg = 1:1:length(trialJson.segments)
  segmentFields = fields(trialJson.segments(idxSeg));
  for idxF = 1:1:length(segmentFields)
    if(defaultTimeUnitFound==0)
      if(strcmp(segmentFields{idxF},'time_s'))
        units.time = 's';
        defaultTimeUnitFound =1;
      end
      if(strcmp(segmentFields{idxF},'time_ms'))
        units.time = 'ms';
        defaultTimeUnitFound =1;
      end      
    end
  end
end
assert(defaultTimeUnitFound==1,...
      'Error: cound not find the default time unit');


dataInfo = getDataColumnLabelsSettings(expJson);

if(~isempty(dataInfo.L.settings))
  units.length=dataInfo.L.settings.unit;
else
  lengthUnit = ddfData610.Units{1};
  lengthScale = ddfData610.Scale_units_V(1);
  if(lengthScale > 1)
    if(strcmp(lengthUnit(1,1),'mm') && lengthScale==1000)
      lengthUnit = 'm';
    else
      assert(0,'Error: Unrecognized length unit and scaling');
    end
  end
  units.length=lengthUnit;
end

if(~isempty(dataInfo.F.settings))
  units.force=dataInfo.F.settings.unit;
else
  forceUnit = ddfData610.Units{1};
  forceScale = ddfData610.Scale_units_V(1);
  if(forceScale > 1)
    if(strcmp(forceUnit(1,1),'mN') && forceScale==1000)
      forceUnit = 'N';
    else
      assert(0,'Error: Unrecognized force unit and scaling');
    end
  end
  units.force=forceUnit;

end

%
% Stimulation voltage and current are not always recorded. Often when 
% this data is recorded the units information in the ddfData is missing.
%
if(~isempty(dataInfo.SV.settings))
  units.voltage=dataInfo.SV.settings.unit;
end
if(~isempty(dataInfo.SC.settings))
  units.current=dataInfo.SC.settings.unit;
end

  