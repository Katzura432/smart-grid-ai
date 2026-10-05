function c = config()
% SI electrical parameters; measured features use per-unit quantities.
c.fs=4800; c.f=60; c.V=230; c.R=0.35; c.L=0.002;
c.window=80; c.duration=0.30; c.onset=0.12;
c.names={'Normal','AG','BG','CG','AB','BC','CA','ABG','BCG','CAG','ABC'};
c.seed=42; c.episodesPerClass=90;
end
