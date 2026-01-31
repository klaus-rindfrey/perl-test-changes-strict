use strict;
use warnings;

use Test::More;
use Test::Builder::Tester;

use Test::Changes::Strict qw(changes_strict_ok);

use FindBin;
use lib "$FindBin::Bin/lib";

use File::Temp qw(tempdir);
use Local::Test::Helper qw(:all);



subtest 'missing Changes file' => sub {
  my $non_existing_file = 'this-file-does-not-exist';
  test_out("not ok 1 - Changes file passed strict checks");
  test_fail(+2);
  test_diag("The '$non_existing_file' file does not exist");
  changes_strict_ok(changes_file => 'this-file-does-not-exist');
  test_test("fail works");
};

subtest 'Changes file is a directory, not a file' => sub {
  my $dir = tempdir(CLEANUP => 1);
  test_out("not ok 1 - Changes file passed strict checks");
  test_fail(+2);
  test_diag("The '$dir' file is not a readable text file");
  changes_strict_ok(changes_file => $dir);
  test_test("fail works");
};


subtest 'Changes file is empty' => sub {
  my $fname = write_changes(q{});
  test_out("not ok 1 - Changes file passed strict checks");
  test_fail(+2);
  test_diag("The '$fname' file empty");
  changes_strict_ok(changes_file => $fname);
  test_test("fail works");
};


subtest 'No newline at end of file' => sub {
  my $fname = write_changes('Revision history for distribution Foo-Bar-Baz');
  test_out("not ok 1 - Changes file passed strict checks");
  test_fail(+2);
  test_diag("'$fname': no newline at end of file");
  changes_strict_ok(changes_file => $fname);
  test_test("fail works");
};

subtest 'Wrong title' => sub {
  subtest 'WrongMalformed title' => sub {
    my $fname = write_changes("Revision history for Foo-Bar-Baz\n");
    test_out("not ok 1 - Changes file passed strict checks");
    test_fail(+2);
    test_diag("Missing or malformed 'Revision history ...' at line 1");
    changes_strict_ok(changes_file => $fname);
    test_test("fail works");
  };

  subtest 'Missing title' => sub {
    my $fname = write_changes(<<'EOF');
0.01 2024-02-28

  - Initial release.
EOF
    test_out("not ok 1 - Changes file passed strict checks");
    test_fail(+2);
    test_diag("Missing or malformed 'Revision history ...' at line 1");
    changes_strict_ok(changes_file => $fname);
    test_test("fail works");
  };

  subtest 'one version with one simple entry and heading empty line' => sub  {
    my $fname = write_changes(<<'EOF');

Revision history for distribution Foo-Bar-Baz

0.01 2024-02-28

  - Initial release.
EOF

    test_out("not ok 1 - Changes file passed strict checks");
    test_fail(+2);
    test_diag("Missing or malformed 'Revision history ...' at line 1");
    changes_strict_ok(changes_file => $fname);
    test_test("fail works");
  };
};

subtest 'Non-space white characters' => sub {
  subtest '1 non-space white character' => sub {
    my $fname = write_changes(<<"EOF");
Revision history for distribution Foo-Bar-Baz

0.01 2024-02-28

\t- Initial release.
EOF
    test_out("not ok 1 - Changes file passed strict checks");
    test_fail(+2);
    test_diag("Non-space white characters found at line 5");
    changes_strict_ok(changes_file => $fname);
    test_test("fail works");
  };

  subtest 'Multiple non-space white characters' => sub {
    my $fname = write_changes(<<"EOF");
Revision history for distribution Foo-Bar-Baz

0.02 2024-03-15

  -\tInitial release.

0.01 2024-02-28

\t\r- Initial release.
EOF
    test_out("not ok 1 - Changes file passed strict checks");
    test_fail(+2);
    test_diag("Non-space white characters found at lines 5, 9");
    changes_strict_ok(changes_file => $fname);
    test_test("fail works");
  };
};


done_testing;

