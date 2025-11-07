require 'rails_helper'
require 'spec_helper'

# Ruby 2.6.6 + Rails 4.2 monkeypatch
if RUBY_VERSION >= '2.6.0'
  if Rails.version < '5'
    class ActionController::TestResponse < ActionDispatch::TestResponse
      def recycle!
        @mon_mutex_owner_object_id = nil
        @mon_mutex = nil
        initialize
      end
    end
  end
end

describe MoviesController do

  #
  # PART 3 — YOUR ORIGINAL TESTS
  #
  describe 'searching TMDb' do
    before :each do
      @fake_results = [double('movie1'), double('movie2')]
    end

    it 'calls the model method that performs TMDb search' do
      expect(Movie).to receive(:find_in_tmdb)
        .with('hardware', hash_including(year: anything, language: anything))
        .and_return(@fake_results)
    
      get :search_tmdb, { search_terms: 'hardware' }
    end    

    describe 'after valid search' do
      before :each do
        allow(Movie).to receive(:find_in_tmdb).and_return(@fake_results)
        get :search_tmdb, { search_terms: 'hardware' }
      end

      it 'selects the Search Results template for rendering' do
        expect(response).to render_template('search_tmdb')
      end

      it 'makes the TMDb search results available to that template' do
        expect(assigns(:movies)).to eq(@fake_results)
      end
    end
  end

  describe 'searching TMDb validations' do
    it 'warns when title missing and re-renders' do
      get :search_tmdb, params: { search_terms: '' }
      expect(flash[:warning]).to match(/Please fill in all required fields!/)
      expect(response).to render_template('search_tmdb')
    end

    it 'shows info flash when no results' do
      allow(Movie).to receive(:find_in_tmdb).and_return([])
      get  :search_tmdb, { search_terms: 'xyz' }
      expect(flash[:info]).to match(/No movies found/)
      expect(response).to render_template('search_tmdb')
    end
  end

  describe 'adding a movie' do
    it 'creates the movie and redirects with success' do
      expect {
        post :add_movie,   { title: 'Foo', release_date: '2001-01-01', rating: '' }
      }.to change(Movie, :count).by(1)

      expect(flash[:success]).to match(/Foo was successfully added/)
      expect(response).to redirect_to(search_path)
    end
  end
end
