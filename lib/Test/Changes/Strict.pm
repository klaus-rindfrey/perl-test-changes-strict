package Test::Changes::Strict;

use 5.010;
use strict;
use warnings;

#use autodie;
use version;

use Test::Builder;

use Time::Local;

use Data::Dumper;

use Exporter 'import';
our @EXPORT_OK = qw(changes_strict_ok);

our $VERSION = '0.01';

#
# The use of global variables is acceptable, as we never check more than one
# Changes file at a time.
#
my $TB = Test::Builder->new;

my $Ver_re = qr/\b\d+\.\d+\b/;

use constant {
              map { $_ => $_ } qw(
                                   st_chlog_head
                                   st_empty_after_head
                                   st_version
                                   st_empty_after_version
                                   st_item
                                   st_item_cont
                                   st_empty_after_item
                                   st_EOF
                                )
             };

use constant {
              NOW      => time,
             };


my %states = (
              +st_chlog_head          => [st_empty_after_head],
              +st_empty_after_head    => [st_version],
              +st_version             => [st_empty_after_version],
              +st_empty_after_version => [st_item],
              +st_item                => [st_item, st_item_cont, st_empty_after_item, st_EOF],
              +st_item_cont           => [st_item, st_item_cont, st_empty_after_item],
              +st_empty_after_item    => [st_version, st_EOF],
              +st_EOF                 => [],
             );
$_ = { map { $_ => undef } @$_ } for values %states;
my %empty_line_st = (+st_chlog_head => st_empty_after_head,
                     +st_version    => st_empty_after_version,
                     +st_item       => st_empty_after_item,
                    );
my %item_line = (+st_item => undef, +st_item_cont => undef);

my $Test_Name = "Changes file passed strict checks";

#my $Mod_Version = "0.05";   # !!!!!!!!!!!!!


sub changes_strict_ok {
  my %args = @_;
  my $changes_file = $args{changes_file} // "Changes";

  my $test_name = "Changes file passed strict checks";

  my @lines;
  _read_file($changes_file, \@lines) or return;

  _check_and_clean_spaces(\@lines) or return;
  _check_title(\@lines) or return;

  my @versions;
  _check_changes(\@lines, \@versions) or return;
  #
  ###########
  _check_version_monotonic(\@versions) or return;
  _check_trailing_empty_lines(\@lines) or return;

  $TB->ok(1, $Test_Name);
}


sub _read_file {
  my ($fname, $lines) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  -e $fname or return _not_ok("The '$fname' file does not exist");
  -f $fname && -r $fname && -T $fname or
    return _not_ok("The '$fname' file is not a readable text file");
  open(my $fh, '<', $fname) or return _not_ok("Cannot open '$fname': $!");
  @$lines = <$fh> or return _not_ok("The '$fname' file empty");
  substr($lines->[-1], -1) eq "\n" or return _not_ok("'$fname': no newline at end of file");
  chomp(@$lines);
  return !0;
}



