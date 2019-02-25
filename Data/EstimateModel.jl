using JuMP
using KNITRO
using CSV
using DataFrames
using Random

nBox = 22
#Assume we have dataMatrix, contentProbs, contentPrices

T = Vector{Int64}(undef,nBox)
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
    T[j] = size(dataMat[j],1)
    K[j] = convert(Int64, dataMat[j][1,6])
    KL[j,1:T[j]] = convert.(Int64, dataMat[j][:,7] )
    #If theres no buy orders this will prevent a column of all zeros
    if( dataMat[j][:,8] == zeros(T[j]))
        Z[j] = dataMat[j][:,[3,4]]
    else
        Z[j] = dataMat[j][:,[3,4,8]]
    end    
    Y[j] = dataMat[j][:,2] - dataMat[j][:,5]
    bigZ[j] = hcat( ones(T[j]), Z[j], contentPrices[j][:,randperm(size(contentPrices[j],2))[1:20]]) #, Probs[j])
    W[j] = inv(bigZ[j]'*bigZ[j])
    numZ[j] = size(bigZ[j],2)
    for i in 1:size(contentProbs[j],1)
        for k in 1:size(contentProbs[j],2)
            if( contentProbs[j][i,k] > 1.0)
                println(contentProbs[j][i,k])
                contentProbs[j][i,k] = 1.0
            end
        end
    end
    #println(j)
end

meanVal = 0.0
for j in 1:nBox
    global meanVal
    meanVal += mean(Y[j])
end
meanVal /= convert(Float64, nBox )

#Jacobian Problems when this is raised
T[15] = 43



function transP( p::Real, α::Real,  λ::Real, δ::Real )
    return (p^δ / (p^δ + (1.0-p)^δ))^(1.0/δ)
    #return ( γ*p^δ) / ( γ*p^δ + (1.0 - p)^δ)
end

function transG( v::Real, α::Real,  λ::Real, δ::Real )
    return v^α
end

function transL( v::Real, α::Real,  λ::Real, δ::Real )
    return -λ*v^α
end

    


m = Model( with_optimizer(KNITRO.Optimizer))

register(m, :transProbs, 4, transP, autodiff=true)
register(m, :transGains, 4, transG, autodiff=true)
register(m, :transLosses, 4, transL, autodiff=true)

@variable(m,  α[i=1:2] >= 0.0 )
#variable(m,  β >= 0.0 )
@variable(m,  1.0 >= δ[i=1:2] >= 0.5 )
@variable(m, λ[i=1:2] >= 0.0 )
@variable(m, 0 >=  ϕ[i=1:2] )
@variable(m, ξ[j=1:nBox,t=1:T[j]] )

#@variable(m, boldξ[j=1:nBox,t=1:T,z=1:numZ[j]])


@NLparameter(m, Probs[j=1:nBox,t=1:T[j],i=1:K[j]] == contentProbs[j][t,i])
@NLparameter(m, Gains[j=1:nBox,t=1:T[j],i=(KL[j,t]+1):K[j]] == contentPrices[j][t,i])
@NLparameter(m, Losses[j=1:nBox,t=1:T[j],i=1:KL[j,t]] == -contentPrices[j][t,i])
    

@NLparameter(m, Y[j=1:nBox,t=1:T[j]] == dataMat[j][t,2] - dataMat[j][t,5] )
@NLparameter(m, Z[j=1:nBox,t=1:T[j],z=1:numZ[j]] == bigZ[j][t,z] )

temp = convert.(Int64, ones(nBox ))
temp[1] = 2
temp[3] = 2
temp[11] = 2
temp[14] = 2
temp[20] = 2

    

@NLexpression( m, diffProbs[j=1:nBox,t=1:T[j], i=2:K[j]],
               transProbs( Probs[j,t,i], α[temp[j]],λ[temp[j]],δ[temp[j]]) - transProbs( Probs[j,t,i-1], α[temp[j]],λ[temp[j]],δ[temp[j]]))



# @NLexpression( m, transProbs[j=1:nBox, t=1:T[j], i=1:K[j]],
#                (Probs[j][t,i]^δ / (Probs[j][t,i]^δ + (1.0 - Probs[j][t,i])^δ))^(1.0/δ) )
# @NLexpression( m, transGains[j=1:nBox, t=1:T[j], i=(KL[j,t]+1):K[j]],
#                Gains[j][t,i]^α)
# @NLexpression( m, transLosses[j=1:nBox, t=1:T[j], i=1:KL[j,t]],
#                - λ * Losses[j][t,i]^α)

# @NLexpression( m, LotteryValue[j=1:nBox, t=1:T[j]],
#                transProbs[j,t,1]*transLosses[j,t,1] +
#                sum((transProbs[j,t,i]-transProbs[j,t,i-1])*transLosses[j,t,i] for i in 2:KL[j,t] )
#                +sum((transProbs[j,t,i]-transProbs[j,t,i-1])*transGains[j,t,i]
#                     for i in (KL[j,t]+1):K[j] ))

@NLconstraint( m, mpec[j=1:nBox,t=1:T[j]],
               ξ[j,t] == Y[j,t] - ϕ[temp[j]] -
               (transProbs( Probs[j,t,1], α[temp[j]],λ[temp[j]],δ[temp[j]])*transLosses(Losses[j,t,1],α[temp[j]],λ[temp[j]],δ[temp[j]]) +
                sum(diffProbs[j,t,i]*transLosses(Losses[j,t,i], α[temp[j]],λ[temp[j]],δ[temp[j]])
                    for i in 2:KL[j,t] ) +
                sum(diffProbs[j,t,i]*transGains(Gains[j,t,i], α[temp[j]],λ[temp[j]],δ[temp[j]])
                    for i in (KL[j,t]+1):(K[j]-1)) ));



               # (transProbs( Probs[j,t,1], α[temp[j]],λ[temp[j]],δ[temp[j]])*transLosses(Losses[j,t,1], α[temp[j]],λ[temp[j]],δ[temp[j]]) +
               # sum((transProbs( Probs[j,t,i], α[temp[j]],λ[temp[j]],δ[temp[j]])-transProbs( Probs[j,t,i-1], α[temp[j]],λ[temp[j]],δ[temp[j]]))*
               #     transLosses(Losses[j,t,i], α[temp[j]],λ[temp[j]],δ[temp[j]]) for i in 2:KL[j,t] ) +
               # sum((transProbs( Probs[j,t,i], α[temp[j]],λ[temp[j]],δ[temp[j]])-transProbs( Probs[j,t,i-1], α[temp[j]],λ[temp[j]],δ[temp[j]]))*
               #     transGains(Gains[j,t,i], α[temp[j]],λ[temp[j]],δ[temp[j]])  for i in (KL[j,t]+1):K[j] )))


# @NLconstraint( m, mpec[j=1:nBox,t=1:T[j]],
#                ξ[j,t] == Y[j,t] - γ -
#                (transProbs( Probs[j,t,1], α[temp[j]],λ[temp[j]],δ[temp[j]])*transLosses(Losses[j,t,1], α[temp[j]],λ[temp[j]],δ[temp[j]]) +
#                sum((transProbs( Probs[j,t,i], α[temp[j]],λ[temp[j]],δ[temp[j]])-transProbs( Probs[j,t,i-1], α[temp[j]],λ[temp[j]],δ[temp[j]]))*
#                    transLosses(Losses[j,t,i], α[temp[j]],λ[temp[j]],δ[temp[j]]) for i in 2:KL[j,t] ) +
#                sum((transProbs( Probs[j,t,i], α[temp[j]],λ[temp[j]],δ[temp[j]])-transProbs( Probs[j,t,i-1], α[temp[j]],λ[temp[j]],δ[temp[j]]))*
#                    transGains(Gains[j,t,i], α[temp[j]],λ[temp[j]],δ[temp[j]])  for i in (KL[j,t]+1):K[j] )));
               


# @NLconstraint( m, boldXi[j=1:nBox,t=1:T[j],z=1:numZ[j]],
#              boldξ[j,t,z] == ξ[j,t]*Z[j,t,z] )
#                #ξ[j,t] == Y[j][t] - LotteryValue[j,t])


@NLobjective( m, Min, sum((ξ[j,t]*Z[j,t,q]) * ( W[j][q,w] ) * (ξ[j,t]*Z[j,t,w])
                          for j in 1:nBox, t in 1:T[j], q in 1:numZ[j], w in 1:numZ[j]) )

for i in 1:nBox
    set_start_value( ϕ[i], meanVal )
end

set_start_value( α[1], 1.0 )
set_start_value( δ[1], .995 )
set_start_value( λ[1], 1.0 )
set_start_value( α[2], 1.0 )
set_start_value( δ[2], .995 )
set_start_value( λ[2], 1.0 )

for j in 1:nBox
    for t in 1:T[j]
        set_start_value( ξ[j,t], dataMat[j][t,2] - dataMat[j][t,5] - meanVal -
                         transP(contentProbs[j][t,1], 1.0,1.0,1.0)*
                         transL(-contentPrices[j][t,1],1.0,1.0,1.0) + 
                         sum((transP(contentProbs[j][t,i], 1.0,1.0,1.0) - transP( contentProbs[j][t,i-1], 1.0,1.0,1.0) ) * 
                             transL(-contentPrices[j][t,i],1.0,1.0,1.0) for i in 2:KL[j,t] ) +
                sum((transP( contentProbs[j][t,i], 1.0,1.0,1.0) - transP( contentProbs[j][t,i-1], 1.0,1.0,1.0) )*transG(contentPrices[j][t,i], 1.0,1.0,1.0)
                    for i in (KL[j,t]+1):(K[j]-1)) )
    end
end

        
optimize!(m)

# Using subsetting to simplify the computation, the last run on the full data set returned
# Fun: 1.06372046088932e+03
# α = 0.6289549093378937 ; 1.1291875204929902
# λ = 0.9132535483941188 ; 2.311963702525802e-9
# δ = 0.9999999999804773 ; 0.8352575991661386
# γ = -9.390234173087833e-11 ; -2.3008629007213743

a = JuMP.value( α[1] )
l = JuMP.value( λ[1] )
d = JuMP.value( δ[1] )

for i in 1:nBox
    println(JuMP.value( ϕ[i]))
end


a = JuMP.value( α[2] )
l = JuMP.value( λ[2] )
d = JuMP.value( δ[2] )

phi = JuMP.value( ϕ[2])

println(JuMP.value( ξ[1,1] )*JuMP.value(Z[1,1,1]))
for j in 1:nBox
    #println(JuMP.value( LotteryValue[1,t] ))
    println(mean(GetLotteryValue( a,
                             d,
                             l,
                             j, t ) for t in 1:T[j] ))
end

for t in 1:T[j]
    println(JuMP.value( ξ[t,1] ))
end
mean( JuMP.value(ξ[j,t]) for j in 1:nBox, t in 1:T[j] )








function TransProbs( δ::Float64, j::Int64, t::Int64, i::Int64)
    return (contentProbs[j][t,i]^δ / (contentProbs[j][t,i]^δ + (1.0 - contentProbs[j][t,i])^δ))^(1.0/δ)
end

function TransGains( α::Float64, j::Int64, t::Int64, i::Int64)
    return contentPrices[j][t,i]^α
end

function TransLosses( α::Float64, λ::Float64,  j::Int64, t::Int64, i::Int64)
    return - λ * (-contentPrices[j][t,i])^α
end
function GetLotteryValue( α::Float64, δ::Float64, λ::Float64, j::Int64, t::Int64 )
    valSum = TransProbs( δ, j, t,1)*TransLosses(α, λ, j, t, 1)
    valSum += sum((TransProbs( δ, j, t,i)-TransProbs( δ, j, t,i-1))*
                  TransLosses(α, λ, j, t, i) for i in 2:KL[j,t] )
    valSum += sum((TransProbs( δ, j, t,i)-TransProbs( δ, j, t,i-1))*
                  TransGains( α, j, t, i) for i in (KL[j,t]+1):K[j] )
    return valSum
end
