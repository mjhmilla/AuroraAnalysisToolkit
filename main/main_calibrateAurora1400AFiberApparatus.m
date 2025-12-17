%%
% @author M.Millard
% @date 17/12/2025
%
% This script uses the perturbation response of a material with a known
% frequency response to calibrate the response of the 1400 fiber apparatus.
% 
% Inputs: the measured force response from a coil spring or very fine 
%         nitrile whisker to random perturbations. The material needs to 
%         behave like a linear spring with approximately zero damping in
%         response to small perturbations.
%
% Outputs: a model of the frequency response (and hopefully its inverse)
%          of the machine.
%
% All of this work has been done because we noticed that our active and
% passive fibers had a negative phase response. Since this is not
% consistent with existing literature we evaluated the phase response of
% a very small coil spring and also a nitrile whisker. Both of these
% test items should have nearly no damping, and yet, the 1400A reported 
% a phase response with a negative slope. At this point we knew the
% strange response we saw from our experiments was due to the frequency
% response of the Aurora 1400A.
%%

clc;
close all;
clear all;

