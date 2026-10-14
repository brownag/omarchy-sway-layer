# Research: Super+D command runner in the Omarchy Sway layer

## Summary

The repository is a Hyprland compatibility layer (not a native Sway config), and its plain config currently has no `SUPER+D` binding. For a dmenu-style prompt that launches an executable typed by the user, the practical default is **fuzzel in dmenu mode** (`fuzzel --dmenu`), invoked via a Hyprland `exec` binding; it has an explicit stdin/stdout dmenu interface, Wayland support, and avoids colliding with Omarchy's reported `SUPER+Space` application menu. **bemenu-run** is a similarly simple runner alternative. Do not use `wofi --show drun` for arbitrary commands: that mode is desktop-application discovery, not a generic executable prompt.

## Findings

1. **Repository grounding:** `config/hypr/binds_sway.conf` defines `$mainMod = SUPER` and uses Hyprland syntax (`bind = ...`); it contains no `SUPER+D` binding. Omarchy's `SUPER+Space` app-menu behavior is part of the task context, not documented in this repository's binding file. **Support:** direct evidence (repository inspection). **Confidence:** high.

2. **Recommended option — fuzzel:** Fuzzel supports Wayland and documents `--dmenu` as dmenu-compatible mode; its dmenu interface reads candidates on stdin and emits selected text on stdout. Its documented executable runner is also available as `fuzzel --launch`/`fuzzel --launch-prefix`, but that launcher is application-oriented; for literal arbitrary executable input use dmenu mode, then run the returned command deliberately through a shell or a dedicated launcher helper. **Sources:** [Fuzzel README](https://codeberg.org/dnkl/fuzzel) (upstream project documentation), [Fuzzel man page](https://man.archlinux.org/man/fuzzel.1.en). **Support:** direct evidence for modes and I/O; recommendation is researcher inference. **Confidence:** high.

3. **Alternative — bemenu:** bemenu is a Wayland-native, dmenu-compatible launcher/menu; `bemenu-run` provides a command-runner interface and is the most direct option when the desired UX is “type a command and execute it.” It can be bound directly as `exec, bemenu-run` in the layer's Hyprland config. **Sources:** [bemenu upstream README](https://github.com/Cloudef/bemenu), [bemenu-run manual](https://man.archlinux.org/man/bemenu-run.1.en). **Support:** direct evidence; the precise integration line is an implementation recommendation. **Confidence:** high.

4. **wofi distinction:** Wofi offers `--show run` for a run-mode prompt, as well as `--show drun` for desktop entries. For arbitrary typed executables choose `run`, not `drun`; Wofi's mode/activation behavior and shell evaluation should be verified against the installed version. **Source:** [Wofi upstream README](https://hg.sr.ht/~scoopta/wofi). **Support:** direct evidence for modes. **Confidence:** medium (upstream documentation is the authority; package/version differences may matter).

5. **Binding shape:** In this Hyprland config, the likely form is `bind = SUPER, d, exec, fuzzel --dmenu` (or `bemenu-run` / `wofi --show run`). This preserves `SUPER+Space` and maps the requested chord to a separate prompt. Add the binding to `config/hypr/binds_sway.conf`, not a Sway `bindsym` file. **Source:** [Hyprland binds wiki](https://wiki.hyprland.org/Configuring/Binds/), plus repository binding syntax. **Support:** interpretation and recommendation. **Confidence:** high.

## Implementation recommendation

Prefer **`fuzzel --dmenu`** where fuzzel is installed, bind it to `SUPER+D` using Hyprland's `exec` dispatcher, and feed its selected output to a small launcher helper if arbitrary command execution is required. If the available fuzzel/package build provides suitable launch behavior directly, validate it locally before relying on it. Prefer **`bemenu-run`** for a zero-glue arbitrary command-runner UX. Do not bind both to the same chord. Keep the command as a single executable/argument in the compositor binding rather than using shell-string concatenation.

Example candidate:

```ini
bind = SUPER, d, exec, bemenu-run
```

or, for a dmenu protocol workflow:

```ini
bind = SUPER, d, exec, fuzzel --dmenu
```

The latter opens a generic dmenu prompt but by itself does not prove that typed text is executed; dmenu mode is a chooser protocol. A launcher wrapper must capture the result and launch it. Test with a simple executable and inspect the runner's behavior before treating the binding as an arbitrary command runner.

## Caveats

- **Shell semantics and safety:** shell syntax such as pipes, redirects, variable expansion, quoting, and `&&` only works if a shell is explicitly invoked. Passing user-entered text to `sh -c` enables shell syntax but also executes shell code; this is intentional for a command prompt, not a safe treatment of untrusted input. For executable-only behavior, parse/split arguments without shell evaluation and execute directly. Avoid unsafe quoting or `eval`.
- **Arguments:** determine whether the chosen runner accepts a command plus arguments, or only resolves executable names. PATH lookup and argument splitting are distinct behaviors; document them and test quoted arguments and paths containing spaces if those matter. Do not assume dmenu protocol performs shell parsing.
- **Prompt vs application menu:** Omarchy's `SUPER+Space` is an app menu per task context. Keep `SUPER+D` distinct; `wofi --show drun` or fuzzel's app launcher may duplicate that app-menu role rather than provide arbitrary command execution.
- **Dependencies/environment:** confirm runner installed and available in the Hyprland process PATH. Wayland-native tools are preferable to X11 dmenu under this environment. Actual behavior depends on installed version and configuration.
- **Current repo scope:** README explicitly says this is a Hyprland/Omarchy layer, not native Sway configuration; avoid Sway-specific `bindsym` syntax in implementation.

## Contradictions

None found in the reviewed project documentation. One important semantic distinction: fuzzel's dmenu mode is a generic selection interface and should not be equated with automatic execution of arbitrary typed input; the runner behavior requires a launcher integration.

## Missing evidence

- The repository does not specify which of bemenu, fuzzel, or wofi is installed on the target Omarchy setup.
- Omarchy's upstream current `SUPER+Space` binding was not independently verified during this research; it is treated as stated in the task.
- No live compositor test was run, and no versions/package configuration were available. Confirm the chosen tool's command and PATH on target.

## Sources

- Kept: [Fuzzel upstream README](https://codeberg.org/dnkl/fuzzel) — Wayland launcher and dmenu-mode reference.
- Kept: [Fuzzel man page](https://man.archlinux.org/man/fuzzel.1.en) — command options and mode details.
- Kept: [bemenu upstream README](https://github.com/Cloudef/bemenu) — upstream project and runner overview.
- Kept: [bemenu-run manual](https://man.archlinux.org/man/bemenu-run.1.en) — runner command behavior.
- Kept: [Wofi upstream README](https://hg.sr.ht/~scoopta/wofi) — run and drun modes.
- Kept: [Hyprland binds documentation](https://wiki.hyprland.org/Configuring/Binds/) — correct compositor binding syntax for this repository.
- Rejected/deprioritized: generic third-party comparisons and blog recommendations — upstream documentation is more relevant; no benchmark is needed for this UX choice.

## Next steps

1. Check installed runner availability on the target Omarchy system and choose fuzzel or bemenu accordingly.
2. For arbitrary free-form shell commands, define a small, reviewed helper with explicit shell semantics; otherwise use bemenu-run's executable-runner behavior.
3. Add only the chosen `SUPER+D` binding and test it in a live Hyprland session alongside `SUPER+Space`.
