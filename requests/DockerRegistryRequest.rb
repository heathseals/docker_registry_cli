#!/usr/bin/ruby

require 'rubygems'
require 'json'
require 'httparty'
require 'yaml'
require 'pp'

require_relative '../auth/TokenAuthService'
require_relative '../auth/BasicAuthService'

class DockerRegistryRequest
  include HTTParty
  format :json
  headers 'Content-Type' => 'application/json'
  headers 'Accept' => 'application/json'
  @@debug = false

  def initialize(domain, user = nil, pass = nil, debug = false)
    @@debug = debug
    self.class.base_uri "https://#{domain}/v2"
    handle_preauth(domain, user, pass)
  end

  def handle_preauth(domain, user = nil, pass = nil)
    # Only BasicAuth is supported
    authService = BasicAuthService.new(self)
    begin
      if user && pass
        # this will base64 encode automatically
        authService.byCredentials(user, pass)
      else
        authService.byToken(domain)
      end
    rescue Exception
      puts "No BasicAuth pre-auth available, will try to use different auth-services later".green
    end

  end

  ### check if the login actually will succeed
  def authenticate(response)
    headers = response.headers()
    begin
      if headers.has_key?('www-authenticate')
        auth_description = headers['www-authenticate']
        if auth_description.match('Bearer realm=')
          authService = TokenAuthService.new(self)
          authService.tokenAuth(response)
        else
          throw "Auth method not supported #{auth_description}"
        end
      end
    rescue Exception
      puts "Authentication failed".colorize(:red)
    end
  end

  ## sends a get request, authenticates if needed
  def send_get_request(path, options = {})
    # we try to send the request. if it fails due to auth, we need the returned scope
    # thats why we first try to do it without auth, then reusing the scope from the response
    response = self.class.get(path, options)
    # need auth
    case (response.code)
      when 200
        # just continue
      when 401
        authenticate(response)
        response = self.class.get(path, options)
      else
    end
    unless response.code == 200
      throw "Could not finish request, status #{response.code}"
    end
    return response
  end

  ## sends a delete request, authenticates if needed
  def send_delete_request(path)
    response = self.class.delete(path)
    # need auth
    case (response.code)
      when 200
        # just continue
      when 401
        authenticate(response)
        response = self.class.delete(path)
      else
    end
    if response.code != 200 && response.code != 202
      throw "Could not finish request, status #{response.code}"
    end
    return response
  end

  ### returns the digest for a tag
  ### @see https://docs.docker.com/registry/spec/api/#pulling-an-image
  def digest(image_name, tag)
    options = {
        :headers => {
            'Accept' => 'application/vnd.docker.distribution.manifest.v2+json'
        }
    }
    begin
      response = send_get_request("/#{image_name}/manifests/#{tag}", options)
    rescue
      puts "Could not find digest for image #{image_name} with tag #{tag}".colorize(:red)
      exit 1
    end

    unless response.code == 200
      puts "Could not find digest for image #{image_name} with tag #{tag}".colorize(:red)
      exit 1
    end

    return response.headers['docker-content-digest']
  end
end