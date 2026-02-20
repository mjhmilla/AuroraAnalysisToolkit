function response = calcMaxwellKelvinVoigtNetworkImpedance(...
                                    omega,paramsIn,settings)


params = getMaxwellKelvinVoigtNetworkParameters_upd(paramsIn, settings);

z = complex(0,0);
ziInv = complex(0,0);

lastBranch=nan;


for i=1:1:size(params,1)
    
    branchNo = params(i,1);

    if(isnan(lastBranch))
        lastBranch = branchNo;
    end
    
    A = params(i,2);
    B = params(i,3);
    C = params(i,4);
    D = params(i,5);

    if(abs(A)<eps && abs(B)<eps && abs(C)<eps && abs(D)<eps)
        zj = 0;
    elseif(abs(C)<eps && abs(D)<eps)
        zj = (A + (B*complex(0,1)).*omega  );
    elseif(abs(A)<eps && abs(B)<eps)
        zj = 0;    
    else
        zj = (A + (B*complex(0,1)).*omega  ) ...
            ./(C + (D*complex(0,1)).*omega );
    end
    
    if(lastBranch == branchNo)
        if(i==size(params,1))
            ziInv = ziInv + 1./zj;
            zi = 1./ziInv;
            z = z + zi;
        else
            ziInv = ziInv + 1./zj;
        end
    elseif(lastBranch ~= branchNo)
        %If were on a new branch, then add the impedance of the last 
        %branch to the total impedance z. Start accumulating the admittance
        %starting with zj.       
        if(i==size(params,1))
            zi      = 1./ziInv;
            z       = z + zi + zj;  
        else
            zi      = 1./ziInv;
            z       = z + zi;        
            ziInv   = 1./zj;
        end        
    end


    lastBranch = branchNo;

end
response.frequency = omega;
response.frequencyHz = omega./(2*pi);
response.gain      = abs(z);
response.phase     = angle(z);
response.storage   = real(z);
response.loss      = imag(z);