using JuMP
using KNITRO
using CSV
using DataFrames
using Random
using ForwardDiff
using LinearAlgebra






function transP( p::Real, α::Real,  λ::Real, δ::Real, γ::Real )
    #return (p^δ / (p^δ + (1.0-p)^δ))^(1.0/δ)
    return ( γ*p^δ) / ( γ*p^δ + (1.0 - p)^δ)
end

function transG( v::Real, α::Real,  λ::Real, δ::Real )
    return v^α
end

function transL( v::Real, α::Real,  λ::Real, δ::Real )
    return -λ*v^α
end

function EstimateModelCRRA( trueProbs::Vector{Matrix{Float64}},
                            truePrices::Vector{Matrix{Float64}},
                            dataMat::Vector{Matrix{Float64}},
                            bigZ::Vector{Matrix{Float64}}, W::Matrix{Float64}, widest::Int64,
                            T::Vector{Int64}, K::Vector{Int64}, KL::Matrix{Int64}, nBox::Int64,
                            startX::Vector{Real}, TwoTypes::Bool)

    m = Model( with_optimizer(KNITRO.Optimizer))
    @variable( m, α >= 0.0)
    @variable( m, β )
    @variable( m, γ >= 0.0 )
    @variable( m, ϕ[j=1:nBox] )
    @variable(m, ξ[j=1:nBox,t=1:T[j]] )

    @variable(m, boldξ[z=1:widest])

    @NLparameter(m, Probs[j=1:nBox,t=1:T[j],i=1:K[j]] == trueProbs[j][t,i])
    @NLparameter(m, Prices[j=1:nBox,t=1:T[j],i=1:K[j]] == truePrices[j][t,i])
    @NLparameter(m, Y[j=1:nBox,t=1:T[j]] == dataMat[j][t,2] - dataMat[j][t,5] )
    @NLparameter(m, Z[j=1:nBox,t=1:T[j],z=1:widest] == bigZ[j][t,z] )
    @NLparameter(m, tot == sum(T[j] for j in 1:nBox) )

    @NLconstraint( m, mpec[j=1:nBox,t=1:T[j]],
                   ξ[j,t] == Y[j,t] - ϕ[j] - β*dataMat[j][t,1] - γ*sum( Probs[j,t,i]*Prices[j,t,i]^α
                                                        for i in 1:(K[j]-1) ) )
    @NLconstraint( m, boldXi[z=1:widest],
                   boldξ[z] == sum(ξ[j,t]*Z[j,t,z] for j in 1:nBox, t in 1:T[j] ) / tot )
    @NLobjective( m, Min, sum( boldξ[q]*W[q,w]*boldξ[w] for q in 1:widest, w in 1:widest))

    set_start_value( α, .5)
    set_start_value( β, -1.0)
    for j in 1:nBox
        for t in 1:T[j]
            set_start_value( ξ[j,t], dataMat[j][t,2] - dataMat[j][t,5] + dataMat[j][t,1] -
                             sum( trueProbs[j][t,i]*truePrices[j][t,i]^.5 for i in 1:(K[j]-1) ))
        end
    end
    

    optimize!(m)

    x = zeros(3+nBox)
    x[1] = JuMP.value(α)
    x[2] = JuMP.value(β)
    x[3] = JuMP.value(γ)
    #println( JuMP.value(α) )
    #println( JuMP.value(β) )
    for j in 1:nBox
        x[3+j] = JuMP.value(ϕ[j])
        #println( JuMP.value(ϕ[j]))
    end
    
    return x
end

function boldXiSCRRA( x::Vector)
    filler = Vector{Real}(undef,widest)#zeros(widest)
    filler .= 0
    tot = sum( T[j] for j in 1:nBox)

    for i in 1:widest
        for j in 1:nBox
            for t in 1:T[j]
                a = x[1]
                b = x[2]
                g = x[3]
                p = x[4:end]
                 xi = dataMat[j][t,2] - dataMat[j][t,5] - p[j] -
                     b*dataMat[j][t,1] - g*sum( trueProbs[j][t,i]*truePrices[j][t,i]^a
                                                for i in 1:(K[j]) )
                filler[i] += xi*bigZ[j][t,i]
            end
        end
        filler[i] /= tot
    end
    return filler
end

