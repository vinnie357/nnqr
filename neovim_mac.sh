#!/bin/bash

# Neovim + Nerd Fonts + Lazy.nvim Setup Script for macOS
# Run with: bash neovim_mac.sh

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on macOS
check_environment() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        log_success "macOS detected"
        # Check architecture
        if [[ "$(uname -m)" == "arm64" ]]; then
            log_info "Apple Silicon (M1/M2/M3) detected"
            IS_ARM64=true
        else
            log_info "Intel Mac detected"
            IS_ARM64=false
        fi
    else
        log_error "This script is designed for macOS. Detected OS: $OSTYPE"
        exit 1
    fi
}

# Check if Homebrew is installed
check_homebrew() {
    if ! command -v brew >/dev/null 2>&1; then
        log_warning "Homebrew not found. Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH for Apple Silicon
        if [ "$IS_ARM64" = true ]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    else
        log_success "Homebrew is installed"
    fi
}

# Install dependencies
install_dependencies() {
    log_info "Installing dependencies..."
    
    # Update Homebrew
    brew update
    
    # Install required tools
    brew install git curl wget fontconfig
    
    # Install development tools if needed
    if ! command -v gcc >/dev/null 2>&1; then
        log_info "Installing Xcode Command Line Tools..."
        xcode-select --install 2>/dev/null || true
    fi
    
    log_success "Dependencies installed"
}

# Install Neovim
install_neovim() {
    log_info "Installing Neovim..."
    
    # Check if nvim is already installed and get version
    if command -v nvim >/dev/null 2>&1; then
        CURRENT_VERSION=$(nvim --version | head -n1 | cut -d' ' -f2)
        log_info "Current Neovim version: $CURRENT_VERSION"
        
        # Check if version is >= 0.8.0
        if ! check_nvim_version "$CURRENT_VERSION"; then
            log_warning "Neovim version $CURRENT_VERSION is too old. lazy.nvim requires >= 0.8.0"
            log_info "Installing newer version..."
            brew reinstall neovim
        else
            log_success "Neovim version $CURRENT_VERSION is compatible"
            return
        fi
    else
        # Install fresh
        brew install neovim
    fi
    
    # Create symlinks if they don't exist
    if ! command -v vim >/dev/null 2>&1; then
        ln -sf "$(which nvim)" /usr/local/bin/vim 2>/dev/null || true
    fi
    if ! command -v vi >/dev/null 2>&1; then
        ln -sf "$(which nvim)" /usr/local/bin/vi 2>/dev/null || true
    fi
    
    # Final verification
    if command -v nvim >/dev/null 2>&1; then
        FINAL_VERSION=$(nvim --version 2>/dev/null | head -n1 | cut -d' ' -f2- | tr -d '\n')
        log_success "Neovim installed successfully"
        log_info "Full version command output:"
        nvim --version 2>&1 | head -n3 || echo "Version command failed"
        
        if [ -n "$FINAL_VERSION" ] && check_nvim_version "$FINAL_VERSION"; then
            log_success "Version check passed!"
        else
            log_warning "Version check failed or version too old. Using fallback config."
            USE_FALLBACK_CONFIG=true
        fi
    else
        log_error "Neovim installation failed"
        exit 1
    fi
}

