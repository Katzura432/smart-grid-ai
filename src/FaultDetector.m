classdef FaultDetector < matlab.System
 properties(Access=private)
  Model
  Config
  Buffer
  Count
 end
 methods(Access=protected)
  function setupImpl(obj)
   obj.Config=config(); root=fileparts(fileparts(mfilename('fullpath')));
   s=load(fullfile(root,'models','classifier.mat'),'mdl'); obj.Model=s.mdl;
   obj.Buffer=zeros(obj.Config.window,6); obj.Count=0;
  end
  function y=stepImpl(obj,u)
   obj.Buffer=[obj.Buffer(2:end,:); reshape(u,1,6)]; obj.Count=obj.Count+1;
   if obj.Count<obj.Config.window, y=[1 0]; return; end
   [label,score]=predict(obj.Model,features(obj.Buffer,obj.Config));
   y=[double(label) max(score)];
  end
  function resetImpl(obj), obj.Buffer=zeros(obj.Config.window,6); obj.Count=0; end
  function s=getOutputSizeImpl(~), s=[1 2]; end
  function d=getOutputDataTypeImpl(~), d='double'; end
  function b=isOutputComplexImpl(~), b=false; end
  function b=isOutputFixedSizeImpl(~), b=true; end
 end
end
