{ stdenv, lib, buildPythonPackage, fetchFromSourcehut,
  sqlparse, wrapt, pytestCheckHook }:

buildPythonPackage rec {
  pname = "embrace";
  version = "4.1.0";

  src = fetchFromSourcehut {
    vc = "hg";
    owner = "~olly";
    repo = "embrace-sql";
    rev = "v${version}-release";
    sha256 = "sha256-R6Ug4f8KFZNzaNWqWZkLvOwtsawCuerzvHlysr7bd6M=";
  };

  propagatedBuildInputs = [ sqlparse wrapt ];
  checkInputs = [ pytestCheckHook ];
  pythonImportsCheck = [ "embrace" ];

  # Some test for hot-reload fails on Darwin, but the rest of the library
  # should remain usable. (https://todo.sr.ht/~olly/embrace-sql/4)
  doCheck = !stdenv.isDarwin;

  meta = with lib; {
    description = "Embrace SQL keeps your SQL queries in SQL files";
    homepage = "https://pypi.org/project/embrace/";
    license = licenses.asl20;
    maintainers = with maintainers; [ pacien ];
  };
}
