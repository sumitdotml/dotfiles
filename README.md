# My Dotfiles

I am learning by doing this. I don't use this workflow all the time; I get into this workflow when I've finished creating a mental model of how I want to do something (say, a neural network architecture) and no longer need to ask questions to the internet (or to language models inside Cursor). Helps to keep me away from distractions.

I want to eventually consolidate my workflow to this, but I'm not there yet (I still use Cursor Chat to talk to language models to learn difficult concepts; I find it quite efficient). But I'm getting there.

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

> [!NOTE]
> If you want to use the [todo](./nvim/lua/modules/floatodo.lua) plugin, you will need to create a directory on the root of your project called `notes` and add a file called `todo.md` inside it (or wherever you want to store your todo list, but make sure to update the path in the plugin config).

![floatodo](/assets/floatodo.png)

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

Now you might be thinking: "Why do all this? Just write your code in Colab or SSH into a GPU instance?" Very good questions. Re the Colab thingy: I do this for nvcc compiling already! But I do not see real-time LSP warnings or errors there since it's just... a notebook for Python. Re the SSH thingy: I could do GPU rentals, but honestly I like the feeling of being able to write locally. Until I get my own GPU (idk when, I am broke rn), this shall do.

> [!NOTE]
> Known limitation: the `<<<>>>` kernel launch syntax still shows a false `cudaConfigureCall` error. Seems this is an [open LLVM bug](https://github.com/llvm/llvm-project/issues/86660); I tried my best to find a solution to suppress this, but at the moment my hands are empty. But all other CUDA diagnostics work correctly.
