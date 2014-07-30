# Kalindar

Kalindar lets you view ics files via a webbrowser.

It employs the ri_cal, sinatra, i18n ruby gems, the rightjs JavaScript framework and the Pure CSS framework.

## Installation

Add this line to your application's Gemfile:

    gem 'kalindar'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install kalindar

## Usage

bundle exec rackup

## Naming

Kali is an Indian goddess of destruction, change and ... time .

## Caveats

Be careful.  Kalindar might destroy, change or delete your ics file(s)!

Kalindar does not care about timezones!

Kalindar gets confused by re-occuring events!

### Configuration

Configuration is done in config.json .  There one or many calendar (ics) files and the locale can be set.

## Contributing

0. Get in touch with me.
1. Fork it ( https://github.com/[my-github-username]/kalindar/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
