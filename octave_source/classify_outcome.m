function [label, stats] = classify_outcome(final)
% CLASSIFY_OUTCOME  Label the final opinion distribution.
%   [label, stats] = classify_outcome(final)
%   final : N x 1 vector of final opinions.
% Returns one of: 'Consensus', 'Polarization', 'Fragmentation',
% 'Mixed / Echo chambers', plus summary statistics.

  final = final(:);
  m   = mean(final);
  s   = std(final);
  pos = mean(final >  0.4);
  neg = mean(final < -0.4);
  mid = mean(abs(final) <= 0.4);

  % crude cluster count from histogram peaks
  edges = linspace(-1,1,21);
  h = histc(final, edges);
  centers = 0.5*(edges(1:end-1) + edges(2:end));
  h = h(1:end-1);
  thr = max(3, 0.06*numel(final));
  peaks = centers(h >= thr);
  clusters = 0; prev = -9;
  for c = sort(peaks(:))'
    if (c - prev) > 0.25, clusters = clusters + 1; end
    prev = c;
  end

  if pos > 0.2 && neg > 0.2
    label = 'Polarization';
  elseif s < 0.18
    label = 'Consensus';
  elseif clusters >= 3 || s > 0.45
    label = 'Fragmentation';
  else
    label = 'Mixed / Echo chambers';
  end

  stats = struct('mean',m,'std',s,'pct_pro',pos,'pct_anti',neg, ...
                 'pct_neutral',mid,'clusters',clusters);
end