# Check if Neovim version is >= 0.8.0
check_nvim_version() {
    local version=$1
    
    # Debug output
    log_info "Checking version: '$version'"
    
    if [ -z "$version" ]; then
        log_warning "Version string is empty"
        return 1
    fi
    
    # Extract version numbers (remove 'v' prefix if present and handle different formats)
    version=${version#v}
    version=${version#NVIM }  # Remove "NVIM " prefix if present
    
    # Handle version strings like "0.9.5" or "0.10.0-dev+sha"
    local clean_version=$(echo "$version" | sed 's/[^0-9.].*$//' | head -c 10)
    
    log_info "Clean version: '$clean_version'"
    
    if [ -z "$clean_version" ]; then
        log_warning "Could not extract version numbers"
        return 1
    fi
    
    local major=$(echo "$clean_version" | cut -d. -f1)
    local minor=$(echo "$clean_version" | cut -d. -f2)
    
    log_info "Major: $major, Minor: $minor"
    
    # Check if major > 0 or (major == 0 and minor >= 8)
    if [ "$major" -gt 0 ] || ([ "$major" -eq 0 ] && [ "$minor" -ge 8 ]); then
        log_success "Version $clean_version is compatible with lazy.nvim"
        return 0  # Version is OK
    else
        log_warning "Version $clean_version is too old for lazy.nvim (need >= 0.8.0)"
        return 1  # Version is too old
    fi
}

# Install Nerd Fonts
install_nerd_fonts() {
    log_info "Installing Nerd Fonts..."
    
    # No need to tap homebrew/cask-fonts anymore - it's deprecated
    # Fonts are now in the main cask repository
    
    # Install JetBrains Mono Nerd Font
    if brew list --cask font-jetbrains-mono-nerd-font &>/dev/null; then
        log_info "JetBrains Mono Nerd Font already installed"
    else
        brew install --cask font-jetbrains-mono-nerd-font
    fi
    
    log_success "Nerd Fonts installed"
    log_warning "Don't forget to set your terminal font to 'JetBrainsMono Nerd Font'"
}

# Setup dotfiles directory structure
setup_dotfiles() {
    log_info "Setting up dotfiles structure..."
    
    DOTFILES_DIR="$HOME/.dotfiles"
    
    # Create dotfiles directory if it doesn't exist
    if [ ! -d "$DOTFILES_DIR" ]; then
        mkdir -p "$DOTFILES_DIR"
        cd "$DOTFILES_DIR"
        git init
        log_info "Initialized dotfiles repository at $DOTFILES_DIR"
    else
        log_warning "Dotfiles directory already exists"
    fi
    
    # Create directory structure
    mkdir -p "$DOTFILES_DIR"/{nvim,bash,zsh,git}
    mkdir -p "$HOME/.config"
    
    log_success "Dotfiles structure created"
}

# Create Neovim configuration
create_nvim_config() {
    log_info "Creating Neovim configuration..."
    
    DOTFILES_DIR="$HOME/.dotfiles"
    NVIM_CONFIG_DIR="$DOTFILES_DIR/nvim"
    
    if [ "$USE_FALLBACK_CONFIG" = true ]; then
        log_info "Creating fallback configuration for older Neovim..."
        create_fallback_config "$NVIM_CONFIG_DIR"
    else
        log_info "Creating modern configuration with lazy.nvim..."
        create_lazy_config "$NVIM_CONFIG_DIR"
    fi
    
    # Create lua directory for additional configs
    mkdir -p "$NVIM_CONFIG_DIR/lua"
    
    log_success "Neovim configuration created"
}

# Create modern config with lazy.nvim
create_lazy_config() {
    local config_dir=$1
    
    # Create init.lua
    cat > "$config_dir/init.lua" << 'EOF'
-- Neovim Configuration with Lazy.nvim
-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Basic settings
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.cursorline = true
vim.opt.termguicolors = true
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.mouse = "a"
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.swapfile = false
vim.opt.undofile = true

-- Key mappings
local keymap = vim.keymap.set

-- General keymaps
keymap("n", "<leader>w", ":w<CR>", { desc = "Save file" })
keymap("n", "<leader>q", ":q<CR>", { desc = "Quit" })
keymap("n", "<leader>x", ":x<CR>", { desc = "Save and quit" })

-- Better window navigation
keymap("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
keymap("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
keymap("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
keymap("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

-- Resize windows
keymap("n", "<C-Up>", ":resize +2<CR>", { desc = "Increase window height" })
keymap("n", "<C-Down>", ":resize -2<CR>", { desc = "Decrease window height" })
keymap("n", "<C-Left>", ":vertical resize -2<CR>", { desc = "Decrease window width" })
keymap("n", "<C-Right>", ":vertical resize +2<CR>", { desc = "Increase window width" })

-- Buffer navigation
keymap("n", "<S-l>", ":bnext<CR>", { desc = "Next buffer" })
keymap("n", "<S-h>", ":bprevious<CR>", { desc = "Previous buffer" })

-- Clear search highlighting
keymap("n", "<Esc>", ":nohl<CR>", { desc = "Clear search highlighting" })

-- Better indenting
keymap("v", "<", "<gv", { desc = "Indent left" })
keymap("v", ">", ">gv", { desc = "Indent right" })

-- Move text up and down
keymap("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move text down" })
keymap("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move text up" })

-- Setup plugins
require("lazy").setup({
  -- Color scheme
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      vim.cmd.colorscheme "catppuccin-mocha"
    end,
  },

  -- File explorer
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("nvim-tree").setup({
        view = {
          width = 30,
        },
        renderer = {
          group_empty = true,
        },
        filters = {
          dotfiles = false,
        },
      })
      keymap("n", "<leader>e", ":NvimTreeToggle<CR>", { desc = "Toggle file explorer" })
    end,
  },

  -- Status line
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({
        options = {
          theme = "catppuccin",
          component_separators = { left = "", right = "" },
          section_separators = { left = "", right = "" },
        },
      })
    end,
  },

  -- Fuzzy finder
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("telescope").setup({})
      local builtin = require("telescope.builtin")
      keymap("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
      keymap("n", "<leader>fg", builtin.live_grep, { desc = "Live grep" })
      keymap("n", "<leader>fb", builtin.buffers, { desc = "Find buffers" })
      keymap("n", "<leader>fh", builtin.help_tags, { desc = "Help tags" })
    end,
  },

  -- Treesitter for syntax highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "lua", "vim", "vimdoc", "query", "python", "javascript", "typescript", "bash" },
        sync_install = false,
        auto_install = true,
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },
      })
    end,
  },

  -- Auto pairs
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      require("nvim-autopairs").setup({})
    end,
  },

  -- Comment plugin
  {
    "numToStr/Comment.nvim",
    config = function()
      require("Comment").setup()
    end,
  },

  -- Git signs
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup()
    end,
  },

  -- Buffer line
  {
    "akinsho/bufferline.nvim",
    version = "*",
    dependencies = "nvim-tree/nvim-web-devicons",
    config = function()
      require("bufferline").setup({
        options = {
          numbers = "none",
          close_command = "bdelete! %d",
          right_mouse_command = "bdelete! %d",
          left_mouse_command = "buffer %d",
          middle_mouse_command = nil,
          indicator = {
            icon = "▎",
            style = "icon",
          },
          buffer_close_icon = "",
          modified_icon = "●",
          close_icon = "",
          left_trunc_marker = "",
          right_trunc_marker = "",
          max_name_length = 30,
          max_prefix_length = 30,
          tab_size = 21,
          diagnostics = "nvim_lsp",
          diagnostics_update_in_insert = false,
          color_icons = true,
          show_buffer_icons = true,
          show_buffer_close_icons = true,
          show_close_icon = true,
          show_tab_indicators = true,
          persist_buffer_sort = true,
          separator_style = "thin",
          enforce_regular_tabs = true,
          always_show_bufferline = true,
        },
      })
    end,
  },

  -- Which key for keybind help
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    init = function()
      vim.o.timeout = true
      vim.o.timeoutlen = 300
    end,
    config = function()
      require("which-key").setup()
    end,
  },
})
EOF
}

