function biasForceSet = calcTrialSpecificBiasForce600A(...
  experimentJson,categories,dataFolder,settings,fidLogFile)


  

  biasForceSet(length(experimentJson.measurements))=...
    struct('trialIndex',[],'isActive',[],'lengthNominal',0,...
            'indexPassiveBias',0,'indexActiveBias',0,'biasForce',0,...
            'passive',[],'active',[]);
  for idxT=1:1:length(experimentJson.measurements)
    biasForceSet(idxT)=...
      struct('trialIndex',[],'isActive',[],'lengthNominal',0,...
            'indexPassiveBias',0,'indexActiveBias',0,'biasForce',0,...
            'passive',[],'active',[]);
    biasForceSet(idxT).passive=...
      struct('time',[],'force',[],'method',[],'file','',...
             'indices',[]);
    biasForceSet(idxT).active=...
      struct('time',[],'force',[],'method',[],'file','',...
             'indices',[]);
  end



  for idxTrial=1:1:length(experimentJson.measurements)
 
    biasForceSet(idxTrial).trials = experimentJson.measurements(idxTrial);
    biasForceSet(idxTrial).isActive = 0;
    if(contains(experimentJson.measurements(idxTrial),categories.active.str))
      biasForceSet(idxTrial).isActive = 1;
    end
    biasForceSet(idxTrial).trialIndex = idxTrial;          

    found=0;
    for idxL=1:1:length(categories.length.value)
      if(contains(experimentJson.measurements(idxTrial),categories.length.str{idxL}))
        assert(found==0);
        biasForceSet(idxTrial).lengthNominal=categories.length.value(idxL);
        found=1;
      end
    end

    if(found==1)
      biasForceSet(idxTrial)= ...
        extractBiasForce600A(biasForceSet(idxTrial),experimentJson,...
                             dataFolder,settings,fidLogFile);  
    end
  end

  indexActiveBias=nan;
  indexPassiveBias=nan;
  for idxTrial=1:1:length(experimentJson.measurements)
    for indexKeyword =1:1:length(settings.biasForce.keywords)
      if(~isempty(settings.biasForce.keywords{indexKeyword}))
        if(contains(experimentJson.measurements{idxTrial},...
                settings.biasForce.keywords{indexKeyword}))

          if(settings.biasForce.isActive(indexKeyword))
            if(isnan(indexActiveBias))
              indexActiveBias=idxTrial;
            end
          else
            if(isnan(indexPassiveBias))
              indexPassiveBias=idxTrial;          
            end
          end
        end
      end
    end
  end

  for i=1:1:length(biasForceSet)
    biasForceSet(i).indexActiveBias=indexActiveBias;
    biasForceSet(i).indexPassiveBias=indexPassiveBias;
  end


  %Calculate the total bias force for each trial
  for idxTrial=1:1:length(experimentJson.measurements)

    %The active force bias contains the passive force at this
    %length, so we need to add it back.
    %
    %Get the passive force bias
    forcePassiveBias=0;
    if(~isnan(biasForceSet(idxTrial).indexPassiveBias))
      idxPassiveBias = biasForceSet(idxTrial).indexPassiveBias;
      forcePassiveBias=biasForceSet(idxPassiveBias).passive.force;
    end

    if(biasForceSet(idxTrial).isActive==1)
      %Get the passive force at the current length
      lengthNominal = biasForceSet(idxTrial).lengthNominal;
      found=0;
      for idxT=1:1:length(biasForceSet)
        if(biasForceSet(idxT).isActive == 0 ...
            && abs(biasForceSet(idxT).lengthNominal-lengthNominal)<1e-6)
          if(found==0)
            forcePassive = biasForceSet(idxT).passive.force-forcePassiveBias;
            found=1;
          end
        end
      end
      
      yActiveBias  = biasForceSet(idxTrial).active.force;
      yPassiveBias = forcePassive;
      yBias        = yActiveBias-yPassiveBias;
      biasForceSet(idxTrial).biasForce=yBias;
    else
      biasForceSet(idxTrial).biasForce=forcePassiveBias;
    end
  end


  flag_debugBiasSet=0;
  if(flag_debugBiasSet==1)
    activeLength=[];
    activeBias=[];
    passiveBias=[];
    passiveLength=[];
    
    for idxNL=1:1:length(categories.length.value)
      found=0;
      for idxT=1:1:length(biasForceSet)
        if(abs(biasForceSet(idxT).lengthNominal-categories.length.value(idxNL))<1e-6 )
          found=1;
          if(biasForceSet(idxT).isActive==1)
            activeBias = [activeBias;biasForceSet(idxT).active.force];
            activeLength=[activeLength;categories.length.value(idxNL)];
          else
            passiveBias = [passiveBias;biasForceSet(idxT).passive.force];          
            passiveLength=[passiveLength;categories.length.value(idxNL)];
            
          end
        end
      end
      assert(found==1);
    end    
    fig_debugBiasSet=figure;
    if(~isempty(passiveBias))
      plot(passiveLength,passiveBias,'ob','MarkerFaceColor',[0,0,1]);
      hold on;
    end
    if(~isempty(activeBias))
      plot(activeLength,activeBias,'or','MarkerFaceColor',[1,0,0]);
      hold on;
    end
    xlabel('Norm. Length');
    ylabel('Force (mN)');
    close(fig_debugBiasSet);
  end
  