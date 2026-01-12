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

flag_readHeader         = 1;
flag_checkSha256Sum     = 1; %Might not work on Windows

folderName             = '20251107_middle_spring';%'20260108_impedance_larb_spring';
%'20251225_impedance_larb_nitrile';
keyword.label          = 'Larb-Stochastic';
keyword.controlFunction= 'Length-Arb';

modelSettings.type = 0; 
% 0. spring-damper in parallel
% 1. spring-damper in series
modelSettings.numberOfParameters=1;
modelSettings.zeroPhaseResponseSlope=0;

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
    disp(experimentJson.trials{i});
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
    
    %Check the sha256sum
    if(flag_checkSha256Sum==1)
        [status,cmdout] =  system(['sha256sum ',dataPath]);
        idx = strfind(cmdout,' ');        
        idx=idx-1;
        sha256Sum = cmdout;
        sha256Sum = sha256Sum(1,1:idx);

        if(strcmp(sha256Sum,trialJson.data.sha256)==0)
            here=1;
        end
        assert(strcmp(sha256Sum,trialJson.data.sha256)==1,...
          sprintf(['Error: sha256 hash of the experimental data does ',...
                   'not match the value in the json file.\n ',...
                   '\n data %s\n sha256: %s\n\n json: %s\n sha256: %s\n'],...
                    dataPath, sha256Sum, trialStr, trialJson.data.sha256));
    end


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

    bandwidth = trialJson.segments(indexSegmentLarb).meta_data.bandwidth';
    amplitude = trialJson.segments(indexSegmentLarb).meta_data.amplitude;
    
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

    expData.x = x;
    expData.y = y;
    expData.time=timeVec;
    expData.bandwidth = bandwidth(1,2);
    expData.sampleFrequency = sampleFrequency;

    dfreq = 1;
    idxFreq     = find(Hs.frequencyHz <= (bandwidth(1,2)+dfreq));
    idxFreqBand = find(Hs.frequencyHz <= bandwidth(1,2) ...
                     & Hs.frequencyHz >= bandwidth(1,1));

    %%
    % Fit a first order low pass model to the response
    %%

    omega3dB_Hz = 250;    

    omega               = Hs.frequency;
    params.k            = 1.4;
    params.beta         = (0.5/(2*pi*100));
    params.m            = 0;
    params.tau          = 1/(omega3dB_Hz*2*pi);   
    params.delay        = 0.005; %in seconds

    params.bandwidth    = bandwidth(1,2);
    params.sampleFrequency= sampleFrequency;
    params.time         = auroraData.Data.Time.Values(dataIndex);
    params.x            = ifft(fft(x),'symmetric');
    params.type         = modelSettings.type;

    samples     = length(x);
    timeVec     = [0:(1/(samples-1)):1]' .* (samples/sampleFrequency);
    freqHz      = [1:1:samples]' .*(sampleFrequency/samples);
    freq        = freqHz.*(2*pi);

    params.xdot         = ifft(fft(x).*(complex(0,1).*freq) ,'symmetric');
    params.frequency    = freq;
    params.frequencyHz  = freqHz;

    flag_checkXdot=0;
    if(flag_checkXdot==1)
        xdotNum = calcCentralDifferenceDataSeries(timeVec,x);

        figXdotCheck = figure;
        subplot(2,1,1);
        plot(timeVec,params.xdot,'-b');
        hold on;
        plot(timeVec,xdotNum,'-r');
        hold on;
        xlabel('Time (s)');
        ylabel('mm/s');
        title('xdot');

        subplot(2,1,2);
        plot(timeVec,params.xdot-xdotNum,'-k');
        hold on;
        xlabel('Time (s)');
        ylabel('mm/s');
        title('xdot error');
        
        here=1;
    end

    xdotNum = calcCentralDifferenceDataSeries(timeVec,x);


    model = calcImpedanceModelFrequencyResponse600A(params);

    %%
    % Fit the spring model
    %%

    optSettings.type=1;
    % 1. min rmse gain error
    % 2. min rmse phase error
    % 3. min rmse of the slope of the phase error
    optSettings.bandwidth = params.bandwidth.*[0.05,0.95];
    optSettings.scaling=[];
    optSettings.objScaling=1;
    optSettings.lambda = 0.9;

    optSettings.phasePolishingInterations = 10;

    lambdaSchedule = [0.9,0.1,0.01,0];

    for indexLambda = 1:1:length(lambdaSchedule)
        optSettings.lambda = lambdaSchedule(indexLambda);

        lsqnonlinOptions =...
            optimoptions('lsqnonlin','MaxFunctionEvaluations',2000,...
                         'Algorithm','trust-region-reflective',...
                         'Display','none');
        if(indexLambda == length(lambdaSchedule))
            lsqnonlinOptions =...
                optimoptions('lsqnonlin','MaxFunctionEvaluations',2000,...
                             'Algorithm','trust-region-reflective',...
                             'Display','none');
        end

        %
        % Fit the delay to the phase response
        %    
    
        x0 = [1];
        optSettings.scaling = params.delay;
        lb = [x0].*0;
        ub = [x0].*10;
        paramNames = {'delay'};
        for j=1:1:length(paramNames)
            model.([paramNames{j},'_bounds'])=[];
        end    
        
        optSettings.type = 2;

        errFcn = @(argX)calcErrorOfImpedanceModel600A(...
                            argX, paramNames,...
                            optSettings, params, expData);
        errVec = errFcn(x0);
        optSettings.objScaling = 1/sqrt(sum(errVec.^2));    
        [xSol, resnorm, residual,exitflag,output] = ...
            lsqnonlin(errFcn,x0,lb,ub,lsqnonlinOptions);
        
    
        for j=1:1:length(xSol)
            params.(paramNames{j})=xSol(j)*optSettings.scaling(j);
        end
        
        %
        % Polish the 
        %
        if(modelSettings.zeroPhaseResponseSlope==1)
            
            delayBest = calcDelayToZeroPhaseResponseSlope(...
                                    params,...
                                    expData,...
                                    optSettings.bandwidth,...
                                    optSettings.phasePolishingInterations);            

            params.delay = delayBest;
        end


        %
        % Fit k & d of the spring to the gain response
        %
        switch modelSettings.numberOfParameters
            case 1
                x0 = [1]; 
                params.k            = 1.4;
                params.beta         = 0;
                optSettings.scaling = [params.k];
                paramNames = {'k'};

            case 2
                x0 = [1,1]; 
                params.k            = 1.4;
                params.beta         = (0.5/(2*pi*100));                
                optSettings.scaling = [params.k,params.beta];
                paramNames = {'k','beta'};                
            otherwise assert(0,'Error modelSettings.numberOfParameters incorrectly set');
        end
        
        lb = [x0].*0;
        ub = [x0].*10;

        for j=1:1:length(paramNames)
            model.([paramNames{j},'_bounds'])=[];
        end
        optSettings.type = 1; %1. gain error, 2. phase error
        errFcn = @(argX)calcErrorOfImpedanceModel600A(...
                            argX, paramNames,...
                            optSettings, params, expData);
        errVec = errFcn(x0);
        optSettings.objScaling = 1/sqrt(sum(errVec.^2));
        [xSol, resnorm, residual,exitflag,output] = ...
            lsqnonlin(errFcn,x0,lb,ub,lsqnonlinOptions);
    
