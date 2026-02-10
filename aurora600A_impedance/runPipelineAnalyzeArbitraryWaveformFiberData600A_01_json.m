function success = runPipelineAnalyzeArbitraryWaveformFiberData600A_01_json(...
                        folderName, specimenType, trialType, settings,projectFolders)

success=0;
mm2m = 0.001;

optSettings.type=1;
% 1. min rmse gain error
% 2. min rmse phase error
% 3. min rmse of the slope of the phase error
optSettings.scaling   = [];
optSettings.objScaling= 1;
optSettings.lambda    = [];
optSettings.phasePolishingInterations = 15;

assert(strcmp(settings.daqDelayModel,'frequency-domain'),...
       'Error: ')

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

modelSettings.type = 0; 
% 0. spring-damper in parallel
% 1. spring-damper in series
switch modelSettings.type
    case 0
        modelSettings.name ='parallel-spring-damper';
    case 1
        modelSettings.name ='no-model';
    otherwise assert(0,'Error: invalid modelSettings.type');
end



modelSettings.coherenceSquaredThreshold=settings.coherenceSquaredThreshold;
modelSettings.numberOfParameters    = 2;

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
% Plot settings
%%
lineColors = getPaulTolColourSchemes('bright');



%%
% Scan through the meta data 
% - check the sha256 value
% - count the total number of segments to plot. 
%%
if(settings.checkDataIntegrity==1)

   
    setOfTrials=verifyDataIntegrityCompletnessOrder(...
                dataFolder,experimentJson,fidLogFile,...
                flag_readHeader,flag_checkSha256Sum);

    totalNumberOfSegmentsToPlot = 0;
    fprintf('%s\n','Preprocessing: ');
    fprintf('%s\n','  Counting the number of segments to plot');
    fprintf(fidLogFile,'%s\n','Preprocessing: ');
    fprintf(fidLogFile,'%s\n','  Counting the number of segments to plot');
    
    for indexSetOfTrials=1:1:length(setOfTrials)
    
        i = setOfTrials(indexSetOfTrials);
    
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

    
    plotWidth                               = ones(1,numberOfHorizontalPlotColumnsGeneric).*25;
    plotHeight                              = ones(numberOfVerticalPlotRowsGeneric,1).*10;
    plotHorizMarginCm                       = 3;
    plotVertMarginCm                        = 2;
    baseFontSize                            = 12;
    
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
    
        i = setOfTrials(indexSetOfTrials);
        %%
        % Read in the meta data
        %%   
        fprintf('\t%s\n',experimentJson.trials{i});
        fprintf(fidLogFile,'\t%s\n',experimentJson.trials{i});
        
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
                                settings.forceNoiseThreshold,...
                                settings.isometricNoiseFilterCutoffFrequencyHz,...
                                auroraData.Setup_Parameters.A_D_Sampling_Rate.Value,...
                                flagPlotReference);

                    f0 = forceReference;
                    t0 = auroraData.Data.Time.Values(intraSegmentIndex(indexReference));

                    flag_debugFF=0;
                    if(flag_debugFF==1)
                        figDebugFF=figure;
                        plot(auroraData.Data.Time.Values(intraSegmentIndex,1),...
                             auroraData.Data.Fin.Values(intraSegmentIndex,1),...
                             '-','Color',[1,1,1].*0.75,'DisplayName','Raw Data');
                        hold on;
                        plot(auroraData.Data.Time.Values(intraSegmentIndex,1),...
                             f,'-k','DisplayName',sprintf('Filtered Data (%i)',...
                             settings.isometricNoiseFilterCutoffFrequencyHz));
                        hold on;
                        plot(auroraData.Data.Time.Values(intraSegmentIndex,1),...
                             ffnoise,'-','Color',[0,1,1],'DisplayName','Noise Magnitude');
                        hold on;
                        plot(t0,f0,'o','Color',[0,0,0],'MarkerFaceColor',[0,0,0],...
                            'DisplayName','Reference Force');
                        hold on;
                        legend('Location','NorthWest');
                        hold on;
                        box off;

                        xlabel(['Time (',auroraData.Data.Time.Unit,')']);
                        ylabel(['Force (',auroraData.Data.Fin.Unit,')']);
                        here=1;
                    end

   
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
        titleStr = strrep(experimentJson.trials{i},'_','\_');                
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
        % Plot each of the segments
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
            assert(isempty(bandwidth)==0,'Error: could not find larb-segment property bandwidth');
    
            if(isempty(amplitude))
                fprintf(fidLogFile,'%s\n',...
                    ['Error: could not find larb-segment property amplitude']);
            end
            assert(isempty(amplitude)==0,'Error: could not find larb-segment property amplitude');
       
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
                segData.bandwidth = bandwidth(1,2);
                segData.sampleFrequency = sampleFrequency;

                %[freqHz, gain, phase,coherenceSq] = ...
                segData.H0 = evaluateGainPhaseCoherenceSq(...
                                    timeVec,...
                                    x,...
                                    y,...
                                    bandwidth(1,2),...
                                    sampleFrequency);
        
                dfreq = 1;
                idxFreq     = find(segData.H0.frequencyHz <= (bandwidth(1,2)+dfreq));
                idxFreqBand = find(segData.H0.frequencyHz <= bandwidth(1,2) ...
                                 & segData.H0.frequencyHz >= bandwidth(1,1));

                %
                % Update the fitting bandwidth
                %
                idxFirst = find(segData.H0.coherenceSq(segData.H0.idxBW) ...
                        >= modelSettings.coherenceSquaredThreshold,1,'first');
                idxLast =  find(segData.H0.coherenceSq(segData.H0.idxBW) ...
                        >= modelSettings.coherenceSquaredThreshold,1,'last');
                
                optSettings.bandwidth =   segData.bandwidth...
                                        .*settings.normFittingBandwidth;

                if(~isempty(idxFirst) && ~isempty(idxLast))
                    freqA = segData.H0.frequencyHz(idxFirst);
                    freqB = segData.H0.frequencyHz(idxLast);
                    if(freqA > optSettings.bandwidth(1,1))
                        optSettings.bandwidth(1,1)=freqA;
                    end
                    if(freqB < optSettings.bandwidth(1,2))
                        optSettings.bandwidth(1,2)=freqB;
                    end
                end                
            end
        
            %%
            % Fit a first order low pass model to the response
            %%
        
            if(xyDataIsValid==1)

                delayModel.delayPropagation=0;
                delayModel.daqDelay        = settings.daqDelay; %in seconds
                delayModel.daqFilterFrequencyHz = settings.daqFilterFrequencyHz;
                delayModel.daqDelayModel   = settings.daqDelayModel;
                 
            

                modelParams.k            = 1.4;
                modelParams.beta         = 0;

            
                modelParams.bandwidth    = bandwidth(1,2);
                modelParams.sampleFrequency= sampleFrequency;
                modelParams.time         = auroraData.Data.Time.Values(dataIndex);
                modelParams.x            = ifft(fft(x),'symmetric');
                modelParams.type         = modelSettings.type;
            
                samples     = length(x);
                timeVec     = [0:(1/(samples-1)):1]' .* (samples/sampleFrequency);
                freqHz      = [1:1:samples]' .*(sampleFrequency/samples);
                freq        = freqHz.*(2*pi);
            
                modelParams.xdot         = ifft(fft(x).*(complex(0,1).*freq) ,'symmetric');
                modelParams.frequency    = freq;
                modelParams.frequencyHz  = freqHz;
            
                flag_checkXdot=0;
                if(flag_checkXdot==1)
                    xdotNum = calcCentralDifferenceDataSeries(timeVec,x);
            
                    figXdotCheck = figure;
                    subplot(2,1,1);
                    plot(timeVec,modelParams.xdot,'-b');
                    hold on;
                    plot(timeVec,xdotNum,'-r');
                    hold on;
                    xlabel('Time (s)');
                    ylabel('mm/s');
                    title('xdot');
            
                    subplot(2,1,2);
                    plot(timeVec,modelParams.xdot-xdotNum,'-k');
                    hold on;
                    xlabel('Time (s)');
                    ylabel('mm/s');
                    title('xdot error');
                    
                    here=1;
                end
            
                xdotNum = calcCentralDifferenceDataSeries(timeVec,x);
                        
                model = calcImpedanceModelFrequencyResponse600A(modelParams);
            
                %%
                % Compensate for the propagation delay
                %%
                switch experimentJson.experiment.material
                    case "stainless steel"
                        assert(strcmp(experimentJson.experiment.specimen,'Spring'),...
                               ['Error: a stainless steel material must go with a ',...
                               'Spring specimen']);

                        %
                        % Compensating for the delay changes the gain
                        % and thus the estimated stiffness of the spring. 
                        % Here we iterate over candidate delays until
                        % the difference between subsequent delays is small
                        %
                        H = segData.H0;
                        delayError = inf;
                        delayP = 0;
                        iter=0;

                        while delayError > settings.phaseDelayTolerance ...
                                && iter < settings.phaseDelayMaxIteration

                            bandwidthFit = segData.bandwidth...
                                          .*settings.normFittingBandwidth;

                            idxFit = find(H.frequencyHz >= bandwidthFit(1,1)...
                                        & H.frequencyHz <= bandwidthFit(1,2));

                            delay = calcPhaseDelayOfThinElasticRod(...
                                H.gain(idxFit),...
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
                                    segData.sampleFrequency);
                            if(iter > 1)
                                delayError = abs(delay-delayP);
                            end
                            delayP = delay;
                            iter=iter+1;
                        end
                        segData.H1=H;
                        delayModel.delayPropagation = delay;

                        if(iter > settings.phaseDelayMaxIteration)
                            fprintf(['  Warning: delay tolerance not met\n',...
                                     '  %1.2e > %1.2e\t error\n',...
                                     '  %i \t iterations'],...
                                     delayError, ...
                                     settings.phaseDelayTolerance,...
                                     settings.phaseDelayMaxIteration);
                        end

                    case "muscle"
                        assert(0,'Error: not yet implemented');
                    otherwise assert(0,['Error: Unrecognized ',...
                        'material. Only muscle and stainless steel',...
                        ' have been implemented']);        
                end
                
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
                                        segData.sampleFrequency);  

                    
                    fittingResults = ...
                        calcLowPassFilterFrequencyToZeroPhaseResponseSlope(...
                            delayModel.daqFilterFrequencyHz,...
                            expResponse,...
                            delayModel.daqFilterFrequencyHz*0.5,...
                            optSettings.bandwidth,...
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
                            segData.sampleFrequency); 


           

                %%
                % Fit the spring model
                %%

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

                    %%
                    % Fit k & d of the spring to the gain response
                    %%                                    
                    switch modelSettings.numberOfParameters
                        case 1
                            x0 = [1];              
                            modelParams.time         = segData.H2.time;
                            modelParams.k            = mean(segData.H2.gain);
                            modelParams.beta         = 0;
                            optSettings.scaling = [modelParams.k];
                            paramNames = {'k'};
            
                        case 2
                            x0 = [1,1]; 
                            modelParams.time         = segData.H2.time;
                            modelParams.k            = mean(segData.H2.gain);
                            modelParams.beta         = modelParams.k*0.01;                
                            optSettings.scaling = [modelParams.k,modelParams.beta];
                            paramNames = {'k','beta'};                
                        otherwise assert(0,['Error modelSettings.numberOfParameters',...
                                ' incorrectly set']);
                    end
                    
                    lb = [x0].*0;
                    ub = [x0].*10;
            
                    for j=1:1:length(paramNames)
                        model.([paramNames{j},'_bounds'])=[];
                    end
                    optSettings.type = 1; %1. gain error, 2. phase error
                    errFcn = @(argX)calcErrorOfImpedanceModel600A(...
                                        argX, paramNames,...
                                        optSettings, modelParams, segData);
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
                        modelParams.(paramNames{j})=xSol(j)*optSettings.scaling(j);
                    end
                
                
                end
            
                %
                % Evaluate the fitted model response
                %
                model = calcImpedanceModelFrequencyResponse600A(modelParams);
            

                %%
                % Evaluate errors
                %%
                assert(length(model.idxBW)==length(segData.H2.idxBW),...
                       ['Error: model and experimental data frequency responses'...
                        ' have differing lengths']);
        
                for j=1:1:length(model.idxBW)
                    modelFreq=model.frequency(model.idxBW(j));
                    dataFreq =segData.H2.frequency(segData.H2.idxBW(j));
                    
                    assert(abs(modelFreq-dataFreq)<1e-3,...
                        ['Error: model and data frequencies differ'])
                end
        
                idxA = find(segData.H2.frequencyHz >= ...
                                optSettings.bandwidth(1,1),1,'first');
                idxB = find(segData.H2.frequencyHz <= ...
                                optSettings.bandwidth(1,2),1,'last');
                
        
                rmse.gain = sqrt( mean( (model.gain(idxA:idxB) ...
                                        -segData.H2.gain(idxA:idxB)).^2 ));
                rmse.phase = sqrt( mean( (model.phase(idxA:idxB) ...
                                         -segData.H2.phase(idxA:idxB)).^2 ));
                rmse.coherenceSq = getSummaryStatistics(segData.H2.coherenceSq(idxA:idxB));
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
    
            segmentJson.interval=[timeStart,timeEnd];
            segmentJson.index = idxSeg;
            segmentJson.type  = trialJson.segments(idxSeg).type; 

            segmentJson.time    = auroraData.Data.Time.Values(dataIndex,1);
            segmentJson.length  = auroraData.Data.Lin.Values(dataIndex,1);
            segmentJson.force   = auroraData.Data.Fin.Values(dataIndex,1);            
            
            segmentJson.forceReference = ...
                intraSegmentData(1).forceReference;

            if(~isempty(activeIntervals))
                segmentJson.pre.time = intraSegmentData(idxSeg).filtered.time(end);
                segmentJson.pre.length = intraSegmentData(idxSeg).filtered.length(end);
                segmentJson.pre.force = intraSegmentData(idxSeg).filtered.force(end);                
            else
                segmentJson.pre.time = [];
                segmentJson.pre.length = [];
                segmentJson.pre.force = [];
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
      
    
            segmentJson.Hs.bandwidth = optSettings.bandwidth;
            segmentJson.Hs.frequencyHz = segData.H2.frequencyHz(idxA:idxB);
            segmentJson.Hs.gain = segData.H2.gain(idxA:idxB);   
            segmentJson.Hs.phase = segData.H2.phase(idxA:idxB);               
            segmentJson.Hs.coherenceSq = segData.H2.coherenceSq(idxA:idxB);               
            
            segmentJson.Hs.summary.gain = ...
                getSummaryStatistics(segData.H2.gain(idxA:idxB));            
            segmentJson.Hs.summary.phase = ...
                getSummaryStatistics(segData.H2.phase(idxA:idxB).*(180/pi));
            segmentJson.Hs.summary.coherenceSq = ...
                getSummaryStatistics(segData.H2.coherenceSq(idxA:idxB));
            segmentJson.Hs.units.gain = ...
                [auroraData.Data.Fin.Unit,'/',auroraData.Data.Lin.Unit];
            segmentJson.Hs.units.phase = 'degrees';
            segmentJson.Hs.units.coherenceSq = '';
    
            segmentJson.model.settings      = modelSettings;
            segmentJson.model.delayPropagation = delayModel.delayPropagation;
            segmentJson.model.daqDelayModel    = delayModel.daqDelayModel;
            segmentJson.model.daqDelay         = delayModel.daqDelay;
            segmentJson.model.daqFilterFrequencyHz = delayModel.daqFilterFrequencyHz;
            segmentJson.model.bandwidth     = optSettings.bandwidth;
            segmentJson.model.param_names   = paramNames;
            segmentJson.model.param_values  = zeros(size(segmentJson.model.param_names));
            for(idxParam=1:1:length(segmentJson.model.param_names))
                segmentJson.model.param_values(idxParam) = ...
                    modelParams.(segmentJson.model.param_names{idxParam});
            end
            segmentJson.model.rmse.gain     = rmse.gain;
            segmentJson.model.rmse.phase    = rmse.phase;  

            segmentJson.model.bandwidth     = optSettings.bandwidth;
            segmentJson.model.frequencyHz   = model.frequencyHz(idxA:idxB);
            segmentJson.model.gain          = model.gain(idxA:idxB);
            segmentJson.model.phase         = model.phase(idxA:idxB);
            segmentJson.model.coherenceSq   = model.coherenceSq(idxA:idxB);
            
                    

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
                
                plot(model.frequencyHz(model.idxBW),...
                     model.gain(model.idxBW),'--k');
                hold on;
                for j=1:1:2
                    plot([optSettings.bandwidth(j);...
                          optSettings.bandwidth(j)],...
                         [min(segData.H2.gain(segData.H2.idxBW)),...
                          max(segData.H2.gain(segData.H2.idxBW))],...
                         '-c');
                    hold on;
                end
                switch settings.daqDelayModel
                    case 'time-domain'
                        text(max(segData.H2.frequencyHz(segData.H2.idxBW)),...
                             min(segData.H2.gain(segData.H2.idxBW)),...
                             sprintf(['%1.2e k\n',...
                                      '%1.2e beta\n',...
                                      '%1.2e delay'],...
                                     modelParams.k,...
                                     modelParams.beta,...
                                     delayModel.daqDelay),...
                                     'HorizontalAlignment','right',...
                                     'VerticalAlignment','bottom',...
                                     'FontSize',8);
                    case 'frequency-domain'
                        text(max(segData.H2.frequencyHz(segData.H2.idxBW)),...
                             min(segData.H2.gain(segData.H2.idxBW)),...
                             sprintf(['%1.2e k\n',...
                                      '%1.2e beta\n',...
                                      '%1.2e Hz %s'],...
                                     modelParams.k,...
                                     modelParams.beta,...
                                     delayModel.daqFilterFrequencyHz,...
                                     '$$\omega_o$$'),...
                                     'HorizontalAlignment','right',...
                                     'VerticalAlignment','bottom',...
                                     'FontSize',8);
                    otherwise
                        assert(0,['Error: delayModel must be either',...
                                  ' frequency-domain or time-domain']);
                end
                hold on;
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
                plot(model.frequencyHz(model.idxBW),...
                     model.phase(model.idxBW).*(180/pi),'--k');
                hold on;    
                
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
        jsonFileName = ['analysis_',experimentJson.trials{i}];
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


