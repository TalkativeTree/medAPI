# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

require 'open-uri'
require 'nokogiri'

def search(term)
  term.downcase.gsub!(/ /, '')
  doc = Nokogiri::XML(open("http://wsearch.nlm.nih.gov/ws/query?db=healthTopics&term=#{term}"))
  Results.new.convert_xml(doc)
end

class Result
  attr_accessor :url, :title, :organizationName, :altTitle, :FullSummary, :mesh, :snippet, :groupName
  def initialize(options={})
    @url = options[:url]
    @rank = options[:rank]
    @title = options[:title]
    @organizationName = options[:organizationName]
    @altTitle = options[:altTitle]
    @FullSummary = options[:FullSummary]
    @mesh = options[:mesh]
    @groupName = []
    @snippet =options[:snippet]
  end

  def add_groupName value
    groupName << value
  end

  def []= attribute, new_value
    symbol = "#{attribute}="
    symbol = "add_groupName" if attribute == "groupName"
    self.send symbol, new_value
  end
end

class Results
  attr_reader :results
  def initialize
    @results = {}
  end

  def convert_xml(xml)
    term = xml.xpath('//term').text
    results[term] = []
    xml.xpath('//list').children.each do |term|
      if term.attributes['url']
        result = Result.new
        result['url'] = term.attributes['url'].value
        result['rank'] = term.attributes['rank'].value.to_int

        term.children.each do |child|
          if child.attributes['name']
            clean_text = child.text.gsub(/(<span class=\"qt0\">|<\/span>)/, '')
            clean_text = clean_text.gsub(/(<p>|<\/p>)/, '')
            result[child.attributes['name'].value] = clean_text.strip
          end
        end

        results[term] << result
      end
    end

    results[term]
  end
end


task seed_medline: :environment do
  search('asthma')
end
