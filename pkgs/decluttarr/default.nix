{
  fetchFromGitHub,
  buildPythonApplication,
  python,
}:

buildPythonApplication rec {
  pname = "decluttarr";
  version = "2.0.0";

  src = fetchFromGitHub {
    owner = "ManiMatter";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-3mB5+ao3w+CkyTS/o1O9/7UXOoGkA/mTpJNEQxUTa9Q=";
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
