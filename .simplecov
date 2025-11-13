require 'simplecov'

SimpleCov.start 'rails' do
  add_filter '/spec/'
  add_filter '/config/'
  add_filter '/vendor/'
  add_filter '/app/mailers/'
  track_files '{app,lib}/**/*.rb'
end
