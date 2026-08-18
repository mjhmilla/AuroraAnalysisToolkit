function [networkComponentImpedanceParams, modelParams] = ...
          getMaxwellKelvinVoigtNetworkParameters(paramsIn, settings)

modelParams = settings.defaultParameters;

if(settings.applyParameterMap==1)

    assert(length(paramsIn)==size(settings.parameterMap,1));        
    %
    % Update the spring and damper coefficients in the default network
    % component parameter network
    %
    for i=1:1:length(paramsIn)
      indexBranch = settings.parameterMap(i,1);
      componentId = settings.parameterMap(i,2);
      eleType     = settings.parameterMap(i,3);

      %Go and find the correct entry in params and update the parameter
      for j=1:1:size(modelParams,1)
        if(modelParams(j,1)==indexBranch && modelParams(j,2)==componentId)
          switch eleType
            case settings.elementTypes.spring
              modelParams(indexBranch,eleType)= paramsIn(i);
            case settings.elementTypes.damper
              modelParams(indexBranch,eleType)= paramsIn(i);            
            otherwise
              assert(0,'Error: unrecognized element type');
          end
        end
      end
    end
end

%
% Evaluate the network component impedance parameter values. Each 
% component is located at a particular serial branch with an index of
% indexB, and has an impedance described by these coefficients 
% (A,B,C,D)
%
% z = (A + B*complex(0,omega))/(C + D*complex(0,omega))
%
% These coefficients are packed into a single row:
% [indexB, A,B,C,D]
%
networkComponentImpedanceParams = zeros(size(modelParams,1),5);
networkComponentImpedanceParams(:,1)=modelParams(:,1);
for i=1:1:size(modelParams,1)
  k     = modelParams(i,settings.elementTypes.spring);
  beta  = modelParams(i,settings.elementTypes.damper);

  switch modelParams(i,3)
    case settings.modelTypes.KelvinVoigt  
      % z = (A +    B*complex(0,omega))/(C + D*complex(0,omega))
      % z = (k + beta*complex(0,omega))/(1 + 0*complex(0,omega))
      networkComponentImpedanceParams(i,2)=k;    %A
      networkComponentImpedanceParams(i,3)=beta; %B
      networkComponentImpedanceParams(i,4)=1;    %C
      networkComponentImpedanceParams(i,5)=0;    %D
      
    case settings.modelTypes.Maxwell
      % z = (A +    B*complex(0,omega))/(C + D*complex(0,omega))          
      % z = (0 + k*beta*complex(0,omega)/(k + beta*complex(0,omega))
      networkComponentImpedanceParams(i,2)=0;      %A
      networkComponentImpedanceParams(i,3)=k*beta; %B
      networkComponentImpedanceParams(i,4)=k;      %C
      networkComponentImpedanceParams(i,5)=beta;   %D
      
    otherwise
      assert(0,'Error: unrecognized model type');
  end
end