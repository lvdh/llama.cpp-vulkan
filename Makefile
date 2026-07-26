REPO_URL := https://github.com/ggerganov/llama.cpp
REPO_DIR := llama.cpp
BUILD_DIR := $(REPO_DIR)/build
JOBS := $(shell nproc --ignore=2)
NGL := 99

.PHONY: all build verify run-cli run-server install update clean distclean docs

.NOTPARALLEL: all
all: install run

$(REPO_DIR)/.git:
	git clone --depth 1 $(REPO_URL) $(REPO_DIR)

build:
	# llama-cli
	cmake -S $(REPO_DIR) -B $(BUILD_DIR) -DGGML_VULKAN=ON -DCMAKE_BUILD_TYPE=Release
	cmake --build $(BUILD_DIR) --config Release -- -j $(JOBS)
	# llama-server
	cmake --build $(BUILD_DIR) --config Release -- -j $(JOBS) llama-server

verify:
	$(BUILD_DIR)/bin/llama-cli --list-devices

run-cli:
	$(MAKE) verify
	$(BUILD_DIR)/bin/llama-cli -hf ggml-org/gpt-oss-20b-GGUF -ngl $(NGL)
	#$(BUILD_DIR)/bin/llama-cli -hf Qwen/Qwen3-14B-GGUF:Q4_K_M -ngl $(NGL)

run-server:
	$(BUILD_DIR)/bin/llama-server --cache-list
	$(BUILD_DIR)/bin/llama-server -sm none -ngl $(NGL)

install: $(REPO_DIR)/.git
	$(MAKE) build
	$(MAKE) verify

update: $(REPO_DIR)/.git
	git -C $(REPO_DIR) pull --depth 1
	$(MAKE) build
	$(MAKE) verify

clean:
	rm -rf $(BUILD_DIR)

distclean:
	rm -rf $(REPO_DIR)

docs:
	vmdfmt -w README.md && inlyne view README.md
