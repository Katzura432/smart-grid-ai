% Reproduce training, independent test evaluation, Simulink run and figures.
clear; close all; clc;
root=fileparts(mfilename('fullpath')); addpath(fullfile(root,'src'));
c=config(); rng(c.seed,'twister');
for folder={'models','results','data'}, if ~isfolder(fullfile(root,folder{1})), mkdir(fullfile(root,folder{1})); end; end
X=[]; Y=[]; split=[]; episode=[];
fprintf('Generating independent feeder episodes...\n');
for kind=1:numel(c.names)
 for e=1:c.episodesPerClass
  [t,x,y]=feeder_episode(kind,c);
  % Disjoint episode split; only stable, fully faulted/healthy windows.
  for stop=[c.window*3 c.window*5 c.window*9 c.window*12]
   idx=stop-c.window+1:stop;
   if all(y(idx)==y(stop))
    X(end+1,:)=features(x(idx,:),c); Y(end+1,1)=y(stop);
    split(end+1,1)=e<=round(0.7*c.episodesPerClass);
    episode(end+1,1)=(kind-1)*c.episodesPerClass+e;
   end
  end
 end
end
train=logical(split); mdl=fitcensemble(X(train,:),Y(train),'Method','Bag','NumLearningCycles',80,'Learners',templateTree('MinLeafSize',3),'ClassNames',(1:11)');
mdl=compact(mdl); save(fullfile(root,'models','classifier.mat'),'mdl','c');
pred=predict(mdl,X(~train,:)); C=confusionmat(Y(~train),pred,'Order',1:11);
accuracy=mean(pred==Y(~train)); recall=diag(C)./max(sum(C,2),1); precision=diag(C)./max(sum(C,1)',1);
f1=2*precision.*recall./max(precision+recall,eps);
metrics=struct('accuracy',accuracy,'macroF1',mean(f1),'trainWindows',sum(train),'testWindows',sum(~train),'seed',c.seed,'matlab',version,'split','70/30 by independent episode, no shared episodes');
save(fullfile(root,'data','dataset.mat'),'X','Y','split','episode','c');
writetable(table(string(c.names'),sum(C,2),precision,recall,f1,'VariableNames',{'Class','TestSupport','Precision','Recall','F1'}),fullfile(root,'results','class_metrics.csv'));
fid=fopen(fullfile(root,'results','metrics.json'),'w'); fprintf(fid,'%s',jsonencode(metrics,PrettyPrint=true)); fclose(fid);
fig=figure('Color','w','Position',[50 50 1200 760]); confusionchart(C,c.names,'RowSummary','row-normalized','ColumnSummary','column-normalized'); title(sprintf('Independent episode test | Accuracy %.2f%% | Macro F1 %.3f',100*accuracy,mean(f1)));
exportgraphics(fig,fullfile(root,'results','confusion_matrix.png'),'Resolution',160);
fprintf('Test accuracy %.2f%%, macro F1 %.3f\n',100*accuracy,mean(f1));
rng(2026); [t,x,truth,feederPlan]=feeder_episode(8,c); assignin('base','feederPlan',feederPlan); clear ai_step;
build_model(root,c); out=sim('smart_grid_fault_detection');
det=squeeze(out.prediction.Data); if size(det,1)==2, det=det'; end; ts=out.prediction.Time;
save(fullfile(root,'results','demo_simulation.mat'),'out','t','x','truth');
writetable(table(ts,det(:,1),det(:,2),'VariableNames',{'Time_s','PredictedClass','VoteConfidence'}),fullfile(root,'results','demo_predictions.csv'));
fig=figure('Color','w','Position',[40 40 1400 900]); tiledlayout(4,1,'TileSpacing','compact');
nexttile; plot(t,x(:,1:3)); ylabel('Voltage (V)'); legend('Phase A','Phase B','Phase C','Location','eastoutside'); grid on; title('Smart grid AI fault detection | simulated AB-to-ground fault');
nexttile; plot(t,x(:,4:6)); ylabel('Current (A)'); grid on;
nexttile; stairs(t,truth,'k--','LineWidth',1.7); hold on; stairs(ts,det(:,1),'Color',[0 .45 .75],'LineWidth',1.2); yticks(1:11); yticklabels(c.names); ylabel('Fault class'); legend('Ground truth','AI prediction','Location','eastoutside'); grid on;
nexttile; plot(ts,det(:,2),'LineWidth',1.4); ylim([0 1.05]); ylabel('Tree vote fraction'); xlabel('Time (s)'); grid on;
axs=findall(fig,'Type','axes'); set(axs,'XLim',[0 c.duration]);
for ax=axs', ax.Toolbar.Visible='off'; end
exportgraphics(fig,fullfile(root,'results','fault_detection_results.png'),'Resolution',160);
% Verify actual Simulink predictions equal an independent causal replay.
clear ai_step; replay=zeros(size(det)); for k=1:numel(ts), [~,ix]=min(abs(t-ts(k))); replay(k,:)=ai_step(x(ix,:)); end
assert(isequal(replay,det),'Simulink/replay disagreement');
measured=squeeze(out.measurements.Data); if size(measured,1)==6, measured=measured'; end
assert(max(abs(measured-x),[],'all')<1e-8,'Simulink circuit/reference disagreement');
assert(isempty(intersect(unique(episode(train)),unique(episode(~train)))),'Episode leakage');
assert(all(isfinite(X),'all') && all(isfinite(det),'all'),'Nonfinite outputs');
fprintf('PASS: episode separation, finite outputs, Simulink causal replay.\n');
fprintf('Results saved to %s\n',fullfile(root,'results'));
