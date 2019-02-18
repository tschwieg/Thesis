#!/usr/bin/python
# -*- coding: utf-8 -*-

import re
import os
import glob
import csv
from datetime import datetime as dt

Roles = {
'HuntsmanKnife': "knife",
 'Sawed-Off': "shotgun",
 'FalchionKnife': "knife",
 'UMP-45': "smg",
 'USP-S': "dPistol",
 'GalilAR': "cheapRifle",
 'Nova': "shotgun",
 'GutKnife': "knife",
 'XM1014': "shotgun",
 'AWP': "awp",
 'MP9': "smg",
 'Negev': "lmg",
 'DualBerettas': "pistol",
 'P2000': "dPistol",
 'SCAR-20': "scopedRifle",
 'M4A1-S': "mainRifle",
 'G3SG1': "scopedRifle",
 'ButterflyKnife': "knife",
 'Five-SeveN': "pistol",
 'M4A4': "mainRifle",
 'Bayonet': "knife",
 'M9Bayonet': "knife",
 'Glock-18': "dPistol",
 'MAG-7': "shotgun",
 'Karambit': "knife",
 'SG553': "scopedRifle",
 'AUG': "scopedRifle",
 'SSG08': "scopedRifle",
 'BowieKnife': "knife",
 'MP7': "smg",
 'CZ75-Auto': "pistol",
 'PP-Bizon': "smg",
 'ShadowDaggers': "knife",
 'Tec-9': "pistol",
 'AK-47': "mainRifle",
 'P250': "pistol",
 'M249': "lmg",
 'DesertEagle': "deagle",
 'MAC-10': "smg",
 'FAMAS': "cheapRifle",
 'R8Revolver': "pistol",
 'P90': "cheapRifle",
    'FlipKnife' : "knife",
     'HydraGloves' : "knife",
    'SpecialistGloves' : "knife",
    'BloodhoundGloves' : "knife",
    'SportGloves' : "knife",
    'DriverGloves' : "knife",
    'HandWraps' : "knife",
    'MotoGloves' : "knife"
}

Usage = {
    "default" : 0,
    "AK-47" : 39.46,
    "M4A4" : 16.16,
    "AWP" : 12.93,
    "M4A1-S" : 8.03,
    "USP-S" : 5.13,
    "Glock-18" : 4.01,
    "UMP-45" : 3.34,
    "P250" : 2.79,
    "CZ75-Auto" : 2.79,
    "DesertEagle" : 2.68,
    "FAMAS" : 2.68
}

Conditions = {"FactoryNew" : 5,
              "MinimalWear" : 4,
              "Field-Tested" : 3,
              "Well-Worn" : 2,
              "Battle-Scarred" : 1,
              "vanilla" : 1,
              "Factory New" : 5,
              "Minimal Wear" : 4
}




#keep-lines regX
#[ a-zA-Z'"\-]+
#
#\([a-zA-Z \-]+\) \(Pistol\|Rifle\|Shotgun\|Sniper Rifle\|SMG\|Machine Gun\)

#replace regX
#\([0-9 a-zA-Z'\-]+\)
#
#\([a-zA-Z \-]+\) \(Pistol\|Rifle\|Shotgun\|Sniper Rifle\|SMG\|Machine Gun\) → elif skin == '\1':
#rarity = "\2"
#

def ensure_dir(file_path):
    # directory = os.path.dirname(file_path)
    if not os.path.exists(file_path):
        os.makedirs(file_path)

caseContents = []

Cases = glob.glob("Data/ModifiedKnives/*.csv")
for case in Cases:
    with open(case, "rb") as data:
        contentsCsv = csv.reader(data, delimiter=',')
        contents = [r for r in contentsCsv]
        caseContents.append(contents)
            

#Change StatTrak to 1 if you  uncomment this
#files = glob.glob("Data/StatTrakData/*/*/*.csv")
# Make StatTrak 0.0 for this guy
files = glob.glob("Data/Data/*/*/*.csv")
files += glob.glob("Data/StatTrakData/*/*/*.csv")

skins = {}
weapons = []

throwoutDate = dt.strptime("Feb 28 2018 01: +0", "%b %d %Y %H: +0")
WeekOne = dt.strptime("Mar 09 2018 01: +0", "%b %d %Y %H: +0")
WeekTwo = dt.strptime("Mar 16 2018 01: +0", "%b %d %Y %H: +0")
WeekThree = dt.strptime("Mar 23 2018 01: +0", "%b %d %Y %H: +0")
WeekFour = dt.strptime("Apr 1 2018 01: +0", "%b %d %Y %H: +0")


rows = []

