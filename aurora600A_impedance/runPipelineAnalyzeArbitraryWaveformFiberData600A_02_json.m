function success = ...
    runPipelineAnalyzeArbitraryWaveformFiberData600A_02_json(...
        folderName, fileKeyWord,specimenType, trialType, ...
        modelSeries, settings,projectFolders)

success=0;
mm2m = 0.001;

fittedModelSeries=modelSeries;

assert(strcmp(settings.daqDelayModel,'frequency-domain'),...
       ['Error: the DAQ delay can only be compensated',...
        ' in the frequency-domain using this implementation']);

flag_readHeader         = 1;
flag_checkSha256Sum     = 1; %Might not work on Windows

setOfSpecimenTypes = {'spring','fiber'};
foundSpecimenType=0;
for i=1:1:length(setOfSpecimenTypes)
    if(strcmp(setOfSpecimenTypes{i},specimenType))
        foundSpecimenType=1;
    end
end
assert(foundSpecimenType,...
    ['Error: specimen name does not contain one of the following'...
          ' keywords: spring or fiber']);


setOfTrialTypes = {'delay','degradation','impedance'};
foundTrialType=0;
for i=1:1:length(setOfTrialTypes)
    if(strcmp(setOfTrialTypes{i},trialType))
        foundTrialType=1;
    end
end
assert(foundTrialType,...
    ['Error: folder name does not contain one of the following'...
          ' keywords: spring, impedance, or degradation']);



keyword.label          = 'Larb-Stochastic';
keyword.controlFunction= 'Length-Arb';





%% 
% Delay model
%
%   There are two sources of delay:
%   1. The longitudinal wave takes time to propagate down the fiber to 
%      the sensor.
%   2. The sensor has a bandwidth of 800 Hz (from Aurora) and the little
%      wire hooks that we use apparently reduce this bandwidth further.
%      For the purpose of simplicity I'm going to model this assuming that
%      it behaves like a low-pass filter
%
% 1. Propagation delay
% - spring: from CE Mungan
%
%          v = L sqrt(k/m)
%          L: length
%          k: stiffness
%          m: mass
%
% - fiber: Each frequency has its own specific delay described 
%         in Pritz 1981 as
%           
%           v  = ve sqrt(2) D / sqrt(D+1)
%           ve = L sqrt(k/m)
%           D  = sqrt(1+ne^2)
%           ne = E''/E'
%
%       : A more detailed derivation from Google Gemini has something a bit
%         different, and unlike Pritz, I can follow all of the steps of the
%         the Gemini derivation. It's quite possible that the two are
%         equivalent. 
%
%
%%
modelSettings.daqDelayModel             = settings.daqDelayModel;
modelSettings.zeroPhaseResponseSlope    = 1;
modelSettings.useManuallySetDaqDelay    = settings.useManuallySetDaqDelay;
modelSettings.coherenceSquaredThreshold = settings.coherenceSquaredThreshold;



%%
% folders
%%
dataFolder      = fullfile(projectFolders.data_600A,folderName);
experimentStr   = fileread(fullfile(dataFolder,[folderName,'.json']));
experimentJson  = jsondecode(experimentStr);

fidLogFile = fopen(fullfile(dataFolder,...
  'log_runPipelineAnalyzeArbitraryWaveformFiberData600A_01_json.txt'),'w');

currentDateTime=datestr(now, 'dd/mm/yy-HH:MM:SS');
fprintf(fidLogFile,'%s\n',currentDateTime);
fprintf('%s\n',currentDateTime);

indexSegmentLarb = 1;
%%
% Default setting
%%
setOfTrialsDefault = [1:1:length(experimentJson.trials)];
setOfTrialsVerified =[];

%%
% Plot settings
%%
lineColors = getPaulTolColourSchemes('bright');



%%
% Scan through the meta data 
% - check the sha256 value
% - count the total number of segments to plot. 
%%
if(settings.checkDataIntegrity==1)

   
    setOfTrialsVerified=verifyDataIntegrityCompletnessOrder(...
                dataFolder,experimentJson,fidLogFile,...
                flag_readHeader,flag_checkSha256Sum);

    totalNumberOfSegmentsToPlot = 0;
    fprintf('%s\n','Preprocessing: ');
    fprintf('%s\n','  Counting the number of segments to plot');
    fprintf(fidLogFile,'%s\n','Preprocessing: ');
    fprintf(fidLogFile,'%s\n','  Counting the number of segments to plot');
    
    for indexSetOfTrials=1:1:length(setOfTrialsVerified)
    
        i = setOfTrialsVerified(indexSetOfTrials);
    
        %%
        % Read in the meta data
        %%    
        %fprintf('\t%s\n',experimentJson.trials{i});
        trialStr = fileread(fullfile(dataFolder,experimentJson.trials{i}));
        trialJson = jsondecode(trialStr);
    
    
        %%
        % Count the number of segments to plot and check if wave files exist
        %%
        setOfSegments=[];
        numSegmentsToPlot = 0;
        for j=1:1:length(trialJson.segments)
            if(strcmp(trialJson.segments(j).type,keyword.label))
                %assert(idxSeg==0,['Error: multiple segments have the name ',...
                %                    keyword.label]);
                if(isempty(setOfSegments)==1)
                    setOfSegments = j;
                else
                    setOfSegments = [setOfSegments;j];
                end            
            end
            if(strcmp(trialJson.segments(j).type,'Larb-Stochastic'))
                waveFile = '';
                for k=1:1:length(trialJson.segments(j).meta_data.file)
                    if(k==1)
                        waveFile = trialJson.segments(j).meta_data.file{k};
                    else
                        waveFile = [waveFile,filesep,...
                                    trialJson.segments(j).meta_data.file{k}];
                    end
                end
                waveFilePath = fullfile(dataFolder, waveFile);
                if( ~exist(waveFilePath,'file'))
                    fprintf('%s\n','  Error: wave file not found: ');
                    fprintf('%s\n',['    ', waveFilePath]);
                    fprintf(fidLogFile,'%s\n','  Error: wave file not found: ');
                    fprintf(fidLogFile,'%s\n',['    ', waveFilePath]);
                end
    
            end
        end    
    
        if(isempty(setOfSegments))
            fprintf(fidLogFile,'%s\n', ...
                    ['Error: could not find segment with ',keyword.label]);
        end
    
        assert(~isempty(setOfSegments),...
                ['Error: could not find segment with ',keyword.label]);
        if(length(setOfSegments) > totalNumberOfSegmentsToPlot)
            totalNumberOfSegmentsToPlot = length(setOfSegments);
        end    
    end

    fprintf('\t%i segments found\n',totalNumberOfSegmentsToPlot);
    fprintf(fidLogFile,'\t%i segments found\n',totalNumberOfSegmentsToPlot);

    
end

