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

folderName             = '20251107_middle_spring';
keyword.label          = 'Larb-Stochastic';
keyword.controlFunction= 'Length-Arb';

larbProperties(4) = struct('number',0,'bandwidth',[0,0],'amplitude',[0]);

waveSet                = 0;
switch folderName
    case '20251030'
        waveSet=1;
    case '20251031'
        waveSet=2;
    case '20251104'
        waveSet=2;
    case '20251107_short_spring'
        waveSet=2;
    case '20251107_middle_spring'
        waveSet=2;        
    otherwise
        assert(0,'Error: Unexpected date');
end

switch waveSet
    case 1
        i=1;
        larbProperties(i).id = 2;
        larbProperties(i).bandwidth = [0,90];
        larbProperties(i).amplitude = 0.01;
        
    case 2
        i=1;
        larbProperties(i).id = i;
        larbProperties(i).bandwidth = [0,15];
        larbProperties(i).amplitude = 0.01;
        i=i+1;
        larbProperties(i).id = i;
        larbProperties(i).bandwidth = [0,90];
        larbProperties(i).amplitude = 0.01;
        i=i+1;
        larbProperties(i).id = i;
        larbProperties(i).bandwidth = [0,15];
        larbProperties(i).amplitude = 0.001;
        i=i+1;
        larbProperties(i).id = i;
        larbProperties(i).bandwidth = [0,90];
        larbProperties(i).amplitude = 0.001;

end



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
        if(strcmp(dataLabels(i).segmentLabels(j).name,keyword.label))
            assert(idxPlot==0,['Error: multiple segments have the name',...
                                keyword.label]);
            idxPlot=j;
        end
    end
    assert(idxPlot~=0,['Error: could not find segment with ',keyword.label]);

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
    for j=1:1:length(auroraData.Test_Protocol.Control_Function.Value)
        commandName = auroraData.Test_Protocol.Control_Function.Value{j};

        if(contains(commandName,keyword.controlFunction))
            optionsStr = auroraData.Test_Protocol.Options.Value{j};
            idxTmp = strfind(optionsStr,' ');
            idxWave = str2double(optionsStr(1:min(idxTmp)));
            for k=1:1:length(larbProperties)
                if(idxWave == larbProperties(k).id)
                    bandwidth = larbProperties(k).bandwidth;
                    amplitude = larbProperties(k).amplitude;
                end
            end
        end
        
    end
    assert(idxWave~=0,'Error: could not find the correct wave number');
    assert(isempty(bandwidth)==0,'Error: could not find the correct larb properties');
    assert(isempty(amplitude)==0,'Error: could not find the correct larb properties');

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
    
    titleStrA = dataConfig.titleTrial{i};
    titleStrB = sprintf('%i Hz, %1.3f Lo',bandwidth(1,2),amplitude);

    title([titleStrA,':', titleStrB]);

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

    %[freqHz, gain, phase,coherenceSq] = ...
    Hs = evaluateGainPhaseCoherenceSq(  x,...
                                        y,...
                                        bandwidth(1,2),...
                                        sampleFrequency);    

    dfreq = 1;
    idxFreq     = find(Hs.frequencyHz <= (bandwidth(1,2)+dfreq));
    idxFreqBand = find(Hs.frequencyHz <= bandwidth(1,2) ...
                     & Hs.frequencyHz >= bandwidth(1,1));
    %%
    % Plot the coherence squared  
    %%    
    idxRow = 2;
    subplot('Position',reshape(subPlotPanelGeneric(idxRow,i,:),1,4));
    plot(Hs.frequencyHz(idxFreq),Hs.gain(idxFreq));
    hold on;
    box off;    
    xlabel('Frequency (Hz)');
    ylabel(sprintf('Gain (%s/%s)',...
            auroraData.Data.Fin.Unit,auroraData.Data.Lin.Unit));

    idxRow = 3;
    subplot('Position',reshape(subPlotPanelGeneric(idxRow,i,:),1,4));
    plot(Hs.frequencyHz(idxFreq),Hs.phase(idxFreq).*(180/pi));
    hold on;
    box off;    
    xlabel('Frequency (Hz)');
    ylabel('Phase ($$^o$$)');

    idxRow = 4;
    subplot('Position',reshape(subPlotPanelGeneric(idxRow,i,:),1,4));
    plot(Hs.frequencyHz(idxFreq),Hs.coherenceSq(idxFreq));
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
fileName =    ['fig_FrequencyResponse_',folderName];
print('-dpdf', fullfile(outputPlotDir,[fileName,'.pdf']));    
saveas(figH,fullfile(outputPlotDir,[fileName,'.fig']));

