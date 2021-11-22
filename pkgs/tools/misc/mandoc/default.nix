{ lib, stdenv, fetchurl, zlib, perl }:

let
  # check if we can execute binaries for the host platform on the build platform
  # even though the platforms aren't the same. mandoc can't be cross compiled
  # (easily) because of its configurePhase, but we want to allow “native” cross
  # such as pkgsLLVM and pkgsStatic.
  executableCross = stdenv.hostPlatform.isCompatible stdenv.buildPlatform;

  # Name of an UTF-8 locale _always_ present at runtime, used for UTF-8 support
  # (locale set by the user may differ). This would usually be C.UTF-8, but
  # darwin has no such locale.
  utf8Locale =
    if stdenv.hostPlatform.isDarwin
    then "en_US.UTF-8"
    else "C.UTF-8";
in

assert executableCross ||
  throw "mandoc relies on executing compiled programs in configurePhase, can't cross compile";

stdenv.mkDerivation rec {
  pname = "mandoc";
  version = "1.14.6";

  src = fetchurl {
    url = "https://mandoc.bsd.lv/snapshots/mandoc-${version}.tar.gz";
    sha256 = "8bf0d570f01e70a6e124884088870cbed7537f36328d512909eb10cd53179d9c";
  };

  buildInputs = [ zlib ];

  configureLocal = ''
    MANPATH_DEFAULT="/run/current-system/sw/share/man"
    MANPATH_BASE="$MANPATH_DEFAULT"
    OSNAME="NixOS"
    PREFIX="$out"
    LD_OHASH="-lutil"
    # Use symlinks instead of hardlinks (more commonly used in nixpkgs)
    LN="ln -sf"
    # nixpkgs doesn't have sbin, install makewhatis to bin
    SBINDIR="$PREFIX/bin"
    CC=${stdenv.cc.targetPrefix}cc
    AR=${stdenv.cc.bintools.targetPrefix}ar
    # Allow makewhatis(8) to follow symlinks from a manpath to the nix store
    READ_ALLOWED_PATH=${builtins.storeDir}
    # Bypass the locale(1)-based check for UTF-8 support since it causes trouble:
    # * We only have meaningful locale(1) implementations for glibc and macOS
    # * NetBSD's locale(1) (used for macOS) depends on mandoc
    # * Sandbox and locales cause all kinds of trouble
    # * build and host libc (and thus locale handling) may differ
    HAVE_WCHAR=1
    UTF8_LOCALE=${utf8Locale}
  '';

  preConfigure = ''
    printf '%s' "$configureLocal" > configure.local
  '';

  doCheck = executableCross;
  checkTarget = "regress";
  checkInputs = [ perl ];
  preCheck = "patchShebangs --build regress/regress.pl";

  meta = with lib; {
    homepage = "https://mandoc.bsd.lv/";
    description = "suite of tools compiling mdoc and man";
    downloadPage = "http://mandoc.bsd.lv/snapshots/";
    license = licenses.bsd3;
    platforms = platforms.all;
    maintainers = with maintainers; [ bb010g ramkromberg sternenseemann ];
  };
}
