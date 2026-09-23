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

experimentsToProcess = {  '20260827_impedance_calibration_rigor_fixation_01'};  
  
ptColor=getPaulTolColourSchemes('vibrant');
colorSeries=[ptColor.grey;...
             ptColor.teal;...
             ptColor.red];

HType='H0';

for idxExp = 1:1:length(experimentsToProcess)

  dataFolder = fullfile(projectFolders.data600A,...
                           experimentsToProcess{idxExp});  
  jsonFolder = fullfile(projectFolders.output600A_json,...
                           experimentsToProcess{idxExp});
  plotFolder = fullfile(projectFolders.output600A_plots,...
                           experimentsToProcess{idxExp});
  
  expStr = fileread(fullfile(dataFolder,...
                     [experimentsToProcess{idxExp},'.json']));

  expJson = jsondecode(expStr);

  nMeasurements = length(expJson.measurements);

  
  %
  % Individual plots
  %   Time-series Length-Arb length
  %   Time-series Length-Arb force  
  %   Time-series sinusoid length
  %   Time-series sinusoid force  
  %   Gain
  %   Phase
  %   Storage
  %   Loss
  %   Loss vs storage
  figImpedanceLengthIndividual = figure;
  
  subplotIndex.lArb_length  =1;
  subplotIndex.lArb_force   =2;
  subplotIndex.sin_length   =3;
  subplotIndex.sin_force    =4;
  subplotIndex.gain         =5;
  subplotIndex.phase        =6;
  subplotIndex.storage      =7;
  subplotIndex.loss         =8;
  subplotIndex.loss_storage =9;

  numberOfHorizontalPlotColumnsGeneric    = nMeasurements;
  numberOfVerticalPlotRowsGeneric         = 9;
  
  plotWidth                               = ones(1,numberOfHorizontalPlotColumnsGeneric).*6;
  plotHeight                              = ones(numberOfVerticalPlotRowsGeneric,1).*6;
  plotHorizMarginCm                       = 2;
  plotVertMarginCm                        = 2.5;
  baseFontSize                            = 12;
  
  [subPlotPanelIndividual, ...
    pageWidthIndividual,   ...
    pageHeightIndividual ] = ...
    plotConfigGeneric(  numberOfHorizontalPlotColumnsGeneric,...
                        numberOfVerticalPlotRowsGeneric,...
                        plotWidth,...
                        plotHeight,...
                        plotHorizMarginCm,...
                        plotVertMarginCm,...
                        baseFontSize); 

  for idxM = 1:1:nMeasurements

    metaDataStr = fileread(fullfile(dataFolder,...
                        expJson.measurements{idxM}));

    metaDataJson = jsondecode(metaDataStr);

    hasLengthArbData=0;
    hasSinusoidData=0;
    for idxK = 1:1:length(metaDataJson.experiment.keywords)
      if(strcmp(metaDataJson.experiment.keywords{idxK},...
                            'Impedance-Individual-Length-Sine'))
        hasSinusoidData=1;
      end
      if(strcmp(metaDataJson.experiment.keywords{idxK},...
                            'Impedance-Length-Arb'))
        hasLengthArbData=1;      
      end
      
    end

    trialNameShort=expJson.measurements{idxM};
    for i=1:1:(length(trialNameShort)-3)
      c1=trialNameShort(1,i);
      c2=trialNameShort(1,i+1);
      c3=trialNameShort(1,i+2);
      c4=trialNameShort(1,i+3);
      
      n2=str2double(c2);
      n3=str2double(c3);

      if(strcmp(c1,'_') && strcmp(c4,'_') && ~isempty(n2) && ~isempty(n3))
        trialNameShort = strrep(trialNameShort(1,1:i+2),'_','\_');
        break;
      end
    end

    if(hasLengthArbData==1)
      larbFileName = ['analysis_ImpedanceLengthArb_',...
                           expJson.measurements{idxM}];
      larbStr=fileread(fullfile(jsonFolder,larbFileName));
      larbJson=jsondecode(larbStr);
    end

    if(hasSinusoidData==1)
      sinFileName = ['analysis_ImpedanceIndividualLengthSine_',...
                           expJson.measurements{idxM}];
      sinStr=fileread(fullfile(jsonFolder,sinFileName));
      sinJson=jsondecode(sinStr);
    end

    if(hasLengthArbData==1 && hasSinusoidData==1)
      unitsLengthArb=larbJson.segment(1).unit;
      unitsSinusoid=sinJson(1).sinusoid.unit;
      fieldsLengthArb=fields(unitsLengthArb);
      fieldsSinusoid=fields(unitsSinusoid);
      assert(length(fieldsSinusoid)==length(fieldsLengthArb),...
             'Error: Length-Arb and Sinusoid analysis use different units');
      for idxU=1:1:length(fieldsSinusoid)
        fieldLArb=fieldsLengthArb{idxU};
        fieldSin = fieldsSinusoid{idxU};
        assert(strcmp(unitsLengthArb.(fieldLArb),unitsSinusoid.(fieldSin)),...
          'Error: Length-Arb and Sinusoid analysis have different units');
      end
    end


    if(hasLengthArbData==1)
      

      for idxSeg=1:1:length(larbJson.segment)
        idxBWC2 = larbJson.segment(idxSeg).(HType).idxBWC2;
        bw      = larbJson.segment(idxSeg).(HType).bandwidthHz;
        bwC2    = larbJson.segment(idxSeg).(HType).bandwidthHzC2;

        %Time-series larb
        
        subplot('Position',reshape(subPlotPanelIndividual(...
                              subplotIndex.lArb_length,idxM,:),1,4));
        
          plot(larbJson.segment(idxSeg).time,...
               larbJson.segment(idxSeg).length,...
               '-','Color',colorSeries(1,:)); 
          box off;
          hold on        
          xlabel(sprintf('Time (%s)',larbJson.segment(idxSeg).unit.time));
          ylabel(sprintf('Length (%s)',larbJson.segment(idxSeg).unit.length));
          title({trialNameShort,'Length-Arb Time-series'});

        subplot('Position',reshape(subPlotPanelIndividual(...
                              subplotIndex.lArb_force,idxM,:),1,4));

          plot(larbJson.segment(idxSeg).time,...
               larbJson.segment(idxSeg).force,...
               '-','Color',colorSeries(1,:));        
          hold on
          box off;
          xlabel(sprintf('Time (%s)',larbJson.segment(idxSeg).unit.time));        
          ylabel(sprintf('Force (%s)',larbJson.segment(idxSeg).unit.force));
          title({trialNameShort,'Length-Arb Time-series'});
          
        %Gain
        axG=subplot('Position',reshape(subPlotPanelIndividual(...
                              subplotIndex.gain,idxM,:),1,4));
                
          plot(larbJson.segment(idxSeg).(HType).frequencyHz(idxBWC2),...
               larbJson.segment(idxSeg).(HType).gain(idxBWC2),...
               '-','Color',colorSeries(1,:));
          hold on
          box off;
          xlabel('Frequency (Hz)');
          axG.XScale='log';
          ylabel(sprintf('Gain (%s/%s)',... 
                 larbJson.segment(idxSeg).unit.force,...
                 larbJson.segment(idxSeg).unit.length));

        %Phase
        axP=subplot('Position',reshape(subPlotPanelIndividual(...
                              subplotIndex.phase,idxM,:),1,4));
        
          plot(larbJson.segment(idxSeg).(HType).frequencyHz(idxBWC2),...
               larbJson.segment(idxSeg).(HType).phase(idxBWC2).*(180/pi),...
               '-','Color',colorSeries(1,:));
          hold on
          box off;
          axP.XScale='log';
          xlabel('Frequency (Hz)');
          ylabel('Phase (deg)');
        
        %   Storage
        axS=subplot('Position',reshape(subPlotPanelIndividual(...
                              subplotIndex.storage,idxM,:),1,4));
                
          plot(larbJson.segment(idxSeg).(HType).frequencyHz(idxBWC2),...
               larbJson.segment(idxSeg).(HType).storage(idxBWC2),...
               '-','Color',colorSeries(1,:));
          hold on
          box off;
          axS.XScale='log';
          xlabel('Frequency (Hz)');
          ylabel(sprintf('Storage (%s/%s)',... 
                 larbJson.segment(idxSeg).unit.force,...
                 larbJson.segment(idxSeg).unit.length));

        %   Loss
        axL=subplot('Position',reshape(subPlotPanelIndividual(...
                              subplotIndex.loss,idxM,:),1,4));
        
          plot(larbJson.segment(idxSeg).(HType).frequencyHz(idxBWC2),...
               larbJson.segment(idxSeg).(HType).loss(idxBWC2),...
               '-','Color',colorSeries(1,:));
          hold on
          box off;
          axL.XScale='log';
          xlabel('Frequency (Hz)');
          ylabel(sprintf('Storage (%s/%s)',... 
                 larbJson.segment(idxSeg).unit.force,...
                 larbJson.segment(idxSeg).unit.length));
                  
        %   Loss vs storage        
        subplot('Position',reshape(subPlotPanelIndividual(...
                              subplotIndex.loss_storage,idxM,:),1,4));
        
          plot(larbJson.segment(idxSeg).(HType).storage(idxBWC2),...
               larbJson.segment(idxSeg).(HType).loss(idxBWC2),...
               '-','Color',colorSeries(1,:));
          hold on
          box off;
          xlabel(sprintf('Storage (%s/%s)',... 
                 larbJson.segment(idxSeg).unit.force,...
                 larbJson.segment(idxSeg).unit.length));
          ylabel(sprintf('Loss (%s/%s)',... 
                 larbJson.segment(idxSeg).unit.force,...
                 larbJson.segment(idxSeg).unit.length));
          
          here=1;
      end

    end
    
    if(hasSinusoidData==1)

      sinData.frequencyHz = zeros(length(sinJson),1);
      sinData.gain        = zeros(length(sinJson),1);
      sinData.phase       = zeros(length(sinJson),1);
      sinData.storage     = zeros(length(sinJson),1);
      sinData.loss        = zeros(length(sinJson),1);
      sinData.length_hk1  = zeros(length(sinJson),1);
      sinData.length_D    = zeros(length(sinJson),1);      
      sinData.force_hk1   = zeros(length(sinJson),1);
      sinData.force_D     = zeros(length(sinJson),1);
      
      for idxS=1:1:length(sinJson)
        sinData.frequencyHz(idxS) = sinJson(idxS).sinusoid.FS.frequencyHz(1);
        sinData.gain(idxS)        = sinJson(idxS).sinusoid.FS.gain(1);
        sinData.phase(idxS)       = sinJson(idxS).sinusoid.FS.phase(1);
        sinData.storage(idxS)     = sinJson(idxS).sinusoid.FS.storage(1);
        sinData.loss(idxS)        = sinJson(idxS).sinusoid.FS.loss(1);
        sinData.length_hk1        = sinJson(idxS).sinusoid.FS.length.hk(1);
        sinData.length_D          = sinJson(idxS).sinusoid.FS.length.D;      
        sinData.force_hk1         = sinJson(idxS).sinusoid.FS.force.hk(1);
        sinData.force_D           = sinJson(idxS).sinusoid.FS.force.D;
        
      end

      %Time-series      

      subplot('Position',reshape(subPlotPanelIndividual(...
                                 subplotIndex.sin_length,idxM,:),1,4));

        colorA=colorSeries(2,:);
        colorB=colorSeries(3,:);
        for idxS=1:1:length(sinJson)
          n=(idxS-1)/(length(sinJson)-1);
          colorLine= colorA.*n + colorB.*(1-n);

          duration=1/sinData.frequencyHz(idxS);
          if(strcmp(sinJson(idxS).sinusoid.unit.length,'mm'))
            duration =duration.*1000;
          end
          t0 = sinJson(idxS).sinusoid.time(1);
          t1 = t0+duration;
          idxT = find(   sinJson(idxS).sinusoid.time >= t0 ...
                      & sinJson(idxS).sinusoid.time <= t1);

          plot(sinJson(idxS).sinusoid.time(idxT)-t0,...
               sinJson(idxS).sinusoid.length(idxT),...
               '-','Color',colorLine);
          hold on;
        end
        box off;
        xlabel(sprintf('Time (%s)',larbJson.segment(idxSeg).unit.time));
        ylabel(sprintf('Length (%s)',larbJson.segment(idxSeg).unit.length));
        title({trialNameShort,'Sin Time-series'});

      subplot('Position',reshape(subPlotPanelIndividual(...
                                 subplotIndex.sin_force,idxM,:),1,4));
      
        colorA=colorSeries(2,:);
        colorB=colorSeries(3,:);
        for idxS=1:1:length(sinJson)
          n=(idxS-1)/(length(sinJson)-1);
          colorLine= colorA.*n + colorB.*(1-n);

          duration=1/sinData.frequencyHz(idxS);
          if(strcmp(sinJson(idxS).sinusoid.unit.length,'mm'))
            duration =duration.*1000;
          end
          
          t0 = sinJson(idxS).sinusoid.time(1);
          t1 = t0+duration;
          idxT = find(   sinJson(idxS).sinusoid.time >= t0 ...
                      & sinJson(idxS).sinusoid.time <= t1);
          
          plot(sinJson(idxS).sinusoid.time(idxT)-t0,...
               sinJson(idxS).sinusoid.force(idxT),...
               '-','Color',colorLine);
          hold on;
        end
        box off;
        xlabel(sprintf('Time (%s)',larbJson.segment(idxSeg).unit.time));        
        ylabel(sprintf('Force (%s)',larbJson.segment(idxSeg).unit.force));
        title({trialNameShort,'Sin Time-series'});      

      %Gain
      axG=subplot('Position',reshape(subPlotPanelIndividual(...
                                  subplotIndex.gain,idxM,:),1,4));
        
        plot(sinData.frequencyHz, ...
             sinData.gain,...
             '-','Color',colorSeries(2,:));
        hold on;
        plot(sinData.frequencyHz, ...
             sinData.gain,...
            '.','Color',colorSeries(2,:));
        hold on;
  
        box off;
        axG.XScale='log';
        xlabel('Frequency (Hz)');
        ylabel(sprintf('Gain (%s/%s)',... 
               larbJson.segment(idxSeg).unit.force,...
               larbJson.segment(idxSeg).unit.length));

      %Phase
      axP=subplot('Position',reshape(subPlotPanelIndividual(...
                                  subplotIndex.phase,idxM,:),1,4));
        
        plot(sinData.frequencyHz, ...
             sinData.phase.*(180/pi),...
             '-','Color',colorSeries(2,:));
        hold on;
        plot(sinData.frequencyHz, ...
             sinData.phase.*(180/pi),...
            '.','Color',colorSeries(2,:));
        hold on;
  
        axP.XScale='log';
        box off;
        xlabel('Frequency (Hz)');
        ylabel('Phase (deg)'); 

      %Storage
      axS=subplot('Position',reshape(subPlotPanelIndividual(...
                                 subplotIndex.storage,idxM,:),1,4));
        
        plot(sinData.frequencyHz, ...
             sinData.storage,...
             '-','Color',colorSeries(2,:));
        hold on;
        plot(sinData.frequencyHz, ...
             sinData.storage,...
            '.','Color',colorSeries(2,:));
        hold on;
  
        box off;
        axS.XScale='log';
        xlabel('Frequency (Hz)');
        ylabel(sprintf('Storage (%s/%s)',... 
               larbJson.segment(idxSeg).unit.force,...
               larbJson.segment(idxSeg).unit.length));        

      %Loss
      axL=subplot('Position',reshape(subPlotPanelIndividual(...
                                 subplotIndex.loss,idxM,:),1,4));
        
        plot(sinData.frequencyHz, ...
             sinData.loss,...
             '-','Color',colorSeries(2,:));
        hold on;
        plot(sinData.frequencyHz, ...
             sinData.loss,...
            '.','Color',colorSeries(2,:));
        hold on;
  
        box off;
        axL.XScale='log';
        xlabel('Frequency (Hz)');
        ylabel(sprintf('Loss (%s/%s)',... 
               larbJson.segment(idxSeg).unit.force,...
               larbJson.segment(idxSeg).unit.length)); 

      %Loss-vs-storage 
      subplot('Position',reshape(subPlotPanelIndividual(...
                                 subplotIndex.loss_storage,idxM,:),1,4));
        
        plot(sinData.storage, ...
             sinData.loss,...
             '-','Color',colorSeries(2,:));
        hold on;
        plot(sinData.storage, ...
             sinData.loss,...
            '.','Color',colorSeries(2,:));
        hold on;
        text(sinData.storage(1), ...
             sinData.loss(1),...
             sprintf('%1.3f Hz',sinData.frequencyHz(1)),...
             'HorizontalAlignment','left',...
             'VerticalAlignment','top',...
             'FontSize',6);
        hold on;
        text(sinData.storage(end), ...
             sinData.loss(end),...
             sprintf('%1.1f Hz',sinData.frequencyHz(end)),...
             'HorizontalAlignment','left',...
             'VerticalAlignment','bottom',...
             'FontSize',6);
        hold on;
        
        box off;
        xlabel(sprintf('Storage (%s/%s)',... 
               larbJson.segment(idxSeg).unit.force,...
               larbJson.segment(idxSeg).unit.length));         
        ylabel(sprintf('Loss (%s/%s)',... 
               larbJson.segment(idxSeg).unit.force,...
               larbJson.segment(idxSeg).unit.length)); 
        here=1;

    end

  end

  outputPlotDir = fullfile(projectFolders.output600A_plots,...
                           experimentsToProcess{idxExp});
  if(~exist(outputPlotDir))
      mkdir(outputPlotDir);
  end
  
  figImpedanceLengthIndividual=...
    configPlotExporter( figImpedanceLengthIndividual, ...
                        pageWidthIndividual, ...
                        pageHeightIndividual);
  
  fileName =    ['fig_Impedance_LengthArb_Sinusoid_'];
  
  print('-dpdf', fullfile(outputPlotDir,[fileName,'.pdf']));    
  
  saveas(figImpedanceLengthIndividual,...
         fullfile(outputPlotDir,[fileName,'.fig']));
  
  close(figImpedanceLengthIndividual);
end