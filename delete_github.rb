#!/usr/bin/env ruby

require 'json'
require 'logger'
require 'net/http'
require 'ostruct'
require 'uri'

class DeleteGitHub
  attr_reader :username, :token, :logger

  def self.run!(username:, token:)
    delete_github = new(username: username, token: token)

    delete_github.delete_repositories!

    delete_github.logger.info('FIN')
  end

  def self.env
    OpenStruct.new(
      github_user: ENV['GITHUB_USER'] || (raise ArgumentError, 'GITHUB_USER must be defined'),
      github_token: ENV['GITHUB_TOKEN'] || (raise ArgumentError, 'GITHUB_TOKEN must be defined')
    )
  end

  def initialize(username:, token:)
    @username = username
    @token = token
    @logger = Logger.new(STDOUT)
  end

  def delete_repositories!
    repos = retrieve_repositories

    if repos.empty?
      return logger.warn("Found 0 repositories to delete.")
    end

    repos.each do |repo|
      project = repo['name']
      uri = URI.parse("https://api.github.com/repos/#{username}/#{project}")
      http = Net::HTTP.new(uri.host, 443)
      http.use_ssl = true

      logger.info("DELETE #{uri}")

      request = Net::HTTP::Delete.new(uri.request_uri)
      request['Authorization'] = "token #{token}"
      response = http.request(request)

      unless response.code.to_i == 204
        raise StandardError, "expected response code 204, found #{response.code}"
      end
    end
  end

  private

  def retrieve_repositories(uri: 'https://api.github.com/user/repos?affiliation=owner&per_page=100',
                            repos: [])
    uri = URI.parse(uri)
    http = Net::HTTP.new(uri.host, 443)
    http.use_ssl = true

    logger.info("GET #{uri}")

    request = Net::HTTP::Get.new(uri.request_uri)
    request['Accept'] = 'application/json'
    request['Authorization'] = "token #{token}"

    response = http.request(request)

    case response.code.to_i
    when 200
      link = response.header['link']

      body = JSON.parse(response.body)

      body.each do |repo|
        repos << repo
      end

      next_page_link = if link.respond_to?(:split)
                         link.split(',').detect { |l| l.end_with?('rel="next"') }
                       else
                         link
                       end

      return repos unless next_page_link

      uri = next_page_link.strip.split(';').first[1..-2]

      retrieve_repositories(uri: uri, repos: repos)
    else
      raise StandardError, "unexpected response code: #{response.code}"
    end
  end
end

DeleteGitHub.run!(
  username: DeleteGitHub.env.github_user,
  token: DeleteGitHub.env.github_token
)
