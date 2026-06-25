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
%   d_direct    = alpha * T_ij  * (O_j - O_i)        % one like-minded neighbour j
%   d_avg       = beta  * (mean_{j in C_i} O_j - O_i) % averaging / echo chamber
%   d_expert    = gamma * mean_k [ Te_ki*(Eexp_k - O_i) ]  % expert correction
%   d_influencer= delta * mean_l [ S_l*Ti_li*(Einf_l - O_i) ] % influencer push
%
% Bounded confidence (eps): peer and influencer terms only act on sources whose
% opinion is within eps of the citizen's own opinion (selective exposure). The
% expert correction is unconditional because experts are credible/corrective.
% STTHK2133 Assignment #3 - Modeling & Simulation

  N = world.N;
  A = world.A;
  Tc = world.Tc * params.peer_trust_mult;
  Te = world.Te * params.exp_trust_mult;
  Ti = world.Ti * params.peer_trust_mult;
  infl_op = world.infl_op; infl_conn = world.infl_conn;
  exp_op  = world.exp_op;  exp_conn  = world.exp_conn;
  S = world.S;

  alpha = params.alpha; beta = params.beta; gamma = params.gamma;
  delta = params.delta; sigma = params.sigma; eps = params.eps;
  T = params.T;

  O = world.O(:);
  hist = zeros(T+1, N);
  hist(1,:) = O';

  for t = 1:T
    Onew = O;
    for i = 1:N
      nbrs = find(A(i,:) > 0);
      d_direct = 0; d_avg = 0;
      if ~isempty(nbrs)
        close = nbrs(abs(O(nbrs) - O(i)) < eps);     % bounded-confidence peers
        if ~isempty(close)
          j = close(randi(numel(close)));            % one random like-minded peer
          d_direct = alpha * Tc(i,j) * (O(j) - O(i));
          d_avg    = beta  * (mean(O(close)) - O(i));
        end
      end
      % expert correction (unconditional)
      ce = find(exp_conn(:,i) > 0);
      d_exp = 0;
      if ~isempty(ce)
        d_exp = gamma * mean(Te(ce,i) .* (exp_op(ce) - O(i)));
      end
      % influencer persuasion with selective exposure
      ci = find(infl_conn(:,i) > 0);
      d_inf = 0;
      if ~isempty(ci)
        cci = ci(abs(infl_op(ci) - O(i)) < eps);
        if ~isempty(cci)
          d_inf = delta * mean(S(cci) .* Ti(cci,i) .* (infl_op(cci) - O(i)));
        end
      end
      noise = sigma * randn();
      val = O(i) + d_direct + d_avg + d_exp + d_inf + noise;
      Onew(i) = max(-1, min(1, val));               % clamp to [-1, 1]
    end
    O = Onew;
    hist(t+1,:) = O';
  end
end
