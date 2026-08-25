function figH = plotCalibrationData600A_Pres(...
                      figH,...
                      calibrationExperiment, ...
                      calibrationTrial, ...
                      projectFolders,...
                      flag_savePlot)


  numberOfHorizontalPlotColumnsGeneric  = 1;
  numberOfVerticalPlotRowsGeneric       = 2;

  plotWidth                 = ones(1,numberOfHorizontalPlotColumnsGeneric).*3.75;
  plotHeight                = ones(numberOfVerticalPlotRowsGeneric,1).*3;
  plotHorizMarginCm         = 3;
  plotVertMarginCm          = 1;
  baseFontSize              = 8;
  
  [subPlotPanelCal, pageWidthCal,pageHeightCal]= ...
    plotConfigGeneric(  numberOfHorizontalPlotColumnsGeneric,...
              numberOfVerticalPlotRowsGeneric,...
              plotWidth,...
              plotHeight,...
              plotHorizMarginCm,...
              plotVertMarginCm,...
              baseFontSize); 

filePath = fullfile(projectFolders.output600A_json,...
                    calibrationExperiment,...
                    calibrationTrial);
fileData = fileread(filePath{1});
jsonData = jsondecode(fileData);

hSet = {'H0','H1','H2'};
hColors=[0.67,0.67,0.67;...
         0.33,0.33,0.33;...
         0.0,0.0,0.0];
hNames = {'Raw',...
  sprintf('%s,(%1.2f ms)','$$\Delta t=1/\sqrt{k/m}$$',...
              jsonData.segment.delayModel.phaseDelayElasticRod*1e3),...
  sprintf('%s (%1.0f Hz)','Inv. LPF',...
              jsonData.segment.delayModel.daqFilterFrequencyHz)};
series = {'gain','phase'};
scaleSeries = [1; (180/pi)];

xyTickSeries(2) = struct('xTicks',[],'yTicks',[]); 
xyTickSeries(1).xTicks = [0,90];
xyTickSeries(1).yTicks = [0,1.5];

xyTickSeries(2).xTicks = [0,90];
xyTickSeries(2).yTicks = [-20,0,5];


xLabelSeries={'Frequency (Hz)','Frequency (Hz)'};
yLabelSeries={'Gain (mN/mm)','Phase ($$^\circ$$)'};

figure(figH);


  for iH=1:1:length(hSet)
    for iS = 1:1:length(series)

      subplot('Position',reshape(subPlotPanelCal(iS,1,:),1,4));
      idxBW = jsonData.segment.(hSet{iH}).idxBW;
      if(iH==1)
        switch iS
          case 1
            meanGain=mean(jsonData.segment.(hSet{iH}).(series{iS})(idxBW))...
                  .* scaleSeries(iS); 
            plot(jsonData.segment.(hSet{iH}).frequencyHz(idxBW),...
                 ones(size(jsonData.segment.(hSet{iH}).frequencyHz(idxBW))).*meanGain,...
                 '-','Color',[0,0,1],...
                 'HandleVisibility','off');
            hold on;
            
          case 2
            plot(jsonData.segment.(hSet{iH}).frequencyHz(idxBW),...
                 zeros(size(jsonData.segment.(hSet{iH}).frequencyHz(idxBW))),...
                 '-','Color',[0,0,1],...
                 'DisplayName','Spring');
            hold on;          
        end
      end

      plot(jsonData.segment.(hSet{iH}).frequencyHz(idxBW),...
           jsonData.segment.(hSet{iH}).(series{iS})(idxBW) .* scaleSeries(iS),...
           '-','Color',hColors(iH,:),...
           'DisplayName',hNames{iH});
      hold on;
      
      xlabel(xLabelSeries{iS});
      ylabel(yLabelSeries{iS});

      xLimSeries = [min(xyTickSeries(iS).xTicks),...
                    max(xyTickSeries(iS).xTicks)]...
                   +[-0.01,0.01];
      yLimSeries = [min(xyTickSeries(iS).yTicks),...
                    max(xyTickSeries(iS).yTicks)]...
                    +[-0.01,0.01];

      xticks(xyTickSeries(iS).xTicks);
      xlim(xLimSeries);
      yticks(xyTickSeries(iS).yTicks);
      ylim(yLimSeries);
      
      box off

      if(iS==length(series))
        legend;
      end
    end
  end

if(flag_savePlot==1)
  outputPlotDir = fullfile(projectFolders.output600A_plots,...
                           calibrationExperiment{1});
  
  figH=configPlotExporter(figH, ...
            pageWidthCal, pageHeightCal);
  fileName =  ['fig_',calibrationExperiment{1},'_pres'];
  print('-dpdf',fullfile(outputPlotDir,[fileName,'.pdf']));  
  saveas(figH,fullfile(outputPlotDir,[fileName,'.fig']));  
end