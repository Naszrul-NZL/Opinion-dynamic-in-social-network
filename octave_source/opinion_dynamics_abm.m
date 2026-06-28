function hist = opinion_dynamics_abm(params, world)
% OPINION_DYNAMICS_ABM  Core simulation of opinion evolution in a social network.
%   hist = opinion_dynamics_abm(params, world)
%     params : struct of model coefficients (see run_scenarios.m)
%     world  : struct from build_world()
%   hist : (T+1) x N matrix of citizen opinions over time.
%
% Update rule for citizen i at step t (clamped to [-1, 1]):
%   O_i(t+1) = O_i(t) + d_direct + d_avg + d_expert + d_influencer + noise
%
%   d_direct    = alpha * T_ij  * (O_j - O_i)          % one like-minded neighbour j
%   d_avg       = beta  * (mean_{j in C_i}(O_j) - O_i)  % averaging / echo chamber
%   d_expert    = gamma * mean_k [ Te_ki*(Eexp_k - O_i) ]   % expert correction
%   d_influencer= delta * mean_l [ S_l*Ti_li*(Einf_l - O_i) ] % influencer push
%
% Bounded confidence (eps): peer and influencer terms only act on sources whose
% opinion is within eps of the citizen's own opinion (selective exposure). The
% expert correction is unconditional because experts are credible/corrective.
%
% PERFORMANCE: this routine is fully VECTORISED (matrix operations, no per-agent
% inner loop), so it runs fast in GNU Octave even for N=200, T=100.
% STTHK2133 Assignment #3 - Modeling & Simulation

  N = world.N;
  A = world.A;                                  % N x N adjacency (0/1)
  Tc = world.Tc * params.peer_trust_mult;       % N x N citizen trust
  Te = world.Te * params.exp_trust_mult;        % K x N expert trust
  Ti = world.Ti * params.peer_trust_mult;       % M x N influencer trust
  infl_op = world.infl_op(:); infl_conn = world.infl_conn;   % M x 1 , M x N
  exp_op  = world.exp_op(:);  exp_conn  = world.exp_conn;    % K x 1 , K x N
  S = world.S(:);                               % M x 1

  alpha = params.alpha; beta = params.beta; gamma = params.gamma;
  delta = params.delta; sigma = params.sigma; eps = params.eps;
  T = params.T;

  Alog = (A > 0);                               % logical adjacency
  O = world.O(:);                               % N x 1
  hist = zeros(T+1, N);
  hist(1,:) = O';

  for t = 1:T
    % ---- pairwise opinion differences: Diff(i,j) = O(j) - O(i) ----
    Diff = O' - O;                              % N x N (broadcasting)
    closeP = Alog & (abs(Diff) < eps);          % like-minded connected peers

    % ---- averaging term (mean of close peers minus self) ----
    cntP = sum(closeP, 2);                       % N x 1
    sumP = sum(closeP .* Diff, 2);               % N x 1
    has  = cntP > 0;
    d_avg = zeros(N,1);
    d_avg(has) = beta * (sumP(has) ./ cntP(has));

    % ---- direct term: one RANDOM like-minded neighbour per citizen ----
    R = rand(N,N); R(~closeP) = -Inf;            % keep only close peers
    [~, jsel] = max(R, [], 2);                    % chosen neighbour index per row
    idx = sub2ind([N N], (1:N)', jsel);
    d_dir = zeros(N,1);
    d_dir(has) = alpha * Tc(idx(has)) .* Diff(idx(has));

    % ---- expert correction (unconditional) ----
    Ediff = exp_op - O';                         % K x N : exp_op(k) - O(i)
    ECc   = (exp_conn > 0);
    cntE  = sum(ECc, 1);                          % 1 x N
    sumE  = sum(Te .* Ediff .* ECc, 1);          % 1 x N
    d_exp = zeros(N,1);
    nzE = cntE > 0;
    d_exp(nzE) = gamma * (sumE(nzE) ./ cntE(nzE))';

    % ---- influencer persuasion (bounded confidence) ----
    Idiff = infl_op - O';                        % M x N : infl_op(l) - O(i)
    ICc   = (infl_conn > 0) & (abs(Idiff) < eps);
    cntI  = sum(ICc, 1);                          % 1 x N
    sumI  = sum((S .* Ti) .* Idiff .* ICc, 1);   % 1 x N
    d_inf = zeros(N,1);
    nzI = cntI > 0;
    d_inf(nzI) = delta * (sumI(nzI) ./ cntI(nzI))';

    % ---- combine + noise + clamp ----
    noise = sigma * randn(N,1);
    O = max(-1, min(1, O + d_dir + d_avg + d_exp + d_inf + noise));
    hist(t+1,:) = O';
  end
end
