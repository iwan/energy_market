require_relative 'electricity_market'

start_date = "2013-01-01"
zone = "Rome"
array = [3, 6, 7, -34, 5.5, 0, 8]

v = EnergyMarket::Vector.new(start_date, zone).data(array)


# puts v
# puts v.size

# puts v.sum

# v.until_the_end_of_the_year(1.0)
# puts v.size
# puts v

# v.set_all_to(0.0)
# puts v

# ---- Initialize --------

Time.zone = "Rome"
# All the following are the same:
EnergyMarket::Vector.new
EnergyMarket::Vector.new(Time.zone.now)


# All the following are the same:
EnergyMarket::Vector.new("13") # no! Wed, 13 Nov 2013 00:00:00 CET +01:00
EnergyMarket::Vector.new("2013")
EnergyMarket::Vector.new("2013-01")
EnergyMarket::Vector.new("2013-01-01")
EnergyMarket::Vector.new("2013-01-01 00")
EnergyMarket::Vector.new("2013-01-01 00:00")
EnergyMarket::Vector.new("2013-01-01 00:00:00")
EnergyMarket::Vector.new("2013-01-01 00:23:45")

# All the following are the same:
EnergyMarket::Vector.new("2013-01-01")
EnergyMarket::Vector.new("2013-01-01", "Rome")


# ---- Insert data --------

v = EnergyMarket::Vector.new("2013-01-01").data([2.3, 1.1, 4])
# solo 3 valori/ore
v.until_the_end_of_the_year(1.0) # di default mette 0.0
# 8760 valori/ore: [2.3, 1.1, 4, 1.0, 1.0, 1.0, 1.0, ...]

v = EnergyMarket::Vector.new("2013-01-01").data([2.3, 1.1, 4])

EnergyMarket::Vector.new(start_date, zone).data([1.0, 2.0], :day)
# tutte le ore del 1 gennaio valorizzate a 1.0, tutte quelle del 2 gennaio a 2.0. Nient'altro

EnergyMarket::Vector.new(start_date, zone).data([1.0, 2.0], :month)
# tutte le ore di gennaio valorizzate a 1.0, tutte quelle di febbraio a 2.0. Nient'altro

EnergyMarket::Vector.new(start_date, zone).data([5.3], :year)
# oppure
EnergyMarket::Vector.new(start_date, zone).data(5.3, :year)




EnergyMarket::Vector.new("2013").until_the_end_of_the_year(default_value = 3.4)
# will prepare a 8760 elements vector with value=3.4


EnergyMarket::Vector.new("2013").data([1,2,3,4,5]).set_all_to(4.0)
# [4.0, 4.0, 4.0, 4.0, 4.0]

v1 = EnergyMarket::Vector.new("2013").until_the_end_of_the_year(default_value = 3.4)
v2 = EnergyMarket::Vector.new("2013").until_the_end_of_the_year(default_value = 1.6)
v3 = (v1+v2)*2
puts v3.maximum_value
puts v3.minimum_value

