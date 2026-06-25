function world = build_world(seed, N, M, K)
% BUILD_WORLD  Create agents, network, trust and opinions for the ABM.
%   world = build_world(seed, N, M, K)
%     seed : RNG seed for reproducibility
%     N    : number of citizen agents      (50-200)
%     M    : number of influencer agents   (4-10)
%     K    : number of education experts   (2-5)
%
% Returns a struct describing the social world.
% STTHK2133 Assignment #3 - Modeling & Simulation (Opinion Dynamics ABM)

  rand('seed', seed); randn('seed', seed);

  % --- Citizen initial opinions: uniform in [-1, 1] ---
  O = 2*rand(N,1) - 1;

  % --- Citizen-citizen random (Erdos-Renyi) network ---
  p = 0.06;                       % edge probability (avg degree ~ 9)
  A = rand(N,N) < p;
  A = triu(A,1); A = A | A';       % symmetric, no self-loops
  A = double(A);

  % --- Influencers: extreme opinions, half pro-AI (+0.9), half anti-AI (-0.9) ---
  infl_op = zeros(M,1);
  for k = 1:M
    if mod(k,2) == 1, infl_op(k) = +0.9; else, infl_op(k) = -0.9; end
  end
  infl_conn = double(rand(M,N) < 0.55);   % high connectivity to citizens

  % --- Experts: balanced / evidence-based opinions near 0 ---
  exp_op   = 0.2*rand(K,1) - 0.1;
  exp_conn = double(rand(K,N) < 0.45);

  % --- Trust matrices ---
  Tc = (0.3 + 0.4*rand(N,N)) .* A;        % citizen-citizen trust on existing edges
  Te = 0.70 + 0.25*rand(K,N);             % experts: high credibility
  Ti = 0.40 + 0.40*rand(M,N);             % trust toward influencers
  S  = 0.8  + 0.2*rand(M,1);              % influencer virality strength

  world = struct('N',N,'M',M,'K',K,'O',O,'A',A, ...
                 'infl_op',infl_op,'infl_conn',infl_conn, ...
                 'exp_op',exp_op,'exp_conn',exp_conn, ...
                 'Tc',Tc,'Te',Te,'Ti',Ti,'S',S);
end
