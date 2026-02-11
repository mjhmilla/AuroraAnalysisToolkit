function delay = calcPhaseDelayOfThinElasticRod(...
                    frequencyHz,gain,phase,...
                    lengthMM,...
                    experimentJson,mm2m)

k = nan;
m = nan;
l = nan;

if(strcmp(experimentJson.experiment.specimen,'Spring'))
    springK = mean(gain); %In units of mN/mm or N/m
    springL_MM = mean(lengthMM); %mm
    springL = springL_MM * mm2m;
    coilGap = springL/experimentJson.experiment.number_of_coils;
    
    coilDiameter_MM = ...
        (experimentJson.experiment.width_mm ...
        +experimentJson.experiment.height_mm)*0.5;
    coilDiameter = coilDiameter_MM * mm2m;
    
    coilL = sqrt((pi*coilDiameter)^2 + coilGap^2);
    wireL = coilL*experimentJson.experiment.number_of_coils;
    wireDiameter_MM = experimentJson.experiment.wire_diameter_mm;
    wireDiameter = wireDiameter_MM*mm2m;
    wireA = pi*(wireDiameter*0.5)^2;
    wireV = wireL * wireA;
    wireM = wireV * experimentJson.experiment.rho_kg_m3;

    k = springK;
    m = wireM;
    l = springL;
elseif(strcmp(experimentJson.experiment.material,'muscle'))
    %Smooth out the gain signal
    df = min(diff(frequencyHz));
    omega = 1/(0.5*df);
    [b,a]=butter(2,0.1);
    gain1 = filtfilt(b,a,gain);
   
    %Set k to be the average of the lowest quarter of the data available
    %for fitting
    idxMax = max(round(length(gain1)*0.25),1);
    k = max(mean(gain1([1:1:idxMax]')), sqrt(eps));
    aMM2      = (pi/4)*(experimentJson.experiment.width_mm...
                       *experimentJson.experiment.height_mm);
    volumeMM3 = mean(lengthMM)*aMM2;
    m = volumeMM3*(mm2m*mm2m*mm2m)*experimentJson.experiment.rho_kg_m3;
    l = mean(lengthMM)*mm2m;


    flag_debug=0;
    if(flag_debug==1)
        figTest=figure;
        plot(frequencyHz,gain,'-','Color',[1,1,1].*0.5);
        hold on;
        plot(frequencyHz,gain1,'-','Color',[0,0,1].*0.5);
        hold on;        
        plot([frequencyHz(1,1),frequencyHz(idxMax,1)],...
             [k,k],'--','Color',[1,0,1].*0.5);
        hold on;        
        
        xlabel('Frequency (Hz)');
        ylabel('Gain (mN/mm)');
        here=1;
    end
else
    assert(0,'Error: unrecognized material')
end


v = l*sqrt(k/m);
delay = l/v;