if(settings.processData==1)
    
    setOfTrials = [];
    if(~isempty(setOfTrialsVerified))
        if(~isempty(fileKeyWord))            
            for i=1:1:length(setOfTrialsVerified)
                if(contains(experimentJson.trials{i},fileKeyWord))
                    setOfTrials = [setOfTrials; i];
                end
            end
        else
            setOfTrials = setOfTrialsVerified;
        end
    else
        if(~isempty(fileKeyWord))
            for i=1:1:length(setOfTrialsVerified)
                if(contains(experimentJson.trials{i},fileKeyWord))
                    setOfTrials = [setOfTrials; i];
                end
            end            
        else
            setOfTrials = setOfTrialsDefault;
        end        
    end
    


    %
    % Plot the segment data
    %    
    numberOfHorizontalPlotColumnsGeneric    = length(setOfTrials);
    numberOfVerticalPlotRowsGeneric         = 4*totalNumberOfSegmentsToPlot;
    % 1. Time domain
    % 2. gain
    % 3. phase
    % 4. coherence
    
    plotWidth                               = ones(1,numberOfHorizontalPlotColumnsGeneric).*6;
    plotHeight                              = ones(numberOfVerticalPlotRowsGeneric,1).*6;
    plotHorizMarginCm                       = 3;
    plotVertMarginCm                        = 2;
    baseFontSize                            = 12;
    
    [subPlotPanelSegment, pageWidthSegment,pageHeightSegment]= ...
      plotConfigGeneric(  numberOfHorizontalPlotColumnsGeneric,...
                          numberOfVerticalPlotRowsGeneric,...
                          plotWidth,...
                          plotHeight,...
                          plotHorizMarginCm,...
                          plotVertMarginCm,...
                          baseFontSize); 
    
    figSegments = figure;
    
    %
    % Intra-segments
    %
    numberOfHorizontalPlotColumnsGeneric    = 1;
    numberOfVerticalPlotRowsGeneric         = 2;
    
    plotWidth                               = ones(1,numberOfHorizontalPlotColumnsGeneric).*20;
    plotHeight                              = ones(numberOfVerticalPlotRowsGeneric,1).*10;
    plotHorizMarginCm                       = 3;
    plotVertMarginCm                        = 2;
    baseFontSize                            = 12;
    
    [subPlotPanelIntraSegment, pageWidthIntraSegment,pageHeightIntraSegment]= ...
      plotConfigGeneric(  numberOfHorizontalPlotColumnsGeneric,...
                          numberOfVerticalPlotRowsGeneric,...
                          plotWidth,...
                          plotHeight,...
                          plotHorizMarginCm,...
                          plotVertMarginCm,...
                          baseFontSize); 
    
    figIntraSegments = figure;

    %
    % Plot the time series domain data
    %
    numberOfHorizontalPlotColumnsGeneric    = 1;
    numberOfVerticalPlotRowsGeneric         = length(setOfTrials);

    
    plotWidth          = ones(1,numberOfHorizontalPlotColumnsGeneric).*25;
    plotHeight         = ones(numberOfVerticalPlotRowsGeneric,1).*10;
    plotHorizMarginCm  = 3;
    plotVertMarginCm   = 2;
    baseFontSize       = 12;
    
    [subPlotPanelTimeSeries, pageWidthTimeSeries,pageHeightTimeSeries]= ...
      plotConfigGeneric(  numberOfHorizontalPlotColumnsGeneric,...
                          numberOfVerticalPlotRowsGeneric,...
                          plotWidth,...
                          plotHeight,...
                          plotHorizMarginCm,...
                          plotVertMarginCm,...
                          baseFontSize); 

    figTimeSeries = figure;

    fprintf('%s\n','Processing: gain, phase, coherence-sq + model fit');
    fprintf(fidLogFile,'%s\n','Processing: gain, phase, coherence-sq + model fit');
    
    for indexSetOfTrials = 1:1:length(setOfTrials)
    
        idxTrial = setOfTrials(indexSetOfTrials);
        %%
        % Read in the meta data
        %%   
        fprintf('\t%s\n',experimentJson.trials{idxTrial});
        fprintf(fidLogFile,'\t%s\n',experimentJson.trials{idxTrial});
        
        trialStr = fileread(fullfile(dataFolder,experimentJson.trials{idxTrial}));
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
        % Identify the active interval, if it exists
        %%
        activeIntervals = [];
        for j=1:1:length(auroraData.Test_Protocol.Time.Value)
            isBathFunction = ...
                strcmp(auroraData.Test_Protocol.Control_Function.Value{j},'Bath');
            isActivation = ...
                contains(auroraData.Test_Protocol.Options.Value{j},...
                sprintf('%i ',settings.activationBathNumber));
            isDeactivation = ...
                contains(auroraData.Test_Protocol.Options.Value{j},...
                sprintf('%i ',settings.deactivationBathNumber));
            isPreactivation = ...
                contains(auroraData.Test_Protocol.Options.Value{j},...
                sprintf('%i ',settings.preactivationBathNumber));
            if(isBathFunction==1 && isActivation==1)
                if(isempty(activeIntervals))
                    activeIntervals = ...
                        [auroraData.Test_Protocol.Time.Value(j,1),nan];
                else
                    activeIntervals = ...
                        [activeIntervals;...
                         auroraData.Test_Protocol.Time.Value(j,1),nan];
                end
            end

            if(isBathFunction && isDeactivation==1)
                activeIntervals(end,2) = auroraData.Test_Protocol.Time.Value(j,1);
            end
        end

        %%
        % Get the perturbation segment intervals
        %%
        setOfSegments=[];
        numSegmentsToPlot = 0;
        for j=1:1:length(trialJson.segments)
            if(strcmp(trialJson.segments(j).type,keyword.label))
                %assert(idxSeg==0,['Error: multiple segments have the name ',...
                %                    keyword.label]);
                if(isempty(setOfSegments)==1)
                    setOfSegments = j;
                else
                    setOfSegments = [setOfSegments;j];
                end
            end
        end    
    
        if(isempty(setOfSegments))
            fprintf(fidLogFile,'%s\n', ...
                    ['Error: could not find segment with ',keyword.label]);
        end    
        assert(~isempty(setOfSegments),...
                ['Error: could not find segment with ',keyword.label]);        
        %%
        % 
        % 1. Extract the active times that are
        %    between segments. For the first segment, ignore all data that
        %    occurs before the the max (this happens early)
        % 2. Fit lines to these segments. 
        % 3. Save 
        %  a. Data: initial value, final value
        %  b. Line: initial value, final value, slope
        % 4. Evaluate defect between segments: difference between
        %    the new starting value and the expected value from the slope
        %%
        

        intraSegmentData(length(setOfSegments)) = ...
            struct('duration',[],'model',[],'xyMax',[],...
            'filtered',[],'forceReference',0);
        for j=1:1:length(setOfSegments)
            intraSegmentData(j).filtered.time = [];
            intraSegmentData(j).filtered.length = [];
            intraSegmentData(j).filtered.force = [];
        end
        
        if(~isempty(activeIntervals))

            assert(size(activeIntervals,1)<=1 && size(activeIntervals,1)<=2,...
                   'Error: the following code assumes one active interval');
            fref=nan;
            for j=1:1:(length(setOfSegments))
                
                t0 = 0;
                t1 = 0;
                if(j==1)

                    assert(strcmp(auroraData.Data.Time.Unit,'ms'),...
                           ['Error: Assumed time unit is ms, not ',...
                            auroraData.Data.Time.Unit]);
                    idSeg=setOfSegments(j,1);
                    t0 = activeIntervals(1,1);                    
                    t1 = trialJson.segments(idSeg).duration(1,1);
                
