require 'cfpropertylist'
require 'pathname'
require 'base64'
require 'colorize'
require './Parsers'

class IpaUtilities
  attr :provisionParser

  def initialize ipaPath
    pn = Pathname.new(ipaPath)
    @ipaPath = pn.dirname
    @ipaName = pn.basename
    @fullPath = ipaPath
  end

  def unzip
    say "Unzipping " + @fullPath.green if $verbose
    system "unzip #{@fullPath} > log.txt"
  end

  def zip path
    say "Zipping " + @fullPath.green if $verbose
    system "zip -qr \"_new.ipa\" Payload"
    system "cp _new.ipa #{path}"
    say "Resigned ipa saved at " + path.green if $verbose
  end

  def bundleName
    Dir.entries("Payload").last
  end

  def verifyCodeSign
    result = `codesign -v Payload/#{bundleName} 2>&1`
    result.empty? ? "Signature Valid\n".green : "Signature Not Valid\n".red + result.red if $verbose
  end

  def parse
    @provisionPath = "Payload/#{bundleName}/embedded.mobileprovision"
    @provisionParser = ProvisionParser.new @provisionPath
  end

  def unzipAndParse
    unzip
    puts "App bundle name is " + bundleName.green if $verbose

    parse
    say "Reading provision profile at "+ @provisionPath.green if $verbose
    puts if $verbose
  end

  def deleteOldSignature
    system "rm -rf Payload/*.app/_CodeSignature"
    puts "Deleting old code sign file" if $verbose
  end

  def cleanUp
    system "rm -rf Payload"
    system "rm -rf tmp.plist"
    system "rm -rf Entitlements.plist"
    system "rm -rf _new.ipa"
  end
end
