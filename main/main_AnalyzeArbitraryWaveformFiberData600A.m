clc;
close all;
clear all;


rootDir         = getRootProjectDirectory();
projectFolders  = getProjectFolders(rootDir);

addpath(projectFolders.aurora600A);
addpath(projectFolders.common);
addpath(projectFolders.postprocessing);
addpath(projectFolders.experiments);
addpath(fullfile(rootDir,'aurora600A_impedance'));

flag_readHeader=1;

folderName = '20251031';
keywordSegmentToPlot = 'Larb-Stochastic';

larbProperties(4) = struct('number',0,'bandwidth',[0,0],'amplitude',[0]);

i=1;
larbProperties(i).keyword = i;
larbProperties(i).bandwidth = [0,15];
larbProperties(i).amplitude = 0.01;
i=i+1;
larbProperties(i).keyword = i;
larbProperties(i).bandwidth = [0,90];
larbProperties(i).amplitude = 0.01;
i=i+1;
larbProperties(i).keyword = i;
larbProperties(i).bandwidth = [0,15];
larbProperties(i).amplitude = 0.001;
i=i+1;
larbProperties(i).keyword = i;
larbProperties(i).bandwidth = [0,90];
larbProperties(i).amplitude = 0.001;


dataConfig = getImpedanceExperimentConfiguration600A(...
                folderName,projectFolders);
dataLabels = readAuroraDataLabelFile600A(dataConfig);


flag_10kHzData = contains(dataConfig.fileNameKeywords{1},'10kHz');

%%
% Plot settings
%%
lineColors = getPaulTolColourSchemes('bright');


[ratMuscleData, ratMuscleMetaData] = ...
        loadRatSkeletalMuscleData(projectFolders);

expDataSetFittingData(3)=struct('optimalSarcomereLength',0,...
                               'minLengthWhereFpeIsLinear',0);

expDataSetFittingData(1).optimalSarcomereLength=2.525;
expDataSetFittingData(2).optimalSarcomereLength=2.525;
expDataSetFittingData(3).optimalSarcomereLength=2.525;

expDataSetFittingData(1).minLengthWhereFpeIsLinear=nan;
expDataSetFittingData(2).minLengthWhereFpeIsLinear=nan;
expDataSetFittingData(3).minLengthWhereFpeIsLinear=0.3;

flag_readDataOnly = 0;

%%
% Plot configuration
%%


numberOfHorizontalPlotColumnsGeneric    = dataConfig.numberOfTrials;
numberOfVerticalPlotRowsGeneric         = 4;
plotWidth                               = ones(1,numberOfHorizontalPlotColumnsGeneric).*6;
plotHeight                              = ones(numberOfVerticalPlotRowsGeneric,1).*6;
plotHorizMarginCm                       = 3;
plotVertMarginCm                        = 2;
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
% Plot configuration
%%

figH = figure;