for csvFile in files:
    #print(csvFile)

    dirSplit = csvFile.split("/")

    weapon = dirSplit[2]
    skin = dirSplit[3]
    condition = dirSplit[4]

    role = Roles[weapon]

    if( weapon not in Usage):
        usage = 0.0
    else:
        usage = Usage[weapon]

    conds = condition.split(".csv")[0]

    cond = Conditions[conds]

    if weapon not in weapons:
        weapons.append(weapon)
    

    if( skin in skins ):
        skins[skin] = skins[skin] + 1
    else:
        skins[skin] = 1

    isKnife = False

    rarity = ""
    if( weapon == "HuntsmanKnife" or weapon == 'FalchionKnife' or weapon == 'GutKnife'
        or weapon == 'ButterflyKnife' or weapon == 'Bayonet' or weapon == 'M9Bayonet'
        or weapon == 'Karambit' or weapon == 'BowieKnife' or weapon == 'ShadowDaggers'
        or weapon == 'FlipKnife' or weapon == 'HydraGloves' or weapon == 'SpecialistGloves' or weapon == 'BloodhoundGloves' or weapon == 'SportGloves' or weapon == 'DriverGloves' or weapon == 'HandWraps' or weapon == 'MotoGloves'):
        rarity = "Covert"
        isKnife = True

    #The following lines are several regular expressions applied to skin pages
    #Taken from public information at csgostash.com The regular expressions are
    #commented above, after this, several extra ones were used to clean the
    #text, such as removing spaces, cleaning apostraphes and newlines.
    if weapon == 'Sawed-Off':
        if skin == 'TheKraken':
            rarity = "Covert"
        elif skin == 'Devourer':
            rarity = "Classified"
        elif skin == 'WastelandPrincess':
            rarity = "Classified"
        elif skin == 'Limelight':
            rarity = "Restricted"
        elif skin == 'Serenity':
            rarity = "Restricted"
        elif skin == 'Highwayman':
            rarity = "Restricted"
        elif skin == 'OrangeDDPAT':
            rarity = "Restricted"
        elif skin == 'BlackSand':
            rarity = "Mil-Spec"
        elif skin == 'Morris':
            rarity = "Mil-Spec"
        elif skin == 'Zander':
            rarity = "Mil-Spec"
        elif skin == 'Fubar':
            rarity = "Mil-Spec"
        elif skin == 'Yorick':
            rarity = "Mil-Spec"
        elif skin == 'Origami':
            rarity = "Mil-Spec"
        elif skin == 'BrakeLight':
            rarity = "Mil-Spec"
        elif skin == 'FirstClass':
            rarity = "Mil-Spec"
        elif skin == 'FullStop':
            rarity = "Mil-Spec"
        elif skin == 'AmberFade':
            rarity = "Mil-Spec"
        elif skin == 'Copper':
            rarity = "Mil-Spec"
        elif skin == 'RustCoat':
            rarity = "Industrial Grade"
        elif skin == 'SnakeCamo':
            rarity = "Industrial Grade"
        elif skin == 'Mosaico':
            rarity = "Industrial Grade"
        elif skin == 'BambooShadow':
            rarity = "Consumer Grade"
        elif skin == 'SageSpray':
            rarity = "Consumer Grade"
        elif skin == 'ForestDDPAT':
            rarity = "Consumer Grade"
        elif skin == 'IrradiatedAlert':
            rarity = "Consumer Grade"
    elif weapon == 'Nova':
        if skin == 'HyperBeast':
            rarity = "Classified"
        elif skin == 'Bloomstick':
            rarity = "Classified"
        elif skin == 'Antique':
            rarity = "Classified"
        elif skin == 'ToySoldier':
            rarity = "Restricted"
        elif skin == 'WildSix':
            rarity = "Restricted"
        elif skin == 'Gila':
            rarity = "Restricted"
        elif skin == 'Koi':
            rarity = "Restricted"
        elif skin == 'RisingSkull':
            rarity = "Restricted"
        elif skin == 'Graphite':
            rarity = "Restricted"
        elif skin == 'Wood Fired':
            rarity = "Mil-Spec"
        elif skin == 'Exo':
            rarity = "Mil-Spec"
        elif skin == 'Ranger':
            rarity = "Mil-Spec"
        elif skin == 'GhostCamo':
            rarity = "Mil-Spec"
        elif skin == 'Tempest':
            rarity = "Mil-Spec"
        elif skin == 'BlazeOrange':
            rarity = "Mil-Spec"
        elif skin == 'ModernHunter':
            rarity = "Mil-Spec"
        elif skin == 'GreenApple':
            rarity = "Industrial Grade"
        elif skin == 'CagedSteel':
            rarity = "Industrial Grade"
        elif skin == 'CandyApple':
            rarity = "Industrial Grade"
        elif skin == 'Mandrel':
            rarity = "Consumer Grade"
        elif skin == 'MooninLibra':
            rarity = "Consumer Grade"
        elif skin == 'SandDune':
            rarity = "Consumer Grade"
        elif skin == 'Predator':
            rarity = "Consumer Grade"
        elif skin == 'PolarMesh':
            rarity = "Consumer Grade"
        elif skin == 'ForestLeaves':
            rarity = "Consumer Grade"
        elif skin == 'Walnut':
            rarity = "Consumer Grade"

    elif weapon == 'UMP-45':
        if skin == 'Momentum':
            rarity = "Classified"
        elif skin == 'PrimalSaber':
            rarity = "Classified"
        elif skin == 'ArcticWolf':
            rarity = "Restricted"
        elif skin == 'Exposure':
            rarity = "Restricted"
        elif skin == 'Scaffold':
            rarity = "Restricted"
        elif skin == 'GrandPrix':
            rarity = "Restricted"
        elif skin == 'MetalFlowers':
            rarity = "Mil-Spec"
        elif skin == 'Briefing':
            rarity = "Mil-Spec"
        elif skin == 'Riot':
            rarity = "Mil-Spec"
        elif skin == 'Delusion':
            rarity = "Mil-Spec"
        elif skin == 'Labyrinth':
            rarity = "Mil-Spec"
        elif skin == 'Corporal':
            rarity = "Mil-Spec"
        elif skin == 'BonePile':
            rarity = "Mil-Spec"
        elif skin == 'Minotaur\'sLabyrinth':
            rarity = "Mil-Spec"
        elif skin == 'Blaze':
            rarity = "Mil-Spec"
        elif skin == 'CarbonFiber':
            rarity = "Industrial Grade"
        elif skin == 'Gunsmoke':
            rarity = "Industrial Grade"
        elif skin == 'FalloutWarning':
            rarity = "Industrial Grade"
        elif skin == 'FacilityDark':
            rarity = "Consumer Grade"
        elif skin == 'Mudder':
            rarity = "Consumer Grade"
        elif skin == 'Indigo':
            rarity = "Consumer Grade"
        elif skin == 'Scorched':
            rarity = "Consumer Grade"
        elif skin == 'UrbanDDPAT':
            rarity = "Consumer Grade"
        elif skin == 'Caramel':
            rarity = "Consumer Grade"

        
    elif weapon == 'USP-S':
        if skin == 'Neo-Noir':
            rarity = "Covert"
        elif skin == 'KillConfirmed':
            rarity = "Covert"
        elif skin == 'Cortex':
            rarity = "Classified"
        elif skin == 'Caiman':
            rarity = "Classified"
        elif skin == 'Orion':
            rarity = "Classified"
        elif skin == 'Serum':
            rarity = "Classified"
        elif skin == 'Flashback':
            rarity = "Restricted"
        elif skin == 'Cyrex':
            rarity = "Restricted"
        elif skin == 'Guardian':
            rarity = "Restricted"
        elif skin == 'Overgrowth':
            rarity = "Restricted"
        elif skin == 'DarkWater':
            rarity = "Restricted"
        elif skin == 'RoadRash':
            rarity = "Restricted"
        elif skin == 'Blueprint':
            rarity = "Mil-Spec"
        elif skin == 'LeadConduit':
            rarity = "Mil-Spec"
        elif skin == 'Torque':
            rarity = "Mil-Spec"
        elif skin == 'BloodTiger':
            rarity = "Mil-Spec"
        elif skin == 'Stainless':
            rarity = "Mil-Spec"
        elif skin == 'CheckEngine':
            rarity = "Mil-Spec"
        elif skin == 'BusinessClass':
            rarity = "Mil-Spec"
        elif skin == 'NightOps':
            rarity = "Mil-Spec"
        elif skin == 'ParaGreen':
            rarity = "Industrial Grade"
        elif skin == 'RoyalBlue':
            rarity = "Industrial Grade"
        elif skin == 'ForestLeaves':
            rarity = "Industrial Grade"
            

        
    elif weapon == 'GalilAR':
        if skin == 'Chatterbox':
            rarity = "Covert"
        elif skin == 'SugarRush':
            rarity = "Classified"
        elif skin == 'Eco':
            rarity = "Classified"
        elif skin == 'Signal':
            rarity = "Restricted"
        elif skin == 'CrimsonTsunami':
            rarity = "Restricted"
        elif skin == 'Firefight':
            rarity = "Restricted"
        elif skin == 'StoneCold':
            rarity = "Restricted"
        elif skin == 'OrangeDDPAT':
            rarity = "Restricted"
        elif skin == 'Cerberus':
            rarity = "Restricted"
        elif skin == 'BlackSand':
            rarity = "Mil-Spec"
        elif skin == 'RocketPop':
            rarity = "Mil-Spec"
        elif skin == 'Kami':
            rarity = "Mil-Spec"
        elif skin == 'BlueTitanium':
            rarity = "Mil-Spec"
        elif skin == 'Sandstorm':
            rarity = "Mil-Spec"
        elif skin == 'Shattered':
            rarity = "Mil-Spec"
        elif skin == 'AquaTerrace':
            rarity = "Mil-Spec"
        elif skin == 'Tuxedo':
            rarity = "Mil-Spec"
        elif skin == 'ColdFusion':
            rarity = "Industrial Grade"
        elif skin == 'UrbanRubble':
            rarity = "Industrial Grade"
        elif skin == 'VariCamo':
            rarity = "Industrial Grade"
        elif skin == 'WinterForest':
            rarity = "Industrial Grade"
        elif skin == 'SageSpray':
            rarity = "Consumer Grade"
        elif skin == 'HuntingBlind':
            rarity = "Consumer Grade"


        
    elif weapon == 'XM1014':
        if skin == 'Tranquility':
            rarity = "Classified"
        elif skin == 'Ziggy':
            rarity = "Restricted"
        elif skin == 'Seasons':
            rarity = "Restricted"
        elif skin == 'BlackTie':
            rarity = "Restricted"
        elif skin == 'TecluBurner':
            rarity = "Restricted"
        elif skin == 'HeavenGuard':
            rarity = "Restricted"
        elif skin == 'OxideBlaze':
            rarity = "Mil-Spec"
        elif skin == 'Slipstream':
            rarity = "Mil-Spec"
        elif skin == 'Scumbria':
            rarity = "Mil-Spec"
        elif skin == 'Quicksilver':
            rarity = "Mil-Spec"
        elif skin == 'RedPython':
            rarity = "Mil-Spec"
        elif skin == 'BoneMachine':
            rarity = "Mil-Spec"
        elif skin == 'RedLeather':
            rarity = "Mil-Spec"
        elif skin == 'VariCamoBlue':
            rarity = "Mil-Spec"
        elif skin == 'BlazeOrange':
            rarity = "Mil-Spec"
        elif skin == 'CaliCamo':
            rarity = "Industrial Grade"
        elif skin == 'BlueSteel':
            rarity = "Industrial Grade"
        elif skin == 'FalloutWarning':
            rarity = "Industrial Grade"
        elif skin == 'BlueSpruce':
            rarity = "Consumer Grade"
        elif skin == 'Jungle':
            rarity = "Consumer Grade"
        elif skin == 'UrbanPerforated':
            rarity = "Consumer Grade"
        elif skin == 'Grassland':
            rarity = "Consumer Grade"


        
    elif weapon == 'AWP':
        if skin == 'Neo-Noir':
            rarity = "Covert"
        elif skin == 'OniTaiji':
            rarity = "Covert"
        elif skin == 'HyperBeast':
            rarity = "Covert"
        elif skin == 'Man-o\'-war':
            rarity = "Covert"
        elif skin == 'Asiimov':
            rarity = "Covert"
        elif skin == 'LightningStrike':
            rarity = "Covert"
        elif skin == 'Medusa':
            rarity = "Covert"
        elif skin == 'DragonLore':
            rarity = "Covert"
        elif skin == 'Mortis':
            rarity = "Classified"
        elif skin == 'FeverDream':
            rarity = "Classified"
        elif skin == 'EliteBuild':
            rarity = "Classified"
        elif skin == 'Corticera':
            rarity = "Classified"
        elif skin == 'Redline':
            rarity = "Classified"
        elif skin == 'ElectricHive':
            rarity = "Classified"
        elif skin == 'Graphite':
            rarity = "Classified"
        elif skin == 'BOOM':
            rarity = "Classified"
        elif skin == 'PAW':
            rarity = "Restricted"
        elif skin == 'Phobos':
            rarity = "Restricted"
        elif skin == 'WormGod':
            rarity = "Restricted"
        elif skin == 'PinkDDPAT':
            rarity = "Restricted"
        elif skin == 'PitViper':
            rarity = "Restricted"
        elif skin == 'Acheron':
            rarity = "Mil-Spec"
        elif skin == 'SnakeCamo':
            rarity = "Mil-Spec"
        elif skin == 'SuninLeo':
            rarity = "Industrial Grade"
        elif skin == 'SafariMesh':
            rarity = "Industrial Grade"


        
    elif weapon == 'MP9':
        if skin == 'Airlock':
            rarity = "Classified"
        elif skin == 'Goo':
            rarity = "Restricted"
        elif skin == 'RubyPoisonDart':
            rarity = "Restricted"
        elif skin == 'RoseIron':
            rarity = "Restricted"
        elif skin == 'Hypnotic':
            rarity = "Restricted"
        elif skin == 'Bulldozer':
            rarity = "Restricted"
        elif skin == 'ModestThreat':
            rarity = "Mil-Spec"
        elif skin == 'Capillary':
            rarity = "Mil-Spec"
        elif skin == 'BlackSand':
            rarity = "Mil-Spec"
        elif skin == 'SandScale':
            rarity = "Mil-Spec"
        elif skin == 'Bioleak':
            rarity = "Mil-Spec"
        elif skin == 'DeadlyPoison':
            rarity = "Mil-Spec"
        elif skin == 'Dart':
            rarity = "Mil-Spec"
        elif skin == 'Pandora\'sBox':
            rarity = "Mil-Spec"
        elif skin == 'SettingSun':
            rarity = "Mil-Spec"
        elif skin == 'DarkAge':
            rarity = "Mil-Spec"
        elif skin == 'HotRod':
            rarity = "Mil-Spec"
        elif skin == 'OrangePeel':
            rarity = "Industrial Grade"
        elif skin == 'Slide':
            rarity = "Consumer Grade"
        elif skin == 'GreenPlaid':
            rarity = "Consumer Grade"
        elif skin == 'Storm':
            rarity = "Consumer Grade"
        elif skin == 'SandDashed':
            rarity = "Consumer Grade"
        elif skin == 'DrySeason':
            rarity = "Consumer Grade"


        
    elif weapon == 'Negev':
        if skin == 'Lionfish':
            rarity = "Restricted"
        elif skin == 'PowerLoader':
            rarity = "Restricted"
        elif skin == 'Loudmouth':
            rarity = "Restricted"
        elif skin == 'Dazzle':
            rarity = "Mil-Spec"
        elif skin == 'Man-o\'-war':
            rarity = "Mil-Spec"
        elif skin == 'Bratatat':
            rarity = "Mil-Spec"
        elif skin == 'Desert-Strike':
            rarity = "Mil-Spec"
        elif skin == 'Terrain':
            rarity = "Mil-Spec"
        elif skin == 'AnodizedNavy':
            rarity = "Mil-Spec"
        elif skin == 'Bulkhead':
            rarity = "Industrial Grade"
        elif skin == 'NuclearWaste':
            rarity = "Industrial Grade"
        elif skin == 'CaliCamo':
            rarity = "Industrial Grade"
        elif skin == 'Palm':
            rarity = "Industrial Grade"
        elif skin == 'ArmySheen':
            rarity = "Consumer Grade"


        
    elif weapon == 'DualBerettas':
        if skin == 'CobraStrike':
            rarity = "Classified"
        elif skin == 'TwinTurbo':
            rarity = "Classified"
        elif skin == 'RoyalConsorts':
            rarity = "Restricted"
        elif skin == 'UrbanShock':
            rarity = "Restricted"
        elif skin == 'Marina':
            rarity = "Restricted"
        elif skin == 'Hemoglobin':
            rarity = "Restricted"
        elif skin == 'Duelist':
            rarity = "Restricted"
        elif skin == 'CobaltQuartz':
            rarity = "Restricted"
        elif skin == 'Demolition':
            rarity = "Restricted"
        elif skin == 'Shred':
            rarity = "Mil-Spec"
        elif skin == 'Ventilators':
            rarity = "Mil-Spec"
        elif skin == 'Cartel':
            rarity = "Mil-Spec"
        elif skin == 'DualingDragons':
            rarity = "Mil-Spec"
        elif skin == 'Retribution':
            rarity = "Mil-Spec"
        elif skin == 'Panther':
            rarity = "Mil-Spec"
        elif skin == 'BlackLimba':
            rarity = "Mil-Spec"
        elif skin == 'AnodizedNavy':
            rarity = "Mil-Spec"
        elif skin == 'Stained':
            rarity = "Industrial Grade"
        elif skin == 'MooninLibra':
            rarity = "Consumer Grade"
        elif skin == 'Briar':
            rarity = "Consumer Grade"
        elif skin == 'Contractor':
            rarity = "Consumer Grade"
        elif skin == 'Colony':
            rarity = "Consumer Grade"


        
    elif weapon == 'P2000':
        if skin == 'FireElemental':
            rarity = "Covert"
        elif skin == 'ImperialDragon':
            rarity = "Classified"
        elif skin == 'Corticera':
            rarity = "Classified"
        elif skin == 'OceanFoam':
            rarity = "Classified"
        elif skin == 'Woodsman':
            rarity = "Restricted"
        elif skin == 'Handgun':
            rarity = "Restricted"
        elif skin == 'AmberFade':
            rarity = "Restricted"
        elif skin == 'Scorpion':
            rarity = "Restricted"
        elif skin == 'UrbanHazard':
            rarity = "Mil-Spec"
        elif skin == 'Turf':
            rarity = "Mil-Spec"
        elif skin == 'Oceanic':
            rarity = "Mil-Spec"
        elif skin == 'Imperial':
            rarity = "Mil-Spec"
        elif skin == 'Ivory':
            rarity = "Mil-Spec"
        elif skin == 'Pulse':
            rarity = "Mil-Spec"
        elif skin == 'RedFragCam':
            rarity = "Mil-Spec"
        elif skin == 'Chainmail':
            rarity = "Mil-Spec"
        elif skin == 'Silver':
            rarity = "Mil-Spec"
        elif skin == 'Pathfinder':
            rarity = "Industrial Grade"
        elif skin == 'Grassland':
            rarity = "Industrial Grade"
        elif skin == 'CoachClass':
            rarity = "Industrial Grade"
        elif skin == 'GraniteMarbleized':
            rarity = "Industrial Grade"
        elif skin == 'GrasslandLeaves':
            rarity = "Industrial Grade"


        
    elif weapon == 'SCAR-20':
        if skin == 'Bloodsport':
            rarity = "Classified"
        elif skin == 'Cardiac':
            rarity = "Classified"
        elif skin == 'Cyrex':
            rarity = "Classified"
        elif skin == 'SplashJam':
            rarity = "Classified"
        elif skin == 'Powercore':
            rarity = "Restricted"
        elif skin == 'Emerald':
            rarity = "Restricted"
        elif skin == 'JungleSlipstream':
            rarity = "Mil-Spec"
        elif skin == 'Blueprint':
            rarity = "Mil-Spec"
        elif skin == 'Outbreak':
            rarity = "Mil-Spec"
        elif skin == 'GreenMarine':
            rarity = "Mil-Spec"
        elif skin == 'Grotto':
            rarity = "Mil-Spec"
        elif skin == 'CrimsonWeb':
            rarity = "Mil-Spec"
        elif skin == 'CarbonFiber':
            rarity = "Industrial Grade"
        elif skin == 'Palm':
            rarity = "Industrial Grade"
        elif skin == 'ArmySheen':
            rarity = "Consumer Grade"
        elif skin == 'Storm':
            rarity = "Consumer Grade"
        elif skin == 'Contractor':
            rarity = "Consumer Grade"
        elif skin == 'SandMesh':
            rarity = "Consumer Grade"


        
    elif weapon == 'M4A1-S':
        if skin == 'MechaIndustries':
            rarity = "Covert"
        elif skin == 'Chantico\'sFire':
            rarity = "Covert"
        elif skin == 'GoldenCoil':
            rarity = "Covert"
        elif skin == 'HyperBeast':
            rarity = "Covert"
        elif skin == 'Cyrex':
            rarity = "Covert"
        elif skin == 'Nightmare':
            rarity = "Classified"
        elif skin == 'LeadedGlass':
            rarity = "Classified"
        elif skin == 'Decimator':
            rarity = "Classified"
        elif skin == 'AtomicAlloy':
            rarity = "Classified"
        elif skin == 'Guardian':
            rarity = "Classified"
        elif skin == 'ControlPanel':
            rarity = "Classified"
        elif skin == 'HotRod':
            rarity = "Classified"
        elif skin == 'Knight':
            rarity = "Classified"
        elif skin == 'MasterPiece':
            rarity = "Classified"
        elif skin == 'Flashback':
            rarity = "Restricted"
        elif skin == 'Basilisk':
            rarity = "Restricted"
        elif skin == 'BrightWater':
            rarity = "Restricted"
        elif skin == 'DarkWater':
            rarity = "Restricted"
        elif skin == 'IcarusFell':
            rarity = "Restricted"
        elif skin == 'Nitro':
            rarity = "Restricted"
        elif skin == 'Briefing':
            rarity = "Mil-Spec"
        elif skin == 'BloodTiger':
            rarity = "Mil-Spec"
        elif skin == 'VariCamo':
            rarity = "Mil-Spec"
        elif skin == 'BorealForest':
            rarity = "Industrial Grade"
            

        
    elif weapon == 'G3SG1':
        if skin == 'TheExecutioner':
            rarity = "Classified"
        elif skin == 'Flux':
            rarity = "Classified"
        elif skin == 'Scavenger':
            rarity = "Restricted"
        elif skin == 'HighSeas':
            rarity = "Restricted"
        elif skin == 'Stinger':
            rarity = "Restricted"
        elif skin == 'Chronos':
            rarity = "Restricted"
        elif skin == 'Hunter':
            rarity = "Mil-Spec"
        elif skin == 'Ventilator':
            rarity = "Mil-Spec"
        elif skin == 'OrangeCrash':
            rarity = "Mil-Spec"
        elif skin == 'Murky':
            rarity = "Mil-Spec"
        elif skin == 'AzureZebra':
            rarity = "Mil-Spec"
        elif skin == 'Demeter':
            rarity = "Mil-Spec"
        elif skin == 'GreenApple':
            rarity = "Industrial Grade"
        elif skin == 'VariCamo':
            rarity = "Industrial Grade"
        elif skin == 'ArcticCamo':
            rarity = "Industrial Grade"
        elif skin == 'OrangeKimono':
            rarity = "Consumer Grade"
        elif skin == 'Contractor':
            rarity = "Consumer Grade"
        elif skin == 'JungleDashed':
            rarity = "Consumer Grade"
        elif skin == 'PolarCamo':
            rarity = "Consumer Grade"
        elif skin == 'SafariMesh':
            rarity = "Consumer Grade"
        elif skin == 'DesertStorm':
            rarity = "Consumer Grade"
            

    elif weapon == 'Five-SeveN':
        if skin == 'HyperBeast':
            rarity = "Covert"
        elif skin == 'MonkeyBusiness':
            rarity = "Classified"
        elif skin == 'FowlPlay':
            rarity = "Classified"
        elif skin == 'Triumvirate':
            rarity = "Restricted"
        elif skin == 'Retrobution':
            rarity = "Restricted"
        elif skin == 'CopperGalaxy':
            rarity = "Restricted"
        elif skin == 'CaseHardened':
            rarity = "Restricted"
        elif skin == 'NeonKimono':
            rarity = "Restricted"
        elif skin == 'FlameTest':
            rarity = "Mil-Spec"
        elif skin == 'Capillary':
            rarity = "Mil-Spec"
        elif skin == 'Scumbria':
            rarity = "Mil-Spec"
        elif skin == 'ViolentDaimyo':
            rarity = "Mil-Spec"
        elif skin == 'UrbanHazard':
            rarity = "Mil-Spec"
        elif skin == 'Nightshade':
            rarity = "Mil-Spec"
        elif skin == 'Kami':
            rarity = "Mil-Spec"
        elif skin == 'Nitro':
            rarity = "Mil-Spec"
        elif skin == 'SilverQuartz':
            rarity = "Mil-Spec"
        elif skin == 'HotShot':
            rarity = "Industrial Grade"
        elif skin == 'OrangePeel':
            rarity = "Industrial Grade"
        elif skin == 'CandyApple':
            rarity = "Industrial Grade"
        elif skin == 'Coolant':
            rarity = "Consumer Grade"
        elif skin == 'Contractor':
            rarity = "Consumer Grade"
        elif skin == 'ForestNight':
            rarity = "Consumer Grade"
        elif skin == 'AnodizedGunmetal':
            rarity = "Consumer Grade"
        elif skin == 'Jungle':
            rarity = "Consumer Grade"


    
    elif weapon == 'M4A4':
        if skin == 'Howl':
            rarity = "Contraband"
        elif skin == 'Neo-Noir':
            rarity = "Covert"
        elif skin == 'BuzzKill':
            rarity = "Covert"
        elif skin == 'TheBattlestar':
            rarity = "Covert"
        elif skin == 'RoyalPaladin':
            rarity = "Covert"
        elif skin == 'BulletRain':
            rarity = "Covert"
        elif skin == 'Desert-Strike':
            rarity = "Covert"
        elif skin == 'Asiimov':
            rarity = "Covert"
        elif skin == 'X-Ray':
            rarity = "Covert"
        elif skin == 'Hellfire':
            rarity = "Classified"
        elif skin == 'DesolateSpace':
            rarity = "Classified"
        elif skin == '龍王(DragonKing)':
            rarity = "Classified"
        elif skin == 'Poseidon':
            rarity = "Classified"
        elif skin == 'EvilDaimyo':
            rarity = "Restricted"
        elif skin == 'Griffin':
            rarity = "Restricted"
        elif skin == 'Zirka':
            rarity = "Restricted"
        elif skin == 'Daybreak':
            rarity = "Restricted"
        elif skin == 'ModernHunter':
            rarity = "Restricted"
        elif skin == 'Magnesium':
            rarity = "Mil-Spec"
        elif skin == 'FadedZebra':
            rarity = "Mil-Spec"
        elif skin == 'Converter':
            rarity = "Mil-Spec"
        elif skin == 'RadiationHazard':
            rarity = "Mil-Spec"
        elif skin == 'Mainframe':
            rarity = "Industrial Grade"
        elif skin == 'UrbanDDPAT':
            rarity = "Industrial Grade"
        elif skin == 'Tornado':
            rarity = "Industrial Grade"
        elif skin == 'JungleTiger':
            rarity = "Industrial Grade"
        elif skin == 'DesertStorm':
            rarity = "Industrial Grade"


    elif weapon == 'Glock-18':
        if skin == 'WastelandRebel':
            rarity = "Covert"
        elif skin == 'WaterElemental':
            rarity = "Classified"
        elif skin == 'TwilightGalaxy':
            rarity = "Classified"
        elif skin == 'Moonrise':
            rarity = "Restricted"
        elif skin == 'Weasel':
            rarity = "Restricted"
        elif skin == 'RoyalLegion':
            rarity = "Restricted"
        elif skin == 'Grinder':
            rarity = "Restricted"
        elif skin == 'SteelDisruption':
            rarity = "Restricted"
        elif skin == 'DragonTattoo':
            rarity = "Restricted"
        elif skin == 'NuclearGarden':
            rarity = "Restricted"
        elif skin == 'Fade':
            rarity = "Restricted"
        elif skin == 'Brass':
            rarity = "Restricted"
        elif skin == 'OxideBlaze':
            rarity = "Mil-Spec"
        elif skin == 'Warhawk':
            rarity = "Mil-Spec"
        elif skin == 'OffWorld':
            rarity = "Mil-Spec"
        elif skin == 'Ironwork':
            rarity = "Mil-Spec"
        elif skin == 'Wraiths':
            rarity = "Mil-Spec"
        elif skin == 'BunsenBurner':
            rarity = "Mil-Spec"
        elif skin == 'Catacombs':
            rarity = "Mil-Spec"
        elif skin == 'BlueFissure':
            rarity = "Mil-Spec"
        elif skin == 'Reactor':
            rarity = "Mil-Spec"
        elif skin == 'CandyApple':
            rarity = "Mil-Spec"
        elif skin == 'HighBeam':
            rarity = "Industrial Grade"
        elif skin == 'Night':
            rarity = "Industrial Grade"
        elif skin == 'DeathRattle':
            rarity = "Industrial Grade"
        elif skin == 'Groundwater':
            rarity = "Industrial Grade"
        elif skin == 'SandDune':
            rarity = "Industrial Grade"
            

        
    elif weapon == 'MAG-7':
        if skin == 'SWAG-7':
            rarity = "Restricted"
        elif skin == 'Petroglyph':
            rarity = "Restricted"
        elif skin == 'Praetorian':
            rarity = "Restricted"
        elif skin == 'Heat':
            rarity = "Restricted"
        elif skin == 'CoreBreach':
            rarity = "Restricted"
        elif skin == 'Bulldozer':
            rarity = "Restricted"
        elif skin == 'HardWater':
            rarity = "Mil-Spec"
        elif skin == 'Sonar':
            rarity = "Mil-Spec"
        elif skin == 'CobaltCore':
            rarity = "Mil-Spec"
        elif skin == 'Firestarter':
            rarity = "Mil-Spec"
        elif skin == 'HeavenGuard':
            rarity = "Mil-Spec"
        elif skin == 'Memento':
            rarity = "Mil-Spec"
        elif skin == 'CounterTerrace':
            rarity = "Mil-Spec"
        elif skin == 'Hazard':
            rarity = "Mil-Spec"
        elif skin == 'Silver':
            rarity = "Industrial Grade"
        elif skin == 'MetallicDDPAT':
            rarity = "Industrial Grade"
        elif skin == 'RustCoat':
            rarity = "Consumer Grade"
        elif skin == 'Seabird':
            rarity = "Consumer Grade"
        elif skin == 'Storm':
            rarity = "Consumer Grade"
        elif skin == 'IrradiatedAlert':
            rarity = "Consumer Grade"
        elif skin == 'SandDune':
            rarity = "Consumer Grade"
            

    elif weapon == 'SG553':
        if skin == 'Cyrex':
            rarity = "Classified"
        elif skin == 'Integrale':
            rarity = "Classified"
        elif skin == 'Phantom':
            rarity = "Restricted"
        elif skin == 'Triarch':
            rarity = "Restricted"
        elif skin == 'TigerMoth':
            rarity = "Restricted"
        elif skin == 'Pulse':
            rarity = "Restricted"
        elif skin == 'Bulldozer':
            rarity = "Restricted"
        elif skin == 'DangerClose':
            rarity = "Mil-Spec"
        elif skin == 'Aloha':
            rarity = "Mil-Spec"
        elif skin == 'Aerial':
            rarity = "Mil-Spec"
        elif skin == 'Atlas':
            rarity = "Mil-Spec"
        elif skin == 'WaveSpray':
            rarity = "Mil-Spec"
        elif skin == 'Ultraviolet':
            rarity = "Mil-Spec"
        elif skin == 'AnodizedNavy':
            rarity = "Mil-Spec"
        elif skin == 'DamascusSteel':
            rarity = "Mil-Spec"
        elif skin == 'FalloutWarning':
            rarity = "Industrial Grade"
        elif skin == 'Traveler':
            rarity = "Industrial Grade"
        elif skin == 'GatorMesh':
            rarity = "Industrial Grade"
        elif skin == 'ArmySheen':
            rarity = "Consumer Grade"
        elif skin == 'WavesPerforated':
            rarity = "Consumer Grade"
        elif skin == 'Tornado':
            rarity = "Consumer Grade"
            

        
    elif weapon == 'AUG':
        if skin == 'Chameleon':
            rarity = "Covert"
        elif skin == 'AkihabaraAccept':
            rarity = "Covert"
        elif skin == 'Stymphalian':
            rarity = "Classified"
        elif skin == 'SydMead':
            rarity = "Classified"
        elif skin == 'FleetFlock':
            rarity = "Classified"
        elif skin == 'BengalTiger':
            rarity = "Classified"
        elif skin == 'Aristocrat':
            rarity = "Restricted"
        elif skin == 'Torque':
            rarity = "Restricted"
        elif skin == 'RandomAccess':
            rarity = "Restricted"
        elif skin == 'AmberSlipstream':
            rarity = "Mil-Spec"
        elif skin == 'Triqua':
            rarity = "Mil-Spec"
        elif skin == 'Ricochet':
            rarity = "Mil-Spec"
        elif skin == 'Wings':
            rarity = "Mil-Spec"
        elif skin == 'AnodizedNavy':
            rarity = "Mil-Spec"
        elif skin == 'HotRod':
            rarity = "Mil-Spec"
        elif skin == 'Copperhead':
            rarity = "Mil-Spec"
        elif skin == 'RadiationHazard':
            rarity = "Industrial Grade"
        elif skin == 'Condemned':
            rarity = "Industrial Grade"
        elif skin == 'Sweeper':
            rarity = "Consumer Grade"
        elif skin == 'Daedalus':
            rarity = "Consumer Grade"
        elif skin == 'Storm':
            rarity = "Consumer Grade"
        elif skin == 'Contractor':
            rarity = "Consumer Grade"
        elif skin == 'Colony':
            rarity = "Consumer Grade"
            
            
            
    elif weapon == 'SSG08':
        if skin == 'Dragonfire':
            rarity = "Covert"
        elif skin == 'BloodintheWater':
            rarity = "Covert"
        elif skin == 'BigIron':
            rarity = "Classified"
        elif skin == 'Death\'sHead':
            rarity = "Restricted"
        elif skin == 'GhostCrusader':
            rarity = "Restricted"
        elif skin == 'Necropos':
            rarity = "Mil-Spec"
        elif skin == 'DarkWater':
            rarity = "Mil-Spec"
        elif skin == 'Abyss':
            rarity = "Mil-Spec"
        elif skin == 'Slashed':
            rarity = "Mil-Spec"
        elif skin == 'HandBrake':
            rarity = "Mil-Spec"
        elif skin == 'Detour':
            rarity = "Mil-Spec"
        elif skin == 'AcidFade':
            rarity = "Mil-Spec"
        elif skin == 'TropicalStorm':
            rarity = "Industrial Grade"
        elif skin == 'MayanDreams':
            rarity = "Industrial Grade"
        elif skin == 'SandDune':
            rarity = "Consumer Grade"
        elif skin == 'BlueSpruce':
            rarity = "Consumer Grade"
        elif skin == 'LichenDashed':
            rarity = "Consumer Grade"
            

        
    elif weapon == 'MP7':
        if skin == 'Bloodsport':
            rarity = "Covert"
        elif skin == 'Nemesis':
            rarity = "Classified"
        elif skin == 'Powercore':
            rarity = "Restricted"
        elif skin == 'Impire':
            rarity = "Restricted"
        elif skin == 'SpecialDelivery':
            rarity = "Restricted"
        elif skin == 'OceanFoam':
            rarity = "Restricted"
        elif skin == 'Fade':
            rarity = "Restricted"
        elif skin == 'Akoben':
            rarity = "Mil-Spec"
        elif skin == 'Cirrus':
            rarity = "Mil-Spec"
        elif skin == 'ArmorCore':
            rarity = "Mil-Spec"
        elif skin == 'UrbanHazard':
            rarity = "Mil-Spec"
        elif skin == 'Skulls':
            rarity = "Mil-Spec"
        elif skin == 'FullStop':
            rarity = "Mil-Spec"
        elif skin == 'AnodizedNavy':
            rarity = "Mil-Spec"
        elif skin == 'Whiteout':
            rarity = "Mil-Spec"
        elif skin == 'Motherboard':
            rarity = "Industrial Grade"
        elif skin == 'Gunsmoke':
            rarity = "Industrial Grade"
        elif skin == 'OrangePeel':
            rarity = "Industrial Grade"
        elif skin == 'Asterion':
            rarity = "Consumer Grade"
        elif skin == 'OlivePlaid':
            rarity = "Consumer Grade"
        elif skin == 'ForestDDPAT':
            rarity = "Consumer Grade"
        elif skin == 'ArmyRecon':
            rarity = "Consumer Grade"
        elif skin == 'Groundwater':
            rarity = "Consumer Grade"


        
    elif weapon == 'CZ75-Auto':
        if skin == 'Victoria':
            rarity = "Covert"
        elif skin == 'Xiangliu':
            rarity = "Classified"
        elif skin == 'YellowJacket':
            rarity = "Classified"
        elif skin == 'TheFuschiaIsNow':
            rarity = "Classified"
        elif skin == 'Eco':
            rarity = "Restricted"
        elif skin == 'Tacticat':
            rarity = "Restricted"
        elif skin == 'RedAstor':
            rarity = "Restricted"
        elif skin == 'PolePosition':
            rarity = "Restricted"
        elif skin == 'Tigris':
            rarity = "Restricted"
        elif skin == 'TreadPlate':
            rarity = "Restricted"
        elif skin == 'Chalice':
            rarity = "Restricted"
        elif skin == 'Polymer':
            rarity = "Mil-Spec"
        elif skin == 'Imprint':
            rarity = "Mil-Spec"
        elif skin == 'Hexane':
            rarity = "Mil-Spec"
        elif skin == 'Twist':
            rarity = "Mil-Spec"
        elif skin == 'PoisonDart':
            rarity = "Mil-Spec"
        elif skin == 'CrimsonWeb':
            rarity = "Mil-Spec"
        elif skin == 'Emerald':
            rarity = "Mil-Spec"
        elif skin == 'Nitro':
            rarity = "Mil-Spec"
        elif skin == 'Tuxedo':
            rarity = "Mil-Spec"
        elif skin == 'ArmySheen':
            rarity = "Consumer Grade"
        elif skin == 'GreenPlaid':
            rarity = "Consumer Grade"


        
    elif weapon == 'PP-Bizon':
        if skin == 'JudgementofAnubis':
            rarity = "Covert"
        elif skin == 'HighRoller':
            rarity = "Classified"
        elif skin == 'FuelRod':
            rarity = "Restricted"
        elif skin == 'BlueStreak':
            rarity = "Restricted"
        elif skin == 'Osiris':
            rarity = "Restricted"
        elif skin == 'Antique':
            rarity = "Restricted"
        elif skin == 'NightRiot':
            rarity = "Mil-Spec"
        elif skin == 'JungleSlipstream':
            rarity = "Mil-Spec"
        elif skin == 'Harvester':
            rarity = "Mil-Spec"
        elif skin == 'PhoticZone':
            rarity = "Mil-Spec"
        elif skin == 'WaterSigil':
            rarity = "Mil-Spec"
        elif skin == 'CobaltHalftone':
            rarity = "Mil-Spec"
        elif skin == 'Brass':
            rarity = "Mil-Spec"
        elif skin == 'RustCoat':
            rarity = "Mil-Spec"
        elif skin == 'ModernHunter':
            rarity = "Mil-Spec"
        elif skin == 'CandyApple':
            rarity = "Industrial Grade"
        elif skin == 'ChemicalGreen':
            rarity = "Industrial Grade"
        elif skin == 'NightOps':
            rarity = "Industrial Grade"
        elif skin == 'CarbonFiber':
            rarity = "Industrial Grade"
        elif skin == 'FacilitySketch':
            rarity = "Consumer Grade"
        elif skin == 'BambooPrint':
            rarity = "Consumer Grade"
        elif skin == 'SandDashed':
            rarity = "Consumer Grade"
        elif skin == 'UrbanDashed':
            rarity = "Consumer Grade"
        elif skin == 'ForestLeaves':
            rarity = "Consumer Grade"
        elif skin == 'IrradiatedAlert':
            rarity = "Consumer Grade"


        
    elif weapon == 'Tec-9':
        if skin == 'FuelInjector':
            rarity = "Classified"
        elif skin == 'RemoteControl':
            rarity = "Classified"
        elif skin == 'Re-Entry':
            rarity = "Restricted"
        elif skin == 'Avalanche':
            rarity = "Restricted"
        elif skin == 'TitaniumBit':
            rarity = "Restricted"
        elif skin == 'RedQuartz':
            rarity = "Restricted"
        elif skin == 'NuclearThreat':
            rarity = "Restricted"
        elif skin == 'Fubar':
            rarity = "Mil-Spec"
        elif skin == 'CrackedOpal':
            rarity = "Mil-Spec"
        elif skin == 'CutOut':
            rarity = "Mil-Spec"
        elif skin == 'IceCap':
            rarity = "Mil-Spec"
        elif skin == 'Jambiya':
            rarity = "Mil-Spec"
        elif skin == 'Isaac':
            rarity = "Mil-Spec"
        elif skin == 'Sandstorm':
            rarity = "Mil-Spec"
        elif skin == 'BlueTitanium':
            rarity = "Mil-Spec"
        elif skin == 'Terrace':
            rarity = "Mil-Spec"
        elif skin == 'Toxic':
            rarity = "Mil-Spec"
        elif skin == 'Brass':
            rarity = "Mil-Spec"
        elif skin == 'Ossified':
            rarity = "Mil-Spec"
        elif skin == 'Hades':
            rarity = "Industrial Grade"
        elif skin == 'VariCamo':
            rarity = "Industrial Grade"
        elif skin == 'BambooForest':
            rarity = "Consumer Grade"
        elif skin == 'UrbanDDPAT':
            rarity = "Consumer Grade"
        elif skin == 'ArmyMesh':
            rarity = "Consumer Grade"
        elif skin == 'Groundwater':
            rarity = "Consumer Grade"
        elif skin == 'Tornado':
            rarity = "Consumer Grade"
            
            
        
    elif weapon == 'AK-47':
        if skin == 'Asiimov':
            rarity = "Covert"
        elif skin == 'NeonRider':
            rarity = "Covert"
        elif skin == 'TheEmpress':
            rarity = "Covert"
        elif skin == 'Bloodsport':
            rarity = "Covert"
        elif skin == 'NeonRevolution':
            rarity = "Covert"
        elif skin == 'FuelInjector':
            rarity = "Covert"
        elif skin == 'AquamarineRevenge':
            rarity = "Covert"
        elif skin == 'WastelandRebel':
            rarity = "Covert"
        elif skin == 'Jaguar':
            rarity = "Covert"
        elif skin == 'Vulcan':
            rarity = "Covert"
        elif skin == 'FireSerpent':
            rarity = "Covert"
        elif skin == 'PointDisarray':
            rarity = "Classified"
        elif skin == 'FrontsideMisty':
            rarity = "Classified"
        elif skin == 'Cartel':
            rarity = "Classified"
        elif skin == 'Redline':
            rarity = "Classified"
        elif skin == 'CaseHardened':
            rarity = "Classified"
        elif skin == 'Asiimov':
            rarity = "Covert"
        elif skin == 'NeonRider':
            rarity = "Covert"
        elif skin == 'TheEmpress':
            rarity = "Covert"
        elif skin == 'Bloodsport':
            rarity = "Covert"
        elif skin == 'NeonRevolution':
            rarity = "Covert"
        elif skin == 'FuelInjector':
            rarity = "Covert"
        elif skin == 'AquamarineRevenge':
            rarity = "Covert"
        elif skin == 'WastelandRebel':
            rarity = "Covert"
        elif skin == 'Jaguar':
            rarity = "Covert"
        elif skin == 'Vulcan':
            rarity = "Covert"
        elif skin == 'FireSerpent':
            rarity = "Covert"
        elif skin == 'PointDisarray':
            rarity = "Classified"
        elif skin == 'FrontsideMisty':
            rarity = "Classified"
        elif skin == 'Cartel':
            rarity = "Classified"
        elif skin == 'Redline':
            rarity = "Classified"
        elif skin == 'CaseHardened':
            rarity = "Classified"
        elif skin == 'RedLaminate':
            rarity = "Classified"
        elif skin == 'Hydroponic':
            rarity = "Classified"
        elif skin == 'JetSet':
            rarity = "Classified"
        elif skin == 'OrbitMk01':
            rarity = "Restricted"
        elif skin == 'BlueLaminate':
            rarity = "Restricted"
        elif skin == 'SafetyNet':
            rarity = "Restricted"
        elif skin == 'FirstClass':
            rarity = "Restricted"
        elif skin == 'EmeraldPinstripe':
            rarity = "Restricted"
        elif skin == 'EliteBuild':
            rarity = "Mil-Spec"
        elif skin == 'BlackLaminate':
            rarity = "Mil-Spec"
        elif skin == 'SafariMesh':
            rarity = "Industrial Grade"
        elif skin == 'JungleSpray':
            rarity = "Industrial Grade"
        elif skin == 'Predator':
            rarity = "Industrial Grade"
            
            
            
    elif weapon == 'P250':
        if skin == 'SeeYaLater':
            rarity = "Covert"
        elif skin == 'Asiimov':
            rarity = "Classified"
        elif skin == 'Muertos':
            rarity = "Classified"
        elif skin == 'Cartel':
            rarity = "Classified"
        elif skin == 'Undertow':
            rarity = "Classified"
        elif skin == 'Mehndi':
            rarity = "Classified"
        elif skin == 'Franklin':
            rarity = "Classified"
        elif skin == 'Nevermore':
            rarity = "Restricted"
        elif skin == 'RedRock':
            rarity = "Restricted"
        elif skin == 'Wingshot':
            rarity = "Restricted"
        elif skin == 'Supernova':
            rarity = "Restricted"
        elif skin == 'Splash':
            rarity = "Restricted"
        elif skin == 'VinoPrimo':
            rarity = "Restricted"
        elif skin == 'NuclearThreat':
            rarity = "Restricted"
        elif skin == 'Ripple':
            rarity = "Mil-Spec"
        elif skin == 'IronClad':
            rarity = "Mil-Spec"
        elif skin == 'Valence':
            rarity = "Mil-Spec"
        elif skin == 'SteelDisruption':
            rarity = "Mil-Spec"
        elif skin == 'Hive':
            rarity = "Mil-Spec"
        elif skin == 'Exchanger':
            rarity = "Mil-Spec"
        elif skin == 'Whiteout':
            rarity = "Mil-Spec"
        elif skin == 'ModernHunter':
            rarity = "Mil-Spec"
        elif skin == 'CrimsonKimono':
            rarity = "Industrial Grade"
        elif skin == 'Contamination':
            rarity = "Industrial Grade"
        elif skin == 'MetallicDDPAT':
            rarity = "Industrial Grade"
        elif skin == 'Facets':
            rarity = "Industrial Grade"
        elif skin == 'Gunsmoke':
            rarity = "Industrial Grade"
        elif skin == 'FacilityDraft':
            rarity = "Consumer Grade"
        elif skin == 'MintKimono':
            rarity = "Consumer Grade"
        elif skin == 'BorealForest':
            rarity = "Consumer Grade"
        elif skin == 'SandDune':
            rarity = "Consumer Grade"
        elif skin == 'BoneMask':
            rarity = "Consumer Grade"


         

    elif weapon == 'M249':
        if skin == 'EmeraldPoisonDart':
            rarity = "Restricted"
        elif skin == 'NebulaCrusader':
            rarity = "Restricted"
        elif skin == 'Spectre':
            rarity = "Mil-Spec"
        elif skin == 'SystemLock':
            rarity = "Mil-Spec"
        elif skin == 'Magma':
            rarity = "Mil-Spec"
        elif skin == 'ShippingForecast':
            rarity = "Industrial Grade"
        elif skin == 'GatorMesh':
            rarity = "Industrial Grade"
        elif skin == 'BlizzardMarbleized':
            rarity = "Industrial Grade"
        elif skin == 'ImpactDrill':
            rarity = "Consumer Grade"
        elif skin == 'ContrastSpray':
            rarity = "Consumer Grade"
        elif skin == 'JungleDDPAT':
            rarity = "Consumer Grade"
            
            
    elif weapon == 'DesertEagle':
        if skin == 'CodeRed':
            rarity = "Covert"
        elif skin == 'GoldenKoi':
            rarity = "Covert"
        elif skin == 'MechaIndustries':
            rarity = "Classified"
        elif skin == 'KumichoDragon':
            rarity = "Classified"
        elif skin == 'Conspiracy':
            rarity = "Classified"
        elif skin == 'CobaltDisruption':
            rarity = "Classified"
        elif skin == 'Hypnotic':
            rarity = "Classified"
        elif skin == 'Directive':
            rarity = "Restricted"
        elif skin == 'Naga':
            rarity = "Restricted"
        elif skin == 'CrimsonWeb':
            rarity = "Restricted"
        elif skin == 'Heirloom':
            rarity = "Restricted"
        elif skin == 'SunsetStorm弐':
            rarity = "Restricted"
        elif skin == 'HandCannon':
            rarity = "Restricted"
        elif skin == 'Pilot':
            rarity = "Restricted"
        elif skin == 'Blaze':
            rarity = "Restricted"
        elif skin == 'OxideBlaze':
            rarity = "Mil-Spec"
        elif skin == 'Corinthian':
            rarity = "Mil-Spec"
        elif skin == 'BronzeDeco':
            rarity = "Mil-Spec"
        elif skin == 'Meteorite':
            rarity = "Mil-Spec"
        elif skin == 'UrbanRubble':
            rarity = "Mil-Spec"
        elif skin == 'Night':
            rarity = "Industrial Grade"
        elif skin == 'MidnightStorm':
            rarity = "Industrial Grade"
        elif skin == 'UrbanDDPAT':
            rarity = "Industrial Grade"
        elif skin == 'Mudder':
            rarity = "Industrial Grade"

        
    elif weapon == 'MAC-10':
        if skin == 'NeonRider':
            rarity = "Covert"
        elif skin == 'PipeDown':
            rarity = "Restricted"
        elif skin == 'LastDive':
            rarity = "Restricted"
        elif skin == 'Malachite':
            rarity = "Restricted"
        elif skin == 'Tatter':
            rarity = "Restricted"
        elif skin == 'Curse':
            rarity = "Restricted"
        elif skin == 'Heat':
            rarity = "Restricted"
        elif skin == 'Graven':
            rarity = "Restricted"
        elif skin == 'Oceanic':
            rarity = "Mil-Spec"
        elif skin == 'Aloha':
            rarity = "Mil-Spec"
        elif skin == 'Carnivore':
            rarity = "Mil-Spec"
        elif skin == 'LapisGator':
            rarity = "Mil-Spec"
        elif skin == 'Rangeen':
            rarity = "Mil-Spec"
        elif skin == 'Ultraviolet':
            rarity = "Mil-Spec"
        elif skin == 'Fade':
            rarity = "Mil-Spec"
        elif skin == 'NuclearGarden':
            rarity = "Mil-Spec"
        elif skin == 'AmberFade':
            rarity = "Mil-Spec"
        elif skin == 'CalfSkin':
            rarity = "Industrial Grade"
        elif skin == 'Commuter':
            rarity = "Industrial Grade"
        elif skin == 'Silver':
            rarity = "Industrial Grade"
        elif skin == 'Palm':
            rarity = "Industrial Grade"
        elif skin == 'CandyApple':
            rarity = "Industrial Grade"
        elif skin == 'Indigo':
            rarity = "Consumer Grade"
        elif skin == 'UrbanDDPAT':
            rarity = "Consumer Grade"
        elif skin == 'Tornado':
            rarity = "Consumer Grade"
            
        
    elif weapon == 'FAMAS':
        if skin == 'RollCage':
            rarity = "Covert"
        elif skin == 'Eye of Athena':
            rarity = "Classified"
        elif skin == 'MechaIndustries':
            rarity = "Classified"
        elif skin == 'Djinn':
            rarity = "Classified"
        elif skin == 'Afterimage':
            rarity = "Classified"
        elif skin == 'Valence':
            rarity = "Restricted"
        elif skin == 'NeuralNet':
            rarity = "Restricted"
        elif skin == 'Sergeant':
            rarity = "Restricted"
        elif skin == 'Pulse':
            rarity = "Restricted"
        elif skin == 'Styx':
            rarity = "Restricted"
        elif skin == 'Spitfire':
            rarity = "Restricted"
        elif skin == 'Macabre':
            rarity = "Mil-Spec"
        elif skin == 'SurvivorZ':
            rarity = "Mil-Spec"
        elif skin == 'Hexane':
            rarity = "Mil-Spec"
        elif skin == 'Doomkitty':
            rarity = "Mil-Spec"
        elif skin == 'Teardown':
            rarity = "Mil-Spec"
        elif skin == 'Cyanospatter':
            rarity = "Industrial Grade"
        elif skin == 'Colony':
            rarity = "Consumer Grade"
        elif skin == 'ContrastSpray':
            rarity = "Consumer Grade"
            
            
    elif weapon == 'R8Revolver':
        if skin == 'Fade':
            rarity = "Covert"
        elif skin == 'LlamaCannon':
            rarity = "Classified"
        elif skin == 'AmberFade':
            rarity = "Classified"
        elif skin == 'Reboot':
            rarity = "Restricted"
        elif skin == 'Survivalist':
            rarity = "Mil-Spec"
        elif skin == 'Grip':
            rarity = "Mil-Spec"
        elif skin == 'CrimsonWeb':
            rarity = "Mil-Spec"
        elif skin == 'Nitro':
            rarity = "Industrial Grade"
        elif skin == 'BoneMask':
            rarity = "Consumer Grade"
            
        
    elif weapon == 'P90':
        if skin == 'Asiimov':
            rarity = "Covert"
        elif skin == 'DeathbyKitty':
            rarity = "Covert"
        elif skin == 'ShallowGrave':
            rarity = "Classified"
        elif skin == 'Shapewood':
            rarity = "Classified"
        elif skin == 'Trigon':
            rarity = "Classified"
        elif skin == 'ColdBlooded':
            rarity = "Classified"
        elif skin == 'EmeraldDragon':
            rarity = "Classified"
        elif skin == 'DeathGrip':
            rarity = "Restricted"
        elif skin == 'Chopper':
            rarity = "Restricted"
        elif skin == 'Virus':
            rarity = "Restricted"
        elif skin == 'BlindSpot':
            rarity = "Restricted"
        elif skin == 'Traction':
            rarity = "Mil-Spec"
        elif skin == 'Grim':
            rarity = "Mil-Spec"
        elif skin == 'EliteBuild':
            rarity = "Mil-Spec"
        elif skin == 'Module':
            rarity = "Mil-Spec"
        elif skin == 'DesertWarfare':
            rarity = "Mil-Spec"
        elif skin == 'FacilityNegative':
            rarity = "Mil-Spec"
        elif skin == 'Teardown':
            rarity = "Mil-Spec"
        elif skin == 'GlacierMesh':
            rarity = "Mil-Spec"
        elif skin == 'Leather':
            rarity = "Industrial Grade"
        elif skin == 'AshWood':
            rarity = "Industrial Grade"
        elif skin == 'FalloutWarning':
            rarity = "Industrial Grade"
        elif skin == 'Storm':
            rarity = "Consumer Grade"
        elif skin == 'Scorched':
            rarity = "Consumer Grade"
        elif skin == 'SandSpray':
            rarity = "Consumer Grade"

    if rarity == "":
        print( csvFile)

    rarityVal = 0.0
    if rarity == "Consumer Grade":
        rarityVal = 0.0#continue
    elif rarity == "Industrial Grade":
        rarityVal = 0.0
    elif rarity == "Mil-Spec":
        rarityVal = 1.0
    elif rarity == "Restricted":
        rarityVal = 2.0
    elif rarity == "Classified":
        rarityVal = 3.0
    elif rarity == "Covert":
        rarityVal = 4.0
        
        
    counter = 0
    price = 0#[0,0,0,0]
    quantity = 0#[0,0,0,0]
    statTrak = 1*("StatTrakData" in csvFile)
    with open(csvFile, "rb") as data:
        transactionReader = csv.reader(data, delimiter=',')
        transRows = [r for r in transactionReader]
        for tRow in transRows:
            date = dt.strptime(tRow[0], "%b %d %Y %H: +0")
            if( date < throwoutDate):
                continue
            price += float(tRow[1])*float(tRow[2])
            quantity += int(tRow[2])
            # if( date < WeekOne):
            #     #This is expenditure rather than price
            #     price[0] += float(tRow[1])*float(tRow[2])
            #     quantity[0] += int(tRow[2])
            # if date < WeekTwo:
            #     price[1] += float(tRow[1])*float(tRow[2])
            #     quantity[1] += int(tRow[2])
            # if date < WeekThree:
            #     price[2] += float(tRow[1])*float(tRow[2])
            #     quantity[2] += int(tRow[2])
            # if date < WeekFour:
            #     price[3] += float(tRow[1])*float(tRow[2])
            #     quantity[3] += int(tRow[2])
            counter += 1
    if counter == 0:
        continue

    # for p in range(4):
    #     if( quantity[p] == 0):
    #         print(csvFile)
    #     else:
    #         price[p] /= quantity[p]
    price /= quantity

    caseID = -1
    caseProb = 1.0

    if not isKnife:
        for i in range(len(caseContents)):#case in caseContents:
            inCase = False
            for row in caseContents[i]:
                if weapon == row[0] and skin == row[1] and conds == row[2]:
                    caseID = i
                    caseProb = row[3]
        if caseID == -1:
            continue       

    
    #for p in range(4):
    rows.append( str(price) + "," + str(quantity) + "," + str(usage) + "," + str(cond) + "," + str(rarityVal) + "," + str(statTrak) + "," + weapon + "," + skin + "," + role + "," + str(caseID) + "," + str(caseProb))
    


output = open( "contents.csv", "w")
output.write("price,quantity,usage,condition,rarity,statTrak,weapon,skin,role,caseID,caseProb,market\n")
for row in rows:
    output.write(row + "\n")
output.close()
