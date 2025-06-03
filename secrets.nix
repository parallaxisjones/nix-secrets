let
  pjones = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAao6hYRda8Dc88DgWHblVFV/HFCcj6kJuDWq7oqt7Aq";
  users = [ pjones ];
  systems = [ ];
in
{
  "openai-key.age".publicKeys = users;
}
