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

dataFolder      = fullfile(projectFolders.data_600A,folderName);
experimentStr   = fileread(fullfile(dataFolder,[folderName,'.json']));
experimentJson  = jsondecode(experimentStr);

indexSegmentLarb = 1;



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


numberOfHorizontalPlotColumnsGeneric    = length(experimentJson.trials);
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

for i=1:1:length(experimentJson.trials)
    %%
    % Read in the meta data
    %%    
    trialStr = fileread(fullfile(dataFolder,experimentJson.trials{i}));
    trialJson = jsondecode(trialStr);
    
    %%
    % Add missing fields in the trial json file from the experiments
    % section
    %%
    experimentFields = fields(experimentJson.experiment);
    trialExperimentFields = fields(trialJson.experiment);
    for j=1:1:length(experimentFields)
        if(~isfield(trialJson.experiment,experimentFields{j}))
            trialJson.experiment.(experimentFields{j}) = ...
                experimentJson.experiment.(experimentFields{j});
        end
    end


    %%
    % Fetch the experimental data files
    %%
    fileType = {'data','protocol'};
    filePaths = [{''};{''}];
    for j=1:1:length(fileType)
        if(length(trialJson.(fileType{j}).file)>0)
            filePaths{j} = trialJson.(fileType{j}).file{1};
            if(length(trialJson.(fileType{j}).file)>1)
                for k=2:1:length(trialJson.(fileType{j}).file)
                    filePaths{j} = [filePaths{j},filesep,trialJson.(fileType{j}).file{k}];
                end
            end
        end
    end

    dataPath = fullfile(dataFolder,filePaths{1});
    protocolPath= fullfile(dataFolder,filePaths{2});
    
    auroraData = readAuroraData600A(dataPath,flag_readHeader);
    
    %%
    % Get the interval to plot
    %%
    idxPlot=0;
    for j=1:1:length(trialJson.segments)
        if(strcmp(trialJson.segments(j).type,keyword.label))
            assert(idxPlot==0,['Error: multiple segments have the name',...
                                keyword.label]);
            idxPlot=j;
        end
    end
    assert(idxPlot~=0,['Error: could not find segment with ',keyword.label]);

    %%
    %Extract the indicies to plot
    %%
    timeStart = trialJson.segments(idxPlot).duration(1);
    timeEnd   = trialJson.segments(idxPlot).duration(2);
    dataIndex = find( auroraData.Data.Time.Values >= timeStart ...
                    & auroraData.Data.Time.Values <= timeEnd); 

    %%
    %Find the wave number
    %%
    %idxWave = trialJson.waveform.id;
    segmentType=trialJson.segments(indexSegmentLarb).type;
    assert(strcmp('Larb-Stochastic',segmentType),...
        ['Error: expected Larb-Stochastic at segment ',num2str(indexSegmentLarb)]);

    bandwidth = trialJson.segments(indexSegmentLarb).bandwidth';
    amplitude = trialJson.segments(indexSegmentLarb).amplitude;
    
    %assert(idxWave~=0,'Error: could not find the correct wave number');
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
    
    titleStrA = trialJson.experiment.title;
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
    % Fit a first order low pass model to the response
    %%

    

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

outputPlotDir = fullfile(projectFolders.output_plots,dataFolder);
if(~exist(outputPlotDir,'dir'))
    mkdir(outputPlotDir);
end

figH=configPlotExporter(figH, ...
                    pageWidthGeneric, pageHeightGeneric);
fileName =    ['fig_FrequencyResponse_',folderName];
print('-dpdf', fullfile(outputPlotDir,[fileName,'.pdf']));    
saveas(figH,fullfile(outputPlotDir,[fileName,'.fig']));

