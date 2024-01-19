{buildDartApplication, lib, sqlite, makeWrapper}:

buildDartApplication rec {
  pname = "emoji-drawing-server";
  version = "unknown";

  src = ./.;
  autoPubspecLock = src + "/pubspec.lock";

  nativeBuildInputs = [ makeWrapper ];

  postInstall = let
    libPath = lib.makeLibraryPath [ sqlite ];
  in ''
    wrapProgram $out/bin/emoji-drawing-server \
      --prefix LD_LIBRARY_PATH : ${libPath} 
  '';
}
