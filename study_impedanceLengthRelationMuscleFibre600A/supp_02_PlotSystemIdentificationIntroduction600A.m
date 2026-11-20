function success = supp_02_PlotSystemIdentificationIntroduction600A(projectFolders)
disp('--------------------------------------------------');
disp('supp_02_PlotSystemIdentificationIntroduction600A');
disp('--------------------------------------------------');


outputFolder = 'system_identification';



%%
% Perturbation plot configuration
%%
numberOfHorizontalPlotColumnsGeneric    = 3;
numberOfVerticalPlotRowsGeneric         = 2;

plotWidth          = ones(1,numberOfHorizontalPlotColumnsGeneric).*4;
plotHeight         = ones(numberOfVerticalPlotRowsGeneric,1).*4;
plotHorizPageMarginCm=2.5;
plotHorizMarginCm  = 2.5;
plotVertMarginCm   = 2;
baseFontSize       = 10;

[subPlotPanel, subPlotSettings]= ...
  plotConfigAdvanced(  numberOfHorizontalPlotColumnsGeneric,...
                      numberOfVerticalPlotRowsGeneric,...
                      plotWidth,...
                      plotHeight,...
                      plotHorizPageMarginCm,...
                      plotHorizMarginCm,...
                      plotVertMarginCm,...
                      baseFontSize); 


cs=getPaulTolColourSchemes('vibrant');

fig_sigIntro=figure;

%%
% Simple signal to show the dual representation of x(t) and X(omega)
%%

ss.fs=2^12;
ss.n=2^12;
ss.nH=2^11;
ss.time = [0:1:(ss.n-1)].*(1/ss.fs);
ss.xt   = zeros(size(ss.time));

ss.fw = (([1:1:ss.n]-1)./ss.n).*ss.fs;
ss.w = ss.fw.*(2*pi);
ss.l0=0;
ss.dl0=0;
ss.ddl0=0;

idFw = [2,2,21];%[10,20,15,25];
ampFw = [1,0.5,-0.1];%[1,0.5,0.25,0.125];
trigType=['s','c','c'];


for i=1:1:length(idFw)
  omegai = (ss.fw(idFw(i))*2*pi);
  ai = ampFw(i);
  switch trigType(i)
    case 's'
      ss.xt = ss.xt + (ai).*sin(omegai.*ss.time);  
      ss.l0 = ss.l0            + (ai).*sin(omegai.*ss.time(1));
      ss.dl0  = ss.dl0  + (ai*omegai).*cos(omegai.*ss.time(1));
      ss.ddl0 = ss.dl0  - (ai*omegai)^2.*cos(omegai.*ss.time(1));
    case 'c'
      ss.xt = ss.xt            + (ai).*cos(omegai.*ss.time);   
      ss.l0 = ss.l0            + (ai).*cos(omegai.*ss.time(1));  
      ss.dl0  = ss.dl0  - (ai*omegai).*sin(omegai.*ss.time(1));
      ss.ddl0 = ss.ddl0 - (ai*omegai)^2.*cos(omegai.*ss.time(1));
 
    otherwise
      assert(0,'Error');
  end
end
ss.idxBW = find(ss.fw <= ss.fw(idFw(end)+1));

ss.xw = fft(ss.xt);

%%
% Plot the data
%%
%%=========================================================================
% Row 1 colum 3
%%=========================================================================

subplot('Position',reshape(subPlotPanel(1,1,:),1,4));
  plot(ss.time,ss.xt,'-k');
  hold on;
  
  xlim([0,max(ss.time)]);

  x0 = min(ss.time);
  x1 = max(ss.time);
  dx = x1-x0;

  y0 = min(ss.xt);
  y1 = max(ss.xt);
  dy = y1-y0;

  yMax=y1+dy*0.45;
  yMin=y0-dy*0.0625;

  xlim([x0,x1]);
  ylim([yMin,yMax]);

  %yticks([round(min(ss.xt),2),0,round(max(ss.xt),2)]);

  text(x0+dx*0.05,yMax,...
       sprintf('%s','$$x(t) = $$'),...
       'HorizontalAlignment','left',...
       'VerticalAlignment','top',...
       'FontSize',8);  
  hold on;

  for i=1:1:length(idFw)

    signChar='';
    if(i>1 && ampFw(i)>0)
      signChar='+';
    end

    xTxt=x0+dx*0.2;
    yTxt=yMax-dy*0.1*(i-1);
    if(i==1)
      xTxt=x0+dx*0.25;
    end

    switch trigType(i)
      case 's'
        text(xTxt,yTxt,...
             sprintf('%s%1.2f%s%1.2f%s',['$$',signChar],ampFw(i),'\sin (',ss.fw(idFw(i)),'(2\pi\,t))$$'),...
             'HorizontalAlignment','left',...
             'VerticalAlignment','top',...
             'FontSize',8);  
        hold on;
        
      case 'c'
        text(xTxt,yTxt,...
             sprintf('%s%1.2f%s%1.2f%s',['$$',signChar],ampFw(i),'\cos (',ss.fw(idFw(i)),'(2\pi\,t))$$'),...
             'HorizontalAlignment','left',...
             'VerticalAlignment','top',...
             'FontSize',8);  
        hold on;        
      otherwise
        assert(0,'Error');
    end
  end



  box off;
  xlabel('Time (s)');
  ylabel('Length (mm)');
  title(sprintf('A. Example time-domain signal %s','$$x(t)$$'));
  
