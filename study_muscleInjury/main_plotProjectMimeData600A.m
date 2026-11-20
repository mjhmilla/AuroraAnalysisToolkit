clc;
close all;
clear all;


rootDir         = getRootProjectDirectory();
projectFolders  = getProjectFolders(rootDir);

addpath(projectFolders.aurora610A);
addpath(projectFolders.aurora600A);

addpath(projectFolders.common);
addpath(projectFolders.postprocessing);

folder600A = fullfile(projectFolders.data_600A,'20250602');


flag_readDataOnly = 1;

%%
% Plot configuration
%%
numberOfHorizontalPlotColumnsGeneric    = 3;
numberOfVerticalPlotRowsGeneric         = 2;
plotWidth                               = [8,8,8];
plotHeight                              = [4;8];
plotHorizMarginCm                       = 3;
plotVertMarginCm                        = 3;
baseFontSize                            = 12;

[subPlotPanelGeneric, pageWidthGeneric,pageHeightGeneric]= ...
  plotConfigGeneric(  numberOfHorizontalPlotColumnsGeneric,...
                      numberOfVerticalPlotRowsGeneric,...
                      plotWidth,...
                      plotHeight,...
                      plotHorizMarginCm,...
                      plotVertMarginCm,...
                      baseFontSize); 


%%
% Muscle-fiber experiments
%%

dirFiles = dir(folder600A);

n           = [0:(1/4):1]';

lineColors   = zeros(length(n),3);
lineColorsA  = zeros(length(n),3);
lineColorsB  = zeros(length(n),3);

axisColorA = [1,   0,   0];
axisColorB = [0,   0,   1];

for i=1:1:length(n)
    lineColorsA(i,:) =[1,0.75,0.75].*(1-n(i,1)) ...
                    + [1,   0,   0].*(n(i,1));

    lineColorsB(i,:) =[0.75,0.75,1].*(1-n(i,1)) ...
                    + [0,   0,   1].*(n(i,1));
    lineColors(i,:)  = [0,0,0].*(1-n(i,1)) ...
                      +[0.75,0.75,0.75].*n(i,1);
    
end


config(5)=struct('fileName','','row',0,'col',0,...
                 'lineColor',[0,0,0],'lineThickness',1,...
                 'displayName','','addLegend',0,'stimulationNumber',0);

idxSampleFmaxLopt=1;

idx=1;
config(idx).fileName = '01_isometric_10Lo_2025602.dat';
config(idx).row = [1;2];
config(idx).col = [2;2];
config(idx).lineColors = [lineColors(idx,:);...
                          lineColors(idx,:)];
config(idx).lineThickness = 1;
config(idx).displayName = ['Pre-injury (',num2str(idx),')'];
config(idx).handleVisibility = 'on';
config(idx).addLegend = 0;
config(idx).stimulationCount = idx;

idx=idx+1;

config(idx).stimulationCount = 3;
config(idx).fileName = '02_FrequencyTests_10Lo_2025602.dat';
config(idx).row = [1;2];
config(idx).col = [2;2];
config(idx).lineColors = [lineColors(idx,:);...
                          lineColors(idx,:)];
config(idx).lineThickness = 1;
config(idx).displayName = ['Pre-injury (',num2str(config(idx).stimulationCount),')'];
config(idx).handleVisibility = 'on';
config(idx).addLegend = 0;

idx=idx+1;
config(idx).stimulationCount = 5;
config(idx).fileName = '11_isometric_10Lo_2025602.dat';
config(idx).row = [1;2];
config(idx).col = [2;2];
config(idx).lineColors = [lineColors(idx,:);...
                          lineColors(idx,:)];
config(idx).lineThickness = 1;
config(idx).displayName = ['Pre-injury ',num2str(config(idx).stimulationCount)];
config(idx).handleVisibility = 'on';
config(idx).addLegend = 0;

idx=idx+1;
config(idx).stimulationCount = 6;
config(idx).fileName = '12_0_injury_10Lo_2025602.dat';
config(idx).row = [1;2];
config(idx).col = [1;1];
config(idx).lineColors = [lineColorsA(2,:);...
                          lineColorsA(2,:)];
