require 'test/unit'
require 'energy_market'
require 'time'

class TestVector < Test::Unit::TestCase
  
  def setup
    @zone = "Rome"
    @opts = {:zone => @zone}
    @array = [3, 6, 7, -34, 5.5, 0, 8]
  end

  def test_initialize_start_time
    v1 = EnergyMarket::Vector.new("2013-01-01 00:00:00", @opts)
    v2 = EnergyMarket::Vector.new("2013-01-01 00:00", @opts)
    assert_equal(v1.start_time, v2.start_time)

    v2 = EnergyMarket::Vector.new("2013-01-01 00", @opts)
    assert_equal(v1.start_time, v2.start_time)

    v2 = EnergyMarket::Vector.new("2013-01-01", @opts)
    assert_equal(v1.start_time, v2.start_time)

    v2 = EnergyMarket::Vector.new("2013-01", @opts)
    assert_equal(v1.start_time, v2.start_time)

    v2 = EnergyMarket::Vector.new("2013", @opts)
    assert_equal(v1.start_time, v2.start_time)

    v2 = EnergyMarket::Vector.new("2013")
    assert_equal(v1.start_time, v2.start_time)

    v2 = EnergyMarket::Vector.new("2013", :zone => "London")
    assert_not_equal(v2.start_time, v1.start_time)

    Time.zone = @zone
    v1 = EnergyMarket::Vector.new
    v2 = EnergyMarket::Vector.new(Time.zone.now.strftime("%Y-%m-%d %H"))
    assert_equal(v1.start_time, v2.start_time)

    v1 = EnergyMarket::Vector.new(Time.now)
    v2 = EnergyMarket::Vector.new(Time.zone.now)
    assert_equal(v1.start_time, v2.start_time)
  end



  def test_initialize_start_time_flooring
    v1 = EnergyMarket::Vector.new("2013-05-03 02", @opts)
    v2 = EnergyMarket::Vector.new("2013-05-03 02:53:18", @opts)
    assert_equal(v1.start_time, v2.start_time)

    v2 = EnergyMarket::Vector.new("2013-05-03 02:53", @opts)
    assert_equal(v1.start_time, v2.start_time)

    v1 = EnergyMarket::Vector.new("2013-05-03", @opts)
    v2 = EnergyMarket::Vector.new("2013-05-03 02:53:18", @opts.merge(unit: :day))
    assert_equal(v1.start_time, v2.start_time)

    v1 = EnergyMarket::Vector.new("2013-05-01", @opts)
    v2 = EnergyMarket::Vector.new("2013-05-03 02:53:18", @opts.merge(unit: :month))
    assert_equal(v1.start_time, v2.start_time)

    v1 = EnergyMarket::Vector.new("2013-01-01", @opts)
    v2 = EnergyMarket::Vector.new("2013-05-03 02:53:18", @opts.merge(unit: :year))
    assert_equal(v1.start_time, v2.start_time)
  end



  def test_initialize_start_time_zones
    v1 = EnergyMarket::Vector.new("2013-05-03 02:53:18", :zone => "Rome")
    v2 = EnergyMarket::Vector.new("2013-05-03 01:53:18", :zone => "London")
    assert_equal(v1.start_time, v2.start_time)
    v2 = EnergyMarket::Vector.new("2013-05-03 04:53:18", :zone => "Moscow")
    assert_equal(v1.start_time, v2.start_time)
  end


  def test_cloning
    v1 = EnergyMarket::Vector.new("2013-05-03 02:53:18", :zone => "Rome")
    v1.data(@array)
    assert_not_same(v1.v, v1.clone.v)

    v2 = EnergyMarket::Vector.new("2013-05-03 02:53:18", :zone => "Rome")
    v2.data(@array)
    assert(v1.v.equal? v2.v) # !!! is the same obj
    @array << 6.6
    assert(@array.equal? v1.v) # !!! is the same obj
    assert(@array.equal? v2.v) # !!! is the same obj
  end

  def test_dataize
    arr = [3, 5, 7]
    v1 = EnergyMarket::Vector.new("2013-01-01", @opts)
    v1.data(arr, :day)
    i = 0
    arr.each do |v|
      24.times do
        assert_equal(v, v1.v[i])
        i += 1
      end
    end

    arr = [3, 5, 7]
    v1 = EnergyMarket::Vector.new("2013-04-01", @opts)
    v1.data(arr, :month)
    i = 0
    month_days = [30, 31, 30]
    arr.each_with_index do |v, j|
      (month_days[j]*24).times do
        assert_equal(v, v1.v[i])
        i += 1
      end
    end

    v = 3.5
    v1 = EnergyMarket::Vector.new("2013-01-01", @opts)
    v1.data(v, :year)
    assert_equal(8760, v1.v.size)
    v1.v.each do |e|
      assert_equal(v, e)
    end

    v = 4.5
    v1 = EnergyMarket::Vector.new("2013-05-01", @opts)
    v1.data(v, :year) # set values to v to the end of year
    n = (Time.parse("2014-01-01") - Time.parse("2013-05-01"))/3600 
    assert_equal(n.to_i, v1.v.size)
    v1.v.each do |e|
      assert_equal(v, e)
    end

  end



end