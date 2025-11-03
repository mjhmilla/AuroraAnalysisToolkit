clc;
close all;
clear all;


rootDir         = getRootProjectDirectory();
projectFolders  = getProjectFolders(rootDir);


addpath(projectFolders.aurora610A);
addpath(projectFolders.common);
addpath(projectFolders.postprocessing);



dataSets(2) = struct('folder','','files',{''});
dataSets(1).folder = fullfile('20250710_610A_EDL','preparation');
dataSets(1).files = {'FFR.ddf','FLR.ddf'};

dataSets(2).folder = fullfile('20250710_610A_EDL','normalization');
dataSets(2).files = {'normalization_03_twitchForceLength_20250710.ddf',...
                     'normalization_04_isometric_20250710.ddf'};

dataCount = 0;
for i=1:1:length(dataSets)
    dataCount = dataCount + length(dataSets(i).files);
end
%%
% Plot configuration
%%
numberOfHorizontalPlotColumnsGeneric    = 1;
numberOfVerticalPlotRowsGeneric         = dataCount;
plotWidth                               = ones(1,1).*8;
plotHeight                              = ones(dataCount,1).*4;
plotHorizMarginCm                       = 3;
plotVertMarginCm                        = 3;
baseFontSize                            = 12;

[subPlotPanelGeneric, pageWidthGeneric,pageHeightGeneric]= ...
  plotConfigGeneric(  numberOfHorizontalPlotColumnsGeneric,...
                      numberOfVerticalPlotRowsGeneric,...
                      plotWidth,...
                      plotHeight,...
                      plotHorizMarginCm,...
                      plotVertMarginCm,...
                      baseFontSize); 

%%
% Whole-muscle experiments
%%
fig = figure;
indexData = 1;
for i=1:1:length(dataSets)
    for j=1:1:length(dataSets(i).files)
        fullFilePath610A = fullfile(projectFolders.data_610A,...
                                    dataSets(i).folder,...
                                    dataSets(i).files{j});
        
        ddfData610A = readAuroraData610A(fullFilePath610A);
    
        assert(strcmp(ddfData610A.data.columnNames{1},'Sample'),...
               'Error: Unexpected column name');
        assert(strcmp(ddfData610A.data.columnNames{2},'AI0'),...
               'Error: Unexpected column name');
        assert(strcmp(ddfData610A.data.columnNames{3},'AI1'),...
               'Error: Unexpected column name');
    
        frequencyHz = ddfData610A.Sample_Frequency_Hz;
        timeV = ddfData610A.data.Sample.Values(:,1) ./ frequencyHz;
        
        figure(fig);
        subplot('Position',reshape(subPlotPanelGeneric(indexData,1,:),1,4));
    
        yyaxis left;
        idxCol = 1;
        plot(timeV, ddfData610A.data.AI0.Values(:,1)...
                  .*ddfData610A.Scale_units_V(1,idxCol));
        hold on;
    
        xlabel('Time (s)');
        ylabel(['Length (',ddfData610A.Units{1},')']);
        
    
        yyaxis right;
        plot(timeV, ddfData610A.data.AI1.Values(:,1) ...
                  .*ddfData610A.Scale_units_V(1,2));
        
        hold on;
        ylabel(['Force (',ddfData610A.Units{2},')']);
        
        titleStr = replace(dataSets(i).files{j},'_','\_');
        title(titleStr);
    
    
        
        indexData = indexData+1;
        here=1;
    end
end
