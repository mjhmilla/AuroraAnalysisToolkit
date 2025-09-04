function figH = addStressStrainModulusPlot600A(...
                            figH,...
                            subPlotPanel,...
                            subPlotRow,...
                            subPlotCol,...
                            lineColors,...
                            dataX,...
                            dataY,...
                            dataYAnnotation,...
                            dataLegendEntry,...
                            fiberProperties,...                            
                            refRatMuscleDataSeries,...
                            refRatMuscleNormalizationData,...
                            typeOfData)

figure(figH);
subPlotH = subplot('Position', ...
            reshape(subPlotPanel(subPlotRow,subPlotCol,:),1,4)); 

markerSize = 3;



%Add force length data from this experiment
if(strcmp(typeOfData,'ss-exp') && isempty(dataX)==0)
    yyaxis left;
    ax = gca;
    ax.YColor = [0,0,0];    

    dataYkPa = dataY.*0.001;

    


    plot(dataX(:,1),...
         dataYkPa,'sq','Color',[0,0,0],...
         'MarkerSize',markerSize*2,...
         'MarkerFaceColor',...
         [0,0,0],'DisplayName',dataLegendEntry);
    hold on;

    for i=1:1:length(dataX)
        text(dataX(i,1),dataYkPa(i,1),...
             [' ',dataYAnnotation{i}],...
             'FontSize',8,...
             'VerticalAlignment','bottom',...
             'HorizontalAlignment','left');
        hold on;
    end    

    if(sum(isnan(dataYkPa))==0)
        yRangeNorm = abs(diff(dataYkPa))/mean(dataYkPa);
        if(yRangeNorm > 1e-2)
            yticks((sort(dataYkPa)));
        end 
        ylim([0,1.1*max(dataYkPa)]);        
    end

    if(sum(isnan(dataX))==0)
        xRangeNorm = abs(diff(dataX))/mean(dataX);
        if(xRangeNorm > 1e-2)
            xticks((sort(dataX)));
        end    
    end

    box off;
    hold on;

      
end

%Add stiffness length data from this experiment
if(strcmp(typeOfData,'em-exp'))
    yyaxis right;
    ax = gca;
    ax.YColor = lineColors.blue;    
    
    dataYMPa = dataY.*(1e-6);

    plot(dataX(:,1),...
         dataYMPa(:,1),'sq','Color',lineColors.blue,...
         'MarkerSize',markerSize*2,...
         'MarkerFaceColor',...
         lineColors.blue,'DisplayName',dataLegendEntry);
    hold on;

    for i=1:1:length(dataX)
        text(dataX(i,1),dataYMPa(i,1),...
             [dataYAnnotation{i},' '],...
             'FontSize',8,...
             'VerticalAlignment','top',...
             'HorizontalAlignment','right');
        hold on;
    end

    yticks((sort(dataYMPa)));
    ylabel('Elastic Modulus (MPa)');

    ylim([0,1.1*max(dataYMPa)]);
    box off;
    hold on;

end

if(strcmp(typeOfData,'ss-exp') && isempty(refRatMuscleDataSeries)==0)

    activeForceLengthData = [];
    
    for i=1:1:length(refRatMuscleDataSeries.activeForceLengthData)
      activeForceLengthData = [...
          activeForceLengthData;...
          refRatMuscleDataSeries.activeForceLengthData(i).x,...
          refRatMuscleDataSeries.activeForceLengthData(i).y];
    end
    
    passiveForceLengthData = [];
    
    for i=1:1:length(refRatMuscleDataSeries.passiveForceLengthData)
      passiveForceLengthData = [...
          passiveForceLengthData;...
          refRatMuscleDataSeries.passiveForceLengthData(i).x,...
          refRatMuscleDataSeries.passiveForceLengthData(i).y];
    end
    
    %
    %Strain
    %
    activeForceLengthData(:,1) = activeForceLengthData(:,1) ...
        ./refRatMuscleNormalizationData.optimalSarcomereLength;
    
    activeStrainData(:,1) = activeForceLengthData(:,1)-1;

    passiveForceLengthData(:,1) = passiveForceLengthData(:,1) ...
        ./refRatMuscleNormalizationData.optimalSarcomereLength;

    passiveStrainData(:,1) = passiveForceLengthData(:,1)-1;

    %
    % Stress
    %
    stressAtLceOpt = fiberProperties.stressAtLceOpt;
    areaAtLceOptMM = fiberProperties.areaAtLceOptMM;

    activeForceLengthData(:,2) = activeForceLengthData(:,2).*stressAtLceOpt;
    passiveForceLengthData(:,2) = passiveForceLengthData(:,2).*stressAtLceOpt;

    for i=1:1:size(activeForceLengthData,1)
        lceNorm = activeForceLengthData(i,1);
        lceMM   = lceNorm*fiberProperties.lceOptMM;
    
        areaMM  = fiberProperties.volumeAtLceOptMM / lceMM;   
        stressScaling = areaAtLceOptMM / areaMM ;
        activeForceLengthData(i,2) = activeForceLengthData(i,2)/areaMM;       
    end
    for i=1:1:size(passiveForceLengthData,1)
        lceNorm = passiveForceLengthData(i,1);
        lceMM   = lceNorm*fiberProperties.lceOptMM;
    
        areaMM  = fiberProperties.volumeAtLceOptMM / lceMM;        
        stressScaling = areaAtLceOptMM / areaMM ;

        passiveForceLengthData(i,2) = passiveForceLengthData(i,2)/areaMM;       
    end


    activeForceLengthData(:,2) =...
        activeForceLengthData(:,2)./max(activeForceLengthData(:,2));
    activeForceLengthData(:,2) = activeForceLengthData(:,2) .* fiberProperties.stressAtLceOpt;

    passiveForceLengthData(:,2) =...
        passiveForceLengthData(:,2)./max(activeForceLengthData(:,2));
    passiveForceLengthData(:,2) = passiveForceLengthData(:,2) .* fiberProperties.stressAtLceOpt;
    %
    % Plot
    %
    yyaxis left;
    ax = gca;
    ax.YColor = [0,0,0];

    plot(activeStrainData(:,1),...
         activeForceLengthData(:,2)./1000,...
         'o','Color',[1,1,1].*0.75,...
         'MarkerSize',markerSize,...
         'MarkerFaceColor',[1,1,1].*0.75,...
         'DisplayName','SW1982 (scaled)');
    hold on;
    
%     plot(passiveStrainData(:,1),...
%          passiveForceLengthData(:,2),...
%          'x','Color',[1,1,1].*0.5,...
%          'MarkerSize',markerSize,...
%          'MarkerFaceColor',[1,1,1],...
%          'DisplayName','SW1982 (pas)');
    xlim([-0.51,0.61]);
    xticks([-0.5:0.1:0.6]);
    ylim([0,max(activeForceLengthData(:,2)./1000)*1.1]);
    box off;
    hold on;

    legend('Location','south');
    legend box off;
    if(fiberProperties.normalize==1)
        xlabel('Strain ($$\ell/\ell_o - 1$$)');
        ylabel('Stress (kPA)');
        title('Stress-Strain-Elastic-Modulus Relation');
    else
        xlabel('Strain ($$\ell/\ell_o - 1$$)');
        ylabel('Stress (kPA)');
        title('Ignore: data is not normalized');
    end
end