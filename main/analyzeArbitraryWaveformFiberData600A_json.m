function success = analyzeArbitraryWaveformFiberData600A_json(folderName, settings)

success=0;

rootDir         = getRootProjectDirectory();
projectFolders  = getProjectFolders(rootDir);

addpath(projectFolders.aurora600A);
addpath(projectFolders.common);
addpath(projectFolders.postprocessing);
addpath(projectFolders.experiments);
addpath(fullfile(rootDir,'aurora600A_impedance'));

flag_readHeader         = 1;
flag_checkSha256Sum     = 1; %Might not work on Windows

trialTypes = {'delay','degradation','impedance'};

%folderName          = '20251203_impedance_larb_7';

if(contains(folderName,'spring'))
    trialTypes='delay';
elseif(contains(folderName,'impedance'))
    trialTypes = 'impedance';
elseif(contains(folderName,'degradation'))
    trialTypes = 'degradation';
else
    assert(0,['Error: folder name does not contain one of the following'...
              ' keywords: spring, impedance, or degradation']);
end

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

prePostWindowTimeWidth = 0.5;
prePostWindowTimeOffset = 0.5;

modelSettings.coherenceSquaredThreshold=0.8;
modelSettings.numberOfParameters    = 2;
modelSettings.zeroPhaseResponseSlope= 0;
modelSettings.useManuallySetDelay   = 1;
modelSettings.manuallySetDelay      = 6.67e-4;

if(strcmp(trialTypes,'delay'))
    modelSettings.numberOfParameters    = 1;
    modelSettings.useManuallySetDelay   = 0;
end

% Delay of the force signal as measured using small steel springs.
%
% 1. fit: min slope of line lsq line through phase data
%   :H20 + steel spring  
%   :trials: 20251107_small, 20251107_medium, 20260108_impedance
%   :amp   : 0.01 and 0.001 lo (lo is the stretch at 0.2 mN)
%
% mean: 0.594 ms
%  min: 0.528 ms
%  max: 0.637 ms
%
% 2. fit: min rmse phase against 0.
%   : H20 + steel spring
%   :trials: 20251107_small, 20251107_medium, 20260108_impedance
%   :amp   : 0.01 and 0.001 lo (lo is the stretch at 0.2 mN)
%
% mean: 0.508 ms
%  min: 0.458 ms
%  max: 0.567 ms
%
% I have a preference for option 1, as the resulting phase response
% is small and (mostly) above zero. Option 2 ends up having large portions
% with a slightly negative phase response. In princple this is physically
% impossible. In any case, 
%
%


dataFolder      = fullfile(projectFolders.data_600A,folderName);
experimentStr   = fileread(fullfile(dataFolder,[folderName,'.json']));
experimentJson  = jsondecode(experimentStr);

fidLogFile = fopen(fullfile(dataFolder,'log.txt'),'w');

