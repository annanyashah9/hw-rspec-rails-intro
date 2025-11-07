# app/models/movie.rb
class Movie < ActiveRecord::Base
  class TmdbError < StandardError; end

  TMDB_SEARCH_URL = 'https://api.themoviedb.org/3/search/movie'.freeze

  # title: required (blank -> [])
  # year: optional
  # language: optional ('en' or 'all'); we omit language if 'all'
  # api_key: defaults from ENV but can be passed in tests
  def self.find_in_tmdb(title, year: nil, language: nil, api_key: ENV['TMDB_API_KEY'])
    return [] if title.to_s.strip.empty?
    raise TmdbError, 'Missing TMDB_API_KEY' if api_key.to_s.empty?

    params = { query: title, api_key: api_key }
    params[:year]     = year if year.present?
    params[:language] = language if language.present? && language != 'all'

    resp = Faraday.get(TMDB_SEARCH_URL, params)
    raise TmdbError, 'TMDb returned an error' unless resp.status == 200

    json = JSON.parse(resp.body)
    results = Array(json['results']).map do |m|
      {
        tmdb_id:      m['id'],
        title:        m['title'],
        release_date: m['release_date'],
        rating:       'R' # per assignment
      }
    end

    # If you want to exclude already-saved movies, uncomment:
    # saved = Movie.pluck(:title, :release_date).to_set
    # results.reject { |h| saved.include?([h[:title], h[:release_date]]) }

    results
  rescue JSON::ParserError
    raise TmdbError, 'TMDb response was not valid JSON'
  rescue Faraday::Error => e
    raise TmdbError, "Network error: #{e.message}"
  end
  def self.all_ratings
  %w[G PG PG-13 R NC-17]
end

# Helper used by MoviesController#index to filter and sort
def self.with_ratings(ratings, sort_by)
  rel = all
  # if no ratings passed, show all
  ratings = all_ratings if ratings.blank?
  rel = rel.where(rating: ratings)
  rel = rel.order(sort_by) if sort_by.present?
  rel
end
end