function boldXiTJCRRA( x::Vector, t::Int64, j::Int64)

    filler = zeros(widest)
    for i in 1:widest
        a = x[1]
        b = x[2]
        g = x[3]
        p = x[4:end]
        xi = dataMat[j][t,2] - dataMat[j][t,5] - p[j] -
            b*dataMat[j][t,1] - g*sum( trueProbs[j][t,i]*truePrices[j][t,i]^a
                                                        for i in 1:(K[j]) )
        filler[i] = xi*bigZ[j][t,i]
    end
    return filler
end




function EstimateModel( contentProbs::Vector{Matrix{Float64}},
                        contentPrices::Vector{Matrix{Float64}},
                        dataMat::Vector{Matrix{Float64}},
                        bigZ::Vector{Matrix{Float64}}, W::Matrix{Float64}, widest::Int64,
                        T::Vector{Int64}, K::Vector{Int64}, KL::Matrix{Int64}, nBox::Int64,
                        startX::Vector{Real}, TwoTypes::Bool)


    m = Model( with_optimizer(KNITRO.Optimizer))

    register(m, :transProbs, 5, transP, autodiff=true)
    register(m, :transGains, 4, transG, autodiff=true)
    register(m, :transLosses, 4, transL, autodiff=true)

    @variable(m,  α[i=1:2] >= 0.0 )
    #variable(m,  β >= 0.0 )
    @variable(m,  1.0 >= δ[i=1:2] >= 0.25 )
    @variable( m, 1.0 >= γ[i=1:2] >= 0.1 )
    @variable(m, 100.0 >= λ[i=1:2] >= 0.0 )
    @variable(m,  ϕ[i=1:nBox] )
    @variable(m, ξ[j=1:nBox,t=1:T[j]] )

    @variable(m, boldξ[z=1:widest])


    @NLparameter(m, Probs[j=1:nBox,t=1:T[j],i=1:K[j]] == contentProbs[j][t,i])
    @NLparameter(m, Gains[j=1:nBox,t=1:T[j],i=(KL[j,t]+1):K[j]] == contentPrices[j][t,i])
    @NLparameter(m, Losses[j=1:nBox,t=1:T[j],i=1:KL[j,t]] == -contentPrices[j][t,i])
    

    @NLparameter(m, Y[j=1:nBox,t=1:T[j]] == dataMat[j][t,2] - dataMat[j][t,5] )
    @NLparameter(m, Z[j=1:nBox,t=1:T[j],z=1:widest] == bigZ[j][t,z] )
    @NLparameter(m, tot == sum(T[j] for j in 1:nBox) )

    temp = convert.(Int64, ones(nBox ))
    if TwoTypes
        temp[4] = 2
        temp[5] = 2
        temp[6] = 2
        temp[13] = 2
        temp[16] = 2
        temp[17] = 2
        temp[19] = 2
        temp[22] = 2
    end
    

    @NLexpression( m, diffProbs[j=1:nBox,t=1:T[j], i=2:K[j]],
                   transProbs( Probs[j,t,i], α[temp[j]],λ[temp[j]],δ[temp[j]],γ[temp[j]]) - transProbs( Probs[j,t,i-1], α[temp[j]],λ[temp[j]],δ[temp[j]],γ[temp[j]]))



    @NLconstraint( m, mpec[j=1:nBox,t=1:T[j]],
                   ξ[j,t] == Y[j,t] - ϕ[j] -
                   (transProbs( Probs[j,t,1], α[temp[j]],λ[temp[j]],δ[temp[j]],γ[temp[j]])*transLosses(Losses[j,t,1],α[temp[j]],λ[temp[j]],δ[temp[j]]) +
                    sum(diffProbs[j,t,i]*transLosses(Losses[j,t,i], α[temp[j]],λ[temp[j]],δ[temp[j]])
                        for i in 2:KL[j,t] ) +
                    sum(diffProbs[j,t,i]*transGains(Gains[j,t,i], α[temp[j]],λ[temp[j]],δ[temp[j]])
                        for i in (KL[j,t]+1):(K[j]-1)) ))




    @NLconstraint( m, boldXi[z=1:widest],
                   boldξ[z] == sum(ξ[j,t]*Z[j,t,z] for j in 1:nBox, t in 1:T[j] ) / tot )
    #ξ[j,t] == Y[j][t] - LotteryValue[j,t])



    

    # @NLobjective( m, Min, sum((ξ[j,t]*Z[j,t,q]) * (ξ[j,t]*Z[j,t,q])
    #                           for j in 1:nBox, t in 1:T[j], q in 1:numZ[j]) )#, w in 1:numZ[j]

    @NLobjective( m, Min, sum( boldξ[q]*W[q,w]*boldξ[w] for q in 1:widest, w in 1:widest))
    #W[j][q,w]

    set_start_value( α[1], startX[1] )
    set_start_value( λ[1], startX[2] )
    set_start_value( δ[1], startX[3] )
    set_start_value( γ[1], startX[4] )
    #set_start_value( ϕ[1], startX[5] )
    set_start_value( α[2], startX[6] )
    set_start_value( λ[2], startX[7] )
    set_start_value( δ[2], startX[8] )
    set_start_value( γ[2], startX[9] )
    #set_start_value( ϕ[2], startX[10] )
    
    #I'm so sorry for any person that tries to understand this.
    #Basically we initialize the ξ at the values given by startX.
    xiStart = zeros(nBox,maximum(T))
    for j in 1:nBox
        for t in 1:T[j]
            if( temp[j] == 1)
                xiStart[j,t] = dataMat[j][t,2] - dataMat[j][t,5] -  startX[5] -
                    transP(contentProbs[j][t,1],startX[1],startX[2],startX[3],startX[4]) *
                    transL(-contentPrices[j][t,1],startX[1],startX[2],startX[3]) + 
                    sum((transP(contentProbs[j][t,i],startX[1],startX[2],startX[3],startX[4]) -
                         transP( contentProbs[j][t,i-1],startX[1],startX[2],startX[3],startX[4]))*
                        transL(-contentPrices[j][t,i],startX[1],startX[2],startX[3])
                        for i in 2:KL[j,t] ) +
                            sum((transP(contentProbs[j][t,i],startX[1],startX[2],startX[3],
                                        startX[4]) -
                                 transP( contentProbs[j][t,i-1],startX[1],startX[2],startX[3],
                                         startX[4]) )*
                                transG(contentPrices[j][t,i],startX[1],startX[2],startX[3])
                                for i in (KL[j,t]+1):(K[j]-1))
            else
                xiStart[j,t] = dataMat[j][t,2] - dataMat[j][t,5] -  startX[10] -
                    transP(contentProbs[j][t,1],startX[6],startX[7],startX[8],
                           startX[9])*
                transL(-contentPrices[j][t,1],startX[6],startX[7],startX[8]) + 
                    sum((transP(contentProbs[j][t,i],startX[6],startX[7],startX[8],
                                startX[9]) - transP( contentProbs[j][t,i-1],
                                                     startX[6],startX[7],startX[8],
                                                     startX[9]) ) * 
                        transL(-contentPrices[j][t,i],startX[6],startX[7],startX[8])
                                     for i in 2:KL[j,t] ) +
                                 sum((transP(contentProbs[j][t,i],startX[6],startX[7],startX[8],
                                             startX[9]) - transP( contentProbs[j][t,i-1],
                                                                  startX[6],startX[7],startX[8],
                                                                  startX[9]) )*
                                     transG(contentPrices[j][t,i],startX[6],startX[7],startX[8])
                                     for i in (KL[j,t]+1):(K[j]-1))
            end
            set_start_value( ξ[j,t], xiStart[j,t])
        end
    end

    for z in 1:widest
        # @NLconstraint( m, boldXi[z=1:widest],
        #boldξ[z] == sum(ξ[j,t]*Z[j,t,z] for j in 1:nBox, t in 1:T[j] ) / tot )
        startVal = 0.0
        for j in 1:nBox
            startVal += sum( xiStart[j,t]*bigZ[j][t,z] for t in 1:T[j] )
        end
        
        set_start_value( boldξ[z], startVal / sum(T[j] for j in 1:nBox))
    end


    optimize!(m)

    x = zeros(8+nBox)


    x[1] = JuMP.value( α[1] )
    x[2] = JuMP.value( λ[1] )
    x[3] = JuMP.value( δ[1] )
    x[4] = JuMP.value( γ[1] )

    x[5] = JuMP.value( α[2] )
    x[6] = JuMP.value( λ[2] )
    x[7] = JuMP.value( δ[2] )
    x[8] = JuMP.value( γ[2] )

    for j in 1:nBox
        x[8+j] = JuMP.value(ϕ[j])
    end
 

    return x
