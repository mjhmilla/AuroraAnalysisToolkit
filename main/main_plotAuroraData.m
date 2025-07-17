clc;
close all;
clear all;


rootDir         = getRootProjectDirectory();
projectFolders  = getProjectFolders(rootDir);

addpath(projectFolders.aurora610A);
addpath(projectFolders.common);

folder600A = '20250604';
file600A   = '01_isometric_10Lo_202564.dat';


folder610A = fullfile('20250710_610A_SOL','normalization');
file610A   = 'normalization_04_isometric_20250710.ddf';


%fullFilePath600A = fullfile(projectFolders.data_600A,...
%                            folder600A,...
%                            file600A);

fullFilePath610A = fullfile(projectFolders.data_610A,...
                            folder610A,...
                            file610A);

ddfData610A = readAuroraData610A(fullFilePath610A);

