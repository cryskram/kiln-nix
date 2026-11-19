{ pkgs, ... }:
let
  ghHelper = [
    ""
    "!gh auth git-credential"
  ];
in
{
  programs.git = {
    enable = true;
    lfs.enable = true;
    settings = {
      user.name = "cryskram";
      user.email = "vageeshgn2005@gmail.com";
      init.defaultBranch = "main";
      pull.rebase = false;
      push.autoSetupRemote = true;
      branch.autoSetupMerge = "simple";
      merge.conflictstyle = "zdiff3";
      diff.colorMoved = "default";
      core.editor = "nvim";
      core.pager = "delta";
      interactive.diffFilter = "delta --color-only";
      delta = {
        line-numbers = true;
        navigate = true;
        syntax-theme = "base16";
        paging = "never";
      };
      pager = {
        diff = "delta";
        log = "delta";
        reflog = "delta";
        show = "delta";
        blame = "delta";
      };
      alias = {
        st = "status -sb";
        co = "checkout";
        br = "branch";
        lg = "log --oneline --graph --decorate --all";
        last = "log -1 --stat";
        unstage = "restore --staged";
      };
      # Resolve gh from PATH: the module's store-path helper breaks once that gh is garbage-collected.
      credential = {
        "https://github.com".helper = ghHelper;
        "https://gist.github.com".helper = ghHelper;
      };
    };
  };

  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = false;
    settings.git_protocol = "https";
  };

  home.packages = [ pkgs.delta ];
}
