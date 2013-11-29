# require "energy_market/version"
# require "energy_market/energy_market"

%w(
    version
    energy_market
    vector
    values_array
    my_util
  ).each { |file| require File.join(File.dirname(__FILE__), 'energy_market', file) }

module EnergyMarket
  # Your code goes here...
end
