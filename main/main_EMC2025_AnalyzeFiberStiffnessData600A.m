clc;
close all;
clear all;


rootDir         = getRootProjectDirectory();
projectFolders  = getProjectFolders(rootDir);

addpath(projectFolders.aurora600A);
addpath(projectFolders.common);
addpath(projectFolders.postprocessing);
addpath(projectFolders.experiments);
addpath(fullfile(rootDir,'conference_emc2025'));


dataFolder600A = '20250821';
dataFolderFullPath600A = fullfile(projectFolders.data_600A,dataFolder600A);
trialNameKeywords = {'04_isometric_06Lo_2025',...
                     '05_isometric_10Lo_2025',...
                     '06_isometric_14Lo_2025'};
lossPerTrial     = 0.02;
idxTrialFmax     = 2;
trialFmaxScaling = [(1-lossPerTrial)^-1,...
                    (1-lossPerTrial)^0,...
                    (1-lossPerTrial)^1];

bandwidthHzSq    = [1.5,10.]; %Power is 0.29
bandwidthHzSine  = [1.5,10.]; %Power is also 0.29
bandwidthHzPlot  = [0,11];
trialColumns     = [1,2,3];
trialFmax        = 2;
trialBandwidth   = bandwidthHzSine;
purturbationType = 'sine'; %'sine' or 'ramp'

settingTimeShift = '';%calc or manual
% calc: calculates the propagation delay assuming the fiber is an elastic
%       cable
% manual: uses the value below
manualTimeShiftMS= 1.5;

flag_10kHzData = contains(trialNameKeywords{1},'10kHz');


%%
% Plot settings
%%
lineColors = getPaulTolColourSchemes('bright');

impedancePlots.gainNorm.ylim        = [0,43];
impedancePlots.phaseNorm.ylim       = [-20,20];
impedancePlots.coherenceSqNorm.ylim = [0,1];

impedancePlots.gain.ylim        = [0,43];
impedancePlots.phase.ylim       = [-20,20];
impedancePlots.coherenceSq.ylim = [0,1];

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
numberOfHorizontalPlotColumnsGeneric    = 3;
numberOfVerticalPlotRowsGeneric         = 3;
plotWidth                               = [8,8,8];
plotHeight                              = [8;8;8];
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



config = getImpedanceDataConfiguration600A( dataFolderFullPath600A, ...
                                            purturbationType,...
                                            trialNameKeywords,...
                                            trialColumns,...
                                            lineColors,...
                                            projectFolders);

%%
% Generate the plots
%%
   
figInput            = figure;
figPreprocessing    = figure;
figGainPhase        = figure;
figCoherenceSq      = figure;
figForceLengthStiffness = figure;

indexStephensonWilliams1982=3;


flag_addExpData=1;
figForceLengthStiffness = ...
    addEMC2025ForceLengthImpedancePlot600A(...
            figForceLengthStiffness,...
            subPlotPanelGeneric,...
            1,...
            1,...
            lineColors,...
            [],...
            [],...
            [],...
            [],...
            ratMuscleData(indexStephensonWilliams1982),...
            expDataSetFittingData(indexStephensonWilliams1982),...
            'ref-exp');


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


%Get fmax
flag_readHeader=1;
here=1;

flag_readHeader=1;
fmaxData = readAuroraData600A(config(trialFmax).fileName,flag_readHeader);
assert(strcmp(config(trialFmax).segmentLabels(6).name,...
                'Activation'),...
       'Error: order of the segmentLabels file has changed ');
assert(strcmp(config(trialFmax).segmentLabels(7).name,...
                'Length-Ramp-Preconditioning'),...
       'Error: order of the segmentLabels file has changed ');
timeFmaxInt = config(trialFmax).segmentLabels(7).timeInterval(1,:);

idxFmaxInt = getIndexInterval600A(fmaxData.Data.Time.Values,timeFmaxInt);
fmax = fmaxData.Data.Fin.Values(idxFmaxInt(1,1),1);

impedanceNameModification='';

