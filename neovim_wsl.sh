#!/bin/bash

# Neovim + Nerd Fonts + Lazy.nvim Setup Script for WSL
# Run with: bash setup.sh

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

# Check if running on WSL or Linux
check_environment() {
    if grep -q Microsoft /proc/version 2>/dev/null; then
        log_success "WSL detected"
        IS_WSL=true
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        log_success "Linux detected"
        IS_WSL=false
    else
        log_error "This script is designed for WSL or Linux. Detected OS: $OSTYPE"
        exit 1
    fi
}

# Install dependencies
install_dependencies() {
    log_info "Installing dependencies..."
    
    if [ -f /etc/debian_version ]; then
        # Debian/Ubuntu
        sudo apt update
        sudo apt install -y curl git unzip fontconfig build-essential software-properties-common
    elif [ -f /etc/redhat-release ]; then
        # RedHat/Fedora/CentOS
        if command -v dnf >/dev/null 2>&1; then
            sudo dnf install -y curl git unzip fontconfig gcc gcc-c++ make
        elif command -v yum >/dev/null 2>&1; then
            sudo yum install -y curl git unzip fontconfig gcc gcc-c++ make
        fi
    elif [ -f /etc/arch-release ]; then
        # Arch Linux
        sudo pacman -S --noconfirm curl git unzip fontconfig base-devel
    else
        log_warning "Unknown distribution. Attempting to install with common package managers..."
        # Try common package managers
        if command -v apt >/dev/null 2>&1; then
            sudo apt update && sudo apt install -y curl git unzip fontconfig build-essential
        elif command -v dnf >/dev/null 2>&1; then
            sudo dnf install -y curl git unzip fontconfig gcc gcc-c++ make
        elif command -v pacman >/dev/null 2>&1; then
            sudo pacman -S --noconfirm curl git unzip fontconfig base-devel
        else
            log_error "No supported package manager found. Please install manually: curl git unzip fontconfig build-essential"
            exit 1
        fi
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
            install_neovim_appimage
        else
            log_success "Neovim version $CURRENT_VERSION is compatible"
            return
        fi
    else
        # Install fresh
        if [ -f /etc/debian_version ]; then
            log_info "Installing via apt (Debian/Ubuntu)..."
            # Remove old version first
            sudo apt remove -y neovim 2>/dev/null || true
            
            # Try to add PPA for latest version
            if command -v add-apt-repository >/dev/null 2>&1; then
                sudo add-apt-repository ppa:neovim-ppa/stable -y 2>/dev/null || true
                sudo apt update
                sudo apt install -y neovim
                
                # Check if we got a good version
                if command -v nvim >/dev/null 2>&1; then
                    NEW_VERSION=$(nvim --version | head -n1 | cut -d' ' -f2)
                    if ! check_nvim_version "$NEW_VERSION"; then
                        log_warning "PPA version $NEW_VERSION still too old, installing AppImage..."
                        sudo apt remove -y neovim
                        install_neovim_appimage
                    fi
                else
                    install_neovim_appimage
                fi
            else
                install_neovim_appimage
            fi
        elif [ -f /etc/redhat-release ]; then
            log_info "Installing via dnf/yum (RedHat/Fedora)..."
            if command -v dnf >/dev/null 2>&1; then
                sudo dnf install -y neovim
            elif command -v yum >/dev/null 2>&1; then
                sudo yum install -y neovim
            fi
            
            # Check version and fallback if needed
            if command -v nvim >/dev/null 2>&1; then
                NEW_VERSION=$(nvim --version 2>/dev/null | head -n1 | cut -d' ' -f2)
                if ! check_nvim_version "$NEW_VERSION"; then
                    log_warning "Package manager version $NEW_VERSION too old, installing AppImage..."
                    if command -v dnf >/dev/null 2>&1; then
                        sudo dnf remove -y neovim
                    elif command -v yum >/dev/null 2>&1; then
                        sudo yum remove -y neovim
                    fi
                    if ! install_neovim_appimage; then
                        log_error "AppImage installation failed"
                        USE_FALLBACK_CONFIG=true
                    fi
                fi
            else
                if ! install_neovim_appimage; then
                    log_error "AppImage installation failed"
                    USE_FALLBACK_CONFIG=true
                fi
            fi
        elif [ -f /etc/arch-release ]; then
            log_info "Installing via pacman (Arch Linux)..."
            sudo pacman -S --noconfirm neovim
        else
            log_info "Installing via AppImage (fallback)..."
            if ! install_neovim_appimage; then
                log_error "AppImage installation failed"
                USE_FALLBACK_CONFIG=true
            fi
        fi
    fi
    
    # Create symlinks if they don't exist
    if ! command -v vim >/dev/null 2>&1; then
        sudo ln -sf "$(which nvim)" /usr/local/bin/vim 2>/dev/null || true
    fi
    if ! command -v vi >/dev/null 2>&1; then
        sudo ln -sf "$(which nvim)" /usr/local/bin/vi 2>/dev/null || true
    fi
    
    # Final verification
    if command -v nvim >/dev/null 2>&1; then
        log_info "Getting final version..."
        # Try multiple ways to get version info
        FINAL_VERSION=""
        
        # Method 1: Standard version command
        if nvim --version >/dev/null 2>&1; then
            FINAL_VERSION=$(nvim --version 2>/dev/null | head -n1 | cut -d' ' -f2- | tr -d '\n')
        fi
        
        # Method 2: If that fails, try lua command
        if [ -z "$FINAL_VERSION" ]; then
            FINAL_VERSION=$(nvim --headless -c 'lua print(vim.version())' -c 'q' 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -n1)
        fi
        
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
        log_error "Neovim installation failed completely"
        log_info "Installing minimal vim as fallback..."
        
        if [ -f /etc/debian_version ]; then
            sudo apt install -y vim-tiny
        elif command -v dnf >/dev/null 2>&1; then
            sudo dnf install -y vim-minimal
        elif command -v pacman >/dev/null 2>&1; then
            sudo pacman -S --noconfirm vim
        fi
        
        USE_FALLBACK_CONFIG=true
        log_warning "Using vim instead of nvim"
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

# Install Neovim via AppImage
install_neovim_appimage() {
    log_info "Installing Neovim from GitHub releases..."
    
    # Remove old nvim if it exists in /usr/local/bin
    sudo rm -f /usr/local/bin/nvim
    
    # Try tar.gz first (more reliable than AppImage)
    log_info "Trying tar.gz download (more compatible)..."
    if install_neovim_tarball; then
        return 0
    fi
    
    # Fallback to AppImage with extraction
    log_info "Tar.gz failed, trying AppImage with extraction..."
    if install_neovim_appimage_extract; then
        return 0
    fi
    
    return 1
}

# Install Neovim via tar.gz (most reliable)
install_neovim_tarball() {
    log_info "Downloading Neovim tar.gz..."
    
    # Detect architecture more accurately
    local arch=$(uname -m)
    local nvim_arch=""
    
    # Check what we're actually running on
    log_info "System architecture: $arch"
    
    # For WSL/compatibility, let's be more specific
    if [ -f /proc/version ] && grep -q Microsoft /proc/version; then
        log_info "WSL detected - checking Windows architecture..."
        # In WSL, often better to use x86_64 even if uname shows something else
        nvim_arch="x86_64"
    else
        case "$arch" in
            x86_64|amd64)
                nvim_arch="x86_64"
                ;;
            aarch64|arm64)
                # Double-check if this is really ARM or emulated
                if command -v file >/dev/null 2>&1 && file /bin/bash | grep -q "x86-64"; then
                    log_info "Detected x86_64 emulation, using x86_64 binary"
                    nvim_arch="x86_64"
                else
                    nvim_arch="arm64"
                fi
                ;;
            *)
                log_warning "Unsupported architecture: $arch, using x86_64..."
                nvim_arch="x86_64"
                ;;
        esac
    fi
    
    log_info "Using Neovim architecture: $nvim_arch"
    
    # Use direct URLs for reliability
    local download_url
    if [ "$nvim_arch" = "x86_64" ]; then
        download_url="https://github.com/neovim/neovim/releases/download/v0.10.1/nvim-linux-x86_64.tar.gz"
    else
        download_url="https://github.com/neovim/neovim/releases/download/v0.10.1/nvim-linux-arm64.tar.gz"
    fi
    
    log_info "Downloading from: $download_url"
    
    # Download tar.gz
    if ! curl -L "$download_url" -o nvim-linux.tar.gz --fail --show-error; then
        log_error "Failed to download Neovim tar.gz for $nvim_arch"
        
        # Force x86_64 as final fallback
        if [ "$nvim_arch" != "x86_64" ]; then
            log_info "Trying x86_64 as final fallback..."
            download_url="https://github.com/neovim/neovim/releases/download/v0.10.1/nvim-linux-x86_64.tar.gz"
            if ! curl -L "$download_url" -o nvim-linux.tar.gz --fail --show-error; then
                log_error "All download attempts failed"
                return 1
            fi
        else
            return 1
        fi
    fi
    
    # Check if file was downloaded properly
    if [ ! -f nvim-linux.tar.gz ] || [ ! -s nvim-linux.tar.gz ]; then
        log_error "Downloaded tar.gz file is empty or missing"
        return 1
    fi
    
    # Extract
    log_info "Extracting Neovim..."
    tar -xzf nvim-linux.tar.gz
    
    # Find the extracted directory
    local nvim_dir=$(find . -maxdepth 1 -name "nvim-linux*" -type d | head -n1)
    if [ -z "$nvim_dir" ]; then
        log_error "Could not find extracted Neovim directory"
        ls -la  # Debug: show what was extracted
        return 1
    fi
    
    log_info "Found extracted directory: $nvim_dir"
    
    # Check binary architecture matches what we expect
    if command -v file >/dev/null 2>&1; then
        local binary_arch=$(file "$nvim_dir/bin/nvim")
        log_info "Binary architecture: $binary_arch"
        
        # If we downloaded x86_64 but got ARM64, there's a mismatch
        if [ "$nvim_arch" = "x86_64" ] && echo "$binary_arch" | grep -q "ARM aarch64"; then
            log_error "Architecture mismatch: requested x86_64 but got ARM64"
            return 1
        fi
    fi
    
    # Test the binary
    log_info "Testing binary compatibility..."
    if ! "$nvim_dir/bin/nvim" --version >/dev/null 2>&1; then
        log_error "Extracted Neovim binary is not compatible with this system"
        
        # Try to provide helpful error info
        if command -v ldd >/dev/null 2>&1; then
            log_info "Checking library dependencies:"
            ldd "$nvim_dir/bin/nvim" 2>&1 | head -10
        fi
        return 1
    fi
    
    # Install to /usr/local
    log_info "Installing to /usr/local..."
    sudo cp -r "$nvim_dir"/* /usr/local/
    
    # Cleanup
    rm -rf nvim-linux.tar.gz "$nvim_dir"
    
    # Make sure /usr/local/bin is in PATH
    if [[ ":$PATH:" != *":/usr/local/bin:"* ]]; then
        export PATH="/usr/local/bin:$PATH"
    fi
    
    log_success "Neovim tar.gz installed successfully"
    return 0
}

# Install Neovim AppImage with extraction (fallback)
install_neovim_appimage_extract() {
    log_info "Downloading and extracting Neovim AppImage..."
    
    # Use direct URL for x86_64 AppImage (most compatible)
    local download_url="https://github.com/neovim/neovim/releases/download/v0.10.1/nvim.appimage"
    
    log_info "Downloading from: $download_url"
    
    # Download AppImage
    if ! curl -L "$download_url" -o nvim.appimage --fail --show-error; then
        log_error "Failed to download Neovim AppImage"
        return 1
    fi
    
    chmod +x nvim.appimage
    
    # Try to run normally first
    if ./nvim.appimage --version >/dev/null 2>&1; then
        log_info "AppImage works normally, installing..."
        sudo mv nvim.appimage /usr/local/bin/nvim
    else
        log_info "AppImage needs extraction (no FUSE support)..."
        
        # Extract AppImage
        if ! ./nvim.appimage --appimage-extract >/dev/null 2>&1; then
            log_error "Failed to extract AppImage"
            return 1
        fi
        
        # Test extracted binary
        if ! ./squashfs-root/usr/bin/nvim --version >/dev/null 2>&1; then
            log_error "Extracted Neovim binary is not working"
            return 1
        fi
        
        # Install extracted version
        sudo cp -r squashfs-root/usr/* /usr/local/
        
        # Cleanup
        rm -rf nvim.appimage squashfs-root
    fi
    
    # Make sure /usr/local/bin is in PATH
    if [[ ":$PATH:" != *":/usr/local/bin:"* ]]; then
        export PATH="/usr/local/bin:$PATH"
    fi
    
    log_success "Neovim AppImage installed successfully"
    return 0
}

# Install Nerd Fonts
install_nerd_fonts() {
    log_info "Installing Nerd Fonts..."
    
    # Create fonts directory
    mkdir -p ~/.local/share/fonts
    
    # Download and install JetBrains Mono Nerd Font
    FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/JetBrainsMono.zip"
    TEMP_DIR="/tmp/nerd-fonts"
    
    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR"
    
    log_info "Downloading JetBrains Mono Nerd Font..."
    curl -L "$FONT_URL" -o JetBrainsMono.zip
    unzip -q JetBrainsMono.zip
    
    # Install fonts
    find . -name "*.ttf" -exec cp {} ~/.local/share/fonts/ \;
    
    # Refresh font cache
    fc-cache -fv > /dev/null 2>&1
    
    # Cleanup
    rm -rf "$TEMP_DIR"
    
    log_success "Nerd Fonts installed"
    if [ "$IS_WSL" = true ]; then
        log_warning "Don't forget to set your Windows Terminal font to 'JetBrainsMono Nerd Font'"
    else
        log_warning "Don't forget to set your terminal font to 'JetBrainsMono Nerd Font'"
    fi
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
    mkdir -p "$DOTFILES_DIR"/{nvim,bash,git}
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

# Create bash configuration
create_bash_config() {
    log_info "Creating bash configuration..."
    
    DOTFILES_DIR="$HOME/.dotfiles"
    BASH_CONFIG_DIR="$DOTFILES_DIR/bash"
    
    # Create .bashrc extension
    cat > "$BASH_CONFIG_DIR/bashrc" << 'EOF'
# Custom bash configuration

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
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi

# Colored prompt
export PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# WSL specific settings
if [ "$IS_WSL" = true ]; then
    export WSLENV=USERPROFILE/p
fi

# Add local bin to PATH
export PATH="$HOME/.local/bin:$PATH"
EOF

    log_success "Bash configuration created"
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
    [ -d "$HOME/.config/nvim" ] && mv "$HOME/.config/nvim" "$HOME/.config/nvim.backup"
    [ -f "$HOME/.gitconfig" ] && cp "$HOME/.gitconfig" "$HOME/.gitconfig.backup"
    
    # Create symlinks
    ln -sf "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
    
    # Append our bashrc to the existing one
    if ! grep -q "source.*\.dotfiles/bash/bashrc" "$HOME/.bashrc" 2>/dev/null; then
        echo "" >> "$HOME/.bashrc"
        echo "# Source custom configuration" >> "$HOME/.bashrc"
        echo "source ~/.dotfiles/bash/bashrc" >> "$HOME/.bashrc"
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
# Dotfiles install script

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing dotfiles from $DOTFILES_DIR"

# Backup existing configs
[ -f "$HOME/.bashrc" ] && cp "$HOME/.bashrc" "$HOME/.bashrc.backup"
[ -d "$HOME/.config/nvim" ] && mv "$HOME/.config/nvim" "$HOME/.config/nvim.backup"
[ -f "$HOME/.gitconfig" ] && cp "$HOME/.gitconfig" "$HOME/.gitconfig.backup"

# Create config directory
mkdir -p "$HOME/.config"

# Create symlinks
ln -sf "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"

# Update bashrc
if ! grep -q "source.*\.dotfiles/bash/bashrc" "$HOME/.bashrc" 2>/dev/null; then
    echo "" >> "$HOME/.bashrc"
    echo "# Source custom configuration" >> "$HOME/.bashrc"
    echo "source ~/.dotfiles/bash/bashrc" >> "$HOME/.bashrc"
fi

echo "Dotfiles installed successfully!"
echo "Don't forget to:"
echo "1. Edit ~/.dotfiles/git/gitconfig with your details"
echo "2. Run: ln -sf ~/.dotfiles/git/gitconfig ~/.gitconfig"
echo "3. Restart your terminal or run: source ~/.bashrc"
EOF

    chmod +x "$DOTFILES_DIR/install.sh"
    
    log_success "Install script created"
}

# Create README
create_readme() {
    log_info "Creating README..."
    
    DOTFILES_DIR="$HOME/.dotfiles"
    
    cat > "$DOTFILES_DIR/README.md" << 'EOF'
# Dotfiles

Personal configuration files for development environment.

## Contents

- **nvim/**: Neovim configuration with Lazy.nvim plugin manager
- **bash/**: Bash configuration and aliases
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

## WSL Terminal Configuration

Add this to your Windows Terminal settings:

```json
{
    "profiles": {
        "list": [
            {
                "name": "Ubuntu",
                "source": "Windows.Terminal.Wsl",
                "fontFace": "JetBrainsMono Nerd Font",
                "fontSize": 12
            }
        ]
    }
}
```
EOF

    log_success "README created"
}

# Main setup function
main() {
    log_info "Starting Neovim + Nerd Fonts + Lazy.nvim setup for WSL/Linux..."
    
    # Initialize variables
    USE_FALLBACK_CONFIG=false
    
    check_environment
    install_dependencies
    install_neovim
    install_nerd_fonts
    setup_dotfiles
    create_nvim_config
    create_bash_config
    create_git_config
    create_symlinks
    create_install_script
    create_readme
    
    log_success "Setup completed successfully!"
    echo ""
    log_info "Next steps:"
    echo "1. Restart your terminal or run: source ~/.bashrc"
    echo "2. Set your terminal font to 'JetBrainsMono Nerd Font'"
    echo "3. Edit ~/.dotfiles/git/gitconfig with your name and email"
    echo "4. Run: ln -sf ~/.dotfiles/git/gitconfig ~/.gitconfig"
    if [ "$USE_FALLBACK_CONFIG" = true ]; then
        echo "5. Open nvim to test your basic configuration"
        echo ""
        log_warning "Note: Using fallback config due to older Neovim version"
        log_warning "For full plugin support, manually install Neovim >= 0.8.0"
    else
        echo "5. Open nvim and let Lazy.nvim install plugins"
    fi
    echo ""
    log_info "Your dotfiles are now managed in ~/.dotfiles"
    log_info "Run 'nvim' to start using your new setup!"
}

# Run main function
main "$@"
