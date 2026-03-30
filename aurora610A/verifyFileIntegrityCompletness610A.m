function output = verifyFileIntegrityCompletness610A(...
                  dataPath,...
                  dataSha256Sum,...
                  protocolPath)

output.sha256_verified=0;
output.protocol_exists=0;
output.comment = '';
output.sha256 = '';

%%
%Check the sha256sum
%%

[status,cmdout] =  system(['sha256sum ',dataPath]);
idx = strfind(cmdout,' ');        
idx=idx-1;
sha256Sum = cmdout;
sha256Sum = sha256Sum(1,1:idx);

output.sha256 = sha256Sum;

if(strcmp(sha256Sum,dataSha256Sum)==0)
    output.sha256_verified=0;
    output.comment = [output.comment,' SHA256-mismatch'];
end

if(strcmp(sha256Sum,dataSha256Sum)==1)  
    output.sha256_verified=1;      
end

%%
% Check if the protocol file exists
%%
if( exist(protocolPath,'file')==2)
    output.protocol_exists =1;    
else
  output.protocol_exists =0;
  output.comment = [output.comment,' Protocol-file-not-found'];
end



