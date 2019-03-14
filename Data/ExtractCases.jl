using DataFrames
using Query
using CSV
using Statistics
using Dates

PlayerBaseFile = "chart.csv"

PlayerBase = DataFrame( CSV.File( PlayerBaseFile))

playerBaseFormat = @dateformat_str("y-m-d H:M:S")
PlayerBase[:DateTime] = [DateTime( PlayerBase[j,1], playerBaseFormat )
                         for j in 1:size(PlayerBase,1)]
fmt = @dateformat_str("u d y H")

startDate = DateTime( "Feb 28 2018 01", fmt)
endDate = DateTime( "Mar 31 2018 01", fmt)

x = @from i in PlayerBase begin
    @where i.DateTime > startDate && i.DateTime < endDate
    @select {i.DateTime, i.Players}
    @collect DataFrame
end

AveragePlayers = mean(x.Players)

#"Clutch Case.csv",
#"Spectrum 2 Case.csv",
Cases = ["Chroma 2 Case.csv","Chroma 3 Case.csv","Chroma Case.csv","CS:GO Weapon Case.csv","eSports 2013 Case.csv","eSports 2013 Winter Case.csv","eSports 2014 Summer Case.csv","Falchion Case.csv","Gamma 2 Case.csv","Gamma Case.csv","Glove Case.csv","Huntsman Weapon Case.csv","Operation Bravo Case.csv","Operation Breakout Weapon Case.csv","Operation Hydra Case.csv","Operation Phoenix Weapon Case.csv","Operation Vanguard Weapon Case.csv","Operation Wildfire Case.csv","Revolver Case.csv","Shadow Case.csv","Spectrum Case.csv","Winter Offensive Weapon Case.csv"]





