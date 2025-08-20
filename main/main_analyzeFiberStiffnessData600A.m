clc;
close all;
clear all;


rootDir         = getRootProjectDirectory();
projectFolders  = getProjectFolders(rootDir);

addpath(projectFolders.aurora600A);
addpath(projectFolders.common);
addpath(projectFolders.postprocessing);


dataFolder600A = '20250818-209';
dataFolderFullPath600A = fullfile(projectFolders.data_600A,dataFolder600A);
trialNameKeywords = {'04_isometric_06Lo_2025',...
                     '05_isometric_10Lo_2025',...
                     '06_isometric_14Lo_2025'};
bandwidthHzSq   = [1,10.]; %Power is 0.29
bandwidthHzSine = [1,10.]; %Power is also 0.29
trialColumns = [1,2,3];
trialFmax    = 2;
trialBandwidth= bandwidthHzSine;
purturbationType = 'sine'; %'sine' or 'ramp'

impedancePlots.gain.ylim        = [0,43];
impedancePlots.phase.ylim       = [-20,20];
impedancePlots.coherenceSq.ylim = [0,1];

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
                                            projectFolders);

%%
% Generate the plots
%%
   
figInput        = figure;
figPreprocessing=figure;
figGainPhase    = figure;
figCoherenceSq  = figure;

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

