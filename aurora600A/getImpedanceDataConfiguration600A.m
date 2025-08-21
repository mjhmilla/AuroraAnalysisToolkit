function config = getImpedanceDataConfiguration600A(folderName, ...
                                                    purturbationType,...
                                                    trialNameKeywords,...
                                                    trialColumns,...
                                                    lineColors,...
                                                    projectFolders)


nFiles = length(trialNameKeywords);
config(nFiles)=struct('fileName','','normLength',0);

dataFiles = dir(folderName);



for i=1:1:length(trialNameKeywords)

    found=0;
    idxFileName = 0;
    for j=1:1:length(dataFiles)
        if(dataFiles(j).isdir == 0)
            if(contains(dataFiles(j).name,trialNameKeywords{i}))
                assert(found==0,...
                    ['Error: more than one file has the keyword ', ...
                     trialNameKeywords{i},...
                     ' in ', folderName]);                    
                found=1;
                idxFileName = j;
            end
        end
    end

    assert(found==1,['Error: could not find a file that contains ',...
                     'the keyword ', trialNameKeywords{i}]);

    config(i).fileName = fullfile(dataFiles(idxFileName).folder,...
                                  dataFiles(idxFileName).name);

    k1 = strfind(dataFiles(idxFileName).name,'Lo');
    k0 = k1;
    while strcmp(dataFiles(idxFileName).name(1,k0),'_')==0
        k0 = k0-1;
    end
    k0=k0+1;
    k1=k1-1;
    config(i).normLength = str2double(dataFiles(idxFileName).name(1,k0:k1))/10;

    config(i).col = trialColumns(1,i);

    config(i).segmentLabels = [];

    k0 = strfind(dataFiles(idxFileName).name,'.');
    segmentLabelFileName = [dataFiles(idxFileName).name(1,1:(k0-1)),...
                            '_labels.csv'];

    segmentLabelFullFileName = ...
        fullfile(folderName,'segmentLabels',segmentLabelFileName);
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

    idxPassiveStochasticRamp    = 2;
    idxPassiveStochasticSine    = 4;
    idxActivation               = 6;
    idxActiveStochasticRamp     = 8;
    idxActiveStochasticSine     = 10;

    assert(strcmp(controlSeries{idxPassiveStochasticRamp},...
                    'Length-Ramp-Stochastic'),...
        'Error: expected segmentLabels have changed');     
    assert(strcmp(controlSeries{idxPassiveStochasticSine},...
                    'Length-Sine-Stochastic'),...
        'Error: expected segmentLabels have changed');    
    assert(strcmp(controlSeries{idxActivation},...
                    'Activation'),...
        'Error: expected segmentLabels have changed');
    assert(strcmp(controlSeries{idxActiveStochasticRamp},...
                    'Length-Ramp-Stochastic'),...
        'Error: expected segmentLabels have changed');
    assert(strcmp(controlSeries{idxActiveStochasticSine},...
                    'Length-Sine-Stochastic'),...
        'Error: expected segmentLabels have changed');

    switch purturbationType
        case 'sine'
            idxPassiveStochasticWave = idxPassiveStochasticSine;
            idxActiveStochasticWave = idxActiveStochasticSine;
            nameModifier = 'StochasticSine';
        case 'ramp'
            idxPassiveStochasticWave = idxPassiveStochasticRamp;
            idxActiveStochasticWave = idxActiveStochasticRamp;
            nameModifier = 'StochasticRamp';
            
        otherwise assert(0,'Error: purturbationType must be sine or ramp');
    end

    idxP = 1;
    config(i).plots(idxP).row   = 1;
    config(i).plots(idxP).yyLeftRight = 'yyaxis left';
    config(i).plots(idxP).yyLeftRightAxisColor = [0,0,0; lineColors.blue];
    config(i).plots(idxP).xField='Time';
    config(i).plots(idxP).yField='Lin';
    config(i).plots(idxP).timeInterval = []; %all
    config(i).plots(idxP).lineColor = lineColors.grey;    
    config(i).plots(idxP).lineWidth = 0.5;
    config(i).plots(idxP).xLabel = 'Time';
    config(i).plots(idxP).yLabel = 'Length';    
    config(i).plots(idxP).title  =...
        ['$$',num2str(config(i).normLength),'\ell_o$$'];
    config(i).plots(idxP).boxTimes = [timeSeries(idxPassiveStochasticWave,:);...
                                      timeSeries(idxActiveStochasticWave,:)];
    config(i).plots(idxP).boxColors = [0,0,0;...
                                       0,0,0];
    config(i).plots(idxP).impedance.analyze = 0;

    idxP=idxP+1;
    config(i).plots(idxP).row   = 1;
    config(i).plots(idxP).yyLeftRight = 'yyaxis right';    
    config(i).plots(idxP).yyLeftRightAxisColor = [0,0,0; lineColors.blue];
    config(i).plots(idxP).xField='Time';
    config(i).plots(idxP).yField='Fin';
    config(i).plots(idxP).timeInterval = []; %all
    config(i).plots(idxP).lineColor = lineColors.blue;    
    config(i).plots(idxP).lineWidth = 0.5;
    config(i).plots(idxP).xLabel = 'Time';
    config(i).plots(idxP).yLabel = 'Force';
    config(i).plots(idxP).title  = ...
        ['$$',num2str(config(i).normLength),'\ell_o$$'];
    config(i).plots(idxP).boxTimes = [];
    config(i).plots(idxP).boxColors = [];   
    config(i).plots(idxP).impedance.analyze = 0;

    idxP=idxP+1;
    config(i).plots(idxP).row   = 2;
    config(i).plots(idxP).yyLeftRight = 'yyaxis left';
    config(i).plots(idxP).yyLeftRightAxisColor = [0,0,0; lineColors.blue];
    config(i).plots(idxP).xField='Time';
    config(i).plots(idxP).yField='Lin';
    config(i).plots(idxP).timeInterval = timeSeries(idxPassiveStochasticWave,:); 
    config(i).plots(idxP).lineColor = lineColors.grey;    
    config(i).plots(idxP).lineWidth = 0.5;
    config(i).plots(idxP).xLabel = 'Time';
    config(i).plots(idxP).yLabel = 'Length';    
    config(i).plots(idxP).title  =...
        ['Box 1: $$',num2str(config(i).normLength),'\ell_o$$'];
    config(i).plots(idxP).boxTimes = [];
    config(i).plots(idxP).boxColors = [];
    config(i).plots(idxP).impedance.analyze = 0;

    idxP=idxP+1;
    config(i).plots(idxP).row   = 2;
    config(i).plots(idxP).yyLeftRight = 'yyaxis right';    
    config(i).plots(idxP).yyLeftRightAxisColor = [0,0,0; lineColors.blue];
    config(i).plots(idxP).xField='Time';
    config(i).plots(idxP).yField='Fin';
    config(i).plots(idxP).timeInterval = timeSeries(idxPassiveStochasticWave,:);
    config(i).plots(idxP).lineColor = lineColors.blue;    
    config(i).plots(idxP).lineWidth = 0.5;
    config(i).plots(idxP).xLabel = 'Time';
    config(i).plots(idxP).yLabel = 'Force';
    config(i).plots(idxP).title  = ...
        ['Box 1: $$',num2str(config(i).normLength),'\ell_o$$'];
    config(i).plots(idxP).boxTimes = [];
    config(i).plots(idxP).boxColors = [];      
    config(i).plots(idxP).impedance.analyze = 1;
    config(i).plots(idxP).impedance.isActive = 0;
    config(i).plots(idxP).impedance.xField = 'Lin';
    config(i).plots(idxP).impedance.yField = 'Fin';
    config(i).plots(idxP).impedance.xColor = lineColors.grey;
    config(i).plots(idxP).impedance.yColor = lineColors.blue;
    config(i).plots(idxP).impedance.gainColor = lineColors.blue;
    config(i).plots(idxP).impedance.phaseColor= lineColors.purple;
    config(i).plots(idxP).impedance.coherenceSqColor= [0,0,0];
    config(i).plots(idxP).impedance.nameModifier = nameModifier;

    idxP=idxP+1;
    config(i).plots(idxP).row   = 3;
    config(i).plots(idxP).yyLeftRight = 'yyaxis left';
    config(i).plots(idxP).yyLeftRightAxisColor = [0,0,0; lineColors.blue];
    config(i).plots(idxP).xField='Time';
    config(i).plots(idxP).yField='Lin';
    config(i).plots(idxP).timeInterval = timeSeries(idxActiveStochasticWave,:); 
    config(i).plots(idxP).lineColor = lineColors.grey;    
    config(i).plots(idxP).lineWidth = 0.5;
    config(i).plots(idxP).xLabel = 'Time';
    config(i).plots(idxP).yLabel = 'Length';    
    config(i).plots(idxP).title  =...
        ['Box 2: $$',num2str(config(i).normLength),'\ell_o$$'];
    config(i).plots(idxP).boxTimes = [];
    config(i).plots(idxP).boxColors = [];
    config(i).plots(idxP).impedance.analyze = 0;

    idxP=idxP+1;
    config(i).plots(idxP).row   = 3;
    config(i).plots(idxP).yyLeftRight = 'yyaxis right';    
    config(i).plots(idxP).yyLeftRightAxisColor = [0,0,0;lineColors.blue];
    config(i).plots(idxP).xField='Time';
    config(i).plots(idxP).yField='Fin';
    config(i).plots(idxP).timeInterval = timeSeries(idxActiveStochasticWave,:);
    config(i).plots(idxP).lineColor = lineColors.blue;    
    config(i).plots(idxP).lineWidth = 0.5;
    config(i).plots(idxP).xLabel = 'Time';
    config(i).plots(idxP).yLabel = 'Force';
    config(i).plots(idxP).title  = ...
        ['Box 2: $$',num2str(config(i).normLength),'\ell_o$$'];
    config(i).plots(idxP).boxTimes = [];
    config(i).plots(idxP).boxColors = [];      
    config(i).plots(idxP).impedance.analyze = 1;
    config(i).plots(idxP).impedance.isActive = 1;
    config(i).plots(idxP).impedance.xField = 'Lin';
    config(i).plots(idxP).impedance.yField = 'Fin';
    config(i).plots(idxP).impedance.xColor = lineColors.grey;
    config(i).plots(idxP).impedance.yColor = lineColors.blue;
    config(i).plots(idxP).impedance.gainColor = lineColors.blue;
    config(i).plots(idxP).impedance.phaseColor= lineColors.purple;
    config(i).plots(idxP).impedance.coherenceSqColor= [0,0,0];
    config(i).plots(idxP).impedance.nameModifier = nameModifier;
    here=1;
end