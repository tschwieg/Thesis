using JuMP
using Ipopt
using CSV
using DataFrames

nBox = 1
#Assume we have dataMatrix, contentProbs, contentPrices
j = 1
K[j] = convert(Int64, dataMatrix[j][1,6])
KL[j,:] = convert.(Int64, dataMatrix[j][:,7] )
Probs[j,:,:] = contentProbs[j]
Gains[j,:,:] = contentPrices[j]
Losses[j,:,:] = -contentPrices[j]
Z[j,:,:] = dataMatrix[j][:,2:3]
bigZ[j] = hcat( ones(T), Z[J,:,:], Probs[j,:,:], contentPrices[j])
W = inv(bigZ[j]'*bigZ[j])

T = 722
K = [367]

ℓ = 737


nBox = 1
T = 31

m = Model( solver=IpoptSolver())

@variable(m, α )
@variable(m, δ )
@variable(m, λ )
@variable(m, ξ[j=1:nBox,t=1:T] )



@NLexpression( m, transProbs[j=1:nBox, t=1:T, i=1:K[j]],
               (Probs[j,t,i]^δ / (Probs[j,t,i]^δ + (1.0 - Probs[j,t,i])^δ))^(1.0/δ) )
@NLexpression( m, transGains[j=1:nBox, t=1:T, i=(KL[j,t]+1):K[j]],
               Gains[j,t,i]^α)
@NLexpression( m, transLosses[j=1:nBox, t=1:T, i=1:KL[j,t]],
               - λ * Losses[j,t,i]^α)

@NLexpression( m, LotteryValue[j=1:nBox, t=1:T],
               transProbs[j,t,1]*transLosses[j,t,1] +
               sum((transProbs[j,t,i]-transProbs[j,t,i-1])*transLosses[j,t,i] for i in 2:KL[j,t] )
               +sum((transProbs[j,t,i]-transProbs[j,t,i-1])*transGains[j,t,i]
                    for i in (KL[j,t]+1):K[j] ))

@NLconstraint( m, mpec[j=1:nBox,t=1:T],
               ξ[j,t] == Y[j,t] - LotteryValue[j,t])



#ZU = 0

@NLobjective( m, Min, (bigZ'*ξ[1,t])*W*(ξ[1,t]'*bigZ) )


status = solve(m)
