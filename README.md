# Code::Ownership::Checker

This gem checks if the github codeowners are specified to all files changes
between two git revisions.

## Installation

    $ gem install code-ownership-checker

## Usage


    $  code-ownership-checker check .

Or via code:

```ruby
Code::Ownership::Checker.check! 'repo-dir', 'HEAD', 'branch-name'
```
### Configure

    $  code-ownership-checker config --team bootcamp

It will configure a `.default_team` file with your `@toptal/bootcamp` team.

### Check file consistency

To check if your codeowners is consistent with your current project you can run
this check.

    $  code-ownership-checker check

It will suggest files that need to be added or removed to the codeowners file. 

### Changes

If you have a Pull Request to review and you just want to check the changes that
make sense for your team, you can also filter the changes:

    $  code-ownership-checker changes all

It will use the default team file or you can pass the team as a parameter:

    $  code-ownership-checker changes by_team bootcamp

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/code-ownership-checker. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Code::Ownership::Checker project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/code-ownership-checker/blob/master/CODE_OF_CONDUCT.md).
