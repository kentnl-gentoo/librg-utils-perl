AC_INIT([librg-utils-perl], [1.0.42], [https://rostlab.org/cgi-bin/bugzilla3/enter_bug.cgi?product=librg-utils-perl])
# remember to update version number in Build.PL
# PERLLIBDIR=$(eval "`perl -V:installvendorlib`"; echo $installvendorlib)
AM_INIT_AUTOMAKE
AC_CONFIG_FILES([Makefile] [Build.PL] [lib/Makefile] [lib/RG/Makefile] [lib/RG/Utils/Makefile] [mat/Makefile])
AC_SUBST(INSTALL_BASE_ARG)

if test "x$prefix" != "x/usr"; then
	INSTALL_BASE_ARG=install_base=$prefix
fi

AC_OUTPUT
