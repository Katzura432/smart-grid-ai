function [t,x,truth,plan] = feeder_episode(kind,c)
% Reduced three-phase feeder: series R-L, resistive loads, shunt faults.
% Backward Euler solves coupled nodal equations at each sample.
t=(0:1/c.fs:c.duration)'; n=numel(t); x=zeros(n,6);
frequency=c.f+0.4*randn; phase=2*pi*rand;
source=sqrt(2)*c.V*(0.92+0.16*rand)*sin(2*pi*frequency*t+phase+[0 -2*pi/3 2*pi/3]);
source=source+0.015*c.V*sin(6*pi*frequency*t+phase+[0 -2*pi/3 2*pi/3]);
loads=(16+18*rand(3,1)).*(0.92+0.16*rand(3,1));
R=c.R*(0.8+0.4*rand); L=c.L*(0.8+0.4*rand);
onset=c.onset+0.025*(rand-0.5); finish=c.duration-0.035;
Gfault=zeros(3); conductance=1/(0.2+3.8*rand);
switch kind
 case 2, Gfault(1,1)=conductance;
 case 3, Gfault(2,2)=conductance;
 case 4, Gfault(3,3)=conductance;
 case {5,8}, pair=[1 2]; Gfault=pairFault(pair,conductance); if kind==8, Gfault(pair,pair)=Gfault(pair,pair)+eye(2)*conductance; end
 case {6,9}, pair=[2 3]; Gfault=pairFault(pair,conductance); if kind==9, Gfault(pair,pair)=Gfault(pair,pair)+eye(2)*conductance; end
 case {7,10}, pair=[3 1]; Gfault=pairFault(pair,conductance); if kind==10, Gfault(pair,pair)=Gfault(pair,pair)+eye(2)*conductance; end
 case 11, Gfault=conductance*(3*eye(3)-ones(3));
end
truth=ones(n,1); current=zeros(3,1); a=L*c.fs; Gs=zeros(3,3,n);
% Normal episodes include benign balanced load switching.
switchFactor=0.65+0.7*rand;
for k=1:n
 G=diag(1./loads);
 if t(k)>=onset && t(k)<finish
  if kind>1, G=G+Gfault; truth(k)=kind;
  else, G=G*switchFactor; end
 end
 Gs(:,:,k)=G;
 v=(eye(3)+(R+a)*G)\(source(k,:)'+a*current);
 current=G*v; x(k,:)=[v' current'];
end
noise=[0.003*c.V*randn(n,3) 0.03*randn(n,3)]; x=x+noise;
plan=struct('source',source,'G',Gs,'noise',noise,'R',R,'a',a,'fs',c.fs);
end
function G=pairFault(p,g)
G=zeros(3); G(p,p)=g*[1 -1;-1 1];
end