for i=1:1:length(config)

    fprintf('%s\tprocessing...\n',config(i).fileName);
    flag_readHeader=1;
    datData = readAuroraData600A(config(i).fileName,flag_readHeader);



    for j=1:1:length(config(i).plots)
        figure(figInput);
        %length
        subPlotH = subplot('Position', ...
                    reshape(subPlotPanelGeneric(config(i).plots(j).row, ...
                                               config(i).col,:),1,4)); 
        xField = config(i).plots(j).xField;
        yField = config(i).plots(j).yField;

        scaleY = 1;
        unitY = datData.Data.(yField).Unit;
        if(strcmp('Lin',yField))
            lo = datData.Setup_Parameters.Initial_Length.Value;
            loUnit = datData.Setup_Parameters.Initial_Length.Unit;
            assert(strcmp(loUnit,unitY),...
                'Error: initial length and Lin units do not match');
            scaleY = (1/lo);
            unitY = '$$\ell_o$$';
        end
        if(strcmp('Fin',yField))
            scaleY = (1/fmax);
            unitY = '$$f_o$$';
        end        


        scaleX = 1;
        unitX = datData.Data.(xField).Unit;
        if(strcmp(datData.Data.Time.Unit,'ms'))
            scaleX = 0.001;
            unitX = 's';
        end
        
        idxA = 1;
        idxB = length(datData.Data.(xField).Values);
        indexDataInterval=[idxA,idxB];

        if(isempty(config(i).plots(j).timeInterval)==0)
            indexDataInterval = ...
                getIndexInterval600A(datData.Data.Time.Values,...
                                config(i).plots(j).timeInterval);
            idxA = indexDataInterval(1);
            idxB = indexDataInterval(2);
        end
        
        if(strcmp(config(i).plots(j).yyLeftRight,'yyaxis left'))
            yyaxis left;
            ax = gca;
            if(isempty(config(i).plots(j).yyLeftRightAxisColor)==0)
                ax.YColor = config(i).plots(j).yyLeftRightAxisColor(1,:);
            end
        end
        if(strcmp(config(i).plots(j).yyLeftRight,'yyaxis right'))
            yyaxis right;
            if(isempty(config(i).plots(j).yyLeftRightAxisColor)==0)
                ax.YColor = config(i).plots(j).yyLeftRightAxisColor(2,:);
            end         
        end


        plot(datData.Data.(xField).Values(idxA:idxB,1).*scaleX,...
             datData.Data.(yField).Values(idxA:idxB,1).*scaleY,...
             '-','Color',config(i).plots(j).lineColor,...
             'LineWidth',config(i).plots(j).lineWidth);
        hold on;
        
        if(isempty(config(i).plots(j).boxTimes)==0)
            for k=1:1:size(config(i).plots(j).boxTimes,1)
                indexBoxInterval = getIndexInterval600A(...
                                    datData.Data.Time.Values,...
                                    config(i).plots(j).boxTimes(k,:));
                idxA = indexBoxInterval(1,1);
                idxB = indexBoxInterval(1,2);
                boxXMin = min(datData.Data.(xField).Values(idxA,1).*scaleX);
                boxXMax = max(datData.Data.(xField).Values(idxB,1).*scaleX);
                
                boxYMin = min(datData.Data.(yField).Values(idxA:idxB,1).*scaleY);
                boxYMax = max(datData.Data.(yField).Values(idxA:idxB,1).*scaleY);

                boxYDelta = (boxYMax-boxYMin)*0.05;
                boxYMin = boxYMin-boxYDelta;
                boxYMax = boxYMax+boxYDelta;

                plot([boxXMin,boxXMax,boxXMax,boxXMin,boxXMin],...
                     [boxYMin,boxYMin,boxYMax,boxYMax,boxYMin],...
                     '-','Color',config(i).plots(j).boxColors(k,:));
                hold on;
                text((boxXMax+boxXMin)*0.5,boxYMax,num2str(k),...
                    'FontSize',8,...
                    'VerticalAlignment','bottom',...
                    'HorizontalAlignment','center');
                hold on;
            end
        end


        box off;
    
        axis tight;


        xlabel([config(i).plots(j).xLabel, '(',unitX,')']);
        ylabel([config(i).plots(j).yLabel, '(',unitY,')']);
        title(config(i).plots(j).title);
    
        if(config(i).plots(j).impedance.analyze==1)

            idxA = indexDataInterval(1);
            idxB = indexDataInterval(2);

            xFieldImp = config(i).plots(j).impedance.xField;
            yFieldImp = config(i).plots(j).impedance.yField;
            timeFieldImp = 'Time';

            assert(strcmp('Lin',xFieldImp),'Error: xFieldImp should be Lin');
            lo = datData.Setup_Parameters.Initial_Length.Value;
            loUnit = datData.Setup_Parameters.Initial_Length.Unit;
            assert(strcmp(loUnit,datData.Data.Lin.Unit),...
                'Error: initial length and Lin units do not match');
            scaleXImp = (1/lo);
            unitXImp = '$$\ell_o$$';

            assert(strcmp('Fin',yFieldImp),'Error: yFieldImp should be Fin');            
            scaleYImp = (1/fmax);
            unitYImp = '$$f_o$$';

            scaleTime = 1;
            unitTime = datData.Data.(timeFieldImp).Unit;
            if(strcmp(datData.Data.Time.Unit,'ms'))
                scaleTime = 0.001;
                unitTime = 's';
            end

            sampleFrequency  = datData.Setup_Parameters.A_D_Sampling_Rate.Value;
            nyquistFrequency = sampleFrequency*0.5;



            xTimeDomain = datData.Data.(xFieldImp).Values(idxA:idxB,1).*scaleXImp;
            yTimeDomain = datData.Data.(yFieldImp).Values(idxA:idxB,1).*scaleYImp;

            xTimeDomain = xTimeDomain - mean(xTimeDomain);
            yTimeDomain = yTimeDomain - mean(yTimeDomain);


            samples = length(xTimeDomain);
            timeVec = [0:(1/(samples-1)):1]' .* (samples/sampleFrequency);
            frequencyHz = [0:(1/(samples)): (1-(1/samples)) ]' .* (sampleFrequency);
            frequencyRadians = frequencyHz.*(2*pi);

            
            figure(figPreprocessing);
            subPlotH = subplot('Position', ...
                        reshape(subPlotPanelGeneric(config(i).plots(j).row, ...
                                                   config(i).col,:),1,4));             
  
            yyaxis left;
            ax = gca;
            ax.YColor = config(i).plots(j).yyLeftRightAxisColor(1,:);            
            plot(timeVec,...
                 xTimeDomain,...
                 '-','Color',config(i).plots(j).impedance.xColor,...
                 'LineWidth',config(i).plots(j).lineWidth);
            hold on;   
            xlabel('Time (s)');
            ylabel(['Length ',unitXImp]);
            axis tight;

            yyaxis right;
            ax = gca;
            ax.YColor = config(i).plots(j).yyLeftRightAxisColor(2,:);            
            plot(timeVec,...
                 yTimeDomain,...
                 '-','Color',config(i).plots(j).impedance.yColor,...
                 'LineWidth',config(i).plots(j).lineWidth);
            hold on;   
            xlabel('Time (s)');
            ylabel(['Force ',unitYImp]);
            box off;
            axis tight;
           
            title([config(i).plots(j).title]);
        



           
            [gain,phase,coherenceSq] = evaluateGainPhaseCoherenceSq(...
                                        xTimeDomain,...
                                        yTimeDomain,...
                                        trialBandwidth(1,2),...
                                        sampleFrequency);
            

            idxFreq = find(frequencyHz < trialBandwidth(1,2));

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
                 impedancePlots.gain.ylim(),...
                 '--k');
            hold on; 
            plot([1,1].*trialBandwidth(1,2),...
                 impedancePlots.gain.ylim(),...
                 '--k');
            hold on; 

            plot(frequencyHz(idxFreq,:),...
                 gain(idxFreq,:),...
                 '-','Color',gainColor,...
                 'LineWidth',0.5);
            hold on;
            
            box off;
            axis tight;
            ylim(impedancePlots.gain.ylim);
            xlabel('Frequency (Hz)');
            ylabel('Gain ($$f_o/\ell_o$$)');

            yyaxis right;
            ax.YColor = phaseColor;
            plot(frequencyHz(idxFreq,:),...
                 phase(idxFreq,:).*(180/pi),...
                 '-','Color',phaseColor,...
                 'LineWidth',0.5);
            hold on;
            box off;
            axis tight;
            ylim(impedancePlots.phase.ylim);            
            ylabel('Phase ($$^o$$)');

            title([config(i).plots(j).title]);


            figure(figCoherenceSq);
            subPlotH = subplot('Position', ...
                        reshape(subPlotPanelGeneric(config(i).plots(j).row, ...
                                                    config(i).col,:),1,4));   

            plot([1,1].*trialBandwidth(1,1),...
                 impedancePlots.coherenceSq.ylim(),...
                 '--k');
            hold on; 
            plot([1,1].*trialBandwidth(1,2),...
                 impedancePlots.coherenceSq.ylim(),...
                 '--k');
            hold on; 

            plot(frequencyHz(idxFreq,:),...
                 coherenceSq(idxFreq,:),...
                 '-','Color',coherenceSqColor,...
                 'LineWidth',0.5);
            hold on;
            box off;
            axis tight;       
            ylim(impedancePlots.coherenceSq.ylim);
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
%
%%
outputPlotDir = fullfile(projectFolders.output_plots,dataFolder600A);
if(~exist(outputPlotDir,'dir'))
    mkdir(outputPlotDir);
end

figInput=configPlotExporter(figInput, pageWidthGeneric, pageHeightGeneric);

fileName =  ['fig_fiberImpedance_Input_',...
              impedanceNameModification,'.pdf'];
print('-dpdf', fullfile(outputPlotDir,fileName));

if(isempty(impedanceNameModification)==0)



    figPreprocessing=configPlotExporter(figPreprocessing,...
                        pageWidthGeneric, pageHeightGeneric);
    fileName =    ['fig_fiberImpedance_Preprocessing_',...
                    impedanceNameModification,'.pdf'];
    print('-dpdf', fullfile(outputPlotDir,fileName));
    
    figGainPhase=configPlotExporter(figGainPhase, ...
                        pageWidthGeneric, pageHeightGeneric);
    fileName =    ['fig_fiberImpedance_PhaseGain_',...
                    impedanceNameModification,'.pdf'];
    print('-dpdf', fullfile(outputPlotDir,fileName));
    
    figCoherenceSq=configPlotExporter(figCoherenceSq, ...
                        pageWidthGeneric, pageHeightGeneric);
    fileName =    ['fig_fiberImpedance_CoherenceSq_',...
                    impedanceNameModification,'.pdf'];
    print('-dpdf', fullfile(outputPlotDir,fileName));

end


