STTHK2133 MODELING & SIMULATION - A252 Group Assignment #3
Opinion Dynamics in a Social Network (Agent-Based Model)
Source code: GNU Octave
===========================================================

FILES
-----
  build_world.m            Creates agents (citizens/influencers/experts),
                           the random network, trust matrices and opinions.
  opinion_dynamics_abm.m   Core simulation (the four interaction rules +
                           bounded confidence). Returns opinion history.
  classify_outcome.m       Labels the result: Consensus / Polarization /
                           Fragmentation / Mixed-Echo chambers.
  run_scenarios.m          MAIN DRIVER. Runs the 4 required scenarios and
                           saves the 2D, 3D, histogram and network figures
                           plus prints the summary table.
  abm_gui.m                Interactive GUI with sliders for every parameter
                           and a RUN button (live plots).

HOW TO RUN (GNU Octave >= 5)
----------------------------
  1. Open Octave and `cd` into this folder.
  2. Batch experiments + figures:   >> run_scenarios
  3. Interactive GUI:               >> abm_gui

MODEL SUMMARY
-------------
  Opinion O in [-1,+1]  (-1 strongly against AI, 0 neutral, +1 strongly support).
  Update per step (clamped to [-1,1]):
    O_i(t+1) = O_i + a*Tij*(Oj-Oi)            % direct (like-minded peer)
                   + b*(mean_neighbours - Oi) % averaging / echo chamber
                   + g*mean[Te*(Eexp - Oi)]   % expert correction (stabiliser)
                   + d*mean[S*Ti*(Iinf - Oi)] % influencer persuasion
                   + noise
  Bounded confidence eps: peer & influencer terms act only on sources within
  eps of the citizen's opinion (selective exposure). Expert term is unconditional.

SCENARIOS
---------
  S1 Baseline           -> Consensus (near neutral)
  S2 Strong Influencer  -> Polarization (two camps)
  S3 Strong Expert      -> Consensus / moderation
  S4 Low Trust          -> Fragmentation / echo chambers

NOTE
----
  The figures supplied in /results were rendered from an identical Python
  mirror of this model (same equations) because Octave was unavailable in the
  build environment. Running run_scenarios.m in Octave reproduces equivalent
  plots and the same qualitative outcomes.