config(idx).lineThickness = 1;
config(idx).displayName = 'Injury 1';
config(idx).handleVisibility = 'on';
config(idx).addLegend = 0;
config(idx).stimulationCount = 6;


idx=idx+1;
config(idx).fileName = '13_0_isometric_10Lo_2025602.dat';
config(idx).row = [1;2];
config(idx).col = [2;2];
config(idx).lineColors = [lineColorsA(2,:);...
                          lineColorsA(2,:)];
config(idx).lineThickness = 1;
config(idx).displayName = 'Post-injury 1';
config(idx).handleVisibility = 'on';
config(idx).addLegend = 0;
config(idx).stimulationCount = 7;

idx=idx+1;
config(idx).fileName = '12_1_injury_10Lo_2025602.dat';
config(idx).row = [1;2];
config(idx).col = [1;1];
config(idx).lineColors = [lineColorsA(3,:);...
                          lineColorsA(3,:)];
config(idx).lineThickness = 1;
config(idx).displayName = 'Injury 2';
config(idx).handleVisibility = 'on';
config(idx).addLegend = 1;
config(idx).stimulationCount = 8;

idx=idx+1;
config(idx).fileName = '13_1_isometric_10Lo_2025602.dat';
config(idx).row = [1;2];
config(idx).col = [2;2];
config(idx).lineColors = [lineColorsA(3,:);...
                          lineColorsA(3,:)];
config(idx).lineThickness = 1;
config(idx).displayName = 'Post-injury 2';
config(idx).handleVisibility = 'on';
config(idx).addLegend = 1;
config(idx).stimulationCount = 9;


idx=idx+1;
config(idx).fileName = 'injury_02_FrequencyTests_10Lo_2025602.dat';
config(idx).row = [1;2];
config(idx).col = [3;3];
config(idx).lineColors = [lineColorsA(3,:);...
                          lineColorsA(3,:)];
config(idx).lineThickness = 1;
config(idx).displayName = 'Injury 2';
config(idx).handleVisibility = 'on';
config(idx).addLegend = 1;


fig=figure;

for i=1:1:numberOfVerticalPlotRowsGeneric
    for j=1:1:numberOfHorizontalPlotColumnsGeneric
        subplot('Position',reshape(subPlotPanelGeneric(i,j,:),1,4));
        here=1;
    end
end

fmax = 0;
lopt = 0;

keyWords = [{'isometric'},{'injury'},{'FrequencyTests'}];
dataTypes = [1,2,3];

