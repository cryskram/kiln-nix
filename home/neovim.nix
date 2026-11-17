{ pkgs, ... }:
let
  inherit (import ../theme/tokens.nix) nvim;
in
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    withNodeJs = true;
    withPython3 = true;
    withRuby = false;
    extraPackages = with pkgs; [
      gcc
      gnumake
      ripgrep
      fd
      fzf
      lazygit
      git
      curl
      wget
      unzip
      nodejs
      tree-sitter
    ];
  };

  # LazyVim manages plugins at runtime; Nix only provides lazy.nvim so the first start needs no network clone.
  xdg.configFile = {
    "nvim/init.lua".text = ''
      local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
      if not vim.uv.fs_stat(lazypath) then
        lazypath = "${pkgs.vimPlugins.lazy-nvim}"
      end
      vim.opt.rtp:prepend(lazypath)

      vim.g.mapleader = " "
      vim.g.maplocalleader = "\\"

      require("lazy").setup({
        spec = {
          { "LazyVim/LazyVim", import = "lazyvim.plugins" },
          { import = "plugins" },
        },
        defaults = { lazy = false, version = false },
        install = { colorscheme = { "${nvim.colorscheme}", "habamax" } },
        checker = { enabled = false },
        performance = {
          rtp = { disabled_plugins = { "gzip", "tarPlugin", "tohtml", "tutor", "zipPlugin" } },
        },
      })
    '';

    "nvim/lua/plugins/colorscheme.lua".text = ''
      return {
        {
          "${nvim.repo}",
          name = "${nvim.name}",
          lazy = false,
          priority = 1000,
          config = function()
            ${nvim.setup}
          end,
        },
        {
          "LazyVim/LazyVim",
          opts = { colorscheme = "${nvim.colorscheme}" },
        },
      }
    '';
  };
}