# helper function
sub _version_line_check {
  # Line is already trimmed!
  my $line = shift;
  (my ($version, $date) = split(/\s+/, $line)) == 2 or return("not exactly two values");
  $version =~ $Ver_re or return("invalid version");
  my ($y, $m, $d);
  if (length($date // "")) {
    $date =~ /(\d{4})-(\d{2})-(\d{2})/ or return("invalid date");
    ($y, $m, $d) = ($1, $2, $3);
  } else {
    return("missing date");
  }

  my $epoch;
  eval {
    $epoch = Time::Local::timegm(0, 0, 0, $d, $m-1, $y);
    1;
  } or return "'$date': invalid date";
  #-----------
  $y >= 1987 or return "$date before Perl era";
  $epoch <= NOW      or return "$date: date is in the future.";
  return {version => version->parse($version),
          version_str => $version,
          date => $date,
          epoch => $epoch};
}


# sub _check_changes {
#   my ($lines, $versions) = @_;
#   local $Test::Builder::Level = $Test::Builder::Level + 1;
#   my $indent;
#   my $state = st_chlog_head;
#   my %errors;
#   my $err = sub { push(@{$errors{$_[0]}}, $_[1]); };
#   my $i = 2;
#   for (; $i <= @$lines; ++$i) {
#     my $line = $lines->[$i - 1];
#     if ($line eq "") {
#       my $old_state = $state;
#       $err->($i - 1, "Missing dot at end of line")
#         if (exists($item_line{$old_state}) && $lines->[$i - 2] !~ /\.$/);
#       $state = $empty_line_st{$state} // do { $err->($i, "unexpected empty line ($old_state)");
#                                               last;
#                                             };
#       next;
#     }
#     if ($line =~ /^[^-\s]/) {
#       exists($states{$state}->{+st_version}) or do { $err->($i, "unexpected version line");
#                                                      last;
#                                                    };
#       $state = st_version;
#       my $result = _version_line_check($line);
#       if (ref($result)) {
#         $result->{line} = $i;
#         push(@$versions, $result);
#       } else {
#         $err->($i, "version check: $result");
#       }
#     } elsif ($line =~ s/^(\s*)-//) {
#       my $heading_spaces = $1;
#       exists($states{$state}->{+st_item}) or do { $err->($i, "unexpected item line");
#                                                   last;
#                                                 };
#       $err->($i - 1, "Missing dot at end of line")
#         if (exists($item_line{$state}) && $lines->[$i - 2] !~ /\.$/);
#       $err->($i, "Invalid item content") unless $line =~ /^ \S+/;
#       $state = st_item;
#       if ($heading_spaces eq "") {
#         $err->($i, "No indentation");
#       } elsif (defined($indent)) {
#         $err->($i, "Wrong indentation") if length($heading_spaces) != $indent;
#       } else {
#         $indent = length($heading_spaces);
#       }
#     } elsif ($line =~ /^(\s+)[^-\s]/) {
#       exists($states{$state}->{+st_item_cont}) or do { $err->($i, "unexpected item continuation");
#                                                        last;
#                                                      };
#       my $state = st_item_cont;
#       my $heading_spaces = $1;
#       $err->($i, "Wrong indentation") if length($heading_spaces) != $indent + 2;
#     }
#   }
#   #  print "--->>> $state\n";
#   my $diag;
#   if (%errors || ($i > @$lines && !exists($states{$state}->{+st_EOF}))) {
#     if (%errors) {
#       $diag = join("\n",
#                    (map {"Line $_: " . join("; ", @{$errors{$_}})}
#                     (sort { $a <=> $b } keys(%errors))));
#     }
#     # !!!!!
#     $diag = join('; ', ($diag // ()), "Unexpected end of file ($state)")
#       if ($i > @$lines && !exists($states{$state}->{+st_EOF}));
#   }
#   return $diag ? _not_ok($diag) : !0;
# }


# sub _check_version_monotonic {
#   my ($versions) = @_;
#   local $Test::Builder::Level = $Test::Builder::Level + 1;
#   my $diag;
#   if (@$versions) {
#     for (my $i = 0; $i < $#$versions; ++$i) {
#       my ($v1, $e1) = @{$versions->[$i]    }{qw(version epoch)};
#       my ($v2, $e2) = @{$versions->[$i + 1]}{qw(version epoch)};
#       unless ($v1 > $v2) {
#         my $vs1 = $versions->[$i]->{version_str};
#         my $vs2 = $versions->[$i + 2]->{version_str};
#         $diag = "$vs1 vs. $vs2: wrong order of versions";
#         last;
#       }
#       if ($e1 < $e2) {
#         my $d1 = $versions->[$i]->{date};
#         my $d2 = $versions->[$i + 1]->{date};
#         $diag = "date $d1 < $d2: chronologically inconsistent";
#         last;
#       }
#     }
#   } else {
#     $diag = "No versions to check";
#   }
#   return $diag ? _not_ok($diag) : !0;
# }

# sub _check_trailing_empty_lines {
#   my ($lines) = @_;
#   local $Test::Builder::Level = $Test::Builder::Level + 1;
#   my $ok = !1;
#   for (my $i = 1; ($i <= 3 && $i < @$lines) && !$ok ; ++$i) {
#     $ok = $lines->[-$i] ne "";
#   }
#   return $ok ? !0 : _not_ok("No more than three blank lines at the end of the file");
# }

#---------------------------------------------------------

sub _not_ok {
  my ($diag) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  $TB->ok(0, $Test_Name);
  $TB->diag($diag);
  return !1;
}


sub _check_and_clean_spaces {
  my ($lines) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  my (@other_spaces, @trailing_spaces);
  for (my $i = 1; $i <= @$lines; ++$i) {
    $lines->[$i - 1] =~ s/[^\S\ ]/\ /g and push(@other_spaces, $i);
    $lines->[$i - 1] =~ s/\s+$// and push(@trailing_spaces, $i);
  }
  my $diag;
  if (@other_spaces) {
    my $plural = @other_spaces > 1 ? "s" : "";
    $diag = "Non-space white characters found at line$plural " . join(', ', @other_spaces);
  }
  if (@trailing_spaces) {
    my $plural = @trailing_spaces > 1 ? "s" : "";
    $diag = join('; ',
                 ($diag // ()),
                 "Trailing white characters at line$plural " . join(', ', @trailing_spaces));
  }
  return $diag ? _not_ok($diag) : !0;
}


sub _check_title {
  my ($lines) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  my $test_name = "Header line ok";
  my $ok = $lines->[0] =~ qr/
                              ^
                              Revision\ history\ for\ (?:
                                (?:perl\ )?
                                (?:
                                  (?:module\ \w+(?:::\w+)*)
                                |
                                  (?:distribution\ \w+(?:-\w+)*)
                                )
                              )
                              $
                            /x;
  return $ok ? !0 : _not_ok("Missing or malformed 'Revision history ...' at line 1");
}


sub _check_changes {
  my ($lines, $versions) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  my $indent;
  my $state = st_chlog_head;
  my %errors;
  my $err = sub { push(@{$errors{$_[0]}}, $_[1]); };
  my $i = 2;
  for (; $i <= @$lines; ++$i) {
    my $line = $lines->[$i - 1];
    if ($line eq "") {
      my $old_state = $state;
      $err->($i - 1, "Missing dot at end of line")
        if (exists($item_line{$old_state}) && $lines->[$i - 2] !~ /\.$/);
      $state = $empty_line_st{$state} // do { $err->($i, "unexpected empty line ($old_state)");
                                              last;
                                            };
      next;
    }
    if ($line =~ /^[^-\s]/) {
      exists($states{$state}->{+st_version}) or do { $err->($i, "unexpected version line");
                                                     last;
                                                   };
      $state = st_version;
      my $result = _version_line_check($line);
      if (ref($result)) {
        $result->{line} = $i;
        push(@$versions, $result);
      } else {
        $err->($i, "version check: $result");
      }
    } elsif ($line =~ s/^(\s*)-//) {
      my $heading_spaces = $1;
      exists($states{$state}->{+st_item}) or do { $err->($i, "unexpected item line");
                                                  last;
                                                };
      $err->($i - 1, "Missing dot at end of line")
        if (exists($item_line{$state}) && $lines->[$i - 2] !~ /\.$/);
      $err->($i, "Invalid item content") unless $line =~ /^ \S+/;
      $state = st_item;
      if ($heading_spaces eq "") {
        $err->($i, "No indentation");
      } elsif (defined($indent)) {
        $err->($i, "Wrong indentation") if length($heading_spaces) != $indent;
      } else {
        $indent = length($heading_spaces);
      }
    } elsif ($line =~ /^(\s+)[^-\s]/) {
      exists($states{$state}->{+st_item_cont}) or do { $err->($i, "unexpected item continuation");
                                                       last;
                                                     };
      my $state = st_item_cont;
      my $heading_spaces = $1;
      $err->($i, "Wrong indentation") if length($heading_spaces) != $indent + 2;
    }
  }
  #  print "--->>> $state\n";
  my $diag;
  if (%errors || ($i > @$lines && !exists($states{$state}->{+st_EOF}))) {
    if (%errors) {
      $diag = join("\n",
                   (map {"Line $_: " . join("; ", @{$errors{$_}})}
                    (sort { $a <=> $b } keys(%errors))));
    }
    # !!!!!
    $diag = join('; ', ($diag // ()), "Unexpected end of file ($state)")
      if ($i > @$lines && !exists($states{$state}->{+st_EOF}));
  }
  return $diag ? _not_ok($diag) : !0;
}


sub _check_version_monotonic {
  my ($versions) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  my $diag;
  if (@$versions) {
    for (my $i = 0; $i < $#$versions; ++$i) {
      my ($v1, $e1) = @{$versions->[$i]    }{qw(version epoch)};
      my ($v2, $e2) = @{$versions->[$i + 1]}{qw(version epoch)};
      unless ($v1 > $v2) {
        my $vs1 = $versions->[$i]->{version_str};
        my $vs2 = $versions->[$i + 2]->{version_str};
        $diag = "$vs1 vs. $vs2: wrong order of versions";
        last;
      }
      if ($e1 < $e2) {
        my $d1 = $versions->[$i]->{date};
        my $d2 = $versions->[$i + 1]->{date};
        $diag = "date $d1 < $d2: chronologically inconsistent";
        last;
      }
    }
  } else {
    $diag = "No versions to check";
  }
  return $diag ? _not_ok($diag) : !0;
}


sub _check_trailing_empty_lines {
  my ($lines) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  my $ok = !1;
  for (my $i = 1; ($i <= 3 && $i < @$lines) && !$ok ; ++$i) {
    $ok = $lines->[-$i] ne "";
  }
  return $ok ? !0 : _not_ok("No more than three blank lines at the end of the file");
}

1; # End of Test::Changes::Strict
