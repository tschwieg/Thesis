using DataFrames
using Query
using CSV
using Statistics
using JuMP
using KNITRO
using LinearAlgebra
using Distributions

df = DataFrame( CSV.File("contents.csv",allowmissing=:none))

roles = unique(df[:role])

nRows = size(df)[1]


newdf = @from i in df begin
    @select {i.price, i.quantity, i.usage, i.condition, i.rarity, i.statTrak,i.role}
    @collect DataFrame
end

newdf = hcat(DataFrame(convert( Matrix{Int64}, zeros(nRows,1))),newdf,DataFrame(zeros(nRows,10)),makeunique=true)
rename!(newdf, names(newdf), [:key,:prices,:shares,:usage,:condition,:rarity,:statTrak,:role,:z1,:z2,:z3,:z4,:z5,:z6,:z7,:z8,:z9,:z10])

for i in 1:nRows
    newdf[i,1] = i
    row = df[i,:]
    curRole = row[:role]

    posRoles = roles[roles .!= curRole]
    for r in 1:10
        if curRole != "knife"
            #println("not knife")
            instr = @from j in df begin
                @where j.caseID == df[i,:caseID] && j.role == posRoles[r]
                @select {j.price, j.caseProb}
                @collect DataFrame
            end
        else
            #println("knife")
            instr = @from j in df begin
                @where j.role == posRoles[r]
                @select {j.price, j.caseProb}
                @collect DataFrame
            end
        end
        
        if size(instr)[1] > 0
            newdf[i,8+r] = mean(instr[z,1] for z in 1:(size(instr)[1])) 
        else
            newdf[i,8+r] = 0.0
        end
        
    end
    #println(i)
end

newdf[:shares] ./=  sum(df[j,2] for j in 1:nRows)

newdf[:rarity] = convert( Vector{Int64},newdf[:rarity])

RoleDF = Vector{DataFrame}(undef,length(roles))

for r in 1:length(roles)
    RoleDF[r] = @from i in newdf begin
        @where i.role == roles[r]
        @select {i.key, i.prices, i.shares, i.usage, i.condition, i.rarity, i.statTrak,i.z1,i.z2,i.z3,i.z4,i.z5,i.z6,i.z7,i.z8,i.z9,i.z10}
        @collect DataFrame
    end
    rows = size(RoleDF[r])[1]
    for i in 1:rows
        RoleDF[r][i,1] = i
    end
    # io = open("Roles/" * roles[r] * ".tab", "w")
    # write(io,"1iampl.tab 1 16\n")
    # CSV.write( io, RoleDF[r], delim = "   ")
    # close(io)
end

dat = @from i in newdf begin
        #@where i.role != "knife"
        @select {i.key, i.prices, i.shares, i.usage, i.condition, i.rarity, i.statTrak,i.z1,i.z2,i.z3,i.z4,i.z5,i.z6,i.z7,i.z8,i.z9,i.z10}
        @collect DataFrame
end

β = Matrix{Float64}(undef,length(roles),6)#Vector{Vector{Float64}}(undef,length(roles))

characteristics = Vector{Matrix{Float64}}(undef,length(roles))
N = Vector{Int64}(undef,length(roles))

