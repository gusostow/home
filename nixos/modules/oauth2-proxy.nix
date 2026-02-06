{
  config,
  pkgs,
  lib,
  ...
}:

{
  age.secrets.oauth2-proxy-env = {
    file = ../../secrets/oauth2-proxy-env.age;
    mode = "0400";
  };

  # oauth2-proxy for forward auth with Keycloak
  services.oauth2-proxy = {
    enable = true;

    # Keycloak OIDC provider
    provider = "keycloak-oidc";
    clientID = "oauth2-proxy";

    # redirect and cookie settings
    cookie = {
      domain = ".home";
      secure = true;
    };

    # allow all emails (restrict in Keycloak instead)
    email.domains = [ "*" ];

    httpAddress = "http://127.0.0.1:4180";

    # Keycloak endpoints
    extraConfig = {
      oidc-issuer-url = "https://idp.home/realms/home";
      code-challenge-method = "S256";
      # pass user info to upstream via headers
      set-xauthrequest = true;
      # allow auth via header check without redirect (for forward_auth)
      reverse-proxy = true;
      # redirect URL for OAuth callback
      redirect-url = "https://auth.home/oauth2/callback";
      # whitelist all .home domains
      whitelist-domain = ".home";
    };

    keyFile = config.age.secrets.oauth2-proxy-env.path;
  };
}
