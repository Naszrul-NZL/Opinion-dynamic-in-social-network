function abm_gui()
% ABM_GUI  Interactive GUI for the Opinion Dynamics ABM.
%   >> abm_gui
%
% FOUR SCENARIO BUTTONS (top-left) load the assignment scenarios instantly:
%   S1 Baseline | S2 Strong Influencer | S3 Strong Expert | S4 Low Trust
% Pressing a scenario button sets the sliders AND runs the simulation. A banner
% above the plots always shows which scenario is currently displayed; as soon as
% you drag any slider it changes to "Custom (modified)" so you always know what
% you are looking at. Press RUN to (re)run with the current slider settings.
%
% The core simulation is vectorised, so a run takes well under a second.
% Works in GNU Octave (>= 5) with the 'qt' or 'fltk' graphics toolkit.
% STTHK2133 Assignment #3 - Modeling & Simulation

  f = figure('Name','Opinion Dynamics ABM - Interactive', ...
             'Position',[40 40 1180 700], 'Color',[0.95 0.96 0.98]);

  d.M = 6; d.K = 3; d.seed = 42;
  setappdata(f,'d',d);
  setappdata(f,'scenario','S1 Baseline');

  % ---- scenario banner (above the plots) ----
  uicontrol(f,'Style','text','Position',[380 662 760 30],'Tag','scenlbl', ...
            'String','Scenario: S1 Baseline','FontWeight','bold','FontSize',13, ...
            'ForegroundColor',[0.12 0.23 0.45],'HorizontalAlignment','center', ...
            'BackgroundColor',[0.88 0.92 0.98]);

  % ---- plot axes (right side) ----
  ax1 = axes('Parent',f,'Units','pixels','Position',[380 390 760 240]);
  title(ax1,'Average opinion vs time');
  ax2 = axes('Parent',f,'Units','pixels','Position',[380  60 360 250]);
  title(ax2,'Final opinion histogram');
  ax3 = axes('Parent',f,'Units','pixels','Position',[780  60 360 250]);
  title(ax3,'Individual trajectories');
  setappdata(f,'ax',[ax1 ax2 ax3]);

  % ---- scenario preset buttons (top-left) ----
  uicontrol(f,'Style','text','Position',[20 665 340 22],'String','SCENARIO PRESETS (click to load + run):', ...
            'FontWeight','bold','HorizontalAlignment','left','BackgroundColor',[0.95 0.96 0.98]);
  bcol = [0.20 0.45 0.85];
  uicontrol(f,'Style','pushbutton','String','S1 Baseline','Position',[20 635 80 28], ...
            'BackgroundColor',[0.20 0.65 0.40],'ForegroundColor','w','FontWeight','bold', ...
            'Callback',@(s,e) set_scenario(f,1));
  uicontrol(f,'Style','pushbutton','String','S2 Influencer','Position',[105 635 85 28], ...
            'BackgroundColor',[0.80 0.25 0.20],'ForegroundColor','w','FontWeight','bold', ...
            'Callback',@(s,e) set_scenario(f,2));
  uicontrol(f,'Style','pushbutton','String','S3 Expert','Position',[195 635 80 28], ...
            'BackgroundColor',[0.16 0.50 0.72],'ForegroundColor','w','FontWeight','bold', ...
            'Callback',@(s,e) set_scenario(f,3));
  uicontrol(f,'Style','pushbutton','String','S4 Low Trust','Position',[280 635 85 28], ...
            'BackgroundColor',[0.90 0.55 0.10],'ForegroundColor','w','FontWeight','bold', ...
            'Callback',@(s,e) set_scenario(f,4));

  % ---- parameter sliders ----
  add_slider(f,'alpha','Direct (alpha)',     0,   0.4, 0.080, 595);
  add_slider(f,'beta', 'Averaging (beta)',   0,   0.4, 0.100, 570);
  add_slider(f,'gamma','Expert (gamma)',     0,   0.5, 0.040, 545);
  add_slider(f,'delta','Influencer (delta)', 0,   0.5, 0.080, 520);
  add_slider(f,'eps',  'Confidence (eps)',   0.1, 1.0, 0.450, 495);
  add_slider(f,'sigma','Noise (sigma)',      0,   0.1, 0.012, 470);
  add_slider(f,'peer', 'Peer trust x',       0,   1.0, 1.000, 445);
  add_slider(f,'expt', 'Expert trust x',     0,   1.0, 1.000, 420);
  add_slider(f,'N',    'Citizens (N)',       50,  200, 120,   395);
  add_slider(f,'T',    'Time steps (T)',     50,  100, 70,    370);

  % ---- RUN button + status ----
  uicontrol(f,'Style','pushbutton','String','RUN SIMULATION', ...
            'Position',[20 325 345 34],'FontWeight','bold','FontSize',10, ...
            'BackgroundColor',bcol,'ForegroundColor','w', ...
            'Callback',@(s,e) run_cb(f));
  uicontrol(f,'Style','text','Position',[20 245 350 70],'Tag','status', ...
            'String','Click a scenario preset (S1-S4) or set sliders and press RUN.', ...
            'FontSize',9,'HorizontalAlignment','left','BackgroundColor',[1 1 1]);

  set_scenario(f,1);   % load Baseline and run on startup
