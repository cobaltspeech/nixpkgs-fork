{ lib
, buildGoModule
, fetchFromGitHub
, writeText
, runtimeShell
, installShellFiles
, ncurses
, perl
}:
buildGoModule rec {
  pname = "fzf";
  version = "0.35.1";

  src = fetchFromGitHub {
    owner = "junegunn";
    repo = pname;
    rev = version;
    sha256 = "sha256-Zn//z66apkhUd2RvLZSV8PqmocQdVmPngfyK4jmWsfs=";
  };

  vendorSha256 = "sha256-EjcOcrADHdwTCGimv2BRvbjqSZxz4isWhGmPbWQ7YDE=";

  outputs = [ "out" "man" ];

  nativeBuildInputs = [ installShellFiles ];

  buildInputs = [ ncurses ];

  ldflags = [
    "-s" "-w" "-X main.version=${version} -X main.revision=${src.rev}"
  ];

  # The vim plugin expects a relative path to the binary; patch it to abspath.
  postPatch = ''
    sed -i -e "s|expand('<sfile>:h:h')|'$out'|" plugin/fzf.vim

    if ! grep -q $out plugin/fzf.vim; then
        echo "Failed to replace vim base_dir path with $out"
        exit 1
    fi

    # Has a sneaky dependency on perl
    # Include first args to make sure we're patching the right thing
    substituteInPlace shell/key-bindings.bash \
      --replace " perl -n " " ${perl}/bin/perl -n "
  '';

  postInstall = ''
    install bin/fzf-tmux $out/bin

    installManPage man/man1/fzf.1 man/man1/fzf-tmux.1

    install -D plugin/* -t $out/share/vim-plugins/${pname}/plugin

    # Install shell integrations
    install -D shell/* -t $out/share/fzf/
    install -D shell/key-bindings.fish $out/share/fish/vendor_functions.d/fzf_key_bindings.fish
    mkdir -p $out/share/fish/vendor_conf.d
    echo fzf_key_bindings > $out/share/fish/vendor_conf.d/load-fzf-key-bindings.fish

    cat <<SCRIPT > $out/bin/fzf-share
    #!${runtimeShell}
    # Run this script to find the fzf shared folder where all the shell
    # integration scripts are living.
    echo $out/share/fzf
    SCRIPT
    chmod +x $out/bin/fzf-share
  '';

  meta = with lib; {
    homepage = "https://github.com/junegunn/fzf";
    description = "A command-line fuzzy finder written in Go";
    license = licenses.mit;
    maintainers = with maintainers; [ Br1ght0ne ma27 zowoq ];
    platforms = platforms.unix;
    changelog = "https://github.com/junegunn/fzf/blob/${version}/CHANGELOG.md";
  };
}
