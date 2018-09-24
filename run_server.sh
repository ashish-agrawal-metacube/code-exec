#!/bin/sh
ulimit -s 128000
export PORT="3001"
bundle exec rails s -p 3001
# bundle exec puma -C config/puma.rb
