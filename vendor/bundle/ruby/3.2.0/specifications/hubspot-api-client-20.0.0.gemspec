# -*- encoding: utf-8 -*-
# stub: hubspot-api-client 20.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "hubspot-api-client".freeze
  s.version = "20.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["HubSpot".freeze]
  s.date = "2025-05-08"
  s.description = "HubSpot Ruby API client".freeze
  s.email = ["".freeze]
  s.homepage = "https://github.com/HubSpot/hubspot-api-ruby".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "HubSpot Ruby API Gem".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<typhoeus>.freeze, ["~> 1.4.0"])
  s.add_runtime_dependency(%q<json>.freeze, ["~> 2.1", ">= 2.1.0"])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.6", ">= 3.6.0"])
  s.add_development_dependency(%q<vcr>.freeze, ["~> 3.0", ">= 3.0.1"])
  s.add_development_dependency(%q<webmock>.freeze, ["~> 3.14"])
  s.add_development_dependency(%q<autotest>.freeze, ["~> 4.4", ">= 4.4.6"])
  s.add_development_dependency(%q<autotest-rails-pure>.freeze, ["~> 4.1", ">= 4.1.2"])
  s.add_development_dependency(%q<autotest-growl>.freeze, ["~> 0.2", ">= 0.2.16"])
  s.add_development_dependency(%q<rake-release>.freeze, ["~> 1.3"])
  s.add_development_dependency(%q<pry>.freeze, ["~> 0.14"])
end
