# require "energy_market/version"
# require "energy_market/energy_market"

%w(
    my_util
    version
    energy_market
    vector
    values_array
  ).each { |file| require File.join(File.dirname(__FILE__), 'energy_market', file) }

module EnergyMarket
  # Your code goes here...
end
