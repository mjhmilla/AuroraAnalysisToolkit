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


flag_addFLKAnnotation=0;

folderName = '20250823_fli_B2';%'20250821';
 
dataConfig = getImpedanceExperimentConfiguration600A(...
                folderName,projectFolders);




settingTimeShift = '';%calc or manual
% calc: calculates the propagation delay assuming the fiber is an elastic
%       cable
% manual: uses the value below
manualTimeShiftMS= 4; %1.5

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
numberOfVerticalPlotRowsGeneric         = 5;
plotWidth                               = ones(1,numberOfHorizontalPlotColumnsGeneric).*5;
plotHeight                              = ones(numberOfVerticalPlotRowsGeneric,1).*5;
plotHorizMarginCm                       = 5;
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


numberOfHorizontalPlotColumnsGeneric    = 2;
numberOfVerticalPlotRowsGeneric         = 1;
plotWidth                               = ones(1,numberOfHorizontalPlotColumnsGeneric).*7;
plotHeight                              = ones(numberOfVerticalPlotRowsGeneric,1).*7;
plotHorizMarginCm                       = 5;
plotVertMarginCm                        = 3;
baseFontSize                            = 12;

[subPlotPanelFLK, pageWidthFLK,pageHeightFLK]= ...
  plotConfigGeneric(  numberOfHorizontalPlotColumnsGeneric,...
                      numberOfVerticalPlotRowsGeneric,...
                      plotWidth,...
                      plotHeight,...
                      plotHorizMarginCm,...
                      plotVertMarginCm,...
                      baseFontSize); 


config = getImpedanceDataConfiguration600A( dataConfig,...
                                            lineColors);


%%
% Get fmax
%%

flag_readHeader=1;
here=1;

flag_readHeader=1;
indexFmaxTrial = dataConfig.trialUsedForFmax;
fmaxData = readAuroraData600A(config(indexFmaxTrial).fileName,flag_readHeader);

fmax = 1;
fiberProperties.fmax                = 1;
fiberProperties.lceOptMM            = 1;
fiberProperties.volumeAtLceOptMM    = 1;
fiberProperties.areaAtLceOptMM      = 1;
fiberProperties.radiusAtLceOptMM    = sqrt(fiberProperties.areaAtLceOptMM/pi);
fiberProperties.stressAtLceOpt      = 1;
fiberProperties.normalize           = dataConfig.normalizeData;

if(dataConfig.normalizeData==1)
    idxFmax = 0;
    flagActivation=0;
    for k=1:1:length(config(indexFmaxTrial).segmentLabels)
        if(strcmp( config(indexFmaxTrial).segmentLabels(k).name, 'Activation' ))
            flagActivation=1;
        end
        if(contains( config(indexFmaxTrial).segmentLabels(k).name, ...
                     'Preconditioning' ) && flagActivation == 1 )
            idxFmax = k;
        end    
    end
    assert(idxFmax > 0 && flagActivation > 0, ...
        ['Error: protocol does not contain an activation',...
        ' and preconditioning command']);
    
    
    timeFmaxInt = config(indexFmaxTrial).segmentLabels(idxFmax).timeInterval(1,:);
    
    idxFmaxInt = getIndexInterval600A(fmaxData.Data.Time.Values,timeFmaxInt);
    fmax = fmaxData.Data.Fin.Values(idxFmaxInt(1,1),1);
    
    fiberProperties.fmax = fmax;
    
    fiberProperties.lceOptMM= ...
        fmaxData.Setup_Parameters.Initial_Length.Value;
    
    %Sven measures the equivalent diameter at lopt
    fiberProperties.volumeAtLceOptMM = ...
        pi*(fmaxData.Setup_Parameters.Diameter.Value * 0.5)^2 ...
        *fiberProperties.lceOptMM;
    
    fiberProperties.areaAtLceOptMM= fiberProperties.volumeAtLceOptMM/fiberProperties.lceOptMM;
    
    fiberProperties.radiusAtLceOptMM= sqrt(fiberProperties.areaAtLceOptMM/pi);
    
    fiberProperties.stressAtLceOpt = fmax*1e-3 / (fiberProperties.areaAtLceOptMM.*1e-6);
