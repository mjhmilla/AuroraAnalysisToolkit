function [gain,phase,coherenceSq] = evaluateGainPhaseCoherenceSq(...
                                            xTimeDomain,...
                                            yTimeDomain,...
                                            bandwidth,...
                                            sampleFrequency)

%%
% SPDX-FileCopyrightText: 2023 Matthew Millard <millard.matthew@gmail.com>
%
% SPDX-License-Identifier: MIT
%
% If you use this code in your work please cite the pre-print of this paper
% or the most recent peer-reviewed version of this paper:
%
%    Matthew Millard, David W. Franklin, Walter Herzog. 
%    A three filament mechanistic model of musculotendon force and impedance. 
%    bioRxiv 2023.03.27.534347; doi: https://doi.org/10.1101/2023.03.27.534347 
%
%%            
%Evaluate the cross-spectral density between x and y using Welch's method
%Welch's method breaks up the time domain signals into overlapping blocks
%Each block is tranformed into the frequency domain, and the final
%result is the average of the each block in the frequency domain.
%The resulting signal has a lower frequency resolution but is not
%so sensitive to noise
[cpsd_Gxy,cpsd_Fxy] = cpsd(xTimeDomain,yTimeDomain,[],[],[],sampleFrequency,'onesided');
[cpsd_Gxx,cpsd_Fxx] = cpsd(xTimeDomain,xTimeDomain,[],[],[],sampleFrequency,'onesided');
[cpsd_Gyy,cpsd_Fyy] = cpsd(yTimeDomain,yTimeDomain,[],[],[],sampleFrequency,'onesided');
[cpsd_Gyx,cpsd_Fyx] = cpsd(yTimeDomain,xTimeDomain,[],[],[],sampleFrequency,'onesided');

coherenceSq     = ( abs(cpsd_Gyx).*abs(cpsd_Gyx) ) ./ (cpsd_Gxx.*cpsd_Gyy) ;
freqHz          = cpsd_Fyx;
freqRadians     = freqHz.*(2*pi);
idxBW         = find(freqHz <= max(bandwidth+1));

gain  = abs(cpsd_Gyx./cpsd_Gxx);
phase = angle(cpsd_Gyx./cpsd_Gxx);

%Check this evaluation with Matlab's own internal function
[coherenceSqCheck,freqCpsdCheck] = mscohere(xTimeDomain,yTimeDomain,[],[],[],sampleFrequency);
assert( max(abs(coherenceSqCheck-coherenceSq)) < 1e-6);