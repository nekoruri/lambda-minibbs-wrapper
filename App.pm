package App;

# See: https://metacpan.org/pod/Plack::App::WrapCGI

use strict;
use warnings;
use parent qw(Plack::Component);
use Plack::Util::Accessor qw(script execute _app);
use File::Spec;
use Carp;
use POSIX ":sys_wait_h";

sub slurp_fh {
    my $fh = $_[0];
    local $/;
    my $v = <$fh>;
    defined $v ? $v : '';
}

sub prepare_app {
    my $self = shift;
    my $script = $self->script
        or croak "'script' is not set";

    $script = File::Spec->rel2abs($script);

    my $app = sub {
        my $env = shift;

        pipe( my $stdoutr, my $stdoutw );
        pipe( my $stdinr,  my $stdinw );

        local $SIG{CHLD} = 'DEFAULT';

        my $pid = fork();
        Carp::croak("fork failed: $!") unless defined $pid;


        if ($pid == 0) { # child
            local $SIG{__DIE__} = sub {
                print STDERR @_;
                exit(1);
            };

            close $stdoutr;
            close $stdinw;

            local %ENV = (%ENV, CGI::Emulate::PSGI->emulate_environment($env));

            open( STDOUT, ">&=" . fileno($stdoutw) )
              or Carp::croak "Cannot dup STDOUT: $!";
            open( STDIN, "<&=" . fileno($stdinr) )
              or Carp::croak "Cannot dup STDIN: $!";

            chdir(File::Basename::dirname($script));
            exec("perl $script") or Carp::croak("cannot exec: $!");

            exit(2);
        }

        close $stdoutw;
        close $stdinr;

        syswrite($stdinw, slurp_fh($env->{'psgi.input'}));
        # close STDIN so child will stop waiting
        close $stdinw;

        my $res = ''; my $waited_pid;
        while (($waited_pid = waitpid($pid, WNOHANG)) == 0) {
            $res .= slurp_fh($stdoutr);
        }
        $res .= slurp_fh($stdoutr);

        # -1 means that the child went away, and something else
        # (probably some global SIGCHLD handler) took care of it;
        # yes, we just reset $SIG{CHLD} above, but you can never
        # be too sure
        if (POSIX::WIFEXITED($?) || $waited_pid == -1) {
            return CGI::Parse::PSGI::parse_cgi_output(\$res);
        } else {
            Carp::croak("Error at run_on_shell CGI: $!");
        }
    };
    $self->_app($app);

}

sub call {
    my($self, $env) = @_;
    $self->_app->($env);
}

1;