%                     We want to find the first measured force that does
%                     not contain any vibration. This will be our
%                     refernence force for this trial
%                     
                    intraSegmentIndex = find( auroraData.Data.Time.Values >= t0 ...
                                           & auroraData.Data.Time.Values <= t1);


                    flagPlotReference=0;
                    [forceReference, indexReference] ...
                        = identifyActiveFiberReferenceForce600A(...
                                auroraData.Data.Fin.Values(intraSegmentIndex,1), ...
                                settings.forceNoiseThresholdmN,...
                                settings.isometricNoiseFilterCutoffFrequencyHz,...
                                auroraData.Setup_Parameters.A_D_Sampling_Rate.Value,...
                                flagPlotReference);

                    f0 = forceReference;
                    t0 = auroraData.Data.Time.Values(intraSegmentIndex(indexReference));

                else
                    idSeg=setOfSegments(j-1,1);
                    t0 = trialJson.segments(idSeg).duration(2,1);
                    idSeg=setOfSegments(j,1);                
                    t1 = trialJson.segments(idSeg).duration(1,1);
                end
    
                intraSegmentData(j).duration=[t0,t1];
                intraSegmentIndex = find( auroraData.Data.Time.Values >= t0 ...
                                        & auroraData.Data.Time.Values <= t1);

    
                timeV = auroraData.Data.Time.Values(intraSegmentIndex,1) ...
                       -auroraData.Data.Time.Values(intraSegmentIndex(1,1),1);

                Amdl = [timeV ones(size(timeV))];
                xmdl = (Amdl'*Amdl)\(Amdl'*auroraData.Data.Fin.Values(intraSegmentIndex,1));
                ymdl = Amdl*xmdl;
                r2mdl = sqrt(mean((ymdl-auroraData.Data.Fin.Values(intraSegmentIndex,1)).^2));
    
                lin.mean = mean(auroraData.Data.Lin.Values(intraSegmentIndex,1));           
                lin.std = std(auroraData.Data.Lin.Values(intraSegmentIndex,1));

                intraSegmentData(j).model.x = ...
                    [auroraData.Data.Time.Values(intraSegmentIndex(1,1),1);...
                     auroraData.Data.Time.Values(intraSegmentIndex(end,1),1)
                     auroraData.Data.Time.Values(end,1)];
    
                timeEnd= auroraData.Data.Time.Values(end,1) ...
                        -auroraData.Data.Time.Values(intraSegmentIndex(1,1),1);

                ymdlEnd = [timeEnd,1]*xmdl;
                intraSegmentData(j).model.y = [ymdl(1,1);ymdl(end,1);ymdlEnd];
                intraSegmentData(j).model.dydx = xmdl(1,1);
                intraSegmentData(j).model.r2 = r2mdl;

                [ymax,idxMax] = max(auroraData.Data.Fin.Values(intraSegmentIndex,1));
                xmax = auroraData.Data.Time.Values(intraSegmentIndex(idxMax,1),1);
                intraSegmentData(j).xyMax = [xmax,ymax];
                
                intraSegmentData(j).filtered.time   = zeros(size(intraSegmentIndex,1),1);
                intraSegmentData(j).filtered.length = zeros(size(intraSegmentIndex,1),1);
                intraSegmentData(j).filtered.force  = zeros(size(intraSegmentIndex,1),1);

                intraSegmentData(j).filtered.time = ...
                    auroraData.Data.Time.Values(intraSegmentIndex,1);

                nyquistFrequency = ...
                    auroraData.Setup_Parameters.A_D_Sampling_Rate.Value*0.5;
                cutoffFrequency = settings.isometricNoiseFilterCutoffFrequencyHz;

                [b,a]=butter(2,cutoffFrequency/nyquistFrequency);
                intraSegmentData(j).filtered.force =...
                    filtfilt(b,a, auroraData.Data.Fin.Values(intraSegmentIndex,1));
                intraSegmentData(j).filtered.length =...
                    filtfilt(b,a, auroraData.Data.Lin.Values(intraSegmentIndex,1));
                intraSegmentData(j).forceReference=forceReference;
                here=1;
                
            end
        end

        %%
        % Plot the time series data
        %%
        figure(figTimeSeries);

        subplot('Position',...
            reshape(subPlotPanelTimeSeries(indexSetOfTrials,1,:),1,4));

        yyaxis left;
        plot(auroraData.Data.Time.Values,auroraData.Data.Lin.Values);
        hold on;
        xlabel(['Time (',auroraData.Data.Time.Unit,')']);
        ylabel(['Length (',auroraData.Data.Lin.Unit,')']);

        yyaxis right;
        plot(auroraData.Data.Time.Values,auroraData.Data.Fin.Values);
        hold on;


        if(~isempty(activeIntervals))
            for j=1:1:length(intraSegmentData)
                n = 0;
                if(length(intraSegmentData)>1)
                    n = (j-1)/(length(intraSegmentData)-1);
                end
                
                mdlColor = [0,0,0].*(1-n)+[1,0,1].*n;

                if(j==length(intraSegmentData))
                    mdlColor = [0,1,0];
                end