end

%%
% Generate the plots
%%
   
figInput            = figure;
%figPreprocessing    = figure;
figGain             = figure;
figPhase            = figure;
figCoherenceSq      = figure;
if(dataConfig.addStressStrainPlot==1)
    figForceLengthStiffness = figure;
end


indexStephensonWilliams1982=3;


if(dataConfig.addStressStrainPlot==1)
    figForceLengthStiffness = ...
        addForceLengthImpedancePlot600A(...
                figForceLengthStiffness,...
                subPlotPanelFLK,...
                1,...
                1,...
                lineColors,...
                [],...
                [],...
                [],...
                [],...
                ratMuscleData(indexStephensonWilliams1982),...
                expDataSetFittingData(indexStephensonWilliams1982),...
                'ref-exp',...
                fiberProperties);
    
    
    figForceLengthStiffness = ...
        addStressStrainModulusPlot600A(...
                figForceLengthStiffness,...
                subPlotPanelFLK,...
                1,...
                2,...
                lineColors,...
                [],...
                [],...
                [],...
                [],...
                fiberProperties,...
                ratMuscleData(indexStephensonWilliams1982),...
                expDataSetFittingData(indexStephensonWilliams1982),...
                'ss-exp');

end

materialProperties.active.l     = [];
materialProperties.active.sigma = [];
materialProperties.active.E     = [];
materialProperties.active.k     = [];
materialProperties.active.f     = [];

materialProperties.passive.l     = [];
materialProperties.passive.sigma = [];
materialProperties.passive.E     = [];
materialProperties.passive.k     = [];
materialProperties.passive.f     = [];




impedanceNameModification='';

fiberProperties.fmax=fmax;

