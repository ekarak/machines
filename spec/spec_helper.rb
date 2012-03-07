=begin
begin
  require 'spec'
rescue LoadError
  require 'rubygems'
  gem 'rspec'
  require 'spec'
end
=end
require 'rspec'
$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'machines'
