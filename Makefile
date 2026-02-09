.PHONY: api-documentation download-dependencies install-test-deps llscheck luacheck check-stylua stylua test test-python test-smoke test-parser test-ci check-mdformat mdformat coverage-html

# Git will error if the repository already exists. We ignore the error.
# NOTE: We still print out that we did the clone to the user so that they know.
#
ifeq ($(OS),Windows_NT)
    IGNORE_EXISTING =
else
    IGNORE_EXISTING = 2> /dev/null || true
endif

CONFIGURATION = .luarc.json
ROCKS_TREE ?= .rocks
ROCKS_BIN := $(ROCKS_TREE)/bin
BUSTED ?= busted
LUACOV ?= luacov

# Prefer a repo-local test runner when global tools are unavailable.
ifeq ($(shell command -v $(BUSTED) 2>/dev/null),)
    ifneq ($(wildcard $(ROCKS_BIN)/busted),)
        BUSTED := $(ROCKS_BIN)/busted
    endif
endif

ifeq ($(shell command -v $(LUACOV) 2>/dev/null),)
    ifneq ($(wildcard $(ROCKS_BIN)/luacov),)
        LUACOV := $(ROCKS_BIN)/luacov
    endif
endif

download-dependencies:
	git clone https://github.com/Bilal2453/luvit-meta.git .dependencies/luvit-meta $(IGNORE_EXISTING)
	git clone https://github.com/ColinKennedy/mega.cmdparse.git .dependencies/mega.cmdparse $(IGNORE_EXISTING)
	git clone https://github.com/ColinKennedy/mega.logging.git .dependencies/mega.logging $(IGNORE_EXISTING)
	git clone https://github.com/LuaCATS/busted.git .dependencies/busted $(IGNORE_EXISTING)
	git clone https://github.com/LuaCATS/luassert.git .dependencies/luassert $(IGNORE_EXISTING)

install-test-deps:
	luarocks --tree $(ROCKS_TREE) --lua-version=5.1 install busted
	luarocks --tree $(ROCKS_TREE) --lua-version=5.1 install luacov
	luarocks --tree $(ROCKS_TREE) --lua-version=5.1 install luacov-multiple

api-documentation:
	nvim -u scripts/make_api_documentation/minimal_init.lua -l scripts/make_api_documentation/main.lua

llscheck: download-dependencies
	VIMRUNTIME="`nvim --clean --headless --cmd 'lua io.write(os.getenv("VIMRUNTIME"))' --cmd 'quit'`" llscheck --configpath $(CONFIGURATION) .

luacheck:
	luacheck lua plugin scripts spec

check-stylua:
	stylua lua plugin scripts spec --color always --check

stylua:
	stylua lua plugin scripts spec

test: download-dependencies
	@if ! command -v nvim >/dev/null 2>&1; then \
		echo "nvim not found. Install Neovim to run Lua tests."; \
		exit 1; \
	fi
	@if [ ! -x "$(BUSTED)" ] && ! command -v "$(BUSTED)" >/dev/null 2>&1; then \
		echo "busted not found. Run 'make install-test-deps' or install busted globally with luarocks."; \
		exit 1; \
	fi
	LUA_PATH="$(ROCKS_TREE)/share/lua/5.1/?.lua;$(ROCKS_TREE)/share/lua/5.1/?/init.lua;;" \
	LUA_CPATH="$(ROCKS_TREE)/lib/lua/5.1/?.so;;" \
	nvim -u NONE -U NONE -N -i NONE --headless -c "luafile scripts/run_busted.lua" -c "quit"

test-python:
	python3 -m unittest discover -s tests -p 'test_server.py' -v

test-smoke:
	nvim --headless -u NONE -i NONE --cmd "set rtp+=." -l scripts/smoke_test.lua

test-parser:
	nvim --headless -u NONE -i NONE --cmd "set rtp+=." -l scripts/parser_test.lua

test-ci: test-python test-smoke test-parser

check-mdformat:
	python -m mdformat --check README.md doc.md FEATURES.md markdown/manual/docs/index.md

mdformat:
	python -m mdformat README.md doc.md FEATURES.md markdown/manual/docs/index.md

coverage-html: download-dependencies
	nvim -u NONE -U NONE -N -i NONE --headless -c "luafile scripts/luacov.lua" -c "quit"
	@if [ ! -x "$(LUACOV)" ] && ! command -v "$(LUACOV)" >/dev/null 2>&1; then \
		echo "luacov not found. Run 'make install-test-deps' or install luacov globally with luarocks."; \
		exit 1; \
	fi
	$(LUACOV) --reporter multiple.html
