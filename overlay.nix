hlib: helf: huper: {
  hnix-store-core =
    helf.callCabal2nix "hnix-store-core" ./hnix-store-core {};
  hnix-store-remote =
    helf.callCabal2nix "hnix-store-remote" ./hnix-store-remote {};
  algebraic-graphs =
    hlib.dontCheck huper.algebraic-graphs;
}
