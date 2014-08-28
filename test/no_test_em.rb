require 'test/unit'
require 'energy_market'

class TestOne < Test::Unit::TestCase

  def setup
    @array = [3, 6, 7, -34, 5.5, 0, 8]
    @vector = EnergyMarket::Vector.new("2013-01-01", "Rome").data(@array)
  end

  def test_set_all_to
    v = 1.2
    @vector.set_all_to(v)
    assert_equal(Array.new(@array.size, v), @vector.v)
  end

  def test_start_time
    assert_equal(Time.parse("2013-01-01 00:00:00"), @vector.start_time)

    # test time floor
    zone = "Rome" # +1
    vector2 = EnergyMarket::Vector.new("2013-01-01 00:23:45", zone).data(@array)
    assert_equal(@vector.start_time, vector2.start_time)

    # another timezone!
    zone = "London" # 0
    vector3 = EnergyMarket::Vector.new("2013-01-01 00:23:45", zone).data(@array)
    assert_not_equal(Time.parse("2013-01-01 00:00:00"), vector3.start_time)
    assert_not_equal(@vector.start_time, vector3.start_time)

    # another timezone!
    zone = "Helsinki" # +2
    vector4 = EnergyMarket::Vector.new("2013-01-01 01:23:45", zone).data(@array)
    assert_equal(Time.parse("2013-01-01 00:00:00"), vector4.start_time)
    assert_equal(@vector.start_time, vector4.start_time)

    # zone = "London"
    # vector3 = EnergyMarket::Vector.new("2013-05-03 16:23:45", zone, '1day').data(@array)
    # assert_not_equal(Time.parse("2013-05-03 00:00:00"), vector3.start_time)

    # vector3 = EnergyMarket::Vector.new("2013-05-03 16:23:45", zone, '1month').data(@array)
    # assert_not_equal(Time.parse("2013-05-01 00:00:00"), vector3.start_time)

    # vector3 = EnergyMarket::Vector.new("2013-05-03 16:23:45", zone, '1year').data(@array)
    # assert_not_equal(Time.parse("2013-01-01 00:00:00"), vector3.start_time)

    # vector3 = EnergyMarket::Vector.new("2013-05-03 16:23:45", zone, '15minutes').data(@array)
    # assert_not_equal(Time.parse("2013-05-03 16:15:00"), vector3.start_time)

    assert_nothing_raised do
      EnergyMarket::Vector.new("13")
      EnergyMarket::Vector.new("2013")
      EnergyMarket::Vector.new("2013-01")
    end
    assert_raise ArgumentError do
      EnergyMarket::Vector.new("201301")
    end
  end

  def test_end_time
    assert_equal(Time.parse("2013-01-01 00:00:00")+(@array.size-1).hours, @vector.end_time)
    assert_equal(Time.parse("2014-01-01 00:00:00")-1.hour, @vector.until_the_end_of_the_year.end_time)
  end

  def test_size
    assert_equal(@array.size, @vector.size)
    assert_equal(8760, @vector.until_the_end_of_the_year.size)
  end

  def test_month_data
    size = 12
    start = 23
    array = (start...(start+size)).to_a
    vector_1 = EnergyMarket::Vector.new("2013-01-01", "Rome").data(array, 'month')
    time = vector_1.start_time
    vector_1.v.each do |value|
      assert_equal(array[time.month-vector_1.start_time.month], value)
      time += 1.hour
    end
  end

  def test_day_data
    size = 365
    start = 17
    array = (start...(start+size)).to_a
    vector_1 = EnergyMarket::Vector.new("2013-01-01", "Rome").data(array, 'day')
    time = vector_1.start_time
    vector_1.v.each do |value|
      assert_equal(array[time.yday-vector_1.start_time.yday], value)
      time += 1.hour
    end
  end

  def test_year_data
    size = 1
    start = 41
    array = (start...(start+size)).to_a
    vector_1 = EnergyMarket::Vector.new("2013-01-01", "Rome").data(array, 'year')
    time = vector_1.start_time
    vector_1.v.each do |value|
      assert_equal(array[0], value)
    end

    vector_2 = EnergyMarket::Vector.new("2013-01-01", "Rome").data(5.3, 'year')
    time = vector_2.start_time
    vector_2.v.each do |value|
      assert_equal(5.3, value)
    end
  end

   def test_elements_sum
    # all elements
    elements_sum = @array.inject(0.0){|total, n| total + n }
    assert_equal(elements_sum, @vector.sum)
    assert_equal(elements_sum, @vector.sum(:values => :all))
    assert_equal(elements_sum, @vector.sum(:values => :non_zero))

    # i>0 elements 
    elements_sum = @array.inject(0.0){|total, n| total + (n>0 ? n : 0.0) }
    assert_equal(elements_sum, @vector.sum(:values => :positive))

    # i>=0 elements 
    elements_sum = @array.inject(0.0){|total, n| total + (n>=0 ? n : 0.0) }
    assert_equal(elements_sum, @vector.sum(:values => :non_negative))

    # i<0 elements 
    elements_sum = @array.inject(0.0){|total, n| total + (n<0 ? n : 0.0) }
    assert_equal(elements_sum, @vector.sum(:values => :negative))

    # i<=0 elements 
    elements_sum = @array.inject(0.0){|total, n| total + (n<=0 ? n : 0.0) }
    assert_equal(elements_sum, @vector.sum(:values => :non_positive))

    # i==0 elements 
    assert_equal(0.0, @vector.sum(:values => :zero))
  end


  def test_elements_count
    # all elements
    elements_count = @array.inject(0.0){|total, n| total + 1 }
    assert_equal(elements_count, @vector.count)
    assert_equal(elements_count, @vector.count(:values => :all))

    # i>0 elements 
    elements_count = @array.inject(0){|total, n| total + (n>0.0 ? 1 : 0) }
    assert_equal(elements_count, @vector.count(:values => :positive))

    # i>=0 elements 
    elements_count = @array.inject(0){|total, n| total + (n>=0.0 ? 1 : 0) }
    assert_equal(elements_count, @vector.count(:values => :non_negative))

    # i<0 elements 
    elements_count = @array.inject(0){|total, n| total + (n<0.0 ? 1 : 0) }
    assert_equal(elements_count, @vector.count(:values => :negative))

    # i<=0 elements 
    elements_count = @array.inject(0){|total, n| total + (n<=0.0 ? 1 : 0) }
    assert_equal(elements_count, @vector.count(:values => :non_positive))

    # i==0 elements 
    elements_count = @array.inject(0){|total, n| total + (n==0.0 ? 1 : 0) }
    assert_equal(elements_count, @vector.count(:values => :zero))

    # i!=0 elements 
    elements_count = @array.inject(0){|total, n| total + (n!=0.0 ? 1 : 0) }
    assert_equal(elements_count, @vector.count(:values => :non_zero))

  end

  def test_elements_mean
    elements_count = @array.inject(0.0){|total, n| total + 1 }
    elements_sum = @array.inject(0.0){|total, n| total + n }
    assert_equal(elements_sum/elements_count, @vector.mean)
    assert_equal(elements_sum/elements_count, @vector.mean(:values => :all))

    elements_sum = @array.inject(0.0){|total, n| total + (n>0 ? n : 0.0) }
    elements_count = @array.inject(0){|total, n| total + (n>0.0 ? 1 : 0) }
    assert_equal(elements_sum/elements_count, @vector.mean(:values => :positive))

    elements_sum = @array.inject(0.0){|total, n| total + (n>=0 ? n : 0.0) }
    elements_count = @array.inject(0){|total, n| total + (n>=0.0 ? 1 : 0) }
    assert_equal(elements_sum/elements_count, @vector.mean(:values => :non_negative))

    elements_sum = @array.inject(0.0){|total, n| total + (n<0 ? n : 0.0) }
    elements_count = @array.inject(0){|total, n| total + (n<0.0 ? 1 : 0) }
    assert_equal(elements_sum/elements_count, @vector.mean(:values => :negative))

    elements_sum = @array.inject(0.0){|total, n| total + (n<=0 ? n : 0.0) }
    elements_count = @array.inject(0){|total, n| total + (n<=0.0 ? 1 : 0) }
    assert_equal(elements_sum/elements_count, @vector.mean(:values => :non_positive))

    assert_equal(0.0, @vector.mean(:values => :zero))

    elements_sum = @array.inject(0.0){|total, n| total + (n!=0 ? n : 0.0) }
    elements_count = @array.inject(0){|total, n| total + (n!=0.0 ? 1 : 0) }
    assert_equal(elements_sum/elements_count, @vector.mean(:values => :non_zero))


    array = [2.0, 3.4, 5.8, 3.1, 0, 0.0]
    vector = EnergyMarket::Vector.new("2013-01-01", "Rome").data(array)
    assert(vector.mean(:values => :negative).nan?)
    # assert_raise ZeroDivisionError do
    #   vector.mean(:values => :negative)
    # end

  end

  def test_minimum_and_maximum_values
    assert_equal(8, @vector.maximum_value)
    assert_equal(-34, @vector.minimum_value)
  end

  def test_size
    assert_equal(@array.size, @vector.size)
    assert_equal(@array.size, @vector.count)
  end


  def test_round
    array = [2.345643, 3.345643, 5.845643, 3.145643, 0, 0.045643]
    vector = EnergyMarket::Vector.new("2013-01-01", "Rome").data(array)
    assert_equal(array.collect{|e| e.round(2)}, vector.round!(2))
    assert_equal(array.collect{|e| e.round(3)}, vector.round!)
  end


  def test_xy_array
    array = [1, 0, 3, -1, -3, 0.5, 0.0]
    vector = EnergyMarket::Vector.new("2013").data(array)
    dt, vv = vector.xy_array

    aa = []
    array.size.times do |i|
      aa[i] = vector.start_time + i.hours
    end
    assert_equal(aa, dt)
    assert_equal(array, vv)


    arr = array.map{|e| e>0.0 ? e : nil}
    dt, vv = vector.xy_array(:values => :positive)
    aa = []
    array.size.times do |i|
      if arr[i].nil?
        aa[i] = nil
      else
        aa[i] = vector.start_time + i.hours
      end
      
    end
    assert_equal(aa.compact, dt)
    assert_equal(arr.compact, vv)

  end


  def test_is_aligned_with
    @array = [3, 6, 7, -34, 5.5, 0, 8]
    assert(@vector.aligned_with?(EnergyMarket::Vector.new("2013-01-01", "Rome").data(@array)))
    assert(!@vector.aligned_with?(EnergyMarket::Vector.new("2013-01-01", "London").data(@array)))
    assert(!@vector.aligned_with?(EnergyMarket::Vector.new("2013-01-01", "Rome").data(@array[0...-1])))
    assert(!@vector.aligned_with?(EnergyMarket::Vector.new("2013-01-01 03:00:00", "Rome").data(@array)))
    assert(!@vector.aligned_with?(EnergyMarket::Vector.new("2013-01-01 02:00:00", "Rome").data(@array[0...-2])))
  end

  def test_align_with
    # Case 1:  v1:    |----------|
    #          v2:  |----------|
    arr_1 = (0...10).to_a
    vec_1 = EnergyMarket::Vector.new("2013-01-01 03:00:00").data(arr_1)
    ost = vec_1.start_time.clone
    arr_2 = (0...10).to_a
    vec_2 = EnergyMarket::Vector.new("2013-01-01 01:00:00").data(arr_2)
    vec_1.align_with(vec_2)
    assert_equal(ost, vec_1.start_time)
    assert_equal(8, vec_1.size)


    # Case 2:  v1:  |----------|
    #          v2:    |----------|
    arr_1 = (0...10).to_a
    vec_1 = EnergyMarket::Vector.new("2013-01-01 01:00:00").data(arr_1)
    arr_2 = (0...10).to_a
    vec_2 = EnergyMarket::Vector.new("2013-01-01 03:00:00").data(arr_2)
    vec_1.align_with(vec_2)
    assert_equal(vec_2.start_time, vec_1.start_time)
    assert_equal(8, vec_1.size)

    # Case 3:  v1:  |----------------|
    #          v2:    |----------|
    arr_1 = (0...20).to_a
    vec_1 = EnergyMarket::Vector.new("2013-01-01 01:00:00").data(arr_1)
    arr_2 = (0...10).to_a
    vec_2 = EnergyMarket::Vector.new("2013-01-01 03:00:00").data(arr_2)
    vec_1.align_with(vec_2)
    assert_equal(vec_2.start_time, vec_1.start_time)
    assert_equal(10, vec_1.size)

    # Case 4:  v1:    |----------|
    #          v2:  |-----------------|
    arr_1 = (0...10).to_a
    vec_1 = EnergyMarket::Vector.new("2013-01-01 03:00:00").data(arr_1)
    ost = vec_1.start_time.clone
    arr_2 = (0...20).to_a
    vec_2 = EnergyMarket::Vector.new("2013-01-01 01:00:00").data(arr_2)
    vec_1.align_with(vec_2)
    assert_equal(ost, vec_1.start_time)
    assert_equal(10, vec_1.size)

  end

  def test_binary_artmetical_operations
    # sum
    arr_1 = (0...10).to_a
    vec_1 = EnergyMarket::Vector.new("2013-01-01 01:00:00").data(arr_1)
    arr_2 = (0...10).to_a
    vec_2 = EnergyMarket::Vector.new("2013-01-01 03:00:00").data(arr_2)
    vec_3 = vec_1+vec_2
    assert_equal([2,4,6,8,10,12,14,16], vec_3.v)
    vec_3 = vec_3+2.0
    assert_equal([4,6,8,10,12,14,16,18], vec_3.v)


    # subtraction
    arr_1 = (0...10).to_a
    vec_1 = EnergyMarket::Vector.new("2013-01-01 01:00:00").data(arr_1)
    arr_2 = (0...10).to_a
    vec_2 = EnergyMarket::Vector.new("2013-01-01 03:00:00").data(arr_2)
    vec_3 = vec_1-vec_2
    assert_equal([2,2,2,2,2,2,2,2], vec_3.v)
    vec_3 = vec_3-12.0
    assert_equal([-10,-10,-10,-10,-10,-10,-10,-10], vec_3.v)

    # multiplication
    arr_1 = (0...10).to_a
    vec_1 = EnergyMarket::Vector.new("2013-01-01 01:00:00").data(arr_1)
    arr_2 = (0...10).to_a
    vec_2 = EnergyMarket::Vector.new("2013-01-01 03:00:00").data(arr_2)
    vec_3 = vec_1*vec_2
    # [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
    #       [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
    aa = [0, 3, 8, 15, 24, 35, 48, 63]
    assert_equal(aa, vec_3.v)
    k = 2.34
    vec_3 = vec_3 * k
    aa.collect!{|e| e*k}
    assert_equal(aa, vec_3.v)

    # ratio
    arr_1 = (0...10).to_a
    vec_1 = EnergyMarket::Vector.new("2013-01-01 01:00:00").data(arr_1)
    arr_2 = (0...10).to_a
    vec_2 = EnergyMarket::Vector.new("2013-01-01 03:00:00").data(arr_2)
    vec_3 = vec_1/vec_2
    aa = [1.0/0, 3.0, 2.0, 5.0/3, 1.5, 1.4, 4.0/3, 9.0/7]
    assert_equal(aa, vec_3.v)
    vec_3 = vec_3 / k
    aa.collect!{|e| e/k}
    assert_equal(aa, vec_3.v)

  end


  def test_max_and_min
    arr_1 = [3.1, 2, 0, 8.6, -1.1, 0.8, -7.7, -2.3, 1, -3]
    vec_1 = EnergyMarket::Vector.new("2013-01-01 01:00:00").data(arr_1)
    arr_2 = [3.1, 2, 0, 8.6, -1.1, 0.8, -7.7, -2.3, 1, -3]
    vec_2 = EnergyMarket::Vector.new("2013-01-01 03:00:00").data(arr_2)
    # [3.1, 2,   0, 8.6, -1.1,  0.8, -7.7, -2.3,    1, -3]
    #         [3.1,   2,    0,  8.6, -1.1,  0.8, -7.7, -2.3,   1,  -3]
    vec_3 = vec_1.max(vec_2)
    assert_equal([3.1, 8.6, 0, 8.6, -1.1, 0.8, 1, -2.3], vec_3.v)

    vec_3 = vec_1.max
    assert_equal([3.1, 2, 0, 8.6, 0.0, 0.8, 0.0, 0.0, 1, 0.0], vec_3.v)

    vec_3 = vec_1.max(1.1)
    assert_equal([3.1, 2, 1.1, 8.6, 1.1, 1.1, 1.1, 1.1, 1.1, 1.1], vec_3.v)


    vec_3 = vec_1.min(vec_2)
    assert_equal([0, 2, -1.1, 0.8, -7.7, -2.3, -7.7, -3], vec_3.v)

    vec_3 = vec_1.min
    assert_equal([0.0, 0.0, 0, 0.0, -1.1, 0.0, -7.7, -2.3, 0.0, -3], vec_3.v)

    vec_3 = vec_1.min(1.1)
    assert_equal([1.1, 1.1, 0, 1.1, -1.1, 0.8, -7.7, -2.3, 1, -3], vec_3.v)
  end



  # def test_sum
  #   @array = [3, 6, 7, -34, 5.5, 0, 8]
  #   array = [3.1, 2, 0, 8.6, -1.1, 0.8, -7.7]
  #   sum_array = []
  #   array.size.times do |i|
  #     sum_array[i] = @array[i] + array[i]
  #   end
  #   vector = EnergyMarket::Vector.new("2013-01-01", "Rome").data(array).sum
  #   assert_equal(sum_array, vector.v)
  # end
end

