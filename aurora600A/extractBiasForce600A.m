function biasForce = extractBiasForce600A(biasForce,experimentJson,...
                                     dataFolder,settings,fidLogFile)
s2ms=1000;

for idxBiasTrial = 1:1:length(biasForce.trials)
      %%
      % Read in the meta data
      %%   
      idxTrial = biasForce.trialIndex(idxBiasTrial);
      flag_isActive = biasForce.isActive(idxBiasTrial);

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
    
      dataPath = fullfile(dataFolder,filePaths{1});
      protocolPath= fullfile(dataFolder,filePaths{2});
        
      flag_readHeader=1;
      auroraData = readAuroraData600A(dataPath,flag_readHeader);
      
      adFreqHz   = auroraData.Setup_Parameters.A_D_Sampling_Rate.Value;
      lpfFreqHz  = settings.biasForce.lowPassFilterFrequency;
      [b,a]      = butter(2,(lpfFreqHz/(0.5*adFreqHz)),'low');
      finFilt    = filtfilt(b,a,auroraData.Data.Fin.Values);
      finEnv  = filtfilt(b,a,abs(auroraData.Data.Fin.Values-finFilt));
      dfinEnv = calcCentralDifferenceDataSeries(...
                  auroraData.Data.Time.Values,finEnv);
      dfinEnv = abs(dfinEnv);
      d2finEnv = calcCentralDifferenceDataSeries(...
                  dfinEnv,finEnv);
      d2finEnv = abs(d2finEnv);

      if(flag_isActive==0)
        npts = round(settings.biasForce.passiveTimeWindowS*adFreqHz);
        biasForce.passive.index = round(npts*0.5);
        biasForce.passive.time  = ...
          auroraData.Data.Time.Values(biasForce.passive.index);
        biasForce.passive.force = mean(finFilt(1:npts));
        biasForce.passive.indexWindow = [1:1:npts];
      end

      if(flag_isActive==1)
        %Go to the time at which the fiber is changed into the bath
        timeBathChangeStart=nan;
        indexQuietSample=[];
        for idxCF = 1:1:length(auroraData.Test_Protocol.Control_Function.Value)
          if(strcmp(auroraData.Test_Protocol.Control_Function.Value{idxCF},...
                    'Bath'))
            if(contains(auroraData.Test_Protocol.Options.Value{idxCF},...
                    [num2str(settings.activationBathNumber),' ']))
              assert(isnan(timeBathChangeStart),...
                ['Error: the fiber is placed into',...
                ' the activation bath twice']);
              timeBathChangeStart=auroraData.Test_Protocol.Time.Value(idxCF);
              idxA=2;
              idxB=strfind(auroraData.Test_Protocol.Options.Value{idxCF},'ms');
              assert(~isempty(idxB),'Error: bath delay time not in ms');
              idxB=idxB-1;
              delayBathChangeMs=str2double(auroraData.Test_Protocol.Options.Value{idxCF}(idxA:idxB));
              timeBathChangeStart=timeBathChangeStart+delayBathChangeMs;
              timeBathChange = [1,1].*timeBathChangeStart ...
                              +[0,1].*max(settings.biasForce.activeTimeWindowS).*s2ms;
              assert(strcmp(auroraData.Data.Time.Unit,'ms'),...
                     'Error: Time is not in ms');
              idxA = find(auroraData.Data.Time.Values > timeBathChange(1),1,'first'); %round(timeBathChange(1)/(adFreqHz/1000));
              idxC = find(auroraData.Data.Time.Values > timeBathChange(2),1,'first');%round(timeBathChange(2)/(adFreqHz/1000));              
              biasForce.active.indexWindow = [idxA:1:idxC];
              timeQuietForce = timeBathChangeStart ...
                   + settings.biasForce.activeTimeWindowS(1).*s2ms;
              assert(length(settings.biasForce.activeTimeWindowS)==2,...
                  ['Error: settings.biasForce.activeTimeWindowS should',...
                   ' contain 2 entries that define a window after the ',...
                   'the bath change that should have a low-noise force reading']);
              idxB = find(auroraData.Data.Time.Values > timeQuietForce,1,'first');%round(timeQuietForce/(adFreqHz/1000));
              indexQuietSample = [idxB:idxC];              
            end
          end
        end

