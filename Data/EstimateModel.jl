using JuMP
using Ipopt
using CSV
using DataFrames

nBox = 22
#Assume we have dataMatrix, contentProbs, contentPrices

T = 31#722

K = Vector{Int64}(undef,nBox)
KL = Matrix{Int64}(undef,nBox,maximum(size(dataMat[j],1) for j in 1:nBox))

Z = Vector{Matrix{Float64}}(undef,nBox)
Y = Vector{Vector{Float64}}(undef,nBox)
bigZ = Vector{Matrix{Float64}}(undef,nBox)
W = Vector{Matrix{Float64}}(undef,nBox)
numZ = Vector{Int64}(undef,nBox)

Probs = contentProbs
Gains= contentPrices
Losses = -contentPrices


for j in 1:nBox
    K[j] = convert(Int64, dataMat[j][1,6])
    s = size(dataMat[j],1)
    KL[j,1:s] = convert.(Int64, dataMat[j][:,7] )
    Z[j] = dataMat[j][:,2:3]
    Y[j] = dataMat[j][:,2] - dataMat[j][:,5]
    bigZ[j] = hcat( ones(s), Z[j], Probs[j], contentPrices[j])
    W[j] = inv(bigZ[j]'*bigZ[j])
    numZ[j] = size(bigZ[j],2)
    #println(j)
end






#ℓ = 737


nBox = 1
T = 31

m = Model( with_optimizer(Ipopt.Optimizer))

@variable(m, α )
@variable(m, δ )
@variable(m, λ )
@variable(m, ξ[j=1:nBox,t=1:T] )
@variable(m, boldξ[j=1:nBox,t=1:T,z=1:numZ[j]])
#@variable(m, boldξ[j=1:nBox,t=1:T,z=1:numZ] )



@NLexpression( m, transProbs[j=1:nBox, t=1:T, i=1:K[j]],
               (Probs[j][t,i]^δ / (Probs[j][t,i]^δ + (1.0 - Probs[j][t,i])^δ))^(1.0/δ) )
@NLexpression( m, transGains[j=1:nBox, t=1:T, i=(KL[j,t]+1):K[j]],
               Gains[j][t,i]^α)
@NLexpression( m, transLosses[j=1:nBox, t=1:T, i=1:KL[j,t]],
               - λ * Losses[j][t,i]^α)

@NLexpression( m, LotteryValue[j=1:nBox, t=1:T],
               transProbs[j,t,1]*transLosses[j,t,1] +
               sum((transProbs[j,t,i]-transProbs[j,t,i-1])*transLosses[j,t,i] for i in 2:KL[j,t] )
               +sum((transProbs[j,t,i]-transProbs[j,t,i-1])*transGains[j,t,i]
                    for i in (KL[j,t]+1):K[j] ))

@NLconstraint( m, mpec[j=1:nBox,t=1:T],
               ξ[j,t] == Y[j][t] - LotteryValue[j,t])



#ZU = 0

@NLobjective( m, Min, sum( sum(boldξ[j,t,q]*boldξ[j,t,w]*W[q,w] for q in 1:numZ, w in 1:numZ)
                           for j in 1:nBox, t in 1:T) );


optimize!(m)
