include config.mk

# Source files and Objects
SRC := $(SRC:%=$(SRC_DIR)/%)
SRC_BONUS := $(SRC_BONUS:%=$(SRC_BONUS_DIR)/%)
OBJS := $(SRC:$(SRC_DIR)/%.c=$(OBJ_DIR)/%.o)
OBJS_BONUS := $(SRC_BONUS:$(SRC_BONUS_DIR)/%.c=$(OBJ_BONUS_DIR)/%.o)

# Libs
LIBS := ft mlx glfw GL m
LIBS_TARGET := lib/libft/libft.a lib/sampalx/libmlx.a

# SampaLX (drop-in MiniLibX replacement on OpenGL/GLFW) lives in the
# lib/sampalx submodule — initialize it with `git clone --recursive`
# or `git submodule update --init --recursive`.
SLX_DIR := lib/sampalx
SLX_LIB := $(SLX_DIR)/libmlx.a
SLX_WEB_LIB := $(SLX_DIR)/libmlx_web.a

# Flags
CC := cc
CFLAGS = -Wall -Wextra -Werror
CPPFLAGS := $(addprefix -I, $(INC_DIR))
CPPFLAGS_BONUS := $(addprefix -I, $(INC_BONUS_DIR))
LDFLAGS := $(addprefix -L, $(dir $(LIBS_TARGET)))
LDLIBS := $(addprefix -l, $(LIBS))

OPT ?= 0
ifeq ($(OPT), 1)
    CFLAGS += -O3
endif

DEBUG ?= 0
ifeq ($(DEBUG), 1)
    CFLAGS += -g2 -O0
endif

RM := rm -f
RMDIR := rm -fr
DUP_DIR = mkdir -p $(@D)

all: $(NAME)

$(NAME): $(OBJS) $(LIBS_TARGET)
	$(CC) $(OBJS) $(CFLAGS) $(LDFLAGS) $(LDLIBS) -o $(NAME)

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c
	$(DUP_DIR)
	$(CC) $(CFLAGS) $(CPPFLAGS) -c $< -o $@

$(LIBS_TARGET):
	$(MAKE) -C $(@D)

# Clear error when the SampaLX submodule was not initialized.
$(SLX_DIR)/Makefile:
	@echo "[error] SampaLX submodule not initialized."
	@echo "        Run: git submodule update --init --recursive"
	@exit 1

$(SLX_LIB): $(SLX_DIR)/Makefile

bonus: $(NAME_BONUS)

$(NAME_BONUS): $(OBJS_BONUS) $(LIBS_TARGET)
	$(CC) $(OBJS_BONUS) $(CFLAGS) $(LDFLAGS) $(LDLIBS) -o $(NAME_BONUS)

$(OBJ_BONUS_DIR)/%.o: $(SRC_BONUS_DIR)/%.c
	$(DUP_DIR)
	$(CC) $(CFLAGS) $(CPPFLAGS_BONUS) -c $< -o $@

valgrind-run:
	@valgrind \
		--leak-check=full \
		--show-leak-kinds=all \
		--track-origins=yes \
		--track-fds=yes \
		--trace-children=yes \
		--trace-children-skip='*/bin/*,*/sbin/*,/usr/bin/*' \
		./$(NAME) $(INPUT)

clean:
	$(RMDIR) $(OBJ_DIR) $(OBJ_BONUS_DIR)

fclean: clean
	make -C lib/libft/ fclean
	-$(MAKE) -C $(SLX_DIR) fclean
	$(RM) $(NAME) $(NAME_BONUS)

test:
	make -C tests run

re: fclean all

# Check for development tools
check-tools:
	@echo "[INFO] Checking for development tools..."
	@command -v c_formatter_42 >/dev/null 2>&1 || { \
        echo "[WARNING] c_formatter_42 not found"; \
        echo "[INFO] Install with: pip3 install --user 42-formatter"; \
        echo ""; \
    }
	@command -v norminette >/dev/null 2>&1 || { \
        echo "[WARNING] norminette not found"; \
        echo "[INFO] Install with: pip3 install --user norminette"; \
        echo ""; \
    }
	@if command -v c_formatter_42 >/dev/null 2>&1 && command -v norminette >/dev/null 2>&1; then \
        echo "[OK] All development tools are installed"; \
    else \
        echo "[INFO] Some tools are missing. Install them for full functionality."; \
    fi

# Git hooks setup
setup: check-tools
	@bash scripts/setup-hooks.sh

# --- Web build (WebAssembly + WebGL2, via SampaLX MiniLibX replacement) ---
WEB_DIR := web
WEB_OBJ_DIR := $(WEB_DIR)/obj
WEB_NAME := minirt
WEB_OUT := $(WEB_DIR)/$(WEB_NAME).html
WEB_SHELL := $(WEB_DIR)/shell.html
WEB_PREJS := $(WEB_DIR)/pre.js

WEB_EMCC := emcc
WEB_CFLAGS := -Wall -Wextra -O3
WEB_LDFLAGS := -O3 -sUSE_GLFW=3 -sMIN_WEBGL_VERSION=2 -sMAX_WEBGL_VERSION=2 \
	-sALLOW_MEMORY_GROWTH=1
WEB_INCLUDES := -Iinc -Ilib/libft/inc -I$(SLX_DIR)/includes
WEB_PRELOAD := --preload-file scenes@/scenes
WEB_LIB := $(SLX_WEB_LIB)