for i=1:1:length(config)

    fprintf('%s\tprocessing...\n',config(i).fileName);
    flag_readHeader=1;
    trialData600A = readAuroraData600A(config(i).fileName,flag_readHeader);

    %%
    % Store basic properties of the fiber that are used throughout
    %%
    fiberProperties.fmax    = fmax*dataConfig.fmaxScaling(1,i);

    fiberProperties.lceMM   =[];
    fiberProperties.areaMM  =[];
    fiberProperties.radiusMM=[];


    assert(strcmp(trialData600A.Setup_Parameters.Initial_Length.Unit,'mm')==1,...
           'Error: initial fiber length is not in mm');
    assert(strcmp(trialData600A.Setup_Parameters.Fiber_Length.Unit,'mm')==1,...
           'Error: fiber length is not in mm');
    assert(strcmp(trialData600A.Setup_Parameters.Diameter.Unit,'mm')==1,...
           'Error: fiber diameter is not in mm');

    
    for j=1:1:length(config(i).plots)


        [figInput, plotProperties]= ...
            addImpedanceDataPlot600A(figInput, subPlotPanelGeneric, ...
                      config(i).plots(j).row,config(i).col,...
                      config(i).plots(j), trialData600A, fiberProperties);

        indexDataInterval=plotProperties.indexDataInterval;



        if(config(i).plots(j).impedance.analyze==1)

            %%
            % Extract the scale and labels of the input data
            %%
            idxA = indexDataInterval(1);
            idxB = indexDataInterval(2);

            xFieldImp = config(i).plots(j).impedance.xField;
            yFieldImp = config(i).plots(j).impedance.yField;
            timeFieldImp = 'Time';

            assert(strcmp('Lin',xFieldImp),'Error: xFieldImp should be Lin');
            scaleXImp = (1/fiberProperties.lceOptMM);
            unitXImp = trialData600A.Data.(xFieldImp).Unit;            
            if(dataConfig.normalizeData==1)
                unitXImp = '$$\ell_o$$';
            end
            assert(strcmp('Fin',yFieldImp),'Error: yFieldImp should be Fin');            
            scaleYImp = (1/fiberProperties.fmax);
            unitYImp = trialData600A.Data.(yFieldImp).Unit;            
            if(dataConfig.normalizeData==1)
                unitYImp = '$$f_o$$';
            end

            scaleTime = 1;
            unitTime = trialData600A.Data.(timeFieldImp).Unit;
            if(strcmp(trialData600A.Data.Time.Unit,'ms'))
                scaleTime = 0.001;
                unitTime = 's';
            end

            sampleFrequency  = ...
                trialData600A.Setup_Parameters.A_D_Sampling_Rate.Value;
            nyquistFrequency = sampleFrequency*0.5;

            impedancePlotProperties.scaleTime   = scaleTime;
            impedancePlotProperties.scaleXImp   = scaleXImp;
            impedancePlotProperties.unitXImp    = unitXImp;
            impedancePlotProperties.scaleYImp   = scaleYImp;
            impedancePlotProperties.unitYImp    = unitYImp;
            
            %%
            % Pick out the window of data to analyze it and give it a  zero
            % mean
            %%
            assert(strcmp(trialData600A.Data.(xFieldImp).Unit,'mm'),...
                'Error: expected mm as the unit of length');
            assert(strcmp(trialData600A.Data.(yFieldImp).Unit,'mN'),...
                'Error: expected mm as the unit of force');

            %%
            % Raw data
            %%
            xTimeDomain = ...
                trialData600A.Data.(xFieldImp).Values(idxA:idxB,1);
            yTimeDomain = ...
                trialData600A.Data.(yFieldImp).Values(idxA:idxB,1); 
            xTimeDomainMean = mean(xTimeDomain);
            yTimeDomainMean = mean(yTimeDomain);            
            xTimeDomain = xTimeDomain - xTimeDomainMean;
            yTimeDomain = yTimeDomain - yTimeDomainMean;
            
            %%
            % Update the fiber properties
            %%

            fiberProperties.lceMM   = xTimeDomainMean;
            fiberProperties.areaMM  =   fiberProperties.volumeAtLceOptMM...
                                        /fiberProperties.lceMM;
            fiberProperties.radiusMM=sqrt(fiberProperties.areaMM/pi);            


            %%
            % Normalized data
            %%
            xNormTimeDomain = xTimeDomain.*scaleXImp;
            yNormTimeDomain = yTimeDomain.*scaleYImp;
            xNormTimeDomainMean = xTimeDomainMean.*scaleXImp;
            yNormTimeDomainMean = yTimeDomainMean.*scaleYImp;
            
            samples     = length(xNormTimeDomain);
            timeVec     = [0:(1/(samples-1)):1]' .* (samples/sampleFrequency);
            frequencyHz = [0:(1/(samples)): (1-(1/samples)) ]' .* (sampleFrequency);
            frequencyRadians = frequencyHz.*(2*pi);

        
            %%
            % Evaluate the gain and phaseNorm
            %%
          
            [gainNorm,phaseNorm,coherenceSqNorm] = ...
                evaluateGainPhaseCoherenceSq(...
                                        xNormTimeDomain,...
                                        yNormTimeDomain,...
                                        dataConfig.bandwidthHz(i,2),...
                                        sampleFrequency);
            
            [gain,phase,coherenceSq] = ...
                evaluateGainPhaseCoherenceSq(...
                                        xTimeDomain,...
                                        yTimeDomain,...
                                        dataConfig.bandwidthHz(i,2),...
                                        sampleFrequency);

            dfreq = dataConfig.bandwidthHz(i,1);

            idxFreq     = find(frequencyHz < (dataConfig.bandwidthHz(i,2)+dfreq));
            idxFreqBand = find(frequencyHz < dataConfig.bandwidthHz(i,2) ...
                             & frequencyHz > dataConfig.bandwidthHz(i,1));

            %%
            % Evaluate the active modulus of elasticity
            %%
            [meanFiberModulus,...
             meanGain,...
             meanStress]=...
                calcFiberModulus600A(...
                                   xTimeDomain,...
                                   yTimeDomain,...                                   
                                   frequencyHz(idxFreqBand,1),...
                                   gain(idxFreqBand,1),...
                                   coherenceSq(idxFreqBand,1),...
                                   yTimeDomainMean(1,1),...
                                   fiberProperties);
            assert(strcmp(meanFiberModulus.Unit,'Pa'),...
                'Error: Active fiber modulus should be in Pa');


           

            if(config(i).plots(j).impedance.isActive==1)
                materialProperties.active.l =...
                    [materialProperties.active.l;...
                    xTimeDomainMean];

                materialProperties.active.sigma = ...
                    [materialProperties.active.sigma;...
                     meanStress.Value                     ];
                materialProperties.active.E     = ...
                    [materialProperties.active.E;...
                    meanFiberModulus.Value];
                materialProperties.active.k     = ...
                    [materialProperties.active.k;...
                    meanGain.Value];
                materialProperties.active.f     = ...
                    [materialProperties.active.f;...
                    yTimeDomainMean];
            else
                materialProperties.passive.l =...
                    [materialProperties.passive.l;...
                    xTimeDomainMean];                
                materialProperties.passive.sigma = ...
                    [materialProperties.passive.sigma;...
                     meanStress.Value                     ];
                materialProperties.passive.E     = ...
                    [materialProperties.passive.E;...
                    meanFiberModulus.Value];
                materialProperties.passive.k     = ...
                    [materialProperties.passive.k;...
                    meanGain.Value];  
                materialProperties.passive.f     = ...
                    [materialProperties.passive.f;...
                    yTimeDomainMean];
            end


            timeShiftInMs = 0;
            
            if(strcmp(settingTimeShift,'manual'))
                timeShiftInMs = manualTimeShiftMS;
            end            
            if(mean(coherenceSq(idxFreqBand,1)) > 0.9...
                    && strcmp(settingTimeShift,'calc'))
                %Evaluating the wave propagation velocity
                %https://en.wikipedia.org/wiki/Longitudinal_wave
                %- Ignoring the shear modulus as this is a uni-axial
                %  stretch
    
                %
                % Segal SS, White TP, Faulkner JA. Architecture, composition, 
                % and contractile properties of rat soleus muscle grafts. 
                % American Journal of Physiology-Cell Physiology. 1986 
                % Mar 1;250(3):C474-9.
                % https://doi.org/10.1152/ajpcell.1986.250.3.C474
                %
                rho = 1062; %kg /m^3
                waveVelocityMPS = sqrt(meanFiberModulus.Value/rho);                
                timeShiftInS   = fiberLengthM/waveVelocityMPS; 
                timeShiftInMs  = timeShiftInS*1000;
                here=1;
            end


            yNormTimeDomainShift = ...
                interp1(    trialData600A.Data.Time.Values(:,1)-timeShiftInMs,...
                            trialData600A.Data.(yFieldImp).Values(:,1),...
                            trialData600A.Data.Time.Values(:,1),...
                            'linear','extrap');

            yNormTimeDomainShift = yNormTimeDomainShift(idxA:idxB,1).*scaleYImp;
                       

          
            [gainNormShift,phaseNormShift,coherenceSqNormShift]...
                = evaluateGainPhaseCoherenceSq(...
                                        xNormTimeDomain,...
                                        yNormTimeDomainShift,...
                                        dataConfig.bandwidthHz(i,2),...
                                        sampleFrequency);
            
        
            

            figure(figGain);
            subPlotH = subplot('Position', ...
                        reshape(subPlotPanelGeneric(config(i).plots(j).row, ...
                                                    config(i).col,:),1,4));  

            gainColor           = config(i).plots(j).impedance.gainColor;
            phaseColor          = config(i).plots(j).impedance.phaseColor;
            coherenceSqColor    = config(i).plots(j).impedance.coherenceSqColor;

            %yyaxis left;
            %ax = gca;
            %ax.YColor = gainColor;

            plot([1,1].*dataConfig.bandwidthHz(i,1),...
                 max(gainNorm(idxFreq,:)),...
                 '--k');
            hold on; 
            plot([1,1].*dataConfig.bandwidthHz(i,2),...
                 max(gainNorm(idxFreq,:)),...
                 '--k');
            hold on; 


            plot(frequencyHz(idxFreq,:),...
                 gainNorm(idxFreq,:),...
                 '-','Color',gainColor,...
                 'LineWidth',0.5);
            hold on;
            if(isempty(settingTimeShift)==0)
                plot(frequencyHz(idxFreq,:),...
                     gainNormShift(idxFreq,:),...
                     '-.','Color',gainColor,...
                     'LineWidth',0.5);
                hold on;
            end
            
            box off;
            axis tight;
            xlim(dataConfig.bandwidthHzPlot(i,:));

            if(isempty(dataConfig.gainNormYLim)==0)
                ylim(dataConfig.gainNormYLim(i,:));
            end
            xlabel('Frequency (Hz)');
            ylabel(['Gain (',unitYImp,'/',unitXImp,')']);            
            
            title([config(i).plots(j).title]);
            
            figure(figPhase);
            subPlotH = subplot('Position', ...
                        reshape(subPlotPanelGeneric(config(i).plots(j).row, ...
                                                    config(i).col,:),1,4));  

            %yyaxis right;
            %ax.YColor = phaseColor;
            plot(dataConfig.bandwidthHzPlot(i,:),...
                zeros(size(dataConfig.bandwidthHzPlot(i,:))),'-',....
                 'Color',[1,1,1].*0.75,'HandleVisibility','off');
            hold on;

            plot(frequencyHz(idxFreq,:),...
                 phaseNorm(idxFreq,:).*(180/pi),...
                 '-','Color',phaseColor,...
                 'LineWidth',0.5);
            hold on;
            if(isempty(settingTimeShift)==0)
                plot(frequencyHz(idxFreq,:),...
                     phaseNormShift(idxFreq,:).*(180/pi),...
                     '.-','Color',phaseColor,...
                     'LineWidth',0.5);
            end
            plot([1,1].*dataConfig.bandwidthHz(i,1),...
                 max(phaseNormShift(idxFreq,:).*(180/pi)),...
                 '--k');
            hold on; 
            plot([1,1].*dataConfig.bandwidthHz(i,2),...
                 max(phaseNormShift(idxFreq,:).*(180/pi)),...
                 '--k');
            hold on; 
            

            hold on;
            box off;
            axis tight;
            xlim(dataConfig.bandwidthHzPlot(i,:));   
            if(isempty(dataConfig.phaseYLim(i,:))==0)
                ylim(dataConfig.phaseYLim(i,:));        
            end
            xlabel('Frequency (Hz)');            
            ylabel('Phase ($$^o$$)');

            title([config(i).plots(j).title]);


            figure(figCoherenceSq);
            subPlotH = subplot('Position', ...
                        reshape(subPlotPanelGeneric(config(i).plots(j).row, ...
                                                    config(i).col,:),1,4));   

            plot([1,1].*dataConfig.bandwidthHz(i,1),...
                 [0,1],...
                 '--k');
            hold on; 
            plot([1,1].*dataConfig.bandwidthHz(i,2),...
                 [0,1],...
                 '--k');
            hold on; 

            plot(frequencyHz(idxFreq,:),...
                 coherenceSqNorm(idxFreq,:),...
                 '-','Color',coherenceSqColor,...
                 'LineWidth',0.5);

            hold on;
            box off;
            axis tight;    
            xlim(dataConfig.bandwidthHzPlot(i,:));  

            ylim([0,1]);
            xlabel('Frequency (Hz)');
            ylabel('Coherence$$^2$$');    
            title([config(i).plots(j).title]);

            if(isempty(impedanceNameModification)==0)
                assert(strcmp(impedanceNameModification,...
                              config(i).plots(j).impedance.nameModifier),...
                             ['Error: the impedance.nameModifier is not',...
                              ' is not consistent']);
            end

            impedanceNameModification=...
                config(i).plots(j).impedance.nameModifier;
        end
    end
    here=1;

