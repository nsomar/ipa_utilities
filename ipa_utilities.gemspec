$:.push File.expand_path("../lib", __FILE__)
require "ipa_utilities/version"

Gem::Specification.new do |s|
  s.name        = 'ipa_utilities'
  s.version     =  IpaVersion::VERSION
  s.date        = '2014-07-16'
  s.summary     = "Utilities and library to handle useful ipa operations"
  s.description = "ipa_utilities is a gem that helps in execute common ipa operations, such as verify, resign and others"
  s.authors     = ["Omar Abdelhafith"]
  s.email       = 'o.arrabi@me.com'
  s.files       = Dir["./**/*"].reject { |file| file =~ /\.\/(bin|log|pkg|script|spec|test|vendor)/ }
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "commander", "~> 4.1"
  s.add_dependency "json", '~> 1.8'
  s.add_dependency "CFPropertyList", '~> 2.2'
  s.add_dependency "colorize", '~> 0.7'

  s.homepage    = 'http://nsomar.com/ipa-utilities/'
  s.license     = 'MIT'
end
