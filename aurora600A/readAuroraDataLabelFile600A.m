function config = readAuroraDataLabelFile600A(fullFilePath)





config.fileName = fullFilePath;

config.segmentLabels = [];

fid = fopen(fullFilePath,'r');

if(fid ~= -1)
    idxBlock = 0;
    line = fgetl(fid);
    controlSeries = [];
    timeSeries = [];
    while(ischar(line))
        idxComma = strfind(line,',');
        assert(length(idxComma)==2,...
            ['Error: expected 2 commas in each row of the',...
            ' segmentLabel file ',fullFilePath]);
        controlFunction = line(1,1:(idxComma(1)-1));
        time0 = str2double(line(1, (idxComma(1)+1):(idxComma(2)-1) ));
        time1 = str2double(line(1, (idxComma(2)+1):end ));
        if(isempty(controlSeries))
            controlSeries = [{controlFunction}];
            timeSeries = [time0,time1];
        else
            controlSeries = [controlSeries; {controlFunction}];
            timeSeries = [timeSeries; time0,time1];
        end
        idxBlock = idxBlock+1;
        line=fgetl(fid);

    end
    fclose(fid);
    here=1;

    for k=1:1:idxBlock
        config.segmentLabels(k).name = controlSeries{k,1};
        config.segmentLabels(k).timeInterval = timeSeries(k,:);
        config.segmentLabels(k).indexInterval = [nan,nan];
    end
end