%                 plot(intraSegmentData(j).model.x,...
%                      intraSegmentData(j).model.y,...
%                      '-.','Color',mdlColor);
%                 hold on;
%                 plot(intraSegmentData(j).xyMax(1,1),...
%                      intraSegmentData(j).xyMax(1,2),...
%                      '.','Color',mdlColor);
%                 hold on;
                plot(intraSegmentData(j).filtered.time,...
                     intraSegmentData(j).filtered.force,...
                     '-','Color',mdlColor);
                hold on;
                text(intraSegmentData(j).filtered.time(1),...
                     intraSegmentData(j).filtered.force(1),...
                     sprintf('%1.3e = yMax', ...
                       intraSegmentData(j).xyMax(1,2)),...
                       'HorizontalAlignment','right',...
                       'VerticalAlignment','top',...
                       'FontSize',8,...
                       'Rotation',45);
                hold on;
                text(intraSegmentData(j).model.x(1,1),...
                     intraSegmentData(j).model.y(1,1),...
                     sprintf('%1.3e = y\n%1.3e = dydx', ...
                       intraSegmentData(j).model.y(1,1),...
                       intraSegmentData(j).model.dydx(1,1)),...
                       'HorizontalAlignment','right',...
                       'VerticalAlignment','bottom',...
                       'FontSize',8,...
                       'Rotation',45);
                hold on;
            end
        end

        ylabel(['Force (',auroraData.Data.Fin.Unit,')']);
        titleStr = strrep(experimentJson.trials{idxTrial},'_','\_');                
        title(titleStr);
        axis tight;
        box off;

        %%
        % Plot the intra segments, if this is a degredation trial
        %%
        if(strcmp(trialType,'degradation'))
            figure(figIntraSegments);
            subplot('Position',...
                reshape(subPlotPanelIntraSegment(1,1,:),1,4));
            colorA = [0,0,0];
            colorB = [0,0,1];

            n=0;
            if(length(setOfTrials)>1)
                n = (indexSetOfTrials-1)/(length(setOfTrials)-1);
            end
            lineColor = colorA.*(n-1) + colorB.*n;    
       
            for j=1:1:length(intraSegmentData)                
                plot(intraSegmentData(j).filtered.time,...
                     intraSegmentData(j).filtered.force,...
                     '-','Color',lineColor);
                hold on;  
                if(j==1)
                    plot(intraSegmentData(j).filtered.time(end),...
                         intraSegmentData(j).filtered.force(end),...
                         '.','Color',lineColor);
                    hold on;                      
                end
            end
            text(intraSegmentData(end).filtered.time(end),...
                 intraSegmentData(end).filtered.force(end),...
                 sprintf('%i',indexSetOfTrials),...
                 'HorizontalAlignment','left',...
                 'FontSize',6);
            hold on            
            box off;
            xlabel(['Time (',auroraData.Data.Time.Unit,')']);
            ylabel(['Force (',auroraData.Data.Fin.Unit,')']); 
            %titleStr = strrep(folderName,'_','\_'); 
            title('Isometric intra-segment force');

            subplot('Position',...
                reshape(subPlotPanelIntraSegment(2,1,:),1,4));
            plot(indexSetOfTrials,intraSegmentData(1).filtered.force(end),...
                 'o','Color',lineColor,'MarkerFaceColor',lineColor);
            hold on;
            forceReference = intraSegmentData(1).forceReference; 
            plot(indexSetOfTrials,...
                (intraSegmentData(1).filtered.force(end)-forceReference),...
                 'x','Color',[1,0,0],'MarkerFaceColor',[1,0,0]);
            hold on;
            box off;
            xlabel(['Trial Number']);
            ylabel(['Force (',auroraData.Data.Fin.Unit,')']); 
            title('Force prior to first perturbation');
            
        end


    
        %%
        % Process each of the segments
        %%
    
    
        for indexIntoSetOfSegments = 1:1:length(setOfSegments)
        
            idxSeg = setOfSegments(indexIntoSetOfSegments,1);
    
            %%
            %Extract the indicies to plot
            %%
            timeStart = trialJson.segments(idxSeg).duration(1);
            timeEnd   = trialJson.segments(idxSeg).duration(2);
            dataIndex = find( auroraData.Data.Time.Values >= timeStart ...
                            & auroraData.Data.Time.Values <= timeEnd); 
            
            %%
            %Find the wave number
            %%
            %idxWave = trialJson.waveform.id;
            segmentType=trialJson.segments(idxSeg).type;
    
            if(strcmp('Larb-Stochastic',segmentType)==0)
                fprintf(fidLogFile,'%s\n',...
                    ['Error: expected Larb-Stochastic at segment ',num2str(idxSeg)]);
            end
            assert(strcmp('Larb-Stochastic',segmentType),...
                ['Error: expected Larb-Stochastic at segment ',num2str(idxSeg)]);
            
            bandwidth = trialJson.segments(idxSeg).meta_data.bandwidth';
            amplitude = trialJson.segments(idxSeg).meta_data.amplitude;
            
            if(isempty(bandwidth))
                fprintf(fidLogFile,'%s\n',...
                    ['Error: could not find larb-segment property bandwidth']);
            end
            assert(isempty(bandwidth)==0,...
                'Error: could not find larb-segment property bandwidth');
    
            if(isempty(amplitude))
                fprintf(fidLogFile,'%s\n',...
                    ['Error: could not find larb-segment property amplitude']);
            end
            assert(isempty(amplitude)==0,...
                'Error: could not find larb-segment property amplitude');
       
            %%
            % Evaluate frequency response   
            %%
            x = auroraData.Data.Lin.Values(dataIndex,1);
            x = x - mean(x);
        
            y = auroraData.Data.Fin.Values(dataIndex,1);
            y = y-mean(y);
            
            xyDataIsValid =0;



    
            if(length(y)>10 && length(x)>10)
                xyDataIsValid=1;
    
                sampleFrequency = auroraData.Setup_Parameters.A_D_Sampling_Rate.Value;
                assert(strcmp(auroraData.Setup_Parameters.A_D_Sampling_Rate.Unit,'Hz'),...
                       'Error: A_D_Sampling_Rate should be in Hz');
            
                samples     = length(x);
                timeVec     = [0:(1/(samples-1)):1]' .* (samples/sampleFrequency);
            
                segData.x = x;
                segData.y = y;
                segData.time=timeVec;
                segData.bandwidth = bandwidth;
                segData.sampleFrequency = sampleFrequency;

                %[freqHz, gain, phase,coherenceSq] = ...
                segData.H0 = evaluateGainPhaseCoherenceSq(...
                                    timeVec,...
                                    x,...
                                    y,...
                                    bandwidth,...
                                    sampleFrequency,...
                                    settings.coherenceSquaredThreshold);

            end
        


            %%
            % Fit a first order low pass model to the response
            %%
        
            if(xyDataIsValid==1)

                delayModel.phaseDelayElasticRod=0;
                delayModel.daqDelay        = settings.daqDelay; %in seconds
                delayModel.daqFilterFrequencyHz = settings.daqFilterFrequencyHz;
                delayModel.daqDelayModel   = settings.daqDelayModel;
                 

                %Test the models with the default parameters

                for idxMdl = 1:1:length(modelSeries)
                    modelSeries(idxMdl).model.settings.applyParameterMap=0;
                    modelResponse = ...
                        calcMaxwellKelvinVoigtNetworkImpedance(...
                            segData.H0.frequency(segData.H0.idxBWC2),...
                            modelSeries(idxMdl).model.parameters,...
                            modelSeries(idxMdl).model.settings);
                end

                %%
                % Compensate for the propagation delay
                %
                %
                % Compensating for the delay changes the gain
                % and thus the estimated stiffness of the spring. 
                % Here we iterate over candidate delays until
                % the difference between subsequent delays is small
                %
                % This delay is also present in a muscle fiber, but it is
                % so small (2.27 e-5 s) that it does not really affect the 
                % phase in our bandwidth of 0-90 Hz: at 90 Hz one period is
                % 11 ms, and the biggest delay incurred by the
                % viscoelascity of the fiber is 0.0227 ms which amounts to
                % 0.11 degrees.
                %
                % Note, however, that there are publications in the
                % literature that examine the frequency response of fibers
                % upto 40 kHz. At such high frequencies these delays would 
                % be noticeable: at 40,000 Hz one period is 0.025 ms, and
                % the transmission delay would amount to 52 degrees
                %
                % De Winkel ME, Blangé T, Treijtel BW. The complex Young's 
                % modulus of skeletal muscle fibre segments in the high 
                % frequency range determined from tension transients. 
                % Journal of Muscle Research & Cell Motility. 1993 
                % Jun;14(3):302-10.
                %%

                
                H = segData.H0;
                delayError = inf;
                delayP = 0;
                delay = 0;
                iter=1;

                while delayError > settings.phaseDelayTolerance ...
                        && iter < settings.phaseDelayMaxIteration

                    idxFit =find(H.frequencyHz >= segData.bandwidth(1,1)...
                               & H.frequencyHz <= segData.bandwidth(1,2));

                    delay = calcPhaseDelayOfThinElasticRod(...
                                H.frequencyHz(idxFit),...
                                H.gain(idxFit),...
                                H.phase(idxFit),...
                                auroraData.Data.Lin.Values(dataIndex,1),...
                                experimentJson,...
                                mm2m);

                    timeDelayedVec  = segData.time + delay;
                    y01        = interp1(   segData.time, ...
                                            segData.y,...
                                            timeDelayedVec,...
                                            'linear','extrap');
                    
                    H = evaluateGainPhaseCoherenceSq(  ...
                            timeDelayedVec,...
                            segData.x,...
                            y01,...
                            segData.bandwidth,...
                            segData.sampleFrequency,...
                            settings.coherenceSquaredThreshold);

                    if(iter > 1)
                        delayError = abs(delay-delayP);
                    end
                    delayP = delay;
                    iter=iter+1;
                end
                if(iter > settings.phaseDelayMaxIteration)
                    fprintf(['  Warning: delay tolerance not met\n',...
                             '  %1.2e > %1.2e\t error\n',...
                             '  %i \t iterations'],...
                             delayError, ...
                             settings.phaseDelayTolerance,...
                             settings.phaseDelayMaxIteration);
                end          

                if(strcmp(experimentJson.experiment.material,'stainless steel'))      
                    segData.H1=H;
                    delayModel.phaseDelayCompensated=1;
                else
                    %%
                    % For now, I'm not compensating for any of the delay
                    % that is present in the fiber for two reasons:
                    %
                    % 1. Between 0-90 Hz the delay is negligible. It is 
                    %    negligible for the fiber but not the spring because
                    %    the fiber is ~1/100th the mass of the spring.
                    %
                    % 2. The delay varies with frequency. To correctly 
                    %    capture this delay you need to have an accurate
                    %    model of the frequency response of the fiber,
                    %    which I currently do not have: a Kelvin-Voigt
                    %    model captures the gain, but not the phase correctly
                    %
                    %  A muscle fiber is viscoelastic, and the damping causes
                    %  the higher frequency waves to travel faster. To
                    %  correctly compensate for this dispersion, you need an
                    %  accurate model of the frequency response of the fiber, 
                    %  which I currently do not have.
                    %%
                    segData.H1=segData.H0;
                    delayModel.phaseDelayCompensated=0;
                end

                delayModel.phaseDelayElasticRod = delay;
                
                %%
                % Compensate for delay introduced by the low-pass-filter
                %                               
                % Identify the filter frequency:
                %
                % Fit the delay to the phase response by fitting an 
                % inverse-low-pass filter until the phase response of
                % the spring is flat.
                %%
                if(modelSettings.useManuallySetDaqDelay==0 ...
                        && strcmp(modelSettings.daqDelayModel,'frequency-domain'))
                    
                    expResponse = evaluateGainPhaseCoherenceSq(  ...
                                        segData.H1.time,...
                                        segData.H1.x,...
                                        segData.H1.y,...
                                        segData.bandwidth,...
                                        segData.sampleFrequency,...
                                        settings.coherenceSquaredThreshold);  
                    
                    fittingResults = ...
                        calcLowPassFilterFrequencyToZeroPhaseResponseSlope(...
                            delayModel.daqFilterFrequencyHz,...
                            expResponse,...
                            delayModel.daqFilterFrequencyHz*0.5,...
                            expResponse.bandwidthHzC2,...
                            100,...
                            0);  

                    delayModel.daqFilterFrequencyHz = ...
                            fittingResults.filterFrequencyHz;

                end
                if(modelSettings.useManuallySetDaqDelay==1 ...
                        && strcmp(modelSettings.daqDelayModel,'frequency-domain'))
                    delayModel.daqFilterFrequencyHz = settings.daqFilterFrequencyHz;
                end

                %
                % Compensate for the filtering effect of the DAQ
                %
                n = length(segData.H1.x);
                omega = delayModel.daqFilterFrequencyHz*2*pi;
                frequencyHz = [0:(1/(n)): (1-(1/n)) ]'...
                                .* (sampleFrequency);
                frequency=frequencyHz.*(2*pi);
                lpfInv = ((omega + complex(0,1).*frequency)./omega);
                yUpd = ifft(lpfInv.*fft(segData.H1.y),...
                        'symmetric');
                
                segData.H2 = evaluateGainPhaseCoherenceSq(  ...
                                segData.H1.time,...
                                segData.H1.x,...
                                yUpd,...
                                segData.bandwidth,...
                                segData.sampleFrequency,...
                                settings.coherenceSquaredThreshold); 
                delayModel.daqDelayCompensated=1;
                
                %%
                % Fit the impedance model(s)
                %%
            
                lsqnonlinOptions =...
                    optimoptions('lsqnonlin','MaxFunctionEvaluations',2000,...
                                 'MaxIterations',2000,...
                                 'Display','none');

                optSettings.objScaling = [1,1]; %gain and phase error

                if(~isempty(segData.H2.idxBWC2))
                    for idxMdl = 1:1:length(modelSeries)
                        x0 = zeros(length(modelSeries(idxMdl).model.settings.parameterMap),1);
                        for i=1:1:length(x0)
                            
                            row     = modelSeries(idxMdl).model.settings.parameterMap(i,1);
                            col     = modelSeries(idxMdl).model.settings.parameterMap(i,2);
    
                            assert(col > 1, ['Error: the first column in ',...
                                            'model.settings.parameterMap is reserved',...
                                            ' for the branch number']);
                            x0(i,1) = modelSeries(idxMdl).model.parameters(row,col);
                        end
    
                        modelSeries(idxMdl).model.settings.applyParameterMap=1;
    
                        errFcn = @(argX)calcErrorOfImpedanceModel600A(...
                                            argX, ...
                                            modelSeries(idxMdl).model.settings, ...                                    
                                            segData.H2,...
                                            optSettings);
    
                        errVec = errFcn(x0);
                        n=length(errVec);
                        errGain = errVec(1:1:(n/2));
                        errPhase= errVec(((n/2)+1):1:n);
                        optSettings.objScaling = ...
                            [1/sqrt(mean(errGain.^2)) 1/sqrt(mean(errPhase.^2))];
    
                        lb = zeros(size(x0,1),1);
                        [xFit, resnorm, residual,exitflag,output] = ...
                            lsqnonlin(errFcn,x0,lb,[],lsqnonlinOptions);
                    
                        %
                        % Evaluate the fitted model response
                        %
    
                        fittedModelSeries(idxMdl).model.parameters = ...
                            getMaxwellKelvinVoigtNetworkParameters(...
                                xFit,...
                                modelSeries(idxMdl).model.settings);
                    
                        fittedModelSeries(idxMdl).model.response ...
                            = calcMaxwellKelvinVoigtNetworkImpedance(...
                                  segData.H2.frequency(segData.H2.idxBWC2),...
                                  xFit,...
                                  modelSeries(idxMdl).model.settings);
    
                        idxBWC2 = segData.H2.idxBWC2;
                            
                        fittedModelSeries(idxMdl).model.rmse.gain =...
                            sqrt( mean( ...
                            (fittedModelSeries(idxMdl).model.response.gain ...
                             -segData.H2.gain(idxBWC2)).^2 ));
                        fittedModelSeries(idxMdl).model.rmse.phase = ...
                            sqrt( mean( ...
                            (fittedModelSeries(idxMdl).model.response.phase ...
                            -segData.H2.phase(idxBWC2)).^2 ));
                        fittedModelSeries(idxMdl).model.rmse.storage = ...
                            sqrt( mean(... 
                            (fittedModelSeries(idxMdl).model.response.storage ...
                            -segData.H2.storage(idxBWC2)).^2 ));
                        fittedModelSeries(idxMdl).model.rmse.loss = ...
                            sqrt( mean( ...
                            (fittedModelSeries(idxMdl).model.response.loss ...
                            -segData.H2.loss(idxBWC2)).^2 ));
                    end
                end
            
                %disp('*** Future: update the viscoelastic rod model ***');
                %
                % Check the transmission delays
                %
                %   2026/2/19: Commenting this out for now. Muscle fibers
                %              behave more like a Maxwell element in series
                %              with a Kelvin-Voigt element. The frequency 
                %              dependent delay times below are estimated only
                %              for a Kelvin-Voigt rod which is the wrong model.
                %
                % kelvinVoigtRodModel = [];
                % if(strcmp(experimentJson.experiment.material,'muscle'))
                %         
                %     if(~isempty(experimentJson.experiment.width_mm) ...
                %             && ~isempty(experimentJson.experiment.height_mm) ...
                %             && ~isempty(experimentJson.experiment.rho_kg_m3))
                %     
                %         k_Nm        = modelParams.k;
                %         beta_Nms    = modelParams.beta;
                %         length_MM   = mean(auroraData.Data.Lin.Values(dataIndex,1));
                %         length_M    = length_MM*mm2m;
                %         area_MM2    = (pi/4)*experimentJson.experiment.width_mm ...
                %                             *experimentJson.experiment.height_mm;
                %         area_M2     = area_MM2*mm2m*mm2m;
                %         rho_kgm3    = experimentJson.experiment.rho_kg_m3;
                %         flag_plot   = 0;
                %         kelvinVoigtRodModel = ...
                %             evaluateDelayModelThinKelvinVoigtRod(...
                %                         k_Nm,beta_Nms,length_M,area_M2,...
                %                         rho_kgm3,segData.H2.frequency,...
                %                         flag_plot);
                %         
                %     end
                % end
                %%
                % Evaluate errors
                %%

        
            end
            %%
            % Record the analysis to a segment json file
            %%
            lengthSummary = ...
                getSummaryStatistics(auroraData.Data.Lin.Values(dataIndex,1));
            forceSummary = ...
                getSummaryStatistics(auroraData.Data.Fin.Values(dataIndex,1));
            if(experimentJson.experiment.temperatureControl)
                temperatureSummary = ...
                getSummaryStatistics(auroraData.Data.Aux1_C.Values(dataIndex,1));
            else
                temp = experimentJson.experiment.temperature_C;           
                temperatureSummary.percentiles.x=[];
                temperatureSummary.percentiles.y=[];
                temperatureSummary.mean = temp;
                temperatureSummary.median=temp;
                temperatureSummary.std = 0;
                temperatureSummary.min = temp;
                temperatureSummary.max = temp;
            end
    
            segmentJson.interval= [timeStart,timeEnd];
            segmentJson.index   = idxSeg;
            segmentJson.type    = trialJson.segments(idxSeg).type; 

            segmentJson.time    = auroraData.Data.Time.Values(dataIndex,1);
            segmentJson.length  = auroraData.Data.Lin.Values(dataIndex,1);
            segmentJson.force   = auroraData.Data.Fin.Values(dataIndex,1);            
            
            segmentJson.forceReference = ...
                intraSegmentData(1).forceReference;

            if(~isempty(activeIntervals))
                segmentJson.pre.filterFrequencyHz=settings.isometricNoiseFilterCutoffFrequencyHz;
                segmentJson.pre.fitlerType = 'Dual-pass 2nd order Butterworth low-pass filter';
                segmentJson.pre.duration= intraSegmentData(idxSeg).duration;
                segmentJson.pre.time    = intraSegmentData(idxSeg).filtered.time;
                segmentJson.pre.length  = intraSegmentData(idxSeg).filtered.length;
                segmentJson.pre.force   = intraSegmentData(idxSeg).filtered.force;                
            end

            segmentJson.summary.length      = lengthSummary;
            segmentJson.summary.force       = forceSummary;
            segmentJson.summary.temperature = temperatureSummary;
            segmentJson.unit.length         = auroraData.Data.Lin.Unit;
            segmentJson.unit.force          = auroraData.Data.Fin.Unit;
            segmentJson.unit.temperature    = 'C';
            segmentJson.channel.length      = 'Lin';
            segmentJson.channel.force       = 'Fin';
            segmentJson.channel.temperature = 'Aux 1';
    
            scaleTime = 1;
            if(strcmp(auroraData.Data.Time.Unit,'ms'))
                scaleTime=1000;
            end
      
    
            hStages = {'H0','H1','H2'};

            for idxH = 1:1:length(hStages)
                hStr = hStages{idxH};

                idxBW = segData.(hStr).idxBW;
                
                responseFields = fields(segData.(hStr));
                idxBW = segData.(hStr).idxBW;
                fieldsToSkip ={'H'};
                fieldsToBWLimit = ...
                    {'frequencyHz','frequency','gain','phase',...
                     'storage','loss','coherenceSq'};
                for idxF = 1:1:length(responseFields)
                    fStr = responseFields{idxF};
                    flag_skip = 0;
                    for idxS = 1:1:length(fieldsToSkip)
                        if(strcmp(responseFields{idxF},fieldsToSkip{idxS}))
                            flag_skip=1;
                        end
                    end
                    
                    flag_bwlimit=0;
                    for idxL = 1:1:length(fieldsToBWLimit)
                        if(strcmp(responseFields{idxF},fieldsToBWLimit{idxL}))
                            flag_bwlimit=1;
                        end
                    end

                    if(flag_skip==0)
                        if(flag_bwlimit==0)
                            segmentJson.(hStr).(fStr)=segData.(hStr).(fStr);
                        else
                            segmentJson.(hStr).(fStr)=segData.(hStr).(fStr)(idxBW);
                        end
                    end

                end
                %
                % There is no way to encode complex numbers, so we must
                % cut H out.
                %
