# RankmiExcelReview

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/rankmi_excel_review`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rankmi_excel_review', git: 'https://github.com/sheikhhamza012/rails_plugin_rankmi_excel_review.git'

```

And then execute:

    $ bundle

Or install it yourself as:

    $ git clone https://github.com/sheikhhamza012/rails_plugin_rankmi_excel_review.git
    $ cd rankmi_excel_review
    $ rake install

## Usage

- in config/routes add `mount RankmiExcelReview::Engine => "/rankmi_excel_review"`
- in the controller where the gem is to be used redirect the request using `redirect_to RankmiExcelReview::Engine.routes.url_helpers.review_index_path(:path_to_file=>@path_to_file, :redirect_to=>'path to go after wirting changes')`

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/rankmi_excel_review. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the RankmiExcelReview project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/rankmi_excel_review/blob/master/CODE_OF_CONDUCT.md).
