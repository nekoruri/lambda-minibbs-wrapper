use utf8;
use warnings;
use strict;
use AWS::Lambda::PSGI;
use Plack::App::WrapCGI;

my $app = Plack::App::WrapCGI->new(script => "$ENV{'LAMBDA_TASK_ROOT'}/minibbs.cgi", execute => 1)->to_app;
my $func = AWS::Lambda::PSGI->wrap($app);

sub handle {
    $ENV{'TZ'} = "JST-9";
    return $func->(@_);
}
