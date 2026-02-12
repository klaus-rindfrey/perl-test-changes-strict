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
  subtest 'missing dot at end of line' => sub {
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
    test_diag("Line 8: missing dot at end of line");
    test_diag("Line 13: missing dot at end of line");
    changes_strict_ok(changes_file => $fname);
    test_test("fail works");
  };

  subtest 'unexpected empty lines' => sub {
    subtest "unexpected empty line after title" => sub {
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
    subtest "unexpected empty line after version line" => sub {
      my $fname = write_changes(<<'EOF');
Revision history for distribution Foo-Bar-Baz

0.02 2024-03-01


  - Initial release

EOF
      test_out("not ok 1 - Changes file passed strict checks");
      test_fail(+2);
      test_diag("Line 5: unexpected empty line");
      changes_strict_ok(changes_file => $fname);
      test_test("fail works");
    };

    subtest "unexpected empty line between item lines" => sub {
      my $fname = write_changes(<<'EOF');
Revision history for distribution Foo-Bar-Baz

0.02 2024-03-01

  - Bugfix.

  - Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo
    ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis
    dis parturient montes, nascetur ridiculus mus.
  - Donec quam felis.
EOF
      test_out("not ok 1 - Changes file passed strict checks");
      test_fail(+2);
      test_diag("Line 6: unexpected empty line");
      changes_strict_ok(changes_file => $fname);
      test_test("fail works");
    };

    subtest "unexpected empty line between item line and continuation" => sub {
      my $fname = write_changes(<<'EOF');
Revision history for distribution Foo-Bar-Baz

0.02 2024-03-01

  - Bugfix.
  - Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo
    ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis
    dis parturient montes, nascetur ridiculus mus.

    Donec sodales sagittis magna.
  - Donec quam felis.
EOF
      test_out("not ok 1 - Changes file passed strict checks");
      test_fail(+2);
      test_diag("Line 9: unexpected empty line");
      changes_strict_ok(changes_file => $fname);
      test_test("fail works");
    };

    subtest "unexpected empty line between item line and version line" => sub {
      my $fname = write_changes(<<'EOF');
Revision history for distribution Foo-Bar-Baz

0.02 2024-03-01

  - Bugfix.
  - Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo
    ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis
    dis parturient montes, nascetur ridiculus mus.
  - Donec quam felis.



0.01 2024-02-28

  - Initial release.
EOF
      test_out("not ok 1 - Changes file passed strict checks");
      test_fail(+2);
      test_diag("Line 10: unexpected empty line");
      changes_strict_ok(changes_file => $fname);
      test_test("fail works");
    };
  };

  subtest 'unexpected version line' => sub {
    subtest 'unexpected version line immediately after title line' => sub {
      my $fname = write_changes(<<'EOF');
Revision history for distribution Foo-Bar-Baz
0.02 2024-03-01

  - Bugfix.
EOF
      test_out("not ok 1 - Changes file passed strict checks");
      test_fail(+2);
      test_diag("Line 2: unexpected version line");
      changes_strict_ok(changes_file => $fname);
      test_test("fail works");
    };

    subtest 'unexpected version line immediately after version line' => sub {
      my $fname = write_changes(<<'EOF');
Revision history for distribution Foo-Bar-Baz

0.03 2024-04-01

  - Bugfix.
  - Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo
    ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis
    dis parturient montes, nascetur ridiculus mus.
  - Donec quam felis.

0.02 2024-03-10
0.01 2024-02-28

  - Initial release.
EOF
      test_out("not ok 1 - Changes file passed strict checks");
      test_fail(+2);
      test_diag("Line 12: unexpected version line");
      changes_strict_ok(changes_file => $fname);
      test_test("fail works");
    };

    subtest 'unexpected version line after empty line after version line' => sub {
      my $fname = write_changes(<<'EOF');
Revision history for distribution Foo-Bar-Baz

0.03 2024-04-01

  - Bugfix.
  - Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo
    ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis
    dis parturient montes, nascetur ridiculus mus.
  - Donec quam felis.

0.02 2024-03-10

0.01 2024-02-28

  - Initial release.
EOF
      test_out("not ok 1 - Changes file passed strict checks");
      test_fail(+2);
      test_diag("Line 13: unexpected version line");
      changes_strict_ok(changes_file => $fname);
      test_test("fail works");
    };
  };



  subtest 'Version line check' => sub {
    subtest 'Not exactly two values' => sub {
      subtest 'Version, but no date' => sub {
        my $fname = write_changes(<<'EOF');
Revision history for distribution Foo-Bar-Baz

0.03

  - Bugfix.
EOF
        test_out("not ok 1 - Changes file passed strict checks");
        test_fail(+2);
        test_diag("Line 3: version check: not exactly two values");
        changes_strict_ok(changes_file => $fname);
        test_test("fail works");
      };
      subtest 'No version, but a date' => sub {
        my $fname = write_changes(<<'EOF');
Revision history for distribution Foo-Bar-Baz

2024-04-01

  - Bugfix.
EOF
        test_out("not ok 1 - Changes file passed strict checks");
        test_fail(+2);
        test_diag("Line 3: version check: not exactly two values");
        changes_strict_ok(changes_file => $fname);
        test_test("fail works");
      };
    };

    subtest 'invalid version' => sub {
      subtest 'too many dots' => sub {
        my $fname = write_changes(<<'EOF');
Revision history for distribution Foo-Bar-Baz

0.03.5.9 2024-04-01

  - Bugfix.
EOF
        test_out("not ok 1 - Changes file passed strict checks");
        test_fail(+2);
        test_diag("Line 3: version check: 0.03.5.9: invalid version");
        changes_strict_ok(changes_file => $fname);
        test_test("fail works");
      };
      subtest "heading 'v'" => sub {
        my $fname = write_changes(<<'EOF');
Revision history for distribution Foo-Bar-Baz

v0.03 2024-04-01

  - Bugfix.
EOF
        test_out("not ok 1 - Changes file passed strict checks");
        test_fail(+2);
        test_diag("Line 3: version check: v0.03: invalid version");
        changes_strict_ok(changes_file => $fname);
        test_test("fail works");
      };
    };
  };


  subtest 'Invalid date' => sub {
    subtest 'wrong format' => sub {
      subtest 'wrong format: separator' => sub {
        my $fname = write_changes(<<'EOF');
Revision history for distribution Foo-Bar-Baz

0.03 2024/04/01

  - Bugfix.
EOF
        test_out("not ok 1 - Changes file passed strict checks");
        test_fail(+2);
        test_diag("Line 3: version check: 2024/04/01: invalid date: wrong format");
        changes_strict_ok(changes_file => $fname);
        test_test("fail works");
      };

      subtest 'wrong format: too many digits' => sub {
        my $fname = write_changes(<<'EOF');
Revision history for distribution Foo-Bar-Baz

0.03 2024-004-01

  - Bugfix.
EOF
        test_out("not ok 1 - Changes file passed strict checks");
        test_fail(+2);
        test_diag("Line 3: version check: 2024-004-01: invalid date: wrong format");
        changes_strict_ok(changes_file => $fname);
        test_test("fail works");
      };
    };

    subtest 'Non-existent date' => sub {
      subtest '35 May' => sub {
        my $fname = write_changes(<<'EOF');
Revision history for distribution Foo-Bar-Baz

0.03 2024-05-35

  - Bugfix.
EOF
        test_out("not ok 1 - Changes file passed strict checks");
        test_fail(+2);
        test_diag("Line 3: version check: '2024-05-35': invalid date");
        changes_strict_ok(changes_file => $fname);
        test_test("fail works");
      };

      subtest '29 February, but not a leap year' => sub {
        my $fname = write_changes(<<'EOF');
Revision history for distribution Foo-Bar-Baz

0.03 2025-02-29

  - Bugfix.
EOF
        test_out("not ok 1 - Changes file passed strict checks");
        test_fail(+2);
        test_diag("Line 3: version check: '2025-02-29': invalid date");
        changes_strict_ok(changes_file => $fname);
        test_test("fail works");
      };
    };
    subtest 'future date' => sub {
      my $next_year = (localtime)[5] + 1900 + 1;
      my $fname = write_changes(<<"EOF");
Revision history for distribution Foo-Bar-Baz

0.01 $next_year-04-03

  - Initial release.
EOF
      test_out("not ok 1 - Changes file passed strict checks");
      test_fail(+2);
      test_diag("Line 3: version check: $next_year-04-03: date is in the future.");
      changes_strict_ok(changes_file => $fname);
      test_test("fail works");
    };
    subtest 'before Perl era' => sub {
      my $fname = write_changes(<<"EOF");
Revision history for distribution Foo-Bar-Baz

0.01 1965-04-03

  - Initial release.
EOF
      test_out("not ok 1 - Changes file passed strict checks");
      test_fail(+2);
      test_diag("Line 3: version check: 1965-04-03: before Perl era");
      changes_strict_ok(changes_file => $fname);
      test_test("fail works");
    };
  };


  subtest 'unexpected item line' => sub {
    my $fname = write_changes(<<"EOF");
Revision history for distribution Foo-Bar-Baz

  - Initial release.

0.03 2025-04-03

  - Bugfix.
EOF
    test_out("not ok 1 - Changes file passed strict checks");
    test_fail(+2);
    test_diag("Line 3: unexpected item line");
    changes_strict_ok(changes_file => $fname);
    test_test("fail works");
  };

  subtest "invalid item content" => sub {
    subtest "empty item" => sub {
      my $fname = write_changes(<<"EOF");
Revision history for distribution Foo-Bar-Baz

0.03 2025-04-03

  - Bugfix.
  -
  - Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo
    ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis
    dis parturient montes, nascetur ridiculus mus.
  - Donec quam felis.
EOF
    test_out("not ok 1 - Changes file passed strict checks");
    test_fail(+2);
    test_diag("Line 6: invalid item content");
    changes_strict_ok(changes_file => $fname);
    test_test("fail works");
    };

    subtest "no space after dash" => sub {
      my $fname = write_changes(<<"EOF");
Revision history for distribution Foo-Bar-Baz

0.03 2025-04-03

  - Bugfix.
  -Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo
    ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis
    dis parturient montes, nascetur ridiculus mus.
  - Donec quam felis.
EOF
    test_out("not ok 1 - Changes file passed strict checks");
    test_fail(+2);
    test_diag("Line 6: invalid item content");
    changes_strict_ok(changes_file => $fname);
    test_test("fail works");
    };

    subtest "more than 1 space after dash" => sub {
      my $fname = write_changes(<<"EOF");
Revision history for distribution Foo-Bar-Baz

0.03 2025-04-03

  - Bugfix.
  - Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo
    ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis
    dis parturient montes, nascetur ridiculus mus.
  -   Donec quam felis.
EOF
    test_out("not ok 1 - Changes file passed strict checks");
    test_fail(+2);
    test_diag("Line 9: invalid item content");
    changes_strict_ok(changes_file => $fname);
    test_test("fail works");
    };
  };

  subtest 'item line: no indentation / wrong indentation' => sub {
    my $fname = write_changes(<<"EOF");
Revision history for distribution Foo-Bar-Baz

0.03 2025-04-03

  - Bugfix. Donec sodales sagittis magna.
- Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo
    ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis
    dis parturient montes, nascetur ridiculus mus.
    - Donec quam felis.
  - Etiam ultricies nisi vel augue. Curabitur ullamcorper ultricies nisi.

0.01 2024-02-28

 - Initial release.
EOF
    test_out("not ok 1 - Changes file passed strict checks");
    test_fail(+4);
    test_diag("Line 6: no indentation");
    test_diag("Line 9: wrong indentation");
    test_diag("Line 14: wrong indentation");
    changes_strict_ok(changes_file => $fname);
    test_test("fail works");
  };
  subtest 'unexpected item continuation' => sub {
    subtest 'immediately after title' => sub {
      my $fname = write_changes(<<"EOF");
Revision history for distribution Foo-Bar-Baz
  Donec sodales sagittis magna.

0.03 2025-04-03

  - Bugfix.
EOF
      test_out("not ok 1 - Changes file passed strict checks");
      test_fail(+2);
      test_diag("Line 2: unexpected item continuation");
      changes_strict_ok(changes_file => $fname);
      test_test("fail works");
    };
    subtest 'after empty line after title' => sub {
      my $fname = write_changes(<<"EOF");
Revision history for distribution Foo-Bar-Baz

  Donec sodales sagittis magna.

0.03 2025-04-03

  - Bugfix.
EOF
      test_out("not ok 1 - Changes file passed strict checks");
      test_fail(+2);
      test_diag("Line 3: unexpected item continuation");
      changes_strict_ok(changes_file => $fname);
      test_test("fail works");
    };
    subtest 'immediately after version line' => sub {
      my $fname = write_changes(<<"EOF");
Revision history for distribution Foo-Bar-Baz

0.03 2025-04-03
  Donec sodales sagittis magna.

  - Bugfix.
EOF
      test_out("not ok 1 - Changes file passed strict checks");
      test_fail(+2);
      test_diag("Line 4: unexpected item continuation");
      changes_strict_ok(changes_file => $fname);
      test_test("fail works");
    };
    subtest 'after empty line after version line' => sub {
      my $fname = write_changes(<<"EOF");
Revision history for distribution Foo-Bar-Baz

0.03 2025-04-03

  Donec sodales sagittis magna.

  - Bugfix.
EOF
      test_out("not ok 1 - Changes file passed strict checks");
      test_fail(+2);
      test_diag("Line 5: unexpected item continuation");
      changes_strict_ok(changes_file => $fname);
      test_test("fail works");
    };
  };
  subtest 'item continuation: wrong indentation' => sub {
    my $fname = write_changes(<<"EOF");
Revision history for distribution Foo-Bar-Baz

0.03 2025-04-03

  - Bugfix.
  - Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo
  ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis
    dis parturient montes, nascetur ridiculus mus.
  - Donec quam felis.
  - Etiam ultricies nisi vel augue. Curabitur ullamcorper ultricies nisi.
      Donec sodales sagittis magna.

0.01 2024-02-28

  - Initial release.
EOF
    test_out("not ok 1 - Changes file passed strict checks");
    test_fail(+3);
    test_diag("Line 7: wrong indentation");
    test_diag("Line 11: wrong indentation");
    changes_strict_ok(changes_file => $fname);
    test_test("fail works");
  };
  subtest "unexpected end of file" => sub {
    subtest "EOF after title line" => sub {
      my $fname = write_changes(<<"EOF");
Revision history for distribution Foo-Bar-Baz

EOF
      test_out("not ok 1 - Changes file passed strict checks");
      test_fail(+2);
      test_diag("unexpected end of file");
      changes_strict_ok(changes_file => $fname);
      test_test("fail works");
    };
    subtest "EOF after version line" => sub {
      my $fname = write_changes(<<"EOF");
Revision history for distribution Foo-Bar-Baz

0.03 2025-04-03

EOF
      test_out("not ok 1 - Changes file passed strict checks");
      test_fail(+2);
      test_diag("unexpected end of file");
      changes_strict_ok(changes_file => $fname);
      test_test("fail works");
    };
  };
};                              # /check changes

# -------------------------------------------------------------------------------------------------

done_testing;

