function dataSet = ...
    createImpedanceLengthDataSet600A(...
                        experimentList,...
                        segmentSeries,...
                        categories,...
                        projectFolders,...
                        settings)

assert(length(segmentSeries)==4,...
  'Error: this function has only been tested when all 4 segments are used');
assert(length(categories.length.value)==7,...
  'Error: this function has only been tested when all 7 lengths are used');


tableColumnNorm = {'','','',...
  '','fo/lo','fo/lo','fo','lo',...
  '','fo/lo','fo/lo','fo','lo',...
  '','fo/lo','fo/lo','fo','lo',...
  'StorageI','LossI',...
  'StorageG','LossG','foG','loG'};

tableColumnNames={'idE','idS','idL',...
  'frequency','storage','loss','force','length',...
  'frequencyA','storageA','lossA','forceA','lengthA',...
  'frequencyP','storageP','lossP','forceP','lengthP',...
  'storageAi','lossAi',...
  'storageAg','lossAg','forceAg','lengthAg'};

tableColumnType={'int8','int8','int8',...
  'double','double','double','double','double',...
  'double','double','double','double','double',...
  'double','double','double','double','double',...
  'double','double',...
  'double','double','double','double'};

tableColumnUnits={'','','',...
  'Hz','(mN/mm)/(mN/mm)','(mN/mm)/(mN/mm)','(mN/mN)','(mm/mm)',...
  'Hz','(mN/mm)/(mN/mm)','(mN/mm)/(mN/mm)','(mN/mN)','(mm/mm)',...
  'Hz','(mN/mm)/(mN/mm)','(mN/mm)/(mN/mm)','(mN/mN)','(mm/mm)',...
  '(mN/mm)/(mN/mm)','(mN/mm)/(mN/mm)',...
  '(mN/mm)/(mN/mm)','(mN/mm)/(mN/mm)','(mN/mN)','(mm/mm)'};

tableColumnDescription = ...
  {'exp. index', 'seg. index', 'length index',...
  'frequency vector that goes with (storage, loss)',...
  'normalized (Fo/Lo) storage vector from an active fiber trial',...
  'normalized (Fo/Lo) loss vector from an active fiber trial',...
  'normalized (Fo) nominal force sample (matching length to storage and loss)',...
  'normalized (Lo) nominal length sample (matching length to storage and loss)',...
  'frequency vector that goes with (storageActive, lossActive)',...
  'normalized (Fo/Lo) storage vector from an active fiber trial with the passive component removed',...
  'normalized (Fo/Lo) loss vector from an active fiber trial with the passive component removed',...  
  'normalized (Fo) nominal force sample (matching length to storageA and lossA)',...
  'normalized (Lo) nominal length sample (matching length to storageA and lossA)',...
  'frequency vector from a passive fiber trial that goes with (storagePassive,lossPassive)',...
  'normalized (Fo/Lo) storage vector from a passive fiber trial',...
  'normalzied (Fo/Lo) loss vector from a passive fiber trial',...
  'normalized (Fo) nominal force sample (matching length to storageP and lossP)',...
  'normalized (Lo) nominal length sample (matching length to storageP and lossP)',...
  'sample normalized (P50(So_i)) storage vector from an active fiber trial',...
  'sample normalized (P50(Lo_i)) loss vector from an active fiber trial',...
  'cohort normalized (P50(So_i, i=1..n)) storage vector from an active fiber trial',...
  'cohort normalized (P50(Lo_i, i=1..n)) loss vector from an active fiber trial'...  
  'cohort normalized (P50(So_i, i=1..n)) force vector from an active fiber trial',...
  'cohort normalized (P50(Lo_i, i=1..n)) length vector from an active fiber trial'...    
  };

tableDescription=...
  ['This table contains the frequency dependent storage and loss ',...
  'vectors that best fits the total, active, and passive response',...
  'of a fiber when exposed to a mechanical vibration'];

nSegment     = length(segmentSeries);
nLength      = length(categories.length.value);
nExperiments = length(experimentList);