end




function GetLotteryValue( j::Int64, t::Int64, α::Real, λ::Real, δ::Real, γ::Real )
    #transP( p::Real, α::Real,  λ::Real, δ::Real, γ::Real )
    valSum = transP( contentProbs[j][t,1], α, λ, δ, γ )*transL( -contentPrices[j][t,1], α, λ, δ )
    valSum += sum(
        (transP( contentProbs[j][t,i], α,λ,δ,γ ) - transP( contentProbs[j][t,i-1], α,λ,δ,γ ))*
        transL( -contentPrices[j][t,i], α, λ, δ ) for i in 2:KL[j,t] )
    valSum += sum(
        (transP( contentProbs[j][t,i], α,λ,δ,γ ) - transP( contentProbs[j][t,i-1], α,λ,δ,γ ))*
                 transG( contentPrices[j][t,i], α, λ, δ ) for i in (KL[j,t]+1):(K[j]-1) )
    return valSum
end


function boldXiS( x::Vector, useTemp::Bool)
    filler = Vector{Real}(undef,widest)#zeros(widest)
    filler .= 0
    tot = sum( T[j] for j in 1:nBox)

    temp = convert.(Int64, ones(nBox ))
    if( useTemp )
        temp[4] = 2
        temp[5] = 2
        temp[6] = 2
        temp[13] = 2
        temp[16] = 2
        temp[17] = 2
        temp[19] = 2
        temp[22] = 2
    end
    
    
    for i in 1:widest
        for j in 1:nBox
            for t in 1:T[j]
                a = x[1+4*(temp[j] - 1)]
                l = x[2+4*(temp[j] - 1)]
                d = x[3+4*(temp[j] - 1)]
                g = x[4+4*(temp[j] - 1)]
                p = x[8+j]
                xi = dataMat[j][t,2] - dataMat[j][t,5]- p - GetLotteryValue(j,t,a, l, d, g)
                filler[i] += xi*bigZ[j][t,i]
            end
        end
        filler[i] /= tot
    end
    return filler
