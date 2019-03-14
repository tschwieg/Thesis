using Plots
using Printf
pyplot()

# Right now this file is a shit show of me mostly fixing the knives in
# all of the cases that were located in ModifiedKnives, and placing
# them in CaseContents.  I also generate the table used in the data
# section later on.

function cln( x::Float64 )
    return replace(@sprintf("%.5g",x), r"e[\+]?([\-0123456789]+)" => s" \\times 10^{\1}")  
end

#There was a problem with Chroma Case.csv not summing to one that is resolved here.
Case = "ModifiedKnives/Operation Vanguard Weapon Case.csv"
df = CSV.read(Case,header=[:gun,:skin,:wear,:prob,:rarity])

FloatVals = Dict( "FactoryNew" => .07,
                  "MinimalWear" => .08,
                  "Field-Tested" => (.38 - .15),
                  "Well-Worn" => (.45 - .38),
                  "Battle-Scarred" => (1.0 - .45),
                  "vanilla" => 1.0)


defaultKnives = ["Bayonet", "FlipKnife", "GutKnife", "Karambit", "M9Bayonet" ]


NormalCases = ["Revolver Case.csv","Operation Phoenix Weapon Case.csv","Operation Vanguard Weapon Case.csv","CS:GO Weapon Case 3.csv","eSports 2013 Winter Case.csv","eSports 2014 Summer Case.csv","CS:GO Weapon Case 2.csv","Winter Offensive Weapon Case.csv","CS:GO Weapon Case.csv","eSports 2013 Case.csv","Operation Bravo Case.csv"]

NormalSkins = ["vanilla","SafariMesh","UrbanMasked","Night","CrimsonWeb","Fade","CaseHardened","BorealForest","ForestDDPAT","Stained","BlueSteel","Scorched"]


ChromaCases = ["Chroma Case.csv","Chroma 2 Case.csv","Chroma 3 Case.csv"]
ChromaSkins = ["DamascusSteel","Doppler","MarbleFade","TigerTooth","RustCoat","Ultraviolet"]

SpectrumSkins = ChromaSkins
SpectrumKnives = ["FalchionKnife", "HuntsmanKnife", "ButterflyKnife", "ShadowDaggers","BowieKnife"]

GammaCases = ["Gamma Case.csv", "Gamma 2 Case.csv"]
GammaSkins = ["GammaDoppler","Freehand","Autotronic","BrightWater","Lore","BlackLaminate"]



normalKnives = DataFrame( gun=[], skin =[], wear = [], prob = [], rarity = [] )
chromaKnives = DataFrame( gun=[], skin =[], wear = [], prob = [], rarity = [] )
gammaKnives = DataFrame( gun=[], skin =[], wear = [], prob = [], rarity = [] )
spectrumKnives = DataFrame( gun=[], skin =[], wear = [], prob = [], rarity = [] )
for knife in defaultKnives
    for skin in NormalSkins
        for (root, dirs, files) in walkdir("./Data/"*knife*"/"*skin)
            for file in files
                push!(normalKnives, (knife, skin, file[1:(end-4)], FloatVals[file[1:(end-4)]], 1))
            end
        end
    end
    for skin in ChromaSkins
        for (root, dirs, files) in walkdir("./Data/"*knife*"/"*skin)
            for file in files
                push!(chromaKnives, (knife, skin, file[1:(end-4)], FloatVals[file[1:(end-4)]], 1))
            end
        end
    end

    for skin in GammaSkins
         for (root, dirs, files) in walkdir("./Data/"*knife*"/"*skin)
            for file in files
                push!(gammaKnives, (knife, skin, file[1:(end-4)], FloatVals[file[1:(end-4)]], 1))
            end
        end
    end
end

for knife in SpectrumKnives
    for skin in SpectrumSkins
        for (root, dirs, files) in walkdir("./Data/"*knife*"/"*skin)
            for file in files
                push!(spectrumKnives, (knife, skin, file[1:(end-4)], FloatVals[file[1:(end-4)]], 1))
            end
        end
    end
