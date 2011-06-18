SUBDIRS = RG mat

dist_noinst_DATA = debian/changelog  debian/compat  debian/control  debian/copyright
dist_noinst_SCRIPTS = debian/rules

dist_pkgdata_SCRIPTS = blast2saf.pl blastpgp_to_saf.pl conv_hssp2saf.pl copf.pl dbSwiss hssp_filter.pl safFilterRed.pl

man_MANS = dbSwiss.1

CLEANFILES = $(man_MANS)

%.1:	%
	sed -e 's|__pkgdatadir__|$(pkgdatadir)|g;s|__sysconfdir__|$(sysconfdir)|g;s|__bindir__|$(bindir)|g;s|__VERSION__|$(VERSION)|g' "$<" | \
	pod2man -c 'User Commands' -r "$(VERSION)" -name $(shell tr '[:lower:]' '[:upper:]' <<< "$(basename $@)") > "$@"
