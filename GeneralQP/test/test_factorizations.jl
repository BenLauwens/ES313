include("../src/GeneralQP.jl")
using Main.GeneralQP
using Random, Test

rng = MersenneTwister(123)
n = 100
m = 50
idx = 3

A = randn(rng, n, m)
P = randn(n, n); @. P = (P + P')/2
H = NullspaceHessianLDL(P, A)
# @show eigvals(H.QR.Q2'*P*H.QR.Q2)
@test norm(H.Z[:,end:-1:1]'*P*H.Z[:,end:-1:1] - H.U'*H.D*H.U) <= 1e-7

remove_constraint!(H, 0)
# A = [A[:, 1:idx-1] A[:, idx+1:m]]
@testset "Update qr - remove column" begin
    @test norm(H.QR.Q'*H.QR.Q - I) <= 1e-7
    @test norm(H.QR.Q1*H.QR.R1 - A) <= 1e-7
end

@testset "Expand hessian matrix" begin
    @test norm(H.Z[:,H.m:-1:1]'*P*H.Z[:,H.m:-1:1] - H.U'*H.D*H.U) <= 1e-7
end

a = randn(n)
add_constraint!(H, a)
A = [A a]
@testset "Update qr - add column" begin
    @test norm(H.QR.Q'*H.QR.Q - I) <= 1e-7
    @test norm(H.QR.Q1*H.QR.R1 - A) <= 1e-7
end

@testset "Shrink hessian matrix" begin
    @test norm(H.Z[:,H.m:-1:1]'*P*H.Z[:,H.m:-1:1] - H.U'*H.D*H.U) <= 1e-7
end

# using BenchmarkTools
# @btime qr_hessenberg!($Q_12, $R_2_T')