%         finEnvQuiet = mean(finEnv(indexQuietSample)) ...
%                       + (settings.biasForce.activeEnvelopeThreshold...
%                          *std(finEnv(indexQuietSample)));
        finEnvThreshold = max(finEnv(idxA:idxC)).*settings.biasForce.activeEnvelopeThreshold;
        dfinEnvThreshold = max(dfinEnv(idxA:idxC)).*settings.biasForce.activeEnvelopeThreshold;
        %Step backwards to the first point at which the threshold is
        %exceeded

        idxBias=idxC;
        while(finEnv(idxBias) < finEnvThreshold ...
            && dfinEnv(idxBias) <dfinEnvThreshold)%finEnvQuiet)
          idxBias=idxBias-1;
          assert(idxBias>0,'Error: idxBias has reached 0');
        end
        idxBias=idxBias+1;

        biasForce.active.index  = idxBias;
        biasForce.active.time   = auroraData.Data.Time.Values(idxBias);
        biasForce.active.force  = finFilt(idxBias);   
        biasForce.active.forceThreshold = finEnvThreshold;%finEnvQuiet;
        assert(~isempty(biasForce.active.indexWindow),...
           'Error: the window to identify the active bias was not found');
        

      end

      flag_debugBiasForce=0;
      if(flag_debugBiasForce==1)
        fig_debugBiasForce=figure;
        subplot(2,1,1);
          plot(auroraData.Data.Time.Values,auroraData.Data.Fin.Values,...
               'Color',[1,1,1].*0.75);
          hold on;
          plot(auroraData.Data.Time.Values,finFilt,...
               'Color',[1,1,1].*0.25);
          hold on;
          if(flag_isActive==0)
            plot(biasForce.passive.time,...
                 biasForce.passive.force,...
                 'o','Color',[0,0,1],'MarkerFaceColor',[0,0,1]);
            hold on;
          end
          if(flag_isActive==1)
            plot(auroraData.Data.Time.Values(biasForce.active.indexWindow),...
                 auroraData.Data.Fin.Values(biasForce.active.indexWindow),...
                 '-','Color',[1,0,0]);
            hold on;
            plot(biasForce.active.time,...
                 biasForce.active.force,...
                 'o','Color',[1,0,0],'MarkerFaceColor',[1,0,0]);
            hold on;
          end  
          
          xlabel(['Time ', auroraData.Data.Time.Unit]);
          ylabel(['Force ',auroraData.Data.Fin.Unit]);

        subplot(2,1,2);        
          plot(auroraData.Data.Time.Values,finEnv,...
               'Color',[0,0,0]);
          hold on;
          if(flag_isActive==0)
            plot(auroraData.Data.Time.Values(biasForce.passive.index),...
                 finEnv(biasForce.passive.index),...
                 'o','Color',[0,0,1],'MarkerFaceColor',[0,0,1]);
            hold on;
          end
          if(flag_isActive==1)
            plot(auroraData.Data.Time.Values(biasForce.active.indexWindow),...
                 finEnv(biasForce.active.indexWindow),...
                 '-','Color',[1,0,0]);
            hold on;

            scale_dfinEnv = max(finEnv(biasForce.active.indexWindow)) ...
                          ./max(dfinEnv(biasForce.active.indexWindow));
            scale_d2finEnv = max(finEnv(biasForce.active.indexWindow)) ...
                          ./max(d2finEnv(biasForce.active.indexWindow));

            plot(auroraData.Data.Time.Values(biasForce.active.indexWindow),...
                 abs(dfinEnv(biasForce.active.indexWindow)).*scale_dfinEnv,...
                 '-','Color',[0,0,1]);
            hold on;

%             plot(auroraData.Data.Time.Values(biasForce.active.indexWindow),...
%                  d2finEnv(biasForce.active.indexWindow).*scale_d2finEnv,...
%                  '-','Color',[0,0,0]);
%             hold on;

            plot(auroraData.Data.Time.Values(biasForce.active.index),...
                 finEnv(biasForce.active.index),...
                 'o','Color',[1,0,0]);
            hold on;            
            plot(auroraData.Data.Time.Values(biasForce.active.indexWindow),...
                 ones(size(auroraData.Data.Time.Values(biasForce.active.indexWindow)))...
                 .*biasForce.active.forceThreshold,...
                 '-c');
            hold on;  
          end          
          xlabel(['Time ', auroraData.Data.Time.Unit]);
          ylabel(['Force ',auroraData.Data.Fin.Unit]);
          
        close(fig_debugBiasForce);
      end
end