end


function NormalizeKnives( df )
    uniqueKnives = unique( df[:,[1,2]])
    p = .0026 / size(uniqueKnives,1)
    for j in 1:size(uniqueKnives,1)

        knives = @from i in df begin
            @where i.gun == uniqueKnives[j,1] &&
                i.skin == uniqueKnives[j,2]
            @select {i.gun, i.skin, i.wear, i.prob}
            @collect DataFrame
        end

        prob = sum(knives[:,4])
        
        for i in 1:size(df,1)
            if( df[i,1] == uniqueKnives[j,1] &&
                df[i,2] == uniqueKnives[j,2])
                df[i,4] /= prob
                df[i,4] *= p
            end
        end
    end
    
end


NormalizeKnives(normalKnives)
NormalizeKnives(chromaKnives)
NormalizeKnives(gammaKnives)
NormalizeKnives(spectrumKnives)

function FixCase( Cases, knives)
    for case in Cases
        df = CSV.read("ModifiedKnives/"*case,header=[:gun,:skin,:wear,:prob,:rarity])
        newdf = @from i in df begin
            @where i.rarity != 1
            @select {i.gun, i.skin, i.wear, i.prob, i.rarity}
            @collect DataFrame
        end
        newdf = vcat( newdf, knives)
        CSV.write( "CaseContents/"*case, newdf, writeheader=false, delim=",")
    end
end

FixCase( NormalCases, normalKnives )
FixCase( ChromaCases, chromaKnives )
FixCase( GammaCases, gammaKnives )
FixCase( ["Spectrum Case.csv"], spectrumKnives )



# # 0    - 0.07       Factory New
# # 0.07 - 0.15    Minimal Wear
# # 0.15 - 0.38    Field-Tested
# # 0.38 - 0.45    Well-Worn
# # 0.45 - 1       Battle-Scarred



# # #Blue - .7992
# # #Purple - .1598
# # #Pink - .032
# # # Red .0064
# # # Yellow .0026

Rarities = [.0026, .0064, .032, .1598, .7992]

# # probs = []

df = CSV.read("CaseContents/Operation Hydra Case.csv",header=[:gun,:skin,:wear,:prob,:rarity])
subdf =  @from i in df begin
        @where i.rarity == 1
        @select {i.gun, i.skin, i.wear, i.prob, i.rarity}
        @collect DataFrame
    end
NormalizeKnives(subdf)

otherdf = @from i in df begin
        @where i.rarity != 1
        @select {i.gun, i.skin, i.wear, i.prob, i.rarity}
        @collect DataFrame
    end

newdf = vcat( subdf, otherdf)
CSV.write( "CaseContents/Operation Hydra Case.csv", newdf, writeheader=false, delim=",")


rarity = [1,2,3,4,5]
for r in rarity

    subdf =  @from i in df begin
        @where i.rarity == r
        @select {i.gun, i.skin, i.wear, i.prob, i.rarity}
        @collect DataFrame
    end
    NormalizeKnives(subdf)

    uniqueGuns = unique( subdf[:,[1,2]])
    gunProb = Rarities[r] / size(uniqueGuns,1)
    println( "GunProb: ", gunProb)
    for gun in 1:size(uniqueGuns,1)
        guns = @from i in subdf begin
            @where i.gun == uniqueGuns[gun,1] &&
                i.skin == uniqueGuns[gun,2]
            @select {i.gun, i.skin, i.wear, i.prob}
            @collect DataFrame
        end
        println( sum(guns[:,4]))

        # for i in 1:size(guns,1)
        #     println(FloatVals[guns[i,3]])
        #     #guns[i,4] = gunProb*FloatVals[guns[i,3]]
        #     # for j in 1:size(df,1)
        #     #     if( df[j,1] == guns[i,1] && df[j,2] == guns[i,2] &&
        #     #         df[j,3] == guns[i,3])
        #     #         df[j,4] = gunProb*FloatVals[guns[i,3]]
        #     #     end
        #     # end
            
        # end
        # println( sum(guns[:,4]))
    end
    println("\n")
