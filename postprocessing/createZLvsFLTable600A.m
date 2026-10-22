function success=createZLvsFLTable600A(...
                  dataSet,...
                  dataSetStats,...
                  segmentSeries,...
                  categories,...
                  projectFolders,...
                  settings)

assert(length(segmentSeries)==4,...
  'Error: this function has only been tested when all 4 segments are used');
assert(length(categories.length.value)==7,...
  'Error: this function has only been tested when all 7 lengths are used');

nS=size(dataSet.individual,1);
nL=size(dataSet.individual,2);
nE=size(dataSet.individual,3);
nC=size(settings.pairwiseComparison,1);

success=0;

nSeg = 4;
nCat = nSeg*2;
nCorr= nSeg*4;
nDiff= nSeg*2*2;
nEntry = nCat+nCorr+nDiff;

varMap(nEntry)=struct('symbol','','str','');

idx=0;
idCS=1;
idCL=2;

corrColorMap(5)=struct('lim',[],'color',[]);
corrColorMap(1).lim=[0,0.1];
corrColorMap(1).color='gray4';
corrColorMap(2).lim=[0.1,0.3];
corrColorMap(2).color='gray3';
corrColorMap(3).lim=[0.3,0.5];
corrColorMap(3).color='gray2';
corrColorMap(4).lim=[0.5,0.7];
corrColorMap(4).color='gray1';
corrColorMap(5).lim=[0.7,1.0];
corrColorMap(5).color='';

diffNormColorMap(7)=struct('lim',[],'color',[]);
diffNormColorMap(1).lim=[-inf,-2.5];
diffNormColorMap(1).color='blue3';
diffNormColorMap(2).lim=[-2.5,-1.5];
diffNormColorMap(2).color='blue2';
diffNormColorMap(3).lim=[-1.5,-0.5];
diffNormColorMap(3).color='blue1';
diffNormColorMap(4).lim=[-0.5,0.5];
diffNormColorMap(4).color='';
diffNormColorMap(5).lim=[0.5,1.5];
diffNormColorMap(5).color='red1';
diffNormColorMap(6).lim=[1.5,2.5];
diffNormColorMap(6).color='red2';
diffNormColorMap(7).lim=[2.5,inf];
diffNormColorMap(7).color='red3';

diffColorMap(7)=struct('lim',[],'color',[]);
diffColorMap(1).lim=[-inf,-0.50];
diffColorMap(1).color='blue3';
diffColorMap(2).lim=[-.50,-0.30];
diffColorMap(2).color='blue2';
diffColorMap(3).lim=[-0.30,-0.1];
diffColorMap(3).color='blue1';
diffColorMap(4).lim=[-0.1,0.1];
diffColorMap(4).color='';
diffColorMap(5).lim=[0.1,0.3];
diffColorMap(5).color='red1';
diffColorMap(6).lim=[0.3,0.5];
diffColorMap(6).color='red2';
diffColorMap(7).lim=[0.5,inf];
diffColorMap(7).color='red3';


%Categories
for idS=1:1:4
  %Amplitude
  idx=idx+1;
  varMap(idx).symbol=sprintf('<%iA>',idS);
  if(dataSet.group(idS).amplitudeLo > 0.009)
    varMap(idx).str=sprintf('%1.2f',dataSet.group(idS).amplitudeLo);
  else
    varMap(idx).str=sprintf('%1.3f',dataSet.group(idS).amplitudeLo);
  end

  %Bandwidth
  idx=idx+1;  
  varMap(idx).symbol=sprintf('<%iB>',idS);
  varMap(idx).str=sprintf('%1.0f',dataSet.group(idS).bandwidthHz);
end

