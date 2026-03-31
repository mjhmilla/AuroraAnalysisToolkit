function [delays] = calcDelayOfThinKelvinVoightRod(...
                             k,beta,area,rho,frequency)



% Derivation of the phase delay of a slender viscoelastic rod needed for
% step 3:
%
% f: force
% Y: Young's modulus
% n: damping coefficient
%
% e: strain
% Psi: length function
%
% s: stress
% rho: density
% g: gain
% p: phase
%
% Viscoelastic constitutive equation
% 1. s = Ye +n eDot
% 2. e = DPsi_Dx
% 3. s = Y DPsi_Dx + n D2Psi_DxDt
% 
% Force balance and equations of motion
% a: acceleration
% A: area
%
% 4. f = s A = m a
% 5. Fnet = f(x+dx)-f(x-dx), dx->0, Fnet->DF_Dx
% 6. m = rho A dx
% 7. Ds_Dx A dx = (rho A dx) D2Psi_Dt2
% 8. Ds_Dx = (rho) D2Psi_Dt2
% 9. Ds_Dx = Y D2Psi_Dx2 + n D3Psi_Dx2Dt
% 10. rho D2Psi_Dt2 = Y D2Psi_Dx2 + n D3Psi_Dx2Dt
%
% I got up to this point by hand, but used Google Gemini for the next steps
%
% Assume a solution of the form:
%
% 11. Psi(x,t) = Psi0 e^{ i (kx-omega t) }
%
% Where
%   Psi0: amplitude   
%      k: angular wave number, where k=2pi/lambda
%  omega: frequency
%      t: time
%
% 12. DPsi_Dx       = i k Psi(x,t)
% 13. D2Psi_Dx2     = - k^2 Psi(x,t)
% 14. D3Psi_Dx2Dt   =   i k^2 omega Psi(x,t)  
% 15. DPsi_Dt       = - i omega Psi(x,t)
% 16. D2Psi_Dt2     = - omega^2 Psi(x,t)
%
% Substituting 16, 13, and 14 into 10
%
% 17. rho (- omega^2 Psi(x,t)) = Y (- k^2 Psi(x,t)) + n (i k^2 omega Psi(x,t))
% 18. rho (- omega^2) = Y (- k^2 ) + n (i k^2 omega)
% 19. k^2 = rho omega^2 / (Y - n i omega) 
% 20. k^2 = rho omega^2 (Y + n i omega) / (Y^2 - (n omega)^2)
% 20a. k^2 = a + b i
% 20b. a = rho omega^2 Y / (Y^2 - (n omega)^2)      
% 20c. b = rho omega^2 n i omega / (Y^2 - (n omega)^2)
% 20d. k = sqrt( ( sqrt(a^2+b^2)+a)/2 ) + i sign(b) sqrt( ( sqrt(a^2+b^2)-a)/2 ) 
% 21. v = omega / Re(k)
%
% Me from here one
% 21. dt = L/v
% 22. T = (2 pi)/omega
% 23. dphi = atan2(dt,T)
% 
% At each frequency component I adjust the real and complex components
% so that the magnitude is the same but phi i schanged by dphi


delays = zeros(size(frequency));

Y = k/area;
n = beta/area;
for i=1:1:length(delays)
    k2 = rho*(frequency(i)^2)/

end