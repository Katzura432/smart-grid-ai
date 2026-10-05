% Open the ready-built model with the reproducible ABG demonstration scenario.
root=fileparts(mfilename('fullpath')); addpath(fullfile(root,'src'));
c=config(); rng(2026); [~,~,~,feederPlan]=feeder_episode(8,c);
assignin('base','feederPlan',feederPlan);
open_system(fullfile(root,'models','smart_grid_fault_detection.slx'));
% Click Run. To try another fault, change 8 above using the README class map.
