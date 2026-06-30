% RUN_SCENARIOS  Drives the Opinion Dynamics ABM across four scenarios,
% produces 2D + 3D temporal plots, final histograms, a network view,
% and prints a summary table.
%
% Usage (from the Octave prompt, inside this folder):
%   >> RUN_predefined_scenarios
%
% STTHK2133 Assignment #3 - Modeling & Simulation
% -------------------------------------------------------------------------

clear; close all; clc;

% ---- Global setup ----
SEED = 42;
N = 150;    % citizens     (50-200)
M = 6;      % influencers  (4-10)
K = 3;      % experts      (2-5)
T = 80;     % time steps   (50-100)

% Base coefficients
base = struct('alpha',0.08,'beta',0.10,'gamma',0.040,'delta',0.08, ...
              'sigma',0.012,'peer_trust_mult',1.0,'exp_trust_mult',1.0, ...
              'eps',0.45,'T',T);

% ---- Scenario parameter sets ----
P = {};
names = {'Scenario 1: Baseline', 'Scenario 2: Strong Influencer', ...
         'Scenario 3: Strong Expert', 'Scenario 4: Low Trust'};

P{1} = base;                                              % S1 Baseline

P{2} = base; P{2}.delta = 0.34; P{2}.gamma = 0.030;       % S2 Strong influencer

P{3} = base; P{3}.gamma = 0.300; P{3}.delta = 0.07; P{3}.eps = 0.55;  % S3 Strong expert

P{4} = base; P{4}.peer_trust_mult = 0.30; P{4}.exp_trust_mult = 0.30; % S4 Low trust
P{4}.delta = 0.05; P{4}.sigma = 0.030; P{4}.eps = 0.20;

% ---- Run all scenarios on the SAME initial world ----
H = cell(1,4);
for sc = 1:4
  world = build_world(SEED, N, M, K);
  H{sc} = opinion_dynamics_abm(P{sc}, world);
end

% ======================= FIGURE 1: 2D temporal =========================
figure('Name','2D Temporal','Position',[80 80 1100 800]);
for sc = 1:4
  subplot(2,2,sc); hold on;
  h = H{sc};
  plot(0:T, h(:,1:3:end), 'Color',[0.75 0.75 0.75], 'LineWidth',0.4);
  plot(0:T, mean(h,2), 'r', 'LineWidth',2.5);
  plot([0 T],[0 0],'k:');
  ylim([-1.05 1.05]); xlabel('Time step'); ylabel('Opinion');
  title(names{sc}); hold off;
end
print(gcf, 'fig_2d_temporal.png', '-dpng', '-r130');

% ======================= FIGURE 2: 3D temporal =========================
figure('Name','3D Temporal','Position',[100 100 1100 800]);
for sc = 1:4
  subplot(2,2,sc);
  h = H{sc};
  [~, order] = sort(h(end,:));        % sort agents by final opinion
  Z = h(:, order)';                   % N x (T+1)
  surf(0:T, 1:N, Z, 'EdgeColor','none');
  view(45,30); zlim([-1 1]); colormap(jet);
  xlabel('Time'); ylabel('Agent (sorted)'); zlabel('Opinion');
  title(names{sc});
end
print(gcf, 'fig_3d_temporal.png', '-dpng', '-r130');

% ======================= FIGURE 3: Histograms ==========================
figure('Name','Final Opinion Histograms','Position',[120 120 1100 800]);
for sc = 1:4
  subplot(2,2,sc);
  final = H{sc}(end,:);
  hist(final, linspace(-1,1,25));
  xlim([-1 1]); xlabel('Final opinion'); ylabel('Count');
  title(names{sc});
end
print(gcf, 'fig_histograms.png', '-dpng', '-r130');

% ======================= FIGURE 4: Network view ========================
world = build_world(SEED, N, M, K); A = world.A;
rand('seed', 7); pos = randn(N,2);
for it = 1:40
  newpos = pos;
  for i = 1:N
    nb = find(A(i,:) > 0);
    if ~isempty(nb), newpos(i,:) = 0.6*pos(i,:) + 0.4*mean(pos(nb,:),1); end
  end
  pos = newpos;
end
final0 = H{1}(end,:)';
figure('Name','Citizen Network','Position',[140 140 800 750]); hold on;
for i = 1:N
  nb = find(A(i,:) > 0);
  for j = nb
    if j > i
      plot([pos(i,1) pos(j,1)], [pos(i,2) pos(j,2)], 'Color',[0.85 0.85 0.85],'LineWidth',0.3);
    end
  end
end
scatter(pos(:,1), pos(:,2), 40, final0, 'filled'); caxis([-1 1]); colorbar;
colormap(jet); title('Citizen network (baseline) coloured by final opinion');
axis off; hold off;
print(gcf, 'fig_network.png', '-dpng', '-r130');

% ======================= Summary table =================================
fprintf('\n%-30s %8s %8s %8s %8s %9s  %s\n', ...
        'Scenario','mean','std','%%pro','%%anti','clusters','Outcome');
fprintf('%s\n', repmat('-',1,95));
for sc = 1:4
  final = H{sc}(end,:)';
  [label, st] = classify_outcome(final);
  fprintf('%-30s %+8.3f %8.3f %7.0f%% %7.0f%% %9d  %s\n', ...
          names{sc}, st.mean, st.std, 100*st.pct_pro, 100*st.pct_anti, ...
          st.clusters, label);
end
fprintf('\nDone. Figures saved as fig_*.png in the current folder.\n');
