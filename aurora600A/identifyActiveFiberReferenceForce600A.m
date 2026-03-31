%%
% SPDX-FileCopyrightText: 2025 Matthew Millard <millard.matthew@gmail.com>
%
% SPDX-License-Identifier: MIT
%
%%
function [forceReference, indexReference] ...
            = identifyActiveFiberReferenceForce600A(...
                    forceSeries, ...
                    forceNoiseThreshold,...
                    filterFrequency,...
                    samplingFrequency,...
                    flagPlot)
%%
% This function is used to evaluate the first data point in forceSeries which
% has a noise envelope that is less than forceNoiseThreshold. This function is
% used to identify a reference force from a muscle fiber experiment in which
% bath changes are done mechanically and introduce a lot of noise into the
% force sensor data. In the case where the bath height is unknown (which is 
% generally true), a refrence force value needs to be extracted from the 
% sensor data as quickly as possible.
%
% @param forceSeries: 
%   The raw force data to analyze. This segment should begin with the bath 
%   change operation.
%
% @param forceNoiseThreshold (typical: 0.025 mN)
%   The maximum amount of noise permitted in the signal. Force from the Aurora
%   1400A has about +/-1 mN at its maximum but quickly drops to small values. 
%   
%
% @param filterFrequency (in Hz)
%   The signal is estimated by filtering the forceSeries data using a 
%   dual-low-pass Butter worth filter at this frequency. The noise is then
%   estimated by subtracting the filtered signal from forceSeries.
%
% @param samplingFrequency (in Hz)
%   The sampling frequency used in forceSeries
%
% @param flagPlot
%   Set to 1 if you want to see an annotated plot showing forceSeries, the 
%   filtered signal, the envelope of the noisy force data, and the reference
%   point
% 
% @param forceReference
%   The value of the filtered forceSeries data at the location of indexReference
%
% @param indexReference
%   The index of the last index of the envelope of the noise signal that is
%   less than forceNoiseThreshold, when the data is scanned from right to left.
%
%%


nyquistFrequency = 0.5*samplingFrequency;
[b,a]=butter(2,filterFrequency/nyquistFrequency);

forceFiltered   = filtfilt(b,a,forceSeries);
noiseAbs        = abs(forceSeries-forceFiltered);
noiseEnvelope   = filtfilt(b,a,noiseAbs);

indexReference = length(noiseEnvelope);
while( noiseEnvelope(indexReference) <= forceNoiseThreshold ...
        && indexReference > 1 )
    indexReference=indexReference-1;
end

forceReference = nan;
indexReference = indexReference+1;
if(noiseEnvelope(indexReference) <= forceNoiseThreshold)
    forceReference = forceFiltered(indexReference);
end

if(flagPlot==1)
    figTest=figure;
    
    timeSeries = [1:1:length(forceSeries)]' .* (1/samplingFrequency);
    timeSeries = reshape(timeSeries,...
        size(forceSeries,1),size(forceSeries,2));

    plot(timeSeries,forceSeries,'-','Color',[1,1,1].*0.75,...
            'DisplayName','Raw');
    hold on;
    plot(timeSeries,forceFiltered,'-','Color',[0,0,0],...
            'DisplayName','Filtered');
    hold on;
    plot(timeSeries,noiseEnvelope,'-','Color',[0,0,1],...
            'DisplayName','Noise Envelope');
    hold on;

    plot([min(timeSeries),max(timeSeries)],[1,1].*forceNoiseThreshold,...
         '-','Color',[1,1,1],'LineWidth',1.5,'HandleVisibility','off');
    hold on;
    plot([min(timeSeries),max(timeSeries)],[1,1].*forceNoiseThreshold,...
         '-.','Color',[0,0,0],'LineWidth',0.5,'HandleVisibility','off');
    hold on;
    
    plot(timeSeries(indexReference),noiseEnvelope(indexReference),...
         'o','Color',[0,0,1],'DisplayName','Noise Reference');
    hold on;

    deltaY = (max(forceSeries)-min(forceSeries)).*0.25;

    plot([1,1].*timeSeries(indexReference),...
         [noiseEnvelope(indexReference),...
         (noiseEnvelope(indexReference)+deltaY)],...
         '-','Color',[0,0,1],'HandleVisibility','off');
    hold on;

    text(timeSeries(indexReference),...
         noiseEnvelope(indexReference)+deltaY,...
         sprintf('%s%1.2e',...
            '\sigma=',forceFiltered(indexReference)),...
         'HorizontalAlignment','left',...
         'VerticalAlignment','bottom',...
         'FontSize',10,...
         'Rotation',0,...
         'Color',[0,0,1]);
    hold on;

    plot([1,1].*timeSeries(indexReference),...
         [forceFiltered(indexReference),forceFiltered(indexReference)-deltaY],...
         '-','Color',[1,0,0],'HandleVisibility','off');
    hold on;

    plot(timeSeries(indexReference),...
         forceFiltered(indexReference),...
         'x','Color',[1,0,0],'DisplayName','Force Reference');
    hold on;

    text(timeSeries(indexReference),...
        forceFiltered(indexReference)-deltaY,...
         sprintf('f=%1.2e',...
            forceFiltered(indexReference)),...
         'HorizontalAlignment','left',...
         'VerticalAlignment','top',...
         'FontSize',10,...
         'Rotation',0,...
         'Color',[1,0,0]);
    hold on;
    box off;
    legend('Location','NorthEast');
    legend boxoff;
    xlabel('Time');
    ylabel('Force');
    
end