%%=========================================================================
% Row 1 column 2
%%=========================================================================

subplot('Position',reshape(subPlotPanel(1,2,:),1,4));

  plot(ss.fw(ss.idxBW),...
       real(ss.xw(ss.idxBW)),'s',...
       'Color',[1,1,1].*0,...
       'MarkerFaceColor',[1,1,1]);  
  hold on;

  plot(ss.fw(ss.idxBW),...
       imag(ss.xw(ss.idxBW)),'.',...
       'Color',[0,0,0],...
       'MarkerFaceColor',[1,1,1]);  
  hold on;

  numTol=sqrt(eps);
  yTickList=[];
  xTickList=[];
  for i=1:1:length(ss.idxBW)
    if(abs(real(ss.xw(ss.idxBW(i)))) > numTol )
      yTickList=[yTickList,real(ss.xw(ss.idxBW(i)))];
      xTickList=[xTickList,ss.fw(ss.idxBW(i))];
    end
    if(abs(imag(ss.xw(ss.idxBW(i)))) > numTol )
      yTickList=[yTickList,imag(ss.xw(ss.idxBW(i)))];
      xTickList=[xTickList,ss.fw(ss.idxBW(i))];      
    end    
  end

  x0 = min(ss.fw(ss.idxBW));
  x1 = max(ss.fw(ss.idxBW));
  dx=x1-x0;
  y0=min([real(ss.xw(ss.idxBW)),imag(ss.xw(ss.idxBW))]);
  y1=max([real(ss.xw(ss.idxBW)),imag(ss.xw(ss.idxBW))]);
  dy=y1-y0;
  yMin=y0-0.1*dy;
  yMax=y1+0.3*dy;
  xlim([0,x1]);
  ylim([yMin,yMax]);
  xticks(sort(unique(xTickList)));
  yticks(sort(unique(yTickList)));

  xTxt= x0+0.6*dx;
  plot(xTxt,yMax-0.1*dy,'.','Color',[0,0,0],'MarkerFaceColor',[1,1,1]);
  hold on;
  text(xTxt+dx*0.05,yMax-0.1*dy,...
    sprintf('%s','$$\mathcal{I}(X(\omega))$$'),...
    'HorizontalAlignment','left',...
    'VerticalAlignment','middle',...
    'FontSize',8);
  hold on;

  plot(xTxt,yMax-0.2*dy,'s','Color',[0,0,0],'MarkerFaceColor',[1,1,1]);
  hold on;
  text(xTxt+dx*0.05,yMax-0.2*dy,...
    sprintf('%s','$$\mathcal{R}(X(\omega))$$'),...
    'HorizontalAlignment','left',...
    'VerticalAlignment','middle',...
    'FontSize',8);
  hold on;


  box off;

  xlabel('Frequency (Hz)');
  ylabel(sprintf('Length%s (mm%s)','$$\times N$$','$$\times N$$'));  
  title(sprintf('B. %s transformed into %s','$$x(t)$$','$$X(\omega)$$'));  

