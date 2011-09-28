Summary: a set of wrappers and conversion utilities for bioinformatics databases
Name: librg-utils-perl
Version: 1.0.41
Release: 1
License: GPL
Group: Applications/Science
Source: ftp://rostlab.org/%{name}/%{name}-%{version}.tar.gz
URL: http://rostlab.org/
BuildArch: noarch
BuildRoot: %{_tmppath}/%{name}-%{version}-root
BuildRequires: perl
Requires: perl-List-MoreUtils, profphd-utils

%description
 This package contains assorted tools like:
 .
 * blast2saf.pl, blastpgp_to_saf.pl, conv_hssp2saf.pl, copf.pl, hssp_filter.pl,
 safFilterRed.pl
 .
 and modules like:
 .
 * RG:Utils::Conv_hssp2saf RG:Utils::Copf RG:Utils::Hssp_filter

%prep
%setup -q

%build
%configure PERLLIBDIR=%{perl_vendorlib}
make

%install
rm -rf $RPM_BUILD_ROOT
make DESTDIR=${RPM_BUILD_ROOT} install

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%doc AUTHORS
%doc COPYING
%{_mandir}/*/*
%{_datadir}/%{name}/*
%{perl_vendorlib}/RG/Utils/*

%changelog
* Mon Jun 27 2011 Laszlo Kajan <lkajan@rostlab.org> - 1.0.41-1
- new upstream
* Mon Jun 27 2011 Laszlo Kajan <lkajan@rostlab.org> - 1.0.39-1
- new upstream
* Wed Jun 22 2011 Laszlo Kajan <lkajan@rostlab.org> - 1.0.38-1
- new upstream
* Tue Jun 21 2011 Laszlo Kajan <lkajan@rostlab.org> - 1.0.37-1
- new upstream
* Tue Jun 21 2011 Laszlo Kajan <lkajan@rostlab.org> - 1.0.36-2
- spec file in dist root, DESTDIR on install
* Wed Jun 16 2011 Guy Yachdav <gyachdav@rostlab.org> - 1.0.36-1
- Initial build.
