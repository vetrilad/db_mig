require 'sequel'
require 'mysql2'
require 'json'
require 'redis'

vmc_conf = JSON.parse(ENV['VMC_SERVICES'])

mysql_credentials = vmc_conf.find { |service| service['name'] == 'winback-mysql-database' }['options']
@url = %(mysql2://#{mysql_credentials['username']}:
                        #{mysql_credentials['password']}@#{mysql_credentials['host']}:
                        #{mysql_credentials['port']}/#{mysql_credentials['name']}).gsub(/\s+/, '').strip

redis_credentials = vmc_conf.find { |service| service['name'] == 'winback-selfserve-redis-20150511' }['options']
@redis_url = %(redis://:#{redis_credentials['password']}@
                        #{redis_credentials['host']}:#{redis_credentials['port']}).gsub(/\s+/, '').strip

def redis_completed_journey
  @redis ||= Redis.new(:url => @redis_url)
end

def completed_journey
  @conn ||= Sequel.connect(@url)[:completed_journeys]
end

def empty_completed_journeys
  completed_journey.truncate
end

empty_completed_journeys

array_accounts = redis_completed_journey.keys.reject do |entry|
  entry.length > 30
end

array_accounts.each do |account_number|
  completed_journey.insert(account_id: account_number, created_at: Time.now)
end
