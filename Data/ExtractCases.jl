using DataFrames
using Query
using CSV
using Statistics

PlayerBaseFile = "chart.csv"

PlayerBase = DataFrame( CSV.File( PlayerBaseFile))

playerBaseFormat = @dateformat_str("y-m-d H:M:S")
PlayerBase[:DateTime] = [DateTime( PlayerBase[j,1], playerBaseFormat )
                         for j in 1:size(PlayerBase,1)]

#"Clutch Case.csv",
#"Spectrum 2 Case.csv",
Cases = ["Chroma 2 Case.csv","Chroma 3 Case.csv","Chroma Case.csv","CS:GO Weapon Case.csv","eSports 2013 Case.csv","eSports 2013 Winter Case.csv","eSports 2014 Summer Case.csv","Falchion Case.csv","Gamma 2 Case.csv","Gamma Case.csv","Glove Case.csv","Huntsman Weapon Case.csv","Operation Bravo Case.csv","Operation Breakout Weapon Case.csv","Operation Hydra Case.csv","Operation Phoenix Weapon Case.csv","Operation Vanguard Weapon Case.csv","Operation Wildfire Case.csv","Revolver Case.csv","Shadow Case.csv","Spectrum Case.csv","Winter Offensive Weapon Case.csv"]



function BuildCaseMatrix( Case::String, PlayerBase::DataFrame)
    contentFile = "ModifiedKnives/"*Case
    caseFile = "Cases/"*Case
    caseDemandFile = caseFile[1:(end-4)] * "_Demand.csv"

    contents = DataFrame( CSV.File(contentFile,allowmissing=:none,header=[:Gun,:Skin,:Wear,:Prob]))

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
    numRows = sum( validRows ) + size(caseDemandData,1)
    rowset = []
    for i in 1:size(caseData,1)
        if validRows[i]
            push!(rowset, i)
        end
    end
    M = length(rowset)


    dataMat = Matrix{Float64}(undef,numRows,6+size(contents,1)*2)
    for i in 1:length(rowset)
        date = caseData[rowset[i],1]
        dataMat[i,1] = caseData[rowset[i],2]
        dataMat[i,2] = caseData[rowset[i],3]

        playerBaseIndex = findfirst( x-> x > date,PlayerBase[:,1])-1
        dataMat[i,3] = PlayerBase[playerBaseIndex,2]
        dataMat[i,4] = PlayerBase[playerBaseIndex,4]
        dataMat[i,5] = 1
        dataMat[i,6] = size(contents,1)
        
        for j in 1:size(contents,1)
            #Get the most recent transaction before the date posted
            index = findfirst( x-> x > date,weaponData[j][:,1])
            #If there was nothing sold during this month, we can only use
            #the most recent transaction, but the findfirst will return
            #nothing so we must manually check for this
            if index == nothing
                index = size(weaponData[j],1)
            else
                index -= 1
            end
            
            
            colIndex = 7+(j-1)*2
            dataMat[i,colIndex] = weaponData[j][index,2]
            dataMat[i,colIndex+1] = weaponData[j][index,3]
        end
    end
    for i in (M+1):numRows
        dataMat[i,1] = caseDemandData[i-M,1]
        dataMat[i,2] = caseDemandData[i-M,2]

        playerBaseIndex = size(PlayerBase,1)
        #Non censored data doesn't need instruments - price is exogenous
        dataMat[i,3] = dataMat[i,1]#PlayerBase[playerBaseIndex,2]
        dataMat[i,4] = dataMat[i,1]#PlayerBase[playerBaseIndex,4]
        dataMat[i,5] = 0
        dataMat[i,6] = size(contents,1)
        
        for j in 1:size(contents,1)
            # For active buy orders, use the last available price
            index = size(weaponData[j],1)
            
            colIndex = 7+(j-1)*2
            #Last active price
            dataMat[i,colIndex] = weaponData[j][index,2]
            #Probability of obtaining it
            dataMat[i,colIndex+1] = contents[j,4]
            #dataMat[i,colIndex+1] = weaponData[j][index,3]
            #println(j)
        end

        indicies = 7.+(1:size(contents,1)-1)*2
        newVec = Vector{Float64}(undef, length(indices)*2)
        prices = dataMat[i,indices]
        #This is the index order that 
        p = sortperm( prices, rev=true)
        prev = 0.0
        for i in 1:length(p)
            newVec[2*(i-1)+1] = prices[p[i]]
            #Probabilities are cumsums
            newVec[2*i] = prices[p[i]+1] + prev
            prev = newVec[2*i]
        end
        dataMat[i,7:end] = newVec
    end
    return dataMat
end

caseMats = Vector{Matrix{Float64}}(undef,length(Cases))
for i in 1:length(Cases)
    caseMats[i] = BuildCaseMatrix(Cases[i], PlayerBase)
end