function BuildCaseMatrix( Case::String, PlayerBase::DataFrame, AveragePlayers::Float64)
    contentFile = "CaseContents/"*Case
    caseFile = "Cases/"*Case
    caseDemandFile = caseFile[1:(end-4)] * "_Demand.csv"

    contents = DataFrame( CSV.File(contentFile,allowmissing=:none,header=[:Gun,:Skin,:Wear,:Prob,:rarity]))

    # sumCont = sum(contents[:,4])
    # for i in 1:size(contents,1)
    #     contents[i,4] = contents[i,4] / sumCont
    #     # Sometimes we have floating point problems where the final
    #     # value is equal to 1.000000000000001
    #     if( contents[i,4] > 1.0)
    #         contents[i,4] = 1.0
    #     end
        
    # end
    

    weaponData = Vector{DataFrame}(undef,size(contents,1))

    fmt = @dateformat_str("u d y H")

    for i in 1:size(contents,1)
        filename = "Data/" * contents[i,:Gun] * "/" * contents[i,:Skin] * "/" *
            contents[i,:Wear] * ".csv"
        weaponData[i] = DataFrame( CSV.File( filename, allowmissing=:none,header=[:Date,:Price,:Quantity]))
        weaponData[i][:Date] = [DateTime( weaponData[i][j,1][1:14], fmt ) for j in 1:size(weaponData[i],1)]
        
    end

    caseData = DataFrame( CSV.File( caseFile, allowmissing=:none,header=[:Date,:Price,:Quantity]))
    caseData[:Date] = [DateTime( caseData[j,1][1:14], fmt ) for j in 1:size(caseData,1)]

    caseDemandData = DataFrame( CSV.File( caseDemandFile, allowmissing=:none,header=[:Price,:Quantity]))
    # newQ = caseDemandData[:,2]
    # for i in 2:size(caseDemandData,1)
    #     caseDemandData[i,2] -= newQ[i-1]
    # end
    



    #throwoutDate = dt.strptime("Feb 28 2018 01: +0", "%b %d %Y %H: +0")
    throwoutDate = DateTime( "Feb 28 2018 01", fmt)

    validRows = caseData[:Date] .>= throwoutDate

    temp = unique(Dates.yearmonthday.(caseData[validRows,1]))
    
    numRows = length( temp ) + size(caseDemandData,1)
    # rowset = []
    # for i in 1:size(caseData,1)
    #     if validRows[i]
    #         push!(rowset, i)
    #     end
    # end
    M = length(temp)


    contentPrices = Matrix{Float64}(undef,numRows,size(contents,1))
    contentProbs = Matrix{Float64}(undef,numRows,size(contents,1))
    
    dataMat = Matrix{Float64}(undef,numRows,8)
    for i in 1:length(temp)
        date = temp[i]#caseData[rowset[i],1]
        rows = @from j in caseData begin
            @where Dates.yearmonthday(j.Date) == date 
            @select { j.Date, j.Price, j.Quantity }
            @collect DataFrame
        end

        dataMat[i,2] = sum( rows[:,3])
        dataMat[i,1] = sum(rows[:,2] .* rows[:,3]) / dataMat[i,2]#caseData[rowset[i],2]

        playerBaseIndex = findfirst( x-> Dates.yearmonthday(x) == date,PlayerBase[:,1])
        #Price is exogenous if the price floor is binding.
        #if dataMat[i,1] > .03
            dataMat[i,3] = AveragePlayers - PlayerBase[playerBaseIndex,2]
            dataMat[i,4] = AveragePlayers - PlayerBase[playerBaseIndex-1,2]
            dataMat[i,8] = 0.0
        # else
        #     dataMat[i,3] = 0.0#.03
        #     dataMat[i,4] = 0.0
        #     dataMat[i,8] = .03
        # end
        
        
        dataMat[i,6] = size(contents,1)
        
        for j in 1:size(contents,1)
            #Get the most recent transaction before the date posted
            index = findfirst( x-> Dates.yearmonthday(x) > date,weaponData[j][:,1])
            #If there was nothing sold during this month, we can only use
            #the most recent transaction, but the findfirst will return
            #nothing so we must manually check for this
            if index == nothing
                index = size(weaponData[j],1)
            else
                index -= 1
            end
            
            contentPrices[i,j] = weaponData[j][index,2] - 2.5 - dataMat[i,1]
            contentProbs[i,j] = contents[j,4]
            #dataMat[i,colIndex+1] = weaponData[j][index,3]
        end
        #dataMat[i,1] = 0.0
        dataMat[i,7] = sum(contentPrices[i,:] .< 0.0)
    end
    for i in (M+1):numRows
        dataMat[i,1] = caseDemandData[i-M,1]
        dataMat[i,2] = caseDemandData[i-M,2]

        playerBaseIndex = size(PlayerBase,1)
        #Non censored data doesn't need instruments - price is exogenous
        dataMat[i,3] = 0.0 #dataMat[i,1]#PlayerBase[playerBaseIndex,2]
        dataMat[i,4] = 0.0#PlayerBase[playerBaseIndex,4]
        dataMat[i,5] = dataMat[i,1]
        dataMat[i,6] = size(contents,1)
        
        for j in 1:size(contents,1)
            # For active buy orders, use the last available price
            index = size(weaponData[j],1)
            
            contentPrices[i,j] = weaponData[j][index,2] - 2.5 - dataMat[i,1]
            contentProbs[i,j] = contents[j,4]
        end
        dataMat[i,7] = sum(contentPrices[i,:] .< 0.0)
        dataMat[i,8] = dataMat[i,1] = caseDemandData[i-M,1]
    end

    for i in 1:numRows

        newVec = Vector{Float64}(undef,size(contents,1))
        #This is the index order that 
        p = sortperm( contentPrices[i,:] )
        prev = 0.0
        for z in 1:length(p)
            newVec[z] = contentProbs[i,p[z]] + prev
            prev = newVec[z]
        end
        contentProbs[i,:] = newVec
        contentPrices[i,:] = contentPrices[i,p]
    end
    
    
    return dataMat,contentProbs,contentPrices
end