currentDateTime=datestr(now, 'dd/mm/yy-HH:MM:SS');
fprintf(fidLogFile,'%s\n',currentDateTime);
fprintf('%s\n',currentDateTime);

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
% Scan through the meta data 
% - check the sha256 value
% - count the total number of segments to plot. 
%%
if(settings.checkDataIntegrity==1)

    totalNumberOfSegmentsToPlot = 0;
    fprintf('%s\n','Preprocessing: ');
    fprintf('%s\n','  :Identifying trials with Larb-Stochastic segments');
    fprintf('%s\n','  :Checking that the files are listed in the order of collection');
    fprintf('%s\n','  :Checking the sha256 values of the data against the stored value');
    
    fprintf(fidLogFile,'%s\n','Preprocessing: ');
    fprintf(fidLogFile,'%s\n','  :Identifying trials with Larb-Stochastic segments');
    fprintf(fidLogFile,'%s\n','  :Checking that the files are listed in the order of collection');
    fprintf(fidLogFile,'%s\n','  :Checking the sha256 values of the data against the stored value');
    
    setOfTrials = [];
    trialOrdering(length(experimentJson.trials)) = struct('name','','time','');
    for i=1:1:length(experimentJson.trials)
        commentStr = '';
        %%
        % Fetch the experimental data files
        %%
        trialStr = fileread(fullfile(dataFolder,experimentJson.trials{i}));
        trialJson = jsondecode(trialStr);
    
        if(length(trialJson.data.file)>1)
            filePath = 'data';
            for k=2:1:length(trialJson.data.file)
                filePath = [filePath,filesep,trialJson.data.file{k}];
            end
        end
        dataPath = fullfile(dataFolder,filePath);        
        auroraData = readAuroraData600A(dataPath,flag_readHeader); 
    
    
        %%
        % Get the time stamp of the measurement
        %%    
        dateTime = convertTimeStamp600A(auroraData.Setup_Parameters.Created.Value);
        
        dateTimeInYears= dateTime.year ...
            + ((dateTime.month-1)/12)...
            + (dateTime.day/365) ...
            + (dateTime.hour/(24*365)) ...
            + (dateTime.minute/(60*24*365)) ...
            + (dateTime.second/(60*60*24*365));
    
        %Check and make sure that this entry was collected after the previous
        %one
        if(i > 1)
            if(dateTimeInYears < previousDateTime)
                commentStr = [commentSTR,' Out-of-order'];
            end
        end
    
        previousDateTime=dateTimeInYears;
    
        %%
        %Check the sha256sum
        %%
        if(flag_checkSha256Sum==1)
            [status,cmdout] =  system(['sha256sum ',dataPath]);
            idx = strfind(cmdout,' ');        
            idx=idx-1;
            sha256Sum = cmdout;
            sha256Sum = sha256Sum(1,1:idx);
    
            if(strcmp(sha256Sum,trialJson.data.sha256)==0)
                here=1;
            end
            if(strcmp(sha256Sum,trialJson.data.sha256)==0)
              commentStr = [commentStr,' SHA256-mismatch'];
            end
        end    
        %
        % Check to see if this trial has a Larb-Stochastic segment
        %
        isLarbStochastic = 0;    
        if(~isempty(trialJson.segments) ... 
                && strcmp(trialJson.segments(1).type,'Larb-Stochastic')==1)
            setOfTrials = [setOfTrials;i];        
            isLarbStochastic=1;
        else
            commentStr = [commentStr,' Skipping'];
        end
    
        %
        % Message to user
        %    
        
        fprintf('\t%i/%i/%i %i:%i:%i\t%s\t%s\n',...
            dateTime.year,dateTime.month,dateTime.day,...
            dateTime.hour,dateTime.minute,dateTime.second,...
            commentStr,...
            experimentJson.trials{i});
    
        fprintf(fidLogFile,...
            '\t%i/%i/%i %i:%i:%i\t%s\t%s\n',...
            dateTime.year,dateTime.month,dateTime.day,...
            dateTime.hour,dateTime.minute,dateTime.second,...
            commentStr,...
            experimentJson.trials{i});    
    
    
    
    end


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
        
        %%
        % Check if the protocol file exists
        %%
        if( ~exist(protocolPath,'file'))
            fprintf('%s\n','  Warning: protocol file not found: ');
            fprintf('%s\n',['    ', protocolPath]);
            fprintf(fidLogFile,'%s\n','  Warning: protocol file not found: ');
            fprintf(fidLogFile,'%s\n',['    ', protocolPath]);        
        end
    
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

end

