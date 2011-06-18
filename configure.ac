AC_INIT([librg-utils-perl], [1.0.36], [https://rostlab.org/cgi-bin/bugzilla3/enter_bug.cgi?product=librg-utils-perl])
AC_ARG_VAR(PERLLIBDIR,[perl modules @<:@default=DATAROOTDIR/perl5@:>@])
AM_INIT_AUTOMAKE
AC_CONFIG_FILES([Makefile] [RG/Makefile] [RG/Utils/Makefile] [mat/Makefile])

if test "x$PERLLIBDIR" = "x"; then
	PERLLIBDIR=\${datadir}/perl5
fi

AC_OUTPUT