dataTable =table('Size',[0,...
                         length(tableColumnNames)],...
                  'VariableNames',tableColumnNames,...
                  'VariableTypes',tableColumnType);



dataTable.Properties.VariableUnits        = tableColumnUnits;
dataTable.Properties.VariableDescriptions = tableColumnDescription;
dataTable.Properties.Description          = tableDescription;

tableProperties = struct('columnTypes',tableColumnType,...
                             'columnNames',tableColumnNames,...
                             'columnNormalization',tableColumnNorm);

individualProperties(nSegment,nLength,nExperiments) = ...
        struct('lengthAtLo',nan,...
               'forceAtLo',nan,...  
               'storageAtLo',nan,...
               'lossAtLo',nan,...               
               'lengthNominalMM',nan,...
               'amplitudeLo',nan,...
               'bandwidthHz',nan);

groupProperties(nSegment)=...
  struct('lengthAtLo',nan,...
         'forceAtLo',nan,...
         'storageAtLo',nan,...
         'lossAtLo',nan,...
         'amplitudeLo',nan,...
         'bandwidthHz',nan);



%
% Pre allocate all of the tables and initialize all of the table entries.
% Any double field is initialized to nan so that raw data vectors of 
% different length can be stored and retrieved by using the nans as a 
% mask.
%
for idxE=1:1:length(experimentList)
  for idxL=1:1:length(categories.length.value)
    for idxS=1:1:length(segmentSeries)
      individualProperties(idxS,idxL,idxE) = ...
              struct('lengthAtLo',nan,...
                     'forceAtLo',nan,...   
                     'storageAtLo',nan,...
                     'lossAtLo',nan,...
                     'lengthNominalMM',nan,...
                     'amplitudeLo',nan,...
                     'bandwidthHz',nan);

    end
  end
end

%
% Populate the entries
%

