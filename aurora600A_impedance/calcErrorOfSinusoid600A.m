function [errV, mdl] = calcErrorOfSinusoid600A(params,settings)

paramsUpd=params.*settings.paramScaling;

t0           = paramsUpd(1);
y0           = paramsUpd(2);
frequency_Hz = paramsUpd(3);
length_Lo    = paramsUpd(4);

index0 = find(settings.time < t0,1,'last');
index1 = find(settings.time > (t0+settings.duration_ms),1,'first');

mdl.x = settings.time(index0:index1);
mdl.y = length_Lo.*sin( (frequency_Hz*2*pi*settings.timeScaling).*(mdl.x-t0) ) + y0;
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