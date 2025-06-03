{  # ────────────────────────────────────────────────────────────────────
  # ~/dev/nix-secrets/flake.nix
  #
  # This flake will expose:
  #   outputs.age.<system>."openai-key"  →  plain‐text OpenAI key
  #
  description = "Private flake that decrypts my .age‐encrypted secrets";

  inputs = {
    # We only need agenix to do the actual age decryption
    agenix.url = "github:numtide/agenix";
  };

  outputs = { self, agenix, ... }: let
    # ─────────────────────────────────────────────────────────────────────
    # 1) Point to the contents of your ~/.ssh/*.pub files
    #
    pjonesPublicKey     = builtins.readFile "/Users/pjones/.ssh/parallaxis.pub";
    parallaxisPublicKey = builtins.readFile "/home/parallaxis/.ssh/parallaxis.pub";

    # ─────────────────────────────────────────────────────────────────────
    # 2) Which “systems” (Nix platforms) do we build for?
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
        # Both “pjones” (darwin) and “parallaxis” (linux) can decrypt:
        "openai-key.age".publicKeys = [ "pjones" "parallaxis" ];
      };
    };
  }
}