WEB_SRC := $(SRC)
WEB_FT_SRC := $(wildcard lib/libft/src/*.c)
WEB_OBJS := $(WEB_SRC:$(SRC_DIR)/%.c=$(WEB_OBJ_DIR)/%.o)
WEB_FT_OBJS := $(WEB_FT_SRC:lib/libft/src/%.c=$(WEB_OBJ_DIR)/libft/%.o)

PORT ?= 8080

web: $(WEB_OUT)
	@echo "[web] built $(WEB_OUT) — serve it with: make web-run"

$(WEB_LIB): $(SLX_DIR)/Makefile
	$(MAKE) -C $(SLX_DIR) web

$(WEB_OBJ_DIR)/%.o: $(SRC_DIR)/%.c
	$(DUP_DIR)
	$(WEB_EMCC) $(WEB_CFLAGS) $(WEB_INCLUDES) -c $< -o $@

$(WEB_OBJ_DIR)/libft/%.o: lib/libft/src/%.c
	$(DUP_DIR)
	$(WEB_EMCC) $(WEB_CFLAGS) $(WEB_INCLUDES) -c $< -o $@

# Web objects include SampaLX headers, so libmlx_web.a must be built
# before compilation starts (also keeps `make -j` correct).
$(WEB_OBJS) $(WEB_FT_OBJS): $(WEB_LIB)

$(WEB_OUT): $(WEB_OBJS) $(WEB_FT_OBJS) $(WEB_LIB) $(WEB_SHELL) $(WEB_PREJS)
	$(WEB_EMCC) $(WEB_OBJS) $(WEB_FT_OBJS) $(WEB_CFLAGS) $(WEB_LDFLAGS) \
		$(WEB_PRELOAD) --shell-file $(WEB_SHELL) --pre-js $(WEB_PREJS) \
		-L$(SLX_DIR) -lmlx_web -o $(WEB_OUT)

# --- Web bonus build (same pipeline, bonus sources + bonus scenes) ---
WEB_NAME_BONUS := minirt_bonus
WEB_OUT_BONUS := $(WEB_DIR)/$(WEB_NAME_BONUS).html
WEB_PREJS_BONUS := $(WEB_DIR)/pre-bonus.js
WEB_INCLUDES_BONUS := -Iinc_bonus -Ilib/libft/inc -I$(SLX_DIR)/includes
# Scenes are preloaded whole; of the textures only the small one is bundled
# (texture/bump_map.xpm is 32 MB and would bloat the wasm data file).
WEB_PRELOAD_BONUS := --preload-file scenes@/scenes \
	--preload-file texture/moonbump1k.xpm@/texture/moonbump1k.xpm

WEB_SRC_BONUS := $(SRC_BONUS)
WEB_OBJS_BONUS := $(WEB_SRC_BONUS:$(SRC_BONUS_DIR)/%.c=$(WEB_OBJ_DIR)/bonus/%.o)

web-bonus: $(WEB_OUT_BONUS)
	@echo "[web-bonus] built $(WEB_OUT_BONUS) — serve it with: make web-run"

$(WEB_OBJ_DIR)/bonus/%.o: $(SRC_BONUS_DIR)/%.c
	$(DUP_DIR)
	$(WEB_EMCC) $(WEB_CFLAGS) $(WEB_INCLUDES_BONUS) -c $< -o $@

$(WEB_OBJS_BONUS): $(WEB_LIB)

$(WEB_OUT_BONUS): $(WEB_OBJS_BONUS) $(WEB_FT_OBJS) $(WEB_LIB) $(WEB_SHELL) \
		$(WEB_PREJS) $(WEB_PREJS_BONUS)
	$(WEB_EMCC) $(WEB_OBJS_BONUS) $(WEB_FT_OBJS) $(WEB_CFLAGS) $(WEB_LDFLAGS) \
		$(WEB_PRELOAD_BONUS) --shell-file $(WEB_SHELL) \
		--pre-js $(WEB_PREJS) --pre-js $(WEB_PREJS_BONUS) \
		-L$(SLX_DIR) -lmlx_web -o $(WEB_OUT_BONUS)

web-run: web
	@echo "[web] serving $(WEB_DIR)/ — open http://localhost:$(PORT)/$(WEB_NAME).html"
	@echo "      bonus build: http://localhost:$(PORT)/$(WEB_NAME_BONUS).html"
	@python3 -m http.server $(PORT) --directory $(WEB_DIR)

webclean:
	$(RMDIR) $(WEB_OBJ_DIR)
	$(RM) $(WEB_DIR)/$(WEB_NAME).html $(WEB_DIR)/$(WEB_NAME).js \
		$(WEB_DIR)/$(WEB_NAME).wasm $(WEB_DIR)/$(WEB_NAME).data \
		$(WEB_DIR)/$(WEB_NAME).wasm.map $(WEB_DIR)/$(WEB_NAME).js.symbols
	$(RM) $(WEB_DIR)/$(WEB_NAME_BONUS).html $(WEB_DIR)/$(WEB_NAME_BONUS).js \
		$(WEB_DIR)/$(WEB_NAME_BONUS).wasm $(WEB_DIR)/$(WEB_NAME_BONUS).data
	-$(MAKE) -C $(SLX_DIR) webclean

.PHONY: all clean fclean re bonus setup check-tools web web-bonus web-run webclean
