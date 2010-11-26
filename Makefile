PACKAGE := librg-utils-perl
VERSION := 1.0.17
DISTDIR := $(PACKAGE)-$(VERSION)

MAN1POD :=
MAN1GZ := $(MAN1POD:%.pod=%.1.gz)  

MAN3PERLPOD := $(wildcard RG/Utils/*.pm)
MAN3PERLGZ := $(MAN3PERLPOD:%.pm=%.3perl.gz)  
INSTMAN3PERLGZ := $(MAN3PERLGZ:%=inst-%)  

all: man 

man:    $(MAN1GZ) $(MAN3PERLGZ)

$(MAN1GZ) : %.1.gz : %.pod
	pod2man -c 'User Commands' -r "$(VERSION)" $< | gzip -c > $@

$(MAN3PERLGZ) : %.3perl.gz : %.pm
	pod2man -c 'Perl Programmers Reference Guide' -r "$(VERSION)" --section=3perl $< | gzip -c > $@

$(DESTDIR)$(prefix)/usr/share/man/man3:
	mkdir -p $(DESTDIR)$(prefix)/usr/share/man/man3

$(INSTMAN3PERLGZ) : inst-% : % | $(DESTDIR)$(prefix)/usr/share/man/man3
	cp $(@:inst-%=%) $(DESTDIR)$(prefix)/usr/share/man/man3/$(subst /,::,$<)

install-man: $(INSTMAN3PERLGZ)

install-mat:
	mkdir -p $(DESTDIR)$(prefix)/usr/share/librg-utils-perl/mat && \
		rsync -rC mat/. $(DESTDIR)$(prefix)/usr/share/librg-utils-perl/mat/.

install: install-man install-mat
	mkdir -p $(DESTDIR)$(prefix)/usr/share/perl5/RG/Utils && \
		cp RG/Utils/*.pm \
			$(DESTDIR)$(prefix)/usr/share/perl5/RG/Utils/
	mkdir -p $(DESTDIR)$(prefix)/usr/share/librg-utils-perl && \
		cp *.pl \
			$(DESTDIR)$(prefix)/usr/share/librg-utils-perl/
	find \
		$(DESTDIR)$(prefix)/usr/share/perl5/RG/Utils \
		$(DESTDIR)$(prefix)/usr/share/librg-utils-perl \
		-name '*.p[lm]' -exec \
		sed -i -e 's|__PREFIX__|$(prefix)|g' {} \;

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
		debian \
		hssp_filter.pl \
		Makefile \
		mat \
	        RG \
		safFilterRed.pl \
		$(DISTDIR)/;

clean: 
	rm -f *.[0123456789].tar.gz 
	rm -f $(MAN3PERLGZ)

.PHONY: all clean install install-man install-mat man $(INSTMAN3PERLGZ)

# vim:ai:
