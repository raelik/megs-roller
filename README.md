# MEGS Roller
This standalone Ruby web application aids in handling dice rolls for tabletop role-playing games using MEGS (Mayfair's Exponential Game System). This includes games like DC Heroes and Blood of Heroes, but not games like Underground which use a differently scaled variant of MEGS. The Action and Result tables used by this program were taken from Blood of Heroes, with some slight typo and scaling fixes made to the Result table in the higher AP ranges.


You can try it out here: [https://megs-roller-b10c3de2770b.herokuapp.com](https://megs-roller-b10c3de2770b.herokuapp.com)

# Usage
MEGS Roller is a standard Rack application, with no external gem dependencies beyond `rack` and a Rack-enabled web server (such as Puma, Thin, Unicorn, Webrick, etc).  The inital development work was done with Ruby 2.7, but works fine on versions up to Ruby 3.3.7. It hasn't been tested with later Ruby versions, but it should work.

## Configuration
The `config.ru` file provided is intended to be used with the `rackup` command and a `puma.rb` file is provided in the `config/` directory configured for Heroku, but any number of alternative methods could be used to start or deploy the server (`bundle exec puma -C config/puma.rb` for instance, if using `bundler` with the included `Gemfile`). An example config file, `config/config.yaml.example` is provided, documenting the various options. When deploying to Heroku, the `config.yaml` file isn't used and instead a few config vars need to be created that replace the config file settings:

* `MEGS_SECRET` (replaces `secret`)
* `MEGS_DATABASE` (replaces `database`)
* `MEGS_MEMCACHE` (replaces `memcache_server`)
* `MEGS_WEBHOOK` (replaces `webhook_url`)

The only required setting is `MEGS_SECRET`/`secret`. To enable the login feature, which in turn allows for roll logging and pushing rolls to a Discord webhook, both the `MEGS_DATABASE`/`database` and `MEGS_MEMCACHE`/`memcache_server` must be set. `MEGS_WEBHOOK`/`webhook_url` is optional, but also requires `MEGS_DATABASE`/`database`, since it is an extension of the logging feature, which requires users and characters to be defined. The default example SQLite database configured in the example config.yaml is NOT recommended for use on Heroku, for the reasons outline here: [SQLite on Heroku](https://devcenter.heroku.com/articles/sqlite3)

**Additionally**, there is a `MEGS_LOGIN`/`login` boolean setting that can be used to explicitly disable the login system. It is enabled by default (`MEGS_DATABASE`/`database` and `MEGS_MEMCACHE`/`memcache_server` must still be set). This is for temporarily disabling logins for maintenance purposes.

__**DO NOT**__ enable the login feature unless you are running your application over HTTPS, or on a secure private network. The usernames and passwords are sent in the clear.

## Using MEGS Roller
Actual usage of the MEGS Roller web application should be fairly self-explanatory, but some features and functionality bear explanation:

* The **Clear** button is used to erase the cookie data and clear the input fields to begin a new Dice Action.
* Rolling a 2 will result in an automatic failure, and rolling doubles will enable the **Reroll** button.
* The **Submit** button (which only appears when **Reroll** is available) is used to complete the Action Table phase of the Dice Action instead of re-rolling. A non-double result will be automatically submitted, to immediately check for success or failure.
* On a success, the *AV*, *OV*, and *OV CS* fields are disabled, enabling the *EV*, *RV*, and *RV CS* fields, along with the **Resolve** button used to complete the Dice Action and calculate RAPs.
* The *OV CS* and *RV CS* fields are specificially used to apply situational Column Shift bonues and penalties (negative numbers) to the OV and RV respectively. OV Column Shifts earned by high rolls on the Action Table are calculated automatically. 

If the login feature is enabled, there is a Rakefile that contains commands to create, update and delete users and characters (these are fairly self-explanatory. Run `bundle exec rake -T` to list the various tasks). Upon logging in, there is a drop-down containing the user's name and their list of characters, which they can choose to roll dice as. This determines what ends up in the log, the last 50 rolls of which are displayed at the bottom of the page. Clicking on a particular roll will open a dialog with more a more detailed and easily-readable breakdown of that roll.

Admin users are GMs, and are able to select ANY character to roll as, though the log still reveals that the admin user made the roll. Additionally, admins have a button (a blue circle with a white check mark) to disable the logging feature so they can remain logged in but make rolls in secret. All users have a Discord button to disable the webhook, in case they want to make rolls and not spam the Discord channel. The results are still logged, unless they are also an admin and have fully disabled logging as well. Disabling logging also disables the webhook implcitly (as it is part of the server's logging functionality), though the Discord option will remain on unless explictly disabled.

## Modifying the Result Table
The modifications made to the Result Table can be changed by editing the `RESULT_TABLE` constant in `lib/megs/tables.rb`.

## Using a different session storage solution
It is possible to replace Memcached and the `dalli` gem with a different solution, such as Redis and the `redis-rack` gem. There are a couple caveats to doing this, and specific steps that need to be taken.

First, the Rack session implementation MUST be derived from the Rack::Session::Abstract::Persisted class provided by the `rack-session` gem. This is not a particularly restrictive caveat, as most implementations use that as a base class.

Second, when initializing the session middleware in `config.ru`, you MUST set the `key` option to `sess`, `httponly` to `false`, and `skip` to `true`. The MEGS Roller code relies on these settings, and is the primary reason that Rack::Session::Abstract::Persisted-based gems are required.

To switch your session storage solution, do the following:

1. Edit the `Gemfile` and remove the `dalli` gem, replacing it with your desired replacement.
2. Run `bundle install` to install your new gem and update `Gemfile.lock`
3. Edit `config.ru`, and replace line 4 (`require 'rack/session/dalli'`) with the appropriate require line for your gem.
4. Also, replace the lines starting with `memcache_server = ...` and ending with `skip: true) if ...` with the middleware initialization for your gem. This should be lines 16 to 23 if you've not made other additions or changes to `config.ru`. Make sure to abide the second caveat above. The reference to `EVN['MEGS_MEMCACHE']`, `config['memcache_server']`, and `memcache_server` should probably be replaced with alternative appropriate to your gem. The middleware should not be initialized if the database config and session storage config are unavailable.
5. Edit `lib/megs/handlers/login.rb` and change the reference to `config['memcache_server']` on line 21 (in the definition for the `enabled` method) to use whatever you changed it to in `config.ru`.

Additional steps may be required for your particular choice of gem in order to prepare the storage service it uses (such as creating a default key, namespace, user, etc), but these should be the only code changes required.
