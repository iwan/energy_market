require 'test/unit'
require 'energy_market'
require 'time'

class TestVector < Test::Unit::TestCase
  
  def setup
    Time.zone = "Rome"
    @array = [3, 6, 7, -34, 5.5, 0, 8]
  end

  def test_zero_vector
    a = [2, 3, 5, 7, 11]

    v1 = EnergyMarket::Vector.new
    v2 = EnergyMarket::Vector.new("2013-01-01").data(a)
    v12 = v1+v2
    assert_equal(v2.start_time, v12.start_time)
    assert_equal(a, v12.v)

    v1 = EnergyMarket::Vector.new
    v2 = EnergyMarket::Vector.new("2013-01-01").data(a)
    v12 = v1*v2
    assert_equal(v2.start_time, v12.start_time)
    assert_equal(a, v12.v)

  end

  def test_initialize_start_time
    v1 = EnergyMarket::Vector.new("2013-01-01 00:00:00")
    v2 = EnergyMarket::Vector.new("2013-01-01 00:00")
    assert_equal(v1.start_time, v2.start_time)

    v2 = EnergyMarket::Vector.new("2013-01-01 00")
    assert_equal(v1.start_time, v2.start_time)

    v2 = EnergyMarket::Vector.new("2013-01-01")
    assert_equal(v1.start_time, v2.start_time)

    v2 = EnergyMarket::Vector.new("2013-01")
    assert_equal(v1.start_time, v2.start_time)

    v2 = EnergyMarket::Vector.new("2013")
    assert_equal(v1.start_time, v2.start_time)

    Time.zone = "London"
    v2 = EnergyMarket::Vector.new("2013")
    assert_not_equal(v2.start_time, v1.start_time)

    Time.zone = "Rome"
    v1 = EnergyMarket::Vector.new
    # v2 = EnergyMarket::Vector.new(Time.zone.now.strftime("%Y-%m-%d %H"))
    assert_equal(nil, v1.start_time)

    # v1 = EnergyMarket::Vector.new(Time.now)
    # v2 = EnergyMarket::Vector.new(Time.zone.now)
    # assert_equal(v1.start_time, v2.start_time)
  end



  def test_initialize_start_time_flooring
    v1 = EnergyMarket::Vector.new("2013-05-03 02")
    v2 = EnergyMarket::Vector.new("2013-05-03 02:53:18")
    assert_equal(v1.start_time, v2.start_time)

    v2 = EnergyMarket::Vector.new("2013-05-03 02:53")
    assert_equal(v1.start_time, v2.start_time)

    v1 = EnergyMarket::Vector.new("2013-05-03")
    v2 = EnergyMarket::Vector.new("2013-05-03 02:53:18", {unit: :day})
    assert_equal(v1.start_time, v2.start_time)

    v1 = EnergyMarket::Vector.new("2013-05-01")
    v2 = EnergyMarket::Vector.new("2013-05-03 02:53:18", {unit: :month})
    assert_equal(v1.start_time, v2.start_time)

    v1 = EnergyMarket::Vector.new("2013-01-01")
    v2 = EnergyMarket::Vector.new("2013-05-03 02:53:18", {unit: :year})
    assert_equal(v1.start_time, v2.start_time)
  end



  def test_initialize_start_time_zones
    v1 = EnergyMarket::Vector.new("2013-05-03 02:53:18", :zone => "Rome")
    v2 = EnergyMarket::Vector.new("2013-05-03 01:53:18", :zone => "London")
    assert_equal(v1.start_time, v2.start_time)
    v2 = EnergyMarket::Vector.new("2013-05-03 04:53:18", :zone => "Moscow")
    assert_equal(v1.start_time, v2.start_time)
    puts Time.zone
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
    v1 = EnergyMarket::Vector.new("2013-05-01")
    v1.data(arr, :day)
    i = 0
    arr.each do |v|
      24.times do
        assert_equal(v, v1.v[i])
        i += 1
      end
    end

    arr = [3, 5, 7]
    v1 = EnergyMarket::Vector.new("2013-04-01")
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
    v1 = EnergyMarket::Vector.new("2013-01-01")
    v1.data(v, :year)
    assert_equal(8760, v1.v.size)
    v1.v.each do |e|
      assert_equal(v, e)
    end

    v = 4.5
    v1 = EnergyMarket::Vector.new("2013-05-01")
    v1.data(v, :year) # set values to v to the end of year
    n = (Time.zone.parse("2014-01-01") - Time.zone.parse("2013-05-01"))/3600 
    assert_equal(n.to_i, v1.v.size)
    v1.v.each do |e|
      assert_equal(v, e)
    end

  end

  def test_set_all_to
    v = 13.2
    arr = [3, 5, 7]
    v1 = EnergyMarket::Vector.new("2013-05-01")
    v1.data(arr, :day)
    v1.set_all_to(v)
    assert_equal(24*arr.size, v1.size)
    v1.v.each do |e|
      assert_equal(v, e)
    end
  end


  def test_sum
    a = [0, 1.2, 3.7, -3.9, 9.735, -0.432]
    v = EnergyMarket::Vector.new("2013").data(a)
    assert_equal(1.2+3.7-3.9+9.735-0.432, v.sum)
    assert_equal(1.2+3.7+9.735, v.sum(:values => :positive))
    assert_equal(1.2+3.7+9.735, v.sum(:values => :not_negative))
    assert_equal(-3.9-0.432, v.sum(:values => :negative))
    assert_equal(-3.9-0.432, v.sum(:values => :not_positive))
    assert_equal(1.2+3.7-3.9+9.735-0.432, v.sum(:values => :all))
    assert_equal(1.2+3.7-3.9+9.735-0.432, v.sum(:values => :not_zero))
    assert_raise ArgumentError do
       v.sum(:values => :nope) 
    end

    v2 = EnergyMarket::Vector.new("2013")
    assert_equal(0.0, v2.sum)
  end

  def test_count
    a = [0, 1.2, 3.7, -3.9, 9.735, -0.432]
    v = EnergyMarket::Vector.new("2013").data(a)
    assert_equal(a.size, v.count)
    assert_equal(3, v.count(:values => :positive))
    assert_equal(4, v.count(:values => :not_negative))
    assert_equal(2, v.count(:values => :negative))
    assert_equal(3, v.count(:values => :not_positive))
    assert_equal(6, v.count(:values => :all))
    assert_equal(5, v.count(:values => :not_zero))
    assert_raise ArgumentError do
      v.count(:values => :nope) 
    end

    v2 = EnergyMarket::Vector.new("2013")
    assert_equal(0.0, v2.count)
  end

  def assert_close_to(f1, f2, delta=0.0001)
    diff = (f1-f2).abs
    diff<delta
  end

  def test_mean
    a = [0, 10.2, 3.4, -4.3, 8.9, -0.2]
    v = EnergyMarket::Vector.new("2013").data(a)
    assert_close_to(3.0, v.mean)
    assert_close_to((10.2+3.4+8.9)/3.0, v.mean(:values => :positive))
    assert_close_to((0+10.2+3.4-4.3+8.9-0.2)/4.0, v.mean(:values => :not_negative))
    assert_close_to((-4.3-0.2)/2.0, v.mean(:values => :negative))
    assert_close_to((0-4.3-0.2)/3.0, v.mean(:values => :not_positive))
    assert_close_to(3.0, v.mean(:values => :all))
    assert_close_to((10.2+3.4-4.3+8.9-0.2)/5.0, v.mean(:values => :not_zero))
    assert_raise ArgumentError do
      v.mean(:values => :nope) 
    end

    v2 = EnergyMarket::Vector.new("2013")
    assert_equal(nil, v2.mean)
  end  

  def test_minimum_value
    a = [0, 10.2, 3.4, -4.3, 8.9, -0.2, nil]
    v = EnergyMarket::Vector.new("2013").data(a)
    assert_equal(-4.3, v.minimum_value)

    v2 = EnergyMarket::Vector.new("2013")
    assert_equal(nil, v2.minimum_value)
  end

  def test_maximum_value
    a = [0, 10.2, 3.4, -4.3, 8.9, -0.2, nil]
    v = EnergyMarket::Vector.new("2013").data(a)
    assert_equal(10.2, v.maximum_value)

    v2 = EnergyMarket::Vector.new("2013")
    assert_equal(nil, v2.maximum_value)
  end

  def test_round
    a = [0, 10.244321, 3.000001, -4.500001, -1.75326, nil]
    v = EnergyMarket::Vector.new("2013").data(a)
    v.round!(2)
    assert_equal([0, 10.24, 3.0, -4.50, -1.75, nil], v.v)

    v2 = EnergyMarket::Vector.new("2013")
    v2.round!(3)
    assert_equal([], v2.v)
  end

  # TODO
  def test_xy_array
    a = [0, 10.244321, 3.000001, -4.500001, -1.75326, nil]
    v = EnergyMarket::Vector.new("2013").data(a)

  end

  def test_end_time
    a = [1,2,3,4,5,6]
    v = EnergyMarket::Vector.new("2013").data(a)
    t = Time.zone.parse("2013-01-01 00:00:00") + (a.size-1).hours
    assert_equal(t, v.end_time)

    # empty array
    v = EnergyMarket::Vector.new("2013")
    assert_nil(v.end_time)

    # one element array
    v = EnergyMarket::Vector.new("2013").data([4])
    assert_equal(v.start_time, v.end_time)
  end

  def test_aligned_with
    # same timezone
    a1 = [0, 10.244321, 3.000001, -4.500001, -1.75326, nil]
    v1 = EnergyMarket::Vector.new("2013").data(a1)
    a2 = [0, 0, 0, 0, 1, nil]
    v2 = EnergyMarket::Vector.new("2013").data(a2)
    assert(v1.aligned_with? v2)

    # different timezone
    a1 = [0, 10.244321, 3.000001, -4.500001, -1.75326, nil]
    v1 = EnergyMarket::Vector.new("2013", :zone => "Rome").data(a1)
    a2 = [0, 0, 0, 0, 1, nil]
    v2 = EnergyMarket::Vector.new("2013", :zone => "London").data(a2)
    assert(!v1.aligned_with?(v2))
  end


  def test_align_with
    # [1,2,3,4,5,6]
    # [1,2,3,4,5]
    # -------------
    # [1,2,3,4,5]
    v1 = EnergyMarket::Vector.new("2013").data([1,2,3,4,5,6])
    v2 = EnergyMarket::Vector.new("2013").data([1,2,3,4,5])
    v1.align_with(v2)
    assert_equal(5, v1.size)
    assert_equal(v1.start_time, v2.start_time)
    assert_equal(v1.end_time, v2.end_time)

    # [1,2,3,4,5]
    # [1,2,3,4,5,6]
    # -------------
    # [1,2,3,4,5]
    v1 = EnergyMarket::Vector.new("2013").data([1,2,3,4,5])
    v2 = EnergyMarket::Vector.new("2013").data([1,2,3,4,5,6])
    v1.align_with(v2)
    assert_equal(5, v1.size)
    assert_equal(v1.start_time, v2.start_time)
    assert_not_equal(v1.end_time, v2.end_time)

    # [1,2,3,4,5]
    # [1,2,3,4,5]
    # -------------
    # [1,2,3,4,5]
    v1 = EnergyMarket::Vector.new("2013").data([1,2,3,4,5])
    v2 = EnergyMarket::Vector.new("2013").data([1,2,3,4,5])
    v1.align_with(v2)
    assert_equal(5, v1.size)
    assert_equal(v1.start_time, v2.start_time)
    assert_equal(v1.end_time, v2.end_time)


    # [1, 1, 1, 1, 1]
    # [2, 2, 2, 2, 2, 2]
    # [0, 0, 0]
    v1 = EnergyMarket::Vector.new("2013").data([1,2,3,4,5,6])
    v2 = EnergyMarket::Vector.new("2013").data([1,2,3,4,5])



    # same start_time, different array size
    v1 = EnergyMarket::Vector.new("2013").data([1,2,3,4,5,6])
    v2 = EnergyMarket::Vector.new("2013").data([1,2,3,4,5])
    assert_not_equal(v1.end_time, v2.end_time)
    v1.align_with(v2)
    assert_equal(5, v1.size)
    assert_equal(v1.end_time, v2.end_time)

    v1 = EnergyMarket::Vector.new("2013").data([1,2,3,4,5,6])
    v1.align_with(EnergyMarket::Vector.new("2013").data([0]))
    assert_equal(1, v1.size)

    v1 = EnergyMarket::Vector.new("2013").data([1,2,3,4,5,6])
    v1.align_with(EnergyMarket::Vector.new("2013"))
    assert_equal(0, v1.size)


    # different start_time (1)
    a1 = [0, 10.244321, 3.000001, -4.500001, -1.75326, nil]
    v1 = EnergyMarket::Vector.new("2013-01-01 00:00").data(a1)
    a2 = [0, 0, nil]
    v2 = EnergyMarket::Vector.new("2013-01-01 02:00").data(a2)

    assert_not_equal(v1.start_time, v2.start_time)
    assert_not_equal(v1.end_time, v2.end_time)
    assert_not_equal(v1.size, v2.size)

    v1.align_with(v2)
    assert_equal(v1.start_time, v2.start_time)
    assert_equal(v1.end_time, v2.end_time)
    assert_equal(v1.size, v2.size)

    # different start_time (2)
    # [1, 1, 1]
    #       [2, 2, 2, 2, 2, 2]
    #       [0]
    a1 = [1, 2, nil]
    v1 = EnergyMarket::Vector.new("2013-01-01 00:00").data(a1)
    a2 = [1,2,3,4,5,6]
    v2 = EnergyMarket::Vector.new("2013-01-01 02:00").data(a2)

    assert_not_equal(v1.start_time, v2.start_time)
    assert_not_equal(v1.end_time, v2.end_time)
    assert_not_equal(v1.size, v2.size)

    v1.align_with(v2)
    assert_equal(v1.start_time, v2.start_time)
    assert_not_equal(v1.end_time, v2.end_time)
    assert_equal(1, v1.size)

    # different start_time (3)
    #       [1, 1, 1]
    # [2, 2, 2, 2, 2, 2]
    #       [0, 0, 0]
    a1 = [0, 0, nil]
    v1 = EnergyMarket::Vector.new("2013-01-01 02:00").data(a1)
    a2 = [0, 10.244321, 3.000001, -4.500001, -1.75326, nil]
    v2 = EnergyMarket::Vector.new("2013-01-01 00:00").data(a2)

    assert_not_equal(v1.start_time, v2.start_time)
    assert_not_equal(v1.end_time, v2.end_time)
    assert_not_equal(v1.size, v2.size)

    v1.align_with(v2)
    assert_not_equal(v1.start_time, v2.start_time)
    assert_not_equal(v1.end_time, v2.end_time)
    assert_equal(3, v1.size)


    v1 = EnergyMarket::Vector.new("2013-01-01").data([2, 3, 5, 7, 11])
    v2 = EnergyMarket::Vector.new("2013-01-02").data([2, 3, 5, 7, 11])
    v1.align_with(v2)


    v1 = EnergyMarket::Vector.new("2013-01-01 02:00")
    a = [0, 10.244321, 3.000001, -4.500001, -1.75326, nil]
    v2 = EnergyMarket::Vector.new("2013-01-01 00:00").data(a)
    v1.align_with(v2)
    assert_equal(0, v1.size)
    assert_equal(2, v1.start_time.hour)

    v1 = EnergyMarket::Vector.new("2013").data([1,2,3])
    v2 = EnergyMarket::Vector.new("2013")
    v1.align_with(v2)
  end

  def test_size
    v1 = EnergyMarket::Vector.new("2013-01-01 02:00")
    assert_equal(0, v1.size)

    a2 = [0, 10.244321, 3.000001, -4.500001, -1.75326, nil]
    v2 = EnergyMarket::Vector.new("2013-01-01 00:00").data(a2)
    assert_equal(a2.size, v2.size)
  end

  def test_until_the_end_of_the_year
    a1 = [2, 3, 5, 7, 11]
    v1 = EnergyMarket::Vector.new("2013-12-01").data(a1)
    v1.until_the_end_of_the_year
    v = v1.v
    assert_equal(24*31, v.size)
    assert_equal(a1+[0.0, 0.0], v[0...7])
    
    v1 = EnergyMarket::Vector.new("2013")
    v1.until_the_end_of_the_year(1.0)
    assert_equal(8760, v1.size)
    assert_equal(8760, v1.sum)
  end


  def operation_w_scalar(operation, k)
    a = [2, 3, 5, 7, 11]
    v = EnergyMarket::Vector.new("2013-01-01").data(a)
    r = v.send(operation, k)
    assert_equal(a.collect{|e| e.to_f.send(operation, k)}, r.v)
  end


  def test_plus
    a1 = [2, 3, 5, 7, 11]
    v1 = EnergyMarket::Vector.new("2013-01-01").data(a1)
    a2 = [2, 3, 5, 7, 11]
    v2 = EnergyMarket::Vector.new("2013-01-01 02:00").data(a2)

    r12 = v1+v2
    assert_equal([5+2, 7+3, 11+5], r12.v)

    operation_w_scalar(:+, 5)
    operation_w_scalar(:+, 5.8)

    v3 = EnergyMarket::Vector.new("2013-01-01")
    r13 = v1+v3
    assert_equal([], r13.v)

    r31 = v3+v1
    assert_equal([], r31.v)


    v1 = EnergyMarket::Vector.new("2013-01-01").data([2, 3, 5, 7, 11])
    v2 = EnergyMarket::Vector.new("2013-01-02").data([2, 3, 5, 7, 11])
    r12 = v1+v2
    assert_equal([], r12.v)
  end


  def test_minus
    a1 = [2, 3, 5, 7, 11]
    v1 = EnergyMarket::Vector.new("2013-01-01").data(a1)
    a2 = [2, 3, 5, 7, 11]
    v2 = EnergyMarket::Vector.new("2013-01-01 02:00").data(a2)

    r12 = v1-v2
    assert_equal([5-2, 7-3, 11-5], r12.v)

    operation_w_scalar(:-, 5)
    operation_w_scalar(:-, 5.8)


    v3 = EnergyMarket::Vector.new("2013-01-01")
    r13 = v1-v3
    assert_equal([], r13.v)

    r31 = v3-v1
    assert_equal([], r31.v) 

    v1 = EnergyMarket::Vector.new("2013-01-01").data([2, 3, 5, 7, 11])
    v2 = EnergyMarket::Vector.new("2013-01-02").data([2, 3, 5, 7, 11])
    r12 = v1+v2
    assert_equal([], r12.v)
  end


  def test_multiply
    a1 = [2, 3, 5, 7, 11]
    v1 = EnergyMarket::Vector.new("2013-01-01").data(a1)
    a2 = [2, 3, 5, 7, 11]
    v2 = EnergyMarket::Vector.new("2013-01-01 02:00").data(a2)

    r12 = v1*v2
    assert_equal([5*2, 7*3, 11*5], r12.v)

    operation_w_scalar(:*, 5)
    operation_w_scalar(:*, 5.8)

    v3 = EnergyMarket::Vector.new("2013-01-01")
    r13 = v1*v3
    assert_equal([], r13.v)

    r31 = v3*v1
    assert_equal([], r31.v) 

    v1 = EnergyMarket::Vector.new("2013-01-01").data([2, 3, 5, 7, 11])
    v2 = EnergyMarket::Vector.new("2013-01-02").data([2, 3, 5, 7, 11])
    r12 = v1*v2
    assert_equal([], r12.v)
  end


  def test_divided_by
    a1 = [2, 3, 5, 7, 11]
    v1 = EnergyMarket::Vector.new("2013-01-01").data(a1)
    a2 = [2, 3, 5, 7, 11]
    v2 = EnergyMarket::Vector.new("2013-01-01 02:00").data(a2)

    r12 = v1/v2
    assert_equal([5.0/2, 7.0/3, 11.0/5], r12.v)

    operation_w_scalar(:/, 5)
    operation_w_scalar(:/, 5.8)

    v3 = EnergyMarket::Vector.new("2013-01-01")
    r13 = v1/v3
    assert_equal([], r13.v)

    r31 = v3/v1
    assert_equal([], r31.v) 

    v1 = EnergyMarket::Vector.new("2013-01-01").data([2, 3, 5, 7, 11])
    v2 = EnergyMarket::Vector.new("2013-01-02").data([2, 3, 5, 7, 11])
    r12 = v1/v2
    assert_equal([], r12.v)
  end

  def test_value
    a1 = [2, 3, 5, 7, 11]
    v1 = EnergyMarket::Vector.new("2013-01-01").data(a1)
    a1.each_with_index do |e, i|
      assert_equal(e, v1.value(i))
    end

    assert_nil(EnergyMarket::Vector.new("2013-01-01").value(0))
  end

  def test_first_values
    a1 = [2, 3, 5, 7, 11]
    v1 = EnergyMarket::Vector.new("2013-01-01").data(a1)
    a1.size.times do |i|
      assert_equal(a1[0, i], v1.first_values(i))
    end

    assert_equal([], EnergyMarket::Vector.new("2013-01-01").first_values(2))
  end

  def test_set_value
    a1 = [2, 3, 5, 7, 11]
    v1 = EnergyMarket::Vector.new("2013-01-01").data(a1)
    v1.set_value(0, 1000)
    assert_equal(1000, v1.v[0])

    v2 = EnergyMarket::Vector.new("2013-01-01")
    v2.set_value(2, 1000)
    assert_equal(1000, v2.v[2])
    assert_equal(1000, v2.value(2))
    assert_nil(v2.value(0))
    assert_nil(v2.value(1))
  end

  def test_min_max
    v1 = EnergyMarket::Vector.new("2013").data([1,2  ,3,4,5,6])
    v2 = EnergyMarket::Vector.new("2013").data([4,0.5,3,9,0,7])
    assert_equal([1,0.5,3,4,0,6], v1.min(v2).v)
    assert_equal([4,2,3,9,5,7], v1.max(v2).v)
  end
end