function biasForceSet = calcTrialSpecificBiasForce600A(...
  setOfTrials,experimentJson,categories,dataFolder,settings,fidLogFile)


  biasForceSet(length(setOfTrials))=...
    struct('trialIndex',[],'isActive',[],'lengthNominal',0,...
            'indexPassiveBias',0,'indexActiveBias',0,'biasForce',0,...
            'passive',[],'active',[]);
  for idxT=1:1:length(setOfTrials)
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



  for indexSetOfTrials=1:1:length(setOfTrials)

    idxTrial = setOfTrials(indexSetOfTrials);  
    biasForceSet(indexSetOfTrials).trials = experimentJson.measurements(idxTrial);
    biasForceSet(indexSetOfTrials).isActive = 0;
    if(contains(experimentJson.measurements(idxTrial),'_active_'))
      biasForceSet(indexSetOfTrials).isActive = 1;
    end
    biasForceSet(indexSetOfTrials).trialIndex = idxTrial;          

    found=0;
    for idxL=1:1:length(categories.length.value)
      if(contains(experimentJson.measurements(idxTrial),categories.length.str{idxL}))
        assert(found==0);
        biasForceSet(indexSetOfTrials).lengthNominal=categories.length.value(idxL);
        found=1;
      end
    end
    assert(found==1);

    biasForceSet(indexSetOfTrials)= ...
      extractBiasForce600A(biasForceSet(indexSetOfTrials),experimentJson,...
                           dataFolder,settings,fidLogFile);  
    here=1;
  end

  indexActiveBias=nan;
  indexPassiveBias=nan;
  for indexSetOfTrials=1:1:length(setOfTrials)
    idxTrial = setOfTrials(indexSetOfTrials); 
    for indexKeyword =1:1:length(settings.biasForce.keywords)
      if(~isempty(settings.biasForce.keywords{indexKeyword}))
        if(contains(experimentJson.measurements{idxTrial},...
                settings.biasForce.keywords{indexKeyword}))
          if(settings.biasForce.isActive(indexKeyword))
            indexActiveBias=indexSetOfTrials;
          else
            indexPassiveBias=indexSetOfTrials;          
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
  for indexSetOfTrials=1:1:length(setOfTrials)

    idxTrial = setOfTrials(indexSetOfTrials);  
    %The active force bias contains the passive force at this
    %length, so we need to add it back.
    %
    %Get the passive force bias
    idxPassiveBias = biasForceSet(indexSetOfTrials).indexPassiveBias;
    forcePassiveBias=biasForceSet(idxPassiveBias).passive.force;

    if(biasForceSet(indexSetOfTrials).isActive==1)
      %Get the passive force at the current length
      lengthNominal = biasForceSet(indexSetOfTrials).lengthNominal;
      found=0;
      for idxT=1:1:length(biasForceSet)
        if(biasForceSet(idxT).isActive == 0 ...
            && abs(biasForceSet(idxT).lengthNominal-lengthNominal)<1e-6)
          assert(found==0);
          forcePassive = biasForceSet(idxT).passive.force-forcePassiveBias;
          found=1;
        end
      end
      
      yActiveBias  = biasForceSet(indexSetOfTrials).active.force;
      yPassiveBias = forcePassive;
      yBias        = yActiveBias-yPassiveBias;
      biasForceSet(indexSetOfTrials).biasForce=yBias;
    else
      biasForceSet(indexSetOfTrials).biasForce=forcePassiveBias;
    end
  end


  flag_debugBiasSet=0;
  if(flag_debugBiasSet==1)
    activeBias=[];
    passiveBias=[];
    for idxNL=1:1:length(categories.length.value)
      found=0;
      for idxT=1:1:length(biasForceSet)
        if(abs(biasForceSet(idxT).lengthNominal-categories.length.value(idxNL))<1e-6 )
          found=1;
          if(biasForceSet(idxT).isActive==1)
            activeBias = [activeBias;biasForceSet(idxT).active.force];
          else
            passiveBias = [passiveBias;biasForceSet(idxT).passive.force];          
          end
        end
      end
      assert(found==1);
    end    
    fig_debugBiasSet=figure;
    plot(categories.length.value,passiveBias,'-b');
    hold on;
    plot(categories.length.value,activeBias,'-r');
    hold on;
    xlabel('Norm. Length');
    ylabel('Force (mN)');
    close(fig_debugBiasSet);
  end
  