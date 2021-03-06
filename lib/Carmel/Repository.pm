package Carmel::Repository;
use strict;
use version ();
use DirHandle;
use Carmel::Artifact;
use CPAN::Meta::Requirements;
use File::Copy::Recursive ();

use subs 'path';
use Class::Tiny qw( path );

sub BUILD {
    my($self, $args) = @_;
    $self->path($args->{path});
    $self->load_artifacts;
}

sub path {
    my $self = shift;
    if (@_ ){
        $self->{path} = Path::Tiny->new($_[0]);
    } else {
        $self->{path};
    }
}

sub import_artifact {
    my($self, $dir) = @_;

    my $dest = $self->path->child($dir->basename);
    File::Copy::Recursive::dircopy($dir, $dest);

    $self->load($dest);
}

sub load_artifacts {
    my $self = shift;
    return unless $self->path->exists;

    for my $ent ($self->path->children) {
        if ($ent->is_dir && $ent->child("blib")->exists) {
            warn "-> Loading artifact from $ent\n" if $Carmel::DEBUG;
            $self->load($ent);
        }
    }
}

sub load {
    my($self, $dir) = @_;

    my $artifact = Carmel::Artifact->new($dir);
    while (my($package, $data) = each %{ $artifact->provides }) {
        $self->add($package, $artifact);
    }
}

sub add {
    my($self, $package, $artifact) = @_;

    my $version = $artifact->version_for($package);
    if (my $found = $self->lookup($package, $version)) {
        if ($self->_compare($version, $found->version_for($package)) > 0) {
            $self->{$package}{$version} = $artifact;
        }
    } else {
        $self->{$package}{$version} = $artifact;
    }
}

sub find {
    my($self, $package, $want_version) = @_;
    $self->_find($package, $want_version);
}

sub find_all {
    my($self, $package, $want_version) = @_;
    $self->_find($package, $want_version, 1);
}

sub _find {
    my($self, $package, $want_version, $all) = @_;

    # shortcut exact requirement
    if ($want_version =~ s/^==\s*//) {
        return $self->lookup($package, $want_version);
    }

    my $reqs = CPAN::Meta::Requirements->from_string_hash({ $package => $want_version });
    my @artifacts;

    for my $artifact ($self->list($package)) {
        if ($reqs->accepts_module($package, $artifact->version_for($package))) {
            if ($all) {
                push @artifacts, $artifact;
            } else {
                return $artifact;
            }
        }
    }

    return @artifacts if $all;
    return;
}

sub list {
    my($self, $package) = @_;
    map { $_->[1] }
      sort { $b->[0] <=> $a->[0] }
        map { [ version::->parse($_->version_for($package)), $_ ] }
          values %{$self->{$package}};
}

sub lookup {
    my($self, $package, $version) = @_;
    $version = version::->parse($version)->numify;
    $self->{$package}{$version}
}

sub _compare {
    my($self, $ver_a, $ver_b) = @_;

    my $ret = eval { version::->parse($ver_a) <=> version::->parse($ver_b) };
    if ($@) {
        # FIXME I'm sure there's a better/more correct way
        $ret = "$ver_a" cmp "$ver_b";
    }

    $ret;
}

1;