for r in 1:length(roles)
    dat = RoleDF[r]
    #Make sure the instrument matrix is full rank
    cols = convert( Vector{Int64}, 4:(size(dat)[2]) )
    goodCols = []
    for i in 1:length(cols)

        mat = hcat( ones(size(dat)[1],1), convert( Matrix{Float64}, hcat( dat[:,goodCols], dat[:,cols[i]] ) ))
        if( det( mat'*mat ) > 1e-7 )
            #deleteat!( zCol,findfirst( x -> x == cols[i], zCol))
            push!( goodCols, cols[i])
        end
    end
    cols = copy(goodCols)

    endCols = [2,4,5,6,7]
    goodCols = []
    for i in 1:length(endCols)
        mat = hcat( ones(size(dat)[1],1), convert( Matrix{Float64}, hcat( dat[:,goodCols],
                                                                          dat[:,endCols[i]] ) ))
        if( det( mat'*mat ) > 1e-7 )
            #deleteat!( zCol,findfirst( x -> x == cols[i], zCol))
            push!( goodCols, endCols[i])
        end
    end
    endCols = copy(goodCols)


    outsideOption = 1.0 - sum( dat[:shares])

    Z = hcat( ones(size(dat)[1]), convert(Matrix{Float64},dat[:,cols]))

    Y = log.(convert( Vector{Float64}, dat[:shares])) .- log( outsideOption)


    X = hcat( ones(size(dat)[1]), convert(Matrix{Float64},dat[:,endCols]))

    

    PZ = Z* ((Z'*Z) \ Z')

    estimate = (X'*PZ*X) \ (X'*PZ*Y)

    exCols = [2,4,5,6,7]

    β[r,1] = estimate[1]

    characteristics[r] = ones(size(X,1),6)
    for j in 1:5
        i = exCols[j]
        if i in endCols
            index = findfirst( x -> x == i, endCols)+1
            β[r,1+j] = estimate[index]
            characteristics[r][:,1+j] = X[:,index]
        else
            β[r,1+j] = 0
            characteristics[r][:,1+j] = zeros(size(X,1))
        end
    end


    coefs = length(endCols)
    N[r] = size(X,1)
    #Demand is given by \Pr( i > j) = 
    
    
end

R = length(roles)

m = Model( with_optimizer(KNITRO.Optimizer))
@variable( m, p[r=1:R,i=1:N[r]])
@variable( m, δ[r=1:R,i=1:N[r]])

for r in 1:R
    for i in 1:N[r]
        set_start_value( p[r,i], characteristics[r][i,2])
        set_start_value( δ[r,i], dot( β[r,:],characteristics[r][i,:]))
    end
end


@NLexpression( m, denom[r=1:R], 1.0 + sum( exp(δ[r,i]) for i in 1:N[r]))
@constraint( m, delta[r=1:R,i=1:N[r]], δ[r,i] == β[r,1] + β[r,2]*p[r,i] +
             sum( β[r,j]*characteristics[r][i,j] for j in 3:6))

@NLobjective(m, Max, sum(p[r,i]*(exp( δ[r,i] ) / denom[r]) for  r in 1:R, i in 1:N[r]) )
optimize!(m)

estP = Vector{Float64}(undef,N)
denEst = JuMP.value(denom)
denStart = 1.0 + sum( exp(dot( β[r,:],X[i,:])) for i in 1:N )
for i in 1:N
    # println( JuMP.value(p[i]))
    # println( X[i,2])
    # println("")

    estP[i] = JuMP.value(p[i])*exp(JuMP.value( δ[i])) / denEst
    # println( estP[i])
    # println( X[i,2]*exp(dot( estimate,X[i,:])) / denStart )
    # println("\n")
end

println( sum(estP[i] for i in 1:N ) - sum( X[i,2]*exp(dot(estimate,X[i,:])) / denStart for i in 1:N ) )


    # W = inv(Z'*Z)


#     coefs = length(endCols)
#     nInst = size(Z,2)

#     nPeople = 25
#     people = rand(Normal(),nPeople,coefs)
    
#     N = size(X,1)

#     #First we get a starting value for ξ
#     m = Model( with_optimizer(KNITRO.Optimizer))
#     @variable(m, ξ[i=1:N])
#     @variable(m, num[i=1:N])

#     @NLexpression( m, denom, 1.0 + sum( exp(ξ[i]) for i in 1:N))
#     @NLconstraint( m, tot[i=1:N], num[i] == log(exp(ξ[i]) / denom) - Y[i] )

#     @NLobjective( m, Min, sum( num[i]*num[i] for i in 1:N))
#     optimize!(m)


#     startVal = Vector{Float64}(undef,N)
#     for i in 1:N
#         startVal[i] = JuMP.value(ξ[i])
            
#     end

    
#     m = Model( with_optimizer(KNITRO.Optimizer))

#     @variable(m,  θ[n=1:2,k=1:coefs], start = 0 )
#     @variable(m, ξ[i=1:N] )
#     @variable(m, boldξ[i=1:N,z=1:nInst])

#     @NLexpression(m, δ[i=1:N],  sum(θ[1,k]*X[i,k] for k in 1:coefs))

#     @NLexpression(m, marketShareGood[i=1:N,j=1:nPeople],
#                   exp( δ[i] + sum( θ[2,k]*people[j,k]*X[i,k] for k in 1:coefs) + ξ[i]))

#     @NLexpression( m, denom[j=1:nPeople],
#                    ( 1 + sum( marketShareGood[l,j] for l in 1:N ) ) )

#     @NLconstraint( m, shares[i=1:N],
#                    Y[i] + log(nPeople) ==
#                    log( sum(marketShareGood[i,j] / denom[j] for j in 1:nPeople )) )
    
#     @NLconstraint( m, boldStuff[i=1:N,z=1:nInst],
#                    boldξ[i,z] == ξ[i]*Z[i,z] )

#     @NLobjective( m, Min,
#                   sum( boldξ[i,q] * W[q,w] * boldξ[i,w] for q in 1:nInst,w in 1:nInst, i in 1:N  ))

#     #exp(x) / (1 + exp(x)) = s

    
#     for i in 1:N
#         set_start_value(ξ[i], startVal[i])
#         for z in 1:nInst
#             set_start_value(boldξ[i], startVal[i]*Z[i,z])
#         end
#     end
    

#     optimize!(m)
    

# end


names(dat)[endCols]
