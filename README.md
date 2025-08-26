# HuggingFace Fast Downloader

A fast and efficient tool for downloading files from HuggingFace repositories. Features parallel downloads, SHA verification, and flexible file filtering.

Forked from https://github.com/lxe/hfdownloader who forked from https://github.com/bodaay/HuggingFaceModelDownloader

## Features

- Fast parallel downloads with configurable connections
- SHA verification for file integrity
- Flexible file filtering with glob and regex patterns
- Custom destination paths for downloaded files
- Support for private repositories with token authentication
- Tree view of repository contents

## Installation

### Using Go Install (Recommended)

```bash
go install github.com/sammcj/hfdownloader@HEAD
```

### From Source

```bash
# Clone the repository
git clone --depth=2 https://github.com/sammcj/hfdownloader
cd hfdownloader

# Build for your platform
make              # Build for macos, linux-am64
make macos        # macOS only (ARM64)
make linux        # Linux only (AMD64)
make linux-arm    # Linux ARM only (ARMv7, ARM64)

# Install locally
make install-macos     # macOS
make install-linux     # Linux AMD64
make install-linux-arm # Linux ARM
```

For more build options, run `make help`.

## Usage

### List Repository Contents

```bash
# List all files in a repository
hfdownloader -r runwayml/stable-diffusion-v1-5 list

# List files in a specific branch/commit
hfdownloader -r runwayml/stable-diffusion-v1-5 list -b main
```

### Practical Examples

```shell
hfdownloader -c 20 -r unsloth/DeepSeek-V3.1-GGUF download -f '*UD-Q2_K_XL*' -t $HUGGINGFACE_API_TOKEN
Files to download:
  UD-Q2_K_XL/DeepSeek-V3.1-UD-Q2_K_XL-00001-of-00006.gguf -> UD-Q2_K_XL/DeepSeek-V3.1-UD-Q2_K_XL-00001-of-00006.gguf (46.5 GiB)
  UD-Q2_K_XL/DeepSeek-V3.1-UD-Q2_K_XL-00002-of-00006.gguf -> UD-Q2_K_XL/DeepSeek-V3.1-UD-Q2_K_XL-00002-of-00006.gguf (45.2 GiB)
  UD-Q2_K_XL/DeepSeek-V3.1-UD-Q2_K_XL-00003-of-00006.gguf -> UD-Q2_K_XL/DeepSeek-V3.1-UD-Q2_K_XL-00003-of-00006.gguf (46.2 GiB)
  UD-Q2_K_XL/DeepSeek-V3.1-UD-Q2_K_XL-00004-of-00006.gguf -> UD-Q2_K_XL/DeepSeek-V3.1-UD-Q2_K_XL-00004-of-00006.gguf (45.8 GiB)
  UD-Q2_K_XL/DeepSeek-V3.1-UD-Q2_K_XL-00005-of-00006.gguf -> UD-Q2_K_XL/DeepSeek-V3.1-UD-Q2_K_XL-00005-of-00006.gguf (45.5 GiB)
  UD-Q2_K_XL/DeepSeek-V3.1-UD-Q2_K_XL-00006-of-00006.gguf -> UD-Q2_K_XL/DeepSeek-V3.1-UD-Q2_K_XL-00006-of-00006.gguf (8.7 GiB)

Proceed with download? [y/N] y
UD-Q2_K_XL/DeepSeek-V3.1-UD-Q2_K_XL-00001-of-00006.gguf [             ] 1.3% | 622.8 MiB / 46.5 GiB | 103.7 MiB/s | ETA: 453ss
```

Examples:

```bash
# List all files in the repository
hfdownloader -r Kijai/flux-fp8 list

# Download all the vae safetensor files into the current directory
hfdownloader -r Kijai/flux-fp8 download -f "*vae*.safetensors"

# Download VAE model to models/vae directory (auto-confirm)
hfdownloader -r Kijai/flux-fp8 download -f "*vae*.safetensors:models/vae" -y

# Same as above but with 16 concurrent connections for faster download
hfdownloader -r Kijai/flux-fp8 download -f "*vae*.safetensors:models/vae" -y -c 16

# Use a regex instead of glob and skip SHA verification for faster downloads
hfdownloader -r Kijai/flux-fp8 download -f "/e4m3fn/:models/checkpoints" -y -c 16 --skip-sha
```

