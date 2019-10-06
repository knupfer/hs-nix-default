{ project, directory, versions }:

with builtins;

let

  historic = import ((import <nixpkgs> {}).fetchFromGitHub {
    owner  = "knupfer";
    repo   = "historic-nixpkgs";
    rev    = "d6f78ef3d1f23717c30f24f25775806ffc9d3dfb";
    sha256 = "1rv0wckzqsh7240vblg3b1k5lc3xc0lmn7qkx68pyffjxf140arx";});

  pkgs = (versionTuple (head versions)).value;
  ghc = (versionTuple (head versions)).name;

  versionTuple = x: if isAttrs x
                    then
                      { name = versionToGhc (head (attrNames x));
                        value = head (attrValues x);
                      }
                    else
                      { name = versionToGhc x;
                        value = latestPkgs listOfNixpkgs (versionToGhc x);
                      };
  latestPkgs = xs: v:
    if xs == []
    then abort "Following ghc version could not be found: ${v}"
    else
      if historic.${head xs}.haskell.packages ? ${v}
      then head xs
      else latestPkgs (tail xs) v;
  listOfNixpkgs = sort (a: b: lessThan b a) (attrNames historic);
  versionToGhc = x: "ghc" + replaceStrings ["."] [""] x;
  when = p: f: if p then f else (x: x);
  eval = modVersion: g: p: with historic.${p};
    historic.${pkgs}.haskell.lib.buildStrictly (when modVersion (addGhcVersion g p)
      ( when (haskell.lib ? doBenchmark) haskell.lib.doBenchmark
        ( haskell.packages.${g}.callCabal2nix project (lib.cleanSource directory) {})));
  addGhcVersion = g: p: x: historic.${pkgs}.haskell.lib.overrideCabal x (old:
    { version = old.version + "-" + p + "-" + g;
      preInstall = "mkdir -p dist/hpc";
      postInstall = "cp -r dist $out/dist";
      doCoverage = true;
    });

in

{ release ? false }:

with historic.${pkgs};

if release

then

  { archive = haskell.lib.sdistTarball (eval false ghc pkgs);
  } // lib.mapAttrs (eval true) (listToAttrs (map versionTuple versions))

else

  haskell.lib.shellAware (eval true ghc pkgs)
