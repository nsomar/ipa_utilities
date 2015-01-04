require 'cfpropertylist'
require 'base64'
require 'colorize'
require 'ipa_utilities/parsers'
require 'tmpdir'

class IpaParser

  attr_reader :provision_profile

  def initialize(ipa_path)
    @full_path = ipa_path
    unzip_and_parse
  end

  def bundle_name
    File.basename(Dir["Payload/*.app"].last)
  end

  def signature_valid?
    system("codesign -v Payload/#{bundle_name} 2>&1")
    $?.exitstatus == 0
  end

  def zip(path)
    say "Zipping " + @full_path.green if $verbose
    system "zip -qr \"_new.ipa\" Payload"
    system "cp _new.ipa #{path}"
    say "Resigned ipa saved at " + path.green if $verbose
  end

  def delete_old_signature
    system "rm -rf Payload/*.app/_CodeSignature"
    puts "Deleting old code sign file" if $verbose
  end

  def cleanup
    system "rm -rf #{zip_out_path}"
    say "Deleting directory #{zip_out_path}" if $verbose
  end

  private

  def unzip_and_parse
    unzip
    parse
  end

  def unzip
    say "Unzipping '#{@full_path.green}' to '#{zip_out_path}'"  if $verbose
    system "unzip #{@full_path} -d #{zip_out_path} | logger -t ipa_utilities"

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
  end

  def zip_out_path
    @zip_out_path ||= Dir.mktmpdir
  end

  def base_path
    File.dirname(@full_path)
  end

  def ipa_name
    File.basename(@full_path)
  end

end
