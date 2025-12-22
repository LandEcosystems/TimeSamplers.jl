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
        @test do_time_sampling(data, daily, TimeNoDiff()) == data

        # Monthly aggregation: mean over all samples
        monthly = create_TimeSampler(dates, TimeMonth())
        @test time_sampling(data, monthly[1]) == [Statistics.mean(data)]

        # Diff (anomaly): daily - mean(all)
        anomaly = create_TimeSampler(dates, TimeDayAnomaly())
        @test do_time_sampling(data, anomaly, TimeDiff()) == data .- Statistics.mean(data)
    end
end


