{ project, directory, versions }:

with builtins;

let

  historic = import ((import <nixpkgs> {}).fetchFromGitHub {
    owner  = "knupfer";
    repo   = "historic-nixpkgs";
    rev    = "685f67412975a4669b0867d4bbf95e86eceebffc";
    sha256 = "0v92b9209h8z6fw4yd4q5bxnv2swcmvwwhg74lp3vy8gk9pnjjki";});

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