# Create fallback config for older Neovim
create_fallback_config() {
    local config_dir=$1
    
    cat > "$config_dir/init.lua" << 'EOF'
-- Basic Neovim Configuration (Compatible with older versions)

-- Leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Basic settings
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.cursorline = true
vim.opt.termguicolors = true
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.mouse = "a"
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.swapfile = false

-- Enable syntax highlighting
vim.cmd('syntax enable')
vim.cmd('filetype plugin indent on')

-- Set colorscheme (built-in)
vim.cmd('colorscheme desert')

-- Key mappings
local function map(mode, lhs, rhs, opts)
    local options = { noremap = true, silent = true }
    if opts then
        options = vim.tbl_extend('force', options, opts)
    end
    vim.keymap.set(mode, lhs, rhs, options)
end

-- General keymaps
map("n", "<leader>w", ":w<CR>")
map("n", "<leader>q", ":q<CR>")
map("n", "<leader>x", ":x<CR>")

-- Better window navigation
map("n", "<C-h>", "<C-w>h")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
map("n", "<C-l>", "<C-w>l")

-- Resize windows
map("n", "<C-Up>", ":resize +2<CR>")
map("n", "<C-Down>", ":resize -2<CR>")
map("n", "<C-Left>", ":vertical resize -2<CR>")
map("n", "<C-Right>", ":vertical resize +2<CR>")

-- Buffer navigation
map("n", "<S-l>", ":bnext<CR>")
map("n", "<S-h>", ":bprevious<CR>")

-- Clear search highlighting
map("n", "<Esc>", ":nohl<CR>")

-- Better indenting
map("v", "<", "<gv")
map("v", ">", ">gv")

-- Move text up and down
map("v", "J", ":m '>+1<CR>gv=gv")
map("v", "K", ":m '<-2<CR>gv=gv")

-- File explorer (using built-in netrw)
map("n", "<leader>e", ":Explore<CR>")

-- Simple status line
vim.opt.laststatus = 2
vim.opt.statusline = "%f %h%w%m%r %=%(%l,%c%V%) %P"

-- Basic autocmds
vim.api.nvim_create_autocmd("BufReadPost", {
    pattern = "*",
    callback = function()
        local line = vim.fn.line("'\"")
        if line > 1 and line <= vim.fn.line("$") then
            vim.cmd('normal! g`"')
        end
    end,
})

print("Basic Neovim config loaded! Use <leader>e for file explorer.")
print("Upgrade to Neovim >= 0.8.0 for the full configuration with plugins.")
EOF
}