%                 segmentJson.(hStr) = segData.(hStr);                 
%                 segmentJson.(hStr).H = [];

                
                segmentJson.(hStr).summary.gain = ...
                    getSummaryStatistics(segData.(hStr).gain(idxBW));            
                segmentJson.(hStr).summary.phase = ...
                    getSummaryStatistics(segData.(hStr).phase(idxBW));
                segmentJson.(hStr).summary.storage = ...
                    getSummaryStatistics(segData.(hStr).storage(idxBW));            
                segmentJson.(hStr).summary.loss = ...
                    getSummaryStatistics(segData.(hStr).loss(idxBW));
                segmentJson.(hStr).summary.coherenceSq = ...
                    getSummaryStatistics(segData.(hStr).coherenceSq(idxBW));

                segmentJson.(hStr).units.gain = ...
                    [auroraData.Data.Fin.Unit,'/',auroraData.Data.Lin.Unit];
                segmentJson.(hStr).units.phase = 'radians';
                segmentJson.(hStr).units.storage = ...
                    [auroraData.Data.Fin.Unit,'/',auroraData.Data.Lin.Unit];
                segmentJson.(hStr).units.loss = ...
                    [auroraData.Data.Fin.Unit,'s/',auroraData.Data.Lin.Unit];
                segmentJson.(hStr).units.coherenceSq = '';

            end

            % if(strcmp(experimentJson.experiment.material,'muscle'))
            %     if(~isempty(kelvinVoigtRodModel))
            %         segmentJson.KelvinVoigtRodModel.frequencyHz = ...
            %             kelvinVoigtRodModel.frequency_Hz;
            %         segmentJson.KelvinVoigtRodModel.velocity_mps = ...
            %             kelvinVoigtRodModel.velocity_mps;
            %         segmentJson.KelvinVoigtRodModel.attenuation = ...
            %             kelvinVoigtRodModel.attenuation;
            %         segmentJson.KelvinVoigtRodModel.delay_s = ...
            %             kelvinVoigtRodModel.delay_s;
            %         segmentJson.KelvinVoigtRodModel.phase_degrees = ...
            %             kelvinVoigtRodModel.phase_degrees;
            %     else
            %         segmentJson.KelvinVoigtRodModel.frequencyHz     = [];
            %         segmentJson.KelvinVoigtRodModel.velocity_mps    = [];
            %         segmentJson.KelvinVoigtRodModel.attenuation     = [];
            %         segmentJson.KelvinVoigtRodModel.delay_s         = [];
            %         segmentJson.KelvinVoigtRodModel.phase_degrees   = [];
            %     end
            % end
            
    
            segmentJson.delayModel.settings      = modelSettings;
            segmentJson.delayModel.phaseDelayElasticRod  ...
                                            = delayModel.phaseDelayElasticRod;

            segmentJson.delayModel.phaseDelayCompensated = delayModel.phaseDelayCompensated;
            segmentJson.delayModel.daqDelayModel = delayModel.daqDelayModel;
            segmentJson.delayModel.daqDelay      = delayModel.daqDelay;
            segmentJson.delayModel.daqFilterFrequencyHz ...
                                            = delayModel.daqFilterFrequencyHz;
            segmentJson.delayModel.daqDelayCompensated = delayModel.daqDelayCompensated;

            if(~isempty(segData.H2.idxBWC2))
                for idxMdl = 1:1:length(fittedModelSeries)
    
                    abb = fittedModelSeries(idxMdl).model.abbreviation;
    
                    segmentJson.model.(abb).name = ...
                        fittedModelSeries(idxMdl).model.name;
    
                    segmentJson.model.(abb).abbreviation = ...
                        fittedModelSeries(idxMdl).model.abbreviation;
    
                    segmentJson.model.(abb).abbreviation = ...
                        fittedModelSeries(idxMdl).model.parameters;
    
                    segmentJson.model.(abb).settings = ...
                        fittedModelSeries(idxMdl).model.settings;
   
                    segmentJson.model.(abb).response = ...
                        fittedModelSeries(idxMdl).model.response;

                    %
                    % There is no standard way to encode complex numbers,
                    % and so, we must set H to be empty.
                    %
                    segmentJson.model.(abb).response.H = [];
    
                    segmentJson.model.(abb).rmse.gain     = ...
                        fittedModelSeries(idxMdl).model.rmse.gain;

                    segmentJson.model.(abb).rmse.phase    = ...
                        fittedModelSeries(idxMdl).model.rmse.phase; 

                    segmentJson.model.(abb).rmse.storage  = ...
                        fittedModelSeries(idxMdl).model.rmse.storage; 

                    segmentJson.model.(abb).rmse.loss     = ...
                        fittedModelSeries(idxMdl).model.rmse.loss; 
                                
                end
            end
                    

            %%
            % Plot time-length-force    
            %%
            figure(figSegments);
        
            idxRow = (idxSeg-1)*4 + 1;
            subplot('Position',reshape(...
                subPlotPanelSegment(idxRow,indexSetOfTrials,:),1,4));        
            yyaxis left;
     
            plot(auroraData.Data.Time.Values(dataIndex,1),...
                 auroraData.Data.Lin.Values(dataIndex,1),'-b');...
            hold on;

            box off;    
            xlabel(sprintf('Time (%s)',auroraData.Data.Time.Unit));
            ylabel(sprintf('Length (%s)',auroraData.Data.Lin.Unit));
        
            yyaxis right;
     
            plot(auroraData.Data.Time.Values(dataIndex,1),...
                 auroraData.Data.Fin.Values(dataIndex,1),'-r');...
            hold on;

            box off;    
            ylabel(sprintf('Force (%s)',auroraData.Data.Fin.Unit));
            
            titleStrA = trialJson.experiment.title;
            titleStrB = sprintf('%i Hz, %1.3f Lo',bandwidth(1,2),amplitude);
        
            titleId = sprintf('(%i,%i). ',idxRow,indexSetOfTrials);        
            title([titleId, titleStrA,':', titleStrB]);
        
            %%
            % Plot the gain response 
            %%    
            if(xyDataIsValid==1)
                idxRow = (idxSeg-1)*4 + 2;
                subplot('Position',reshape(...
                    subPlotPanelSegment(idxRow,indexSetOfTrials,:),1,4)); 

                plot(segData.H0.frequencyHz(segData.H0.idxBW),...
                     segData.H0.gain(segData.H0.idxBW),...
                    '-','Color',lineColors.red);
                hold on;
                plot(segData.H1.frequencyHz(segData.H1.idxBW),...
                     segData.H1.gain(segData.H1.idxBW),...
                    '-','Color',lineColors.purple);
                hold on;
                plot(segData.H2.frequencyHz(segData.H2.idxBW),...
                    segData.H2.gain(segData.H2.idxBW),...
                    '-','Color',lineColors.blue);
                hold on;
                    
                if(~isempty(segData.H2.idxBWC2))
                    for idxMdl=1:1:length(fittedModelSeries)    
                        plot(fittedModelSeries(idxMdl).model.response.frequencyHz,...
                             fittedModelSeries(idxMdl).model.response.gain,...
                             fittedModelSeries(idxMdl).model.lineType,...
                             'Color', fittedModelSeries(idxMdl).model.color);
                        hold on;    
                    end
                    for j=1:1:2
                        plot([segData.H2.bandwidthHzC2(j);...
                              segData.H2.bandwidthHzC2(j)],...
                             [min(segData.H2.gain(segData.H2.idxBW)),...
                              max(segData.H2.gain(segData.H2.idxBW))],...
                             '-c');
                        hold on;
                    end
                end

