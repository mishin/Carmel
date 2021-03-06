requires 'perl', '5.010001';

requires 'JSON';
requires 'Class::Tiny', '1.001';
requires 'CPAN::Meta::Requirements', '2.129';
requires 'CPAN::Meta::Prereqs', '2.132830';
requires 'Module::CoreList';
requires 'Module::CPANfile', '1.1000';
requires 'Module::Metadata', '1.000003';
requires 'Path::Tiny', '0.068';
requires 'File::Copy::Recursive';

requires 'App::cpanminus', '1.7030';

requires 'Carton', 'v1.0.13';

on test => sub {
    requires 'Test::More', '0.96';
};
