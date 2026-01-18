let
  aostowMacbook = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHSUqN8CKiPvebqr78Cn6csnIFrHKx0VX7lPFalduA8C";
  systemUltan = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOVFSoFO9x36zlAAJ1DFXtYnEepvyq4Lb8/pb8J86unP";
  users = [ aostowMacbook ];
  systems = [ systemUltan ];
  all = users ++ systems;
in
{
  "decluttarr.env.age".publicKeys = all;
}
