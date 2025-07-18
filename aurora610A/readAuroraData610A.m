function ddfData = readAuroraData610A(fullFilePath)
%%
% This function will 
% 1. Read in the sample frequency
% 2. Read in the channel names
% 3. Read in the scale
% 4. Read in the offset
% 5. Go to Sample
%    Read in column names
% 6. Read in the data
%%

fid =fopen(fullFilePath,'r');

[line, ltout]= fgets(fid);

assert(contains(line,'DMCv5.3 Data File')==1,...
       ['Error: readAuroraData610A is compatable with DMCv5.3 Data File. ',...
         'This file is a ', line]);

[line, ltout]= fgets(fid);

idx = strfind(line,': ')+1;
ddfData.Sample_Frequency_Hz =  str2double(strtrim(line(1,idx:end)));

[line, ltout]= fgets(fid);
assert(contains(line,'Reference Area:')==1,...
          'Error Reference Area not found');

idx0 = strfind(line,':')   + 1;
str0 = strtrim(line(1,idx0:end));
sp0 = strfind(str0,' ');
idx1 =sp0(1);

ddfData.Reference_Area.value      = str2double(strtrim(str0(1,1:idx1)));
ddfData.Reference_Area.unit =    strtrim(str0(1,idx1:end));

[line, ltout]= fgets(fid);
assert(contains(line,'Reference Force:')==1,...
       'Error Reference Force not found');

idx0 = strfind(line,':')   + 1;
str0 = strtrim(line(1,idx0:end));
sp0 = strfind(str0,' ');
idx1 =sp0(1);

ddfData.Reference_Force.value      = str2double(strtrim(str0(1,1:idx1)));
ddfData.Reference_Force.unit =    strtrim(str0(1,idx1:end));

[line, ltout]= fgets(fid);
assert(contains(line,'Reference Length:')==1,...
          'Error Reference Length not found');

idx0 = strfind(line,':')   + 1;
str0 = strtrim(line(1,idx0:end));
sp0 = strfind(str0,' ');
idx1 =sp0(1);

ddfData.Reference_Length.value = str2double(strtrim(str0(1,1:idx1)));
ddfData.Reference_Length.unit  =    strtrim(str0(1,idx1:end));

[line, ltout]= fgets(fid);
assert(contains(line,'Calibration Data:')==1,...
      'Error Reference Force not found');

[line, ltout]= fgets(fid);
idx0 = strfind(line,'Channel')+7;
str0 = strtrim(line(1,idx0:end));

ddfData.Channel = parseDelimitedStringToCellArray(str0,char(9));

[line, ltout]= fgets(fid);
idx0 = strfind(line,'Units')+5;
str0 = strtrim(line(1,idx0:end));

ddfData.Units = [];

for i=1:1:length(ddfData.Channel)
    i0 = 1;
    t0 = strfind(str0,char(9));
    if(isempty(t0)==0)        
        i1 = t0(1,1);
    else
        i1 = length(str0);
    end
    
    if((i1-i0)>0)
        if(isempty(ddfData.Units)==1)
            ddfData.Units = [{strtrim(str0(1,i0:i1))}];
        else
            ddfData.Units = [ddfData.Units, {strtrim(str0(1,i0:i1))}];            
        end        
    else
        if(isempty(ddfData.Units)==1)
            ddfData.Units = [{''}];
        else
            ddfData.Units = [ddfData.Units, {''}];            
        end        
    end
    str0 = str0(1,(i1+1):end);    
end

%ddfData.Units = parseDelimitedStringToCellArray(str0,char(9));

[line, ltout]= fgets(fid);
idx0 = strfind(line,'Scale (units/V)')+15;
str0 = strtrim(line(1,idx0:end));

cellArray = parseDelimitedStringToCellArray(str0,char(9));

ddfData.Scale_units_V = zeros(size(cellArray));
for i=1:1:length(cellArray)
    ddfData.Scale_units_V(i) = str2double(cellArray{i});
end


[line, ltout]= fgets(fid);
idx0 = strfind(line,'Offset (volts)')+14;
str0 = strtrim(line(1,idx0:end));

cellArray = parseDelimitedStringToCellArray(str0,char(9));

ddfData.Offset_volts = zeros(size(cellArray));
for i=1:1:length(cellArray)
    ddfData.Offset_volts(i) = str2double(cellArray{i});
end

[line, ltout]= fgets(fid);
idx0 = strfind(line,'TADs')+4;
str0 = strtrim(line(1,idx0:end));

cellArray = parseDelimitedStringToCellArray(str0,char(9));

ddfData.TADs = zeros(size(cellArray));
for i=1:1:length(cellArray)
    ddfData.TADs(i) = str2double(cellArray{i});
end


while contains(line,'Sample') == 0
    [line, ltout]= fgets(fid);    
end

ddfData.data.columnNames = parseDelimitedStringToCellArray(line,char(9));

[line, ltout]= fgets(fid);    

ddfData.data.values = zeros(1000,length(ddfData.data.columnNames));

i=1;
while line ~= -1
    cellArray = parseDelimitedStringToCellArray(line,char(9));

    if(length(cellArray)~=length(ddfData.data.columnNames))
        here=1;
    end
    assert(length(cellArray)==length(ddfData.data.columnNames),...
          ['Error: mismatch between data column size and',...
           ' the number of column names']);
    for j=1:1:length(ddfData.data.columnNames)
        ddfData.data.values(i,j) = str2double(cellArray{j});
    end

    i=i+1;
    
    if(i==size(ddfData.data.values,1))
        ddfData.data.values = [ddfData.data.values; ...
                                zeros(size(ddfData.data.values))];
    end

    [line, ltout]= fgets(fid);        
end

i=i-1;
ddfData.data.values = ddfData.data.values(1:i,:);


here=1;


