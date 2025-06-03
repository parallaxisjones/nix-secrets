{  # ──────────────────────────────────────────────────────────────────────────
  # nix-secrets/flake.nix
  #
  # This flake simply decrypts all .age files for:
  #   • x86_64-linux   (NixOS / Linux)
  #   • aarch64-darwin (macOS)
  #
  # It will export:
  #   outputs.age.<system>."<secret-name>" = (the decrypted text file path)
  #
  description = "Private flake that decrypts my .age‐encrypted secrets";

  inputs = {
    # We only need agenix to do the age‐decryption dance
    agenix.url = "github:numtide/agenix";
  };

  outputs = { self, agenix, ... }: let
    # ────────────────────────────────────────────────────────────────────────
    # 1) Point to the *contents* of your public‐key files.
    #    Make sure these paths are readable by the user who runs `nix build`.
    #
    pjonesPublicKey     = builtins.readFile "/Users/pjones/.ssh/parallaxis.pub";
    parallaxisPublicKey = builtins.readFile "/home/parallaxis/.ssh/parallaxis.pub";

    # ────────────────────────────────────────────────────────────────────────
    # 2) Declare exactly which machines (Nix “systems”) we want to build for.
    #
    systems = [ "x86_64-linux" "aarch64-darwin" ];
  in
  {
    # ────────────────────────────────────────────────────────────────────────
    # 3) In `outputs.age` we run agenix.lib.secrets { … } exactly once.
    #
    age = agenix.lib.secrets {
      inherit systems;

      # “users” is a set of labels → publicKeys arrays
      users = {
        pjones     = { publicKeys = [ pjonesPublicKey     ]; };
        parallaxis = { publicKeys = [ parallaxisPublicKey ]; };
      };

      # “ageFiles” must list every *.age under this repo that you want to decrypt
      ageFiles = {
        # both machines decrypt “openai-key.age”:
        "openai-key.age".publicKeys = [ "pjones" "parallaxis" ];
      };
    };
  }
}
