> [!WARNING]  
> This branch (roll\_log\_and\_character\_db) uses a VERY over-engineered login system that uses pure Javascript
> public key encryption and signatures (via JSCrypt) to encrypt login data and validate session data. It serves
> as a testbed for some ideas I had, and while it DOES work, don't use it as-is. There's a reason we SSL, so just
> use that and rip out all the insanity. The existing HMAC cookie signature is more than adequate to validate
> players aren't cheating rolls, just integrate the sess cookie into the hash calculation and you're set.

# MEGS Roller
This standalone Ruby web application aids in handling dice rolls for tabletop role-playing games using MEGS (Mayfair's Exponential Game System). This includes games like DC Heroes and Blood of Heroes, but not games like Underground which use a differently scaled variant of MEGS. The Action and Result tables used by this program were taken from Blood of Heroes, with some slight typo and scaling fixes made to the Result table in the higher AP ranges.


You can try it out here: [https://megs-roller-b10c3de2770b.herokuapp.com](https://megs-roller-b10c3de2770b.herokuapp.com)

# Usage
MEGS Roller is a standard Rack application, with no external gem dependencies beyond `rack` and a Rack-enabled web server (such as Puma, Thin, Unicorn, Webrick, etc).  The inital development work was done with Ruby 2.7, but works fine on versions up to Ruby 3.3.7. It hasn't been tested with later Ruby versions, but it should work.

## Configuration
The `config.ru` file provided is intended to be used with the `rackup` command and a `puma.rb` file is provided in the `config/` directory configured for Heroku, but any number of alternative methods could be used to start or deploy the server. An example file, `config/config.yaml.example` is provided, documenting the various options. When deploying to Heroku, the `config.yaml` file isn't used and instead a few config vars need to be created:

* MEGS\_SECRET
* MEGS\_DATABASE
* MEGS\_MEMCACHE

These are equivalent to the options given in the example config file.

## Using MEGS Roller
Actual usage of the MEGS Roller web application should be fairly self-explanatory, but some features bear explanation. The **Clear** button is used to erase the cookie data and clear the input fields to begin a new Dice Action. Rolling a 2 will result in an automatic failure, and rolling doubles will enable the **Reroll** button. The **Submit** button is used to complete the Action Table phase of the Dice Action. This disables the AV, OV, and OV CS fields, and enables the EV, RV, and RV CS fields, along with the **Resolve** button used to complete the Dice Action and calculate RAPs. The OV CS and RV CS fields are specificially used to apply situational Column Shift bonues and penalties (negative numbers) to the OV and RV respectively. OV Column Shifts earned by high rolls on the Action Table are calculated automatically. 

## Modifying the Result Table
The modifications made to the Result Table can be changed by editing the RESULT\_TABLE constant in `lib/megs/tables.rb`.
