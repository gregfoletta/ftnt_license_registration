#!/usr/bin/env perl

use strict;
use warnings;
use 5.010;
use Pod::Usage;
use Getopt::Long;
use Term::ANSIColor;
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
    'no-licenses=s',
    'help' => sub { pod2usage(1) }
) or pod2usage(2);

=pod

=head1 NAME

ftnt_license_registration - extract license information from Fortinet zip files and register with Fortinet support.

=head1 SYNOPSIS

./ftnt_license_registration --username <IAM API User> [--password <IAM API Password> --no-licenses]

Script will prefer FORTICARE_API_PASSWORD environment variable over command line argument.

=cut


croak "No --username specified" unless $args{username};

# Extract the registration codes from zip files
my @codes = extract_reg_codes(@ARGV);

# Get our API access token
my $access_token = forticare_auth(
    username => $args{username},
    password => $ENV{FORTICARE_API_PASSWORD} // $args{password},
    client_id => $args{client_id} // 'assetmanagement'
);

# Register the devices
my @licenses = forticare_register($access_token, @codes);


# Write out the license files
write_license_files(@licenses) unless $args{'no-licenses'};


### Functions ###

sub log_output {
    print STDERR colored('- ', 'bold green');
    say STDERR join ' ', @_;
}

sub log_error {
    say STDERR colored('- '.join(' ', @_), 'bold red');
}

sub extract_reg_codes {
    my (@zip_files) = @_;
    my @codes;

    my $zip  = Archive::Zip->new();

    # Read in each zipfile
    ZIP:
    for my $zip_file (@zip_files) {
        log_output("Reading $zip_file");

        if ($zip->read($zip_file) != AZ_OK) { 
            carp "Could not open zipfile '$zip_file'";
            next ZIP;
        }
    }
   
    PDF:
    for my $pdf_name ($zip->memberNames()) {
        # Extract PDF contents
        my $pdf = CAM::PDF->new( $zip->memberNamed( $pdf_name )->contents() );
       
        # Regex out the registration code
        my ($registration_code) = $pdf->getPageText(1) =~ m{Registration Code\s+:\s+((\w{5}-){4}(\w{6}))};

        if (!$registration_code) {
            carp "Error extracting code from '$pdf_name'";
            next PDF;
        }

        log_output("Extracted code $registration_code");

        push @codes, $registration_code;
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

sub forticare_register {
    my ($access_token, @reg_codes) = @_;

    my @licenses;

    my $ua = Mojo::UserAgent->new;

    CODE:
    for my $code (@reg_codes) {
        log_output("Registering code $code");
        my $res = $ua->post(
            'https://support.fortinet.com/ES/api/registration/v3/licenses/register' =>
            { Authorization => "Bearer $access_token" } =>
            json => {
                licenseRegistrationCode => $code,
                description => "Auto Registered ".localtime()
            }
        )->result;

        if ($res->is_error) {
            log_error("Error: ".$res->json->{message});
            next CODE;
        }

        my $license = $res->json->{assetDetails}{license};

        log_output("Registered $license->{licenseSKU} ($license->{serialNumber})");

        # Push the license and serial on to the stack
        push @licenses, $license;
    }

    return @licenses;
}

sub write_license_files {
    my (@licenses) = @_;

    for my $license (@licenses) {
        open(my $fh, '>:encoding(UTF-8)', $license->{serialNumber}."lic");
        print $fh $license->{licenseFile};
        close $fh;
    }
} 