fiberProperties.fmax=fmax;

for i=1:1:length(config)

    fprintf('%s\tprocessing...\n',config(i).fileName);
    flag_readHeader=1;
    trialData600A = readAuroraData600A(config(i).fileName,flag_readHeader);

    %%
    % Store basic properties of the fiber that are used throughout
    %%
    fiberProperties.fmax    = fmax*trialFmaxScaling(1,i);

    fiberProperties.lceOptMM= ...
        trialData600A.Setup_Parameters.Initial_Length.Value;

    %Sven measures the equivalent diameter at lopt
    fiberProperties.volumeAtLceOptMM = ...
        pi*(trialData600A.Setup_Parameters.Diameter.Value * 0.5)^2 ...
        *fiberProperties.lceOptMM;

    fiberProperties.areaAtLceOptMM= fiberProperties.volumeAtLceOptMM/fiberProperties.lceOptMM;

    fiberProperties.radiusAtLceOptMM= sqrt(fiberProperties.areaAtLceOptMM/pi);

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
            addEMC2025DataPlot600A(figInput, subPlotPanelGeneric, ...
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
            unitXImp = '$$\ell_o$$';

            assert(strcmp('Fin',yFieldImp),'Error: yFieldImp should be Fin');            
            scaleYImp = (1/fiberProperties.fmax);
            unitYImp = '$$f_o$$';

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

           
            figPreprocessing = ...
                addEMC2025ImpedanceInputDataPlot600A(figPreprocessing,...
                    subPlotPanelGeneric, ...
                    config(i).plots(j).row,...
                    config(i).col,...
                    config(i).plots(j), ...
                    timeVec, ...
                    xNormTimeDomain,...
                    yNormTimeDomain,...
                    impedancePlotProperties);            
            
            
  
        
            %%
            % Evaluate the gain and phaseNorm
            %%
          
            [gainNorm,phaseNorm,coherenceSqNorm] = ...
                evaluateGainPhaseCoherenceSq(...
                                        xNormTimeDomain,...
                                        yNormTimeDomain,...
                                        trialBandwidth(1,2),...
                                        sampleFrequency);
            
            [gain,phase,coherenceSq] = ...
                evaluateGainPhaseCoherenceSq(...
                                        xTimeDomain,...
                                        yTimeDomain,...
                                        trialBandwidth(1,2),...
                                        sampleFrequency);

            idxFreq     = find(frequencyHz < trialBandwidth(1,2));
            idxFreqBand = find(frequencyHz < trialBandwidth(1,2) ...
                             & frequencyHz > trialBandwidth(1,1));

            %%
            % Evaluate the active modulus of elasticity
            %%
            [meanFiberModulus,...
             meanGain,...
             meanStress]=...
                calcEMC2025FiberModulus600A(...
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
                                        trialBandwidth(1,2),...
                                        sampleFrequency);
            
        
            

            figure(figGainPhase);
            subPlotH = subplot('Position', ...
                        reshape(subPlotPanelGeneric(config(i).plots(j).row, ...
                                                    config(i).col,:),1,4));  

            gainColor           = config(i).plots(j).impedance.gainColor;
            phaseColor          = config(i).plots(j).impedance.phaseColor;
            coherenceSqColor    = config(i).plots(j).impedance.coherenceSqColor;

            yyaxis left;
            ax = gca;
            ax.YColor = gainColor;
            
            plot([1,1].*trialBandwidth(1,1),...
                 impedancePlots.gainNorm.ylim(),...
                 '--k');
            hold on; 
            plot([1,1].*trialBandwidth(1,2),...
                 impedancePlots.gainNorm.ylim(),...
                 '--k');
            hold on; 

            plot(frequencyHz(idxFreqBand,:),...
                 gainNorm(idxFreqBand,:),...
                 '-','Color',gainColor,...
                 'LineWidth',0.5);
            hold on;
            if(isempty(settingTimeShift)==0)
                plot(frequencyHz(idxFreqBand,:),...
                     gainNormShift(idxFreqBand,:),...
                     '-.','Color',gainColor,...
                     'LineWidth',0.5);
                hold on;
            end
            xlim(bandwidthHzPlot);
            
            box off;
            axis tight;
            ylim(impedancePlots.gainNorm.ylim);
            xlabel('Frequency (Hz)');
            ylabel('Gain ($$f_o/\ell_o$$)');

            yyaxis right;
            ax.YColor = phaseColor;
            plot(frequencyHz(idxFreqBand,:),...
                 phaseNorm(idxFreqBand,:).*(180/pi),...
                 '-','Color',phaseColor,...
                 'LineWidth',0.5);
            hold on;
            if(isempty(settingTimeShift)==0)
                plot(frequencyHz(idxFreqBand,:),...
                     phaseNormShift(idxFreqBand,:).*(180/pi),...
                     '.-','Color',phaseColor,...
                     'LineWidth',0.5);
            end
            
            hold on;
            box off;
            axis tight;
            xlim(bandwidthHzPlot);            
            ylim(impedancePlots.phaseNorm.ylim);            
            ylabel('Phase ($$^o$$)');

            title([config(i).plots(j).title]);


            figure(figCoherenceSq);
            subPlotH = subplot('Position', ...
                        reshape(subPlotPanelGeneric(config(i).plots(j).row, ...
                                                    config(i).col,:),1,4));   

            plot([1,1].*trialBandwidth(1,1),...
                 impedancePlots.coherenceSqNorm.ylim(),...
                 '--k');
            hold on; 
            plot([1,1].*trialBandwidth(1,2),...
                 impedancePlots.coherenceSqNorm.ylim(),...
                 '--k');
            hold on; 

            plot(frequencyHz(idxFreqBand,:),...
                 coherenceSqNorm(idxFreqBand,:),...
                 '-','Color',coherenceSqColor,...
                 'LineWidth',0.5);
            
            hold on;
            box off;
            axis tight;    
            xlim(bandwidthHzPlot);            
            ylim(impedancePlots.coherenceSqNorm.ylim);
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

%%
% Finish the force-length-impedance plot
%%
% dataX=expFpe.x;
% dataY=expFpe.y;
% 
% flag_addExpData=1;
% figForceLengthStiffness = ...
%     addEMC2025ForceLengthImpedancePlot600A(...
%             figForceLengthStiffness,...
%             subPlotPanelGeneric,...
%             1,...
%             1,...
%             lineColors,...
%             dataX,...
%             dataY,...
%             [],...
%             'Exp:$$f^{pe}$$',...
%             ratMuscleData(indexStephensonWilliams1982),...
%             expDataSetFittingData(indexStephensonWilliams1982),...
%             'fl-exp');
% 

dataL=materialProperties.active.l;
dataF=(materialProperties.active.f-materialProperties.passive.f);

dataSigma = (materialProperties.active.sigma...
             -materialProperties.passive.sigma);

dataYAnnotation ={''};
for i=1:1:length(dataL)
    if(i==1)
        dataYAnnotation = ...
            [{sprintf('%1.2fmN\n%1.2fkPa', ...
                dataF(i,1), dataSigma(i,1)*0.001)}];
    else
        dataYAnnotation = ...
            [dataYAnnotation,...
            {sprintf('%1.2fmN\n%1.2fkPa', ...
                dataF(i,1), dataSigma(i,1)*0.001)}];        
    end
end

dataLNorm = dataL ./ dataL(idxTrialFmax);
dataFNorm = dataF ./ dataF(idxTrialFmax);

flag_addExpData=1;
figForceLengthStiffness = ...
    addEMC2025ForceLengthImpedancePlot600A(...
            figForceLengthStiffness,...
            subPlotPanelGeneric,...
            1,...
            1,...
            lineColors,...
            dataLNorm,...
            dataFNorm,...
            dataYAnnotation,...
            'Exp:$$f^L$$',...
            ratMuscleData(indexStephensonWilliams1982),...
            expDataSetFittingData(indexStephensonWilliams1982),...
            'fl-exp');

% dataX=expKpe.x;
% dataY=(expKpe.y);
% dataYNorm=dataY ./ dataY(idxTrialFmax,1);
% dataYAnnotation ={''};
% for i=1:1:length(dataX)
%     if(i==1)
%         dataYAnnotation = [{sprintf('%1.2fMPa',(dataY(i,1)/1000000))}];
%     else
%         dataYAnnotation = [dataYAnnotation,...
%                            {sprintf('%1.2fMPa',(dataY(i,1)/1000000))}];        
%     end
% end

% flag_addExpData=1;
% figForceLengthStiffness = ...
%     addEMC2025ForceLengthImpedancePlot600A(...
%             figForceLengthStiffness,...
%             subPlotPanelGeneric,...
%             1,...
%             1,...
%             lineColors,...
%             dataX,...
%             dataYNorm,...
%             dataYAnnotation,...
%             'Exp:$$k^{PE}$$',...
%             ratMuscleData(indexStephensonWilliams1982),...
%             expDataSetFittingData(indexStephensonWilliams1982),...
%             'im-exp');

dataL=materialProperties.active.l;
dataK=(materialProperties.active.k-materialProperties.passive.k);
dataE=(materialProperties.active.E-materialProperties.passive.E);

dataLNorm = dataL ./ dataL(idxTrialFmax);
dataKNorm = dataK ./ dataK(idxTrialFmax);

dataYAnnotation ={''};
for i=1:1:length(dataL)
    if(i==1)
        dataYAnnotation = ...
            [{sprintf('%1.2fmN/mm\n%1.2fMPa',...
              dataK(i,1),dataE(i,1)*1e-6)}];
    else
        dataYAnnotation =...
            [dataYAnnotation,...
             {sprintf('%1.2fmN/mm\n%1.2fMPa', ...
             dataK(i,1),dataE(i,1)*1e-6)}];        
    end
end

flag_addExpData=1;
figForceLengthStiffness = ...
    addEMC2025ForceLengthImpedancePlot600A(...
            figForceLengthStiffness,...
            subPlotPanelGeneric,...
            1,...
            1,...
            lineColors,...
            dataLNorm,...
            dataKNorm,...
            dataYAnnotation,...
            'Exp:$$k^{L}$$',...
            ratMuscleData(indexStephensonWilliams1982),...
            expDataSetFittingData(indexStephensonWilliams1982),...
            'im-exp');



%%
%
%%
outputPlotDir = fullfile(projectFolders.output_plots,dataFolder600A);
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



    figPreprocessing=configPlotExporter(figPreprocessing,...
                        pageWidthGeneric, pageHeightGeneric);
    fileName =    ['fig_fiberImpedance_Preprocessing_',...
                    impedanceNameModification,nameMod10kHz,'.pdf'];
    print('-dpdf', fullfile(outputPlotDir,fileName));
    
    figGainPhase=configPlotExporter(figGainPhase, ...
                        pageWidthGeneric, pageHeightGeneric);
    fileName =    ['fig_fiberImpedance_PhaseGain_',...
                    impedanceNameModification,nameMod10kHz,'.pdf'];
    print('-dpdf', fullfile(outputPlotDir,fileName));
    
    figCoherenceSq=configPlotExporter(figCoherenceSq, ...
                        pageWidthGeneric, pageHeightGeneric);
    fileName =    ['fig_fiberImpedance_CoherenceSq_',...
                    impedanceNameModification,nameMod10kHz,'.pdf'];
    print('-dpdf', fullfile(outputPlotDir,fileName));

    

    figForceLengthStiffness=configPlotExporter(figForceLengthStiffness, ...
                        pageWidthGeneric, pageHeightGeneric);
    fileName =    ['fig_fiberImpedance_forceLengthImpedance_',...
                    impedanceNameModification,nameMod10kHz,'.pdf'];
    print('-dpdf', fullfile(outputPlotDir,fileName));
end