end

%%ds
% Finish the force-length-impedance plot
%%

if(dataConfig.isActive(i,1)==1)
    dataL= materialProperties.passive.l;
    dataF= materialProperties.passive.f;
    dataK= materialProperties.passive.k;
else
    dataL=materialProperties.active.l;
    dataF=(materialProperties.active.f-materialProperties.passive.f);
    dataK = materialProperties.active.k-materialProperties.passive.k;
end
dataStrain  = ones(size(dataL)).*nan;
dataSigma   = ones(size(dataF)).*nan;

dataLMax = 1;
dataFMax = 1;
dataKMax = 1;
idxTrialFmax = dataConfig.trialUsedForFmax;

if(isempty(idxTrialFmax)==0)
    dataStrain = (dataL./dataL(idxTrialFmax)) - 1;
    dataSigma = (materialProperties.active.sigma...
                 -materialProperties.passive.sigma);
    dataLMax = dataL(idxTrialFmax);
    dataFMax = dataF(idxTrialFmax);  
    dataKMax = dataK(idxTrialFmax);
end

dataYAnnotationFL ={''};
dataYAnnotationSS ={''};

if(flag_addFLKAnnotation==1)
    for i=1:1:length(dataL)
        if(i==1)
            dataYAnnotationFL = ...
                [{sprintf('%1.2fmN', ...
                    dataF(i,1))}];
    
            dataYAnnotationSS = ...
                [{sprintf('%1.2fkPa', ...
                    dataSigma(i,1)*0.001)}];
    
        else
            dataYAnnotationFL = ...
                [dataYAnnotationFL,...
                {sprintf('%1.2fmN', ...
                    dataF(i,1))}];   
            dataYAnnotationSS = ...
                [dataYAnnotationSS,...
                {sprintf('%1.2fkPa', ...
                    dataSigma(i,1)*0.001)}];           
        end
    end
