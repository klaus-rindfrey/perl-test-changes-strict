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
  my $changes_file = write_changes(q{});
  test_out("not ok 1 - Changes file passed strict checks");
  test_fail(+2);
  test_diag("The '$changes_file' file empty");
  changes_strict_ok(changes_file => $changes_file);
  test_test("fail works");
};

# subtest 'No newline at end of file' => sub {
#   my $changes_file = write_changes('Revision history for distribution Foo-Bar-Baz');
#   test_fail(+3);
#   test_out("not ok 1 - Newline at end of file");
#   test_out("not ok 2 - Changes file passed strict checks");
#   changes_strict_ok(changes_file => $changes_file);
#   test_test("fail works");
# };

# subtest 'trailing white spaces' => sub {
#   subtest 'Changes file contains only white spaces' => sub {
#     my $file = write_changes("\n   \n\n");
#     changes_strict_ok(changes_file => $file);
    
#   };
# };



done_testing;

