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

    push!(names, "Matching LP Color02")
    push!(files, ["instances/color02/myciel3.col", "instances/color02/myciel4.col", "instances/color02/2-Insertions_3.col", "instances/color02/1-FullIns_3.col", "instances/color02/3-Insertions_3.col", "instances/color02/mug88_1.col", "instances/color02/mug88_25.col", "instances/color02/4-Insertions_3.col", "instances/color02/mug100_1.col", "instances/color02/mug100_25.col", "instances/color02/2-FullIns_3.col", "instances/color02/1-Insertions_4.col", "instances/color02/myciel5.col"])
    push!(ors, MatchingOracle)
    push!(seps, separate_matching)

    # MaxCut SDP
    push!(names, "Max Cut SDP")
    push!(files, ["instances/maxcut/complete-10-1.csv", "instances/maxcut/complete-10-2.csv", "instances/maxcut/complete-10-3.csv", "instances/maxcut/complete-10-4.csv", "instances/maxcut/complete-10-5.csv", "instances/maxcut/complete-10-6.csv", "instances/maxcut/complete-10-7.csv", "instances/maxcut/complete-10-8.csv", "instances/maxcut/complete-10-9.csv", "instances/maxcut/complete-10-10.csv"])
    push!(ors, MaxCutOracle)
    push!(seps, separate_maxcut)

    # LPBoost
    push!(names, "LPBoost")
    push!(files, ["instances/lpboost/00451.data", "instances/lpboost/audit_risk.data", "instances/lpboost/australian.data", "instances/lpboost/colposkopy-green.data", "instances/lpboost/echocardiogram.data", "instances/lpboost/german.data", "instances/lpboost/heart.data", "instances/lpboost/house-votes-84.data", "instances/lpboost/ionosphere.data", "instances/lpboost/mesothelioma.data", "instances/lpboost/parkinsons.data", "instances/lpboost/pop_failures-2.data", "instances/lpboost/sonar.data", "instances/lpboost/spect.data", "instances/lpboost/tic-tac-toe.data", "instances/lpboost/wpbc-1.data"])
    push!(ors, LPBoostOracle)
    push!(seps, separate_lpboost)

    optvals_matching = [3.162277660168, 3.316624790355, 3.464101615137, 3.605551275463, 3.756594202199, 3.872983346207, 4.000000000000, 4.123105625617, 4.242640687119, 4.358898943540, 4.472135954999, 4.582575694955, 4.690415759823, 4.795831523312, 4.898979485566, 5.000000000000]
    optvals_matching_color02 = [1.118033988749895, 1.3054598240132387, 2.121320343559642, 1.5000000000000002, 2.6696952498876594, 3.6414659098504214, 3.6414659098504214, 3.122498999199199, 3.8807526285316682, 3.8807526285316674, 1.833898601232361, 2.1665561421854234, 1.4971724762794754]
    optvals_maxcut = [2.638620747693, 3.323483085625, 2.816436033797, 3.040558400287, 2.459940756816, 3.496606433292, 2.845966722105, 2.918403106499, 2.838488826993, 2.735140217777]
    optvals_lpboost = [-0.072193067831, -1.000000000000, -0.013643388213, -0.273964579252, -0.836065573770, -0.000000000000, -0.026366450408, -0.698275862068, -0.104851081748, -1.000000000000, -0.143400508742, -0.171681197639, -0.137160937420, -0.598930481283, -0.043841336116, -0.082512641734]
    optvals = [optvals_matching, optvals_matching_color02, optvals_maxcut, optvals_lpboost]

    return names, files, ors, seps, optvals
end