for idx = 1:1:length(config)
    
    dataType = -1;

    for i=1:1:length(keyWords)
        i0 = strfind(config(idx).fileName ,keyWords{i});
        if(isempty(i0)==0)
           dataType = dataTypes(1,i); 
        end
    end

    file600A   = fullfile(folder600A,...
                 config(idx).fileName );
    
    % Read in the file     
    fprintf('%s\treading...\n',config(idx).fileName);
    flag_readHeader=1;
    time0=tic;
    datData = readAuroraData600A(file600A,flag_readHeader);
    time1=toc(time0);

    %Extract the time in Bath 3: activation
    startTime = 0;
    endTime = 0;
    for i=1:1:length(datData.Test_Protocol.Control_Function.Value)
        cf = datData.Test_Protocol.Control_Function.Value{i};
        opt = datData.Test_Protocol.Options.Value{i};
        arg1='';
        if(isempty(opt)==0)
            i1 = strfind(opt,' ');
            arg1 = str2double(opt(1,1:i1));
        end

        if(strcmp(cf,'Bath') && arg1 == 3)
            startTime = datData.Test_Protocol.Time.Value(i,1);
        end

        if(strcmp(cf,'Data-Disable'))
            endTime = datData.Test_Protocol.Time.Value(i,1);
        end
    end

    assert(strcmp(datData.Data.Time.Unit,'ms'),...
            'Error: expected the time unit to be ms' );
    idx0=nan;
    idx1=nan;
    if(strcmp(datData.Data.Time.Unit,'ms'))
        idx0 = floor(startTime*0.001...
                    *datData.Setup_Parameters.A_D_Sampling_Rate.Value );
        idx1 = floor((endTime)*0.001...
                    *datData.Setup_Parameters.A_D_Sampling_Rate.Value);...  
        idx1 = min([idx1,length(datData.Data.Time.Values)]);
    end

    if(idxSampleFmaxLopt==idx)
        lopt = mean(datData.Data.Lin.Values(idx0:idx1,1));
        fmax = max(datData.Data.Fin.Values(idx0:idx1,1));
    end    
    
    col=config(idx).col(1,1); 
    switch col
        case 1
            plotLabel ={'A.','B.'};
        case 2
            plotLabel ={'C.','D.'};
        case 3
            plotLabel ={'E.','F.'};
    end

    tmin = datData.Data.Time.Values(idx0,:) .*(0.001);
    tmax = datData.Data.Time.Values(idx1,:) .*(0.001);

    % Plot the specimen length
    figure(fig);
    subplot('Position', reshape(...
             subPlotPanelGeneric(config(idx).row(1,1),...
                                 config(idx).col(1,1),:),1,4));

    plot(datData.Data.Time.Values(idx0:idx1,:) .*(0.001),...
         datData.Data.Lin.Values(idx0:idx1,:) .*(1/lopt),...
         '-',...
         'Color',config(idx).lineColors(1,:),...
         'LineWidth',config(idx).lineThickness,...
         'DisplayName',config(idx).displayName,...
         'HandleVisibility',config(idx).handleVisibility );
    hold on;

    xlabel(['Time (s)']);
    ylabel(['Norm. Length ($$\ell/\ell^M_o$$)']);
    box off;
    
    if(config(idx).addLegend == 1)
        legend('Location','NorthWest');
        legend box off;
    end

    switch dataType
        case 1
            xlim([tmin,tmax]);
            ylim([0,1.5]);
            yticks([0,1,1.5]);
            title([plotLabel{1},' Isometric Trial at $$\ell^M_o$$']);
        case 2
            xlim([tmin,tmax]);            
            ylim([0,1.5]);
            xlim([80.5,81.7]);
            yticks([0,1,1.5]);
            title([plotLabel{1},' Active Lengthening Injury Trial']);
            
        case 3
            xlim([tmin,tmax]);            
            ylim([0,1.2]);            
            title([plotLabel{1},' Isometric Trial across $$f^L(\ell^M_o)$$']);
            
        otherwise
            assert(0,'Error: invalid dataType');
    end

    ax = gca;
    ax.TitleHorizontalAlignment = 'left';


    %Plot the specimen force
    subplot('Position', reshape(...
             subPlotPanelGeneric(config(idx).row(2,1),...
                                 config(idx).col(2,1),:),1,4));


    plot(datData.Data.Time.Values(idx0:idx1,:) .*(0.001),...
         datData.Data.Fin.Values(idx0:idx1,:) .* (1/fmax),...
         '-',...
         'Color',config(idx).lineColors(1,:),...
         'LineWidth',config(idx).lineThickness,...
         'DisplayName',config(idx).displayName,...
         'HandleVisibility',config(idx).handleVisibility );
    hold on;

    xlabel(['Time (s)']);
    ylabel(['Norm. Force ($$f/f^M_o$$)']);
    title(plotLabel{2});
    box off;

    switch dataType
        case 1
            xlim([tmin,tmax]);            
            ylim([0,1.2]);
            yticks([0,0.64,0.83,1]);
        case 2
            xlim([tmin,tmax]);            
            ylim([0,3.7]);
            xlim([80.5,81.7]);
            yticks([1,3.68]);
        case 3
            xlim([tmin,tmax]);            
            ylim([0,1.2]);            
        otherwise
            assert(0,'Error: invalid dataType');
    end
    
    if(config(idx).addLegend == 1)
        legend('Location','NorthWest');
        legend box off;
    end


    ax = gca;
    ax.TitleHorizontalAlignment = 'left';



    here=1;

end

fig=configPlotExporter(fig, pageWidthGeneric, pageHeightGeneric);

fileName =    'fig_fiberActiveLengtheningInjury.pdf';
print('-dpdf', fullfile(projectFolders.output_plots,fileName));



