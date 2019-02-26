using Plots
pyplot()


Case = "ModifiedKnives/Chroma 2 Case.csv"
df = CSV.read(Case,header=[:gun,:skin,:wear,:prob,:rarity])

# 0    - 0.07       Factory New
# 0.07 - 0.15    Minimal Wear
# 0.15 - 0.38    Field-Tested
# 0.38 - 0.45    Well-Worn
# 0.45 - 1       Battle-Scarred

# FloatVals = { "FactoryNew" : .07,
#               "Minimal Wear" : .08,
#               "Field-Tested" : .38 - .15,
#               "Well-Worn" : .45 - .38,
#               "Battle-Scarred" : 1.0 - .45}

# #Blue - .7992
# #Purple - .1598
# #Pink - .032
# # Red .0064
# # Yellow .0026

# Rarities = [.0026, .0064, .032, .1598, .7992]

# probs = []

# subdf =  @from i in df begin
#     @where i.rarity == 5
#     @select {i.gun, i.skin, i.wear, i.prob}
#     @collect DataFrame
# end

# uniqueGuns = unique( subdf[:,[1,2]])
# gunProb = .7992 / size(uniqueGuns,1)
# for gun in 1:size(uniqueGuns,1)
#     guns = @from i in subdf begin
#         @where i.gun == uniqueGuns[gun,1] &&
#             i.skin == uniqueGuns[gun,2]
#         @select {i.gun, i.skin, i.wear, i.prob}
#         @collect DataFrame
#     end

    
# end



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

probVals = copy(contentProbs[j][t,:])
prev = 0.0
for i in 1:length(probVals)
    global prev
    probVals[i] -= prev
    prev += probVals[i]
end


cdfs =  contentProbs[j][t,:]
vals = (contentPrices[j][t,:] .+ dataMat[j][t,1] .+ 2.5) .* probVals

plot( cdfs )
plot!( vals ./ maximum(vals))