# Create shell configuration (bash and zsh for macOS)
create_shell_config() {
    log_info "Creating shell configurations..."
    
    DOTFILES_DIR="$HOME/.dotfiles"
    BASH_CONFIG_DIR="$DOTFILES_DIR/bash"
    ZSH_CONFIG_DIR="$DOTFILES_DIR/zsh"
    
    # Create bash configuration
    cat > "$BASH_CONFIG_DIR/bashrc" << 'EOF'
# Custom bash configuration for macOS

# Aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias vim='nvim'
alias vi='nvim'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline'
alias gd='git diff'

# Environment variables
export EDITOR=nvim
export VISUAL=nvim

# Better history
export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTCONTROL=ignoreboth
shopt -s histappend

# Better completion
if [ -f $(brew --prefix)/etc/bash_completion ]; then
    . $(brew --prefix)/etc/bash_completion
fi

# Colored prompt
export PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# Add Homebrew to PATH
eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null || eval "$(/usr/local/bin/brew shellenv)" 2>/dev/null

# Add local bin to PATH
export PATH="$HOME/.local/bin:$PATH"
EOF

    # Create zsh configuration
    cat > "$ZSH_CONFIG_DIR/zshrc" << 'EOF'
# Custom zsh configuration for macOS

# Enable colors
autoload -U colors && colors

# History settings
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt appendhistory
setopt sharehistory
setopt incappendhistory

# Aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias vim='nvim'
alias vi='nvim'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline'
alias gd='git diff'

# Environment variables
export EDITOR=nvim
export VISUAL=nvim

# Prompt
PROMPT='%{$fg[green]%}%n@%m%{$reset_color%}:%{$fg[blue]%}%~%{$reset_color%}$ '

# Add Homebrew to PATH
eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null || eval "$(/usr/local/bin/brew shellenv)" 2>/dev/null

# Add local bin to PATH
export PATH="$HOME/.local/bin:$PATH"

# Enable completion
autoload -Uz compinit && compinit

# Better completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu select
EOF

    log_success "Shell configurations created"
}

# Create git configuration
create_git_config() {
    log_info "Creating git configuration template..."
    
    DOTFILES_DIR="$HOME/.dotfiles"
    GIT_CONFIG_DIR="$DOTFILES_DIR/git"
    
    cat > "$GIT_CONFIG_DIR/gitconfig" << 'EOF'
[user]
    # name = Your Name
    # email = your.email@example.com

[core]
    editor = nvim
    autocrlf = input

[init]
    defaultBranch = main

[pull]
    rebase = false

[push]
    default = simple

[alias]
    st = status
    co = checkout
    br = branch
    ci = commit
    unstage = reset HEAD --
    last = log -1 HEAD
    visual = !gitk
    lg = log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit

[color]
    ui = auto

[diff]
    tool = vimdiff

[merge]
    tool = vimdiff
EOF

    log_success "Git configuration template created"
}

