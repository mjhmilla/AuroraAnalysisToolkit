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

varMap(24)=struct('symbol','','str','');

idx=0;
idCS=1;
idCL=2;

corrColorMap(5)=struct('lim',[],'color',[]);
corrColorMap(1).lim=[0,0.1];
corrColorMap(1).color='red';
corrColorMap(2).lim=[0.1,0.3];
corrColorMap(2).color='darkgray';
corrColorMap(3).lim=[0.3,0.5];
corrColorMap(3).color='gray';
corrColorMap(3).lim=[0.5,0.7];
corrColorMap(3).color='lightgray';
corrColorMap(3).lim=[0.7,1.0];
corrColorMap(3).color='';


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
  
  %rho 50 S-F
  assert(0,'You are here');
  idx=idx+1;  
  varMap(idx).symbol=sprintf('<%irho50SF>',idS); 
  value = dataSetStats.corrS(idS).corrMedian_rho(idCS);
  str=sprintf('%1.2f',val);
  str = addCorrelationColorToLaTeXTable(str,value, corrColorMap);
  varMap(idx).str=str;
  assert(contains(dataSetStats.corrS(idS).vars{idCS},'storage'));

  %rho S-F
  idx=idx+1;  
  varMap(idx).symbol=sprintf('<%irhoSF>',idS);
  varMap(idx).str=sprintf('%1.2f',dataSetStats.corrS(idS).corr_rho(idCS));

  %rho 50 L-F
  idx=idx+1;  
  varMap(idx).symbol=sprintf('<%irho50LF>',idS);
  varMap(idx).str=sprintf('%1.2f',dataSetStats.corrS(idS).corrMedian_rho(idCL));
  assert(contains(dataSetStats.corrS(idS).vars{idCL},'loss'));

  %rho L-F
  idx=idx+1;  
  varMap(idx).symbol=sprintf('<%irhoLF>',idS);
  varMap(idx).str=sprintf('%1.2f',dataSetStats.corrS(idS).corr_rho(idCL));
  
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