else
    dataYAnnotationFL =[];
    dataYAnnotationSS =[];
end



dataLNorm = dataL ./ dataLMax;
dataFNorm = dataF ./ dataFMax;

if(dataConfig.addStressStrainPlot==1)
    figForceLengthStiffness = ...
        addForceLengthImpedancePlot600A(...
                figForceLengthStiffness,...
                subPlotPanelFLK,...
                1,...
                1,...
                lineColors,...
                dataLNorm,...
                dataFNorm,...
                dataYAnnotationFL,...
                'Exp:$$f^L$$',...
                [],...
                [],...
                'fl-exp');
    
    
    figForceLengthStiffness = ...
        addStressStrainModulusPlot600A(...
                figForceLengthStiffness,...
                subPlotPanelFLK,...
                1,...
                2,...
                lineColors,...
                dataStrain,...
                dataSigma,...
                dataYAnnotationSS,...
                'Exp:$$\sigma^\epsilon$$',...
                fiberProperties,...
                [],...
                [],...
                'ss-exp');

end

dataL=materialProperties.active.l;
dataK=(materialProperties.active.k-materialProperties.passive.k);
dataE=(materialProperties.active.E-materialProperties.passive.E);

dataLNorm = dataL ./ dataLMax;
dataKNorm = dataK ./ dataKMax;

