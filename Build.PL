use warnings;
use strict;
use Module::Build;

Module::Build->new(
  module_name => 'RG::Utils',
  license  => 'perl',
  dist_name => 'librg-utils-perl',
  dist_version => '1.0.41',
  dist_author => [ 'Burkhard Rost', 'Laszlo Kajan <lkajan@rostlab.org>', 'Guy Yachdav <gyachdav@rostlab.org>' ],
  dist_abstract => 'modules for file format conversion utilities for bioinformatics',
)->create_build_script;

# vim:et:ts=2:ai:
