RGUtilsdir = @PERLLIBDIR@/RG/Utils
dist_RGUtils_DATA = $(srcdir)/*.pm

man3_MANS =

MAN3PERLPOD = $(wildcard *.pm)
MAN3PERL = $(MAN3PERLPOD:%.pm=%.3perl)
INSTMAN3PERL = $(MAN3PERL:%=inst-%)  

CLEANFILES = $(man3_MANS)

$(MAN3PERL) : %.3perl : %.pm
	pod2man -c 'Perl Programmers Reference Guide' -r "$(VERSION)" --section=3perl $< $@

$(DESTDIR)$(man3dir):
	mkdir -p $(DESTDIR)$(man3dir)

$(INSTMAN3PERL) : inst-% : % | $(DESTDIR)$(man3dir)
	cp $(@:inst-%=%) $(DESTDIR)$(man3dir)/RG::Utils::$(notdir $<)

all-local: $(MAN3PERL)

install-data-local: $(INSTMAN3PERL)
