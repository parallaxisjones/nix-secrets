let
  # macOS (pjones) and NixOS (parallaxis) decrypt with the same ~/.ssh/parallaxis identity.
  pjones = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAao6hYRda8Dc88DgWHblVFV/HFCcj6kJuDWq7oqt7Aq";
  users = [ pjones ];
  systems = [ ];
in
{
  "openai-key.age".publicKeys = users;
  "smb-credentials.age".publicKeys = users;
  "anthropic-api-key.age".publicKeys = users;
  "datadog-api-key.age".publicKeys = users;
  "datadog-app-key.age".publicKeys = users;
}
