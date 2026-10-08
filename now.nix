let
  services = import ./.;
  now = import (import ./.tack).now { system = builtins.currentSystem; };
in
{
  jobs = {
    # Garage
    garage = {
      steps = [
        (services.garage {
          args = [
            "--single-node"
            "--default-bucket"
          ];
        })
      ];
    };
    test-garage = {
      steps = [
        {
          env = {
            # Note: Use `runner.secret "ENV_VAR"` in real environments!
            GARAGE_CONFIG_FILE = "tests/garage/config.toml";
            GARAGE_DEFAULT_ACCESS_KEY = "GK6b392ad9fef050386b98f96e096ea7c4";
            GARAGE_DEFAULT_SECRET_KEY = "ad37b6e6a96e81d2a1f6b71ac5b756adc2b8214c36c04e6c2bd7d4ae5b139270";
            GARAGE_DEFAULT_BUCKET = "default-bucket";
          };
          path = [ now ];
          run = "now run garage";
        }
      ];
    };

    # PostgreSQL
    postgresql = { pkgs, ... }: {
      steps = [ (services.postgresql { package = pkgs.postgresql_18; }) ];
    };
    test-postgresql = {
      steps = [
        {
          path = [ now ];
          env.PGDATA = "tests/postgresql";
          run = ''
            # Note: Use `runner.secret "ENV_VAR"` in real environments!
            export DATABASE_URL="postgresql://$USER:mysecretpassword@127.0.0.1:5432/postgres"
            now run postgresql
          '';
        }
      ];
    };

    # Redis
    redis = { pkgs, ... }: {
      steps = [ (services.redis { package = pkgs.redis; }) ];
    };
    test-redis = {
      steps = [
        {
          path = [ now ];
          run = "now run redis";
        }
      ];
    };
  };
}
