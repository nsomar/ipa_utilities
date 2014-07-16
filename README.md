# ipa_utilities

Simple ruby gem to execute common ipa utilities, such as verify integrity, convert certificate formats, re-signs an ipa using a new provision profile and more.

## Installation

    $ gem install ipa_utilities
    
## Command Line Tool
`ipa_utilities` is available as a command line tool. the main functionalities are described bellow:

For help use

	ipa_utilities -h
	# works for any of the verbs bellow
	ipa_utilities verify -h
	
#### verify
ipa_utilities verify verb is used to verify the integrity and signature of an ipa file

	ipa_utilities verify ipa_path	
	ipa_utilities verify ipa_path -c apns_certificate_path
	ipa_utilities verify ipa_path -c apns_certificate_path -d device_UDID
	
By using the `-c apns_certificate_path` you can cross reference the ipa APNS environment with the APNS_Certificate passed

By passing a device UDID using `-d UDID` option, you can verify if the UDID is included in the embedded provision profile

#### certificate

	ipa_utilities certificate ipa_path
This command will return the name of the APNS certificate that will be used with for the current ipa, it will also search the keychain for the existence of the certificate returned

#### convert

	ipa_utilities convert p12_path
Convert verb helps in converting a P12 formatted identity file to a PEM file to be used with your APNS server implementation

Use `-o out_path` to select the save location

#### resign
	
	ipa_utilities resign ipa_path -p new_provision_path
Re-Signs the ipa using the new `new_provision_path`

Use `-o out_path` to select the save location

## Ruby Classes

#### `IpaUtilities`
`IpaUtilities` contains high level ipa bound operations:

	ipa = IpaUtilities.new ipa_path

- `ipa.unzip` to unzip the ipa
- `ipa.zip path` zip the ipa to a specific location
- `ipa.verifyCodeSign` verifies the code sign for the unzipped ipa
- `ipa.parse` create and return a `ProvisionParser` object that is used to query the embedded provision profile

#### `ProvisionParser`
`ProvisionParser` used to query a provision profile

	parser = ProvisionParser.new provision_profile_path

- `parser.uuid` returns the UUID of the provision profile
- `parser.signingIdentities` returns the signing identities from the certificate object within the the provision profile
- `parser.certificates` returns the array of the certificates
- `parser.provisionedDevices` returns array of devices included in the provision profile
- `parser.isAPNSProduction` reads the entitlements and checks for APNS environment
- `parser.isBuildRelease`, `isBuildStoreDistribution` reads `get-task-allow` fro the - entitlements
- `parser.appBundleID` returns the 
- `parser.teamName` returns the team name
- `parser.teamIdentifier` returns the team identifier

#### `PemParser`
`PemParser` reads a PEM formatted certificate files
	
	pem = PemParser.new pem_path
	
- `name` the common name of the certificate
- `isAPNS` checks if the pem is APNS
- `isProduction` check if the certificate is for production
- `bundleID` return the bundle id from the certificate

## Contact

Omar Abdelhafith

- http://nsomar.com
- http://twitter.com/ifnottrue
- o.arrabi@me.com

## License

ipa_utilities is available under the MIT license.

## Future
Since xcode keeps changing how it signs and package the ipa files i will keep that up-todate for this library.

Other future improvements:

- Adding RSpec tests
- Better document the libraries
- Refactor the ipa_utilities binary

## Contribute
Please!

Feel free to fork me on [github](https://github.com/oarrabi/ipa_utilities)
