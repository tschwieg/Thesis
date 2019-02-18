using DataFrames
using Query
using CSV
using Statistics

df = DataFrame( CSV.File("contents.csv",allowmissing=:none))

roles = unique(df[:role])

nRows = size(df)[1]


newdf = @from i in df begin
    @select {i.price, i.quantity, i.usage, i.condition, i.rarity, i.statTrak,i.role}
    @collect DataFrame
end

newdf = hcat(DataFrame(convert( Matrix{Int64}, zeros(nRows,1))),newdf,DataFrame(zeros(nRows,10)))
rename!(newdf, names(newdf), [:key,:prices,:shares,:usage,:condition,:rarity,:statTrak,:role,:z1,:z2,:z3,:z4,:z5,:z6,:z7,:z8,:z9,:z10])

for i in 1:nRows
    newdf[i,1] = i
    row = df[i,:]
    curRole = row[:role]

    posRoles = roles[roles .!= curRole]
    for r in 1:10
        if curRole[1] != "knife"
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
    io = open("Roles/" * roles[r] * ".tab", "w")
    write(io,"1iampl.tab 1 16\n")
    CSV.write( io, RoleDF[r], delim = "   ")
    close(io)
end

dat = @from i in newdf begin
        #@where i.role != "knife"
        @select {i.key, i.prices, i.shares, i.usage, i.condition, i.rarity, i.statTrak,i.z1,i.z2,i.z3,i.z4,i.z5,i.z6,i.z7,i.z8,i.z9,i.z10}
        @collect DataFrame
end

β = Vector{Vector{Float64}}(undef,length(roles))

for r in 2:length(roles)
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

    Z = hcat( ones(size(dat)[1]), convert(Matrix{Float64},dat[:,goodCols]))

    Y = log.(convert( Vector{Float64}, dat[:shares])) .- log( outsideOption)


    X = hcat( ones(size(dat)[1]), convert(Matrix{Float64},dat[:,endCols]))

    PZ = Z* ((Z'*Z) \ Z')

    β[r] = (X'*PZ*X) \ (X'*PZ*Y)
end


names(roleData)[endCols]
