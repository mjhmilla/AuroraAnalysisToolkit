function [errV,errDot, mdl] = calcErrorOfSinusoid600A(params,settings)

idxOptVar = settings.optVarIndex;

index0        = settings.paramOffset(1);
y0            = settings.paramOffset(2);
frequency_Hz  = settings.paramOffset(3);
amplitudeNorm = settings.paramOffset(4);
numberOfElements=settings.paramOffset(5);

isIndex0AnOptVar=0;
isNumberOfElementsAnOptVar=0;

for i=1:1:length(idxOptVar)
  switch idxOptVar(i)
    case 1
      index0 = index0 + params(i).*settings.paramScaling(idxOptVar(i));
      index0=round(index0);
      if(index0 < 1)
        index0=1;
      end
      if(index0 > (length(settings.time)-numberOfElements))
        index0=(length(settings.time)-numberOfElements);
      end
      isIndex0AnOptVar=1;
    case 2
      y0 = y0 + params(i).*settings.paramScaling(idxOptVar(i));
    case 3
      frequency_Hz = frequency_Hz ...
                     + params(i).*settings.paramScaling(idxOptVar(i));
    case 4
      amplitudeNorm=amplitudeNorm...
                   +params(i).*settings.paramScaling(idxOptVar(i));      
    case 5
      numberOfElements=numberOfElements...
                    + params(i).*settings.paramScaling(idxOptVar(i)); 
      isNumberOfElementsAnOptVar=1;
    otherwise
      assert(0,'Error: desired optVarIndex does not exist');
  end
end

numberOfElements=round(numberOfElements);




amplitude=nan;
if(strcmp(settings.var,'length'))
  amplitude=amplitudeNorm*settings.Lo;
end

if(isNumberOfElementsAnOptVar == 1) 
  index1 = index0+numberOfElements;
  if(index1 > length(settings.time))
    index1=length(settings.time);
  end
elseif(isIndex0AnOptVar==1)
  index1 = index0+diff(settings.optInterval);
else
  index0 = settings.optInterval(1);
  index1 = settings.optInterval(2);  
end
if(index1 > length(settings.time))
  here=1;
end

t0 = settings.time(index0);

mdl.x = settings.time(index0:index1);
mdl.y = amplitude.*sin( ...
          (frequency_Hz*2*pi*settings.timeScaling).*(mdl.x-t0) ) + y0;
errV  = mdl.y-settings.(settings.var)(index0:index1);
errV  = (errV./settings.scaling);

normDot=  dot(mdl.y,mdl.y);

errDot = dot(mdl.y, settings.(settings.var)(index0:index1))...
         /normDot;


flag_debug=0;
if(flag_debug==1)
  fig_debug=figure;
  subplot(1,2,1);
    plot( settings.time,...
          settings.(settings.var),...
          '-','Color',[1,1,1].*0.75,'LineWidth',1.5);
    hold on;
  
    plot(mdl.x,mdl.y,'-','Color',[0,0,1]);
    hold on;
    xlabel('Time (ms)');
    ylabel((settings.var));
  subplot(1,2,2);
    plot(settings.time(index0:index1),...
         settings.(settings.var)(index0:index1),...
         '-','Color',[1,1,1].*0.75,'LineWidth',1.5);
    hold on;
    plot(mdl.x,mdl.y,'-','Color',[0,0,1]);
    hold on;
    [maxY,idxMaxY] = max(mdl.y);
    text(mdl.x(idxMaxY),mdl.y(idxMaxY),sprintf('%1.6f',errDot));
    hold on;
    xlabel('Time (ms)');
    ylabel([(settings.var), '(Dot Product)']);
  here=1;
  close(fig_debug);
end