end




function boldXiTJ( x::Vector{Real}, t::Int64, j::Int64, useTemp::Bool)
    temp = convert.(Int64, ones(nBox ))
    if( useTemp )
        temp[4] = 2
        temp[5] = 2
        temp[6] = 2
        temp[13] = 2
        temp[16] = 2
        temp[17] = 2
        temp[19] = 2
        temp[22] = 2
    end
    filler = zeros(widest)
    for i in 1:widest
        a = x[1+4*(temp[j] - 1)]
        l = x[2+4*(temp[j] - 1)]
        d = x[3+4*(temp[j] - 1)]
        g = x[4+4*(temp[j] - 1)]
        p = x[8+j]
        xi = dataMat[j][t,2] - dataMat[j][t,5] - p - GetLotteryValue(j,t,a, l, d, g)
        filler[i] = xi*bigZ[j][t,i]
    end
    return filler
end

nBox = 22
#Assume we have dataMatrix, contentProbs, contentPrices Now we
#construct the objects we need in a rather ugly form.  This is a set
#of vectors of matrices, transforming it to a good form is half of
#what is done here

T = Vector{Int64}(undef,nBox)
K = Vector{Int64}(undef,nBox)
KL = Matrix{Int64}(undef,nBox,maximum(size(dataMat[j],1) for j in 1:nBox))

Z = Vector{Matrix{Float64}}(undef,nBox)
Y = Vector{Vector{Float64}}(undef,nBox)
bigZ = Vector{Matrix{Float64}}(undef,nBox)
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

    #permute = 

    probMat = copy(contentProbs[j])
    for i in 2:K[j]
        probMat[:,i] = contentProbs[j][:,i] .- contentProbs[j][:,i-1]
    end
    
    bigZ[j] = hcat( ones(T[j]), Z[j], (contentPrices[j] .* probMat) )
    
    #bigZ[j] = hcat( ones(T[j]), Z[j], contentPrices[j][:,randperm(size(contentPrices[j],2))[1:100]]) #, Probs[j])
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


widest = maximum( [size(bigZ[j],2) for j in 1:nBox ])
#We need to ensure that all of the bigZ have the same number of
#columns, so pad all the ones that are a little short by zeros
for j in 1:nBox
    bigZ[j] = hcat(bigZ[j], zeros(size(bigZ[j],1),widest-size(bigZ[j],2)))