%         disp('lsqnonlin output');
%         for j=1:1:length(paramNames)
%             disp(paramNames{j});
%         end
%         disp(output);
    
        for j=1:1:length(xSol)
            params.(paramNames{j})=xSol(j)*optSettings.scaling(j);
        end
    
    
    end

    %
    % Evaluate the fitted model response
    %
    model = calcImpedanceModelFrequencyResponse600A(params);

    %
    % Evaluate the delay-corrected experimental data
    %
    timeDelayedVec  = expData.time + params.delay;
    yDelayed        = interp1(  expData.time, ...
                                expData.y,...
                                timeDelayedVec,...
                                'linear','extrap');
    
    HsFit = evaluateGainPhaseCoherenceSq(  ...
                        expData.x,...
                        yDelayed,...
                        expData.bandwidth,...
                        expData.sampleFrequency);    
    


    %%
    % Plot the coherence squared  
    %%    
    idxRow = 2;
    subplot('Position',reshape(subPlotPanelGeneric(idxRow,i,:),1,4));    
    plot(Hs.frequencyHz(idxFreq),Hs.gain(idxFreq),'-','Color',[1,1,1].*0.75);
    hold on;
    plot(HsFit.frequencyHz(idxFreq),HsFit.gain(idxFreq),'-','Color',[1,1,1].*0.5);
    hold on;
    plot(model.frequencyHz(model.idxBandwidth),...
         model.gain(model.idxBandwidth),'--k');
    hold on;
    for j=1:1:2
        plot([optSettings.bandwidth(j);optSettings.bandwidth(j)],...
             [min(HsFit.gain(idxFreq)),max(HsFit.gain(idxFreq))],...
             '-c');
        hold on;
    end
    text(max(HsFit.frequencyHz(idxFreq)),...
         min(HsFit.gain(idxFreq)),...
         sprintf(['%1.2e k\n',...
                  '%1.2e beta\n',...
                  '%1.2e delay'],...
                 params.k,...
                 params.beta,...
                 params.delay),...
                 'HorizontalAlignment','right',...
                 'VerticalAlignment','bottom',...
                 'FontSize',8);
    hold on;
    box off;    
    xlabel('Frequency (Hz)');
    ylabel(sprintf('Gain (%s/%s)',...
            auroraData.Data.Fin.Unit,auroraData.Data.Lin.Unit));

    idxRow = 3;
    subplot('Position',reshape(subPlotPanelGeneric(idxRow,i,:),1,4));
    plot(Hs.frequencyHz(idxFreq),Hs.phase(idxFreq).*(180/pi),'-','Color',[1,1,1].*0.75);
    hold on;
    plot(HsFit.frequencyHz(idxFreq),HsFit.phase(idxFreq).*(180/pi),'-','Color',[1,1,1].*0.25);
    hold on;
    plot(model.frequencyHz(model.idxBandwidth),...
         model.phase(model.idxBandwidth).*(180/pi),'--k');
    hold on;    
    
    box off;    
    xlabel('Frequency (Hz)');
    ylabel('Phase ($$^o$$)');

    idxRow = 4;
    subplot('Position',reshape(subPlotPanelGeneric(idxRow,i,:),1,4));
    plot(Hs.frequencyHz(idxFreq),Hs.coherenceSq(idxFreq),'-','Color',[1,1,1].*0.75);
    hold on;
    plot(HsFit.frequencyHz(idxFreq),HsFit.coherenceSq(idxFreq),'-','Color',[1,1,1].*0.25);
    hold on;
    box off;    
    xlabel('Frequency (Hz)');
    ylabel('Coherence-Sq');

    here=1;

end

outputPlotDir = fullfile(projectFolders.output_plots,folderName);
if(~exist(outputPlotDir,'dir'))
    mkdir(outputPlotDir);
end

figH=configPlotExporter(figH, ...
                    pageWidthGeneric, pageHeightGeneric);
fileName =    ['fig_FrequencyResponse_',folderName];
print('-dpdf', fullfile(outputPlotDir,[fileName,'.pdf']));    
saveas(figH,fullfile(outputPlotDir,[fileName,'.fig']));

