function data = getDataColumnLabelsSettings(expJson)

data.S.ch = 'Sample';
data.S.settings = [];  
data.L.ch = 'AI0';
data.L.settings = [];
data.F.ch  = 'AI1';
data.F.settings = [];
data.SV.ch  = [];
data.SV.settings = [];
data.SC.ch  = [];
data.SC.settings = [];
data.SS.ch  = 'Stim';
data.SS.settings = [];

stimV = [];
stimA = [];

if(isfield(expJson,'data'))
  for k=1:1:length(expJson.data)
    if(strcmp(expJson.data(k).name,'Stimulation Voltage'))
      stimV = expJson.data(k);
    end
    if(strcmp(expJson.data(k).name,'Stimulation Current'))
      stimA = expJson.data(k);
    end
    switch expJson.data(k).name
      case 'Sample'
        data.S.ch = expJson.data(k).channel;
        data.S.settings = expJson.data(k);
      case 'Length'
        data.L.ch = expJson.data(k).channel;
        data.L.settings = expJson.data(k);          
      case 'Force'
        data.F.ch = expJson.data(k).channel;
        data.F.settings = expJson.data(k);
      case 'Stimulation Voltage'
        data.SV.ch = expJson.data(k).channel;
        data.SV.settings = expJson.data(k);
      case 'Stimulation Current'
        data.SC.ch = expJson.data(k).channel;
        data.SC.settings = expJson.data(k);
      case 'Stimulation Signal'
        data.SS.ch = expJson.data(k).channel;
        data.SS.settings = expJson.data(k);
    end
  end    
end