# /Users/pjones/dev/nix-secrets/flake.nix

{
  description = "Private Flake that decrypts my .age-encrypted secrets via agenix";

  inputs = {
    # 1) Pull in nixpkgs so that agenix can pick it up automatically.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # 2) Pull in the official agenix flake, telling it to “follow”
    #    the same nixpkgs we declared above.  This ensures that
    #    agenix.lib.secrets (and all of agenix’s modules) show up.
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, agenix, ... }:
    let
      # ─────────────────────────────────────────────────────────────
      #  Which “systems” (architectures) do we support?
      #
      #  Adjust this list to whichever platforms you need.
      systems = [ "x86_64-linux" "aarch64-darwin" ];

      # ─────────────────────────────────────────────────────────────
      #  Read your SSH public keys from disk.  Make sure these
      #  paths are correct on your machine!
      #
      #  • On macOS, your key is at /Users/pjones/.ssh/parallaxis.pub
      #  • On Linux, your key is at /home/parallaxis/.ssh/parallaxis.pub
      #
      pjonesPub     = builtins.readFile "/Users/pjones/.ssh/parallaxis.pub";
      parallaxisPub = builtins.readFile "/home/parallaxis/.ssh/parallaxis.pub";
    in
    {
      ############################################################
      ##  A) “secrets” – expose each decrypted .age file by name:
      ##
      ##     secrets.<system>."<secret-name>"  →  plaintext secret path
      ##
      ##  Under the hood, this calls agenix.lib.secrets{…}, and
      ##  produces, for each system, an attribute named “openai-key”
      ##  whose value is the store-path of the plaintext file.
      ############################################################
      secrets = agenix.lib.secrets {
        inherit systems;

        # ───────────────────────────────────────────────────────────
        #  Define each “user” (SSH identity‐name) and which public
        #  keys it corresponds to.  These names (“pjones”, “parallaxis”)
        #  must exactly match the recipient IDs that were used when
        #  you ran “age -r pjones -r parallaxis -o openai-key.age …”.
        #
        users = {
          pjones     = { publicKeys = [ pjonesPub     ]; };
          parallaxis = { publicKeys = [ parallaxisPub ]; };
        };

        # ───────────────────────────────────────────────────────────
        #  Tell agenix which .age files live in this directory, and
        #  which users can decrypt each one.  The filename must match
        #  exactly (“openai-key.age” → decryptable by pjones & parallaxis).
        #
        ageFiles = {
          "openai-key.age".publicKeys = [ "pjones" "parallaxis" ];
          # If you add foo.age, bar.age, list them here:
          # "foo.age".publicKeys = [ "pjones" ];
          # "bar.age".publicKeys = [ "parallaxis" "pjones" ];
        };
      };

      ############################################################
      ##  B) defaultPackage – pick “openai-key” whenever you run
      ##     a bare “nix build” inside this flake root.
      ##
      ##  That way, instead of typing:
      ##    nix build .#secrets.x86_64-linux."openai-key"
      ##  you can just do:
      ##    nix build
      ##
      ##  and it will decrypt “openai-key.age” for your current system.
      ############################################################
      defaultPackage = { system }: self.secrets.${system}."openai-key";

      ############################################################
      ##  (Optional) If you want to expose more “packages” beyond
      ##  the single default secret, you could define a `packages`
      ##  attribute set instead of—or alongside—`defaultPackage`:
      ##
      ##    packages = { system }: {
      ##      default = self.secrets.${system}."openai-key";
      ##      # other derivations, if needed…
      ##    };
      ##
      ##  But most “secrets-only” flakes simply set defaultPackage.
      ############################################################
      # packages = { system }: {
      #   default = self.secrets.${system}."openai-key";
      # };

      ############################################################
      ##  (Optional) A quick “test” derivation that prints your secret
      ##  at build time.  Uncomment if you ever want:
      ##    $ nix build .#packages.x86_64-linux.default
      ############################################################
      # packages = { system }: let
      #   pkgs = import nixpkgs { inherit system; };
      # in {
      #   default = pkgs.stdenv.mkDerivation {
      #     pname = "nix-secrets-test";
      #     version = "0.1";
      #     src = ./.;
      #     buildPhase = ''
      #       echo "Here is your decrypted openai-key for ${system}:"
      #       cat ${self.secrets.${system}."openai-key"}
      #     '';
      #   };
      # };
    };
}
