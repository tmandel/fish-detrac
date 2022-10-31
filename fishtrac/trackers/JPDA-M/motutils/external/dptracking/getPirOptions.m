function opt=getPirOptions(opt)

%%% setting parameters for tracking
opt.c_en      = 5;     %% birth cost
opt.c_ex      = 5;     %% death cost
opt.c_ij      = .1;      %% transition cost
opt.betta     = 0.2;    %% betta
opt.max_it    = Inf;    %% max number of iterations (max number of tracks)
opt.thr_cost  = 18;     %% max acceptable cost for a track (increase it to have more tracks.)

end