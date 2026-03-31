function config = readAuroraDataLabelFile600A(dataConfig)




nFiles = length(dataConfig.fileNameKeywords);
config(nFiles)=struct('fileName','','normLength',0);

dataFiles = dir(dataConfig.path);



for i=1:1:length(dataConfig.fileNameKeywords)

    found=0;
    idxFileName = 0;
    for j=1:1:length(dataFiles)
        if(dataFiles(j).isdir == 0)
            if(contains(dataFiles(j).name,dataConfig.fileNameKeywords{i}))
                assert(found==0,...
                    ['Error: more than one file has the keyword ', ...
                     dataConfig.fileNameKeywords{i},...
                     ' in ', dataConfig.path]);                    
                found=1;
                idxFileName = j;
            end
        end
    end

    assert(found==1,['Error: could not find a file that contains ',...
                     'the keyword ', dataConfig.fileNameKeywords{i}]);

    config(i).fileName = fullfile(dataFiles(idxFileName).folder,...
                                  dataFiles(idxFileName).name);

    k1 = strfind(dataFiles(idxFileName).name,'Lo');
    k0 = k1;
    while strcmp(dataFiles(idxFileName).name(1,k0),'_')==0
        k0 = k0-1;
    end
    k0=k0+1;
    k1=k1-1;
    config(i).normLength = ...
        str2double(dataFiles(idxFileName).name(1,k0:k1))/100;

    config(i).segmentLabels = [];

    k0 = strfind(dataFiles(idxFileName).name,'.');
    segmentLabelFileName = [dataFiles(idxFileName).name(1,1:(k0-1)),...
                            '_labels.csv'];

    segmentLabelFullFileName = ...
        fullfile(dataConfig.path,'segmentLabels',segmentLabelFileName);
    fid = fopen(segmentLabelFullFileName,'r');

    if(fid ~= -1)
        idxBlock = 0;
        line = fgetl(fid);
        controlSeries = [];
        timeSeries = [];
        while(ischar(line))
            idxComma = strfind(line,',');
            assert(length(idxComma)==2,...
                ['Error: expected 2 commas in each row of the',...
                ' segmentLabel file ',segmentLabelFullFileName]);
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
            config(i).segmentLabels(k).name = controlSeries{k,1};
            config(i).segmentLabels(k).timeInterval = timeSeries(k,:);
            config(i).segmentLabels(k).indexInterval = [nan,nan];
        end
    end
end



