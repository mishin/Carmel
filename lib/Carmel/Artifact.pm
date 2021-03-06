package Carmel::Artifact;
use strict;
use CPAN::Meta;
use JSON ();
use Path::Tiny ();

sub new {
    my($class, $path) = @_;
    bless { path => Path::Tiny->new($path) }, $class;
}

sub path { $_[0]->{path} }

sub install {
    my $self = shift;
    $self->{install} ||= $self->_build_install;
}

sub _build_install {
    my $self = shift;

    my $file = $self->path->child("blib/meta/install.json");
    if ($file->exists) {
        return JSON::decode_json($file->slurp);
    }

    die "Could not read build artifact from ", $self->path;
}

sub provides {
    my $self = shift;
    $self->install->{provides};
}

sub package {
    my $self = shift;
    $self->install->{name};
}

sub version {
    my $self = shift;
    $self->version_for($self->package);
}

sub version_for {
    my($self, $package) = @_;
    $self->provides->{$package}{version} || '0';
}

sub distname {
    $_[0]->path->basename;
}

sub dist_version {
    $_[0]->install->{version};
}

sub blib {
    $_[0]->path->child("blib");
}

sub paths {
    my $self = shift;
    ($self->blib . "/script", $self->blib . "/bin");
}

sub libs {
    my $self = shift;
    ($self->blib . "/arch", $self->blib . "/lib");
}

sub meta {
    my $self = shift;
    CPAN::Meta->load_file($self->path->child("MYMETA.json"));
}

sub requirements {
    my $self = shift;
    $self->meta->effective_prereqs->merged_requirements(['runtime'], ['requires']);
}

1;