for idxE=1:1:length(experimentList)
  trialList = dir(fullfile(projectFolders.output600A_json,...
                    experimentList{idxE}));

  fprintf('\n\n%i.\t%s\n',idxE,experimentList{idxE});

  flag_addedActivePassiveData=0;  
  trialCount=0;

  for idxTrialA=1:1:length(trialList)

    if(contains(trialList(idxTrialA).name,'.json'))

      %Go get the active trial, and then its passive pair
      if(contains(trialList(idxTrialA).name,...
         settings.keyWordActive))

        %Make sure that this active file has a unique length id
        idxL = nan;
        for i = 1:1:length(categories.length.str)
          if(contains(trialList(idxTrialA).name,categories.length.str{i}))
            assert(isnan(idxL),...
              'Error: there appear to be two valid active trials');
            idxL=i;
          end
        end
        assert(~isnan(idxL),...
          'Error: could not find a valid length category');

        aFilePath = fullfile(projectFolders.output600A_json,...
                            experimentList{idxE},...
                            trialList(idxTrialA).name);
        aFileData = fileread(aFilePath);
        aJsonData = jsondecode(aFileData);


        %Go and get the passive data
        idxTrialP=nan;
        for idxTmp=1:1:length(trialList)
          if(   contains(trialList(idxTmp).name,'_passive_') ...
             && contains(trialList(idxTmp).name,categories.length.str{idxL}))
            assert(isnan(idxTrialP),...
              'Error: there appear to be two valid passive trials');
            idxTrialP=idxTmp;
          end
        end
        assert(~isnan(idxTrialP),...
          'Error: could not find a matching passive trial');
        pFilePath = fullfile(projectFolders.output600A_json,...
                            experimentList{idxE},...
                            trialList(idxTrialP).name);
        pFileData = fileread(pFilePath);
        pJsonData = jsondecode(pFileData);        
       
        trialCount=trialCount+1;
        fprintf('\t%i.\t%s\n',trialCount,trialList(idxTrialA).name);
        trialCount=trialCount+1;        
        fprintf('\t%i.\t%s\n',trialCount,trialList(idxTrialP).name);

        flag_addedActivePassiveData=1;
        %
        % Go through each segment
        %
        for idxS = 1:1:length(segmentSeries)          
          %
          % Check the units
          %
          assert(strcmp(aJsonData(idxS).segment.unit.length,...
                        settings.lengthUnit));
          assert(strcmp(aJsonData(idxS).segment.unit.force,...
                        settings.forceUnit));
          assert(strcmp(aJsonData(idxS).segment.unit.time,...
                        settings.timeUnit));
  
          assert(strcmp(pJsonData(idxS).segment.unit.length,...
                        settings.lengthUnit));
          assert(strcmp(pJsonData(idxS).segment.unit.force,...
                        settings.forceUnit));
          assert(strcmp(pJsonData(idxS).segment.unit.time,...
                        settings.timeUnit));
          %
          % Initialize the table for this measurement
          %
          mTable =table('Size',[settings.numberOfTableRows,...
                                   length(tableColumnNames)],...
                        'VariableNames',tableColumnNames,...
                        'VariableTypes',tableColumnType);  

          mTable.Properties.VariableUnits=tableColumnUnits;
          mTable.Properties.VariableDescriptions...
            =tableColumnDescription;
          mTable.Properties.Description=tableDescription;          
    
          for idxC=1:1:length(tableColumnType)
            switch tableColumnType{idxC}
              case 'int8'
                switch tableColumnNames{idxC}
                  case 'idE'
                    mTable.(tableColumnNames{idxC})(:)=idxE;
                  case 'idS'
                    mTable.(tableColumnNames{idxC})(:)=idxS;
                  case 'idL'
                    mTable.(tableColumnNames{idxC})(:)=idxL;
                  otherwise
                    assert(0,'Error: unrecognized id');
                end
              case 'double'
                mTable.(tableColumnNames{idxC})(:)=nan;
              otherwise
                assert(0,'Error: Unrecognized type');
            end
            
          end

          %
          % Get the target bandwidth and amplitude and make sure it is
          % consistent between the active and passive experiments
          %
  
          bandwidthHz=max(aJsonData(idxS).segment.H.bandwidthHz);
          amplitudeLo=aJsonData(idxS).segment.H.amplitudeLo*2;
  
          if(~isempty(pJsonData(idxS).segment.H.bandwidthHzC2))  
            if(abs(max(aJsonData(idxS).segment.H.bandwidthHz)...
                      -max(pJsonData(idxS).segment.H.bandwidthHz))>1e-6)
              here=1;
            end
            if(abs(aJsonData(idxS).segment.H.amplitudeLo...
                       -pJsonData(idxS).segment.H.amplitudeLo)>1e-6)
              here=1;
            end
            assert(abs(max(aJsonData(idxS).segment.H.bandwidthHz)...
                      -max(pJsonData(idxS).segment.H.bandwidthHz))<1e-6);
            assert(abs(aJsonData(idxS).segment.H.amplitudeLo...
                      -pJsonData(idxS).segment.H.amplitudeLo)<1e-6);
          end 


          %
          % Go and get the quiet time interval before the perturbation
          % starts
          %
          aNominalLengthMM=median(aJsonData(idxS).segment.pre.raw.length);

          %If there is passive data, then check that the active and
          %passive trials are really measuring the same length
          if(~isempty(pJsonData(idxS).segment.H.bandwidthHzC2)) 
            pNominalLengthMM=median(pJsonData(idxS).segment.pre.raw.length);  
            relErrorNominalLength = ...
               0.5*abs(aNominalLengthMM-pNominalLengthMM) ...
                /(0.5*(aNominalLengthMM+pNominalLengthMM));
  
            if(relErrorNominalLength >= 0.05 ...
                || isnan(relErrorNominalLength) ...
                || isempty(relErrorNominalLength))
              here=1;
            end
            assert(relErrorNominalLength < 0.05);
          end
          


         
          individualProperties(idxS,idxL,idxE).lengthNominalMM = ...
            median(aJsonData(idxS).segment.pre.raw.length);
          individualProperties(idxS,idxL,idxE).bandwidthHz= bandwidthHz;
          individualProperties(idxS,idxL,idxE).amplitudeLo= amplitudeLo;

          %
          % Process the data and save it to the table
          %

          mTable.idE(:)=idxE;
          mTable.idS(:)=idxS;
          mTable.idL(:)=idxL;

          %
          % Save the measured active trial
          %

          %
          % If the passive data contains any frequency components that
          % meet the coherence-squared requirements, save these, and
          % subtract the passive storage and loss profiles from the
          % active storage and loss profiles
          %
          idxBWC2 = aJsonData(idxS).segment.H.idxBWC2;
          nA =length(idxBWC2);
          
          assert(nA <= settings.numberOfTableRows);
          assert(nA <= length(aJsonData(idxS).segment.pre.raw.length));
          
          mTable.frequency(1:nA) = ...
            aJsonData(idxS).segment.H.frequencyHz(idxBWC2);
          mTable.storage(1:nA) = ...
            aJsonData(idxS).segment.H.storage(idxBWC2);
          mTable.loss(1:nA) = ...
            aJsonData(idxS).segment.H.loss(idxBWC2);
          mTable.force(1:nA) = ...
            aJsonData(idxS).segment.pre.raw.force(1:nA);
          mTable.length(1:nA) = ...
            aJsonData(idxS).segment.pre.raw.length(1:nA);


          %Copy over the response over to the active component.
          %If there is valid passive data, then we'll subtract it off.
          mTable.frequencyA(1:nA) = ...
            mTable.frequency(1:nA);
          mTable.storageA(1:nA) = ...
            mTable.storage(1:nA);
          mTable.lossA(1:nA) = ...
            mTable.loss(1:nA);
          mTable.forceA(1:nA) = ...
            mTable.force(1:nA);
          mTable.lengthA(1:nA) = ...
            mTable.length(1:nA);    

          if(~isempty(pJsonData(idxS).segment.H.bandwidthHzC2)) 

            %
            % There is passive force: subtract the passive storage and
            % loss from the total passive and storage to get the 
            % active storage and loss.
            %            
            idxPBWC2 = pJsonData(idxS).segment.H.idxBWC2;
            nP =length(idxPBWC2);
          
            assert(nP <= settings.numberOfTableRows);
            assert(nP <= length(pJsonData(idxS).segment.pre.raw.length));

            %Copy over the passive data that matches the coherence-squared
            %threshold
            mTable.frequency(1:nP) = ...
              pJsonData(idxS).segment.H.frequencyHz(idxPBWC2);
            mTable.storage(1:nP) = ...
              pJsonData(idxS).segment.H.storage(idxPBWC2);
            mTable.loss(1:nP) = ...
              pJsonData(idxS).segment.H.loss(idxPBWC2);
            mTable.force(1:nP) = ...
              pJsonData(idxS).segment.pre.raw.force(1:nP);
            mTable.length(1:nP) = ...
              pJsonData(idxS).segment.pre.raw.length(1:nP);

            %
            % If there is sufficient passive storage and loss data
            % subtract it from the total storage and loss data
            %
            bwA = diff(aJsonData(idxS).segment.H.bandwidthHzC2);
            bwP = diff(pJsonData(idxS).segment.H.bandwidthHzC2);
            bwN = bwP/bwA;
            if(bwN >= settings.minimumBandwidthFractionForPassiveInclusion)

              storageP = interp1(pJsonData(idxS).segment.H.frequencyHz,...
                                 pJsonData(idxS).segment.H.storage,...
                                 aJsonData(idxS).segment.H.frequencyHz(idxBWC2));

              lossP = interp1(pJsonData(idxS).segment.H.frequencyHz,...
                              pJsonData(idxS).segment.H.loss,...
                              aJsonData(idxS).segment.H.frequencyHz(idxBWC2));
              
              mTable.frequencyA(1:nA) = ...
                aJsonData(idxS).segment.H.frequencyHz(idxBWC2);

              mTable.storageA(1:nA) = ...
                aJsonData(idxS).segment.H.storage(idxBWC2) ...
                -storageP;

              mTable.lossA(1:nA) = ...
                aJsonData(idxS).segment.H.loss(idxBWC2) ...
                -lossP;

              mTable.forceA(1:nA) = ...
                aJsonData(idxS).segment.pre.raw.force(1:nA) ...
                -mean(pJsonData(idxS).segment.pre.raw.force(1:nA));

              mTable.lengthA(1:nA) = ...
                aJsonData(idxS).segment.pre.raw.length(1:nA);

            end
          end

          %These will be normalized later
          mTable.storageAi(1:nA) =mTable.storageA(1:nA);
          mTable.lossAi(1:nA)    =mTable.lossA(1:nA);
          mTable.storageAg(1:nA) =mTable.storageA(1:nA);
          mTable.lossAg(1:nA)    =mTable.lossA(1:nA);
          mTable.forceAg(1:nA)   =mTable.forceA(1:nA);
          mTable.lengthAg(1:nA)  =mTable.lengthA(1:nA);


          % If this is Lo, save the parameters
          if(categories.isLo(idxL)==1)


            individualProperties(idxS,idxL,idxE).lengthAtLo = ...
              median(mTable.lengthA(1:nA));

            individualProperties(idxS,idxL,idxE).forceAtLo = ...
              median(mTable.forceA(1:nA));

            individualProperties(idxS,idxL,idxE).storageAtLo = ...
              median(mTable.storageA(1:nA));

            individualProperties(idxS,idxL,idxE).lossAtLo = ...
              median(mTable.lossA(1:nA)); 
            
          end

          dataTable=[dataTable;mTable];
        end
      end
    end
  end
  
  %
  %Normalize all of this experiments data by Fo, Lo, and Fo/Lo
  %
  assert(flag_addedActivePassiveData==1);

  if(flag_addedActivePassiveData==1)
    idxAtLo = find(categories.isLo > 0);

    %idxSNorm = settings.normalizationSegment;

