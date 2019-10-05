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
  eval = g: p: with historic.${p};
    ( if haskell.lib ? doBenchmark then haskell.lib.doBenchmark else x: x)
      ( haskell.packages.${g}.callCabal2nix project
        ( lib.cleanSource directory
        ) {}
      )
  ;
  addGhcVersion = x: g: historic.${pkgs}.haskell.lib.overrideCabal x (old:
    { version = old.version + "-" + g;
      postInstall = "cp -r dist $out/dist";
      doCoverage = true;
    });

in

{ release ? false }:

if release

then

   { archive = historic.${pkgs}.haskell.lib.sdistTarball (eval ghc pkgs);
   } // historic.${pkgs}.lib.mapAttrs (x: y: addGhcVersion (eval x y) x) (listToAttrs (map versionTuple versions))

else

  historic.${pkgs}.haskell.lib.shellAware (addGhcVersion (eval ghc pkgs) ghc)
