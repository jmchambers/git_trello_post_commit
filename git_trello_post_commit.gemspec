# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'git_trello_post_commit/version'

Gem::Specification.new do |spec|
  spec.name          = "git_trello_post_commit"
  spec.version       = GitTrelloPostCommit::VERSION
  spec.authors       = ["jmchambers"]
  spec.email         = ["j.chambers@gmx.net"]
  spec.description   = %q{This gem can be used in a post-commit hook in any Git repository to comment on and move Trello cards in a specified board. What will be done is based on a Git commit message:for example, if a message contains 'Card #20', post-commit will add the rest of comment message as a comment on card #20.}
  spec.summary       = %q{Update Trello cards with git commit messages.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"

  spec.add_runtime_dependency 'json'
  spec.add_runtime_dependency "git", "~> 1.2"
end
