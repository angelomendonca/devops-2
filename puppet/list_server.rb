#!/usr/bin/env ruby

require 'net/http'
require 'net/https'
require 'net/ping'
require 'uri'
require 'filecache'
require 'colorize'
require 'mongo'

def build_url(environment, role, cronMaster)
  url_string = "https://<PUPPET_MASTER_IPADDRESS>:8140/production/facts_search/search?facts.env=#{environment}"
  url_string += "&facts.role=#{role}" if role
  url_string += "&facts.is_cronMaster=true" if cronMaster
  URI.parse(url_string)
end

def http_get(url)
  begin
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    http.get(url.request_uri)
  rescue => e
    puts e.inspect
  end
end

def clean_host(host)
  host.gsub(/["\[\]]/, '')
end

def parse_hosts_list(hosts_list)
  hosts_list.split(',').map { |h| clean_host(h) }
end

def alive?(host)
  Net::Ping::TCP.new(host, 22, 5).ping?
end

def is_cronMaster?(host)
  if host.include?('ws-') and ARGV[0].match(/^(prod|pro|pr|production|p)/)
     cronMaster_response = http_get(URI.parse("https://10.0.0.37:8140/production/facts_search/search?facts.is_cronMaster=true&facts.fqdn=#{host}"))
     if cronMaster_response.body.include?(host)
      return true
     else
      return false
     end
  end
  return false
end

def is_master?(host)
  if host.include?('-mongodb-')
    host = host 
    port = '27017'
    client  = Mongo::MongoClient.new(host, port)
    isMaster = client.check_is_master([host, port]).to_a[1][1]
    if isMaster 
       return true
    else 
       return false
    end
  end
end

def set_or_get_from_cache(host)
  cache = FileCache.new("server_list", "/tmp/server_list", 28800)
  if cache.get(host)
    fqdn = cache.get(host)
  else
    puts "      not in cache, saving and getting:".colorize(:light_red)
    if is_cronMaster?(host)
      cache.set(host,"[cronMaster] #{host}".colorize(:light_green)) if alive?(host)
      fqdn = cache.get(host)
    elsif is_master?(host)
      cache.set(host,"[MASTER] #{host}".colorize(:yellow)) if alive?(host)
      fqdn = cache.get(host)
    else
       cache.set(host,host) if alive?(host)
       fqdn = cache.get(host)
    end
  end
  return fqdn
end

if ARGV.length < 1
  puts "Parameters error : Usage is : #{$0} environment (role)"
  exit 1
end

environment = ARGV[0]
role = ARGV[1]
cronMaster = ARGV[2]

if ARGV[0].match(/^(prod|pro|pr|production|p)/)
  environment = 'production'
end

url = build_url(environment, role, cronMaster)
resp = http_get(url)
hosts_list = parse_hosts_list(resp.body)
hosts_list.each { |host| puts set_or_get_from_cache(host).bold }
