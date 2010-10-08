# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_pin-notes_session',
  :secret      => '1c96e6d36da894aff86af60401977e5de5729a8e8ba61740130f60e30edb12f3f181edaba40f0bae40728e0363566716c4f0ab13772bdeb4ab7592a0c63226ca'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