end

% ===================== subfunctions =====================
function add_slider(f, tag, label, lo, hi, val, y)
  uicontrol(f,'Style','text','Position',[15 y 130 18],'String',label, ...
            'HorizontalAlignment','left','BackgroundColor',[0.95 0.96 0.98]);
  s = uicontrol(f,'Style','slider','Position',[150 y 150 18], ...
                'Min',lo,'Max',hi,'Value',val,'Tag',tag);
  t = uicontrol(f,'Style','text','Position',[305 y 55 18], ...
                'String',sprintf('%.3f',val),'Tag',[tag '_lbl'], ...
                'BackgroundColor',[0.95 0.96 0.98]);
  % dragging a slider updates its readout AND marks the run as Custom
  set(s,'Callback',@(src,e) on_slider(f, t, src));
end

function on_slider(f, t, src)
  set(t,'String',sprintf('%.3f',get(src,'Value')));
  setappdata(f,'scenario','Custom (modified)');
  set(findobj(f,'Tag','scenlbl'),'String', ...
      'Scenario: Custom (modified) - press RUN', ...
      'BackgroundColor',[0.98 0.92 0.80]);
end

function setval(f, tag, v)
  set(findobj(f,'Tag',tag),'Value',v);
  set(findobj(f,'Tag',[tag '_lbl']),'String',sprintf('%.3f',v));
end

function val = gv(f, tag)
  val = get(findobj(f,'Tag',tag),'Value');
end

function set_scenario(f, idx)
% Load one of the four assignment scenarios into the sliders, then run.
  setval(f,'alpha',0.08); setval(f,'beta',0.10); setval(f,'sigma',0.012);
  setval(f,'peer',1.0);   setval(f,'expt',1.0);
  switch idx
    case 1
      setval(f,'gamma',0.040); setval(f,'delta',0.08); setval(f,'eps',0.45);
      name = 'S1 Baseline';
    case 2
      setval(f,'gamma',0.030); setval(f,'delta',0.34); setval(f,'eps',0.45);
      name = 'S2 Strong Influencer';
    case 3
      setval(f,'gamma',0.300); setval(f,'delta',0.07); setval(f,'eps',0.55);
      name = 'S3 Strong Expert';
    case 4
      setval(f,'gamma',0.040); setval(f,'delta',0.05); setval(f,'eps',0.20);
      setval(f,'sigma',0.030); setval(f,'peer',0.30);  setval(f,'expt',0.30);
      name = 'S4 Low Trust';
  end
  setappdata(f,'scenario',name);
  set(findobj(f,'Tag','scenlbl'),'String',['Scenario: ' name], ...
      'BackgroundColor',[0.88 0.92 0.98]);
  run_cb(f);
end

function run_cb(f)
  d = getappdata(f,'d');
  scen = getappdata(f,'scenario');
  params = struct('alpha',gv(f,'alpha'),'beta',gv(f,'beta'), ...
                  'gamma',gv(f,'gamma'),'delta',gv(f,'delta'), ...
                  'eps',gv(f,'eps'),'sigma',gv(f,'sigma'), ...
                  'peer_trust_mult',gv(f,'peer'),'exp_trust_mult',gv(f,'expt'), ...
                  'T',round(gv(f,'T')));
  N = round(gv(f,'N'));
  world = build_world(d.seed, N, d.M, d.K);
  H = opinion_dynamics_abm(params, world);
  ax = getappdata(f,'ax'); T = params.T;

  % banner reflects exactly what was just run
  set(findobj(f,'Tag','scenlbl'),'String',['Scenario: ' scen]);

  plot(ax(1), 0:T, mean(H,2), 'r','LineWidth',2.5);
  set(ax(1),'YLim',[-1 1]); xlabel(ax(1),'Time'); ylabel(ax(1),'Mean opinion');
  title(ax(1),['Average opinion vs time  [' scen ']']); grid(ax(1),'on');

  final = H(end,:);
  edges = linspace(-1,1,25); counts = histc(final, edges);
  bar(ax(2), edges, counts, 'histc'); set(ax(2),'XLim',[-1 1]);
  title(ax(2),'Final opinion histogram');

  plot(ax(3), 0:T, H(:,1:4:end), 'Color',[0.7 0.7 0.7]);
  set(ax(3),'YLim',[-1 1]); title(ax(3),'Individual trajectories');

  [label, st] = classify_outcome(final');
  set(findobj(f,'Tag','status'),'String', ...
      sprintf('Scenario: %s\nOutcome: %s\nmean=%.2f  std=%.2f  %%pro=%.0f%%  %%anti=%.0f%%  clusters=%d\nN=%d  T=%d', ...
              scen, label, st.mean, st.std, 100*st.pct_pro, 100*st.pct_anti, st.clusters, N, T));
end
