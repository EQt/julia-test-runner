using ExercismTestReports
using Test
import InteractiveUtils

# When running tests on this project, the solution_dir path is likely to be
# in our home directory, which Julia prints differently, so we copy all the
# input paths to somewhere else to sort that out (might not work in windows,
# but also who cares?)

const FIXTURES = joinpath(@__DIR__, "fixtures")
const TEMPDIR = mktempdir()
cp(FIXTURES, joinpath(TEMPDIR, "fixtures"))
const TMP_FIXTURES = joinpath(TEMPDIR, "fixtures")

@testset "All possible test result types are covered" begin
    @test Set(InteractiveUtils.subtypes(Test.Result)) == Set([
        Test.Pass, Test.Error, Test.LogTestFailure, Test.Broken, Test.Fail
    ])
end

@testset for fixture in readdir(TMP_FIXTURES)
    results = test_runner("", "$TMP_FIXTURES/$fixture/")
    if endswith(fixture, "syntax_error")
        # Substitute prefix with local file name in stack trace
        HOME_PREFIX = Base.contractuser(pkgdir(ExercismTestReports))
        TEST_PREFIX = "~/projects/exercism/repos/julia-test-runner"
        results = replace(results, HOME_PREFIX => TEST_PREFIX)
    end
    reference = "$FIXTURES/$fixture/results.json"
    if isfile(reference)
        ref = read(reference, String)
        if ref != results
            @test false
            try
                run(pipeline(`diff $reference /dev/stdin`; stdin=IOBuffer(results)))
            catch
            end
        else
            @test true
        end
    else
        write(reference, results)
        @test_skip nothing
    end
end
