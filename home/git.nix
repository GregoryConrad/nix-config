{ lib, git, ... }:
{
  programs.git = lib.recursiveUpdate git {
    enable = true;
    lfs.enable = true;

    settings = {
      color.ui = "auto";
      pull.rebase = true;
      push.autoSetupRemote = true;

      alias = {
        br = "branch";
        co = "checkout";
        st = "status";
        ds = "diff --staged";
        amend = "commit --amend";
        dag = "log --graph --format='format:%C(yellow)%h%C(reset) %C(blue)%an <%ae>%C(reset) %C(magenta)%cr%C(reset)%C(auto)%d%C(reset)%n%s' --date-order";
      };
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };
}
