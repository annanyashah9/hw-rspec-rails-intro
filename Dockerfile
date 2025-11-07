FROM ruby:2.6.10
RUN apt-get update -qq && apt-get install -y nodejs sqlite3 libsqlite3-dev
WORKDIR /app
COPY Gemfile Gemfile.lock ./
RUN gem install bundler -v 1.17.3
RUN bundle _1.17.3_ install
COPY . .
EXPOSE 3000
CMD ["bash", "-c", "bundle exec rails s -p ${PORT:-3000} -b 0.0.0.0"]