%     idxOpt= dataTable.idE==idxE ...
%           & dataTable.idL == categories.length.indexLopt ...
%           & dataTable.idS == settings.normalizationSegment ...
%           & ~isnan(dataTable.length);
% 
%     lengthAtLoA = mean(dataTable.length(idxOpt));


    for idxS = 1:1:length(segmentSeries)

      lengthAtLo  = individualProperties(idxS,idxAtLo,idxE).lengthAtLo;
      forceAtLo   = individualProperties(idxS,idxAtLo,idxE).forceAtLo;  
      storageAtLo = individualProperties(idxS,idxAtLo,idxE).storageAtLo;  
      lossAtLo    = individualProperties(idxS,idxAtLo,idxE).lossAtLo;  
  
      stiffnessNorm=forceAtLo/lengthAtLo;
      
      for idxL = 1:1:length(categories.length.value)

        individualProperties(idxS,idxL,idxE).lengthAtLo   = lengthAtLo;
        individualProperties(idxS,idxL,idxE).forceAtLo    = forceAtLo;
        individualProperties(idxS,idxL,idxE).storageAtLo  = storageAtLo;
        individualProperties(idxS,idxL,idxE).lossAtLo     = lossAtLo;

        idxT=   dataTable.idS == idxS ...
              & dataTable.idL == idxL ...
              & dataTable.idE == idxE;

        for idxC=1:1:length(tableColumnNames)
          if(~isempty(tableColumnNorm{idxC}))
            switch tableColumnNorm{idxC}
              case 'fo'
                dataTable.(tableColumnNames{idxC})(idxT) = ...
                  dataTable.(tableColumnNames{idxC})(idxT) ...
                  ./ forceAtLo;
                
              case 'lo'
                dataTable.(tableColumnNames{idxC})(idxT) = ...
                  dataTable.(tableColumnNames{idxC})(idxT) ...
                  ./ lengthAtLo;              
                
              case 'fo/lo'
                dataTable.(tableColumnNames{idxC})(idxT) = ...
                  dataTable.(tableColumnNames{idxC})(idxT) ...
                    ./ stiffnessNorm;
       
              case 'StorageI'
                dataTable.(tableColumnNames{idxC})(idxT) = ...
                  dataTable.(tableColumnNames{idxC})(idxT) ...
                  ./storageAtLo;

                t0=~isnan(dataTable.(tableColumnNames{idxC})(idxT));
                if(sum(t0)==0)
                  here=1;
                end

              case 'LossI'
                dataTable.(tableColumnNames{idxC})(idxT) = ...
                  dataTable.(tableColumnNames{idxC})(idxT) ...
                  ./ lossAtLo;                

              otherwise
                assert(strcmp(tableColumnNorm{idxC},'StorageG') ...
                  || strcmp(tableColumnNorm{idxC},'LossG') ...
                  || strcmp(tableColumnNorm{idxC},'foG') ...
                  || strcmp(tableColumnNorm{idxC},'loG'),...
                  'Error: unrecogized normalization factor');
            end
          end          
        end
      end
    end
  end  

