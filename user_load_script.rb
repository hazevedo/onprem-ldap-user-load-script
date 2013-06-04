# Copyright 2002-2012 Rally Software Development Corp. All Rights Reserved.

require 'rubygems'
require 'rally_rest_api'
require 'fastercsv'

rally_url        = "https://10.32.0.250/slm"
rally_user       = "test@rallydev.com"
rally_password   = "treblid!"
rally_ws_version = "1.23"
filename         = 'users_update.csv'

def get_rally_users()
  users = @rally.find(:user) { equal :onprem_ldap_username, nil }
  return users
end

def update_user(header, row)
  username        = row[header[0]]
  onprem_username = row[header[1]]
  rally_user      = @rally.find(:user) { equal :user_name, username }

  if rally_user.total_result_count == 0
    puts "Rally user #{username} not found"
  else
    begin
      rally_user_updated = @rally.update(rally_user.first, :onprem_ldap_username => onprem_username)
      puts "Rally user #{username} updated successfully - onprem username set to '#{rally_user_updated[:onprem_ldap_username.to_sym]}'"
    rescue => ex
      puts " Rally user #{username} not updated due to error"
      puts ex
    end
  end
end

begin
  @rally = RallyRestAPI.new(:base_url => rally_url, :username => rally_user, :password => rally_password, :version => rally_ws_version)

  input  = FasterCSV.read(filename)


  header = input.first #ignores first line

  rows   = []
  (1...input.size).each { |i| rows << FasterCSV::Row.new(header, input[i]) }

  rows.each do |row|
    update_user(header, row)
  end

  rally_users = get_rally_users()
  puts "#{rally_users.total_result_count} Rally users with no OnpremLdapUsername"
  rally_users.each do |user|
    puts "Rally user #{user.user_name} without a ldap onprem username value"

  end
rescue => ex
  puts ex
end
