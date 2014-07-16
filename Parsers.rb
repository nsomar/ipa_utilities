class PemParser

  def initialize file
    @identity = PemParser.signingIdentitiesWithFile(file).first
  end

  def name
    @identity
  end

  def isAPNS
    @identity.include?("IOS Push Services")
  end

  def isProduction
    !@identity.include?("Development")
  end

  def enviroment
    isProduction ? "Production" : "Development (Sandbox)"
  end

  def bundleID
    /: (.*?)$/.match(@identity).captures.first
  end

  def self.signingIdentitiesWithBase64 base64
    string = "-----BEGIN CERTIFICATE-----\n"
    string += base64
    string += "-----END CERTIFICATE-----"

    File.write("cer.pem", string)

    pem = `openssl x509 -text -in cer.pem`

    system "rm -rf cer.pem"

    identity = /CN=(.*?),/.match(pem).captures
    identity
  end

  def self.signingIdentitiesWithFile file
    pem = `openssl x509 -text -in #{file}`
    identity = /CN=(.*?),/.match(pem).captures
    identity
  end
end

class ProvisionParser

  def initialize provisionPath
    @provisionPath = provisionPath
    parse
  end

  def parse
    # read mobileprovision and convert it to plist
    `security cms -D -i #{@provisionPath} > tmp.plist`

    # Get info from plist
    plist = CFPropertyList::List.new
    plist = CFPropertyList::List.new(:file => "tmp.plist")
    @data = CFPropertyList.native_types(plist.value)
  end

  def uuid
    @data["UUID"]
  end

  def signingIdentities

    arr = []

    certificates.each do |var|
      arr << PemParser.signingIdentitiesWithBase64(Base64.encode64(var))
    end

    arr
  end

  def certificates
    @data["DeveloperCertificates"]
  end

  def provisionedDevices
    @data["ProvisionedDevices"]
  end

  def isAPNSProduction
    @data["Entitlements"]["aps-environment"] == "production"
  end

  def isBuildRelease
    @data["Entitlements"]["get-task-allow"] == false
  end

  def isBuildDistro
    @data["ProvisionedDevices"].nil?
  end

  def isAPNSandAppSameEnviroment
    isBuildRelease == isAPNSProduction
  end

  def appBundleID
    var = @data["Entitlements"]["application-identifier"]
    var.slice!(@data["TeamIdentifier"].first + ".")
    var
  end

  def teamName
    @data["TeamName"]
  end

  def teamIdentifier
    @data["Entitlements"]["com.apple.developer.team-identifier"]
  end

  def apnsEnviroment
    isAPNSProduction ? "Production" : "Development (Sandbox)"
  end

  def buildEnviroment
    if isBuildRelease
      isBuildDistro ? "Distribution" : "AdHoc"
    else
      "Development"
    end
  end
end
