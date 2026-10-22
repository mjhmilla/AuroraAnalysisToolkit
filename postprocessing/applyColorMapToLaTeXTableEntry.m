function str = applyColorMapToLaTeXTableEntry(str,value, colorMap)

for idxC=1:1:length(colorMap)

  if(value >= colorMap(idxC).lim(1) ...
      && value < colorMap(idxC).lim(2))
    if(~isempty(colorMap(idxC).color))
      str = ['\colorbox{',colorMap(idxC).color,'}{',str,'}'];
    end
  end

end