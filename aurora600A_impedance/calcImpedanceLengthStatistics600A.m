function zlStats=calcImpedanceLengthStatistics600A(dataSet,settings)

%
% Summary statistics
%

nS=size(dataSet.individual,1);
nL=size(dataSet.individual,2);
nE=size(dataSet.individual,3);

varsLeft =settings.pairwiseComparison(:,1);
varsRight =settings.pairwiseComparison(:,2);
nC=length(varsLeft);


% 'diffMedian',zeros(nC,nL).*nan,...
% 'diffMedianNorm',zeros(nC,nL).*nan,...

statsSLE_diff(nS,nL,nE) = ...
  struct('medianDiff',zeros(nC,nL).*nan,...
         'medianDiffNorm',zeros(nC,nL),...       
         'vars',[]);

statsSL_diff(nS,nL) = ...
  struct('medianDiff',zeros(nC,nL).*nan,...
         'medianDiffNorm',zeros(nC,nL),...       
         'vars',[]);

statsSE(nS,nE) = ...
  struct('corr_rho',zeros(nC,1).*nan,...
         'corr_pval',zeros(nC,1).*nan,...
         'corr_n',zeros(nC,1).*nan,...
         'corrMedian_rho',zeros(nC,1).*nan,...
         'corrMedian_pval',zeros(nC,1).*nan,...
         'corrMedian_n',zeros(nC,1).*nan,...         
         'vars',[]);
% 
statsS(nS) = ...
  struct('corr_rho',zeros(nC,1).*nan,...
         'corr_pval',zeros(nC,1).*nan,...
         'corr_n',zeros(nC,1).*nan,...
         'vars',[]);

%
% Individual statistics
%
for idS=1:1:nS
  for idE=1:1:nE
    for idC=1:1:nC    
      statsSE(idS,idE).vars=...
        [statsSE(idS,idE).vars,...
        {[varsLeft{idC},'_',varsRight{idC}]}];   
    end
    for idL=1:1:nL
      for idC=1:1:nC
        statsSLE_diff(idS,idL,idE).vars=...
          [statsSLE_diff(idS,idL,idE).vars,...
          {[varsLeft{idC},'_',varsRight{idC}]}];
        
      end
    end
  end
end

fprintf('Extracting statistics: segment x experiment\n');
for idS=1:1:nS
  for idE=1:1:nE
    for idC=1:1:nC 

      medianSet1 = [];
      medianSet2 = [];
      dataSet1   = [];
      dataSet2   = [];

      for idL=1:1:nL
        
        idT=dataSet.T.idS==idS ...
          & dataSet.T.idL==idL ...
          & dataSet.T.idE==idE ...
          & ~isnan(dataSet.T.(varsLeft{idC}));            
        y1 = dataSet.T.(varsLeft{idC})(idT);

        idT=dataSet.T.idS==idS ...
          & dataSet.T.idL==idL ...
          & dataSet.T.idE==idE ...
          & ~isnan(dataSet.T.(varsRight{idC}));           
        y2 = dataSet.T.(varsRight{idC})(idT);            
      
        

        if(~isempty(y1) && ~isempty(y2))

          assert(length(y1)==length(y2));
          m1=median(y1);
          m2=median(y2);
  
          medianSet1=[medianSet1;m1];
          medianSet2=[medianSet2;m2];
  
          dataSet1=[dataSet1;y1];
          dataSet2=[dataSet2;y2];
  
          statsSLE_diff(idS,idL,idE).diffMedian(idC,1)=m1-m2;
    
          ss=getSummaryStatistics(y1);
          assert(abs(ss.x(5)-0.75)<1e-6 && abs(ss.x(3)-0.25)<1e-6);
          
          w = ss.y(5)-ss.y(3);        
          statsSLE_diff(idS,idL,idE).diffMedianNorm(idC,1)=(m1-m2)/w; 
  
        else
          statsSLE_diff(idS,idL,idE).diffMedian(idC,1)=nan;
          statsSLE_diff(idS,idL,idE).diffMedianNorm(idC,1)=nan;

          fprintf('\t%i,%i,%i - %i\n',idS,idE,idL, idC);
          fprintf('\t*%i - too little data\n',length(y1));
        end
      end 
      if(~isempty(medianSet1))
        [rhoM,pvalM] = corr(medianSet1,medianSet2,'Type','Pearson');
        statsSE(idS,idE).corrMedian_n(idC)    = length(medianSet1);       
        statsSE(idS,idE).corrMedian_rho(idC)  = rhoM;   
        statsSE(idS,idE).corrMedian_pval(idC) = pvalM;  
    
        [rho,pval] = corr(dataSet1,dataSet2,'Type','Pearson');
        statsSE(idS,idE).corr_n(idC)    = length(dataSet1);       
        statsSE(idS,idE).corr_rho(idC)  = rho;   
        statsSE(idS,idE).corr_pval(idC) = pval;  
        statsSE(idS,idE).vars(idC)=...
          {[varsLeft{idC},'_',varsRight{idC}]};
      end

    end    
  end
