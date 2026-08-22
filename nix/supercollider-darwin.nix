{
  fetchurl,
  lib,
  stdenvNoCC,
  undmg,
}:
stdenvNoCC.mkDerivation {
  pname = "supercollider";
  version = "3.14.1";

  src = fetchurl {
    url = "https://github.com/supercollider/supercollider/releases/download/Version-3.14.1/SuperCollider-3.14.1-macOS-universal.dmg";
    hash = "sha256-7SZLMnUtJ/yG5QbdCn6zbefBnrznPD/fLtVRT4xz8C4=";
  };

  nativeBuildInputs = [undmg];

  sourceRoot = ".";
  installPhase = ''
    runHook preInstall

    mkdir -p "$out/Applications" "$out/bin"
    cp -R SuperCollider.app "$out/Applications/"
    ln -s "$out/Applications/SuperCollider.app/Contents/MacOS/sclang" "$out/bin/sclang"
    ln -s "$out/Applications/SuperCollider.app/Contents/Resources/scsynth" "$out/bin/scsynth"
    ln -s "$out/Applications/SuperCollider.app/Contents/Resources/supernova" "$out/bin/supernova"

    runHook postInstall
  '';

  meta = {
    description = "Platform for audio synthesis and algorithmic composition";
    homepage = "https://supercollider.github.io/";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.darwin;
  };
}
