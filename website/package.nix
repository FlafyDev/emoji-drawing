{buildNpmPackage, version}:

buildNpmPackage rec {
  pname = "emoji-drawing-website";
  inherit version;

  src = ./.;

  npmDepsHash = "sha256-B76eYNy7qzkugyCAnZY+y29snAoHgoQSKDN/IY0r0Qc=";
  npmFlags = [ "--legacy-peer-deps" ];

  postInstall = ''
    mkdir -p $out
    cp -r * $out
    cp -r .next $out
  '';
}
