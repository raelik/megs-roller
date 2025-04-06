$LOAD_PATH.unshift File.expand_path('lib', File.dirname(__FILE__))

require 'rom'
require 'rom-sql'
require 'rom/sql/rake_task'
require 'yaml'
require 'megs/db'
require 'argon2id'
require 'highline/import'

config = YAML.load_file('config/config.yaml')

namespace :db do
  task :setup do
    ROM::SQL::RakeSupport.env = ROM.container(:sql, config['database'])
  end
end

namespace :megs do
  task :db_connect do |task|
    MEGS::DB.configure(config['database'])
    MEGS::DB.connect
  end

  task :list_users => :db_connect do
    puts "      ID | Username                       | Player                          | Admin?"
    puts "---------+--------------------------------+---------------------------------+--------"
    MEGS::DB[:users].each do |user|
      puts " %7d | %-30s | %-31s | %s" % [user[:id], user[:username], user[:name], user[:admin] ? 'Yes' : 'No']
    end
  end

  task :list_characters => :db_connect do
    puts "      ID | Character                                                        | User ID"
    puts "---------+------------------------------------------------------------------+---------"
    MEGS::DB[:characters].each do |char|
      puts " %7d | %-64s | %d" % [char[:id], char[:name], char[:user_id]]
    end
  end

  task :create_user, [:username] => :db_connect do |_t, args|
    raise ArgumentError.new("Must specify a username when creating a user. i.e. rake megs:create_user[alice]") unless args.username
    raise ArgumentError.new("Username is too long. Must be 255 characters or less.") if args.username.size > 255

    while (player_name = ask("Please enter a player name: ") { |q| q.limit = 255 }).nil?
      puts "Player name must not be blank."
    end

    password = []
    while password.uniq.size != 1 || password.uniq.first.empty?
      password << ask("Please enter a password for user #{args.username}: ") { |q| q.echo = '*' }
      password << ask("Re-enter password to verify: ") { |q| q.echo = '*' }
      puts "Passwords did not match, please try again." unless password.uniq.size == 1
      puts "Password must not be blank." if password.uniq.first.empty?
    end

    admin = agree("Is #{args.username} an admin [y/N]? ") { |q| q.default = 'n'; q.default_hint_show = false }

    MEGS::DB[:users].changeset(:create, { username: args.username, name: player_name, password: password.uniq.first, admin: admin }).commit
  rescue ArgumentError => e
    puts "ERROR: #{e.message}"
  end

  task :update_user, [:id] => :db_connect do |_t, args|
    raise ArgumentError.new("Must specify a user ID when updating a user. i.e. rake megs:update_user[3]") unless args.id
    user = MEGS::DB[:users].by_pk(args.id.to_i).one
    raise ArgumentError.new("User with ID of #{args.id} not found.") unless user

    changes = {}
    if agree("Change username (currently #{user[:username]}) [y/N]? ") { |q| q.default = 'n'; q.default_hint_show = false }
      exists = true
      while exists
        while (changes[:username] = ask("Please enter a new username: ") { |q| q.limit = 255 }).nil?
          puts "Username must not be blank."
        end
        exists = MEGS::DB[:users].select(:id).where(username: changes[:username]).one
        puts "Username already exists. Please choose another." if exists
      end
    end

    if agree("Change player name (currently #{user[:name]}) [y/N]? ") { |q| q.default = 'n'; q.default_hint_show = false }
      while (changes[:name] = ask("Please enter a new player name: ") { |q| q.limit = 255 }).nil?
        puts "Player name must not be blank."
      end
    end

    class PasswordValidator
      class << self
        attr_accessor :password
        def valid?(pw)
          password.is_password?(pw)
        end

        def inspect
          'current password'
        end
      end
    end
    PasswordValidator.password = user[:password]

    if agree("Change password [y/N]? ") { |q| q.default = 'n'; q.default_hint_show = false }
      current = ask("Please enter current password: ") { |q| q.echo = '*'; q.validate = PasswordValidator }
      new_password = []
      while new_password.uniq.size != 1 || new_password.uniq.first.empty?
        new_password << ask("Please enter a new password for user #{changes[:username] || user[:username]}: ") { |q| q.echo = '*' }
        new_password << ask("Re-enter new password to verify: ") { |q| q.echo = '*' }
        puts "Passwords did not match, please try again." unless new_password.uniq.size == 1
        puts "Password must not be blank." if new_password.uniq.first.empty?
      end
      changes[:password] = new_password.uniq.first
    end

    if agree("Change admin status for user #{changes[:username] || user[:username]} [y/N]? ") { |q| q.default = 'n'; q.default_hint_show = false }
      changes[:admin] = agree("Is #{changes[:username] || user[:username]} an admin [y/N]? ") { |q| q.default = 'n'; q.default_hint_show = false }
    end

    unless changes.empty?
      MEGS::DB[:users].by_pk(user[:id]).changeset(:update, changes).commit
    end
  rescue ArgumentError => e
    puts "ERROR: #{e.message}"
  end

  task :delete_user, [:id] => :db_connect do |_t, args|
    raise ArgumentError.new("Must specify a user ID when deleting a user. i.e. rake megs:delete_user[3]") unless args.id
    user = MEGS::DB[:users].by_pk(args.id.to_i).one
    raise ArgumentError.new("User with ID of #{args.id} not found.") unless user

    if agree("Are you sure you want to delete #{user[:username]} and all of their characters [y/N]? ") { |q| q.default = 'n'; q.default_hint_show = false }
      MEGS::DB[:characters].where(user_id: user[:id]).changeset(:delete).commit
      MEGS::DB[:users].by_pk(user[:id]).changeset(:delete).commit
    end
  rescue ArgumentError => e
    puts "ERROR: #{e.message}"
  end

  task :create_character, [:user_id] => :db_connect do |_t, args|
    raise ArgumentError.new("Must specify a user ID when creating a character. i.e. rake megs:create_character[3]") unless args.user_id
    user = MEGS::DB[:users].by_pk(args.user_id.to_i).one
    raise ArgumentError.new("User with ID of #{args.user_id} not found.") unless user

    puts "Adding a new character for #{user[:username]}..."
    name = ask("Please enter a character name: ") { |q| q.limit = 255 }

    if name.nil?
      puts "Character name must not be blank. Aborting."
    else
      if MEGS::DB[:characters].select(:id).where(user_id: user[:id], name: name).one
        puts "Character #{name} already exists for #{user[:username]}. Aborting."
      else
        MEGS::DB[:characters].changeset(:create, { user_id: user[:id], name: name }).commit
      end
    end
  rescue ArgumentError => e
    puts "ERROR: #{e.message}"
  end

  task :update_character, [:id] => :db_connect do |_t, args|
    raise ArgumentError.new("Must specify a character ID when updating a character. i.e. rake megs:update_character[5]") unless args.id
    character = MEGS::DB[:characters].by_pk(args.id.to_i).one
    raise ArgumentError.new("Character with ID of #{args.id} not found.") unless character
    user = MEGS::DB[:users].by_pk(character[:user_id]).one

    changes = {}
    if agree("Change character name (currently #{character[:name]}) [y/N]? ") { |q| q.default = 'n'; q.default_hint_show = false }
      while (changes[:name] = ask("Please enter a new character name: ") { |q| q.limit = 255 }).nil?
        puts "Character name must not be blank."
      end
    end

    if agree("Change owner of character (currently #{user[:username]}) [y/N]? ") { |q| q.default = 'n'; q.default_hint_show = false }
      user_ids = MEGS::DB[:users].select(:id).map { |u| u[:id].to_s }
      taken = true
      while taken
        changes[:user_id] = ask("Please enter a new user ID (currently #{user[:id]}): ") { |q| q.in = user_ids }
        taken = MEGS::DB[:characters].where(user_id: changes[:user_id], name: changes[:name] || character[:name]).one
        puts "User #{user[:username]} already has a character named #{changes[:name] || character[:name]}. Choose a different user ID." if taken
      end
    end

    unless changes.empty?
      MEGS::DB[:characters].by_pk(character[:id]).changeset(:update, changes).commit
    end
  rescue ArgumentError => e
    puts "ERROR: #{e.message}"
  end

  task :delete_character, [:id] => :db_connect do |_t, args|
    raise ArgumentError.new("Must specify a character ID when deleting a character. i.e. rake megs:delete_character[4]") unless args.id
    character = MEGS::DB[:characters].by_pk(args.id.to_i).one
    raise ArgumentError.new("Character with ID of #{args.id} not found.") unless character
    user = MEGS::DB[:users].by_pk(character[:user_id]).one

    if agree("Are you sure you want to delete #{character[:name]} for user #{user[:username]} [y/N]? ") { |q| q.default = 'n'; q.default_hint_show = false }
      MEGS::DB[:characters].where(id: character[:id]).changeset(:delete).commit
    end
  rescue ArgumentError => e
    puts "ERROR: #{e.message}"
  end
end