if(settings.processData==1)

    %%
    % Plot configuration
    %%
    
    
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
    
    [subPlotPanelGeneric, pageWidthGeneric,pageHeightGeneric]= ...
      plotConfigGeneric(  numberOfHorizontalPlotColumnsGeneric,...
                          numberOfVerticalPlotRowsGeneric,...
                          plotWidth,...
                          plotHeight,...
                          plotHorizMarginCm,...
                          plotVertMarginCm,...
                          baseFontSize); 
    
    figH = figure;
    
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
        % Get the interval to plot
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
            end
        
            %%
            % Fit a first order low pass model to the response
            %%
        
            if(xyDataIsValid==1)
                omega3dB_Hz = 250;    
            
                omega               = Hs.frequency;
                params.k            = 1.4;
                params.beta         = 0;
                params.delay        = 0.0005; %in seconds
            
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
                idxFirst = find(Hs.coherenceSq(Hs.idxBandwidth) ...
                        >= modelSettings.coherenceSquaredThreshold,1,'first');
                idxLast =  find(Hs.coherenceSq(Hs.idxBandwidth) ...
                        >= modelSettings.coherenceSquaredThreshold,1,'last');
        
                if(~isempty(idxFirst) && ~isempty(idxLast))
                    freqA = Hs.frequencyHz(idxFirst);
                    freqB = Hs.frequencyHz(idxLast);
                    freqWidth = freqB-freqA;
                    if(freqWidth > params.bandwidth*0.25)
                        optSettings.bandwidth = [freqA,freqB];                
                    else
                        optSettings.bandwidth = params.bandwidth.*[0.05,0.95];                
                    end
                else
                    optSettings.bandwidth = params.bandwidth.*[0.05,0.95];
                end
        
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
                
                    if(modelSettings.useManuallySetDelay==0)
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
                            delayDelta = 0.001;
                            delayBest = calcDelayToZeroPhaseResponseSlope(...
                                                    params,...
                                                    expData,...
                                                    delayDelta,...
                                                    optSettings.bandwidth,...
                                                    optSettings.phasePolishingInterations);            
                
                            params.delay = delayBest;
                        end
            
                    else
                        params.delay = modelSettings.manuallySetDelay;
                    end
            
                    %
                    % Fit k & d of the spring to the gain response
                    %
                    if((modelSettings.useManuallySetDelay==1 && indexLambda==1) ...
                        || modelSettings.useManuallySetDelay==0 )
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
        
                        expData.HsDelayed = HsFit;
                    end
            
                    switch modelSettings.numberOfParameters
                        case 1
                            x0 = [1]; 
                            params.k            = mean(HsFit.gain);
                            params.beta         = 0;
                            optSettings.scaling = [params.k];
                            paramNames = {'k'};
            
                        case 2
                            x0 = [1,1]; 
                            params.k            = mean(HsFit.gain);
                            params.beta         = mean(HsFit.gain);                
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
                % Evaluate errors
                %%
                assert(length(model.idxBandwidth)==length(HsFit.idxBandwidth),...
                       ['Error: model and experimental data frequency responses'...
                        ' have differing lengths']);
        
                for j=1:1:length(model.idxBandwidth)
                    modelFreq=model.frequency(model.idxBandwidth(j));
                    dataFreq =HsFit.frequency(HsFit.idxBandwidth(j));
                    
                    assert(abs(modelFreq-dataFreq)<1e-3,...
                        ['Error: model and data frequencies differ'])
                end
        
                idxA = find(HsFit.frequencyHz >= ...
                                optSettings.bandwidth(1,1),1,'first');
                idxB = find(HsFit.frequencyHz <= ...
                                optSettings.bandwidth(1,2),1,'last');
                
        
                rmse.gain = sqrt( mean( (model.gain(idxA:idxB) ...
                                        -HsFit.gain(idxA:idxB)).^2 ));
                rmse.phase = sqrt( mean( (model.phase(idxA:idxB) ...
                                         -HsFit.phase(idxA:idxB)).^2 ));
                rmse.coherenceSq = getSummaryStatistics(HsFit.coherenceSq(idxA:idxB));
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
                tempSetting = experimentJson.experiment.temperature_C;           
                temp = str2double(tempSetting(1:idx(1,1)));
                temperatureSummary.percentiles.x=[];
                temperatureSummary.percentiles.y=[];
                temperatureSummary.mean = temp;
                temperatureSummary.median=temp;
                temperatureSummary.std = 0;
                temperatureSummary.min = temp;
                temperatureSummary.max = temp;
            end
    
            segmentJson.time=[timeStart,timeEnd];
            segmentJson.index = idxSeg;
            segmentJson.type  = trialJson.segments(idxSeg).type; 
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
    
            timePreStart = timeStart...
                            -prePostWindowTimeWidth*scaleTime...
                            -prePostWindowTimeOffset*scaleTime;
            timePreEnd   = timeStart-prePostWindowTimeOffset*scaleTime;
    
            preIndex = find( auroraData.Data.Time.Values >= timePreStart ...
                            & auroraData.Data.Time.Values <= timePreEnd); 
    
            segmentJson.pre.time = [timePreStart,timePreEnd];
            segmentJson.pre.summary.length = ...
                getSummaryStatistics(auroraData.Data.Lin.Values(preIndex,1));
            segmentJson.pre.summary.force = ...
                getSummaryStatistics(auroraData.Data.Fin.Values(preIndex,1));
    
            timePostStart = timeEnd+prePostWindowTimeOffset*scaleTime;
            timePostEnd   = timeEnd+prePostWindowTimeOffset*scaleTime...
                                   +prePostWindowTimeWidth*scaleTime;
    
            postIndex = find( auroraData.Data.Time.Values >= timePostStart ...
                            & auroraData.Data.Time.Values <= timePostEnd); 
    
            segmentJson.post.time = [timePostStart,timePostEnd];
            segmentJson.post.summary.length = ...
                getSummaryStatistics(auroraData.Data.Lin.Values(postIndex,1));
            segmentJson.post.summary.force = ...
                getSummaryStatistics(auroraData.Data.Fin.Values(postIndex,1));
    
    
            segmentJson.Hs.bandwidth = optSettings.bandwidth;
            segmentJson.Hs.summary.gain = ...
                getSummaryStatistics(HsFit.gain(idxA:idxB));
            segmentJson.Hs.summary.phase = ...
                getSummaryStatistics(HsFit.phase(idxA:idxB).*(180/pi));
            segmentJson.Hs.summary.coherenceSq = ...
                getSummaryStatistics(HsFit.coherenceSq(idxA:idxB));
            segmentJson.Hs.units.gain = ...
                [auroraData.Data.Fin.Unit,'/',auroraData.Data.Lin.Unit];
            segmentJson.Hs.units.phase = 'degrees';
            segmentJson.Hs.units.coherenceSq = '';
    
            segmentJson.model.settings      = modelSettings;
            segmentJson.model.delay         = params.delay;
            segmentJson.model.bandwidth     = optSettings.bandwidth;
            segmentJson.model.param_names   = paramNames;
            segmentJson.model.param_values  = zeros(size(segmentJson.model.param_names));
            for(idxParam=1:1:length(segmentJson.model.param_names))
                segmentJson.model.param_values(idxParam) = ...
                    params.(segmentJson.model.param_names{idxParam});
            end
            segmentJson.model.rmse.gain     = rmse.gain;
            segmentJson.model.rmse.phase    = rmse.phase;        
    
           
            %%
            % Plot time-length-force    
            %%
            figure(figH);
        
            idxRow = (idxSeg-1)*4 + 1;
            subplot('Position',reshape(subPlotPanelGeneric(idxRow,indexSetOfTrials,:),1,4));
        
            yyaxis left;
            plot(auroraData.Data.Time.Values(preIndex,1),...
                 auroraData.Data.Lin.Values(preIndex,1),'-b');...
            hold on;        
            plot(auroraData.Data.Time.Values(dataIndex,1),...
                 auroraData.Data.Lin.Values(dataIndex,1),'-b');...
            hold on;
            plot(auroraData.Data.Time.Values(postIndex,1),...
                 auroraData.Data.Lin.Values(postIndex,1),'-b');...
            hold on;
            box off;    
            xlabel(sprintf('Time (%s)',auroraData.Data.Time.Unit));
            ylabel(sprintf('Length (%s)',auroraData.Data.Lin.Unit));
        
            yyaxis right;
            plot(auroraData.Data.Time.Values(preIndex,1),...
                 auroraData.Data.Fin.Values(preIndex,1),'-r');...
            hold on;        
            plot(auroraData.Data.Time.Values(dataIndex,1),...
                 auroraData.Data.Fin.Values(dataIndex,1),'-r');...
            hold on;
            plot(auroraData.Data.Time.Values(postIndex,1),...
                 auroraData.Data.Fin.Values(postIndex,1),'-r');...
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
                subplot('Position',reshape(subPlotPanelGeneric(idxRow,indexSetOfTrials,:),1,4));    
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
                titleId = sprintf('(%i,%i). ',idxRow,indexSetOfTrials);
                title(titleId);
            end
        
            %%
            % Plot the phase response 
            %%            
            if(xyDataIsValid==1)        
                idxRow = (idxSeg-1)*4 + 3;
                subplot('Position',reshape(subPlotPanelGeneric(idxRow,indexSetOfTrials,:),1,4));
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
        
                titleId = sprintf('(%i,%i). ',idxRow,indexSetOfTrials);
                title(titleId);
            end
        
            %%
            % Plot the coherence-sq response 
            %%            
            if(xyDataIsValid==1)
                idxRow = (idxSeg-1)*4 + 4;
                subplot('Position',reshape(subPlotPanelGeneric(idxRow,indexSetOfTrials,:),1,4));
                plot(Hs.frequencyHz(idxFreq),Hs.coherenceSq(idxFreq),'-','Color',[1,1,1].*0.75);
                hold on;
                plot(HsFit.frequencyHz(idxFreq),HsFit.coherenceSq(idxFreq),'-','Color',[1,1,1].*0.25);
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
    
    fileNameMod ='';
    if(modelSettings.useManuallySetDelay==1)
        fileNameMod = '_fixedDelay';
    else
        fileNameMod = '_fitDelayRmsePhase';
        if(modelSettings.zeroPhaseResponseSlope==1)
            fileNameMod = '_fitDelayZeroPhaseSlope';
        end
    end
    
    figH=configPlotExporter(figH, ...
                        pageWidthGeneric, pageHeightGeneric);
    fileName =    ['fig_FrequencyResponse_',folderName,fileNameMod];
    print('-dpdf', fullfile(outputPlotDir,[fileName,'.pdf']));    
    saveas(figH,fullfile(outputPlotDir,[fileName,'.fig']));
end
success=1;


