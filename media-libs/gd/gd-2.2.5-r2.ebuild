# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="7"

inherit autotools flag-o-matic multilib-minimal

DESCRIPTION="Graphics library for fast image creation"
HOMEPAGE="https://libgd.org/ https://www.boutell.com/gd/"
SRC_URI="https://github.com/libgd/libgd/releases/download/${P}/lib${P}.tar.xz
	test? (
		https://github.com/libgd/libgd/raw/e0cb1b76c305db68b251fe782faa12da5d357593/tests/gif/ossfuzz5700.gif -> lib${P}-ossfuzz5700.dat
		https://github.com/libgd/libgd/raw/e0cb1b76c305db68b251fe782faa12da5d357593/tests/gif/php_bug_75571.gif -> lib${P}-php_bug_75571.dat
	)"

LICENSE="gd IJG HPND BSD"
SLOT="2/3"
KEYWORDS="~alpha amd64 ~arm arm64 ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh sparc x86 ~ppc-aix ~amd64-fbsd ~x86-fbsd ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~x64-solaris ~x86-solaris"
IUSE="cpu_flags_x86_sse fontconfig jpeg png static-libs test tiff truetype webp xpm zlib"

# fontconfig has prefixed font paths, details see bug #518970
REQUIRED_USE="prefix? ( fontconfig )"

RDEPEND="fontconfig? ( >=media-libs/fontconfig-2.10.92[${MULTILIB_USEDEP}] )
	jpeg? ( >=virtual/jpeg-0-r2:0=[${MULTILIB_USEDEP}] )
	png? ( >=media-libs/libpng-1.6.10:0=[${MULTILIB_USEDEP}] )
	tiff? ( media-libs/tiff:0[${MULTILIB_USEDEP}] )
	truetype? ( >=media-libs/freetype-2.5.0.1[${MULTILIB_USEDEP}] )
	webp? ( media-libs/libwebp:=[${MULTILIB_USEDEP}] )
	xpm? ( >=x11-libs/libXpm-3.5.10-r1[${MULTILIB_USEDEP}] >=x11-libs/libXt-1.1.4[${MULTILIB_USEDEP}] )
	zlib? ( >=sys-libs/zlib-1.2.8-r1[${MULTILIB_USEDEP}] )"
DEPEND="${RDEPEND}
	>=virtual/pkgconfig-0-r1[${MULTILIB_USEDEP}]"

S="${WORKDIR}/lib${P}"

PATCHES=(
	"${FILESDIR}/${P}-ossfuzz5700.patch"
	"${FILESDIR}/${P}-CVE-2018-5711.patch"
	"${FILESDIR}/${P}-CVE-2018-1000222.patch"
	"${FILESDIR}/${P}-CVE-2019-6977.patch"
	"${FILESDIR}/${P}-CVE-2019-6978.patch"
)

src_unpack() {
	default

	if use test ; then
		cp "${DISTDIR}"/lib${P}-ossfuzz5700.dat \
			"${S}"/tests/gif/ossfuzz5700.gif || die
		cp "${DISTDIR}"/lib${P}-php_bug_75571.dat \
			"${S}"/tests/gif/php_bug_75571.gif || die
	fi
}

src_prepare() {
	default
	eautoreconf
}

multilib_src_configure() {
	# bug 603360, https://github.com/libgd/libgd/blob/fd06f7f83c5e78bf5b7f5397746b4e5ee4366250/docs/README.TESTING#L65
	if use cpu_flags_x86_sse ; then
		append-cflags -msse -mfpmath=sse
	else
		append-cflags -ffloat-store
	fi

	# bug 632076, https://github.com/libgd/libgd/issues/278
	if use arm64 || use ppc64 || use s390 ; then
		append-cflags -ffp-contract=off
	fi

	# we aren't actually {en,dis}abling X here ... the configure
	# script uses it just to add explicit -I/-L paths which we
	# don't care about on Gentoo systems.
	local myeconfargs=(
		--disable-werror
		--without-x
		--without-liq
		$(use_enable static-libs static)
		$(use_with fontconfig)
		$(use_with png)
		$(use_with tiff)
		$(use_with truetype freetype)
		$(use_with jpeg)
		$(use_with webp)
		$(use_with xpm)
		$(use_with zlib)
	)
	ECONF_SOURCE="${S}" econf "${myeconfargs[@]}"
}

multilib_src_install_all() {
	dodoc README.md
	find "${ED}" -name '*.la' -delete || die
}