%%=========================================================================
% Row 1 column 3
%%=========================================================================
subplot('Position',reshape(subPlotPanel(1,3,:),1,4));

  pwr2Real = real(ss.xw) ./ ss.n;
  pwr1Real = pwr2Real(1:(ss.n/2+1));
  pwr1Real(2:end-1)=2.*pwr1Real(2:end-1);

  pwr2Imag = -imag(ss.xw) ./ ss.n;
  pwr1Imag = pwr2Imag(1:(ss.n/2+1));
  pwr1Imag(2:end-1)=2.*pwr1Imag(2:end-1);  

  plot(ss.fw(ss.idxBW),...
       pwr1Real(ss.idxBW),'s',...
       'Color',[1,1,1].*0,...
       'MarkerFaceColor',[1,1,1]);  
  hold on;

  plot(ss.fw(ss.idxBW),...
       pwr1Imag(ss.idxBW),'.',...
       'Color',[0,0,0],...
       'MarkerFaceColor',[1,1,1]);  
  hold on;


  numTol=sqrt(eps);
  yTickList=[];
  xTickList=[];
  for i=1:1:length(ss.idxBW)
    if(abs(pwr1Real(i)) > numTol )
      yTickList=[yTickList,pwr1Real(i)];
      xTickList=[xTickList,ss.fw(ss.idxBW(i))];
    end
    if(abs(pwr1Imag(i)) > numTol )
      yTickList=[yTickList,pwr1Imag(i)];
      xTickList=[xTickList,ss.fw(ss.idxBW(i))];      
    end    
  end
  xticks(sort(unique(xTickList)));
  yticks(sort(unique(yTickList)));

  x0=min(ss.fw(idFw));
  x1=max(ss.fw(idFw));
  dx=x1-x0;

  y0=min(yTickList);
  y1=max(yTickList);
  dy=y1-y0;
  yMin=y0-0.1*dy;
  yMax=y1+0.4*dy;
  xlim([0,x1]);
  ylim([yMin,yMax])

  xTxt= x0+0.72;
  plot(xTxt,yMax-0.1*dy,'.','Color',[0,0,0],'MarkerFaceColor',[1,1,1]);
  hold on;
  text(xTxt+dx*0.05,yMax-0.1*dy,...
    sprintf('%s','$$A_i \sin (\omega_i (2\pi\,t) ): -(2/N)\mathcal{I}(X(\omega))$$'),...
    'HorizontalAlignment','left',...
    'VerticalAlignment','middle',...
    'FontSize',8);
  hold on;
  plot(xTxt,yMax-0.2*dy,'s','Color',[0,0,0],'MarkerFaceColor',[1,1,1]);
  hold on;
  text(xTxt+dx*0.05,yMax-0.2*dy,...
    sprintf('%s','$$A_i \cos (\omega_i (2\pi\,t) ): (2/N)\mathcal{R}(X(\omega))$$'),...
    'HorizontalAlignment','left',...
    'VerticalAlignment','middle',...
    'FontSize',8);
  hold on;

  xticks(sort(unique(xTickList)));

  box off;
  xlabel('Frequency (Hz)');
  ylabel('Length (mm)');
  title(sprintf('C. %s and %s parameters from %s','$$\sin$$','$$\cos$$','$$X(\omega)$$'))


%%
% Simple parameter id example
%%

sid.fs=2^12;
sid.n=2^13;
sid.nH=2^12;
sid.time = [0:1:(sid.n-1)].*(1/sid.fs);
sid.fw = (([1:1:sid.n]-1)./sid.n).*sid.fs;
sid.w  = sid.fw.*(2*pi);

sid.xt   = zeros(size(sid.time));




xFunctionType = 'square';

switch xFunctionType
  case 'square'

    omegaHz = 10;
    sid.idxBW = find(sid.fw < 10*omegaHz);

    idxPad0= find( sid.time <= (3/omegaHz) );
    idxPad1= find( sid.time >= (sid.time(end)-(3/omegaHz)));

    idxA = find( sin( (omegaHz*2*pi).*sid.time ) >= 0 );
    idxB = find( sin( (omegaHz*2*pi).*sid.time ) < 0 );
    sid.xt(idxA)   =  1;
    sid.xt(idxB)   = -1;
    sid.xt(idxPad0)=  0;
    sid.xt(idxPad1)=  0;    
    sid.l0   = 0;
    sid.dl0  = 0;
    sid.ddl0 = 0;
    
  case 'sine'

    omegaHz = 10;
    sid.idxBW = find(sid.fw < 2*omegaHz);

    idxPad0= find( sid.time <= (3/omegaHz) );
    idxPad1= find( sid.time >= (sid.time(end)-(3/omegaHz)));

    idxA = find( sin( (omegaHz*2*pi).*sid.time ) >= 0 );
    idxB = find( sin( (omegaHz*2*pi).*sid.time ) < 0 );
    sid.xt = sin((omegaHz*2*pi).*sid.time);
    sid.xt(idxPad0)=0;
    sid.xt(idxPad1)=0;    
    sid.dl0  = 0;% cos((omegaHz*2*pi).*sid.time(1)).*(omegaHz*2*pi);
    sid.ddl0 = 0;%-sin((omegaHz*2*pi).*sid.time(1)).*(omegaHz*2*pi)^2;
   
  case 'random'
    omegaHz = 90;
    sid.idxBW = find(sid.fw < 2*omegaHz);

    timeDuration = sid.time(end)-sid.time(1);
    idxPad0= find( sid.time <=  timeDuration*0.1);
    idxPad1= find( sid.time >= timeDuration*0.9);
    sid.xt = rand(sid.n,1);
    sid.xt = sid.xt-mean(sid.xt);
    sid.xt(idxPad0)=0;
    sid.xt(idxPad1)=0;   
    [b,a]=butter(2,(omegaHz./(0.5*sid.fs)),'low');
    sid.xt = filtfilt(b,a,sid.xt);
    sid.l0=0;
    sid.dl0=0;
    sid.ddl0=0;
  otherwise
    assert(0,'Error');