# Create symlinks
create_symlinks() {
    log_info "Creating symlinks..."
    
    DOTFILES_DIR="$HOME/.dotfiles"
    
    # Backup existing configs
    [ -f "$HOME/.bashrc" ] && cp "$HOME/.bashrc" "$HOME/.bashrc.backup"
    [ -f "$HOME/.zshrc" ] && cp "$HOME/.zshrc" "$HOME/.zshrc.backup"
    [ -d "$HOME/.config/nvim" ] && mv "$HOME/.config/nvim" "$HOME/.config/nvim.backup"
    [ -f "$HOME/.gitconfig" ] && cp "$HOME/.gitconfig" "$HOME/.gitconfig.backup"
    
    # Create symlinks
    ln -sf "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
    
    # Detect current shell and update appropriate config
    CURRENT_SHELL=$(basename "$SHELL")
    
    if [[ "$CURRENT_SHELL" == "zsh" ]]; then
        if ! grep -q "source.*\.dotfiles/zsh/zshrc" "$HOME/.zshrc" 2>/dev/null; then
            echo "" >> "$HOME/.zshrc"
            echo "# Source custom configuration" >> "$HOME/.zshrc"
            echo "source ~/.dotfiles/zsh/zshrc" >> "$HOME/.zshrc"
        fi
        log_info "Updated .zshrc"
    else
        if ! grep -q "source.*\.dotfiles/bash/bashrc" "$HOME/.bashrc" 2>/dev/null; then
            echo "" >> "$HOME/.bashrc"
            echo "# Source custom configuration" >> "$HOME/.bashrc"
            echo "source ~/.dotfiles/bash/bashrc" >> "$HOME/.bashrc"
        fi
        log_info "Updated .bashrc"
    fi
    
    log_success "Symlinks created"
    log_warning "Edit ~/.dotfiles/git/gitconfig with your name and email, then run:"
    log_warning "ln -sf ~/.dotfiles/git/gitconfig ~/.gitconfig"
}

# Create install script for dotfiles
create_install_script() {
    log_info "Creating dotfiles install script..."
    
    DOTFILES_DIR="$HOME/.dotfiles"
    
    cat > "$DOTFILES_DIR/install.sh" << 'EOF'
#!/bin/bash
# Dotfiles install script for macOS

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing dotfiles from $DOTFILES_DIR"

# Backup existing configs
[ -f "$HOME/.bashrc" ] && cp "$HOME/.bashrc" "$HOME/.bashrc.backup"
[ -f "$HOME/.zshrc" ] && cp "$HOME/.zshrc" "$HOME/.zshrc.backup"
[ -d "$HOME/.config/nvim" ] && mv "$HOME/.config/nvim" "$HOME/.config/nvim.backup"
[ -f "$HOME/.gitconfig" ] && cp "$HOME/.gitconfig" "$HOME/.gitconfig.backup"

# Create config directory
mkdir -p "$HOME/.config"

# Create symlinks
ln -sf "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"

# Detect shell and update config
CURRENT_SHELL=$(basename "$SHELL")

if [[ "$CURRENT_SHELL" == "zsh" ]]; then
    if ! grep -q "source.*\.dotfiles/zsh/zshrc" "$HOME/.zshrc" 2>/dev/null; then
        echo "" >> "$HOME/.zshrc"
        echo "# Source custom configuration" >> "$HOME/.zshrc"
        echo "source ~/.dotfiles/zsh/zshrc" >> "$HOME/.zshrc"
    fi
    echo "Updated .zshrc"
else
    if ! grep -q "source.*\.dotfiles/bash/bashrc" "$HOME/.bashrc" 2>/dev/null; then
        echo "" >> "$HOME/.bashrc"
        echo "# Source custom configuration" >> "$HOME/.bashrc"
        echo "source ~/.dotfiles/bash/bashrc" >> "$HOME/.bashrc"
    fi
    echo "Updated .bashrc"
fi

echo "Dotfiles installed successfully!"
echo "Don't forget to:"
echo "1. Edit ~/.dotfiles/git/gitconfig with your details"
echo "2. Run: ln -sf ~/.dotfiles/git/gitconfig ~/.gitconfig"
echo "3. Restart your terminal or run: source ~/.${CURRENT_SHELL}rc"
EOF

    chmod +x "$DOTFILES_DIR/install.sh"
    
    log_success "Install script created"
}

