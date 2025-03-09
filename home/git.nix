{ git, ... }:
{
  programs.git = git // {
    enable = true;
    lfs.enable = true;

    aliases = {
      br = "branch";
      co = "checkout";
      st = "status";
      ds = "diff --staged";
      amend = "commit --amend";
      dag = "log --graph --format='format:%C(yellow)%h%C(reset) %C(blue)%an <%ae>%C(reset) %C(magenta)%cr%C(reset)%C(auto)%d%C(reset)%n%s' --date-order";
    };

    extraConfig = {
      color.ui = "auto";
      pull.rebase = true;
      push.autoSetupRemote = true;
    };

    delta.enable = true;
  };
}