end
  






flag_useSimpleSignal=0;
if(flag_useSimpleSignal==1)
  fieldsToCopy={'fs','n','nH','time','fw','w','xt','l0','dl0','ddl0'};
  for idxF=1:1:length(fieldsToCopy)
    sid.(fieldsToCopy{idxF})=ss.(fieldsToCopy{idxF});
  end
end


maxwellSettings.l    = sid.xt;
maxwellSettings.t    = sid.time;
maxwellSettings.k    = 5;
maxwellSettings.beta = 0.1;

odeFcn = @(tArg,xArg)calcMaxwellElementDerivative(tArg,xArg,maxwellSettings);

dx0 = -((maxwellSettings.beta*sid.ddl0)-maxwellSettings.k*sid.dl0)...
        /maxwellSettings.k;
x0  =  (maxwellSettings.k.*sid.l0 - maxwellSettings.beta*dx0) ...
       /maxwellSettings.k;

[t,x]=ode15s(odeFcn,sid.time,x0);
f=zeros(size(x));
for i=1:1:length(f)
  [dx,f(i)]=calcMaxwellElementDerivative(t(i),x(i),maxwellSettings);
end

sid.yt = f;
sid.xw = fft(sid.xt);
sid.yw = fft(sid.yt);



subplot('Position',reshape(subPlotPanel(2,1,:),1,4));


  yyaxis right;
  plot(sid.time,sid.yt,'-','Color',cs.cyan);
  hold on;
  ylabel('Force (mN)');

  y0 = min(sid.yt);
  y1 = max(sid.yt);
  ySpan = y1-y0;
  ylim([-11,11]);

  yyaxis left;
  plot(sid.time,sid.xt,'-','Color',[0,0,0]);
  hold on;
  xlabel('Time (s)');
  ylabel('Length (mm)');

  x0 = min(sid.xt);
  x1 = max(sid.xt);
  xSpan = x1-x0;
  ylim([-11,11]);  

  ax=gca;
  ax.YAxis(1).Color=[0,0,0];
  ax.YAxis(2).Color=cs.cyan;
  set(ax,'SortMethod','depth');
  box off;
  

  xlim([0,sid.time(end)]);  
  title(sprintf('D. %s and %s','$$x(t)$$','$$y(t)$$'));
  
subplot('Position',reshape(subPlotPanel(2,2,:),1,4));

  y0 = [];
  y1 = [];
  for i=1:1:length(sid.idxBW)
    s = 1;
    if(i>1)
      s=2;
    end
    fi = sid.fw(sid.idxBW(i));
    ptX = s*real(sid.xw(sid.idxBW(i))); 
    ptY = s*real(sid.yw(sid.idxBW(i)));

    y0 = min([y0,ptX,ptY]);
    y1 = max([y1,ptX,ptY]);

    plot([fi,fi],[ptX,ptY],'-','Color',cs.red);
    hold on;
    plot(fi,ptX,'.','Color',[0,0,0],'MarkerFaceColor',[0,0,0]);
    hold on;
    plot(fi,ptY,'.','Color',cs.cyan,'MarkerFaceColor',cs.cyan);
    hold on;
  end
  box off;

  xlim([0,sid.fw(sid.idxBW(end))]);
  ylim([-9000,23000]);


  x0=0;
  x1=sid.fw(sid.idxBW(end));
  dy = 0.1*(x1-x0);

  y0=-9000;
  y1=23000;  

  xPt = x0+0.6*(x1-x0);
  yPt0 = y1-0.1*(y1-y0);
  yPt1 = y1-0.2*(y1-y0);
  yPt2 = y1-0.3*(y1-y0);

  plot(xPt,yPt0,'.','Color',[0,0,0]);
  hold on;
  plot(xPt,yPt1,'.','Color',cs.cyan);
  hold on;
  plot([xPt-dy,xPt],[yPt2,yPt2],'-','Color',cs.red);
  hold on;

  text(xPt+0.5*dy,yPt0,sprintf('%s','$$\mathcal{R}(X(\omega))$$'),...
       'HorizontalAlignment','left',...
       'VerticalAlignment','middle',...
       'FontSize',8);
  hold on;
  text(xPt+0.5*dy,yPt1,sprintf('%s','$$\mathcal{R}(Y(\omega))$$'),...
       'HorizontalAlignment','left',...
       'VerticalAlignment','middle',...
       'FontSize',8);
  hold on;
  text(xPt+0.5*dy,yPt2,sprintf('%s','$$\mathcal{R}(H(\omega))$$'),...
       'HorizontalAlignment','left',...
       'VerticalAlignment','middle',...
       'FontSize',8);
  hold on;

  xlabel('Frequency (Hz)');
  ylabel(sprintf('Length%s (mm%s)','$$\times N$$','$$\times N$$'));  
  title({'E. Real parts of',...
    sprintf('%s and %s','$$X(\omega)$$','$$Y(\omega)$$')});  

