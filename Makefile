.PHONY: install uninstall test lint

install:
	./bin/apply-sway-layer

uninstall:
	./bin/apply-sway-layer --uninstall

test:
	@set -eu; \
	for tool in shellcheck jq luac; do \
		if ! command -v "$$tool" >/dev/null 2>&1; then \
			printf 'make test: required tool not found: %s\n' "$$tool" >&2; \
			exit 1; \
		fi; \
	done; \
	bash -n bin/apply-sway-layer scripts/backup.sh scripts/detect_omarchy.sh scripts/sway-group-move scripts/bemenu-themed tests/test-sway-group-move.sh tests/test-sway-installer.sh tests/test-bemenu-themed.sh; \
	shellcheck bin/apply-sway-layer scripts/backup.sh scripts/detect_omarchy.sh scripts/sway-group-move scripts/bemenu-themed tests/test-sway-group-move.sh tests/test-sway-installer.sh tests/test-bemenu-themed.sh; \
	json_tmp=$$(mktemp); \
	trap 'rm -f "$$json_tmp"' EXIT HUP INT TERM; \
	cp config/waybar/config.jsonc "$$json_tmp"; \
	jq empty "$$json_tmp"; \
	luac -p config/hypr/binds_sway.lua tests/test-sway-bindings.lua; \
	bash tests/test-sway-group-move.sh; \
	bash tests/test-sway-installer.sh; \
	bash tests/test-bemenu-themed.sh; \
	lua tests/test-sway-bindings.lua; \
	grep -Fq 'bind = SUPER, h, movefocus, l' config/hypr/binds_sway.conf; \
	grep -Fq 'bind = SUPER, LEFT, movefocus, l' config/hypr/binds_sway.conf; \
	grep -Fq 'bind = SUPER, DOWN, movefocus, d' config/hypr/binds_sway.conf; \
	grep -Fq 'bind = SUPER, UP, movefocus, u' config/hypr/binds_sway.conf; \
	grep -Fq 'bind = SUPER, RIGHT, movefocus, r' config/hypr/binds_sway.conf; \
	grep -Fq 'bind = SUPER SHIFT, LEFT, exec, sh -c' config/hypr/binds_sway.conf; \
	grep -Fq 'bind = SUPER SHIFT, DOWN, exec, sh -c' config/hypr/binds_sway.conf; \
	grep -Fq 'bind = SUPER SHIFT, UP, exec, sh -c' config/hypr/binds_sway.conf; \
	grep -Fq 'bind = SUPER SHIFT, RIGHT, exec, sh -c' config/hypr/binds_sway.conf; \
	grep -Fq 'bind = SUPER, d, exec, bemenu-run' config/hypr/binds_sway.conf; \
	grep -Fq -- '--enable-bemenu-themed' README.md; \
	grep -Fq '0004-live-palette-wrapper-for-bemenu' docs/decisions/README.md; \
	grep -Fq 'scripts/bemenu-themed' AGENTS.md; \
	grep -Fq 'bind = SUPER, b, togglesplit, horizontal' config/hypr/binds_sway.conf; \
	grep -Fq 'bind = SUPER, v, togglesplit, vertical' config/hypr/binds_sway.conf; \
	grep -Fq 'binde = , LEFT, resizeactive, -20 0' config/hypr/binds_sway.conf; \
	grep -Fq 'binde = , DOWN, resizeactive, 0 20' config/hypr/binds_sway.conf; \
	grep -Fq 'binde = , UP, resizeactive, 0 -20' config/hypr/binds_sway.conf; \
	grep -Fq 'binde = , RIGHT, resizeactive, 20 0' config/hypr/binds_sway.conf; \
	grep -Fq 'submap = resize' config/hypr/binds_sway.conf; \
	grep -Fq 'source = ~/.config/hypr/binds_sway.conf' bin/apply-sway-layer; \
	grep -Fq 'pcall(require, "sway_bindings")' bin/apply-sway-layer; \
	grep -Fq 'waybar -c ~/.config/waybar/sway-dense.jsonc -s ~/.config/waybar/sway-dense.css' bin/apply-sway-layer; \
	printf 'make test: all static checks passed\n'

lint: test
