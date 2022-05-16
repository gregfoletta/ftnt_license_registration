# Fortinet License Registration

The 'Fortinet License Registration' script allows you to easly bulk-register Fortinet licenses.

The licenses come in email as PDFs inside zip archives. This script takes one or more zip files and

1. Opens the zip file in memory
1. Reads the PDFs inside
1. Extracts the registration code
1. Registers the code into the FortiCare support portal

# Module Requirement

You'll need the following modules, preferably installed using the more modern [cpanminus](https://metacpan.org/pod/App::cpanminus):

```
sh$ cpanm Archive::Zip CAM::PDF Mojo::UserAgent
```

or the old CPAN client:

```
sh$ cpan Archive::Zip CAM::PDF Mojo::UserAgent
```

# How To Use It

```
# Extract the license zip files into a folder
sh$ ls
FAC-VM-BASE_51949408.zip  FG-VM02_51949411.zip

# Set the FORTICARE_API_PASSWORD environment variable with your
# API password
sh$ export FORTICARE_API_PASSWORD '<api password>'

# Run the script, specifying the API username followed by one or more zip files
sh$ ./ftnt_license_registration.pl --username 4599C7F8-1154-4EC1-86F7-33202067041C *.zip
```

So you can keep track of what was registered, the script adds "Auto Registered <date> <time>" into the description field of each device.

# API User

The script uses version 3 of the registration API. This uses OAuth tokens generated from IAM API username/passwords. You can create IAM users [here](https://support.fortinet.com/iam/#/api-user).

# TODO

- Automatic saving of generated license files (which are returned in the registration response).
