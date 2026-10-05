classdef GridFeeder < matlab.System
 % Stateful backward-Euler electrical circuit executed within Simulink.
 properties(Access=private)
  Plan
  Current
 end
 methods(Access=protected)
  function setupImpl(obj)
   obj.Plan=evalin('base','feederPlan'); obj.Current=zeros(3,1);
  end
  function x=stepImpl(obj,t)
   p=obj.Plan; k=min(round(t*p.fs)+1,size(p.source,1)); G=p.G(:,:,k);
   v=(eye(3)+(p.R+p.a)*G)\(p.source(k,:)'+p.a*obj.Current);
   obj.Current=G*v; x=[v' obj.Current']+p.noise(k,:);
  end
  function resetImpl(obj), obj.Current=zeros(3,1); end
  function s=getOutputSizeImpl(~), s=[1 6]; end
  function d=getOutputDataTypeImpl(~), d='double'; end
  function b=isOutputComplexImpl(~), b=false; end
  function b=isOutputFixedSizeImpl(~), b=true; end
 end
end
