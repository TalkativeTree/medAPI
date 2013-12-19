require 'open-uri'
require 'nokogiri'
require_relative "topics"

UNWANTED = ['',' ', ',', ';']
UNWANTED_REGEX = /(,| |;)/

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
        term
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

  matches = []
  alternatives = []
  topics = {}
  odds = []
  MEDLINE_TERMS.each_with_object({}) do |pair, hash|
    if pair[0] == pair[1]
      term = Term.where(name: pair[0]).first_or_create
      odds << term
      matches << pair
    elsif pair[0] != pair[1]
      term = Term.where(name: pair[0]).first_or_create
      alt = Term.where(name: pair[1]).first_or_create
      term.alternatives << alt
      alternatives << alt
      hash[pair[0]] ||= []
      hash[pair[0]] << alt
    else
      odds << pair
    end
    topics = hash
  end

  MEDLINE_PAIRS.each_pair do |term_key, alts|
    puts "MEDLINE_PAIRS: term: #{term_key} alt: #{alts}"
    term = Term.where(name: term_key).first_or_create
    # create tokens for search
    tokens = Search.convert(term_key + ' ' + alts.join(' '))
    puts "TOKENS: #{tokens}"
    #create or find search enginge


    #create term
    new_term = Term.where(name: term_key).first_or_create
    puts "SEARCH_ENGINE: #{term}"
    alt_terms = alts.map{ |a| a }
    puts "ALT_TERMS: #{alt_terms.inspect}"

    #add alternatives to term
    alt_terms.each do |a|
      new_term.alternatives << Term.where(name: a).first_or_create
    end
    # create search
    puts "TERM: #{term.inspect}"
    puts "TOKENS: #{tokens}"

    db_search = new_term.searches.where(tokens: tokens).first_or_create do |srch|
      # add term to search
      puts "SEARCH  #{srch.inspect}"
      puts "SEARCH.tokens:  #{srch.tokens}"
      new_term.searches << srch
      #add search to search_engine
      # SEARCH_ENGINE.searches << search
    end
    #get search results
    results = search(term_key)

    results.each do |s|
    # create source

    #create search result
      Source.where(title: s["organizationName"]).first_or_create

      result = Result.create(
            title: s["title"],
            summary: s["FullSummary"],
            url: s["url"],
            snippet: s["snippet"],
          )
      rank = result.rankings.create(position: s['rank'])
      db_search.rankings << rank
    end
  end
end
