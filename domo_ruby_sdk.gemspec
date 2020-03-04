require_relative 'lib/domo_ruby_sdk/version'

Gem::Specification.new do |spec|
  spec.name          = "domo_ruby_sdk"
  spec.version       = DomoRubySdk::VERSION
  spec.authors       = ["Ryan Grow"]
  spec.email         = ["ryan.grow@bluemoondigital.co"]

  spec.summary       = "A ruby interface for invoking the Domo Data API endpoints."
  spec.homepage      = "https://github.com/visual4site/domo_ruby_sdk"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/visual4site/domo_ruby_sdk"
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'rest-client', '~> 2.1.0'
  spec.add_development_dependency 'vcr', '~> 5.1.0'
end
