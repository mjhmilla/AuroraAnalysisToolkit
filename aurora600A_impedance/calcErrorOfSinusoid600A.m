function [errV, mdl] = calcErrorOfSinusoid600A(params,settings)

paramsUpd=params.*settings.paramScaling;

t0           = paramsUpd(1);
y0           = paramsUpd(2);
frequency_Hz = paramsUpd(3);
amplitudeNorm    = paramsUpd(4);

amplitude=nan;
if(strcmp(settings.var,'length'))
  amplitude=amplitudeNorm*settings.Lo;
end

index0 = find(settings.time <= t0,1,'last');
index1 = index0+settings.number_of_elements;

mdl.x = settings.time(index0:index1);
mdl.y = amplitude.*sin( (frequency_Hz*2*pi*settings.timeScaling).*(mdl.x-t0) ) + y0;
errV  = mdl.y-settings.(settings.var)(index0:index1);
errV  = errV./settings.scaling;


flag_debug=0;
if(flag_debug==1)
  fig_debug=figure;
  plot( settings.time,...
        settings.(settings.var),...
        '-','Color',[1,1,1].*0.5);
  hold on;

  plot(mdl.x,mdl.y,'-','Color',[0,0,0]);
  hold on;
  xlabel('Time (ms)');
  ylabel((settings.var));
  here=1;
  close(fig_debug);
end