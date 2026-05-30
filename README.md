# My Dotfiles

I am learning by doing this. This is my primary workflow these days, especially when I've finished creating a mental model of how I want to do something (say, a neural network architecture) and no longer need to ask questions to the internet (or to agents). Helps to keep me away from distractions.

I want to eventually consolidate my workflow to this; getting there. For chatting to LMs and running agents I mostly use Claude Code and Codex these days. For editing, it's Neovim, either on my mac or on a remote VM when I need GPUs (which is what motivated the Linux GPU setup further down).

#

Currently, I use Neovim, Ghostty, and tmux for my workflow.

![!ss1](/assets/screenshot1.png)

![!ss2](/assets/screenshot2.png)

![!ss3](/assets/screenshot3.png)

![!ss4](/assets/screenshot4.png)

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

If you're editing `.cu` files on a machine without the CUDA toolkit installed (e.g., a MacBook with no GPU like mine), clangd won't resolve CUDA identifiers like `cudaMalloc`, `__global__`, `threadIdx`, and so on. This script downloads the CUDA headers so clangd can provide proper diagnostics:

```zsh
./scripts/setup-cuda-headers.sh
brew install llvm
```

Then add a `.clangd` file to your CUDA project:

```yaml
CompileFlags:
  Add:
    [
      --cuda-host-only,
      --cuda-path=/Users/<you>/.local/cuda,
      --cuda-gpu-arch=sm_75,
    ]
```

I tuned this neovim config to prefer Homebrew's clangd over Apple's when available just for this.

Now you might be thinking: "Why do all this? Just write your code in Colab or SSH into a GPU instance?" Very good questions. Re the Colab thingy: I do this for nvcc compiling already! But I do not see real-time LSP warnings or errors there since it's just... a notebook for Python. Re the SSH thingy: when I'm SSH'd into a VM that has GPUs (which is honestly why I have the Linux GPU tmux config above), the CUDA LSP setup isn't really needed since I'm already on a real GPU machine. But I want it handy for the times I don't have a VM and just want to write or learn some GPU programming on my mac. Better than nothing, and basically covering all bases.

> [!NOTE]
> Known limitation: the `<<<>>>` kernel launch syntax still shows a false `cudaConfigureCall` error. Seems this is an [open LLVM bug](https://github.com/llvm/llvm-project/issues/86660); I tried my best to find a solution to suppress this, but at the moment my hands are empty. But all other CUDA diagnostics work correctly.
