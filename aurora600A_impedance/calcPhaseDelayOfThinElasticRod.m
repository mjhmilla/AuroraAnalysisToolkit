function delay = calcPhaseDelayOfThinElasticRod(gain,length,experimentJson,mm2m)

springK = mean(gain); %In units of mN/mm or N/m
springL_MM = mean(length); %mm
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

v = springL*sqrt(springK/wireM);
delay = springL/v;