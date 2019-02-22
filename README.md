# Codeowners Checker

This gem checks if the github codeowners are specified to all files changes
between two git revisions.

## Installation

    $ gem install codeowners-checker

## Usage


### Configure

    $  codeowners-checker config owner <@owner>

It will configure `@owner` as the default owner in the config file.

### Check file consistency

To check if your CODEOWNERS file is consistent with your current project you can run
this check.

    $  codeowners-checker check

It will suggest files that need to be added or removed from the CODEOWNERS file and provide
options to make the necessary changes.

Or via code:

```ruby
Codeowners::Checker.check! 'repo-dir', 'HEAD', 'branch-name'
```
When a new pattern is detected, it will suggest possible groups to which particular file belongs based on the main owner of the patterns in each group. After selecting a group the pattern is added to the group in alphabetical order. If no group is selected or found the pattern is added at the end of the CODEOWNERS file.

<p align="center">
  <img src="demos/missing_reference.svg">
</p>

When a pattern which doesn't match any files in the folder structure is detected, it will ask to fix the pattern and suggest a possible alternative. The user can choose to accept the suggestion, ignore, edit or delete the pattern.

<p align="center">
  <img src="demos/useless_pattern.svg">
</p>

After modifying the CODEOWNERS file the changes can be immediately committed.

### Filtering Changes in Pull Requests

If you have a Pull Request to review and you just want to check the changes that
are meaningful to you, you can also filter the changes.

To list all the changes grouped by an owner:

    $  codeowners-checker filter all

It will use the default owner from the configuration if you omit parameters:

    $  codeowners-checker filter

Or you can filter any owner as a parameter:

    $  codeowners-checker filter by <owner>

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/toptal/codeowners-checker. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Codeowners::Checker project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/toptal/codeowners-checker/blob/master/CODE_OF_CONDUCT.md).
