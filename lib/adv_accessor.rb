require 'mharris_ext'
%w(base dsl mapping checker).each do |f|
  require File.dirname(__FILE__) + "/adv_accessor/#{f}"
end

module AdvAccessor
end