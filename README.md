# llama.cpp-vulkan

Local build of [llama.cpp](https://github.com/ggerganov/llama.cpp) with
[Vulkan](https://vulkan.org/) on Linux.

In this case, specifically targeting an AMD Radeon RX 9060 XT
([RDNA4](https://www.amd.com/en/technologies/rdna.html),
[gfx1201](https://rocm.docs.amd.com/en/latest/reference/gpu-specs.html)) on
[Void Linux](https://voidlinux.org/).

[ROCm](https://github.com/ROCm/rocm)/[HIP](https://rocm.docs.amd.com/projects/HIP/en/latest/what_is_hip.html)
was deliberately skipped. [Mesa](https://mesa3d.org/)'s [RADV Vulkan
driver](https://docs.mesa3d.org/drivers/radv.html) already supports RDNA4,
avoiding a heavy ROCm-from-source build. More context below.

## requirements

> [!IMPORTANT]
> 
> **xbps/Void Linux**: These packages are specific to
> [xbps](https://docs.voidlinux.org/xbps/index.html)/[Void
> Linux](https://voidlinux.org/). Find related packages for your distribution of
> choice. Note that distros might bundle
> [SPIR-V](https://www.khronos.org/spirv/) software with their Vulkan packages.

```
sudo xbps-install -S \
  base-devel \
  libgomp-devel \
  cmake \
  git \
  vulkan-loader \
  vulkan-loader-devel \
  Vulkan-Headers \
  mesa-vulkan-radeon \
  shaderc \
  SPIRV-Headers \
  SPIRV-Tools
```

docs only:

```
sudo xbps-install -S \
  inlyne \
  vmdfmt
```

## quick start

```
git clone <url>/llama.cpp-vulkan.git
make -C ./llama.cpp-vulkan
```

## usage

> [!WARNING]
> 
> **Model size**: `run-cli` runs a model fit for **16GB VRAM**. Consider other
> models in case of less (certainly) or more (optionally) VRAM.

| Target          | Description                                                |
|-----------------|------------------------------------------------------------|
| make all        | `install` + `run-cli` (one-shot)                           |
| make build      | (Re)configure and compile                                  |
| make verify     | List GPU devices available to llama.cpp                    |
| make run-cli    | Download (first run) and chat with a model (`gpt-oss-20b`) |
| make run-server | Run llama.cpp's web- and API-server                        |
| make install    | Clone llama.cpp (if not already present), build and verify |
| make update     | Pull latest changes for llama.cpp, rebuild and verify      |
| make clean      | Remove the build directory only                            |
| make distclean  | Remove the full clone (source + build)                     |
| make docs       | Format and preview README.md                               |

> [!NOTE]
> 
> **Model storage**: First `run-cli` downloads the model (several GB) to the
> Hugging Face cache (`~/.cache/huggingface/hub/` by default; override with
> `LLAMA_CACHE`). Subsequent runs use the cached copy.

## GPU target

The RX 9060 XT [reports](https://github.com/ollama/ollama/issues/14927) as
`gfx1201` via `rocminfo`. While Vulkan/Mesa labels it `GFX1200`. This is a
driver/tooling naming quirk, the chips are the same.

## why Vulkan, not ROCm

### native, fast RDNA4 support

Vulkan via RADV already supports RDNA4 and has benchmarked *faster* than
ROCm/HIP for token generation on this architecture (ROCm edges out on prompt
processing).

### skill issue/laziness

This chip required the (currently) very latest ROCm. Building it from source
seemed a multi-repo, ~day-long undertaking with no guarantee of a clean result
on an unsupported distro.

### no need for ROCm optimizations

Some HIP-specific optimizations (e.g. rocWMMA flash-attention) aren't available
under Vulkan. Framework-level ML work (PyTorch, training, etc.) would still
require ROCm. Vulkan only covers llama.cpp-style inference.

## troubleshooting

Issues encountered while getting this build working, in the order they showed
up, for future reference if a distro/package update reintroduces any of them.
Future-self will thank me.

### package name casing on Void Linux

The package name `vulkan-headers`, as used by other package management systems,
is (currently) not a valid package name on Void Linux. It is capitalized:
`Vulkan-Headers`. Similarly, `SPIRV-Headers` and `SPIRV-Tools` follow upstream
project capitalization rather than all-lowercase. If a future `xbps-install`
call fails with "package not found," check casing with:

```
xbps-query -Rs <partial-name>
```

### Vulkan not found

Error: `Could NOT find Vulkan (missing: Vulkan_LIBRARY)`

```
CMake Error ... Could NOT find Vulkan (missing: Vulkan_LIBRARY) (found version "1.4.341")
```

**Cause:** `vulkan-loader` provides the versioned runtime library (e.g.
`libvulkan.so.1`), but CMake's `find_package(Vulkan)` looks for the unversioned
`libvulkan.so` symlink, which lives in a separate `-devel` package.

**Fix:**

```
sudo xbps-install -S vulkan-loader-devel
```

### SPIR-V not found

Error: `Could not find a package configuration file provided by "SPIRV-Headers"`

```
CMake Error ... Could not find a package configuration file provided by "SPIRV-Headers"
```

**Cause:** llama.cpp's Vulkan backend needs the SPIR-V headers/tools as a
separate dependency from Vulkan itself, for compiling shaders.

**Fix:**

```
sudo xbps-install -S SPIRV-Headers SPIRV-Tools
```

### OpenMP not found

Warning: `OpenMP not found`

```
-- Could NOT find OpenMP_C (missing: OpenMP_C_FLAGS OpenMP_C_LIB_NAMES) 
-- Could NOT find OpenMP_CXX (missing: OpenMP_CXX_FLAGS OpenMP_CXX_LIB_NAMES) 
-- Could NOT find OpenMP (missing: OpenMP_C_FOUND OpenMP_CXX_FOUND) 
CMake Warning at ggml/src/CMakeLists.txt:231 (message):
  OpenMP not found
```

**Cause:** OpenMP development files not installed

**Fix:**

```
sudo xbps-install -S libgomp-devel
```

## Verified working environment

- [Void Linux](https://voidlinux.org/) with above requirements
- AMD Radeon RX 9060 XT (16GB)
   - of which ~15.1GB free after driver overhead
- 32GB RAM
   - of which ~11GB used by `build` at `-j 30`