for i=1:1:length(dataLabels)
    auroraData = readAuroraData600A(dataLabels(i).fileName,flag_readHeader);
    
    %%
    % Get the interval to plot
    %%
    idxPlot=0;
    for j=1:1:length(dataLabels(i).segmentLabels)
        if(strcmp(dataLabels(i).segmentLabels(j).name,keywordSegmentToPlot))
            assert(idxPlot==0,['Error: multiple segments have the name',...
                                keywordSegmentToPlot]);
            idxPlot=j;
        end
    end
    assert(idxPlot~=0,['Error: could not find segment with ',keywordSegmentToPlot]);

    %%
    %Extract the indicies to plot
    %%
    timeStart = dataLabels(i).segmentLabels(idxPlot).timeInterval(1,1);
    timeEnd   = dataLabels(i).segmentLabels(idxPlot).timeInterval(1,2);
    dataIndex = find( auroraData.Data.Time.Values >= timeStart ...
                    & auroraData.Data.Time.Values <= timeEnd); 

    %%
    %Find the wave number
    %%
    idxWave = 0;
    for j=2:1:length(auroraData.Test_Protocol.Control_Function.Value)
        commandName = auroraData.Test_Protocol.Control_Function.Value{j};
        t0 = auroraData.Test_Protocol.Time.Value(j-1);
        t1 = auroraData.Test_Protocol.Time.Value(j);

        if(t0 == timeStart && t1 <= timeEnd)
            optionsStr = auroraData.Test_Protocol.Options.Value{j};
            idxTmp = strfind(optionsStr,' ');
            idxWave = str2double(optionsStr(1:min(idxTmp)));
        end
        
    end
    assert(idxWave~=0,'Error: could not find the correct wave number');

    bandwidth = larbProperties(idxWave).bandwidth;
    amplitude = larbProperties(idxWave).amplitude;

    %%
    % Plot time-length-force    
    %%
    figure(figH);

    idxRow = 1;
    subplot('Position',reshape(subPlotPanelGeneric(idxRow,i,:),1,4));

    yyaxis left;
    plot(auroraData.Data.Time.Values(dataIndex,1),...
         auroraData.Data.Lin.Values(dataIndex,1));...
    hold on;
    box off;    
    xlabel(sprintf('Time (%s)',auroraData.Data.Time.Unit));
    ylabel(sprintf('Length (%s)',auroraData.Data.Lin.Unit));

    yyaxis right;
    plot(auroraData.Data.Time.Values(dataIndex,1),...
         auroraData.Data.Fin.Values(dataIndex,1));...
    hold on;
    box off;    
    ylabel(sprintf('Force (%s)',auroraData.Data.Fin.Unit));
    
    titleStr = replace(dataConfig.fileNameKeywords{i},'_','\_');
    title(titleStr);

    here=1;


    %%
    % Evaluate frequency response   
    %%
    x = auroraData.Data.Lin.Values(dataIndex,1);
    x = x - mean(x);

    y = auroraData.Data.Fin.Values(dataIndex,1);
    y = y-mean(y);
    
    sampleFrequency = auroraData.Setup_Parameters.A_D_Sampling_Rate.Value;
    assert(strcmp(auroraData.Setup_Parameters.A_D_Sampling_Rate.Unit,'Hz'),...
           'Error: A_D_Sampling_Rate should be in Hz');

    samples     = length(x);
    timeVec     = [0:(1/(samples-1)):1]' .* (samples/sampleFrequency);

    [freqHz, gain, phase,coherenceSq] = ...
        evaluateGainPhaseCoherenceSq(...
                                x,...
                                y,...
                                bandwidth(1,2),...
                                sampleFrequency);    

    dfreq = 1;
    idxFreq     = find(freqHz <= (bandwidth(1,2)+dfreq));
    idxFreqBand = find(freqHz <= bandwidth(1,2) ...
                     & freqHz >= bandwidth(1,1));
    %%
    % Plot the coherence squared  
    %%    
    idxRow = 2;
    subplot('Position',reshape(subPlotPanelGeneric(idxRow,i,:),1,4));
    plot(freqHz(idxFreq),gain(idxFreq));
    hold on;
    box off;    
    xlabel('Frequency (Hz)');
    ylabel(sprintf('Gain (%s/%s)',...
            auroraData.Data.Fin.Unit,auroraData.Data.Lin.Unit));

    idxRow = 3;
    subplot('Position',reshape(subPlotPanelGeneric(idxRow,i,:),1,4));
    plot(freqHz(idxFreq),phase(idxFreq).*(180/pi));
    hold on;
    box off;    
    xlabel('Frequency (Hz)');
    ylabel('Phase ($$^o$$)');

    idxRow = 4;
    subplot('Position',reshape(subPlotPanelGeneric(idxRow,i,:),1,4));
    plot(freqHz(idxFreq),coherenceSq(idxFreq));
    hold on;
    box off;    
    xlabel('Frequency (Hz)');
    ylabel('Coherence-Sq');

    here=1;

end

outputPlotDir = fullfile(projectFolders.output_plots,dataConfig.folder);
if(~exist(outputPlotDir,'dir'))
    mkdir(outputPlotDir);
end

figH=configPlotExporter(figH, ...
                    pageWidthGeneric, pageHeightGeneric);
fileName =    ['fig_FrequencyResponse'];
print('-dpdf', fullfile(outputPlotDir,[fileName,'.pdf']));    
saveas(figH,fullfile(outputPlotDir,[fileName,'.fig']));

