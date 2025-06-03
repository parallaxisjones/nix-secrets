{  # ──────────────────────────────────────────────────────────────────────────
  # nix-secrets/flake.nix
  #
  # This flake simply decrypts all .age files for either:
  #   • x86_64-linux   (NixOS)
  #   • aarch64-darwin (macOS)
  #
  # It exposes:
  #   secrets.age.<system>.<“openai-key”|“darwin-syncthing-cert”|…>
  #
  description = "Private flake that decrypts my .age‐encrypted secrets";

  inputs = {
    # We need agenix to do the actual .age decryption
    agenix.url = "github:numtide/agenix";
  };

  outputs = { self, agenix, ... }: let
    # ────────────────────────────────────────────────────────────────────────
    # 1) Replace these with the *contents* of your ~/.ssh/*.pub files.
    #    On macOS (“pjones”) you encrypted with /Users/pjones/.ssh/parallaxis.pub
    #    On NixOS (“parallaxis”) you encrypted with /home/parallaxis/.ssh/parallaxis.pub
    #
    pjonesPublicKey     = builtins.readFile "/Users/pjones/.ssh/parallaxis.pub";
    parallaxisPublicKey = builtins.readFile "/home/parallaxis/.ssh/parallaxis.pub";

    # ────────────────────────────────────────────────────────────────────────
    # 2) Which platforms do we want to decrypt for?
    #
    systems = [ "x86_64-linux" "aarch64-darwin" ];
  in
  {
    age = agenix.lib.secrets {
      inherit systems;

      users = {
        pjones     = { publicKeys = [ pjonesPublicKey ]; };
        parallaxis = { publicKeys = [ parallaxisPublicKey ]; };
      };

      ageFiles = {
        # On macOS: pjones can decrypt “darwin-syncthing-cert.age”
        # "darwin-syncthing-cert.age".publicKeys = [ pjones ];
        # "darwin-syncthing-key.age".publicKeys  = [ pjones ];

        # On NixOS:   parallaxis can decrypt “nixos-syncthing-cert.age”
        # "nixos-syncthing-cert.age".publicKeys = [ parallaxis ];
        # "nixos-syncthing-key.age".publicKeys  = [ parallaxis ];

        # Shared across both machines: both pjones and parallaxis can decrypt
        "openai-key.age".publicKeys            = [ pjones parallaxis ];

        # GitHub keys (if you want them later):
        # "github-ssh-key.age".publicKeys     = [ pjones ];
        # "github-signing-key.age".publicKeys = [ pjones ];
      };
    };
  }
}
