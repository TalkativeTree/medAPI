require 'open-uri'
require 'nokogiri'
require_relative "topics"

UNWANTED = ['',' ', ',', ';','--']
UNWANTED_REGEX = /(,| |;|--)/

def split(term)
  term.split(UNWANTED_REGEX).reject!{|s| UNWANTED.include?(s)}
end

def clean_up(term)
  t = if term.match(UNWANTED_REGEX)
        split(term).join('+')
      else
        term
      end
  p "%22#{t}%22"
  "%22#{t}%22"
end

def tokenize(term)
  t = if term.match(UNWANTED_REGEX)
        split(term.downcase)
      else
        [term]
      end

  t.sort
end

def convert_for_postgres(tokens)
  postgreql_array_insert = "{"
  tokens.each{ |word| postgreql_array_insert += word + "," }
  postgreql_array_insert[-1] = "}"
  postgreql_array_insert
end

def search(term)
  term = clean_up(term)
  doc = Nokogiri::XML(open("http://wsearch.nlm.nih.gov/ws/query?db=healthTopics&term=#{term}"))
  Results.new.convert_xml(doc)
end

class SearchResult
  attr_accessor :url, :rank, :title, :organizationName, :altTitle, :FullSummary, :mesh, :snippet, :groupName
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

  def [] attribute
    self.send attribute
  end

  def as_hash
    self.instance_variables.each_with_object({}) do |var, hash|
      ivar = var.to_s.delete('@')
      hash[ivar] = self[ivar]
    end
  end
end

class Results
   include ActionView::Helpers::SanitizeHelper

  attr_reader :results
  def initialize
    @results = []
  end

  def convert_xml(xml)
    xml.xpath('//list').children.each do |term|
      if term.attributes['url']
        result = SearchResult.new
        result['url'] = term.attributes['url'].value
        result['rank'] = term.attributes['rank'].value

        term.children.each do |child|
          if child.attributes['name']
            clean_text = strip_tags(child.text)
            result[child.attributes['name'].value] = clean_text.strip
          end
        end

        results << result
      end
    end

    results
  end
end


task seed_medline: :environment do

  SEARCH_ENGINE = SearchEngine.where(
    name: "Medline",
    base_url: "http://wsearch.nlm.nih.gov/ws/query?db=healthTopics"
  ).first_or_create

  MEDLINE_TERMS.uniq.sort.each do |term|
    unless Term.where(name: term).first
      new_term = Term.where(name: term).first_or_create
      tokens = tokenize(term)
      search = Search.create(tokens: tokens)

      new_term.search_engines << SEARCH_ENGINE
      new_term.searches << search

      results = search(term)

      results.each do |s|

        # create source & ranking
        source = Source.where(title: s["organizationName"]).first_or_create
        rank = Ranking.create(position: s['rank'])

        #create search result
        Result.where(
          title: s["title"],
          summary: s["FullSummary"],
          url: s["url"],
          snippet: s["snippet"],
        ).first_or_create do |new_result|
          source.results << new_result
          search.rankings << rank
          new_result.rankings << rank
        end
      end
    end
  end
end
