SUBDIRS = lib mat

dist_noinst_DATA = Build.PL $(PACKAGE).spec
dist_noinst_SCRIPTS =

dist_pkgdata_SCRIPTS = blast2saf.pl blastpgp_to_saf.pl conv_hssp2saf.pl copf.pl dbSwiss hssp_filter.pl safFilterRed.pl

man_MANS = dbSwiss.1
man3_MANS =

CLEANFILES = $(man_MANS)

all-local: build-stamp

clean-local:
	if [ -e Build ]; then perl Build clean && rm -f Build build-stamp; fi

distclean-local:
	rm -rf _build MYMETA.yml

build-stamp: Build.PL
	perl $(srcdir)/Build.PL installdirs=vendor && perl Build && touch build-stamp

install-data-local:
	perl Build install destdir=$(DESTDIR) $(INSTALL_BASE_ARG) create_packlist=0

%.1:	%
	sed -e 's|__pkgdatadir__|$(pkgdatadir)|g;s|__sysconfdir__|$(sysconfdir)|g;s|__bindir__|$(bindir)|g;s|__VERSION__|$(VERSION)|g' "$<" | \
	pod2man -c 'User Commands' -r "$(VERSION)" -name $(shell echo "$(basename $@)" | tr '[:lower:]' '[:upper:]') > "$@"

install-data-hook:
	for f in "$(DESTDIR)$(pkgdatadir)/copf.pl" "$(DESTDIR)$(pkgdatadir)/hssp_filter.pl"; do \
		sed -i -e 's|__bindir__|$(bindir)|g;s|__datadir__|$(datadir)|g;s|__docdir__|$(docdir)|g;s|__pkgdatadir__|$(pkgdatadir)|g;s|__PREFIX__|$(prefix)|g;s|__sysconfdir__|$(sysconfdir)|g;s|__VERSION__|$(VERSION)|g;' "$$f"; \
	done
