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
  subtest 'Malformed title 1' => sub {
    my $fname = write_changes("Revision history for Foo-Bar-Baz\n");
    test_out("not ok 1 - Changes file passed strict checks");
    test_fail(+2);
    test_diag("Missing or malformed 'Revision history ...' at line 1");
    changes_strict_ok(changes_file => $fname);
    test_test("fail works");
  };

  subtest 'Malformed title 2' => sub {
    my $fname = write_changes("Revision history for module Foo-Bar-Baz\n");
    test_out("not ok 1 - Changes file passed strict checks");
    test_fail(+2);
    test_diag("Missing or malformed 'Revision history ...' at line 1");
    changes_strict_ok(changes_file => $fname);
    test_test("fail works");
  };

  subtest 'Malformed title 3' => sub {
    my $fname = write_changes("Revision history for distribution Foo::Bar::Baz\n");
    test_out("not ok 1 - Changes file passed strict checks");
    test_fail(+2);
    test_diag("Missing or malformed 'Revision history ...' at line 1");
    changes_strict_ok(changes_file => $fname);
    test_test("fail works");
  };

  subtest 'Malformed title 4' => sub {
    my $fname = write_changes("Revision history for distribution Foo-Bar::Baz\n");
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
    test_diag("Non-space white character found at line 5");
    changes_strict_ok(changes_file => $fname);
    test_test("fail works");
  };

  subtest 'Multiple non-space white characters' => sub {
    my $fname = write_changes(<<"EOF");
Revision history for distribution Foo-Bar-Baz

0.02 2024-03-15

  -\tAnother release.

0.01 2024-02-28

\t\r- Initial release.
EOF
    test_out("not ok 1 - Changes file passed strict checks");
    test_fail(+2);
    test_diag("Non-space white character found at lines 5, 9");
    changes_strict_ok(changes_file => $fname);
    test_test("fail works");
  };
};


subtest 'Trailing blanks' => sub {
  my @changes = ("Revision history for distribution Foo-Bar-Baz",  # 0 - line  1
                 "",                                               # 1 - line  2
                 "0.02 2024-03-01",                                # 2 - line  3
                 "",                                               # 3 - line  4
                 "  - Bugfix.",                                    # 4 - line  5
                 "",                                               # 5 - line  6
                 "0.01 2024-02-28",                                # 6 - line  7
                 "",                                               # 7 - line  8
                 "  - Initial release.",                           # 8 - line  9
                 ""                                                # 9 - line 10
                );
  subtest 'Trailing blanks in title line' => sub {
    my @test_input = @changes;
    $test_input[0] .= "  ";
    my $fname = write_changes(join("\n", @test_input));
    test_out("not ok 1 - Changes file passed strict checks");
    test_fail(+2);
    test_diag("Trailing white character at line 1");
    changes_strict_ok(changes_file => $fname);
    test_test("fail works");
  };

  subtest 'Trailing blanks in empty line' => sub {
    my @test_input = @changes;
    $test_input[3] .= "  ";
    my $fname = write_changes(join("\n", @test_input));
    test_out("not ok 1 - Changes file passed strict checks");
    test_fail(+2);
    test_diag("Trailing white character at line 4");
    changes_strict_ok(changes_file => $fname);
    test_test("fail works");
  };

  subtest 'Trailing blanks in multiple lines' => sub {
    my @test_input = @changes;
    $test_input[$_] .= "  " for (1, 2, 4);
    my $fname = write_changes(join("\n", @test_input));
    test_out("not ok 1 - Changes file passed strict checks");
    test_fail(+2);
    test_diag("Trailing white character at lines 2, 3, 5");
    changes_strict_ok(changes_file => $fname);
    test_test("fail works");
  };

  subtest 'Trailing blanks and non-blank white chars in multiple lines' => sub {
    my @test_input = @changes;
    $test_input[1] .= "\t ";
    $test_input[2] .= "    ";
    substr($test_input[4], 0, 1) = "\t";
    substr($test_input[8], 0, 1) = "\t";
    $test_input[8] .= " ";
    my $fname = write_changes(join("\n", @test_input));
    my $diag =
      "Non-space white character found at lines 2, 5, 9" .
      ". " .
      "Trailing white character at lines 2, 3, 9";
    test_out("not ok 1 - Changes file passed strict checks");
    test_fail(+2);
    test_diag($diag);
    changes_strict_ok(changes_file => $fname);
    test_test("fail works");
  };

  subtest '4 trailing empty lines' => sub {
    my $fname = write_changes(join("\n", (@changes, ("") x 4)));
    test_out("not ok 1 - Changes file passed strict checks");
    test_fail(+2);
    test_diag("More than 3 empty lines at end of file");
    changes_strict_ok(changes_file => $fname);
    test_test("fail works");
  };
};


subtest 'check changes' => sub {
  subtest 'Missing dot at end of line' => sub {
    my $fname = write_changes(<<'EOF');
Revision history for distribution Foo-Bar-Baz

0.02 2024-03-01

  - Bugfix.
  - Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo
    ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis
    dis parturient montes, nascetur ridiculus mus
  - Donec quam felis.

0.01 2024-02-28

  - Initial release

EOF
    test_out("not ok 1 - Changes file passed strict checks");
    test_fail(+3);
    test_diag("Line 8: Missing dot at end of line");
    test_diag("Line 13: Missing dot at end of line");
    changes_strict_ok(changes_file => $fname);
    test_test("fail works");
  };

  subtest 'unexpected empty lines' => sub {
    my $fname = write_changes(<<'EOF');
Revision history for distribution Foo-Bar-Baz


0.02 2024-03-01

  - Initial release

EOF
    test_out("not ok 1 - Changes file passed strict checks");
    test_fail(+2);
    test_diag("Line 3: unexpected empty line");
    changes_strict_ok(changes_file => $fname);
    test_test("fail works");
  };
};


done_testing;

