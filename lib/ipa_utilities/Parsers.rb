class SigningIdentity

  def initialize(name)
    @identity = name
  end

  def self.from_base64(base64)
    string = "-----BEGIN CERTIFICATE-----\n"
    string += base64
    string += "-----END CERTIFICATE-----"

    File.write("cer.pem", string)

    pem = `openssl x509 -text -in cer.pem`

    system "rm -rf cer.pem"

    SigningIdentity.new(pem[/CN=(.*?),/, 1])
  end

  def self.from_file(file)
    pem = `openssl x509 -text -in #{file}`
    SigningIdentity.new(pem[/CN=(.*?),/, 1])
  end

  def name
    @identity
  end

  def apns?
    @identity.include?("IOS Push Services")
  end

  def production?
    !@identity[/[Development|Developer]/]
  end

  def environment
    if apns?
      production? ? "Production" : "Development (Sandbox)"
    else
      production? ? "Production" : "Development"
    end
  end

  def display_name
    @identity[/: (.*?)$/, 1]
  end

end

class ProvisionProfile

  attr_reader :provision_path

  def initialize(provision_path)
    @provision_path = provision_path
    @data = CFPropertyList.native_types(read_profile)
  end

  def uuid
    @data["UUID"]
  end

  def signing_identities
    certificates.map { |identity| SigningIdentity.from_base64(Base64.encode64(identity)) }
  end

  def certificates
    @data["DeveloperCertificates"]
  end

  def provisioned_devices
    @data["ProvisionedDevices"]
  end

  def production_apns?
    @data["Entitlements"]["aps-environment"] == "production"
  end

  def release_build?
    !@data["Entitlements"]["get-task-allow"]
  end

  def task_allow?
    @data["Entitlements"]["get-task-allow"]
  end

  def app_store_build?
    provisioned_devices.nil?
  end

  def apns_and_app_same_environment?
    release_build? == production_apns?
  end

  def bundle_id
    identifier = @data["Entitlements"]["application-identifier"]
    identifier[/#{team_identifier}\.(.*)/, 1]
  end

  def team_name
    @data["TeamName"]
  end

  def display_name
    @data["Name"]
  end

  def team_identifier
    @data["Entitlements"]["com.apple.developer.team-identifier"]
  end

  def apns_environment
    production_apns? ? "Production" : "Development (Sandbox)"
  end

  def apns_gateway
    production_apns? ? "gateway.push.apple.com:2195" : "gateway.sandbox.push.apple.com:2195"
  end

  def build_environment
    if release_build?
      app_store_build? ? "Distribution" : "AdHoc"
    else
      "Development"
    end
  end

  def signing_entitlement(new_bundle_id)
    bundle_to_write = "#{team_identifier}.#{new_bundle_id || bundle_id}"
    puts "Bundle identifier: #{bundle_to_write}"

    file_path = File.expand_path("#{__FILE__}/../../resources/Original.Entitlements.plist")
    file = File.read(file_path)
    file.sub!("BUNDLE_ID", bundle_to_write)
    file.sub!("GET_TASK_ALLOW", release_build? ? "false" : "true")
  end

  private

  def read_profile
    cmd = "security cms -D -i '#{@provision_path}' > tmp.plist"
    say cmd if $verbose
    system(cmd)

    # Get info from plist
    plist = CFPropertyList::List.new(:file => "tmp.plist")
    system("rm tmp.plist")

    plist.value
  end
end
