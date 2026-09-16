function success = ...
  runPipelineAnalyzeIndividualLengthSineFiberData600A_json(...
    folderName, fileKeyWord,settings,...
    projectFolders)

success=0;
mm2m = 0.001;



flag_readHeader       = 1;


analysisKeywords={'Impedance-Individual-Length-Sine'};
analysisKeywordsList='';
for i=1:1:length(analysisKeywords)
  if(i>1)
    analysisKeywordsList = [analysisKeywordsList,', '];
  end  
  analysisKeywordsList=analysisKeywords{i};
end


%%
% folders
%%
dataFolder      = fullfile(projectFolders.data600A,folderName);
experimentStr   = fileread(fullfile(dataFolder,[folderName,'.json']));
experimentJson  = jsondecode(experimentStr);

%%
% Check that the type of experiment is valid for this processing script
%%

specimenType=lower(experimentJson.experiment.specimen);
idxS = strfind(specimenType,' ');
specimenType(idxS)='-';

setOfSpecimenTypes = {'spring','rat-edl'};
foundSpecimenType=0;
for i=1:1:length(setOfSpecimenTypes)
  if(strcmp(setOfSpecimenTypes{i},specimenType))
    foundSpecimenType=1;
  end
end

assert(foundSpecimenType,...
  ['Error: specimen name does not contain one of the following'...
      ' keywords: spring or rat-edl']);

trialType=lower(experimentJson.experiment.type);
idxS = strfind(trialType,' ');
trialType(idxS)='_';

setOfTrialTypes = {'impedance_calibration'};
foundTrialType=0;
for i=1:1:length(setOfTrialTypes)
  if(strcmp(setOfTrialTypes{i},trialType))
    foundTrialType=1;
  end
end
assert(foundTrialType,...
  ['Error: folder name does not contain one of the following'...
      ' keywords: impedance_calibration']);



%%
%
%%
fidLogFile = fopen(fullfile(dataFolder,...
  'log_runPipelineAnalyzeIndividualLengthSineFiberData600A_json.txt'),'w');

currentDateTime  = datestr(now, 'dd/mm/yy-HH:MM:SS');

fprintf(fidLogFile,'%s\n',currentDateTime);
fprintf('%s\n',currentDateTime);

indexSegmentLarb = 1;
%%
% Default setting
%%
setOfTrialsDefault = [1:1:length(experimentJson.measurements)];
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

   
setOfTrialsVerified=verifyDataIntegrityCompletnessOrder600A(...
                      dataFolder,...
                      experimentJson,...
                      analysisKeywords,...
                      fidLogFile,...
                      settings.checkFileOrder,...
                      settings.checkSha256Sum);


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
  %fprintf('\t%s\n',experimentJson.measurements{i});
  trialStr = fileread(fullfile(dataFolder,experimentJson.measurements{i}));
  if(exist('trialJson','var'))
    clear('trialJson');
  end
  trialJson = jsondecode(trialStr);


  %%
  % Count the number of segments to analyze
  %%
  setOfSegments=[];
  numSegmentsToPlot = 0;
  for j=1:1:length(trialJson.segments)

    if(isfield(trialJson.segments(j).meta_data,'keywords'))
      foundKeyword=0;
      for idxA = 1:1:length(trialJson.segments(j).meta_data.keywords)
        for idxB = 1:1:length(analysisKeywords)
          if(strcmp(trialJson.segments(j).meta_data.keywords{idxA},...
                    analysisKeywords{idxB}))
            foundKeyword=1;
          end
        end
      end
      if(foundKeyword==1)
        if(isempty(setOfSegments)==1)
          setOfSegments = j;
        else
          setOfSegments = [setOfSegments;j];
        end

      end
    end    

  end  

  if(isempty(setOfSegments))
    fprintf(fidLogFile,'%s\n', ...
        ['Error: could not find segment with ',analysisKeywordsList]);
  end

  assert(~isempty(setOfSegments),...
      ['Error: could not find segment with ',analysisKeywordsList]);
  if(length(setOfSegments) > totalNumberOfSegmentsToPlot)
    totalNumberOfSegmentsToPlot = length(setOfSegments);
  end  
end

fprintf('\t%i segments found\n',totalNumberOfSegmentsToPlot);
fprintf(fidLogFile,'\t%i segments found\n',totalNumberOfSegmentsToPlot);