dataYAnnotationFL ={''};
dataYAnnotationSS ={''};

if(flag_addFLKAnnotation==1)
    for i=1:1:length(dataL)
        if(i==1)
            dataYAnnotationFL = ...
                [{sprintf('%1.2fmN/mm',...
                  dataK(i,1))}];
            
            dataYAnnotationSS = ...
                [{sprintf('%1.2fMPa',...
                  dataE(i,1)*1e-6)}];        
        else
            dataYAnnotationFL =...
                [dataYAnnotationFL,...
                 {sprintf('%1.2fmN/mm', ...
                 dataK(i,1))}];       
    
            dataYAnnotationSS =...
                [dataYAnnotationSS,...
                 {sprintf('%1.2fMPa', ...
                  dataE(i,1)*1e-6)}];        
        end
    end
else
    dataYAnnotationFL =[];
    dataYAnnotationSS =[];
end

if(dataConfig.addStressStrainPlot==1)
    figForceLengthStiffness = ...
        addForceLengthImpedancePlot600A(...
                figForceLengthStiffness,...
                subPlotPanelFLK,...
                1,...
                1,...
                lineColors,...
                dataLNorm,...
                dataKNorm,...
                dataYAnnotationFL,...
                'Exp:$$k^{L}$$',...
                [],...
                [],...
                'im-exp');
    

    figForceLengthStiffness = ...
        addStressStrainModulusPlot600A(...
                figForceLengthStiffness,...
                subPlotPanelFLK,...
                1,...
                2,...
                lineColors,...
                dataStrain,...
                dataE,...
                dataYAnnotationSS,...
                'Exp:$$E$$',...
                fiberProperties,...            
                [],...
                [],...
                'em-exp');
