using Test
import Pkg

# Allow running this file directly from `test/` as well as via `Pkg.test()`.
# - Under `Pkg.test()`, the package is already available in the test environment.
# - If you `Pkg.activate("test"); include("runtests.jl")`, we develop the parent package.
if Base.find_package("TimeSamplers") === nothing
    Pkg.develop(Pkg.PackageSpec(path=joinpath(@__DIR__, "..")))
    Pkg.instantiate()
end

@testset "TimeSamplers.jl" begin
    using TimeSamplers
    using Dates
    using Statistics

    @testset "get_TimeSampler" begin
        @test get_TimeSampler("TimeDay") isa TimeDay
        @test get_TimeSampler(:TimeMonth) isa TimeMonth
    end

    @testset "create_TimeSampler basics" begin
        dates = collect(Date(2000, 1, 1):Day(1):Date(2000, 1, 5))

        day_samplers = create_TimeSampler(dates, TimeDay())
        @test length(day_samplers) == 1
        @test day_samplers[1] isa TimeSample
        @test length(day_samplers[1].indices) == length(dates) # daily groups -> one per day

        month_samplers = create_TimeSampler(dates, "TimeMonth")
        @test length(month_samplers) == 1
        @test month_samplers[1] isa TimeSample
        @test length(month_samplers[1].indices) == 1 # all within one month

        anomaly_samplers = create_TimeSampler(dates, TimeDayAnomaly())
        @test length(anomaly_samplers) == 2
        @test all(x -> x isa TimeSample, anomaly_samplers)
    end

    @testset "time_sampling / do_time_sampling" begin
        dates = collect(Date(2000, 1, 1):Day(1):Date(2000, 1, 5))
        data = [1.0, 2.0, 3.0, 4.0, 5.0]

        # NoDiff: daily sampler is effectively identity for daily input
        daily = create_TimeSampler(dates, TimeDay())
        @test time_sampling(data, daily[1]) == data
        @test do_time_sampling(data, daily) == data
        @test do_time_sampling(data, daily, TimeNoDiff()) == data

        # Monthly aggregation: mean over all samples
        monthly = create_TimeSampler(dates, TimeMonth())
        @test time_sampling(data, monthly[1]) == [Statistics.mean(data)]

        # Diff (anomaly): daily - mean(all)
        anomaly = create_TimeSampler(dates, TimeDayAnomaly())
        @test do_time_sampling(data, anomaly, TimeDiff()) == data .- Statistics.mean(data)

        # every sampler knows the length of its time axis and rejects other data
        @test all(s -> s.n_time == length(dates), anomaly)
        @test_throws ErrorException time_sampling(data[1:4], daily[1])
        @test_throws ErrorException time_sampling([data; 6.0], monthly[1])
        @test_throws ErrorException do_time_sampling(data[1:4], anomaly, TimeDiff())
        all_years = create_TimeSampler(dates, TimeAllYears())
        @test do_time_sampling(data, all_years, TimeIndexed()) == data
        @test_throws ErrorException do_time_sampling([data; 6.0], all_years, TimeIndexed())
    end

    @testset "selections with TimeIndexed" begin
        dates = collect(Date(2000, 1, 1):Day(1):Date(2002, 12, 31))
        years = year.(dates)
        data = collect(1.0:length(dates))
        mat = hcat(data, 2 .* data)
        year_block(y) = data[years .== y]
        select(x, method) = do_time_sampling(x, create_TimeSampler(dates, method), TimeIndexed())

        @test select(data, TimeAllYears()) == data
        @test select(mat, TimeAllYears()) == mat
        @test select(data, TimeFirstYear()) == year_block(2000)
        @test select(mat, TimeFirstYear()) == mat[years .== 2000, :]

        random_year = select(data, TimeRandomYear())
        @test any(y -> random_year == year_block(y), 2000:2002)

        # whole years in a shuffled order, each kept in time order
        shuffled = select(data, TimeShuffleYears())
        @test sort(shuffled) == data
        @test shuffled in [reduce(vcat, year_block.(p)) for p in
            ([2000, 2001, 2002], [2000, 2002, 2001], [2001, 2000, 2002],
             [2001, 2002, 2000], [2002, 2000, 2001], [2002, 2001, 2000])]
        shuffled_mat = select(mat, TimeShuffleYears())
        @test size(shuffled_mat) == size(mat)
        @test shuffled_mat[:, 2] == 2 .* shuffled_mat[:, 1]

        @test_throws ErrorException select(data[1:10], TimeFirstYear())
    end

    @testset "parse_temporal_resolution" begin
        @test parse_temporal_resolution("day") == (1, "day")
        @test parse_temporal_resolution("hour") == (1, "hour")
        @test parse_temporal_resolution("") == (1, "")
        @test parse_temporal_resolution("6-hour") == (6, "hour")
        @test parse_temporal_resolution("1-day") == (1, "day")
        @test parse_temporal_resolution("2-day") == (2, "day")
        @test parse_temporal_resolution("3-month") == (3, "month")
        @test_throws ErrorException parse_temporal_resolution("0-hour")
        @test_throws ErrorException parse_temporal_resolution("-1-hour")
        @test_throws ErrorException parse_temporal_resolution("abc-hour")
        @test_throws ErrorException parse_temporal_resolution("6.5-hour")
        @test_throws ErrorException parse_temporal_resolution("6-6-hour")
        # a count written directly before the unit
        @test parse_temporal_resolution("3hour") == (3, "hour")
        @test parse_temporal_resolution("3h") == (3, "h")
        @test parse_temporal_resolution("30 min") == (30, "min")
        @test parse_temporal_resolution(Symbol("8day")) == (8, "day")
        @test_throws ErrorException parse_temporal_resolution("0hour")
    end

    @testset "get_time_period" begin
        @test get_time_period("6-hour") == Hour(6)
        @test get_time_period("30-sec") == Second(30)
        @test get_time_period("15-min") == Minute(15)
        @test get_time_period(:day) == Day(1)
        @test get_time_period("2-Weeks") == Week(2)
        @test get_time_period("3-mon") == Month(3)
        @test get_time_period("yr") == Year(1)
        @test get_time_period(Hour(3)) == Hour(3)
        @test get_time_period(8, "d") == Day(8)
        @test get_time_period("3hour") == Hour(3)
        @test get_time_period("3h") == Hour(3)
        @test get_time_period("30sec") == Second(30)
        @test get_time_period("8d") == Day(8)
        @test get_time_period("3 mon") == Month(3)
        @test_throws ErrorException get_time_period("15m")
        @test_throws ErrorException get_time_period("6.5h")
        @test_throws ErrorException get_time_period("6-m")
        @test_throws ErrorException get_time_period("fortnight")
        @test_throws ErrorException get_time_period("")
    end

    @testset "TimePeriodSample bins" begin
        # hourly data from 03:00 gives a short first 6-hour bin
        hourly = collect(DateTime(2000, 1, 1, 3):Hour(1):DateTime(2000, 1, 2, 5))
        inds = create_TimeSampler(hourly, "6-hour")[1].indices
        @test inds == [1:3, 4:9, 10:15, 16:21, 22:27]
        @test time_resample_dates(hourly, "6-hour") == DateTime(2000, 1, 1):Hour(6):DateTime(2000, 1, 2)

        # daily data to calendar quarters
        daily = collect(Date(2000, 1, 1):Day(1):Date(2000, 12, 31))
        quarters = create_TimeSampler(daily, "3-month")[1].indices
        @test length.(quarters) == [91, 91, 92, 92]
        @test time_resample_dates(daily, "3-month") == [Date(2000, 1, 1), Date(2000, 4, 1), Date(2000, 7, 1), Date(2000, 10, 1)]

        minutes = collect(DateTime(2000, 1, 1):Minute(1):DateTime(2000, 1, 1, 0, 59))
        @test length.(create_TimeSampler(minutes, "15-min")[1].indices) == fill(15, 4)
        seconds = collect(DateTime(2000, 1, 1):Second(1):DateTime(2000, 1, 1, 0, 1, 59))
        @test length.(create_TimeSampler(seconds, "30-sec")[1].indices) == fill(30, 4)

        # origin :start counts bins from the first date across the year boundary
        two_years = collect(Date(2001, 1, 1):Day(1):Date(2002, 12, 31))
        start_bins = create_TimeSampler(two_years, TimePeriodSample(Day(8); origin=:start))[1].indices
        @test length(start_bins) == cld(length(two_years), 8)
        @test all(==(8), length.(start_bins[1:end-1]))
        @test time_resample_dates(two_years, Day(8); origin=:start)[2] == Date(2001, 1, 9)

        # origin :year restarts at Jan 1 so the last bin of every year is short
        year_bins = create_TimeSampler(two_years, TimePeriodSample("8-day"; origin=:year))[1].indices
        @test length(year_bins) == 2 * 46
        @test length(year_bins[46]) == 5
        @test first(year_bins[47]) == 366
        @test_throws ErrorException TimePeriodSample(Day(8); origin=:bogus)
        @test_throws ErrorException TimePeriodSample(Day(0))
    end

    @testset "TimePeriodSample values and entry points" begin
        dates = collect(Date(2000, 1, 1):Day(1):Date(2000, 1, 6))
        data = collect(1.0:6.0)
        # calendar bins of several days are aligned to the Dates epoch, not the data
        @test time_resample_dates(dates, "2-day")[1] == Date(1999, 12, 31)
        @test do_time_sampling(data, create_TimeSampler(dates, "2-day")) == [1.0, 2.5, 4.5, 6.0]

        by_start = TimePeriodSample(Day(2); origin=:start)
        samplers = create_TimeSampler(dates, by_start)
        @test do_time_sampling(data, samplers) == [1.5, 3.5, 5.5]
        @test do_time_sampling(data, create_TimeSampler(dates, by_start, sum)) == [3.0, 7.0, 11.0]
        @test create_TimeSampler(dates, by_start, mean, true) == [nothing]

        ref = create_TimeSampler(dates, TimePeriodSample(Day(2)))[1].indices
        @test create_TimeSampler(dates, Day(2))[1].indices == ref
        @test create_TimeSampler(dates, "2-day")[1].indices == ref
        @test create_TimeSampler(dates, Symbol("2-day"))[1].indices == ref
        @test create_TimeSampler(dates, TimePeriodSample(2, "day"))[1].indices == ref

        for period in ("2-day", Symbol("2-day"), Day(2))
            @test time_resample(data, dates, period; origin=:start) == [1.5, 3.5, 5.5]
        end
        @test time_resample(data, dates, by_start) == [1.5, 3.5, 5.5]
        mat = hcat(data, 2 .* data)
        expected = hcat([1.5, 3.5, 5.5], [3.0, 7.0, 11.0])
        @test time_resample(mat, dates, by_start) == expected
        @test time_resample(permutedims(mat), dates, by_start; dim=2) == permutedims(expected)
        @test_throws ErrorException time_resample(data[1:5], dates, "2-day")
        @test time_resample_dates(dates, by_start) == [Date(2000, 1, 1), Date(2000, 1, 3), Date(2000, 1, 5)]
    end

    @testset "period anomaly, MSC and IAV" begin
        daily = collect(Date(2001, 1, 1):Day(1):Date(2003, 12, 31))
        data = rand(length(daily))

        msc = time_resample(data, daily, TimePeriodMSC(Day(8)))
        @test length(msc) == 46
        first_bin = [i for y in 0:2 for i in (365y+1):(365y+8)]
        @test msc[1] ≈ mean(data[first_bin])
        @test time_resample_dates(daily, "8-day_msc") == collect(0:45)

        iav_samplers = create_TimeSampler(daily, TimePeriodIAV(Day(8)))
        @test length(iav_samplers[1].indices) == 3 * 46
        @test length(iav_samplers[2].indices) == 3 * 46
        iav = time_resample(data, daily, "8-day_iav")
        @test iav ≈ do_time_sampling(data, iav_samplers, TimeDiff())
        @test length(time_resample_dates(daily, "8-day_iav")) == length(iav)
        # with equal bin sizes every position of the iav averages to zero
        @test abs(sum(iav[[1, 47, 93]])) < 1e-10

        anomaly = time_resample(data, daily, "8-day_anomaly")
        @test anomaly ≈ time_resample(data, daily, "8-day") .- mean(data)
        @test time_resample(data, daily, "8-day_msc_anomaly") ≈ msc .- mean(data)

        halfhourly = collect(DateTime(2001, 1, 1):Minute(30):DateTime(2001, 1, 10, 23, 30))
        @test length(time_resample(rand(length(halfhourly)), halfhourly, TimePeriodMSC(Minute(30); cycle=Day(1)))) == 48
        @test_throws ErrorException TimePeriodMSC(Year(1))
        @test_throws ErrorException TimePeriodMSC(Month(1); cycle=Day(1))
        @test_throws ErrorException TimePeriodIAV(Day(2); cycle=Day(1))
    end

    @testset "seasonal cycles match calendar dates across leap years" begin
        # 2003 and 2005 have no Feb 29, 2004 has one
        daily = collect(Date(2003, 1, 1):Day(1):Date(2005, 12, 31))
        data = Float64.(dayofyear.(daily))
        msc = time_resample(data, daily, "day_msc")
        positions = time_resample_dates(daily, "day_msc")
        @test length(msc) == 366
        @test sort(positions) == collect(0:365)
        by_position = Dict(zip(positions, msc))
        # Feb 29 only has the leap year, Mar 1 and Dec 31 have all three years
        @test by_position[59] == 60.0
        @test by_position[60] ≈ mean([60.0, 61.0, 60.0])
        @test by_position[365] ≈ mean([365.0, 366.0, 365.0])
        groups = create_TimeSampler(daily, TimeDayMSC())[1].indices
        @test all(g -> length(unique(monthday.(daily[g]))) == 1, groups)
        @test count(g -> length(g) == 1, groups) == 1

        # the IAV of every date is measured against the same calendar date
        iav_inds = create_TimeSampler(daily, TimeDayIAV())[2].indices
        @test all(i -> all(==(monthday(daily[i])), monthday.(daily[iav_inds[i]])), eachindex(daily))

        # 8-day bins share their edges in every year, bin 7 holds Feb 26 to Mar 4
        bin_starts = time_resample_dates(daily, "8-day_iav")
        @test Date(2003, 2, 26) in bin_starts && Date(2004, 2, 26) in bin_starts
        @test Date(2003, 3, 5) in bin_starts && Date(2004, 3, 5) in bin_starts
        @test length(time_resample(data, daily, "8-day_msc")) == 46

        # the MODIS style :year origin keeps counting plain days from Jan 1
        @test Date(2003, 2, 26) in time_resample_dates(daily, "8-day"; origin=:year)
        @test Date(2003, 3, 6) in time_resample_dates(daily, "8-day"; origin=:year)
    end

    @testset "3-hour MSC of hourly data" begin
        hourly = collect(DateTime(2001, 1, 1):Hour(1):DateTime(2002, 12, 31, 23))
        data = rand(length(hourly))
        seasonal = time_resample(data, hourly, "3-hour_msc")
        @test length(seasonal) == 2920
        @test seasonal[1] ≈ mean(data[[1, 2, 3, 8761, 8762, 8763]])
        @test time_resample(data, hourly, "3-hour-msc") == seasonal
        @test time_resample(data, hourly, "3-hour_msc_year") == seasonal

        diurnal = time_resample(data, hourly, "3-hour_msc_day")
        @test length(diurnal) == 8
        @test diurnal[2] ≈ mean(data[[i for i in eachindex(hourly) if hour(hourly[i]) in 3:5]])
        @test time_resample(data, hourly, "3-hour-msc-day") == diurnal
        @test time_resample(data, hourly, "3h_msc_day") == diurnal
        @test time_resample(data, hourly, "3hour") == time_resample(data, hourly, "3-hour")
        @test time_resample(data, hourly, "3-hour_msc"; cycle=Day(1)) == diurnal
    end

    @testset "spec strings" begin
        @test get_TimeSampler("8-day_msc") == TimePeriodMSC(Day(8))
        @test get_TimeSampler("month_iav") == TimePeriodIAV(Month(1))
        @test get_TimeSampler("6-hour_anomaly") == TimePeriodAnomaly(Hour(6))
        @test get_TimeSampler("8-day_msc_anomaly") == TimePeriodMSCAnomaly(Day(8))
        @test get_TimeSampler("30-min-msc-anomaly-day") == TimePeriodMSCAnomaly(Minute(30), Day(1))
        @test get_TimeSampler("30-min_iav_day") == TimePeriodIAV(Minute(30), Day(1))
        @test get_TimeSampler(:day) == TimeDay()
        @test get_TimeSampler(:day; origin=:start) == TimePeriodSample(Day(1); origin=:start)
        @test get_TimeSampler("mean") == TimeMean()
        @test get_TimeSampler("3h") == TimePeriodSample(Hour(3))
        @test get_TimeSampler("3hour_msc_day") == TimePeriodMSC(Hour(3), Day(1))
        @test get_TimeSampler("8d-iav") == TimePeriodIAV(Day(8))
        @test get_TimeSampler("30min_msc_anomaly_d") == TimePeriodMSCAnomaly(Minute(30), Day(1))
        @test_throws ErrorException get_TimeSampler("0h")
        @test_throws ErrorException get_TimeSampler("15m_msc")
        @test get_TimeSampler("TimeDayMSC") == TimeDayMSC()
        @test_throws ErrorException get_TimeSampler("3-hour_foo")
        @test_throws ErrorException get_TimeSampler("3-hour_anomaly_day")
    end


    @testset "snake case names" begin
        @test get_TimeSampler("first_year") == TimeFirstYear()
        @test get_TimeSampler("all_years") == TimeAllYears()
        @test get_TimeSampler("day_MSC") == TimeDayMSC()
        @test get_TimeSampler("hour_anomaly") == TimeHourAnomaly()
        @test get_TimeSampler("hour_day_mean") == TimeHourDayMean()
        @test get_TimeSampler("TimeMonthIAV") == TimeMonthIAV()
        # names that are not method types are read as period specs
        @test get_TimeSampler("8-day_msc") == TimePeriodMSC(Day(8))
        @test get_TimeSampler("day_msc") == TimePeriodMSC(Day(1))
    end

    @testset "time_sampling_type, time_sampling_period, format_temporal_resolution" begin
        @test time_sampling_type(TimeDay()) == TimeNoDiff()
        @test time_sampling_type("hour_anomaly") == TimeDiff()
        @test time_sampling_type("30-min_iav_day") == TimeDiff()
        @test time_sampling_type("3-hour-anomaly") == TimeDiff()
        @test time_sampling_type("day_MSC") == TimeNoDiff()
        @test time_sampling_type(TimeMean()) == TimeNoDiff()
        for name in ("first_year", "all_years", "random_year", "shuffle_years")
            @test time_sampling_type(name) == TimeIndexed()
        end

        @test time_sampling_period(TimeDay()) == Day(1)
        @test time_sampling_period("hour_anomaly") == Hour(1)
        @test time_sampling_period("month_iav") == Month(1)
        @test time_sampling_period("3h_msc_day") == Hour(3)
        @test time_sampling_period("hour_day_mean") == Hour(1)
        @test time_sampling_period(TimeMean()) === nothing
        @test time_sampling_period("first_year") === nothing

        @test format_temporal_resolution(Day(1)) == "day"
        @test format_temporal_resolution(Hour(6)) == "6-hour"
        @test format_temporal_resolution(Minute(30)) == "30-minute"
        @test format_temporal_resolution("3h") == "3-hour"
        @test format_temporal_resolution(:mon) == "month"
        @test parse_temporal_resolution(format_temporal_resolution(Hour(6))) == (6, "hour")
    end

    @testset "TimeResampler" begin
        hourly = collect(DateTime(2001, 1, 1):Hour(1):DateTime(2002, 12, 31, 23))
        realizations = [rand(length(hourly), 3) for _ in 1:3]
        for spec in ("6-hour", "8-day_iav", "3-hour_msc_day", "month_anomaly", "day_MSC")
            rs = TimeResampler(hourly, spec)
            @test rs isa TimeResampler
            @test rs.samplers isa Tuple
            @test time_resample_dates(rs) == time_resample_dates(hourly, spec)
            for x in realizations
                @test time_resample(x, rs) ≈ time_resample(x, hourly, spec)
            end
        end

        # the combine step comes from the method
        @test TimeResampler(hourly, "8-day_iav").combine == TimeDiff()
        @test TimeResampler(hourly, "day").combine == TimeNoDiff()

        # keywords and dimensions
        x = realizations[1]
        rs_sum = TimeResampler(hourly, :day; sampler_func=sum)
        @test time_resample(x, rs_sum) ≈ time_resample(x, hourly, :day; sampler_func=sum)
        @test time_resample(permutedims(x), rs_sum; dim=2) ≈ permutedims(time_resample(x, rs_sum))
        @test_throws ErrorException time_resample(x[1:10, :], rs_sum)

        # a skipped first sampler returns the data as it is, of any length
        rs_skip = TimeResampler(hourly, "hour"; skip_sampling=true)
        @test first(rs_skip.samplers) === nothing
        @test time_resample(x, rs_skip) === x
        @test time_resample(x[1:10, :], rs_skip) == x[1:10, :]
        # the second sampler of an anomaly still checks the length
        rs_skip_anomaly = TimeResampler(hourly, "hour_anomaly"; skip_sampling=true)
        @test time_resample(x, rs_skip_anomaly) ≈ x .- mean(x; dims=1)
        @test_throws ErrorException time_resample(x[1:10, :], rs_skip_anomaly)

        # selections do not resample
        @test_throws ErrorException TimeResampler(hourly, "first_year")
        @test_throws ErrorException TimeResampler(hourly, TimeAllYears())

        # applying a prebuilt resampler only allocates about the output
        rs = TimeResampler(hourly, "month")
        time_resample(x, rs)
        out_bytes = sizeof(time_resample(x, rs))
        @test (@allocated time_resample(x, rs)) < 2 * out_bytes + 4096
    end

    @testset "TimeMean" begin
        dates = collect(Date(2000, 1, 1):Day(1):Date(2000, 1, 10))
        mat = rand(length(dates), 3)
        @test time_resample(mat, dates, :mean) ≈ mean(mat; dims=1)
        @test time_resample(mat, dates, :mean; sampler_func=sum) ≈ sum(mat; dims=1)
        @test create_TimeSampler(dates, TimeMean())[1].indices == [1:10]
        @test create_TimeSampler(dates, TimeAllYears())[1].indices == [1:10]
    end

    @testset "calendar methods rebuilt on period methods" begin
        # reference implementations of the previous grouping by date component
        legacy_groups(keys) = TimeSamplers.getIndicesForTimeGroups(keys)
        legacy_by_value(keys) = [findall(==(k), keys) for k in unique(keys)]

        daily = collect(Date(2000, 1, 1):Day(1):Date(2002, 7, 20))
        hourly = collect(DateTime(2000, 1, 1):Hour(1):DateTime(2000, 3, 3, 23))
        for dates in (daily, hourly)
            @test create_TimeSampler(dates, TimeDay())[1].indices == legacy_groups(day.(dates))
            @test create_TimeSampler(dates, TimeMonth())[1].indices == legacy_groups(month.(dates))
            @test create_TimeSampler(dates, TimeYear())[1].indices == legacy_groups(year.(dates))
            @test create_TimeSampler(dates, TimeDayMSC())[1].indices == legacy_by_value(monthday.(dates))
            @test create_TimeSampler(dates, TimeMonthMSC())[1].indices == legacy_by_value(month.(dates))
            @test create_TimeSampler(dates, TimeMonthAnomaly())[2].indices == [1:length(dates)]
            month_iav = create_TimeSampler(dates, TimeMonthIAV())[2].indices
            month_msc = legacy_by_value(month.(dates))
            @test month_iav == [month_msc[month(dates[first(r)])] for r in legacy_groups(month.(dates))]
        end
        @test create_TimeSampler(hourly, TimeHour())[1].indices == legacy_groups(hour.(hourly))
        @test create_TimeSampler(hourly, TimeHourDayMean())[1].indices == legacy_by_value(hour.(hourly))
        calendar_days = unique(monthday.(daily))
        day_groups = legacy_by_value(monthday.(daily))
        @test create_TimeSampler(daily, TimeDayIAV())[2].indices == [day_groups[findfirst(==(md), calendar_days)] for md in monthday.(daily)]

        # coarse inputs no longer merge different days, months or years
        monthly = collect(Date(2000, 1, 1):Month(1):Date(2000, 12, 1))
        @test length(create_TimeSampler(monthly, TimeDay())[1].indices) == 12
        yearly = [Date(2000, 1, 1), Date(2001, 1, 1)]
        @test length(create_TimeSampler(yearly, TimeMonth())[1].indices) == 2
        daily_dt = collect(DateTime(2000, 1, 1):Day(1):DateTime(2000, 1, 5))
        @test length(create_TimeSampler(daily_dt, TimeHour())[1].indices) == 5

        # skip_sampling keeps its previous meaning per method
        @test create_TimeSampler(daily, TimeDay(), mean, true) == [nothing]
        @test create_TimeSampler(daily, TimeMonth(), mean, true)[1] isa TimeSample
        @test create_TimeSampler(daily, TimeYear(), mean, true)[1] isa TimeSample
        @test create_TimeSampler(daily, TimeMonthIAV(), mean, true)[1] isa TimeSample
        @test create_TimeSampler(daily, TimeDayAnomaly(), mean, true)[1] === nothing
    end
end