%                 switch settings.daqDelayModel
%                     case 'time-domain'
%                         text(max(segData.H2.frequencyHz(segData.H2.idxBW)),...
%                              min(segData.H2.gain(segData.H2.idxBW)),...
%                              sprintf(['%1.2e k\n',...
%                                       '%1.2e beta\n',...
%                                       '%1.2e delay'],...
%                                      modelParams.k,...
%                                      modelParams.beta,...
%                                      delayModel.daqDelay),...
%                                      'HorizontalAlignment','right',...
%                                      'VerticalAlignment','bottom',...
%                                      'FontSize',8);
%                     case 'frequency-domain'
%                         text(max(segData.H2.frequencyHz(segData.H2.idxBW)),...
%                              min(segData.H2.gain(segData.H2.idxBW)),...
%                              sprintf(['%1.2e k\n',...
%                                       '%1.2e beta\n',...
%                                       '%1.2e Hz %s'],...
%                                      modelParams.k,...
%                                      modelParams.beta,...
%                                      delayModel.daqFilterFrequencyHz,...
%                                      '$$\omega_o$$'),...
%                                      'HorizontalAlignment','right',...
%                                      'VerticalAlignment','bottom',...
%                                      'FontSize',8);
%                     otherwise
%                         assert(0,['Error: delayModel must be either',...
%                                   ' frequency-domain or time-domain']);
%                 end
%                hold on;
                box off;    
                xlabel('Frequency (Hz)');
                ylabel(sprintf('Gain (%s/%s)',...
                        auroraData.Data.Fin.Unit,auroraData.Data.Lin.Unit));
                titleId = sprintf('(%i,%i). ',idxRow,indexSetOfTrials);
                title(titleId);
            end
        
            %%
            % Plot the phase response 
            %%            
            if(xyDataIsValid==1)        
                idxRow = (idxSeg-1)*4 + 3;
                subplot('Position',reshape(...
                    subPlotPanelSegment(idxRow,indexSetOfTrials,:),1,4));

                plot(segData.H0.frequencyHz(segData.H0.idxBW),...
                     segData.H0.phase(segData.H0.idxBW).*(180/pi),...
                     '-','Color',lineColors.red);
                hold on;
                plot(segData.H1.frequencyHz(segData.H1.idxBW),...
                     segData.H1.phase(segData.H1.idxBW).*(180/pi),...
                     '-','Color',lineColors.purple);
                hold on;
                plot(segData.H2.frequencyHz(segData.H2.idxBW),...
                         segData.H2.phase(segData.H2.idxBW).*(180/pi),...
                         '-','Color',lineColors.blue);
                hold on;

                if(~isempty(segData.H2.idxBWC2))                    
                    for idxMdl=1:1:length(fittedModelSeries)
                        plot(fittedModelSeries(idxMdl).model.response.frequencyHz,...
                             fittedModelSeries(idxMdl).model.response.phase.*(180/pi),...
                             fittedModelSeries(idxMdl).model.lineType,...
                             'Color', fittedModelSeries(idxMdl).model.color);
                        hold on;    
                    end
                end
                
                box off;    
                xlabel('Frequency (Hz)');
                ylabel('Phase ($$^o$$)');
        
                titleId = sprintf('(%i,%i). ',idxRow,indexSetOfTrials);
                title(titleId);
            end
        
            %%
            % Plot the coherence-sq response 
            %%            
            if(xyDataIsValid==1)
                idxRow = (idxSeg-1)*4 + 4;
                subplot('Position',reshape(...
                    subPlotPanelSegment(idxRow,indexSetOfTrials,:),1,4));

                plot(segData.H0.frequencyHz(segData.H0.idxBW),...
                    segData.H0.coherenceSq(segData.H0.idxBW),...
                    '-','Color',lineColors.red);
                hold on;
                plot(segData.H1.frequencyHz(segData.H1.idxBW),...
                    segData.H1.coherenceSq(segData.H1.idxBW),...
                    '-','Color',lineColors.purple);
                hold on;
                plot(segData.H2.frequencyHz(segData.H2.idxBW),...
                    segData.H2.coherenceSq(segData.H2.idxBW),...
                    '-','Color',lineColors.blue);
                hold on;

                box off;    
                xlabel('Frequency (Hz)');
                ylabel('Coherence-Sq');
        
                titleId = sprintf('(%i,%i). ',idxRow,indexSetOfTrials);
                title(titleId);    
            end
    
            setSegmentJson(indexIntoSetOfSegments).segment = segmentJson;
        end
    
        
        outputJsonDir = fullfile(projectFolders.output_json,folderName);
        if(~exist(outputJsonDir,'dir'))
            mkdir(outputJsonDir);
        end
        
        setSegmentJsonEncode = jsonencode(setSegmentJson);
        jsonFileName = ['analysis_',experimentJson.trials{idxTrial}];
        fidJson = fopen(fullfile(outputJsonDir,jsonFileName),'w');
        fprintf(fidJson,setSegmentJsonEncode);
    
        clear('setSegmentJson');
    
    end
    
    fclose(fidLogFile);
    
    outputPlotDir = fullfile(projectFolders.output_plots,folderName);
    if(~exist(outputPlotDir,'dir'))
        mkdir(outputPlotDir);
    end
    
    fileNameMod =['_daqDelayModel_',settings.daqDelayModel];
    fileNameMod = strrep(fileNameMod,'-','_');
    switch settings.daqDelayModel
        case 'time-domain'
            if(modelSettings.useManuallySetDaqDelay==1)
                fileNameMod = [fileNameMod,'_fixedDelay'];
            else
                fileNameMod = [fileNameMod,'_fitDelayRmsePhase'];
                if(modelSettings.zeroPhaseResponseSlope==1)
                    fileNameMod = [fileNameMod,'_fitDelayZeroPhaseSlope'];
                end
            end            
        case 'frequency-domain'
            if(modelSettings.useManuallySetDaqDelay==1)
                fileNameMod = [fileNameMod,'_fixedInvLpfFrequency'];
            else
                fileNameMod = [fileNameMod,'_fitInvLpfFrequency'];
                if(modelSettings.zeroPhaseResponseSlope==1)
                    fileNameMod = [fileNameMod,'_fitInvLpfFrequencyZeroPhaseSlope'];
                end
            end            
        otherwise
            assert(0,'Error: delayModel must be either time-domain or frequency-domain');
    end
    
    figSegments=configPlotExporter(figSegments, ...
                        pageWidthSegment, pageHeightSegment);
    fileName =    ['fig_FrequencyResponse_',folderName,fileNameMod];
    print('-dpdf', fullfile(outputPlotDir,[fileName,'.pdf']));    
    saveas(figSegments,fullfile(outputPlotDir,[fileName,'.fig']));
    close(figSegments);

    figIntraSegments=configPlotExporter(figIntraSegments, ...
                        pageWidthIntraSegment, pageHeightIntraSegment);
    fileName =    ['fig_IntraSegmentDegradation_',folderName,fileNameMod];
    print('-dpdf', fullfile(outputPlotDir,[fileName,'.pdf']));    
    saveas(figIntraSegments,fullfile(outputPlotDir,[fileName,'.fig']));
    close(figIntraSegments);


    figTimeSeries=configPlotExporter(figTimeSeries, ...
                        pageWidthTimeSeries, pageHeightTimeSeries);
    fileName =    ['fig_TimeSeries_',folderName,fileNameMod];
    print('-dpdf', fullfile(outputPlotDir,[fileName,'.pdf']));    
    saveas(figTimeSeries,fullfile(outputPlotDir,[fileName,'.fig']));
    close(figTimeSeries);    
end
success=1;


