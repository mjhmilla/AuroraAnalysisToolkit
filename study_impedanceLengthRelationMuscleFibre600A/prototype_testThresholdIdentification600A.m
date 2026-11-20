clc;
close all;
clear all;

forceSeries = dlmread('activationForceExample.csv');

filterFrequency     = 30;   %Hz
samplingFrequency   = 1000; %Hz
forceNoiseThreshold = 0.025; %mN
flagPlot            = 1;

[forceReference, indexReference] ...
            = identifyActiveFiberReferenceForce600A(...
                    forceSeries, ...
                    forceNoiseThreshold,...
                    filterFrequency,...
                    samplingFrequency,...
                    flagPlot);




