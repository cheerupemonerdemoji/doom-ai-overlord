# Windows CPU setup and reuse guide

This fork was verified on Windows 11 with an AMD Radeon RX 5700 XT. It uses the CPU because
the upstream project's CUDA-pinned `uv` configuration targets NVIDIA hardware.

## Environment used on this PC

The repository has its own `.venv`; it does not modify the independent Laya installation.
The environment was created with:

```powershell
py -3.12 -m venv .venv
.\.venv\Scripts\python.exe -m pip install --upgrade pip
.\.venv\Scripts\python.exe -m pip install -e .
```

Standard `pip` resolves the Windows CPU build of PyTorch. Do not use the repository's default
`uv sync` command on this AMD machine unless the CUDA source override is removed first.

## Run it

From this repository in PowerShell:

```powershell
.\scripts\run-windows-cpu.ps1 -Scenario basic.cfg
```

The default opens the ViZDoom window. Add `-Headless` for a terminal-only run. Other useful
examples:

```powershell
.\scripts\run-windows-cpu.ps1 -Scenario basic.cfg -HoldOpen
.\scripts\run-windows-cpu.ps1 -Scenario defend_the_center.cfg -MaxSteps 60 -HoldOpen
.\scripts\run-windows-cpu.ps1 -Scenario deadly_corridor.cfg -MaxSteps 100
```

`-HoldOpen` leaves the final game frame visible after the last episode. Press Enter in the
PowerShell window when you are ready to close it.

The launcher loads the already-downloaded English checkpoint by absolute local path, enables
Hugging Face and Transformers offline mode, and disables CUDA. Override the checkpoint with
`-ModelPath` or the `LAYA_DOOM_MODEL` environment variable.

## What happened in the verified smoke test

The command below was run headlessly with Laya 0.4.1, PyTorch 2.14.1+cpu and ViZDoom 1.3.1:

```powershell
.\scripts\run-windows-cpu.ps1 -Scenario basic.cfg -Headless
```

The agent killed the Cacodemon in two decisions and finished with reward `+95`. The two model
calls took about 1.26 seconds each on this CPU. The model emitted low-confidence `attack`
choices, while the deterministic geometry and ammo rails ensured the executable action was
valid. This is an architecture demonstration, not evidence that confidence is calibrated.

## How to reuse the pattern in another project

Treat the package as four layers:

1. **Perception** (`perception.py`) converts an untrusted or complex environment into a compact,
   factual state dictionary. In another project this could summarize a form, job listing,
   ticket or sensor feed.
2. **Questions** (`make_questions` in `decisions.py`) define a small allowlist of decisions.
   Option descriptions should be literal and distinct.
3. **Rails** (`apply_rails`) enforce invariants after the model answers. Examples: never fire
   with no ammo; never submit a form without approval; never execute an option that was not
   offered.
4. **Actuation** (`episode_steps` in `agent.py`) maps the validated choice to code you wrote.
   Laya output is data, never executable code.

For a new integration, copy the design rather than the Doom-specific geometry:

```python
state = observe_environment()              # deterministic facts
questions = build_allowlisted_questions()  # choice / noul / score schema
result = agent.predict(state, questions)   # one local model call
choice = result["answers"]["action"]["choice"]
safe_choice = enforce_invariants(choice, state)
execute_known_action(safe_choice)
```

Log the state, raw model answer, enforced answer, latency and outcome separately. That makes it
possible to see whether Laya helped, whether a rail corrected it, and whether the final action
actually worked.

## Files to study first

- `src/doom_ai_overlord/perception.py`: environment-to-state boundary.
- `src/doom_ai_overlord/decisions.py`: decision schema, capability filtering and rails.
- `src/doom_ai_overlord/agent.py`: complete observe-decide-enforce-act loop.
- `src/doom_ai_overlord/cli.py`: thin presentation layer; it should not own behavior.
- `docs/agent-design.md`: rationale and known failure modes.