end

%
% Group statistics
%
for idS=1:1:nS

  for idC=1:1:nC
    statsS(idS).vars= ...
      [statsS(idS).vars,...
       {[varsLeft{idC},'_',varsRight{idC}]}]; 
  end
  for idL=1:1:nL
    for idC=1:1:nC
      statsSL_diff(idS,idL).vars=...
        [statsSL_diff(idS,idL).vars,...
         {[varsLeft{idC},'_',varsRight{idC}]}];  
    end
  end

end

fprintf('Extracting statistics: segment\n');
for idS=1:1:nS
  for idC=1:1:nC 

    medianSet1 = [];
    medianSet2 = [];
    dataSet1   = [];
    dataSet2   = [];

    for idL=1:1:nL

      idT=dataSet.T.idS==idS ...
        & dataSet.T.idL==idL ...
        & ~isnan(dataSet.T.(varsLeft{idC}));            
      y1 = dataSet.T.(varsLeft{idC})(idT);

      idT=dataSet.T.idS==idS ...
        & dataSet.T.idL==idL ...
        & ~isnan(dataSet.T.(varsRight{idC}));           
      y2 = dataSet.T.(varsRight{idC})(idT);            

      if(~isempty(y1) && ~isempty(y2))
        assert(length(y1)==length(y2));  
  
        m1=median(y1);
        m2=median(y2);
  
        medianSet1=[medianSet1;median(y1)];
        medianSet2=[medianSet2;median(y2)];
  
        dataSet1=[dataSet1;y1];
        dataSet2=[dataSet2;y2];
  
        statsSL_diff(idS,idL).diffMedian(idC,1)=m1-m2;
  
        ss=getSummaryStatistics(y1);
        assert(abs(ss.x(5)-0.75)<1e-6 && abs(ss.x(3)-0.25)<1e-6);
        
        w = ss.y(5)-ss.y(3);        
        statsSL_diff(idS,idL).diffMedianNorm(idC,1)=(m1-m2)/w;       
      else
        statsSL_diff(idS,idL).diffMedian(idC,1)=nan;
        statsSL_diff(idS,idL).diffMedianNorm(idC,1)=nan;
        fprintf('\t%i,%i - %i\n',idS,idL, idC);
        fprintf('\t*%i - too little data\n',length(y1));        
      end


    end 
    [rhoM,pvalM] = corr(medianSet1,medianSet2,'Type','Pearson');
    statsS(idS).corrMedian_n(idC)    = length(medianSet1);       
    statsS(idS).corrMedian_rho(idC)  = rhoM;   
    statsS(idS).corrMedian_pval(idC) = pvalM;  

    [rho,pval] = corr(dataSet1,dataSet2,'Type','Pearson');
    statsS(idS).corr_n(idC)    = length(dataSet1);       
    statsS(idS).corr_rho(idC)  = rho;   
    statsS(idS).corr_pval(idC) = pval;     

    
  end    
end

zlStats.corrS   = statsS;
zlStats.corrSE  = statsSE;
zlStats.diffSLE = statsSLE_diff;
zlStats.diffSL  = statsSL_diff;