dataMat = Vector{Matrix{Float64}}(undef,length(Cases))
contentProbs = Vector{Matrix{Float64}}(undef,length(Cases))
contentPrices = Vector{Matrix{Float64}}(undef,length(Cases))
for i in 1:length(Cases)
    println(Cases[i])
    dataMat[i],contentProbs[i],contentPrices[i] =
        BuildCaseMatrix(Cases[i], PlayerBase,AveragePlayers)
end

J = length(Cases)


# for j in 1:J
#     exVal = zeros(size(contentProbs[j],1))
#     for i in 1:size(contentProbs[j],1)
#         prev = 0.0
#         for k in 1:size(contentProbs[j],2)
#             prob = contentProbs[j][i,k] - prev
#             #println(prob*contentPrices[j][i,k])
#             exVal[i] += prob*contentPrices[j][i,k]
#             prev += prob
#         end
#     end
#     for k in 1:size(contentProbs[j],2)
#         contentPrices[j][:,k] -= dataMat[j][:,1] .+ 2.5# + exVal
#     end
#     for i in 1:size(contentProbs[j],1)
#         dataMat[j][i,7] = sum(contentPrices[j][i,:] .< 0.0)
#     end
# end





for i in 1:J
    println( size( contentProbs[i]))
end

T = Vector{Int64}(undef,J)
for j in 1:J
    T[j] = size(contentPrices[j],1)
end










trueProbs = Vector{Matrix{Float64}}(undef,J)
truePrices = Vector{Matrix{Float64}}(undef,J)
casePrices = Vector{Vector{Float64}}(undef,J)
for j in 1:J
    trueProbs[j] = copy(contentProbs[j])
    truePrices[j] = copy(contentPrices[j])
    #println(j)
   # println("\n\n")
    for t in 1:size(contentProbs[j],1)
        #println(t)
        trueProbs[j][t,:] = vcat( [copy(trueProbs[j][t,i]) - copy(trueProbs[j][t,i-1]) for i in length(trueProbs[j][t,:]):-1:2], copy(trueProbs[j][t,1]))[end:-1:1]
        truePrices[j][t,:] = contentPrices[j][t,:] .+ 2.50 .+ dataMat[j][t,1]
    end
end

exVals = Vector{Matrix{Float64}}(undef,22)
exVal = Vector{Vector{Float64}}(undef,22)
for j in 1:J
    exVals[j] = copy(trueProbs[j])
    exVal[j] = zeros(T[j])
    for t in 1:T[j]
        exVals[j][t,:] = trueProbs[j][t,:] .* (contentPrices[j][t,:] .+ 2.50 .+ dataMat[j][t,1] )
        exVal[j][t] = sum( exVals[j][t,i] for i in 1:size(exVals[j],2))
    end    
end

for j in 1:J
    for t in 1:size(contentProbs[j],1)
        contentPrices[j][t,:] = contentPrices[j][t,:] .- exVal[j][t]
        dataMat[j][t,7] = sum(contentPrices[j][t,:] .< 0.0)
    end
end



T .= 31

for j in 1:J
    for i in 1:size(contentProbs[j],1)
        if( dataMat[j][i,3] == 0.0 )
            T[j] = i-1
            break
        end
    end
end

outsideOption = 0.0
for j in 1:J
    global outsideOption
    outsideOption += mean(dataMat[j][:,2])
end
outsideOption /= convert(Float64, J )


for i in 1:J
   
    for t in (T[i]+1):size(contentProbs[i],1)
        #newOutOption = AveragePlayers - sum( dataMat[j][T,2] for j in 1:J) - dataMat[i][t,2]
        newOutOption = mean( dataMat[j][T[i],2] for j in 1:J)
        dataMat[i][t,2] = log((dataMat[i][t,2] + dataMat[i][T[i],2]) )
        dataMat[i][t,5] = log(newOutOption )
    end
end

    
for i in 1:J
        for t in 1:T[i]
        dataMat[i][t,2] = log(dataMat[i][t,2] )
        dataMat[i][t,5] = log(outsideOption )
    end
end
