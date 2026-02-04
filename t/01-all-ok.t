use strict;
use warnings;

use Test::More;
use Test::Builder::Tester;

use Test::Changes::Strict qw(changes_strict_ok);

use FindBin;
use lib "$FindBin::Bin/lib";

use Local::Test::Helper qw(write_changes set_test_out_all_ok);


subtest 'one version with one simple entry / examples with different titles.' => sub  {
  subtest '1: ... for distribution Foo-Bar-Baz' => sub {
    my $valid_changes = write_changes(<<'EOF');
Revision history for distribution Foo-Bar-Baz

0.01 2024-02-28

  - Initial release.
EOF

    set_test_out_all_ok();
    changes_strict_ok(changes_file => $valid_changes);
    test_test("valid Changes file passes");
  };

  subtest '2 ... for perl distribution Foo-Bar-Baz' => sub {
    my $valid_changes = write_changes(<<'EOF');
Revision history for perl distribution Foo-Bar-Baz

0.01 2024-02-28

  - Initial release.
EOF

    set_test_out_all_ok();
    changes_strict_ok(changes_file => $valid_changes);
    test_test("valid Changes file passes");
  };
  subtest '3: ... for module Foo::Bar::Baz' => sub {
    my $valid_changes = write_changes(<<'EOF');
Revision history for module Foo::Bar::Baz

0.01 2024-02-28

  - Initial release.
EOF

    set_test_out_all_ok();
    changes_strict_ok(changes_file => $valid_changes);
    test_test("valid Changes file passes");
  };
  subtest '4: ... for perl module Foo::Bar::Baz' => sub {
    my $valid_changes = write_changes(<<'EOF');
Revision history for perl module Foo::Bar::Baz

0.01 2024-02-28

  - Initial release.
EOF

    set_test_out_all_ok();
    changes_strict_ok(changes_file => $valid_changes);
    test_test("valid Changes file passes");
  };
};

subtest 'two simple entries and 3 trailing empty lines' => sub  {
  my $valid_changes = write_changes(<<'EOF');
Revision history for distribution Foo-Bar-Baz

0.02 2024-03-01

  - Bugfix.

0.01 2024-02-28

  - Initial release.



EOF
  set_test_out_all_ok();
  changes_strict_ok(changes_file => $valid_changes);
  test_test("valid Changes file passes");
};

subtest 'multiple entries, some with line continuation, 2 versions same day' => sub  {
  my $valid_changes = write_changes(<<'EOF');
Revision history for distribution Foo-Bar-Baz

0.03 2024-03-01

  - Another version, same day.

0.02 2024-03-01

  - Bugfix.
  - Added a very fancy feature that alllows this
    and that.
  - Another bugfix.

0.01 2024-02-28

  - Initial release. This will hopefully work
    fine.

EOF
  set_test_out_all_ok();
  changes_strict_ok(changes_file => $valid_changes);
  test_test("valid Changes file passes");
};



done_testing;