subplot('Position',reshape(subPlotPanel(2,3,:),1,4));
  y0 = [];
  y1 = [];
  for i=1:1:length(sid.idxBW)
    s = 1;
    if(i>1)
      s=2;
    end
    
    fi = sid.fw(sid.idxBW(i));
    ptX = -s*imag(sid.xw(sid.idxBW(i))); 
    ptY = -s*imag(sid.yw(sid.idxBW(i)));

    y0 = min([y0,ptX,ptY]);
    y1 = max([y1,ptX,ptY]);

    plot([fi,fi],[ptX,ptY],'-','Color',cs.red);
    hold on;
    plot(fi,ptX,'.','Color',[0,0,0],'MarkerFaceColor',[0,0,0]);
    hold on;
    plot(fi,ptY,'.','Color',cs.cyan,'MarkerFaceColor',cs.cyan);
    hold on;
  end
  box off;

  xlim([0,sid.fw(sid.idxBW(end))]);
  ylim([-9000,23000]);

  x0=0;
  x1=sid.fw(sid.idxBW(end));

  dy = 0.1*(x1-x0);

  y0=-9000;
  y1=23000;

  xPt = x0+0.6*(x1-x0);
  yPt0 = y1-0.1*(y1-y0);
  yPt1 = y1-0.2*(y1-y0);
  yPt2 = y1-0.3*(y1-y0);

  plot(xPt,yPt0,'.','Color',[0,0,0]);
  hold on;
  plot(xPt,yPt1,'.','Color',cs.cyan);
  hold on;
  plot([xPt-dy,xPt],[yPt2,yPt2],'-','Color',cs.red);
  hold on;

  text(xPt+0.5*dy,yPt0,sprintf('%s','$$\mathcal{I}(X(\omega))$$'),...
       'HorizontalAlignment','left',...
       'VerticalAlignment','middle',...
       'FontSize',8);
  hold on;
  text(xPt+0.5*dy,yPt1,sprintf('%s','$$\mathcal{I}(Y(\omega))$$'),...
       'HorizontalAlignment','left',...
       'VerticalAlignment','middle',...
       'FontSize',8);
  hold on;
  text(xPt+0.5*dy,yPt2,sprintf('%s','$$\mathcal{I}(H(\omega))$$'),...
       'HorizontalAlignment','left',...
       'VerticalAlignment','middle',...
       'FontSize',8);
  hold on;

  xlabel('Frequency (Hz)');
  ylabel(sprintf('Length%s (mm%s)','$$\times N$$','$$\times N$$'));  
  title({'F. Imaginary parts of',...
    sprintf('%s and %s','$$X(\omega)$$','$$Y(\omega)$$')});  

%%
% Write the data to file
%%



fig_sigIntro=configPlotExporter(fig_sigIntro, ...
                    subPlotSettings.pageWidthCm, ...
                    subPlotSettings.pageHeightCm);

fileName =    ['fig_systemIdentificationIntroduction'];
print('-dpdf', fullfile(projectFolders.output600A_plots, ...
                        outputFolder,[fileName,'.pdf']));    
saveas(fig_sigIntro,fullfile(projectFolders.output600A_plots,...
                                 outputFolder,[fileName,'.fig']));
close(fig_sigIntro);


success=1;

