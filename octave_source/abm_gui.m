function abm_gui()
% ABM_GUI  Interactive GUI for the Opinion Dynamics ABM.
%   >> abm_gui
% Sliders control the four interaction coefficients, the bounded-confidence
% threshold, trust multipliers, agent count and time steps. Press RUN to
% simulate and view the live average-opinion trace, histogram and trajectories.
%
% Works in GNU Octave (>= 5) with the 'qt' or 'fltk' graphics toolkit.
% STTHK2133 Assignment #3 - Modeling & Simulation

  f = figure('Name','Opinion Dynamics ABM','Position',[60 60 1080 640], ...
             'Color',[0.96 0.96 0.98]);

  d.M = 6; d.K = 3; d.seed = 42;        % fixed structural defaults
  setappdata(f,'d',d);

  ax1 = axes('Parent',f,'Units','pixels','Position',[330 360 700 240]);
  title(ax1,'Average opinion vs time');
  ax2 = axes('Parent',f,'Units','pixels','Position',[330  60 330 240]);
  title(ax2,'Final opinion histogram');
  ax3 = axes('Parent',f,'Units','pixels','Position',[700  60 330 240]);
  title(ax3,'Individual trajectories');
  setappdata(f,'ax',[ax1 ax2 ax3]);

  add_slider(f,'alpha','Direct (alpha)',     0,   0.4, 0.080, 580);
  add_slider(f,'beta', 'Averaging (beta)',   0,   0.4, 0.100, 555);
  add_slider(f,'gamma','Expert (gamma)',     0,   0.5, 0.040, 530);
  add_slider(f,'delta','Influencer (delta)', 0,   0.5, 0.080, 505);
  add_slider(f,'eps',  'Confidence (eps)',   0.1, 1.0, 0.450, 480);
  add_slider(f,'sigma','Noise (sigma)',      0,   0.1, 0.012, 455);
  add_slider(f,'peer', 'Peer trust x',       0,   1.0, 1.000, 430);
  add_slider(f,'expt', 'Expert trust x',     0,   1.0, 1.000, 405);
  add_slider(f,'N',    'Citizens (N)',       50,  200, 150,   380);
  add_slider(f,'T',    'Time steps (T)',     50,  100, 80,    355);

  uicontrol(f,'Style','pushbutton','String','RUN SIMULATION', ...
            'Position',[40 300 240 36],'FontWeight','bold', ...
            'BackgroundColor',[0.2 0.5 0.9],'ForegroundColor','w', ...
            'Callback',@(src,evt) run_cb(f));

  uicontrol(f,'Style','text','Position',[20 240 300 50], 'Tag','status', ...
            'String','Set parameters and press RUN.', ...
            'HorizontalAlignment','left','BackgroundColor',[0.96 0.96 0.98]);
end

% ---------- subfunctions ----------
function add_slider(f, tag, label, lo, hi, val, y)
  uicontrol(f,'Style','text','Position',[15 y 130 18],'String',label, ...
            'HorizontalAlignment','left','BackgroundColor',[0.96 0.96 0.98]);
  s = uicontrol(f,'Style','slider','Position',[150 y 120 18], ...
                'Min',lo,'Max',hi,'Value',val,'Tag',tag);
  t = uicontrol(f,'Style','text','Position',[275 y 45 18], ...
                'String',sprintf('%.3f',val),'Tag',[tag '_lbl'], ...
                'BackgroundColor',[0.96 0.96 0.98]);
  set(s,'Callback',@(src,evt) set(t,'String',sprintf('%.3f',get(src,'Value'))));
end

function val = gv(f, tag)
  val = get(findobj(f,'Tag',tag),'Value');
end

function run_cb(f)
  d = getappdata(f,'d');
  params = struct('alpha',gv(f,'alpha'),'beta',gv(f,'beta'), ...
                  'gamma',gv(f,'gamma'),'delta',gv(f,'delta'), ...
                  'eps',gv(f,'eps'),'sigma',gv(f,'sigma'), ...
                  'peer_trust_mult',gv(f,'peer'),'exp_trust_mult',gv(f,'expt'), ...
                  'T',round(gv(f,'T')));
  N = round(gv(f,'N'));
  world = build_world(d.seed, N, d.M, d.K);
  H = opinion_dynamics_abm(params, world);
  ax = getappdata(f,'ax');
  T = params.T;

  plot(ax(1), 0:T, mean(H,2), 'r','LineWidth',2.5);
  set(ax(1),'YLim',[-1 1]); xlabel(ax(1),'Time'); ylabel(ax(1),'Mean opinion');
  title(ax(1),'Average opinion vs time');

  final = H(end,:);
  edges = linspace(-1,1,25);
  counts = histc(final, edges);
  bar(ax(2), edges, counts, 'histc'); set(ax(2),'XLim',[-1 1]);
  title(ax(2),'Final opinion histogram');

  plot(ax(3), 0:T, H(:,1:4:end), 'Color',[0.7 0.7 0.7]);
  set(ax(3),'YLim',[-1 1]); title(ax(3),'Individual trajectories');

  [label, st] = classify_outcome(final');
  set(findobj(f,'Tag','status'),'String', ...
      sprintf('Outcome: %s\nmean=%.2f  std=%.2f  clusters=%d', ...
              label, st.mean, st.std, st.clusters));
end
