# My Dotfiles

I am learning by doing this. This is my primary workflow these days, especially when I've finished creating a mental model of how I want to do something (say, a neural network architecture) and no longer need to ask questions to the internet (or to agents). Helps to keep me away from distractions.

I want to eventually consolidate my workflow to this; getting there. For chatting to LMs and running agents I mostly use Claude Code and Codex these days. For editing, it's Neovim, either on my mac or on a remote VM when I need GPUs (which is what motivated the Linux GPU setup further down).

#

Currently, I use Neovim, Ghostty, and tmux for my workflow.

![!ss1](/assets/screenshot1.png)

![!ss2](/assets/screenshot2.png)

![!ss3](/assets/screenshot3.png)

---

## Installation

**Note**: you need to have [Ghostty](https://ghostty.org/) installed before all these steps.

1. Clone the repo

```zsh
git clone https://github.com/sumitdotml/dotfiles.git

```

2. Go to the cloned directory in your terminal

```zsh
cd dotfiles
```

3. Make the install script executable:

```zsh
chmod +x install.sh
```

4. Run this command (you need to be inside the `dotfiles` directory):

```zsh
./install.sh
```

The installer is interactive and asks which dependencies and config symlinks you want to set up before changing anything.

> [!NOTE]
> If you want to use the [todo](./nvim/lua/modules/floatodo.lua) plugin, you will need to create a directory on the root of your project called `notes` and add a file called `todo.md` inside it (or wherever you want to store your todo list, but make sure to update the path in the plugin config).

![floatodo](/assets/floatodo.png)

---

## macOS desktop setup (optional)

This is separate from the main installer because it changes the desktop/window-manager look: sketchybar, JankyBorders, AeroSpace, and the menubar helper.

Run:

```zsh
./scripts/install-macos-desktop.sh
```

It symlinks the desktop configs from `sketchybar/`, `borders/`, `aerospace/`, and `wm/`, applies the daily wallpaper from `assets/macos-theme/landscapes/`, installs the wallpaper rotation LaunchAgent, backs up existing files before replacing them, restarts sketchybar and JankyBorders, and asks AeroSpace to reload its config.

---

## Linux GPU setup (optional)

For Linux boxes with `nvidia-smi` available (a workstation with a desktop GPU, a cloud/lab VM, etc.). The main `install.sh` is mac-oriented and would brew/apt install dependencies that don't always make sense on a shared remote box, so this stays a separate path.

What you get on top of plain tmux:

- a compact GPU segment in the status bar: per-GPU util/memory, with a MIG-aware fallback for sliced cards (e.g., an H100 or H200 in MIG mode shows `G0[4g+3g]` instead of a meaningless aggregate)
- SSH up/down traffic rates and RTT, only shown when over ssh
- the same tpm-managed plugin set as the mac config

Run:

```zsh
./tmux/vm-setup.sh
```

This symlinks `~/.tmux.conf` to `tmux/vm.tmux.conf`, links `~/.tmux/scripts` to `tmux/scripts`, clones tpm, and auto-installs the listed plugins. Idempotent, so safe to re-run.

> [!NOTE]
> The script's filename still says `vm-setup.sh` because that's where I first hit this need (lab VMs). The setup itself isn't VM-specific; it works on any Linux box where `nvidia-smi` exists. The GPU and SSH script segments silently no-op if those aren't applicable.

---

## CUDA LSP support (optional)

This setup is for editing `.cu` files on macOS or Linux when a CUDA toolkit is not installed. It installs a header-only CUDA 12.8 tree under `~/.local/cuda`. This is enough for clangd analysis, but it does not provide `nvcc`, a CUDA runtime, or GPU execution. CUDA 12.8 is pinned because [Clang 22 marks it as the newest fully supported CUDA release](https://github.com/llvm/llvm-project/blob/llvmorg-22.1.1/clang/include/clang/Basic/Cuda.h).

### 1. Install the headers

On macOS, install Homebrew LLVM first. The editor configuration below explicitly selects its clangd instead of the Apple-provided binary.

```zsh
brew install llvm
./scripts/setup-cuda-headers.sh
```

The script detects Intel and Arm machines, then downloads these packages from [NVIDIA's CUDA 12.8.2 redistribution](https://developer.download.nvidia.com/compute/cuda/redist/redistrib_12.8.2.json):

- `cuda_cudart` 12.8.90
- `cuda_nvcc` 12.8.93
- `cuda_cccl` 12.8.90
- `libcurand` 10.3.9.90

Each archive is checked against NVIDIA's published SHA-256 hash. If `~/.local/cuda` contains an older header tree, the script preserves it in a timestamped backup before installing the new version.

### 2. Configure clangd

The installer prints the correct `.clangd` block for the current operating system. On macOS, use:

```yaml
CompileFlags:
  Add:
    [
      --cuda-host-only,
      --cuda-path=/Users/<you>/.local/cuda,
      --cuda-gpu-arch=sm_75,
      -Xclang,
      -target-sdk-version=12.8,
    ]
```

The last two flags are macOS-only. They keep the macOS SDK version from replacing CUDA's SDK version inside Clang, which otherwise produces a false `cudaConfigureCall` diagnostic for `<<<...>>>` kernel launches.

On Linux, omit `-Xclang` and `-target-sdk-version=12.8`. Point `--cuda-path` at `~/.local/cuda`, or at the real toolkit when one is installed.

### 3. Configure the editor

The Neovim config prefers Homebrew clangd from both Apple Silicon and Intel prefixes.

For Cursor or VS Code, install the `llvm-vs-code-extensions.vscode-clangd` extension and set `clangd.path` to the result of:

```zsh
echo "$(brew --prefix llvm)/bin/clangd"
```

For example, Apple Silicon Homebrew uses:

```json
{
  "clangd.path": "/opt/homebrew/opt/llvm/bin/clangd"
}
```

Use one C/C++ diagnostics provider for CUDA files. In Cursor, add `cuda-cpp` to `cursor.cpp.disabledLanguages` when the bundled C/C++ extension is also enabled.

Now you might be thinking: "Why do all this? Just write your code in Colab or SSH into a GPU instance?" Very good questions. Re the Colab thingy: I do this for nvcc compiling already! But I do not see real-time LSP warnings or errors there since it's just... a notebook for Python. Re the SSH thingy: when I'm SSH'd into a VM that has GPUs (which is honestly why I have the Linux GPU tmux config above), the CUDA LSP setup isn't really needed since I'm already on a real GPU machine. But I want it handy for the times I don't have a VM and just want to write or learn some GPU programming on my mac. Better than nothing, and basically covering all bases.
