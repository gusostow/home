{
  fetchFromGitHub,
  buildPythonApplication,
  python,
}:

buildPythonApplication rec {
  pname = "decluttarr";
  # v2.1.0 adds support for the QBT_SID_<port> cookie name introduced in qBittorrent 5.2
  version = "2.1.0";

  src = fetchFromGitHub {
    owner = "ManiMatter";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-pOuAQ2KKvhmUM6xX5iX9s33ZXL3OLx6yIOL8LZF1W64=";
  };

  propagatedBuildInputs = with python.pkgs; [
    demjson3
    python-dateutil
    requests
    packaging
    pyyaml-env-tag
    watchdog
  ];

  doCheck = false;
  pyproject = false;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/${python.sitePackages}/${pname}
    cp -R ./src ./main.py $out/lib/${python.sitePackages}/${pname}/

    mkdir -p $out/bin
    makeWrapper ${python.interpreter} $out/bin/${pname} --add-flags "$out/lib/${python.sitePackages}/${pname}/main.py" --prefix PYTHONPATH : "${python.pkgs.makePythonPath propagatedBuildInputs}"

    runHook postInstall
  '';
}
