function kelvinVoightRodModel = evaluateDelayModelThinKelvinVoightRod(...
                                k_Nm,beta_Nms,...
                                length_M,area_M2,...
                                rho_kgm3,frequency_rad,...
                                flag_plot)



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


kelvinVoightRodModel.frequency  = zeros(size(frequency_rad));
kelvinVoightRodModel.v          = zeros(size(frequency_rad)); %phase velocity
kelvinVoightRodModel.ac         = zeros(size(frequency_rad)); %attenuation 
kelvinVoightRodModel.dt         = zeros(size(frequency_rad)); %delay
kelvinVoightRodModel.dphi       = zeros(size(frequency_rad)); %phase shift

Y   = k_Nm*length_M/area_M2;
eta = beta_Nms*length_M/area_M2;

for i=1:1:length(frequency_rad)
    k2 = rho_kgm3*(frequency_rad(i)^2)/(Y - complex(0,frequency_rad(i)*eta));
    period = (2*pi)/(frequency_rad(i));

    kelvinVoightRodModel.frequency_rad(i) = frequency_rad(i);
    kelvinVoightRodModel.v(i)    =frequency_rad(i)/real(sqrt(k2));

    alpha = imag(sqrt(k2));

    kelvinVoightRodModel.at(i)   = exp(-alpha*length_M);
    kelvinVoightRodModel.dt(i)   =length_M/kelvinVoightRodModel.v(i);
    kelvinVoightRodModel.dphi(i) =2*pi*(kelvinVoightRodModel.dt(i)/period);
end


if(flag_plot==1)
    figKVModel=figure;
    frequencyHz = frequency_rad./(2*pi);
    subplot(4,1,1);        
        plot(frequencyHz,kelvinVoightRodModel.v,'-k');
        xlabel('Frequency (Hz)');
        ylabel('Phase Velocity (m/s)');
        box off;
    subplot(4,1,2);
        plot(frequencyHz,kelvinVoightRodModel.dt,'-k');
        xlabel('Frequency (Hz)');
        ylabel('Delay (s)');
        box off;
    subplot(4,1,3);
        plot(frequencyHz,kelvinVoightRodModel.dphi.*(180/pi),'-k');
        xlabel('Frequency (Hz)');
        ylabel('Phase shift (degrees)');
        box off;
    subplot(4,1,4);
        plot(frequencyHz,kelvinVoightRodModel.at,'-k');
        xlabel('Frequency (Hz)');
        ylabel('Attenuation over length');
        box off;
        
        here=1;
end