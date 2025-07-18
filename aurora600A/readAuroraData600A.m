function datData = readAuroraData600A(fullFilePath)


fid =fopen(fullFilePath,'r');

[line, ltout]= fgets(fid);

assert(contains(line,'ASI 600A Data File')==1,...
       ['Error: readAuroraData600A is compatable with ASI 600A Data File. ',...
         'This file is a ', line]);

%%
% Read Setup Parameters
%%
[line, ltout]= fgets(fid);
while contains(line,'*** Calibration Parameters ***') == 0

    if(contains(line,'***') == 0)
        [fieldNameStr, fieldValueStr, fieldUnitStr] = ...
                    extractAuroraScalarField(line);
        
        fieldValue = str2double(fieldValueStr);
        if(isnan(fieldValue)==0)
            datData.Setup_Parameters.(fieldNameStr).value = fieldValue;
        else
            datData.Setup_Parameters.(fieldNameStr).value = fieldValueStr;
        end

        if(isempty(fieldUnitStr)==0)
            datData.Setup_Parameters.(fieldNameStr).unit = fieldUnitStr;
        else
            datData.Setup_Parameters.(fieldNameStr).unit = [];
        end
    end

    [line, ltout]= fgets(fid);
    if(line==-1)
        assert(0, 'Error: incomplete file');
    end

end

%%
% Read Calibration Parameters
%%
[line, ltout]= fgets(fid);


colNames = parseDelimitedStringToCellArray(line,'  ');

for i=1:1:length(colNames)
    datData.Calibration_Parameters.(colNames{i}).value = [];
    datData.Calibration_Parameters.(colNames{i}).unit  = [];
end

[line, ltout]= fgets(fid);

columnUnits = ...
    parseDelimitedStringToCellArray(line,' ');

assert(length(colNames)==length(columnUnits),...
       ['Error: in Calibration Parameters: mismatch between the number',...
       ' of column names and units']);

for i=1:1:length(colNames)
    datData.Calibration_Parameters.(colNames{i}).unit  = columnUnits{i};
end


[line, ltout]= fgets(fid);
while contains(line,'*** Test Protocol Parameters ***') == 0

    dataRow = parseDelimitedStringToCellArray(line,char(9));

    assert(length(dataRow)==length(colNames),...
        ['Error: in Calibration Parameters: mismatch between the number',...
         ' of column names and units']);

    for j=1:1:length(dataRow)
        dataValueStr = dataRow{j};
        dataValue = str2double(dataValueStr);

        if(isnan(dataValue)==1)
            datData.Calibration_Parameters.(colNames{j}).value = ...
                [datData.Calibration_Parameters.(colNames{j}).value;...
                 {dataValueStr}];
        else
            datData.Calibration_Parameters.(colNames{j}).value = ...
                [datData.Calibration_Parameters.(colNames{j}).value;...
                 dataValue];             
        end 

    end

    [line, ltout]= fgets(fid);
    if(line==-1)
        assert(0, 'Error: incomplete file');
    end    
end

%%
% Read Test Protocol Parameters
%%
[line, ltout]= fgets(fid);
while contains(line,'Stimulus') == 0 && contains(line,'Time (ms)') == 0 

    if(contains(line,'***') == 0)
        [fieldNameStr, fieldValueStr, fieldUnitStr] = ...
                    extractAuroraScalarField(line);
        
        fieldValue = str2double(fieldValueStr);
        if(isnan(fieldValue)==0)
            datData.Test_Protocol_Parameters.(fieldNameStr).value = fieldValue;
        else
            datData.Test_Protocol_Parameters.(fieldNameStr).value = fieldValueStr;
        end

        if(isempty(fieldUnitStr)==0)
            datData.Test_Protocol_Parameters.(fieldNameStr).unit = fieldUnitStr;
        else
            datData.Test_Protocol_Parameters.(fieldNameStr).unit = [];
        end
    end
    [line, ltout]= fgets(fid);
    if(line==-1)
        assert(0, 'Error: incomplete file');
    end        
end

%%
% Read Test Protocol commands
%%
[line, ltout]= fgets(fid);
while contains(line,'Time (ms)') == 0 
    [line, ltout]= fgets(fid);
    if(line==-1)
        assert(0, 'Error: incomplete file');
    end        
end

colNames = parseDelimitedStringToCellArray(line,char(9));
fieldNames = [];

