# encoding: utf-8


require 'pp'
require 'yaml'
require 'json'
require 'uri'
require 'time'

## gems
require 'hubba'



module Hubba
  class Github
    def repo( full_name )   ## full_name (handle) e.g. henrythemes/jekyll-starter-theme
      Resource.new( get "/repos/#{full_name}" )
    end

    def repo_commits( full_name )
      Resource.new( get "/repos/#{full_name}/commits" )
    end
  end
end


class GithubRepoStats

  attr_reader :data

  def initialize( full_name )
    @data = {}
    @data['full_name'] = full_name  # e.g. poole/hyde etc.
  end

  def full_name() @data['full_name']; end


  def fetch( gh )   ## update stats / fetch data from github via api
    puts "fetching #{full_name}..."
    repo    = gh.repo( full_name )

    @data['created_at'] = repo.data['created_at']
    ## e.g. 2015-05-11T20:21:43Z
    ## puts Time.iso8601( repo.data['created_at'] )

    rec = {}

    puts "stargazers_count"
    puts repo.data['stargazers_count']
    rec['stargazers_count'] = repo.data['stargazers_count']

    today = Date.today.strftime( '%Y-%m-%d' )   ## e.g. 2016-09-27
    puts "add record #{today} to history..."

    @data[ 'history'] ||= {}
    @data[ 'history'][ today ] = rec

    ##########################
    ## also check / keep track of (latest) commit
    commits = gh.repo_commits( full_name )
    puts "last commit/update:"
    ## pp commits
    commit = {
      'committer' => {
        'date' => commits.data[0]['commit']['committer']['date'],
        'name' => commits.data[0]['commit']['committer']['name']
      },
      'message' => commits.data[0]['commit']['message']
    }

    ## for now store only the latest commit (e.g. a single commit in an array)
    @data[ 'commits'] = [commit]

    pp @data
  end

  def write( data_dir: './data' )
    basename = full_name.gsub( '/', '~' )   ## e.g. poole/hyde become poole~hyde
    puts "writing (saving) to #{basename}..."
    File.open( "#{data_dir}/#{basename}.json", "w" ) do |f|
        f.write JSON.pretty_generate( data )
    end
  end

  def read( data_dir: './cache' )   ## note: use read instead of load (load is kind of keyword for loading code)
    ## note: skip reading if file not present
    basename = full_name.gsub( '/', '~' )   ## e.g. poole/hyde become poole~hyde
    filename = "#{data_dir}/#{basename}.json"
    if File.exist?( filename )
      puts "reading (loading) from #{basename}..."
      json = File.read( filename )    ## todo/fix: use read_utf8
      @data = JSON.parse( json )
    else
      puts "skipping reading (loading) from #{basename} -- file not found"
    end
  end

end # class GithubRepoStats



## for testing if called via script/stats.rb
##
if __FILE__ == $0

themes = [
  'henrythemes/jekyll-starter-theme',
  'poole/hyde',
  'jekyll/minima'
]

gh = Hubba::Github.new( cache_dir: './cache' )

themes.each do |theme|
  stats = GithubRepoStats.new( theme )
  stats.read( data_dir: './data' )
  stats.fetch( gh )
  stats.write( data_dir: './data' )
end

end
