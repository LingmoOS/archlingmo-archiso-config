OUT_DIR ?= $(CURDIR)/out
PKGBUILDER_DIR ?= /home/devalexandre/projects/devalexandre/lingmo-arch-pkgbuilder
PKGBUILDER_OUTPUTS_DIR ?= $(PKGBUILDER_DIR)/outputs
LOCAL_REPO_DIR ?= $(OUT_DIR)/localrepo
WITH_KWIN_PLUGINS ?= 1
SKIP_PKGS ?= lingmo-settings
STOP_ON_ERROR ?= 0
ONLY_PKGS ?=
WORK_DIR ?= $(OUT_DIR)/work
PROFILE_TMP ?= $(OUT_DIR)/profile-tmp
FORCE_REBUILD ?= 0

SUDO ?= sudo
MAKEPKG ?= makepkg
MAKEPKGFLAGS ?= -Ccf --noconfirm --syncdeps --needed
FIX_OWNERSHIP ?= 1

CONTAINER_ENGINE ?=
CONTAINER_IMAGE ?= archlingmo-archiso
CONTAINER_RUN_FLAGS ?= --privileged

HOST_UID := $(shell id -u)
HOST_GID := $(shell id -g)

.PHONY: help build iso iso-local pkgs embed run-iso clean
.PHONY: container-image iso-container iso-container-local
.PHONY: localrepo-from-outputs localrepo-compat
.PHONY: build

help:
	@echo "Targets:"
	@echo "  build  - alias for iso-local (offline ISO)"
	@echo "  iso    - build ISO into $(OUT_DIR)/"
	@echo "  iso-container - build ISO using docker/podman (no host archiso needed)"
	@echo "  iso-container-local - like iso-local but uses docker/podman"
	@echo "  pkgs   - build local Lingmo packages into $(LOCAL_REPO_DIR)/"
	@echo "  localrepo-from-outputs - populate $(LOCAL_REPO_DIR)/ from $(PKGBUILDER_OUTPUTS_DIR)/ and repo-add"
	@echo "  localrepo-compat - build compatibility packages into $(LOCAL_REPO_DIR)/"
	@echo "  iso-local - build ISO embedding $(LOCAL_REPO_DIR)/ as an offline pacman repo"
	@echo "  embed  - run Lingmo session inside Xephyr (host)"
	@echo "  run-iso - boot the latest ISO in QEMU"
	@echo "  clean  - remove $(OUT_DIR)/"

build: iso-local

$(OUT_DIR):
	mkdir -p $(OUT_DIR)

$(LOCAL_REPO_DIR):
	mkdir -p $(LOCAL_REPO_DIR)


iso: $(OUT_DIR)
	@set -eu; \
		command -v mkarchiso >/dev/null 2>&1 || { \
			echo "mkarchiso not found. Install archiso (e.g. 'sudo pacman -S archiso') or use 'make iso-container'." >&2; \
			exit 1; \
		}; \
		mkdir -p "$(WORK_DIR)"; \
		if [ "$(FORCE_REBUILD)" = "1" ]; then "$(SUDO)" rm -rf "$(WORK_DIR)/x86_64" "$(WORK_DIR)/iso" && "$(SUDO)" rm -f "$(WORK_DIR)"/*._*; fi; \
		rm -f "$(WORK_DIR)/iso.pacman.conf"; \
		"$(SUDO)" mkarchiso -v -w "$(WORK_DIR)" -o "$(OUT_DIR)" profile; \
		if [ "$(FIX_OWNERSHIP)" = "1" ]; then "$(SUDO)" chown -R "$(HOST_UID):$(HOST_GID)" "$(OUT_DIR)"; fi


container-image:
	@set -eu; \
		engine="$(CONTAINER_ENGINE)"; \
		if [ -z "$$engine" ]; then \
			if command -v docker >/dev/null 2>&1; then engine="docker"; \
			elif command -v podman >/dev/null 2>&1; then engine="podman"; \
			else echo "docker/podman not found. Install one or install archiso and use 'make iso'." >&2; exit 1; fi; \
		fi; \
		"$$engine" build --no-cache -t "$(CONTAINER_IMAGE)" -f Dockerfile .

iso-container: $(OUT_DIR)
	@set -eu; \
		engine="$(CONTAINER_ENGINE)"; \
		if [ -z "$$engine" ]; then \
			if command -v docker >/dev/null 2>&1; then engine="docker"; \
			elif command -v podman >/dev/null 2>&1; then engine="podman"; \
			else echo "docker/podman not found. Install one or install archiso and use 'make iso'." >&2; exit 1; fi; \
		fi; \
		mkdir -p "$(WORK_DIR)"; \
		"$$engine" image inspect "$(CONTAINER_IMAGE)" >/dev/null 2>&1 || $(MAKE) container-image CONTAINER_ENGINE="$$engine"; \
		"$$engine" run --rm $(CONTAINER_RUN_FLAGS) \
			-e FORCE_REBUILD="$(FORCE_REBUILD)" \
			-e HOST_UID="$(HOST_UID)" -e HOST_GID="$(HOST_GID)" \
			-v "$(CURDIR)":/config:ro \
			-v "$(OUT_DIR)":/out \
			-v "$(WORK_DIR)":/work \
		"$(CONTAINER_IMAGE)" sh -lc 'rm -f /work/iso.pacman.conf; if [ "$$FORCE_REBUILD" = "1" ]; then rm -rf /work/x86_64 /work/iso /work/*._*; fi; mkarchiso -v -w /work -o /out /config/profile && chown -R "$$HOST_UID:$$HOST_GID" /out /work'

iso-container-local: localrepo-from-outputs $(OUT_DIR)
	@set -eu; \
		engine="$(CONTAINER_ENGINE)"; \
		if [ -z "$$engine" ]; then \
			if command -v docker >/dev/null 2>&1; then engine="docker"; \
			elif command -v podman >/dev/null 2>&1; then engine="podman"; \
			else echo "docker/podman not found. Install one or install archiso and use 'make iso-local'." >&2; exit 1; fi; \
		fi; \
		mkdir -p "$(WORK_DIR)"; \
		"$$engine" image inspect "$(CONTAINER_IMAGE)" >/dev/null 2>&1 || $(MAKE) container-image CONTAINER_ENGINE="$$engine"; \
		"$$engine" run --rm $(CONTAINER_RUN_FLAGS) \
			-e FORCE_REBUILD="$(FORCE_REBUILD)" \
			-e HOST_UID="$(HOST_UID)" -e HOST_GID="$(HOST_GID)" \
			-v "$(CURDIR)":/config:ro \
			-v "$(OUT_DIR)":/out \
			-v "$(WORK_DIR)":/work \
			-v "$(LOCAL_REPO_DIR)":/localrepo:ro \
			"$(CONTAINER_IMAGE)" sh -lc 'sh /config/scripts/iso-container-local.sh'

embed:
	./scripts/run-xephyr.sh

run-iso:
	./scripts/run-iso.sh

clean:
	rm -rf "$(OUT_DIR)"
