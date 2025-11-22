{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "schemat";
  version = "0.4.7";

  src = fetchFromGitHub {
    owner = "raviqqe";
    repo = "schemat";
    tag = "v${finalAttrs.version}";
    hash = "sha256-veGrwwERnMy+60paF/saEbVxTDyqNVT1hsfggGCzZt0=";
  };

  strictDeps = true;

  cargoHash = "sha256-R43i06XW3DpP+6fPUo/CZhKOVXMyoTPuygJ01BpW1/I=";
})
