function [dx, f]= calcMaxwellElementDerivative(t,x,settings)

l=interp1(settings.t,settings.l,t,'linear');

k = settings.k;
beta=settings.beta;

dx=k*(l-x)/beta;

f = k*(l-x);