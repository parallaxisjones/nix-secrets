# ┌─────────────────────────────────────────────────────────────────────────┐
# │  nix-secrets/flake.nix                                                 │
# └─────────────────────────────────────────────────────────────────────────┘
{
  description = "Private flake that just decrypts all of my .age secrets.";

  # We only need agenix as an input here:
  inputs = {
    agenix.url = "github:numtide/agenix";  # or "github:ryantm/agenix"
    # (no need for nixpkgs here, since agenix itself will pull one in)
  };

  outputs = { self, agenix, ... }:

  let
    # ──────────────────────────────────────────────────────────────────────
    # 1) Replace these with the actual contents of each user's `.pub` file:
    #
    #    On macOS, you encrypt for “pjones” using /Users/pjones/.ssh/parallaxis.pub  
    #    On NixOS, you encrypt for “parallaxis” using   /home/parallaxis/.ssh/parallaxis.pub
    #
    pjonesPublicKey     = builtins.readFile "/Users/pjones/.ssh/parallaxis.pub";
    # parallaxisPublicKey = builtins.readFile "/home/parallaxis/.ssh/parallaxis.pub";

    # ──────────────────────────────────────────────────────────────────────
    # 2) Which platforms do we need to expose? (so that each machine only
    #    tries to decrypt the secrets it actually needs)
    #
    systems = [ "x86_64-linux" "aarch64-darwin" ];
  in

  {
    # ──────────────────────────────────────────────────────────────────────
    # 3) Run agenix.lib.secrets to decrypt all the “.age” blobs in this repo:
    age = agenix.lib.secrets {
      inherit systems;

      users = {
        pjones     = { publicKeys = [ pjonesPublicKey ]; };
        parallaxis = { publicKeys = [ parallaxisPublicKey ]; };
      };

      ageFiles = {
        # On macOS, “pjones” can decrypt the darwin‐*.age files;
        # On NixOS, “parallaxis” can decrypt the nixos‐*.age files;
        # "darwin-syncthing-cert.age".publicKeys   = [ pjones ];
        # "darwin-syncthing-key.age".publicKeys    = [ pjones ];

        # "nixos-syncthing-cert.age".publicKeys    = [ parallaxis ];
        # "nixos-syncthing-key.age".publicKeys     = [ parallaxis ];

        # “openai-key.age” should be readable on both machines:
        "openai-key.age".publicKeys              = [ pjones parallaxis ];

        # Your GitHub‐SSH key only needs to be decrypted on macOS:
        # "github-ssh-key.age".publicKeys          = [ pjones ];
        # "github-signing-key.age".publicKeys      = [ pjones ];
      };
    };
  }
}
