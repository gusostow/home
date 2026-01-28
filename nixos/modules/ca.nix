{ pkgs, config, ... }:

{
  environment.systemPackages = with pkgs; [ step-ca ];

  age.secrets.intermediate-ca-key = {
    file = ../../secrets/intermediate-ca-key.age;
    mode = "440";
    group = "step-ca";
  };

  services.step-ca = {
    enable = true;
    address = "localhost";
    port = 8443;

    settings = {
      root = ./ca/root/ca.crt;

      crt = ./ca/intermediate/ca.crt;
      key = config.age.secrets.intermediate-ca-key.path;

      address = "localhost:8443";
      dnsNames = [
        "ca.home"
        "localhost"
      ];

      logger.format = "text";

      db = null;

      provisioners = [
        {
          type = "ACME";
          name = "acme";
          claims = {
            minTLSCertDuration = "1h";
            maxTLSCertDuration = "720h";
            defaultTLSCertDuration = "24h";
          };
          policy.x509.allow.dns = [ "*.home" ];
        }
      ];
    };
  };
}