end


%
% All experiments have been processed, now we can calculate the cohort
% norms
%

for idxS=1:1:length(segmentSeries)
  idxL = categories.length.indexLopt;

  forceAtLo   =[];
  lengthAtLo  =[];
  storageAtLo =[];
  lossAtLo    =[];

  for idxE=1:1:length(experimentList)
    forceAtLo   =[forceAtLo;    individualProperties(idxS,idxL,idxE).forceAtLo];
    lengthAtLo  =[lengthAtLo;   individualProperties(idxS,idxL,idxE).lengthAtLo];
    storageAtLo =[storageAtLo;  individualProperties(idxS,idxL,idxE).storageAtLo];
    lossAtLo    =[lossAtLo;     individualProperties(idxS,idxL,idxE).lossAtLo];    
  end



  forceAtLoG    = mean(forceAtLo);
  lengthAtLoG   = mean(lengthAtLo);
  storageAtLoG  = mean(storageAtLo);
  lossAtLoG     = mean(lossAtLo);
  amplitudeLo   = individualProperties(idxS,idxL,idxE).amplitudeLo;
  bandwidthHz   = individualProperties(idxS,idxL,idxE).bandwidthHz;


  groupProperties(idxS)=...
    struct('lengthAtLo',lengthAtLoG,...
           'forceAtLo',forceAtLoG,...
           'storageAtLo',storageAtLoG,...
           'lossAtLo',lossAtLoG,...
           'amplitudeLo',amplitudeLo,...
           'bandwidthHz',bandwidthHz);

  idxTS =  dataTable.idS == idxS;

  for idxC=1:1:length(tableColumnNames)
    if(~isempty(tableColumnNorm{idxC}))
      switch tableColumnNorm{idxC}
        case 'foG'
          dataTable.(tableColumnNames{idxC})(idxTS) = ...
            dataTable.(tableColumnNames{idxC})(idxTS) ...
            ./forceAtLoG;

        case 'loG'
          dataTable.(tableColumnNames{idxC})(idxTS) = ...
            dataTable.(tableColumnNames{idxC})(idxTS) ...
            ./lengthAtLoG;

        case 'StorageG'
          dataTable.(tableColumnNames{idxC})(idxTS) = ...
            dataTable.(tableColumnNames{idxC})(idxTS) ...
            ./storageAtLoG;

        case 'LossG'
          dataTable.(tableColumnNames{idxC})(idxTS) = ...
            dataTable.(tableColumnNames{idxC})(idxTS) ...
            ./lossAtLoG;

        otherwise
          assert( ...
               strcmp(tableColumnNorm{idxC},'fo') ...
            || strcmp(tableColumnNorm{idxC},'lo') ...
            || strcmp(tableColumnNorm{idxC},'fo/lo') ...            
            || strcmp(tableColumnNorm{idxC},'StorageI') ...
            || strcmp(tableColumnNorm{idxC},'LossI') ...
            || strcmp(tableColumnNorm{idxC},'foG') ...
            || strcmp(tableColumnNorm{idxC},'loG'), ...            
            'Error: unrecogized normalization factor');
      end
    end          
  end

end




dataSet= struct('T',dataTable, ...
                'Tprop',tableProperties, ...
                'individual',individualProperties,...
                'group',groupProperties);





