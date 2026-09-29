function [errV, mdl] = calcErrorOfSinusoid600A(params,settings)

idxOptVar = settings.optVarIndex;

t0            = settings.paramOffset(1);
y0            = settings.paramOffset(2);
frequency_Hz  = settings.paramOffset(3);
amplitudeNorm = settings.paramOffset(4);
numberOfElements=settings.paramOffset(5);


for i=1:1:length(idxOptVar)
  switch idxOptVar(i)
    case 1
      t0 = t0 + params(i).*settings.paramScaling(idxOptVar(i));
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
    otherwise
      assert(0,'Error: desired optVarIndex does not exist');
  end
end

numberOfElements=round(numberOfElements);




amplitude=nan;
if(strcmp(settings.var,'length'))
  amplitude=amplitudeNorm*settings.Lo;
end

index0 = find(settings.time <= t0,1,'last');
index1 = index0+numberOfElements;
if(index1 > length(settings.time))
  index1=length(settings.time);
end

mdl.x = settings.time(index0:index1);
mdl.y = amplitude.*sin( (frequency_Hz*2*pi*settings.timeScaling).*(mdl.x-t0) ) + y0;
errV  = mdl.y-settings.(settings.var)(index0:index1);
errV  = (errV./settings.scaling);


flag_debug=0;
if(flag_debug==1)
  fig_debug=figure;
  plot( settings.time,...
        settings.(settings.var),...
        '-','Color',[1,1,1].*0.75,'LineWidth',1.5);
  hold on;

  plot(mdl.x,mdl.y,'-','Color',[0,0,1]);
  hold on;
  xlabel('Time (ms)');
  ylabel((settings.var));
  here=1;
  close(fig_debug);
end