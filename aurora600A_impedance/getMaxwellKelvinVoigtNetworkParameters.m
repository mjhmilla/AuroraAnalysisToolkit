function params = getMaxwellKelvinVoigtNetworkParameters(paramsIn, settings)

if(settings.applyParameterMap==1)
    params = settings.defaultParameters;
    
    for i=1:1:length(paramsIn)
        row = settings.parameterMap(i,1);
        col = settings.parameterMap(i,2);
        params(row,col) = paramsIn(i,1);
    end

else
    params=paramsIn;
end