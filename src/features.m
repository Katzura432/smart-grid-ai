function z=features(x,c)
% One causal cycle; no fault labels or scenario parameters are predictors.
v=x(:,1:3)/c.V; i=x(:,4:6)/(c.V/24);
vr=sqrt(mean(v.^2)); ir=sqrt(mean(i.^2));
z=[vr ir sqrt(mean(sum(i,2).^2)) sqrt(mean(sum(v,2).^2)) ...
 max(abs(i)) mean(v.*i) std(vr) std(ir)];
end
