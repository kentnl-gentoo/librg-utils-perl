PACKAGE := librg-utils-perl
VERSION := 1.0.32
DISTDIR := $(PACKAGE)-$(VERSION)

pkgdatadir := $(prefix)/usr/share/$(PACKAGE)

MAN1GZ := dbSwiss.1.gz
SCRIPTS := dbSwiss

MAN3PERLPOD := $(wildcard RG/Utils/*.pm)
MAN3PERLGZ := $(MAN3PERLPOD:%.pm=%.3perl.gz)  
INSTMAN3PERLGZ := $(MAN3PERLGZ:%=inst-%)  

all: man 

man:    $(MAN1GZ) $(MAN3PERLGZ)

%.1:	%
	sed -e 's|__PREFIX__|$(prefix)|g;s|__pkgdatadir__|$(pkgdatadir)|g;s|__sysconfdir__|$(sysconfdir)|g;s|__bindir__|$(bindir)|g;s|__VERSION__|$(VERSION)|g' "$<" | \
	pod2man -c 'User Commands' -r "$(VERSION)" -name $(shell tr '[:lower:]' '[:upper:]' <<< "$(basename $@)") > "$@"

%.1.gz:	%.1
	gzip -c < $< > $@

$(MAN3PERLGZ) : %.3perl.gz : %.pm
	pod2man -c 'Perl Programmers Reference Guide' -r "$(VERSION)" --section=3perl $< | gzip -c > $@

$(DESTDIR)$(prefix)/usr/share/man/man1:
	mkdir -p $(DESTDIR)$(prefix)/usr/share/man/man1

$(DESTDIR)$(prefix)/usr/share/man/man3:
	mkdir -p $(DESTDIR)$(prefix)/usr/share/man/man3

$(INSTMAN3PERLGZ) : inst-% : % | $(DESTDIR)$(prefix)/usr/share/man/man3
	cp $(@:inst-%=%) $(DESTDIR)$(prefix)/usr/share/man/man3/$(subst /,::,$<)

install-man1: | $(DESTDIR)$(prefix)/usr/share/man/man1
	cp $(MAN1GZ) $(DESTDIR)$(prefix)/usr/share/man/man1/

install-man: $(INSTMAN3PERLGZ) install-man1

install-mat:
	mkdir -p $(DESTDIR)$(pkgdatadir)/mat && \
		rsync -rC mat/. $(DESTDIR)$(pkgdatadir)/mat/.

install: install-man install-mat
	mkdir -p $(DESTDIR)$(prefix)/usr/share/perl5/RG/Utils && \
		cp RG/Utils/*.pm \
			$(DESTDIR)$(prefix)/usr/share/perl5/RG/Utils/
	mkdir -p $(DESTDIR)$(pkgdatadir) && \
		cp *.pl $(SCRIPTS) \
			$(DESTDIR)$(pkgdatadir)/
	find \
		$(DESTDIR)$(prefix)/usr/share/perl5/RG/Utils \
		$(DESTDIR)$(pkgdatadir) \
		-name '*.p[lm]' -exec \
		sed -i -e 's|__PREFIX__|$(prefix)|g;s|__pkgdatadir__|$(pkgdatadir)|g;' {} \;
	for f in $(SCRIPTS); do \
		sed -i -e 's|__PREFIX__|$(prefix)|g;s|__pkgdatadir__|$(pkgdatadir)|g;s|__sysconfdir__|$(sysconfdir)|g;s|__bindir__|$(bindir)|g;s|__VERSION__|$(VERSION)|g' $(DESTDIR)$(pkgdatadir)/$$f; \
	done

help:
	@echo "Targets:"
	@echo "clean"
	@echo "dist"
	@echo "distclean"
	@echo "install - install-man install-mat"
	@echo "install-man"
	@echo "install-mat"
	@echo
	@echo "Variables:"
	@echo "DESTDIR - install to DESTDIR"
	@echo "prefix - common installation prefix for all files"
	@echo "  use prefix=$$HOME to build for personal use"

distclean: clean
	rm -rf\
		$(DISTDIR)\
		$(DISTDIR).tar.gz

dist:	$(DISTDIR)
	tar -ch -f - "$(DISTDIR)" | gzip -c >$(DISTDIR).tar.gz
	rm -rf $(DISTDIR)

$(DISTDIR): distclean
	rm -rf $(DISTDIR) && mkdir -p $(DISTDIR) && \
	rsync -avC \
		--exclude /*-stamp \
		--exclude .*.swp \
		blast2saf.pl \
		blastpgp_to_saf.pl \
		conv_hssp2saf.pl \
		copf.pl \
		dbSwiss \
		debian \
		hssp_filter.pl \
		runNewPSIC.pl \
		Makefile \
		mat \
	        RG \
		safFilterRed.pl \
		$(DISTDIR)/;

clean: 
	rm -f *.[0123456789].tar.gz 
	rm -f $(MAN3PERLGZ)

.PHONY: all clean install install-man install-man1 install-mat man $(INSTMAN3PERLGZ)

# vim:ai:
