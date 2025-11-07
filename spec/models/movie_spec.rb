require 'rails_helper'
require 'spec_helper'

describe Movie do
  describe '.find_in_tmdb' do
    let(:api_key)   { 'DUMMY' }
    let(:endpoint)  { 'https://api.themoviedb.org/3/search/movie' }
    let(:query)     { 'Manhunter' }
    let(:year)      { 1986 }
    let(:fake_body) do
      {
        "results" => [
          {"id"=>11448, "title"=>"Manhunter", "release_date"=>"1986-08-15", "vote_average"=>7.0}
        ]
      }.to_json
    end
    let(:fake_resp) { instance_double(Faraday::Response, status: 200, body: fake_body) }

    before do
      # allow normal ENV lookups (so Faraday can read http_proxy, etc.)
      allow(ENV).to receive(:[]).and_call_original
      # but override only the key we care about
      allow(ENV).to receive(:[]).with('TMDB_API_KEY').and_return(api_key)
    end
    

    it 'calls TMDb search endpoint with query/year/api_key' do
      expect(Faraday).to receive(:get).with(endpoint, hash_including(
        query: query, year: year, api_key: api_key
      )).and_return(fake_resp)

      Movie.find_in_tmdb(query, year: year)
    end

    it 'parses JSON and returns array of hashes' do
      allow(Faraday).to receive(:get).and_return(fake_resp)
    
      results = Movie.find_in_tmdb(query, year: year)
      expect(results).to be_an(Array)
      expect(results.first).to include(
        title: "Manhunter",
        release_date: "1986-08-15",
        rating: 'R'              # Part 5: default to 'R'
      )
      # No :tmdb_id expectation now, because we don’t return it in Part 5
    end
    

    it 'raises on non-200' do
      bad = instance_double(Faraday::Response, status: 401, body: '{"status_message":"Invalid"}')
      allow(Faraday).to receive(:get).and_return(bad)
      expect { Movie.find_in_tmdb(query) }.to raise_error(Movie::TmdbError)
    end
  end
end