end

#I think I need a better naming convention
#This gives us a 1000-something by widest matrix of all the instruments
# We can then invert its inner product to get the TSLS weight matrix
superZ = vcat( bigZ...)

tempMat = superZ'*superZ
chol = cholesky(tempMat)

#chol.L * chol.U = tempMat
W = chol.U \ ( chol.L \ I)
TSLSW = chol.U \ ( chol.L \ I)


meanVal = 0.0
for j in 1:nBox
    global meanVal
    meanVal += mean(Y[j])
end
meanVal /= convert(Float64, nBox )

#Jacobian Problems when this is raised
T[15] = 43

startX =  convert(Vector{Real}, [1.0, 1.0, .995, .995, meanVal, 1.0, 1.0, .995, .995, meanVal ] )

x = EstimateModel( contentProbs, contentPrices, dataMat, bigZ, W,
                   widest, T, K, KL, nBox, startX, false)

#Since we need automatic differentiation we will use this
x = convert(Vector{Real},x)

tot = sum( T[j] for j in 1:nBox)

slate = zeros(widest,widest)
for j in 1:nBox
    for t in 1:T[j]
        global slate
        #println(t, "  ", j)
        f = boldXiTJ(x,t,j,false)
        slate += f*f'
    end
end


W = inv((1.0/tot)*slate)

func(x) = boldXiS( x, false)
#Re-Estimate the model using the new W
#J = ForwardDiff.jacobian( func, x )
#firstPar = inv( convert(Matrix{Float64},J' * W * J ) )
#varEst = (J'*TSLSW*J) \ ( J'*TSLSW*W*TSLSW'*J ) / (J'*TSLSW*J)

#stdErrors = [sqrt(varEst[i,i]) for i in 1:length(x)]

TwoStageX = EstimateModel( contentProbs, contentPrices, dataMat, bigZ, W, widest, T,
                           K, KL, nBox,  x, false)

# Final Statistics
# ----------------
# Final objective value               =   8.71674937414742e-01
# Final feasibility error (abs / rel) =   1.00e-12 / 2.03e-14
# Final optimality error  (abs / rel) =   1.06e-05 / 5.76e-07
# # of iterations                     =        323 
# # of CG iterations                  =          0 
# # of function evaluations           =        330
# # of gradient evaluations           =        325
# Total program time (secs)           =    2370.29126 (  2370.112 CPU time)
# Time spent in evaluations (secs)    =    1760.17639

# ===============================================================================

#  1.3063215196562323   
#  0.9131016988258991   
#  0.9999998735684159   
#  0.9999993099625579   
# -1.7918430066070015e-7
#  0.479799929976823    
#  0.6403221005467947   
#  0.9999999586432163   
#  0.999999961685922    
# -0.9931198800806328  


TwoStageX = convert(Vector{Real},TwoStageX)
slate = zeros(widest,widest)
for j in 1:nBox
    for t in 1:T[j]
        global slate
        #println(t, "  ", j)
        f = boldXiTJ(TwoStageX,t,j, false)
        slate += f*f'
    end
end


W = inv((1.0/tot)*slate)

