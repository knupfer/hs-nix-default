* hs-nix-default

`hs-nix-default` provides a standard nix solution to developing and releasing haskell packages and binaries.

Look at the following example of a `default.nix` in a typical haskell project:
```
import ((import <nixpkgs> {}).fetchFromGitHub {
  owner  = "knupfer";
  repo   = "hs-nix-default";
  rev    = "3d7569d391e988bfa79346d09fc88df825135525";
  sha256 = "1sjry7bd8yx0w7mh99v0c9623qaxk4ksc2dy47pv9bznajhq6kva";})

  { project = "my-hs-project";
    directory = ./.;
    versions =
      [
        "8.6.5"
        "8.6.4"
        { "8.4.4" = "nixpkgs_2018";}
        "8.4.3"
        { "8.2.2" = "nixpkgs_2018";}
        "8.2.1"
      ];
  }
```

This deterministically pins ghc and nixpkgs versions down to specific
commits, so if it compiles it will compile in the future.

If you specify just the version of a ghc compiler, it will search the
most recent deterministic packageset (more or less every major release
since 2013 of nixos) containing that version.

You can specify with an set the year of the nixpkgs, this is relevant
if like in this example the 8.4.4 version will fail to compile in the
packageset of 2019. This is usually due to dependencies failing to
compile.

The `project` attribute must have as value the name of your cabal file.

If you run `nix-shell`, you'll be dumped into dev shell with the first
ghc in your versions list.

If you run `nix build` your package will be build as usually, but with
the resulting dist directory copied over into the result, allowing you
to inspect built benchmarks and testsuites.

If you run `nix build --arg release true`, it will build your package
with all specified ghc versions and all testsuites and benchmarks and
use the first ghc version to build an sdist tarball for hackage.

Besides that, the source will be filtered to avoid recompilation
because of nix or vc artifacts.