end

%%
%
%%
outputPlotDir = fullfile(projectFolders.output_plots,dataConfig.folder);
if(~exist(outputPlotDir,'dir'))
    mkdir(outputPlotDir);
end

nameMod10kHz='';
if(flag_10kHzData==1)
    nameMod10kHz = '_10kHz';
end

figInput=configPlotExporter(figInput, pageWidthGeneric, pageHeightGeneric);

fileName =  ['fig_fiberImpedance_Input_',...
              impedanceNameModification,nameMod10kHz,'.pdf'];
print('-dpdf', fullfile(outputPlotDir,fileName));

if(isempty(impedanceNameModification)==0)



%     figPreprocessing=configPlotExporter(figPreprocessing,...
%                         pageWidthGeneric, pageHeightGeneric);
%     fileName =    ['fig_fiberImpedance_Preprocessing_',...
%                     impedanceNameModification,nameMod10kHz,'.pdf'];
%     print('-dpdf', fullfile(outputPlotDir,fileName));
    
    figGain=configPlotExporter(figGain, ...
                        pageWidthGeneric, pageHeightGeneric);
    fileName =    ['fig_fiberImpedance_Gain_',...
                    impedanceNameModification,nameMod10kHz,'.pdf'];
    print('-dpdf', fullfile(outputPlotDir,fileName));    
    
    figPhase=configPlotExporter(figPhase, ...
                        pageWidthGeneric, pageHeightGeneric);
    fileName =    ['fig_fiberImpedance_Phase_',...
                    impedanceNameModification,nameMod10kHz,'.pdf'];
    print('-dpdf', fullfile(outputPlotDir,fileName));    

    
    figCoherenceSq=configPlotExporter(figCoherenceSq, ...
                        pageWidthGeneric, pageHeightGeneric);
    fileName =    ['fig_fiberImpedance_CoherenceSq_',...
                    impedanceNameModification,nameMod10kHz,'.pdf'];
    print('-dpdf', fullfile(outputPlotDir,fileName));

    
    if(dataConfig.addStressStrainPlot==1)
        figForceLengthStiffness=configPlotExporter(figForceLengthStiffness, ...
                            pageWidthFLK, pageHeightFLK);
        fileName =    ['fig_fiberImpedance_forceLengthImpedance_',...
                        impedanceNameModification,nameMod10kHz,'.pdf'];
        print('-dpdf', fullfile(outputPlotDir,fileName));
    end
end