end

# CSV.write( "test.csv", df, writeheader=false, delim=",")



p = cumsum(sort(df[:,4],rev=true))

probs = sum(df[i,4] for i in 317:size(df,1))
for i in 317:size(df,1)
    global probs
    if( df[i,5] != 1)
        probs += df[i,4]
    end
end



plot(p)


j = 5

t = 5

# temp[1] = 2
# temp[3] = 2
# temp[11] = 2
# temp[14] = 2
# temp[20] = 2


probVals = copy(contentProbs[j][t,:])
prev = 0.0
for i in 1:length(probVals)
    global prev
    probVals[i] -= prev
    prev += probVals[i]
end


cdfs =  [mean(contentProbs[j][t,:] for t in 1:size(contentPrices,1)) for j in [1,3,11,14,20]]

mat = Matrix(undef,22,8)

for j in 1:22
    probVals = copy(contentProbs[j][t,:])
    prev = 0.0
    for i in 1:length(probVals)
        probVals[i] -= prev
        prev += probVals[i]
    end
    val =  sum(mean((contentPrices[j][t,:] .+ dataMat[j][t,1] .+ 2.5) .* probVals for t in 1:size(contentPrices,1)))
    df = CSV.read("CaseContents/"*Cases[j],header=[:gun,:skin,:wear,:prob,:rarity])

    
    mat[j,1] = Cases[j]
    mat[j,2] = cln(val)
    mat[j,3] = cln(dataMat[j][t,1] + 2.5)
    mat[j,4] = sum( df[:,5] .== 5)
    mat[j,5] = sum( df[:,5] .== 4)
    mat[j,6] = sum( df[:,5] .== 3)
    mat[j,7] = sum( df[:,5] .== 2)
    mat[j,8] = sum( df[:,5] .== 1)
    println(Cases[j])
    println(val, "      ", dataMat[j][t,1] + 2.5)

    println(sum( df[:,5] .== 5))
    println(sum( df[:,5] .== 4))
    println(sum( df[:,5] .== 3))
    println(sum( df[:,5] .== 2))
    println(sum( df[:,5] .== 1))
    println("\n")
end


plot( cdfs[1] )
plot!( cdfs[2] )
plot!( cdfs[3] )
plot!( cdfs[4] )
plot!( cdfs[5] )

plot!( vals ./ maximum(vals))





















#Here I actually generate some plots

tot = sum( T[j] for j in 1:22)

exValVec = zeros(tot,4)
counter = 1
for j in 1:J
    for t in 1:T[j]
        global counter
        exValVec[counter,1] = exVal[j][t]
        exValVec[counter,2] = dataMat[j][t,1] + 2.50
        exValVec[counter,3] = size(contentProbs[j],2)
        exValVec[counter,4] = j
        counter += 1
    end
end

scatter( exValVec[:,2], exValVec[:,1], zcolor = exValVec[:,3],
         label="Lotteries", xlabel="Price", ylabel="\$\\mathbb{E} V\$",
         zlabel="Contents", markeralpha=1.0)
plot!( 2.5:0.01:7.5, 2.5:0.01:7.5, label="Break-Even" )
savefig( "../Plots/BreakEvenScatter.pdf")

Losses = exValVec[:,2] - exValVec[:,1]
plot(  ylims=(0.0,10.0), xlims=(110.0,500.0), title="Contents vs Losses",
       ylabel="Losses", xlabel="# Contents" )
for j in 1:J
    plotme = exValVec[:,4] .== j
    scatter!( exValVec[plotme,3], Losses[plotme], label = Cases[j][1:end-4], show=true, markershape=:x, markeralpha=.2)
end
savefig( "../Plots/LossesVSizeNoLegend.png")