## Pattern Matching

The downloader supports two types of patterns:

1. Glob Patterns (default):
   - `*.safetensors` - match all safetensors files
   - `model/*.bin` - match bin files in model directory
   - `v2-*/*.ckpt` - match ckpt files in v2-* directories

2. Regex Patterns (enclosed in /):
   - `/\\.safetensors$/` - match files ending in .safetensors
   - `/v\\d+/.*\\.bin$/` - match .bin files in version directories
   - `/model_(fp16|fp32)\\.bin$/` - match specific model variants

## Destination Mapping

You can specify custom destinations for downloaded files using the format `pattern:destination`. The destination can be specified in three ways:

1. Directory with trailing slash (`path/to/dir/`):
   ```bash
   # Downloads flux-vae.safetensors to models/vae/flux-vae.safetensors
   hfdownloader -r org/model download -f "flux-vae.safetensors:models/vae/"

   # Downloads all .safetensors files to models/checkpoints/, keeping original names
   hfdownloader -r org/model download -f "*.safetensors:models/checkpoints/"

   # Downloads multiple files to different directories
   hfdownloader -r org/model download \
     -f "model.safetensors:models/full/" \
     -f "vae/*.pt:models/vae/" \
     -f "configs/*.yaml:configs/"
   ```

2. Existing directory (without trailing slash):
   ```bash
   # If models/vae exists, this will show a warning and download to:
   # models/vae/flux-vae.safetensors
   hfdownloader -r org/model download -f "flux-vae.safetensors:models/vae"

   # Multiple files to existing directory
   hfdownloader -r org/model download \
     -f "*-fp16.safetensors:models/checkpoints" \
     -f "*-fp32.safetensors:models/checkpoints"
   ```

3. Full file path (new filename):
   ```bash
   # Downloads to exact path with new filename
   hfdownloader -r org/model download \
     -f "model.safetensors:models/checkpoints/sd15-base.safetensors"

   # Multiple files with custom names
   hfdownloader -r org/model download \
     -f "model-v1.safetensors:models/v1-base.safetensors" \
     -f "model-v2.safetensors:models/v2-base.safetensors"
   ```

### Complex Examples

1. Mix of patterns and destinations:
   ```bash
   # Download multiple file types to organized directories
   hfdownloader -r org/model download \
     -f "*.safetensors:models/" \
     -f "*.pt:weights/" \
     -f "*.yaml:configs/" \
     -f "*.json:configs/"
   ```

2. Using regex with custom destinations:
   ```bash
   # Download specific model variants to organized directories
   hfdownloader -r org/model download \
     -f "/model_fp16.*/:models/fp16/" \
     -f "/model_fp32.*/:models/fp32/" \
     -f "/vae_v[0-9].*/:models/vae/"
   ```

3. Combining glob patterns with specific paths:
   ```bash
   # Download and rename some files, keep original names for others
   hfdownloader -r org/model download \
     -f "model.safetensors:models/sd15-base.safetensors" \
     -f "vae/*.pt:models/vae/" \
     -f "embeddings/*.pt:embeddings/" \
     -f "lora/*.safetensors:models/lora/"
   ```

4. Using patterns with directory structure:
   ```bash
   # Match nested directory structure
   hfdownloader -r org/model download \
     -f "v1/*/*.safetensors:models/v1/" \
     -f "v2/*/*.safetensors:models/v2/" \
     -f "*/vae/*.pt:models/vae/"
   ```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

Apache 2.0 License - see LICENSE file for details

(Note: Before forking, the original repo stated it was MIT licensed, but the included license was actually Apache 2.0. This repo is now Apache 2.0 licensed.)
