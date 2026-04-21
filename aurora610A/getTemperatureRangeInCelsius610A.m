function tempRange=getTemperatureRangeInCelsius610A(idxM,expJson,expName)

found=0;        
for i=1:1:length(expJson.experiment.manually_measured_temperature_C)
  
  idxTemp = find(expJson.experiment.manually_measured_temperature_C(i).measurements ...
                  ==idxM,1);
  
  if(~isempty(idxTemp))
    assert(found==0,['Error: ',expName,...
      ' contains repeated measurements across the different',...
      ' temperatures listed']);            
    found=1;
    tempRange=...
      expJson.experiment.manually_measured_temperature_C(i).range_C;
  end
end