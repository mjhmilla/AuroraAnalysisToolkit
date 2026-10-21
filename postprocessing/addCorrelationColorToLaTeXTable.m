function str = addCorrelationColorToLaTeXTable(str,value, corrColorMap)

for idC=1:1:length(corrColorMap)

  if(value >= corrColorMap(idxC).lim(1) ...
      && value < corrColorMap(idxC).lim(2))
    if(~isempty(corrColorMap(idxC).color))
      str = ['\textcolor{',corrColorMap(idxC).color,'}'];
    end
  end

end