require 'cfpropertylist'
require 'base64'
require 'colorize'
require 'ipa_utilities/parsers'
require 'tmpdir'

class IpaParser

  attr_reader :provision_profile, :info_plist, :ipa_path

  def initialize(ipa_path)
    @ipa_path = ipa_path
    unzip_and_parse
  end

  def bundle_name
    File.basename(app_path)
  end

  def app_path
    Dir["Payload/*.app"].last
  end

  def info_plist_path
    app_path + "/Info.plist"
  end

  def zip(path)
    say "Zipping " + @ipa_path.green if $verbose
    system "zip -qr \"_new.ipa\" Payload"
    system "cp _new.ipa '#{path}'"
    say "Resigned ipa saved at " + path.green
  end

  def cleanup
    system "rm -rf '#{zip_out_path}'"
    say "Deleting directory #{zip_out_path}" if $verbose
  end

  private

  def generate_entitlements(new_bundle_id = nil)
    puts "\nGenerating Entitlements.plist"
    File.write("Entitlements.plist", provision_profile.signing_entitlement(new_bundle_id))
  end

  def unzip_and_parse
    unzip
    parse
  end

  def unzip
    say "Unzipping '#{@ipa_path.green}' to '#{zip_out_path}'"  if $verbose
    system "unzip '#{@ipa_path}' -d '#{zip_out_path}' | logger -t ipa_utilities"

    change_directory
  end

  def change_directory
    puts "Changing directory: " + "'#{zip_out_path}'\n".green if $verbose
    FileUtils.chdir(zip_out_path)
  end

  def parse
    provision_path = "Payload/#{bundle_name}/embedded.mobileprovision"
    say "Reading provision profile: "+ provision_path.green + "\n" if $verbose

    @provision_profile = ProvisionProfile.new(provision_path)
    @info_plist = InfoPlist.new(info_plist_path)
  end

  def zip_out_path
    @zip_out_path ||= Dir.mktmpdir
  end

  def base_path
    File.dirname(@ipa_path)
  end

  def ipa_name
    File.basename(@ipa_path)
  end

end

class InfoPlist

  def initialize(path)
    @path = path
    plist = CFPropertyList::List.new(:file => path)
    @data = CFPropertyList.native_types(plist.value)
  end

  def bundle_id
    @data["CFBundleIdentifier"]
  end

  def display_name
    @data["CFBundleDisplayName"]
  end

  def bundle_id=(bundle)
    @data["CFBundleIdentifier"] = bundle
  end

  def save
    plist = CFPropertyList::List.new(:file => @path)
    plist.value = CFPropertyList.guess(@data)
    plist.save(@path, CFPropertyList::List::FORMAT_BINARY)
  end

end