for i=1:1:length(colNames)

    fieldNameStr = '';
    fieldUnitStr = '';

    str0 = colNames{i};
    i0 = strfind(str0,'(');
    if(isempty(i0)==0)
        i1 = strfind(str0,')');
        fieldUnitStr = strtrim(str0(1,(i0+1):(i1-1)));
        fieldNameStr = strtrim(str0(1,1:(i0-1)));        
    else
        fieldUnitStr = '';
        fieldNameStr = strtrim(str0);        
    end

    fieldNameStr = convertStringToValidStructFieldName(fieldNameStr);


    if(isempty(fieldNames)==1)
        fieldNames = [{fieldNameStr}];
    else
        fieldNames = [fieldNames,{fieldNameStr}];
    end

    datData.Test_Protocol.(fieldNameStr).value = [];
    datData.Test_Protocol.(fieldNameStr).unit = fieldUnitStr;

end

[line, ltout]= fgets(fid);
while contains(line,'*** Force and Length Signals vs Time ***') == 0 

    rowData = parseDelimitedStringToCellArray(line,char(9));

    assert(length(rowData)<=length(fieldNames),...
          ['Error: mismatch in column names and column',...
          ' data in Test Protocol Parameters']);

    valueStr = '';
    for i=1:1:length(fieldNames)
        if(i <= length(rowData))
            valueStr = rowData{i};
        else
            valueStr ='';
        end

        value = str2double(valueStr);
        if(isnan(value))
            if(isempty(datData.Test_Protocol.(fieldNames{i}).value))
                datData.Test_Protocol.(fieldNames{i}).value = ...                    
                     [{valueStr}];
            else
                datData.Test_Protocol.(fieldNames{i}).value = ...
                    [datData.Test_Protocol.(fieldNames{i}).value;...
                     {valueStr}];
            end
        else
            if(isempty(datData.Test_Protocol.(fieldNames{i}).value))
                datData.Test_Protocol.(fieldNames{i}).value = ...
                    [value];
            else
                datData.Test_Protocol.(fieldNames{i}).value = ...
                    [datData.Test_Protocol.(fieldNames{i}).value;...
                     value];
            end
        end

    end


    [line, ltout]= fgets(fid);
    if(line==-1)
        break;
    end     
end




%%
% Read Force and Length Signals vs Time
%%

%[line, ltout]= fgets(fid);
%while contains(line,'*** Force and Length Signals vs Time ***') == 0 
%    [line, ltout]= fgets(fid);
%    if(line==-1)
%        assert(0, 'Error: incomplete file');
%    end        
%end

[line, ltout]= fgets(fid);
columnNames = parseDelimitedStringToCellArray(line,'  ');
fieldNames = [];

for i=1:1:length(columnNames)

    fieldNameComplete =columnNames{i};
    fieldUnit = [];

    i0 = strfind(fieldNameComplete,'(');
    
    if(i0>0)
        i1 = strfind(fieldNameComplete,')');
        fieldName = strtrim( fieldNameComplete(1,1:(i0-1)) );
        fieldUnit = strtrim( fieldNameComplete(1,(i0+1):(i1-1)));
    else
        fieldName = fieldNameComplete;
        fieldUnit = [];
    end

    fieldName = convertStringToValidStructFieldName(fieldName);

    
    if(strcmp(fieldName,'Time'))
        maxTime = max(datData.Test_Protocol.Time.value);
        if(strcmp(fieldUnit,'ms')==1)
            maxTime = maxTime*0.001;
        end

        n = ceil(maxTime * datData.Setup_Parameters.A_D_Sampling_Rate.value);
    end


    datData.Data.(fieldName).value = zeros(n,1);
    datData.Data.(fieldName).unit =fieldUnit;

    if(i==1)
        fieldNames = [{fieldName}];
    else
        fieldNames = [fieldNames, {fieldName}];
    end
end

fmt = '%f';
for i=2:1:length(fieldNames)
    fmt = [fmt,' %f'];
end

[line, ltout]= fgets(fid);

idx = 1;
while (line ~=-1)

    %rowData = parseDelimitedStringToCellArray(line,' ');
    rowData = sscanf(line,fmt)';

    assert(length(rowData)==length(columnNames),...
           'Error: length mismatch between column names and data columns');

    for i=1:1:length(rowData)        
        %dataValue = str2double(strtrim(rowData{i}));
        if(idx > length(datData.Data.(fieldNames{i}).value))
            datData.Data.(fieldNames{i}).value = ...
                [datData.Data.(fieldNames{i}).value; ...
                 zeros(size(datData.Data.(fieldNames{i}).value))];
        end

        datData.Data.(fieldNames{i}).value(idx,1) = ...          
             rowData(1,i);        
    end

    [line, ltout]= fgets(fid);
    idx=idx+1;
    if(line==-1)
        break;
    end

end

idx=idx-1;
for i=1:1:length(fieldNames)
    datData.Data.(fieldNames{i}).value = ...
        datData.Data.(fieldNames{i}).value(1:idx,:);
end
here=1;