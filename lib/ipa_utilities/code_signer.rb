class CodeSigner

  def initialize(options)
    @ipa_path = check_file_exist(options[:ipa_path], "Cannot find file at '%s'",)
    @profile = check_file_exist(options[:profile], "Cannot find file at '%s'") if options[:profile]

    @output_path = options[:output_path] || "~/Desktop/resigned.ipa"

    @identity = check_non_nil(options[:identity], "Identity cannot be nil")
    @bundle_id = options[:bundle_id]
  end

  def self.signature_valid?(ipa)
    system("codesign -v #{ipa.app_path} 2>&1")
    $?.exitstatus == 0
  end

  def resign
    ipa = IpaParser.new(@ipa_path)
    @app_path = ipa.app_path

    delete_old_signature
    embed_profile
    update_bundle_id(ipa.info_plist)

    cmd = "codesign -s '#{@identity}' '#{ipa.app_path}' -f"
    puts cmd if $verbose
    system(cmd)
    ipa.zip(@output_path)
    ipa.cleanup
  end

  def update_bundle_id(info_plist)
    return unless @bundle_id

    puts "Applying new bundle id '#{@bundle_id.green}'"
    info_plist.bundle_id = @bundle_id
    info_plist.save
  end

  private

  def embed_profile
    return unless @profile

    puts "Copying the new provision profile to app bundle"
    system "cp \"#{@profile}\" \"#{@app_path}/embedded.mobileprovision\""
  end

  def delete_old_signature
    system "rm -rf #{@app_path}/_CodeSignature"
    puts "Deleting old code sign file" if $verbose
  end

  def check_non_nil(string, error)
    raise error unless string
    string
  end

  def check_file_exist(file, error)
    file_path = file || ""
    raise error%file_path unless File.exist?(file_path)
    file
  end

end