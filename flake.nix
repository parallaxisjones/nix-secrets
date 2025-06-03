{
  ##################################################################
  ##  /Users/pjones/dev/nix-secrets/flake.nix
  ##
  ##  1) Pull in nixpkgs and pin agenix to v0.15.0
  ##  2) Expose decrypted secrets under `outputs.secrets.<system>."<name>"`
  ##  3) Define `defaultPackage` so that `nix build` → decrypt “openai-key”
  ##################################################################

  description = "Private Flake that decrypts my .age-encrypted secrets via agenix";

  inputs = {
    # ───────────────────────────────────────────────────────────────
    #  1) We need nixpkgs because agenix wants to “follow” a nixpkgs
    #     For pure secret-only use, you could remove nixpkgs, but pinning
    #     agenix → tag requires a nixpkgs context.
    #
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # ───────────────────────────────────────────────────────────────
    #  2) Pull in the official agenix flake at a release tag:
    #
    agenix = {
      url = "github:ryantm/agenix/0.15.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, agenix, ... }:
    let
      # ─────────────────────────────────────────────────────────────
      #  Which “systems” (platforms) are we targeting?  Adjust if needed.
      systems = [ "x86_64-linux" "aarch64-darwin" ];

      # ─────────────────────────────────────────────────────────────
      #  Read your SSH public keys off disk.  These must match the
      #  recipients you used when running `age -r pjones -r parallaxis …`
      #
      pjonesPub     = builtins.readFile "/Users/pjones/.ssh/parallaxis.pub";
      parallaxisPub = builtins.readFile "/home/parallaxis/.ssh/parallaxis.pub";
    in
    {
      ################################################################
      ##  A) “secrets” – expose each decrypted .age file by name:
      ##
      ##     → secrets.<system>."openai-key"  = store-path of plaintext
      ##
      ##  Under the hood, this calls agenix.lib.secrets{…}.
      ################################################################
      secrets = agenix.lib.secrets {
        inherit systems;

        # ───────────────────────────────────────────────────────────
        #  1) Define which user-IDs exist, and which public keys they use.
        #     The names “pjones” / “parallaxis” must match exactly the
        #     recipients you used during `age -r … -o openai-key.age`.
        #
        users = {
          pjones     = { publicKeys = [ pjonesPub     ]; };
          parallaxis = { publicKeys = [ parallaxisPub ]; };
        };

        # ───────────────────────────────────────────────────────────
        #  2) Tell agenix which .age files live here, and which users
        #     can decrypt each one.  The filename must match exactly.
        #
        #     “openai-key.age”.publicKeys = [ "pjones" "parallaxis" ];
        #
        ageFiles = {
          "openai-key.age".publicKeys = [ "pjones" "parallaxis" ];
          # If you add foo.age / bar.age, list them similarly here.
        };
      };

      ################################################################
      ##  B) defaultPackage – decrypt “openai-key” if someone runs
      ##     `nix build` with no arguments.  On x86_64-linux, this
      ##     means `nix build .#defaultPackage.x86_64-linux` → the
      ##     plaintext “openai-key” store path.
      ################################################################
      defaultPackage = { system }: self.secrets.${system}."openai-key";

      ################################################################
      ##  (Optional) If you wanted a full `packages` set in addition
      ##  to or instead of defaultPackage, you could do:
      ##
      ##    packages = { system }: {
      ##      default = self.secrets.${system}."openai-key";
      ##      # …other derivations if desired…
      ##    };
      ################################################################
      # packages = { system }: {
      #   default = self.secrets.${system}."openai-key";
      # };
    };
}
