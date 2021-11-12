function get_data()
    names = []
    files = []
    ors = []
    seps = []

    # Matching LP
    push!(names, "Matching LP")
    push!(files, ["instances/matching/triangles-30.csv", "instances/matching/triangles-33.csv", "instances/matching/triangles-36.csv", "instances/matching/triangles-39.csv", "instances/matching/triangles-42.csv", "instances/matching/triangles-45.csv", "instances/matching/triangles-48.csv", "instances/matching/triangles-51.csv", "instances/matching/triangles-54.csv", "instances/matching/triangles-57.csv", "instances/matching/triangles-60.csv", "instances/matching/triangles-63.csv", "instances/matching/triangles-66.csv", "instances/matching/triangles-69.csv", "instances/matching/triangles-72.csv", "instances/matching/triangles-75.csv"])
    push!(ors, MatchingOracle)
    push!(seps, separate_matching)

    # MaxCut SDP
    push!(names, "Max Cut SDP")
    push!(files, ["instances/maxcut/complete-10-1.csv", "instances/maxcut/complete-10-2.csv", "instances/maxcut/complete-10-3.csv", "instances/maxcut/complete-10-4.csv", "instances/maxcut/complete-10-5.csv", "instances/maxcut/complete-10-6.csv", "instances/maxcut/complete-10-7.csv", "instances/maxcut/complete-10-8.csv", "instances/maxcut/complete-10-9.csv", "instances/maxcut/complete-10-10.csv"])
    push!(ors, MaxCutOracle)
    push!(seps, separate_maxcut)

    optvals_matching = [3.162277660168, 3.316624790355, 3.464101615137, 3.605551275463, 3.756594202199, 3.872983346207, 4.000000000000, 4.123105625617, 4.242640687119, 4.358898943540, 4.472135954999, 4.582575694955, 4.690415759823, 4.795831523312, 4.898979485566, 5.000000000000]
    optvals_maxcut = [2.638620747693, 3.323483085625, 2.816436033797, 3.040558400287, 2.459940756816, 3.496606433292, 2.845966722105, 2.918403106499, 2.838488826993, 2.735140217777]
    optvals = [optvals_matching, optvals_maxcut]

    return names, files, ors, seps, optvals
end