# Create README
create_readme() {
    log_info "Creating README..."
    
    DOTFILES_DIR="$HOME/.dotfiles"
    
    cat > "$DOTFILES_DIR/README.md" << 'EOF'
# Dotfiles for macOS

Personal configuration files for development environment on macOS.

## Contents

- **nvim/**: Neovim configuration with Lazy.nvim plugin manager
- **bash/**: Bash configuration and aliases
- **zsh/**: Zsh configuration and aliases
- **git/**: Git configuration template

## Installation

Run the install script:

```bash
cd ~/.dotfiles
./install.sh
```

## Manual Setup

1. **Git Configuration**: Edit `git/gitconfig` with your name and email:
   ```bash
   ln -sf ~/.dotfiles/git/gitconfig ~/.gitconfig
   ```

2. **Terminal Font**: Set your terminal to use "JetBrainsMono Nerd Font"

3. **Reload Configuration**:
   ```bash
   # For zsh (default on macOS)
   source ~/.zshrc
   
   # For bash
   source ~/.bashrc
   ```

## Neovim Plugins

The configuration includes:
- Catppuccin color scheme
- Nvim-tree file explorer
- Lualine status line
- Telescope fuzzy finder
- Treesitter syntax highlighting
- Auto pairs
- Comment plugin
- Git signs
- Buffer line
- Which-key

## Key Bindings

- Leader key: `<Space>`
- File explorer: `<leader>e`
- Find files: `<leader>ff`
- Live grep: `<leader>fg`
- Save: `<leader>w`
- Quit: `<leader>q`

## Terminal Configuration

### iTerm2
1. Preferences → Profiles → Text
2. Set Font to "JetBrainsMono Nerd Font"

### Terminal.app
1. Preferences → Profiles → Text
2. Click "Change" next to Font
3. Select "JetBrainsMono Nerd Font"

### Alacritty
Add to `~/.config/alacritty/alacritty.yml`:
```yaml
font:
  normal:
    family: "JetBrainsMono Nerd Font"
  size: 12.0
```
EOF

    log_success "README created"
}

# Main setup function
main() {
    log_info "Starting Neovim + Nerd Fonts + Lazy.nvim setup for macOS..."
    
    # Initialize variables
    USE_FALLBACK_CONFIG=false
    
    check_environment
    check_homebrew
    install_dependencies
    install_neovim
    install_nerd_fonts
    setup_dotfiles
    create_nvim_config
    create_shell_config
    create_git_config
    create_symlinks
    create_install_script
    create_readme
    
    log_success "Setup completed successfully!"
    echo ""
    log_info "Next steps:"
    
    # Detect current shell
    CURRENT_SHELL=$(basename "$SHELL")
    if [[ "$CURRENT_SHELL" == "zsh" ]]; then
        echo "1. Restart your terminal or run: source ~/.zshrc"
    else
        echo "1. Restart your terminal or run: source ~/.bashrc"
    fi
    
    echo "2. Set your terminal font to 'JetBrainsMono Nerd Font'"
    echo "3. Edit ~/.dotfiles/git/gitconfig with your name and email"
    echo "4. Run: ln -sf ~/.dotfiles/git/gitconfig ~/.gitconfig"
    
    if [ "$USE_FALLBACK_CONFIG" = true ]; then
        echo "5. Open nvim to test your basic configuration"
        echo ""
        log_warning "Note: Using fallback config due to older Neovim version"
        log_warning "For full plugin support, run: brew upgrade neovim"
    else
        echo "5. Open nvim and let Lazy.nvim install plugins"
    fi
    
    echo ""
    log_info "Your dotfiles are now managed in ~/.dotfiles"
    log_info "Run 'nvim' to start using your new setup!"
}

# Run main function
main "$@"