%Correlations
for idS=1:1:4
  %rho 50 S-F
  idx=idx+1;  
  varMap(idx).symbol=sprintf('<%irho50SF>',idS); 
  value = dataSetStats.corrS(idS).corrMedian_rho(idCS);
  str   = sprintf('%1.2f',value);
  str   = applyColorMapToLaTeXTableEntry(str,value, corrColorMap);
  varMap(idx).str=str;
  assert(contains(dataSetStats.corrS(idS).vars{idCS},'storage'));

  %rho S-F
  idx=idx+1;    
  varMap(idx).symbol=sprintf('<%irhoSF>',idS);
  value = dataSetStats.corrS(idS).corr_rho(idCS);
  str   = sprintf('%1.2f',value);
  str   = applyColorMapToLaTeXTableEntry(str,value, corrColorMap);
  varMap(idx).str=str;

  %rho 50 L-F
  idx=idx+1;  
  varMap(idx).symbol=sprintf('<%irho50LF>',idS);
  value = dataSetStats.corrS(idS).corrMedian_rho(idCL);
  str   = sprintf('%1.2f',value);
  str   = applyColorMapToLaTeXTableEntry(str,value,corrColorMap);
  varMap(idx).str=str;
  assert(contains(dataSetStats.corrS(idS).vars{idCL},'loss'));

  %rho L-F
  idx=idx+1;  
  varMap(idx).symbol=sprintf('<%irhoLF>',idS);
  value = dataSetStats.corrS(idS).corr_rho(idCL);
  str   = sprintf('%1.2f',value);
  str   = applyColorMapToLaTeXTableEntry(str,value,corrColorMap);  
  varMap(idx).str=str;      
end

%Differences
idLSet=[1,7];
for idS=1:1:4
  for idxLSet=1:1:length(idLSet)
    idL=idLSet(idxLSet);

    idx=idx+1;  
    varMap(idx).symbol=sprintf('<%idiffSFAtL%i>',idS,idL); 
    value = dataSetStats.diffSL(idS,idL).diffMedian(idCS);
    str   = sprintf('%1.2f',value);
    str   = applyColorMapToLaTeXTableEntry(str,value, diffColorMap);
    varMap(idx).str=str;
    assert(contains(dataSetStats.corrS(idS).vars{idCS},'storage'));    

    idx=idx+1;  
    varMap(idx).symbol=sprintf('<%idiffSFWAtL%i>',idS,idL); 
    value = dataSetStats.diffSL(idS,idL).diffMedianNorm(idCS);
    str   = sprintf('%1.2f',value);
    str   = applyColorMapToLaTeXTableEntry(str,value, diffNormColorMap);
    varMap(idx).str=str;
    assert(contains(dataSetStats.corrS(idS).vars{idCS},'storage'));    

    idx=idx+1;  
    varMap(idx).symbol=sprintf('<%idiffLFAtL%i>',idS,idL); 
    value = dataSetStats.diffSL(idS,idL).diffMedian(idCL);
    str   = sprintf('%1.2f',value);
    str   = applyColorMapToLaTeXTableEntry(str,value, diffColorMap);
    varMap(idx).str=str;
    assert(contains(dataSetStats.corrS(idS).vars{idCL},'loss'));    

    idx=idx+1;  
    varMap(idx).symbol=sprintf('<%idiffLFWAtL%i>',idS,idL); 
    value = dataSetStats.diffSL(idS,idL).diffMedianNorm(idCL);
    str   = sprintf('%1.2f',value);
    str   = applyColorMapToLaTeXTableEntry(str,value, diffNormColorMap);
    varMap(idx).str=str;
    assert(contains(dataSetStats.corrS(idS).vars{idCL},'loss'));    


  end
end


tableTemplate=readlines(fullfile(projectFolders.output600A_tables,...
  'impedance_length_relation_larb','tbl_zl_fl_template.tex'));



fidTable=fopen(fullfile(projectFolders.output600A_tables,...
  'impedance_length_relation_larb','tbl_zl_fl.tex'),'w');

for i=1:1:size(tableTemplate)
  lineText=tableTemplate{i};
  for j=1:1:length(varMap)
    if(contains(lineText,varMap(j).symbol))
      lineText=strrep(lineText,varMap(j).symbol,varMap(j).str);
    end
  end
  fprintf(fidTable,'%s\n',lineText);
end

fclose(fidTable);
success=1;