J = ForwardDiff.jacobian( func, TwoStageX )[1:5]
varEst = inv( convert(Matrix{Float64},J' * W * J ) )

 

stdErrors = [sqrt(varEst[i,i]) for i in 1:length(x)]
#  3.199452543235351 
#  6.269299038601584 
#  3.1350439571802786
#  7.417031241454985 
# 10.271609599865902 
#  9.488229095149913 
# 23.9868868549652   
# 20.147182306567217 
# 16.357626543252415 
# 20.9880109812606   

TwoStageX = EstimateModel( contentProbs, contentPrices, dataMat, bigZ, W, widest, T,
                           K, KL, nBox,  TwoStageX, false)

# Final Statistics
# ----------------
# Final objective value               =   6.16020746607278e-01
# Final feasibility error (abs / rel) =   3.63e-12 / 4.67e-14
# Final optimality error  (abs / rel) =   1.14e-05 / 7.87e-07
# # of iterations                     =        259 
# # of CG iterations                  =         16 
# # of function evaluations           =        310
# # of gradient evaluations           =        261
# Total program time (secs)           =    2014.82495 (  2013.903 CPU time)
# Time spent in evaluations (secs)    =    1497.03052

# ===============================================================================
#  1.2949150326957228  
#  0.8442570186053501  
#  0.9999999874813716  
#  0.9999999411547855  
# -1.794427358186775e-8
#  0.5862931111161834  
#  0.3836257401189918  
#  0.9999999847204135  
#  0.9999999883578421  
# -1.4928934210163254

TwoStageX = convert(Vector{Real},TwoStageX)
slate = zeros(widest,widest)
for j in 1:nBox
    for t in 1:T[j]
        global slate
        #println(t, "  ", j)
        f = boldXiTJ(TwoStageX,t,j,false)
        slate += f*f'
    end
end


W = inv((1.0/tot)*slate)
TwoStageX = EstimateModel( contentProbs, contentPrices, dataMat, bigZ, W, widest, T,
                           K, KL, nBox,  TwoStageX, false)
# Final Statistics
# ----------------
# Final objective value               =   5.97985786677539e-01
# Final feasibility error (abs / rel) =   1.03e-12 / 1.42e-14
# Final optimality error  (abs / rel) =   3.91e-06 / 6.04e-07
# # of iterations                     =        228 
# # of CG iterations                  =          0 
# # of function evaluations           =        230
# # of gradient evaluations           =        230
# Total program time (secs)           =    1559.13037 (  1559.017 CPU time)
# Time spent in evaluations (secs)    =    1099.14526

# ===============================================================================
#   1.285332276751168   
#   0.7911102272284904  
#   0.9999999599036227  
#   0.9999999176651859  
#  -3.921183464826817e-8
#   0.6716310210692721  
#   0.2790476019955516  
#   0.9999999673314469  
#   0.9999999818155321  
#  -1.772617631347913 
TwoStageX = convert(Vector{Real},TwoStageX)
slate = zeros(widest,widest)
for j in 1:nBox
    for t in 1:T[j]
        global slate
        #println(t, "  ", j)
        f = boldXiTJ(TwoStageX,t,j,false)
        slate += f*f'
    end
end


W = inv((1.0/tot)*slate)

J = ForwardDiff.jacobian( func, TwoStageX )#[:,1:5]
varEst = inv( convert(Matrix{Float64},J' * W * J ) )
stdErrors = [sqrt(varEst[i,i]) for i in 1:size(varEst,1)]


#  3.323785185269059 
#  6.203146706858448 
#  3.2260739626977477
#  7.46509444742952  
# 11.863060500114432 
#  9.194758766501746 
#  8.970867156234847 
# 12.897490083024893 
#  5.048227635817969 
#  6.068960521564928 


#-----------------------------------------------------------
#Single Estimate Model

# Final Statistics
# ----------------
# Final objective value               =   7.05710171438247e-01
# Final feasibility error (abs / rel) =   2.53e-11 / 1.68e-11
# Final optimality error  (abs / rel) =   3.62e-05 / 5.92e-07
# # of iterations                     =        102 
# # of CG iterations                  =          0 
# # of function evaluations           =        104
# # of gradient evaluations           =        104
# Total program time (secs)           =     711.10059 (   711.058 CPU time)
# Time spent in evaluations (secs)    =     491.62891

# ===============================================================================

# 10-element Array{Float64,1}:
#   0.47457512741755825
#   0.5466738788208474 
#   0.9999999971234642 
#   0.9999999970490249 
#  -1.2149618905415727 
#  81.34323381493454   
#  67.58916760871001   
#   0.6785355628216312 
#   0.21090991136209136
#  -0.7376533826211099 

# VarCov Matrix
#   29.2338   -78.427    54.5134   -43.9726   -74.803
#  -78.427    212.275  -150.762    121.698    200.399
#   54.5134  -150.762   120.344   -108.656   -135.755
#  -43.9726   121.698  -108.656    117.849    107.504
#  -74.803    200.399  -135.755    107.504    194.402

# stdErrors
#   5.40683235673159 
#  14.569667319489948
#  10.970141250082516
#  10.855832443020974
#  13.942815792414633


# tot = sum( T[j] for j in 1:nBox)

# slate = zeros(widest,widest)
# for j in 1:nBox
#     for t in 1:T[j]
#         global slate
#         #println(t, "  ", j)
#         f = boldXiTJCRRA(ccra,t,j)
#         slate += f*f'
#     end
# end


# W = inv((1.0/tot)*slate)













