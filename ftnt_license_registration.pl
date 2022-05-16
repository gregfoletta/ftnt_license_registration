#!/usr/bin/env perl

use strict;
use warnings;
use 5.010;
use Pod::Usage;
use Getopt::Long;
use Carp;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use CAM::PDF;
use Mojo::UserAgent;


my %args;
GetOptions(
    \%args,
    'username=s',
    'password=s',
    'client_id=s',
    'help' => sub { pod2usage(1) }
) or pod2usage(2);

=pod

=head1 NAME

=head1 SYNOPSIS

=cut


croak "No --username specified" unless $args{username};

my %auth_info = (
    username => $args{username},
    password => $ENV{FORTICARE_API_PASSWORD} // $args{password},
    client_id => $args{client_id} // 'assetmanagement'
);

my @codes = extract_reg_codes(@ARGV);

my $access_token = forticare_auth( %auth_info );
forticare_register($access_token, @codes);

sub extract_reg_codes {
    my (@zip_files) = @_;
    my @codes;

    my $zip  = Archive::Zip->new();

    for my $zipfile (@zip_files) {
        say STDERR "- Reading $zipfile";
        unless ($zip->read($zipfile) == AZ_OK) { die "Could not open zipfile '$zipfile'"; }

        for my $itf_pdf ($zip->members()) {
            my $pdf_contents = $itf_pdf->contents();
            my $pdf = CAM::PDF->new($pdf_contents);
            
            my ($registration_code) = $pdf->getPageText(1) =~ m{Registration Code\s+:\s+((\w+-?){5})};

            if (!$registration_code) {
                carp "Could not extract code from '$zipfile'";
                next;
            }

            say STDERR "- Extracted code $registration_code'";

            push @codes, $registration_code;
        }
    }

    return @codes;
}


sub forticare_auth {
    my (%credentials) = @_;
    
    my $ua = Mojo::UserAgent->new;
    my %auth_info = (
        uri => 'https://customerapiauth.fortinet.com/api/v1/oauth/token/',
        json => {
            username => $credentials{username},
            password => $credentials{password},
            client_id => $credentials{client_id},
            grant_type => 'password'
        }
    );

    my $res = $ua->post( $auth_info{uri} => json => $auth_info{json} )->result->json;

    if (defined $res->{error}) {
        croak "Could not authenticate: ". $res->{error_description};
    }

    return $res->{access_token};
}

sub forticare_licenses {
    my ($access_token, $filter) = @_;

    # Default filter
    $filter //= 'FGVM';

    my $ua = Mojo::UserAgent->new;

    return $ua->post(
        'https://support.fortinet.com/ES/api/registration/v3/products/list' =>
        { Authorization => "Bearer $access_token" } =>
        json => { serialNumber => $filter }
    )->result->json;
}


sub forticare_register {
    my ($access_token, @reg_codes) = @_;

    my $ua = Mojo::UserAgent->new;

    CODE:
    for my $code (@reg_codes) {
        say STDERR "Registering code '$code'";
        my $res = $ua->post(
            'https://support.fortinet.com/ES/api/registration/v3/licenses/register' =>
            { Authorization => "Bearer $access_token" } =>
            json => {
                licenseRegistrationCode => $code,
                description => "Auto Registered ".localtime()
            }
        )->result;

        if ($res->is_error) {
            say STDERR "Error: ".$res->json->{message};
            next CODE;
        }

        my $license = $res->json->{assetDetails}{license};

        say STDERR "- Registered $license->{licenseSKU} ($license->{licenseSKU})";
    }
}

            
