{
  ##########################################################
  ##  /Users/pjones/dev/nix-secrets/flake.nix
  ##
  ##  This Flake will:
  ##    • Pull in agenix from GitHub
  ##    • Define two users (pjones and parallaxis), each
  ##      pointing at an “.pub” key on disk
  ##    • Tell agenix that “openai-key.age” is decryptable
  ##      by both pjones and parallaxis
  ##    • Expose a top-level attribute set called “secrets”
  ##      such that:
  ##        secrets.x86_64-linux."openai-key"
  ##        secrets.aarch64-darwin."openai-key"
  ##      are plain-text values of the decrypted file.
  ##
  ##  After this, your “main” Flake can simply pull:
  ##    inputs.nix-secrets.secrets.${system}."openai-key"
  ##########################################################

  description = "Private Flake that decrypts my .age-encrypted secrets using agenix";

  inputs = {
    # 1) We only need 'agenix' for the decryption machinery
    agenix.url = "github:numtide/agenix";

    # 2) We do not strictly need nixpkgs here, but it can be useful
    #    if you ever want to test-building something. For purely
    #    exposing decrypted secrets, you could omit nixpkgs.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # (Optionally) if you plan to reference this Flake by name in your
    # “main” Flake’s inputs, you could give it a name:
    # “nix-secrets = { url = ...; }”
  };

  outputs = { self, agenix, nixpkgs, ... }:
    let
      # ───────────────────────────────────────────────────────────────
      #  Which Nix “systems” (platforms) are we targeting?
      #
      #  Adjust this to whichever platforms you actually need.
      systems = [ "x86_64-linux" "aarch64-darwin" ];

      # ───────────────────────────────────────────────────────────────
      #  Read your public keys off disk.  Make sure these paths exist.
      #
      #  • On macOS (“pjones”), your SSH pub might live under /Users/pjones/.ssh/
      #  • On Linux (“parallaxis”), your SSH pub might live under /home/parallaxis/.ssh/
      #
      #  You can substitute whatever key you’ve actually used to
      #  encrypt “openai-key.age” (and any others).
      pjonesPub = builtins.readFile "/Users/pjones/.ssh/parallaxis.pub";
      paraPub  = builtins.readFile "/home/parallaxis/.ssh/parallaxis.pub";
    in
    {
      ############################################################
      ##  1) Expose all decrypted secrets under ‘secrets’:
      ##
      ##      secrets.x86_64-linux."openai-key"
      ##      secrets.aarch64-darwin."openai-key"
      ############################################################
      secrets = agenix.lib.secrets {
        inherit systems;

        # ───────────────────────────────────────────────────────────
        #  2) Define which user-IDs exist, and which public keys
        #     they correspond to.  These user-IDs must match the
        #     “recipient identifiers” you used when encrypting.
        #     In your example, you encrypted “openai-key.age” with
        #     both pjones and parallaxis.
        #
        users = {
          pjones     = { publicKeys = [ pjonesPub ]; };
          parallaxis = { publicKeys = [ paraPub ]; };
        };

        # ───────────────────────────────────────────────────────────
        #  3) Tell agenix exactly which .age files live in this
        #     directory, and which users can decrypt each one.
        #     The key on disk must be named exactly “openai-key.age”:
        #
        ageFiles = {
          "openai-key.age".publicKeys = [ "pjones" "parallaxis" ];
          # If you had foo.age, bar.age, you’d add:
          # "foo.age".publicKeys = [ "pjones" ];
          # "bar.age".publicKeys = [ "parallaxis" "pjones" ];
        };
      };

      ############################################################
      ##  4) (Optional) If you ever want to build a simple “test”
      ##     that does something with nixpkgs, you can add it:
      ############################################################
      packages = { system }: rec {
        default = with (import nixpkgs { inherit system; }).pkgs; stdenv.mkDerivation {
          pname = "nix-secrets-test";
          version = "0.1";
          src = ./.;
          buildPhase = ''
            echo "Here is your decrypted secret:"
            cat ${self.secrets.${system}."openai-key"}
          '';
        };
      };
    };
}
