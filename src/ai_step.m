function y=ai_step(u)
% Simulation-only interpreted MATLAB block; reset with clear ai_step.
persistent buffer count mdl c
if isempty(mdl)
 c=config(); s=load(fullfile(fileparts(fileparts(mfilename('fullpath'))),'models','classifier.mat'),'mdl');
 mdl=s.mdl; buffer=zeros(c.window,6); count=0;
end
buffer=[buffer(2:end,:); reshape(u,1,6)]; count=count+1;
if count<c.window, y=[1 0]; return; end
[label,score]=predict(mdl,features(buffer,c)); y=[double(label) max(score)];
end
