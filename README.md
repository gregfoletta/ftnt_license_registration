# NAME

ftnt\_license\_registration - extract, register, and download Fortinet licenses.

# VERSION

version .3

# SYNOPSIS

    # Register FTNT licenses straight from zip files.
    # FortiCloud credentials stored in ~/.ftnt/ftnt_cloud_api
    # Licenses will be downloaded into the working directory
    ./ftnt_license_registration ~/Documents/licenses/*.zip

    # Specify the directory to store licenses
    ./ftnt_license_registration --license-dir ~/Documents/licenses

    # Don't download licenses, just regisuter
    ./ftnt_license_registration --no-licenses

    # API user/pass can be specified as ENV vars
    export FORTICLOUD_API_USERNAME='<user>'
    export FORTICLOUD_API_PASSWORD='<pass>'
    ./ftnt_license_registration

    # Or on the command line
    ./ftnt_license_registration --username '<user>' --pasword '<pass>'

# OPTIONS

- -u|--username _user_ - the FortiCloud API username
- -p|--password _pass_ - the FortiCloud API password
- -l|--license-dir _path_ - the path to save registered licenses
- -n|--no-licenses - don't download licenses
- -n|--ipv4-addresses - assign an IPv4 address when registering (see section below for more details)
- -h|--help - print usage information

# DESCRIPTION

The 'Fortinet License Registration' script allows you to easly bulk-register and download Fortinet licenses.

The licenses come in email as PDFs inside zip archives. This script takes one or more zip files and

- Opens the zip file in memory
- Reads the PDFs inside
- Extracts the registration code
- Registers the code into the FortiCare support portal

# REQUIREMENTS

You'll need the following modules, preferably installed using the more modern [cpanminus](https://metacpan.org/pod/App::cpanminus):

    sh$ cpanm Archive::Zip CAM::PDF Mojo::UserAgent

or the old CPAN client:

    sh$ cpan Archive::Zip CAM::PDF Mojo::UserAgent

# AUTHENTICATION

The script uses version 3 of the registration API. This uses OAuth tokens generated from IAM API username/passwords. You can create IAM users [here](https://support.fortinet.com/iam/#/api-user).

Once you have your credentials, the script will search for them in three places:

- In ~/.ftnt/ftnt\_cloud\_api formatted as &lt;username>:&lt;password>
    - Lines beginning with '#' are skipped
- In the environment variabes `FORTICLOUD_API_USER` and `FORTICLOUD_API_PASSWORD`
- In the command line arguments `-u|--username` and `-p|--password`.

If the credentials are available in multiple places, local dotfile beats environment variable beats commandline.

Note that the password appears to always have an exclaimation mark, so be sure to enclose in single quotes if you're using the environment variable or command line methods.

# IPv4 ADDRESSES

The `--ipv4-addresses` argument will eventually take two arguments, although only one is implemented at this stage:

- It takes a single IPv4 address, and will apply this address to all registrations.
- It will take a file with an IP address on each line, and apply each IP to eace (not currently implemented).

    Some devices do not take an IP address (for example, FortiGates). This script will not discriminate, and will still try to apply the IP address. Recommendation it that if you're using this command, separate the licenses that require an IP into a different folder. You can this run this script across that folder with this --ipv4-addresses argument.

# LICENSE DOWNLOAD

The registration API generally returns the license keys for the codes you register with a couple of caveats:

- Some aren't returned, for example FortiManager licneses
- Some devices require an IP specification, which will not have been done rendering the license useless.

You will get warnings in the console for registration codes that do not return a license.

# POD ERRORS

Hey! **The above document had some coding errors, which are explained below:**

- Around line 146:

    You forgot a '=back' before '=head1'