if(settings.processData==1)
  
  setOfTrials = [];
  if(~isempty(setOfTrialsVerified))
    if(~isempty(fileKeyWord))      
      for idxSoT=1:1:length(setOfTrialsVerified)
        i = setOfTrialsVerified(idxSoT);
        disp(experimentJson.measurements{i});
        if(contains(experimentJson.measurements{i},fileKeyWord))
          setOfTrials = [setOfTrials; i];
        end
      end
    else
      setOfTrials = setOfTrialsVerified;
    end
  else
    if(~isempty(fileKeyWord))
      for i=1:1:length(setOfTrialsVerified)
        if(contains(experimentJson.measurements{i},fileKeyWord))
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
  numberOfHorizontalPlotColumnsGeneric  = length(setOfTrials);
  numberOfVerticalPlotRowsGeneric       = 7*totalNumberOfSegmentsToPlot;

  % 1. Time domain
  % 2. gain
  % 3. phase
  % 4. coherence  
  plotWidth                 = ones(1,numberOfHorizontalPlotColumnsGeneric).*6;
  plotHeight                = ones(numberOfVerticalPlotRowsGeneric,1).*6;
  plotHorizMarginCm         = 3;
  plotVertMarginCm          = 2;
  baseFontSize              = 12;
  
  [subPlotPanelSegment, pageWidthSegment, pageHeightSegment]= ...
    plotConfigGeneric(  numberOfHorizontalPlotColumnsGeneric,...
                        numberOfVerticalPlotRowsGeneric,...
                        plotWidth,...
                        plotHeight,...
                        plotHorizMarginCm,...
                        plotVertMarginCm,...
                        baseFontSize); 
  
  figSegments = figure;
  
  %
  % Plot the time series domain data
  %
  numberOfHorizontalPlotColumnsGeneric  = 1;
  numberOfVerticalPlotRowsGeneric       = length(setOfTrials);

  plotWidth           = ones(1,numberOfHorizontalPlotColumnsGeneric).*25;
  plotHeight          = ones(numberOfVerticalPlotRowsGeneric,1).*10;
  plotHorizMarginCm   = 3;
  plotVertMarginCm    = 2;
  baseFontSize        = 12;
  
  [subPlotPanelTimeSeries, pageWidthTimeSeries,pageHeightTimeSeries]= ...
    plotConfigGeneric(  numberOfHorizontalPlotColumnsGeneric,...
              numberOfVerticalPlotRowsGeneric,...
              plotWidth,...
              plotHeight,...
              plotHorizMarginCm,...
              plotVertMarginCm,...
              baseFontSize); 

  figTimeSeries = figure;

  %%
  % Extract the passive and active bias forces
  %%
  fprintf('%s\n','Extracting the passive and active bias forces');
  fprintf(fidLogFile,'%s\n','Extracting the passive and active bias forces');
  
  biasForce.passive.indexWindow=[];
  biasForce.passive.time  = nan;
  biasForce.passive.force = nan;
  biasForce.active.indexWindow = [];  
  biasForce.active.time   = nan;
  biasForce.active.force  = nan;
  biasForce.active.forceThreshold=nan;
  biasForce.trials=[];
  biasForce.trialIndex=[];  
  biasForce.isActive=[];

  foundBiasTrials=1;
  for indexKeyword =1:1:length(settings.biasForce.keywords)  
  
    found=0;
    for idxTrial=1:1:length(experimentJson.measurements)
      if(~isempty(settings.biasForce.keywords{indexKeyword}))
        if(contains(experimentJson.measurements{idxTrial},...
                    settings.biasForce.keywords{indexKeyword}))
          %assert(found==0,'Error: 1 bias force keyword has matched to two files');
          found=1;
          biasForce.trials = ...
            [biasForce.trials,experimentJson.measurements(idxTrial)];
          biasForce.isActive= ...
            [biasForce.isActive,settings.biasForce.isActive(indexKeyword)];
          biasForce.trialIndex = ...
            [biasForce.trialIndex,idxTrial];          
        end
      end
    end
    foundBiasTrials=foundBiasTrials & found;
  end
  if(foundBiasTrials==1)
    biasForce=extractBiasForce600A(biasForce,experimentJson,...
                                   dataFolder,settings,fidLogFile);
  else
    fprintf('%s\n','Warning: cound not find passive and active bias files');
    fprintf(fidLogFile,'%s\n','Warning: cound not find passive and active bias files');
  end

  %%
  % -Extract the individual sine curves from the length and force data.
  % -Fit curves to the data and extract out the frequency, amplitude, and
  %  start time of best fit.
  % -Evaluate the gain and phase shift and store this data in the
  %  analysis json file.
  %%

  
  fprintf('%s\n','Processing: gain, phase, coherence-sq + model fit');
  fprintf(fidLogFile,'%s\n','Processing: gain, phase, coherence-sq + model fit');
  
  for indexSetOfTrials = 1:1:length(setOfTrials)
  
    idxTrial = setOfTrials(indexSetOfTrials);
    isValid=1;    
    %%
    % Read in the meta data
    %%   
    fprintf('\t%s\n',experimentJson.measurements{idxTrial});
    fprintf(fidLogFile,'\t%s\n',experimentJson.measurements{idxTrial});
    
    trialStr = fileread(fullfile(dataFolder,experimentJson.measurements{idxTrial}));
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
  
    dataPath    = fullfile(dataFolder,filePaths{1});
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
    % Get the length-sine segments
    %%
    setOfSegments=[];
    for j=1:1:length(trialJson.segments)
      
      if(isfield(trialJson.segments(j).meta_data,'keywords'))
        foundKeyword=0;
        for idxA = 1:1:length(trialJson.segments(j).meta_data.keywords)
          for idxB=1:1:length(analysisKeywords)
            if(strcmp(trialJson.segments(j).meta_data.keywords{idxA},...
                      analysisKeywords{idxB}))
              foundKeyword=1;
            end
          end
        end
        if(foundKeyword==1)
          if(isempty(setOfSegments)==1)
            setOfSegments = j;
          else
            setOfSegments = [setOfSegments;j];
          end
        end
      end
    end  

    if(isempty(setOfSegments))
      isValid=0;    
      

      fprintf(fidLogFile,'%s\n', ...
          ['Warning: could not find segment with ',analysisKeywordsList, ...
           ' in ', experimentJson.measurements{idxTrial}]);
      fprintf('%s\n', ...
          ['Warning: could not find segment with ',analysisKeywordsList, ...
           ' in ', experimentJson.measurements{idxTrial}]);

    end  
  
    if(isValid==1)      

 
      %%
      % Plot the time series data
      %%
      figure(figTimeSeries);
  
      subplot('Position',...
        reshape(subPlotPanelTimeSeries(indexSetOfTrials,1,:),1,4));
  
      yyaxis left;
      plot(auroraData.Data.Time.Values,...
           auroraData.Data.Lin.Values,...
        '-','Color',lineColors.grey);
      hold on;
      xlabel(['Time (',auroraData.Data.Time.Unit,')']);
      ylabel(['Length (',auroraData.Data.Lin.Unit,')']);
  
      yyaxis right;
      plot(auroraData.Data.Time.Values,...
         auroraData.Data.Fin.Values,...
         '-','Color',[0,0,0]);
      hold on;
  
  
      ylabel(['Force (',auroraData.Data.Fin.Unit,')']);
      titleStr = strrep(experimentJson.measurements{idxTrial},'_','\_');        
      title(titleStr);
      axis tight;
      box off;
  
  
  
    
      %%
      % Process each of the segments
      %%
    
    
      for indexIntoSetOfSegments = 1:1:length(setOfSegments)
      
        idxSeg = setOfSegments(indexIntoSetOfSegments,1);
    
        %%
        %Extract the indicies to plot
        %%
        timeStartNoPad = trialJson.segments(idxSeg).time_ms(1);
        timeEndNoPad   = trialJson.segments(idxSeg).time_ms(2);
        dataIndexNoPad = find( auroraData.Data.Time.Values >= timeStartNoPad ...
                & auroraData.Data.Time.Values <= timeEndNoPad); 

        timeStart = trialJson.segments(idxSeg).time_ms(1)-settings.paddingTimeMS;
        timeEnd   = trialJson.segments(idxSeg).time_ms(2)+settings.paddingTimeMS;
        dataIndex = find( auroraData.Data.Time.Values >= timeStart ...
                & auroraData.Data.Time.Values <= timeEnd); 

        isSegmentValid=nan;
        if(length(dataIndex)>10)
          if(    length(auroraData.Data.Lin.Values(dataIndex,1))>10 ...
              && length(auroraData.Data.Fin.Values(dataIndex,1))>10)
            isSegmentValid=1;
          else
            isSegmentValid=0;
          end
        else
          isSegmentValid=0;
        end
        
        assert(isSegmentValid);

        %%
        %Get the meta data
        %%
        assert(isfield(trialJson.segments(idxSeg).meta_data,'keywords'));
        foundKeywords=0;
        for idxA=1:1:length(trialJson.segments(idxSeg).meta_data.keywords)
          for idxB=1:1:length(analysisKeywords)
            if(strcmp(trialJson.segments(idxSeg).meta_data.keywords{idxA},...
                      analysisKeywords{idxB}))
              foundKeywords=1;
            end
          end
        end
        assert(foundKeywords);        

        %
        % Check that all of the fields have been populated
        %
        assert(trialJson.segments(idxSeg).is_recorded==1);
        assert(isfield(trialJson.segments(idxSeg).meta_data,'bath'));
        assert(isfield(trialJson.segments(idxSeg).meta_data,'frequency_Hz'));
        assert(isfield(trialJson.segments(idxSeg).meta_data,'length_Lo'));
        assert(isfield(trialJson.segments(idxSeg).meta_data,'duration_ms'));
        
        
       
        %%
        % Fit a sinusoid to the length data to extract the amplitude
        % and fundamental frequency and process the data using the 
        % exact same approach as Kawai
        %%
        if(isSegmentValid==1)

    
          fittingSettings.time        = auroraData.Data.Time.Values(dataIndex);
          fittingSettings.length      = auroraData.Data.Lin.Values(dataIndex,1);
          fittingSettings.force       = auroraData.Data.Fin.Values(dataIndex,1);
          fittingSettings.timeScaling = 0.001; %Convert to seconds
          fittingSettings.duration_ms = ...
            trialJson.segments(idxSeg).meta_data.duration_ms;
          fittingSettings.number_of_elements = length(dataIndexNoPad);
          fittingSettings.Lo = experimentJson.experiment.length_mm;

          fittingSettings.var          = 'length';
          fittingSettings.scaling      = 1;
          fittingSettings.paramScaling = [];



          fittingSettings.paramScaling = [ ...
            trialJson.segments(idxSeg).time_ms(1),...
            mean(fittingSettings.length),...
            trialJson.segments(idxSeg).meta_data.frequency_Hz,...
            trialJson.segments(idxSeg).meta_data.length_Lo];  

          params = ones(size(fittingSettings.paramScaling));
          
          fittingSettings.var = 'length';                
              
          [errV,fittedSine] = ...
            calcErrorOfSinusoid600A(params,fittingSettings);
  
          errFcn = @(arg)calcErrorOfSinusoid600A(arg,fittingSettings);
          
          x = params;
          xDelta = 1;
          iterLsq=1;
          options = optimoptions('lsqnonlin','Display','off');

          if(indexIntoSetOfSegments==2 && indexSetOfTrials==2)
            here=1;
          end

          while(max(xDelta)>0.005 && iterLsq < 100)
            [x,resnorm,res,exitflag,output,lambda,jac] ...
              = lsqnonlin(errFcn,params,[],[],options);
            xDelta = abs(x-params);              
            params=x;
            iterLsq=iterLsq+1;
          end

          assert(max(xDelta) < 0.005, ...
            'Error: failed to fit the length sinusoid data');
          

          xUpd = x.*fittingSettings.paramScaling;


             

          [errV,fittedSine] = calcErrorOfSinusoid600A(x,fittingSettings);

          sinusoidFit = ...
            struct('time_ms',xUpd(1),...
                   'length_mm',xUpd(2),...
                   'frequency_Hz',xUpd(3),...
                   'amplitude_Lo',xUpd(4),...
                   'duration_ms',trialJson.segments(idxSeg).meta_data.duration_ms,...
                   'resnorm',resnorm,...
                   'exitflag',exitflag);   

          
          flag_checkFit=0;
          if(flag_checkFit==1)
            fig_checkFit=figure;
            plot( fittingSettings.time,...
                  fittingSettings.(fittingSettings.var),...
                  '-','Color',[1,1,1].*0.5);
            hold on;

            lineColor=[0,0,1];

            plot(fittedSine.x,fittedSine.y,'-','Color',lineColor);
            hold on;
            xlabel('Time (ms)');
            ylabel(fittingSettings.var);
            here=1;
            close(fig_checkFit);
          end
  
        end



        %%
        % Extract the segment and process it using Welch's method. This
        % will include the higher harmonics and give us a measure of
        % the linearity of the response.
        %%
        nHarmonics = 10; 
        nyquistFrequency = auroraData.Setup_Parameters.A_D_Sampling_Rate.Value*0.5;
        if((nHarmonics*sinusoidFit.frequency_Hz) > nyquistFrequency)
          nHarmonics = floor(nyquistFrequency/sinusoidFit.frequency_Hz);
        end

        if(isSegmentValid==1)

          timeStart = sinusoidFit.time_ms;
          timeEnd   = timeStart+sinusoidFit.duration_ms;

          dataIndex = find( auroraData.Data.Time.Values >= timeStart ...
                          & auroraData.Data.Time.Values <= timeEnd); 

          preTimeStart = timeStart-settings.paddingTimeMS;
          preTimeEnd   = timeStart;
          preDataIndex = [];
    
          if(preTimeEnd > 0)
            preDataIndex = find( auroraData.Data.Time.Values >= preTimeStart ...
                    & auroraData.Data.Time.Values <= preTimeEnd); 
          end

          x     = auroraData.Data.Lin.Values(dataIndex,1);
          xMean = mean(x);
          x     = x - xMean;      
  
          y = auroraData.Data.Fin.Values(dataIndex,1);
  
          yBias=0;        
          switch trialJson.segments(idxSeg).meta_data.bath
            case 'active'
              if(~isnan(biasForce.active.force))
                yBias = biasForce.active.force;
              end
            case 'passive'
              if(~isnan(biasForce.passive.force))
                yBias = biasForce.passive.force;
              end
          end
          y     = y-yBias;        
          yMean = mean(y);
          y     = y-yMean;
          
          
          segData.x      = x;
          segData.y      = y;
          segData.yBias  = yBias;
          segData.xMean  = xMean;
          segData.yMean  = yMean;     

          segData.xPrior = [];
          segData.yPrior = [];
          if(~isempty(preDataIndex))
            segData.timePrior=auroraData.Data.Time.Values(preDataIndex,1);
            segData.xPrior = auroraData.Data.Lin.Values(preDataIndex,1);
            segData.yPrior = auroraData.Data.Fin.Values(preDataIndex,1);            
          end
          
          segData.time            = auroraData.Data.Time.Values(dataIndex);
          segData.bandwidth_Hz    = [0,sinusoidFit.frequency_Hz*nHarmonics];
          segData.sampleFrequency = auroraData.Setup_Parameters.A_D_Sampling_Rate.Value;   

          if(max(segData.bandwidth_Hz)>0.5*segData.sampleFrequency)
            segData.bandwidth_Hz = [0,0.5*segData.sampleFrequency];
          end

   
          %%
          %
          % Evaluate the frequency response using Welch's method
          %
          %%
          segData.H = evaluateGainPhaseCoherenceSq(...
                          segData.time,...
                          segData.x,...
                          segData.y,...
                          segData.bandwidth_Hz,...
                          segData.sampleFrequency,...
                          settings.coherenceSquaredThreshold,...
                          settings.minAcceptableBandwidthFraction);


          %%
          %
          % Use Kawai's approach of just extracting out the Fourier
          % coefficients directly
          %
          %%          
          
          ms2s = 0.001;          
          segData.FS.frequency   = zeros(nHarmonics,1);
          segData.FS.frequencyHz = zeros(nHarmonics,1);          
          segData.FS.length.L    = zeros(nHarmonics,1);
          segData.FS.length.hk    = zeros(nHarmonics,1);
          segData.FS.length.I     = 0;          
          segData.FS.length.D     = 0;
          
          segData.FS.force.F     = zeros(nHarmonics,1);
          segData.FS.force.hk    = zeros(nHarmonics,1);
          segData.FS.force.I     = 0;          
          segData.FS.force.D     = 0;
          
          for idxN =1:1:nHarmonics
            segData.FS.frequency(idxN)   = ...
              sinusoidFit.frequency_Hz*(2*pi)*idxN;
            segData.FS.frequencyHz(idxN) = ...
              sinusoidFit.frequency_Hz*idxN;
            
            omega   = sinusoidFit.frequency_Hz*(2*pi)*idxN;
            Tcyc    = 1/sinusoidFit.frequency_Hz;
            A      = (1/(idxN*Tcyc));
            timeSeg = (segData.time-sinusoidFit.time_ms).*ms2s;

            %Real component
            sineWt = sin( omega.*(timeSeg) );
            l_dot_sineWt = sineWt.*segData.x;
            f_dot_sineWt = sineWt.*segData.y;

            fcnSineL = @(argX)interp1(timeSeg,l_dot_sineWt,argX,'linear');
            L_real = integral(fcnSineL,timeSeg(1),timeSeg(end)); 
            L_real = A.*L_real;

            fcnSineF = @(argX)interp1(timeSeg,f_dot_sineWt,argX,'linear');
            F_real = integral(fcnSineF,timeSeg(1),timeSeg(end)); 
            F_real = A.*F_real;

            %Complex component
            cosWt = cos( omega.*(timeSeg) );
            l_dot_cosWt = cosWt.*segData.x;
            f_dot_cosWt = cosWt.*segData.y;

            fcnCosL = @(argX)interp1(timeSeg,l_dot_cosWt,argX,'linear');
            L_imag = integral(fcnCosL,timeSeg(1),timeSeg(end)); 
            L_imag = A.*L_imag;

            fcnCosF = @(argX)interp1(timeSeg,f_dot_cosWt,argX,'linear');
            F_imag = integral(fcnCosF,timeSeg(1),timeSeg(end)); 
            F_imag = A.*F_imag;        
            
            %Save the complex coefficients
            segData.FS.length.L(idxN) = complex(L_real,L_imag);
            segData.FS.force.F(idxN)  = complex(F_real,F_imag);
            
            segData.FS.length.I= ...
              segData.FS.length.I + (L_real*L_real + L_imag*L_imag);

            segData.FS.force.I= ...
              segData.FS.force.I + (F_real*F_real + F_imag*F_imag);

          end

          for idxN=1:1:nHarmonics
            segData.FS.force.hk(idxN) = abs(segData.FS.force.F(idxN))...
                                        ./sqrt(segData.FS.force.I);
            segData.FS.length.hk(idxN) = abs(segData.FS.length.L(idxN))...
                                         ./sqrt(segData.FS.length.I);
          end

          h1F = segData.FS.force.hk(1);
          segData.FS.force.D = sqrt(1-h1F'*h1F);

          h1L = segData.FS.length.hk(1);
          segData.FS.length.D = sqrt(1-h1L'*h1L);


          segData.FS.H = (segData.FS.force.F .* segData.FS.length.L)...
                       ./(segData.FS.length.L .* segData.FS.length.L);

          segData.FS.gain = abs(segData.FS.H);
          segData.FS.phase= angle(segData.FS.H);
          segData.FS.storage = segData.FS.gain .* cos(segData.FS.phase);
          segData.FS.loss    = segData.FS.gain .* sin(segData.FS.phase);

          %%
          % Populate and save the json structure
          %%
          if(isSegmentValid==1)

            sinusoidJson.interval = [timeStart,timeEnd];
            sinusoidJson.index    = idxSeg;
            sinusoidJson.type     = trialJson.segments(idxSeg).type;
            sinusoidJson.time     = auroraData.Data.Time.Values(dataIndex,1);
            sinusoidJson.length   = auroraData.Data.Lin.Values(dataIndex,1);
            sinusoidJson.force    = auroraData.Data.Fin.Values(dataIndex,1);  
            sinusoidJson.lengthMean  = segData.xMean;
            sinusoidJson.forceMean   = segData.yMean;
            sinusoidJson.forceBias   = segData.yBias;      
            sinusoidJson.nominal.time    = segData.timePrior;
            sinusoidJson.nominal.length  = segData.xPrior;
            sinusoidJson.nominal.force   = segData.yPrior; 


            sinusoidJson.H  = segData.H;   
            %Remove the H field, since we cannot encode complex numbers 
            %into json
            sinusoidJson.H = rmfield(sinusoidJson.H,'H');

            sinusoidJson.H.units.gain = ...
              [auroraData.Data.Fin.Unit,'/',auroraData.Data.Lin.Unit];
            sinusoidJson.H.units.phase = 'radians';
            sinusoidJson.H.units.storage = ...
              [auroraData.Data.Fin.Unit,'/',auroraData.Data.Lin.Unit];
            sinusoidJson.H.units.loss = ...
              [auroraData.Data.Fin.Unit,'s/',auroraData.Data.Lin.Unit];
            sinusoidJson.H.units.coherenceSq = '';

            sinusoidJson.FS = segData.FS;
            sinusoidJson.FS = rmfield(sinusoidJson.FS,'H');
            sinusoidJson.FS.length = rmfield(sinusoidJson.FS.length,'L');
            sinusoidJson.FS.force  = rmfield(sinusoidJson.FS.force,'F');
            sinusoidJson.FS.lengthSinusoidFit = sinusoidFit;
            
            lengthSummary = ...
              getSummaryStatistics(auroraData.Data.Lin.Values(dataIndex,1));
            forceSummary = ...
              getSummaryStatistics(auroraData.Data.Fin.Values(dataIndex,1));
            temperatureSummary = ...
              getSummaryStatistics(auroraData.Data.Aux1_C.Values(dataIndex,1));

            sinusoidJson.summary.length       = lengthSummary;
            sinusoidJson.summary.force        = forceSummary;
            sinusoidJson.summary.temperature  = temperatureSummary;
            sinusoidJson.unit.length          = auroraData.Data.Lin.Unit;
            sinusoidJson.unit.force           = auroraData.Data.Fin.Unit;
            sinusoidJson.unit.temperature     = 'C';
            sinusoidJson.unit.time            = auroraData.Data.Time.Unit;
            sinusoidJson.channel.length       = 'Lin';
            sinusoidJson.channel.force        = 'Fin';
            sinusoidJson.channel.temperature  = 'Aux 1';


            setSinusoidJson(indexIntoSetOfSegments).sinusoid = sinusoidJson;
             

          end
          %%
          % Plot
          %%
          flag_plotH=0;
          if(flag_plotH==1)
            figPlotH=figure;
            subplot(2,2,1);
              yyaxis left;
                plot(segData.time,segData.x);
                hold on;
                box off;
                xlabel('Time (ms)');
                ylabel('Length (mm)');

              yyaxis right;
                plot(segData.time,segData.y);
                hold on;
                box off;
                ylabel('Force (mN)');
              title('Time Domain');
            subplot(2,2,2);
              yyaxis left;
                plot(segData.H.frequencyHz(segData.H.idxBW),...
                     segData.H.gain(segData.H.idxBW),...
                     'DisplayName','Welch');
                hold on;
                plot(segData.FS.frequencyHz(1),...
                     segData.FS.gain(1),...
                     'o','Color',[0,0,1],'MarkerFaceColor',[0,0,1],...
                     'DisplayName','FT');
                hold on;
                box off;
                xlabel('Frequency (Hz)');
                ylabel('Gain (mN/mm)');
              
              yyaxis right;
                plot(segData.H.frequencyHz(segData.H.idxBW),...
                     segData.H.phase(segData.H.idxBW).*(180/pi),...
                     'DisplayName','Welch');
                hold on;
                plot(segData.FS.frequencyHz(1),...
                     segData.FS.phase(1).*(180/pi),...
                     'd','Color',[1,0,0],'MarkerFaceColor',[1,0,0],...
                     'DisplayName','FT');
                hold on;
                box off;                
                ylabel('Phase (deg)');
                legend;
              title('Frequency Domain');
            subplot(2,2,3);
              plot(segData.FS.frequencyHz,...
                   segData.FS.force.hk,'-','Color',[0,0,0]);
              hold on;
              plot(segData.FS.frequencyHz,...
                   segData.FS.force.hk,'o','Color',[0,0,0],...
                   'MarkerFaceColor',[1,1,1]);
              hold on;
              box off;
              xlabel('Frequency (Hz)');
              ylabel('Relative Magnitude (mN/mN)');


            subplot(2,2,4);
              plot(segData.H.frequencyHz(segData.H.idxBW),...
                     segData.H.coherenceSq(segData.H.idxBW));
              box off;
              xlabel('Frequency (Hz)');
              ylabel('Coherence-Sq');
              hold on;
            title('Coherence');
                
            close(figPlotH);

          end

        end


  
        %%
        % Plot time-length-force  
        %%
        if(isSegmentValid==1)
          figure(figSegments);
        
          idxRow = (indexIntoSetOfSegments-1)*7 + 1;
          subplot('Position',reshape(...
            subPlotPanelSegment(idxRow,indexSetOfTrials,:),1,4));    
          yyaxis left;
       
          plot(auroraData.Data.Time.Values(dataIndex,1),...
             auroraData.Data.Lin.Values(dataIndex,1),...
             '-','Color',lineColors.grey);...
          hold on;
    
          box off;  
          xlabel(sprintf('Time (%s)',auroraData.Data.Time.Unit));
          ylabel(sprintf('Length (%s)',auroraData.Data.Lin.Unit));
        
          yyaxis right;
       
          plot(auroraData.Data.Time.Values(dataIndex,1),...
             auroraData.Data.Fin.Values(dataIndex,1),...
             '-','Color',[0,0,0]);...
          hold on;
    
          box off;  
          ylabel(sprintf('Force (%s)',auroraData.Data.Fin.Unit));
          
          titleStrA = trialJson.experiment.title;
          titleStrB = sprintf('%i Hz, %1.3f mm',...
            sinusoidFit.frequency_Hz,sinusoidFit.amplitude_Lo);    
          titleId   = sprintf('(%i,%i). ',idxRow,indexSetOfTrials);    
          title([titleId, titleStrA,':', titleStrB]);
        end
        %%
        % Plot the gain response 
        %%  
        if(isSegmentValid==1)
          idxRow = (indexIntoSetOfSegments-1)*7 + 2;
          subplot('Position',reshape(...
            subPlotPanelSegment(idxRow,indexSetOfTrials,:),1,4)); 
  
  
          plot(segData.H.frequencyHz(segData.H.idxBW),...
             segData.H.gain(segData.H.idxBW),...
            '-','Color',settings.colorData0);
          hold on;

            
          if(~isempty(segData.H.idxBWC2))
            for j=1:1:2
              plot([segData.H.bandwidthHzC2(j);...
                    segData.H.bandwidthHzC2(j)],...
                   [min(segData.H.gain(segData.H.idxBW)),...
                    max(segData.H.gain(segData.H.idxBW))],...
                   '-','Color',lineColors.grey);
              hold on;
            end
          end
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
        if(isSegmentValid==1)   
  
          idxRow = (indexIntoSetOfSegments-1)*7 + 3;
          subplot('Position',reshape(...
            subPlotPanelSegment(idxRow,indexSetOfTrials,:),1,4));
  
          plot(segData.H.frequencyHz(segData.H.idxBW),...
             segData.H.phase(segData.H.idxBW).*(180/pi),...
             '-','Color',settings.colorData0);
          hold on;
  
          if(~isempty(segData.H.idxBWC2))          
            for idxMdl=1:1:length(fittedModelSeries)
              if(~isempty(fittedModelSeries(idxMdl).model))
                plot(fittedModelSeries(idxMdl).model.response.frequencyHz,...
                   fittedModelSeries(idxMdl).model.response.phase.*(180/pi),...
                   fittedModelSeries(idxMdl).model.lineType,...
                   'Color', fittedModelSeries(idxMdl).model.color);
                hold on;  
              end
            end
            for j=1:1:2
              plot([segData.H.bandwidthHzC2(j);...
                  segData.H.bandwidthHzC2(j)],...
                 [0,45],...
                 '-','Color',lineColors.grey);
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
        % Plot storage vs frequency
        %%      
        if(isSegmentValid==1)   
  
          idxRow = (indexIntoSetOfSegments-1)*7 + 4;
          subplot('Position',reshape(...
            subPlotPanelSegment(idxRow,indexSetOfTrials,:),1,4));
  
          plot(segData.H.frequencyHz(segData.H.idxBW),...
             segData.H.storage(segData.H.idxBW),...
             '-','Color',settings.colorData0);
          hold on;

  
          if(~isempty(segData.H.idxBWC2))          
            for j=1:1:2
              plot([segData.H.bandwidthHzC2(j);...
                  segData.H.bandwidthHzC2(j)],...
                 [0,10],...
                 '-','Color',lineColors.grey);
              hold on;
            end
          end
                         
          box off;  
          xlabel('Frequency (Hz)');
          ylabel(sprintf('Storage (%s/%s)',...
              auroraData.Data.Fin.Unit,auroraData.Data.Lin.Unit));    
          titleId = sprintf('(%i,%i). ',idxRow,indexSetOfTrials);
          title(titleId);
        end
        
        %%
        % Plot storage vs frequency
        %%      
        if(isSegmentValid==1)   
  
          idxRow = (indexIntoSetOfSegments-1)*7 + 5;
          subplot('Position',reshape(...
            subPlotPanelSegment(idxRow,indexSetOfTrials,:),1,4));
  
          plot(segData.H.frequencyHz(segData.H.idxBW),...
             segData.H.loss(segData.H.idxBW),...
             '-','Color',settings.colorData0);
          hold on;

  
          if(~isempty(segData.H.idxBWC2))          
            for j=1:1:2
              plot([segData.H.bandwidthHzC2(j);...
                  segData.H.bandwidthHzC2(j)],...
                 [0,10],...
                 '-','Color',lineColors.grey);
              hold on;
            end
          end
          
          
          
          box off;  
          xlabel('Frequency (Hz)');
          ylabel(sprintf('Loss (%s/(%s/%s))',...
              auroraData.Data.Fin.Unit,auroraData.Data.Lin.Unit,'s'));    
          titleId = sprintf('(%i,%i). ',idxRow,indexSetOfTrials);
          title(titleId);
        end
        %%
        % Plot storage vs loss
        %%      
        if(isSegmentValid==1)   
  
          idxRow = (indexIntoSetOfSegments-1)*7 + 6;
          subplot('Position',reshape(...
            subPlotPanelSegment(idxRow,indexSetOfTrials,:),1,4));
  
          plot(segData.H.storage(segData.H.idxBW),...
             segData.H.loss(segData.H.idxBW),...
             '-','Color',settings.colorData0);
          hold on;
          
          
          box off;  
          xlabel('Storage (mm/mN)');
          ylabel('Loss (mN/(mm/s))');
      
          titleId = sprintf('(%i,%i). ',idxRow,indexSetOfTrials);
          title(titleId);
        end
  
        %%
        % Plot the coherence-sq response 
        %%      
        if(isSegmentValid==1)
          idxRow = (indexIntoSetOfSegments-1)*7 + 7;
          subplot('Position',reshape(...
            subPlotPanelSegment(idxRow,indexSetOfTrials,:),1,4));
  
          plot(segData.H.frequencyHz(segData.H.idxBW),...
            segData.H.coherenceSq(segData.H.idxBW),...
            '-','Color',settings.colorData0);
          hold on;

          if(~isempty(segData.H.idxBWC2))                    
            for j=1:1:2
              plot([segData.H.bandwidthHzC2(j);...
                  segData.H.bandwidthHzC2(j)],...
                 [min(segData.H.coherenceSq(segData.H.idxBW)),...
                  max(segData.H.coherenceSq(segData.H.idxBW))],...
                 '-','Color',lineColors.grey);
              hold on;
            end
          end
  
          box off;  
          xlabel('Frequency (Hz)');
          ylabel('Coherence-Sq');
      
          titleId = sprintf('(%i,%i). ',idxRow,indexSetOfTrials);
          title(titleId);  
        end
    
        
      end
    
      
      outputJsonDir = fullfile(projectFolders.output600A_json,folderName);
      if(~exist(outputJsonDir,'dir'))
        mkdir(outputJsonDir);
      end
      
      


      jsonFileName = [settings.prependToJsonFileName,...
                      experimentJson.measurements{idxTrial}];
      jsonFilePath=fullfile(outputJsonDir,jsonFileName);


      if(exist(jsonFilePath,'file'))
        mainStr   = fileread(jsonFilePath);
        mainJson  = jsondecode(mainStr); 

        mainJson.ImpedanceIndividualLengthSine = setSinusoidJson;
        mainJsonEncode  = jsonencode(mainJson);

        fidJson               = fopen(jsonFilePath,'w');
        fprintf(fidJson,mainJsonEncode);
        fclose(fidJson);       

      else
        mainJson.ImpedanceIndividualLengthSine = setSinusoidJson;
        mainJsonEncode  = jsonencode(mainJson);
        fidJson         = fopen(jsonFilePath,'w');
        fprintf(fidJson,mainJsonEncode);
        fclose(fidJson);  
      end      
    
      clear('setSinusoidJson');
      clear('sinusoidJson');
  
      pause(1);
  
    end
  end
  
  fclose(fidLogFile);
  
  outputPlotDir = fullfile(projectFolders.output600A_plots,folderName);
  if(~exist(outputPlotDir,'dir'))
    mkdir(outputPlotDir);
  end
  
  
  figSegments=configPlotExporter(figSegments, ...
            pageWidthSegment, pageHeightSegment);
  fileName =  ['fig_Sinusoid_FrequencyResponse_',folderName];
  print('-dpdf', fullfile(outputPlotDir,[fileName,'.pdf']));  
  saveas(figSegments,fullfile(outputPlotDir,[fileName,'.fig']));
  close(figSegments);


  figTimeSeries=configPlotExporter(figTimeSeries, ...
            pageWidthTimeSeries, pageHeightTimeSeries);
  fileName =  ['fig_Sinusoid_TimeSeries_',folderName];
  print('-dpdf', fullfile(outputPlotDir,[fileName,'.pdf']));  
  saveas(figTimeSeries,fullfile(outputPlotDir,[fileName,'.fig']));
  close(figTimeSeries);  
end
success=1;


