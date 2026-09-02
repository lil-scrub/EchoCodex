-- Echo Codex: Tome drop-location data
-- Sourced from the community 'World of Echoes' farming map. Coverage is partial;
-- some Tomes have no documented location yet.
EchoCodexZones = {
  ["eastern-kingdoms"] = "Eastern Kingdoms",
  ["kalimdor"] = "Kalimdor",
  ["outland"] = "Outland",
  ["northrend"] = "Northrend",
}

EchoCodexTomes = {
  ["tome-accelerated-decay"] = { name="Accelerated Decay", quality="epic", description="Your damage-over-time effects now benefit from Haste." },
  ["tome-adaptive-power"] = { name="Adaptive Power", quality="epic", description="Increases your damage by 1% for each unique Echo you have active. Additional ranks or qualities of the same Echo do not increase this bonus." },
  ["tome-ambidexterity"] = { name="Ambidexterity", quality="epic", description="Allows you to dual wield. Off-hand damage is reduced by 20%." },
  ["tome-arcane-burn"] = { name="Arcane Burn", quality="rare", description="While above 20% mana, your spell damage done is increased by 15%, but your ressource costs are increased by 50%." },
  ["tome-arcane-cadence"] = { name="Arcane Cadence", quality="rare", description="Casting an offensive spell or ability increases your damage done by 3% for 6 sec. While this effect is active, each different offensive spell or ability you use increases this bonus by an additional 3% and refreshes the duration." },
  ["tome-arcane-density"] = { name="Arcane Density", quality="rare", description="Increases your Spell Power by an amount equal to 5% of your Armor, up to a maximum of 150% of your intellect. Current bonus: @armor0.05LOWERintellect1.5@ Spell Power." },
  ["tome-arcane-hazard"] = { name="Arcane Hazard", quality="rare", description="While 4 or more enemies are within range, the damage of your Arcane Explosion, Blizzard, Flamestrike, and Blast Wave is increased by 20%." },
  ["tome-arcane-surge"] = { name="Arcane Surge", quality="rare", description="Casting a spell or ability has a chance to make your next eligible spell instant-cast. Eligible spells: Arcane Blast, Fireball, Frostbolt, Frostfire Bolt, Pyroblast, Flamestrike." },
  ["tome-arcane-ward"] = { name="Arcane Ward", quality="rare", description="Increases Arcane Resistance by @flat10+lvl0.5@." },
  ["tome-archmage-mark"] = { name="Archmage Mark", quality="rare", description="Dealing Fire, Frost, and Arcane damage within 6 sec increases the damage you deal by 10% for 12 sec." },
  ["tome-armor-mastery"] = { name="Armor Mastery", quality="epic", description="You can equip all armor types." },
  ["tome-battle-rhythm"] = { name="Battle Rhythm", quality="rare", description="Increases your critical strike damage by 1%, plus an additional 1% for every 150 Critical Strike Rating you have. Current bonus: @flat1+critRating0.0066@%" },
  ["tome-battlefield-hazard"] = { name="Battlefield Hazard", quality="rare", description="While 4 or more enemies are within range, the damage of your Thunder Clap, Shockwave, Whirlwind, and Bladestorm is increased by 20%." },
  ["tome-beast-bane"] = { name="Beast Bane", quality="rare", description="Increases your spell power by @flat120+lvl6@ when fighting Beasts." },
  ["tome-beast-slayer"] = { name="Beast Slayer", quality="rare", description="Increases your attack power by @flat180+lvl9@ when fighting Beasts." },
  ["tome-blighted-hazard"] = { name="Blighted Hazard", quality="rare", description="While 4 or more enemies are within range, the damage of your Death and Decay, Blood Boil, Howling Blast, and Corpse Explosion is increased by 20%." },
  ["tome-brittle-forging"] = { name="Brittle Forging", quality="epic", description="Your Fire damage builds Heat on the target. At 10 stacks, the target becomes Brittle for 6 sec, increasing your critical strike chance against it by 20%. While Brittle is active, your next Fire critical strike against the target causes it to Shatter, dealing @flat20+sp1+ap0.5@ Fire damage to enemies within 8 yards. Once Brittle expires, the target cannot gain Heat stacks for 6 sec." },
  ["tome-broodmother-s-fury"] = { name="Broodmother's Fury", quality="epic", description="Your damaging spells and abilities have a chance to apply Searing Cinders for 8 sec, dealing 3385 Fire damage every 1 sec. When Searing Cinders reaches 5 stacks, it triggers Deep Breath, burning all enemies in a line in front of you for 45123 Fire damage and consuming all stacks on the primary target. Deep Breath cannot occur more than once every 6 sec." },
  ["tome-broodmother-s-webbing"] = { name="Broodmother's Webbing", quality="epic", description="When you take damage while below 50% health, you spray webs, dealing 22552 Nature damage to nearby enemies and stunning them for 4 sec. This effect cannot occur more than once every 15 sec." },
  ["tome-call-of-the-lich-king"] = { name="Call of the Lich King", quality="epic", description="Killing an enemy grants a Soul Fragment. At 6 Soul Fragments, they are consumed to summon a Servant of the Lich King for 30 sec. You can have up to 6 Servants active at once." },
  ["tome-champion-s-rally"] = { name="Champion's Rally", quality="epic", description="Your healing spells grant Rally for 8 sec. At 10 stacks, you unleash Champion’s Rally, instantly healing your target for 42782 and granting them Rallying Cry for 6 sec, reducing damage taken by 15% and increasing healing received by 20%. While Rallying Cry is active, 30% of your direct healing on that target is also granted to the most injured nearby ally." },
  ["tome-chill-of-the-bone-wyrm"] = { name="Chill of the Bone Wyrm", quality="epic", description="Dealing Frost damage grants a stack of Rime. At 12 stacks, you unleash Frost Breath in front of you, dealing 39469 Frost damage and leaving enemies hit Brittle for 5 sec. While Brittle is active, your Frost damage against them is increased by 10%. After triggering, you cannot gain Rime stacks for 4 sec." },
  ["tome-cinders-of-the-sanctum"] = { name="Cinders of the Sanctum", quality="epic", description="Dealing Fire damage grants a stack of Cinders. At 12 stacks, you summon a Fire Cyclone for 12 sec., dealing 6771 Fire damage to enemies within 10 yds every 2 sec. After triggering, you cannot gain Cinders stacks for 4 sec." },
  ["tome-constellations"] = { name="Constellations", quality="epic", description="Your critical strikes have a 10% chance to summon a Falling Star that strikes a nearby enemy for @flat10+sp0.5+ap0.25@ Arcane damage. After 5 Falling Stars strike, you trigger Big Bang, dealing @flat100+sp5+ap2.5@ Arcane damage split between all enemies within 12 yards of your target." },
  ["tome-contagion"] = { name="Contagion", quality="epic", description="Damage dealt by your damage-over-time effects has a chance to apply a random damage-over-time effect associated with another class." },
  ["tome-crusader-s-surge"] = { name="Crusader's Surge", quality="rare", description="Casting a spell or ability has a chance to make your next eligible spell instant-cast. Eligible spells : Exorcism, Flash of Light, Holy Light." },
  ["tome-crushing-finish"] = { name="Crushing Finish", quality="rare", description="When you damage a target below 30% health with a melee or ranged attack, you Execute it, dealing @flat10+ap0.5@ Physical damage. Damage is increased by 2% per point of Expertise. Cannot occur more than once every 6 sec per target." },
  ["tome-crypt-lord-s-swarm"] = { name="Crypt Lord's Swarm", quality="epic", description="While in combat, you are enveloped by a Locust Swarm, reducing damage taken by 20% and dealing 5644 Nature damage to nearby enemies every 2 sec." },
  ["tome-curse-of-the-plaguebringer"] = { name="Curse of the Plaguebringer", quality="epic", description="Dealing Shadow damage applies a stack of Infection to the target. At 12 stacks, you afflict the target with Curse of the Plaguebringer for 10 sec, dealing $ Shadow damage every 2 sec. Each time it deals damage, it spreads to a nearby enemy not already affected." },
  ["tome-demon-bane"] = { name="Demon Bane", quality="rare", description="Increases your spell power by @flat120+lvl6@ when fighting Demons." },
  ["tome-demon-slayer"] = { name="Demon Slayer", quality="rare", description="Increases your attack power by @flat180+lvl9@ when fighting Demons." },
  ["tome-demonic-awakening"] = { name="Demonic Awakening", quality="epic", description="When you fall below 35% health, you transform into a Demon for 8 sec. While transformed, your damage is increased by 30%, you leech 15% of damage dealt as health, and your melee attacks strike an additional nearby enemy. Cannot occur more than once every 45 sec." },
  ["tome-divine-surge"] = { name="Divine Surge", quality="rare", description="Casting a spell or ability has a chance to make your next eligible spell instant-cast. Eligible spells: Smite, Holy Fire, Mind Blast, Flash Heal, Greater Heal, Heal, Binding Heal, and Prayer of Healing." },
  ["tome-dragon-slayer"] = { name="Dragon Slayer", quality="rare", description="Increases your attack power by @flat180+lvl9@ when fighting Dragonkin." },
  ["tome-dragonkin-bane"] = { name="Dragonkin Bane", quality="rare", description="Increases your spell power by @flat120+lvl6@ when fighting Dragonkin." },
  ["tome-drillmaster-s-rebuke"] = { name="Drillmaster's Rebuke", quality="epic", description="Your melee attacks have a chance to unleash an Unbalancing Strike, dealing 350% weapon damage and leaving the target Unbalanced, increasing your damage dealt to it by 10% for 6 sec." },
  ["tome-earthen-snap"] = { name="Earthen Snap", quality="rare", description="Your first hit after entering combat roots the target for 1.50 sec." },
  ["tome-earthen-spike"] = { name="Earthen Spike", quality="rare", description="When struck by a melee attack, you have a chance to launch an earthen spike at the attacker, dealing @flat20+armor0.15@ damage to the attacker and nearby enemies. Damage is further increased by your Armor and generates a high amount of threat." },
  ["tome-echoing-tides"] = { name="Echoing Tides", quality="rare", description="Your periodic effects have a 30% chance to flare, causing them to deal damage or healing an additional time. Cannot occur more than once every until cancelled on the same target." },
  ["tome-edict-of-the-four"] = { name="Edict of the Four", quality="epic", description="Your damaging spells and abilities build Edict. At 10 stacks, you invoke an Edict, cycling through the following effects in order: Meteor, Void Zone, Unholy Shadow and Holy Wrath. Each invocation triggers its effect at your target’s location. \\|cff1eff00Meteor : \\|cffffffffDeals 56391 Fire damage, split between all enemies within 8 yds of the impact. \\|cff1eff00Void Zone : \\|cffffffffSummons a Void Zone for until cancelled sec that deals 11278 Shadow damage every 1 sec to enemies within it. \\|cff1eff00Unholy Shadow : \\|cffffffffDeals 22552 Shadow damage, plus 5639 Shadow damage every 1 sec for 8 sec. \\|cff1eff00Holy Wrath : \\|cffffffffHurls Holy bolts that deal 16912 Holy damage to the target, jumping to additional nearby enemies. Damage increases by 50% with each jump." },
  ["tome-edict-of-the-iron-council"] = { name="Edict of the Iron Council", quality="epic", description="Your damaging spells and abilities build Edict. At 10 stacks, you invoke an Edict, cycling through the following effects in order: Rune of Death, Overload, Fusion Punch. \\|cff1eff00Rune of Death : \\|cffffffffSummons a Rune of Death under your target for 8 sec, dealing @flat5+sp0.25+ap0.125@ Shadow damage every half-second to enemies within 13 yards. \\|cff1eff00Overload : \\|cffffffffYou erupt with lightning, dealing @flat35+sp1.75+ap0.875@ Nature damage to enemies within 10 yards. \\|cff1eff00Fusion Punch : \\|cffffffffYour next melee attack deals an additional @flat50+sp2.5+ap1.25@ Nature damage and an additional @flat25+sp1.25+ap0.625@ Nature damage every 1 sec for 6 sec." },
  ["tome-elemental-bane"] = { name="Elemental Bane", quality="rare", description="Increases your spell power by @flat120+lvl6@ when fighting Elementals." },
  ["tome-elemental-slayer"] = { name="Elemental Slayer", quality="rare", description="Increases your attack power by @flat180+lvl9@ when fighting Elementals." },
  ["tome-ember-ward"] = { name="Ember Ward", quality="rare", description="Increases Fire Resistance by @flat10+lvl0.5@." },
  ["tome-emberlord-s-gift"] = { name="Emberlord's Gift", quality="rare", description="Dealing Fire damage grants a stack of Kindling. At 100 stacks, you erupt in flame, dealing @flat90+sp3+ap1.5@ Fire damage to nearby enemies and @flat90+sp3+ap1.5@ additional Fire damage over time for 6 sec. After erupting, you cannot gain Kindling for 6 sec." },
  ["tome-entropic-fusion"] = { name="Entropic Fusion", quality="rare", description="Dealing Fire and Shadow damage within 3 sec increases the damage you deal by 10% for 6 sec." },
  ["tome-eonar-s-seed"] = { name="Eonar's Seed", quality="epic", description="Up to 20% of your overhealing on allies is stored as Eonar’s Seed for 10 sec. When the target health lowers under 50%, it blooms, healing the target aswell as the most injured nearby ally for the stored amount. Stored amount cannot exceed 40% of the target's maximum health." },
  ["tome-essence-tap"] = { name="Essence Tap", quality="rare", description="Damage dealt by your damage-over-time effects has a chance to grant a random ally 1% maximum Mana, 8 Energy, 4 Rage, or 16 Runic Power." },
  ["tome-exposed-heart"] = { name="Exposed Heart", quality="epic", description="Your basic attacks builds Stress. At 12 stacks, you expose your target’s heart for 6 sec, increasing your damage dealt to it by 20%. While Exposed Heart is active, 40% of the damage you deal to the target is also dealt to all enemies within 8 yards of it. While Exposed Heart is active and up to 6 seconds after it expires you cannot generate Stress on any target." },
  ["tome-fel-hazard"] = { name="Fel Hazard", quality="rare", description="While 4 or more enemies are within range, the damage of your Rain of Fire, Hellfire, Shadowflame, and Shadowfury is increased by 20%." },
  ["tome-fel-surge"] = { name="Fel Surge", quality="rare", description="Casting a spell or ability has a chance to make your next eligible spell instant-cast. Eligible spells: Shadow Bolt, Incinerate, Soul Fire, Chaos Bolt, Seed of Corruption, Haunt, Unstable Affliction." },
  ["tome-flame-vents"] = { name="Flame Vents", quality="epic", description="Dodging or Parrying builds Pressure, maximum 1 stack every 0,3 seconds. At 12 stacks, you vent flames for 8 sec, dealing @flat5+stam0.8@ Fire damage every 1 sec to enemies within 0 yards, scaling with your Stamina. While Flame Vents is active, you take 15% reduced damage and your movement speed is increased by an additional 20%." },
  ["tome-fortress-soul"] = { name="Fortress Soul", quality="rare", description="Reduces damage taken by 35%, but reduces damage dealt by 70%. Increases threat generated by 200%." },
  ["tome-frost-bite"] = { name="Frost Bite", quality="rare", description="When struck, you have a 10% chance to freeze the attacker for 3 sec seconds." },
  ["tome-frost-ward"] = { name="Frost Ward", quality="rare", description="Increases Frost Resistance by @flat10+lvl0.5@." },
  ["tome-frostfire-paradox"] = { name="Frostfire Paradox", quality="epic", description="Your Frost damage applies Biting Cold for 6 sec, stacking up to 10 times. Your direct Fire damage against a target with 6 or more stacks Shatters it, consuming all stacks and dealing @flat3+sp0.15+ap0.075@ Frost damage per stack to the target and to enemies within 8 yards." },
  ["tome-giant-bane"] = { name="Giant Bane", quality="rare", description="Increases your spell power by @flat120+lvl6@ when fighting Giants." },
  ["tome-giant-slayer"] = { name="Giant Slayer", quality="rare", description="Increases your attack power by @flat180+lvl9@ when fighting Giants." },
  ["tome-harpoon-barrage"] = { name="Harpoon Barrage", quality="epic", description="Every 8 sec while in combat, you throw Harpoons at up to 5 enemies between 8 and 35 yards away, pulling them to you and Pinning them for 5 sec. Pinned enemies are slowed by 50% and take 15% increased damage from you." },
  ["tome-healing-cadence"] = { name="Healing Cadence", quality="rare", description="Casting a healing spell or ability increases your healing done by 3% for 6 sec. While this effect is active, each different healing spell or ability you use increases this bonus by an additional 3% and refreshes the duration." },
  ["tome-heavy-incantations"] = { name="Heavy Incantations", quality="epic", description="Increases the damage of spells with a base cast time longer than 2.5 seconds by 30%." },
  ["tome-holy-hazard"] = { name="Holy Hazard", quality="rare", description="While 4 or more enemies are within range, the damage of your Holy Nova is increased by 20%." },
  ["tome-hungering-curse"] = { name="Hungering Curse", quality="rare", description="Every 2 sec while in combat, you afflict a nearby enemy with Siphon Life, dealing @sp1.2+ap0.6@ Shadow damage over 12 sec. If the affected target dies, you are healed for @sp0.2+ap0.1@. This effect deals at least 5 damage and heals at least 10 health." },
  ["tome-hunting-hazard"] = { name="Hunting Hazard", quality="rare", description="While 4 or more enemies are within range, the damage of your Volley and Multi-Shot is increased by 20%." },
  ["tome-idol-of-yogg-saron"] = { name="Idol of Yogg-Saron", quality="epic", description="Whenever you kill an enemy, gain a stack of Idol of Yogg-Saron. At 10 stacks, you summon a Thing from Beyond that casts Void Spike at nearby enemies for 20 sec. \\|cff1eff00Void Spike : \\|cffffffffHurls a bolt of dark magic, dealing @flat15+sp0.75+ap0.375@ Shadow damage and @flat5+sp0.2+ap0.1@ Shadow damage to all enemies within 0 yards of the target." },
  ["tome-impaler-s-tribute"] = { name="Impaler's Tribute", quality="epic", description="Your damaging abilities build Impale on the target. At 8 stacks, you Skewer the target for 8 sec, dealing 6766 Physical damage every 1 sec. While Skewered is active, your attacks against the target have a 20% chance to splinter, dealing 9040 Physical damage to up to 5 nearby enemies." },
  ["tome-inspiring-mending"] = { name="Inspiring Mending", quality="epic", description="Your direct healing spells have a 10% chance to grant a random ally a 3% bonus to all attributes for 15 sec. Stacks up to a total of 10%." },
  ["tome-insulated-soul"] = { name="Insulated Soul", quality="rare", description="Reduces the duration of stun effects on you by @flat30@%." },
  ["tome-leeching-swarm"] = { name="Leeching Swarm", quality="epic", description="While below 50% health, your damaging spells and abilities unleash Leeching Swarm, dealing 6761 Nature damage every 1 sec to all enemies within 10 yds for 6 sec. You are healed for 30% of the damage dealt. If Leeching Swarm hits only 1 target, its damage and healing are increased by 100%. Leeching Swarm cannot occur more than once every 6 sec." },
  ["tome-lightning-charged"] = { name="Lightning Charged", quality="epic", description="While in combat, you gain Lightning Charged every 8 sec, stacking up to 5 times lasting 12 sec. Each stack increases your attack speed by 2% and causes your melee and ranged auto-attacks to deal an additional @flat1+ap0.05@ Nature damage. At 5 stacks, your auto-attacks instead unleash Chain Lightning at the target, dealing @flat5+ap0.25@ Nature damage and chaining up to 5 times. Effect is lost on exiting combat." },
  ["tome-lingering-inspiration"] = { name="Lingering Inspiration", quality="epic", description="Your periodic healing effects have a 5% chance to grant a random ally a 1% bonus to all attributes for 15 sec. Stacks up to a total of 10%." },
  ["tome-machine-slayer"] = { name="Machine Slayer", quality="rare", description="Increases your attack power by @flat180+lvl9@ when fighting Mechanical enemies." },
  ["tome-mana-infusion"] = { name="Mana Infusion", quality="rare", description="While above 80% mana, restoring mana also restores health equal to 50% of the mana restored." },
  ["tome-mechanical-bane"] = { name="Mechanical Bane", quality="rare", description="Increases your spell power by @flat120+lvl6@ when fighting Mechanical enemies." },
  ["tome-mutagenic-fumes"] = { name="Mutagenic Fumes", quality="epic", description="Killing an enemy summons a Poison Cloud for 20, dealing 4512 Nature damage to nearby enemies every 1. This effect cannot occur more than once every 8 sec." },
  ["tome-nature-surge"] = { name="Nature's Surge", quality="rare", description="Casting a spell or ability has a chance to make your next eligible spell instant-cast. Eligible spells: Wrath, Starfire. Healing: Healing Touch, Nourish, Regrowth." },
  ["tome-nether-lord-s-command"] = { name="Nether Lord's Command", quality="epic", description="Your damaging spells and abilities have a chance to open a Nether Portal for 10 sec. While active, the portal hurls Fel Lightning at your target every 2 sec, dealing 28196 Fel damage. Each strike has a 25% chance to summon a Fel Flamestrike under the target, dealing 45113 Fel damage and burning the ground for 4 sec, dealing 9025 Fel damage every 1 sec. You cannot summon a Nether Portal more than once every 6 sec." },
  ["tome-overwhelming-restoration"] = { name="Overwhelming Restoration", quality="epic", description="Your healing done is increased by 30%, but your spells cost 500% more mana." },
  ["tome-pandemic"] = { name="Pandemic", quality="epic", description="When a target dies while affected by one of your damage-over-time effects, that effect spreads to all enemies within 20 yards." },
  ["tome-permafrost-aura"] = { name="Permafrost Aura", quality="rare", description="While in combat, you deal @sp0.16+ap0.08@ Frost damage every 2 sec to enemies within 8 yards. This effect deals at least 5 damage. Enemies hit have their attack speed reduced by 5% for 3 sec." },
  ["tome-polarity-shift"] = { name="Polarity Shift", quality="epic", description="You alternate between Positive Charge and Negative Charge. Taking direct melee damage shifts you to Negative Charge. While under Negative Charge, going 1 to 0 sec without taking direct melee damage shifts you to Positive Charge. You cannot shift more than once every 4 sec. \\|cff1eff00Positive Charge: \\|cffffffffIncreases your critical strike chance by 10% and damage dealt by 5%. \\|cff1eff00Negative Charge: \\|cffffffffReduces damage taken by 10%, increases healing received by 5%, and increases your movement speed by 5%." },
  ["tome-provoking-presence"] = { name="Provoking Presence", quality="rare", description="Increases threat generated by @flat3@%." },
  ["tome-quickened-tempo"] = { name="Quickened Tempo", quality="epic", description="Your global cooldown is now reduced by your Haste." },
  ["tome-rage-of-the-colossus"] = { name="Rage of the Colossus", quality="epic", description="Your critical strikes grant Momentum for 8 sec, stacking up to 10 times. Momentum cannot be gained more than once per second. Each stack increases your movement speed by 2% and damage dealt by 1%. At 10 stacks, you unleash a Massive Crash, dealing 56391 Physical damage to enemies within 10 yards of your target." },
  ["tome-raging-momentum"] = { name="Raging Momentum", quality="rare", description="While below 80% Rage, your Rage generation is increased by 20%. While above 80% Rage, your damage done is increased by 10%." },
  ["tome-ravenous-bellow"] = { name="Ravenous Bellow", quality="epic", description="Delivering a killing blow unleashes Terrifying Roar, dealing 6771 damage to enemies within 10 yds, slowing them by 50% and causing them to take 15% increased damage from you for 5 sec. This effect cannot occur more than once every 2 sec." },
  ["tome-reaper-s-doom"] = { name="Reaper's Doom", quality="epic", description="Dealing damage afflict the target with Reaper’s Doom for 30 sec. When it expires, it detonates for 33855 Shadow damage split between all enemies within 8 yards. If the target dies while afflicted, Reaper’s Doom detonates immediately." },
  ["tome-reaper-s-reprieve"] = { name="Reaper's Reprieve", quality="rare", description="Fatal damage instead reduces you to 1 health, prevents all damage for 3 sec, and heals you for 35% of your maximum health. This effect cannot occur more than once every 60 min and can trigger without consuming Cheat Death charges." },
  ["tome-reaper-s-verdict"] = { name="Reaper's Verdict", quality="epic", description="Your damage against enemies below 35% health is increased by 20%. When you damage an enemy below 15% health, you deal an additional 16952 Shadow damage. This effect cannot occur more than once every 2 sec per target." },
  ["tome-relentless-energy"] = { name="Relentless Energy", quality="rare", description="While below 80% Energy, your Energy regeneration is increased by 10%. While above 80% Energy, your damage done is increased by 10%." },
  ["tome-resonant-build"] = { name="Resonant Build", quality="epic", description="While you have at least 3 different Base Stat Echo types active (Strength, Agility, Intellect, Spirit, or Stamina), your damage is increased by 15%." },
  ["tome-rocket-strike"] = { name="Rocket Strike", quality="epic", description="Your melee and ranged attacks have a 5% chance to launch a Rocket at your target, dealing @flat15+sp0.75+ap0.375@ Fire damage. You fire 1 additional Rocket on random nearby enemies for each of your active pets or guardians. Subsequent Rockets hitting the same target deal reduced damage." },
  ["tome-rootbreaker"] = { name="Rootbreaker", quality="rare", description="Reduces the duration of root effects on you by @flat30@%." },
  ["tome-runic-momentum"] = { name="Runic Momentum", quality="rare", description="While below 80% Runic Power, your Runic Power generation is increased by 20%. While above 80% Runic Power, your damage done is increased by 10%." },
  ["tome-sanctified-hazard"] = { name="Sanctified Hazard", quality="rare", description="While 4 or more enemies are within range, the damage of your Consecration, Divine Storm, and Hammer of the Righteous is increased by 20%." },
  ["tome-sanctum-sentries"] = { name="Sanctum Sentries", quality="epic", description="While in combat you are accompanied by two Sanctum Sentries. Enemies struck by either guardian take 10% increased damage from you for 4 sec." },
  ["tome-sanguine-bulwark"] = { name="Sanguine Bulwark", quality="epic", description="Reduces your healing done by 25%. Absorbs up to 50% of damage taken, to a maximum of 5644 per hit." },
  ["tome-shadow-crash"] = { name="Shadow Crash", quality="epic", description="Your Shadow damage-over-time damage have a 3% chance to hurl a Shadow Crash at the target. On impact, it deals @flat20+sp1+ap0.5@ Shadow damage to enemies within 10 yards" },
  ["tome-shadow-hazard"] = { name="Shadow Hazard", quality="rare", description="While 4 or more enemies are within range, the damage of your Fan of Knives is increased by 20%." },
  ["tome-shadow-ward"] = { name="Shadow Ward", quality="rare", description="Increases Shadow Resistance by @flat10+lvl0.5@." },
  ["tome-shielded-steps"] = { name="Shielded Steps", quality="rare", description="Reduces damage taken from area-of-effect attacks by @flat1@%." },
  ["tome-slimebound-husk"] = { name="Slimebound Husk", quality="epic", description="Taking direct damage grants a stack of Molten Blood, up to 8. At 8 stacks, you shed your skin, leaving behind a Poisonous Slime for 10 sec that deals 11278 Nature damage every 1 sec to nearby enemies, while you gain 15% increased movement speed and 10% reduced damage taken for 6 sec." },
  ["tome-static-overflow"] = { name="Static Overflow", quality="rare", description="Every 3 sec while in combat, your next spell or ability also hurls lightning at up to 3 random nearby enemies, dealing @sp0.4+ap0.2@ Nature damage. This effect deals at least 15 damage." },
  ["tome-steady-casting"] = { name="Steady Casting", quality="rare", description="Reduces pushback suffered from damaging attacks while casting by @flat20@%." },
  ["tome-steady-grip"] = { name="Steady Grip", quality="rare", description="Reduces the duration of disarm effects on you by @flat30@%." },
  ["tome-stitched-fury"] = { name="Stitched Fury", quality="epic", description="While below 15% health, you go into a Frenzy, increasing Attack Speed by 30% and Physical damage dealt by 25%." },
  ["tome-stone-shatter"] = { name="Stone Shatter", quality="epic", description="The first time you damage an enemy, you mark it with Fracture for 10 sec. If it dies while fractured, it shatters, dealing @flat10+sp0.5+ap0.25@ Physical damage to enemies within 8 yards." },
  ["tome-stoneskin-threads"] = { name="Stoneskin Threads", quality="rare", description="Reduces the duration of movement slowing effects on you by @flat15@%." },
  ["tome-stored-momentum"] = { name="Stored Momentum", quality="rare", description="The resources you spend are stored. Every 5 sec, your next ability deals additional damage based on the amount stored." },
  ["tome-storm-hazard"] = { name="Storm Hazard", quality="rare", description="While 4 or more enemies are within range, the damage of your Chain Lightning and Thunderstorm is increased by 20%." },
  ["tome-storm-of-the-spellweaver"] = { name="Storm of the Spellweaver", quality="epic", description="Dealing Arcane damage grants a stack of Overcharge. At 10 stacks, you fire a salvo of Magic Missiles into the air, striking up to 3 nearby enemies for 33825 Arcane damage each. After triggering, you cannot gain Overcharge stacks for 2 sec." },
  ["tome-storm-surge"] = { name="Storm Surge", quality="rare", description="Casting a spell or ability has a chance to make your next eligible spell instant-cast. Eligible spells: Lightning Bolt, Chain Lightning, Lava Burst, Healing Wave, Chain Heal." },
  ["tome-subtle-presence"] = { name="Subtle Presence", quality="rare", description="Reduces threat generated by @flat2@%." },
  ["tome-sundered-will"] = { name="Sundered Will", quality="rare", description="Reduces the duration of fear effects on you by @flat30@%." },
  ["tome-temporal-pressure"] = { name="Temporal Pressure", quality="epic", description="Your cooldowns are now reduced by your Haste. Affected spells : Shield Slam, Revenge, Thunder Clap, Mortal Strike, Bloodthirst, Whirlwind, Shockwave, Concussion Blow." },
  ["tome-the-harvester-s-tithe"] = { name="The Harvester's Tithe", quality="epic", description="You constantly harvest the souls of nearby enemies, gaining a stack of Harvested Soul. Each stack increases your damage done by 1%. Up to 10% increase. When an enemy with its soul harvested dies, you regain 11273 health." },
  ["tome-the-last-wall"] = { name="The Last Wall", quality="rare", description="Increases your maximum health by 50%, but reduces healing received by 60%." },
  ["tome-the-sporelord-s-gift"] = { name="The Sporelord's Gift", quality="epic", description="While in combat, you periodically summon Spores for 20 sec, increasing the critical strike damage of nearby allies by 10%." },
  ["tome-the-unclean-s-fever"] = { name="The Unclean's Fever", quality="epic", description="Enemies that strike you are afflicted with Decrepit Fever, dealing 3381 Shadow damage each second for 3 sec and reduces the damage they deal to you by 10% for the duration." },
  ["tome-titan-s-grip"] = { name="Titan's Grip", quality="epic", description="Allows you to wield two-handed weapons in one hand. Your damage is reduced by 20%." },
  ["tome-twilight-equilibrium"] = { name="Twilight Equilibrium", quality="epic", description="You begin combat in Light Essence. Light Essence: Dealing Holy, Fire, or Nature damage applies Light Charge for 8 sec, stacking up to 20 times. Dealing Shadow, Frost, or Arcane damage consumes Light Charge to unleash Darkburst, dealing 3380 Shadow damage per stack to the target and all enemies within 8 yards and shifts you into Dark Essence. Dark Essence: Dealing Shadow, Frost, or Arcane damage applies Dark Charge for 8 sec, stacking up to 20 times. Dealing Holy, Fire, or Nature damage consumes Dark Charge to unleash Lightburst, dealing 3380 Holy damage per stack to the target and all enemies within 8 yards and shifts you into Light Essence." },
  ["tome-undead-bane"] = { name="Undead Bane", quality="rare", description="Increases your spell power by @flat120+lvl6@ when fighting Undead." },
  ["tome-undead-slayer"] = { name="Undead Slayer", quality="rare", description="Increases your attack power by @flat180+lvl9@ when fighting Undead." },
  ["tome-unstable-missiles"] = { name="Unstable Missiles", quality="rare", description="Your direct spells have a chance to launch an Unstable Missile at the target, dealing @sp0.3+ap0.15@ Arcane damage. This effect deals at least 10 damage." },
  ["tome-verdant-ward"] = { name="Verdant Ward", quality="rare", description="Increases Nature Resistance by @flat10+lvl0.5@." },
  ["tome-weapon-mastery"] = { name="Weapon Mastery", quality="epic", description="You can equip all weapon types." },
  ["tome-widow-s-venom"] = { name="Widow's Venom", quality="epic", description="Dealing Nature damage grants a stack of Venomous. At 12 stacks, you unleash Poison Bolt Volley, spraying poison at all enemies within 10 yds, dealing 22557 Nature damage and an additional 5644 Nature damage every second for 4 sec. After triggering, you cannot gain Venomous stacks for 4 sec." },
  ["tome-wild-hazard"] = { name="Wild Hazard", quality="rare", description="While 4 or more enemies are within range, the damage of your Hurricane, Starfall, and Swipe is increased by 20%." },
}

-- tomeId -> list of drop locations
EchoCodexLocations = {
  ["tome-arcane-density"] = {
    { zone="eastern-kingdoms", placeName="Hearthglen", x=46.5, y=9.3, mobs={"Scarlet Paladins"}, notes="Source: Open World" },
  },
  ["tome-arcane-surge"] = {
    { zone="eastern-kingdoms", placeName="just outside booty bay", x=29, y=95.4, mobs={"Bloodsail Mage/Raider"}, notes="Source: Open World" },
    { zone="northrend", placeName="Crystalsong Forest", x=48.3, y=45, mobs={"Azure Manashaper"}, notes="" },
  },
  ["tome-battle-rhythm"] = {
    { zone="eastern-kingdoms", placeName="Blackrock Stronghold", x=47.9, y=61.6, mobs={"Blackrock Stronghold mobs"}, notes="Source: Open World" },
    { zone="eastern-kingdoms", placeName="Redrige Mountain - Render's Rock", x=54.5, y=67.1, mobs={"Blackrock Champion"}, notes="" },
    { zone="outland", placeName="Outland - Shattered Halls", x=57.5, y=53.5, mobs={}, notes="" },
  },
  ["tome-crusader-s-surge"] = {
    { zone="eastern-kingdoms", placeName="Hearthglen", x=46.9, y=9.5, mobs={"Scarlet Paladins"}, notes="Source: Open World" },
  },
  ["tome-crushing-finish"] = {
    { zone="eastern-kingdoms", placeName="Blackrock Stronghold", x=47.3, y=61.5, mobs={"Blackrock Slayer"}, notes="Source: Open World" },
  },
  ["tome-fortress-soul"] = {
    { zone="eastern-kingdoms", placeName="Scarlet Encampments", x=48.9, y=13.4, mobs={"Scarlet Knights"}, notes="Source: Open World" },
    { zone="outland", placeName="Outland - Shattered Halls", x=57.5, y=53.4, mobs={}, notes="" },
  },
  ["tome-the-last-wall"] = {
    { zone="eastern-kingdoms", placeName="Alterac Mountains", x=35.2, y=22.6, mobs={"Giant Yetis"}, notes="Source: Open World" },
  },
  ["tome-reaper-s-doom"] = {
    { zone="kalimdor", placeName="Unknown — to be placed", x=91.2, y=3.6, mobs={"Reaper"}, notes="Spawn and defeat the Reaper after fighting for 10 minutes straight at Intensity 5. Hard fight." },
  },
  ["tome-reaper-s-verdict"] = {
    { zone="kalimdor", placeName="Anywhere", x=91.3, y=4.4, mobs={"Reaper"}, notes="Spawn and defeat the Reaper after fighting for 10 minutes straight at Intensity 5. Hard fight." },
  },
  ["tome-relentless-energy"] = {
    { zone="kalimdor", placeName="Unknown — to be placed", x=85.7, y=3.6, mobs={}, notes="Same as Subtle Presence\nFor energy-based classes (rogues, cat druids)" },
    { zone="outland", placeName="Outland - Shattered Halls", x=57.6, y=53.4, mobs={}, notes="rogues/cat druids" },
    { zone="eastern-kingdoms", placeName="(see Subtle Presence) - Stranglethorn Vale", x=26.3, y=94, mobs={"Same mobs as Subtle Presence"}, notes="Open World" },
  },
  ["tome-resonant-build"] = {
    { zone="kalimdor", placeName="Southwind Village", x=31.6, y=82.1, mobs={"Tortured Druids"}, notes="Source: Open World" },
  },
  ["tome-storm-surge"] = {
    { zone="kalimdor", placeName="Feralas", x=32.3, y=72, mobs={"Grimtotem mobs"}, notes="Source: Open World" },
    { zone="eastern-kingdoms", placeName="Stranglethorn Vale - Mosh'ogg ogred mound", x=41.3, y=85.9, mobs={"Mosh'Ogg Shaman"}, notes="" },
  },
  ["tome-subtle-presence"] = {
    { zone="kalimdor", placeName="Unknown — to be placed", x=85.6, y=4.4, mobs={}, notes="Same mobs that drop Relentless Energy" },
    { zone="eastern-kingdoms", placeName="Stranglethorn Vale - Booty Bay (north bandit camp); also see Relentless Energy - Stranglethorn Vale", x=26.4, y=94, mobs={"Bloodsail Raider", "Same mobs as Relentless Energy"}, notes="Open World" },
  },
  ["tome-brittle-forging"] = {
    { zone="northrend", placeName="Ulduar", x=58.1, y=11.8, mobs={"Ignis the Furnace Master"}, notes="Source: Raid" },
  },
  ["tome-broodmother-s-webbing"] = {
    { zone="northrend", placeName="Naxxramas", x=58.3, y=58.6, mobs={"Maexxna"}, notes="Source: Raid" },
  },
  ["tome-call-of-the-lich-king"] = {
    { zone="northrend", placeName="Naxxramas", x=58.3, y=58.3, mobs={"Kel'Thuzad"}, notes="Source: Raid" },
  },
  ["tome-chill-of-the-bone-wyrm"] = {
    { zone="northrend", placeName="Naxxramas", x=58.2, y=58.7, mobs={"Sapphiron"}, notes="Source: Raid\n\nhttps://www.wowhead.com/wotlk/npc=15989/sapphiron" },
  },
  ["tome-constellations"] = {
    { zone="northrend", placeName="Ulduar", x=57.7, y=11.8, mobs={"Algalon the Observer"}, notes="Source: Raid\n\nIn order to access the boss you need a [Celestial Planetarium Key] of correct type 10/25 man    https://www.wowhead.com/wotlk/item=45796/celestial-planetarium-key" },
  },
  ["tome-crypt-lord-s-swarm"] = {
    { zone="northrend", placeName="Naxxramas", x=58.2, y=58.6, mobs={"Anub'Rekhan"}, notes="Source: Raid" },
  },
  ["tome-drillmaster-s-rebuke"] = {
    { zone="northrend", placeName="Ulduar", x=58.1, y=11.5, mobs={"Instructor Razuvious"}, notes="Source: Raid" },
  },
  ["tome-edict-of-the-four"] = {
    { zone="northrend", placeName="Naxxramas", x=58.2, y=58.2, mobs={"The Four Horsemen"}, notes="Source: Raid" },
  },
  ["tome-edict-of-the-iron-council"] = {
    { zone="northrend", placeName="Ulduar", x=58.1, y=11.2, mobs={"Assembly of Iron"}, notes="Source: Raid" },
  },
  ["tome-emberlord-s-gift"] = {
    { zone="northrend", placeName="Bottom right corner", x=40.7, y=52.1, mobs={"Fire elementals"}, notes="Source: Open World" },
  },
  ["tome-eonar-s-seed"] = {
    { zone="northrend", placeName="Ulduar", x=57.9, y=10.6, mobs={"Freya"}, notes="Source: Raid" },
  },
  ["tome-exposed-heart"] = {
    { zone="northrend", placeName="Ulduar", x=58.1, y=10.9, mobs={"XT-002 Deconstructor"}, notes="Source: Raid" },
  },
  ["tome-flame-vents"] = {
    { zone="northrend", placeName="Ulduar", x=57.9, y=11.2, mobs={"Flame Leviathan"}, notes="Source: Raid" },
  },
  ["tome-frostfire-paradox"] = {
    { zone="northrend", placeName="Ulduar", x=57.7, y=11.5, mobs={"Hodir"}, notes="Source: Raid" },
  },
  ["tome-hungering-curse"] = {
    { zone="northrend", placeName="Wintergrasp west side, near blackened area", x=34.1, y=48, mobs={"Wandering Shadow"}, notes="Source: Open World\n\nhttps://www.wowhead.com/wotlk/npc=30842/wandering-shadow" },
  },
  ["tome-idol-of-yogg-saron"] = {
    { zone="northrend", placeName="Ulduar", x=57.9, y=10.9, mobs={"Yogg-Saron"}, notes="Source: Raid" },
  },
  ["tome-lightning-charged"] = {
    { zone="northrend", placeName="Ulduar", x=58.1, y=10.6, mobs={"Thorim"}, notes="Source: Raid" },
  },
  ["tome-mutagenic-fumes"] = {
    { zone="northrend", placeName="Naxxramas", x=58.3, y=58.5, mobs={"Grobbulus"}, notes="Source: Raid" },
  },
  ["tome-polarity-shift"] = {
    { zone="northrend", placeName="Naxxramas", x=58.2, y=58.4, mobs={"Thaddius"}, notes="Source: Raid" },
  },
  ["tome-ravenous-bellow"] = {
    { zone="northrend", placeName="Naxxramas", x=58.2, y=58.3, mobs={"Gluth"}, notes="Source: Raid" },
  },
  ["tome-rocket-strike"] = {
    { zone="northrend", placeName="Ulduar", x=57.7, y=10.9, mobs={"Mimiron"}, notes="Source: Raid" },
  },
  ["tome-sanctum-sentries"] = {
    { zone="northrend", placeName="Ulduar", x=57.7, y=10.6, mobs={"Auriaya"}, notes="Source: Raid" },
  },
  ["tome-shadow-crash"] = {
    { zone="northrend", placeName="Ulduar", x=57.7, y=11.2, mobs={"General Vezax"}, notes="Source: Raid" },
  },
  ["tome-static-overflow"] = {
    { zone="northrend", placeName="Bottom right corner next to fire place", x=38.3, y=53.1, mobs={"Whispering Wind"}, notes="Source: Open World" },
  },
  ["tome-the-harvester-s-tithe"] = {
    { zone="northrend", placeName="Naxxramas", x=58.3, y=58.4, mobs={"Gothik the Harvester"}, notes="Source: Raid" },
  },
  ["tome-the-sporelord-s-gift"] = {
    { zone="northrend", placeName="Naxxramas", x=58.2, y=58.5, mobs={"Loatheb"}, notes="Source: Raid" },
  },
  ["tome-the-unclean-s-fever"] = {
    { zone="northrend", placeName="Naxxramas", x=58.2, y=58.2, mobs={"Heigan the Unclean"}, notes="Source: Raid" },
  },
  ["tome-widow-s-venom"] = {
    { zone="northrend", placeName="Naxxramas", x=58.1, y=58.4, mobs={"Grand Widow Faerlina"}, notes="Source: Raid" },
  },
  ["tome-adaptive-power"] = {
    { zone="outland", placeName="Tomb of Lights", x=48.7, y=76.8, mobs={"Ethereal Arcanist", "Plunderer", "Nethermancer"}, notes="Source: Open World\n\nhttps://www.wowhead.com/wotlk/npc=21405/ethereal-arcanist" },
  },
  ["tome-arcane-burn"] = {
    { zone="outland", placeName="Bash'ir Landing", x=40.3, y=18.3, mobs={"Ethereal mobs"}, notes="Source: Open World" },
  },
  ["tome-arcane-cadence"] = {
    { zone="outland", placeName="Tomb of Lights", x=48.7, y=76.5, mobs={"Ethereal Plunderers/Arcanists"}, notes="Source: Open World" },
  },
  ["tome-divine-surge"] = {
    { zone="outland", placeName="The Shattered Halls", x=57.4, y=53.5, mobs={"Shattered Hand Zealot"}, notes="Source: Dungeon\n\nhttps://www.wowhead.com/wotlk/npc=17462/shattered-hand-zealot" },
    { zone="eastern-kingdoms", placeName="Eastern Plaguelands - Tyr's Hand; also Shattered Halls - Eastern Plaguelands", x=85.5, y=16.1, mobs={"Clerics", "Shattered Hand Zealot"}, notes="Open World / Dungeon" },
  },
  ["tome-entropic-fusion"] = {
    { zone="outland", placeName="Forge Camp: Wrath", x=35.1, y=24.6, mobs={"Demons"}, notes="Source: Open World" },
    { zone="eastern-kingdoms", placeName="Burning Steppes - Dreadmaul Rock", x=64.9, y=63.8, mobs={"Flamekin Spitter"}, notes="" },
  },
  ["tome-fel-surge"] = {
    { zone="outland", placeName="Tomb of Lights", x=48.8, y=76.7, mobs={"Ethereal Necromancer"}, notes="Source: Open World" },
    { zone="kalimdor", placeName="Everywhere", x=85.6, y=6.1, mobs={}, notes="This tomes is extremely common. Usually very cheap on the AH" },
  },
  ["tome-healing-cadence"] = {
    { zone="outland", placeName="southern path toward Nagrand/Shattrath (packs of 3 Seers)", x=48.2, y=66, mobs={"Seers"}, notes="Source: Open World" },
    { zone="outland", placeName="Zangarmarsh - southern path toward Nagrand/Shattrath - Zangarmarsh", x=41.6, y=57.3, mobs={"Seers (packs of 3)"}, notes="Open World" },
  },
  ["tome-nature-surge"] = {
    { zone="outland", placeName="Zangarmarsh", x=41.8, y=57.3, mobs={"Seers"}, notes="Source: Open World" },
    { zone="kalimdor", placeName="Unknown location", x=72.8, y=4.1, mobs={}, notes="Found on druid type enemies" },
  },
  ["tome-raging-momentum"] = {
    { zone="outland", placeName="Shattered Halls", x=57.4, y=53.4, mobs={"Warrior‑type mobs without shields or Execute"}, notes="Source: Dungeon" },
  },
  ["tome-unstable-missiles"] = {
    { zone="outland", placeName="Bash'ir Landing", x=40, y=18.4, mobs={"Bash’ir Ethereals"}, notes="Source: Open World" },
  },
  ["tome-weapon-mastery"] = {
    { zone="outland", placeName="Shattered Halls", x=57.6, y=53.5, mobs={"Warrior mobs"}, notes="Source: Dungeon" },
    { zone="eastern-kingdoms", placeName="Redridge Mountain - Render's Rock", x=54.6, y=67.1, mobs={"Blackrock Champion"}, notes="Easier farm than shattered halls and if you have echoes that attract mobs to you, you can find a few spots to make your farming really efficient and get more and get better droprate/h." },
  },
  ["tome-reaper-s-reprieve"] = {
    { zone="kalimdor", placeName="Anywhere", x=91.4, y=5.3, mobs={"Reaper"}, notes="Spawn and defeat the Reaper after fighting for 10 minutes straight at Intensity 5. Hard fight." },
  },
  ["tome-storm-of-the-spellweaver"] = {
    { zone="northrend", placeName="Coldarra - Eye of Eternity", x=15, y=57.3, mobs={"Malygos"}, notes="" },
  },
  ["tome-cinders-of-the-sanctum"] = {
    { zone="northrend", placeName="Dragonblight - Obsidian Sanctum", x=50.4, y=60.4, mobs={"Sartharion"}, notes="You need to deal fire damage" },
  },
  ["tome-permafrost-aura"] = {
    { zone="northrend", placeName="Dragonblight - Coldwind Pass", x=35.9, y=58.6, mobs={"Frozen Elemental"}, notes="Be careful, they can stunlock-bump you if you can't kill them fast enough" },
  },
  ["tome-heavy-incantations"] = {
    { zone="kalimdor", placeName="Pretty much everywhere", x=85.5, y=5.4, mobs={}, notes="This tomes is extremely common. Usually very cheap on the AH" },
  },
  ["tome-hunting-hazard"] = {
    { zone="kalimdor", placeName="Pretty much Everywhere", x=83.1, y=3.5, mobs={}, notes="This tomes is extremely common. Usually very cheap on the AH" },
    { zone="kalimdor", placeName="Unknown location", x=69.5, y=5, mobs={}, notes="Found on enemies that use volley / multishot" },
  },
  ["tome-fel-hazard"] = {
    { zone="kalimdor", placeName="Pretty much everywhere", x=83.1, y=4.4, mobs={}, notes="This tomes is extremely common. Usually very cheap on the AH" },
    { zone="kalimdor", placeName="Unknown location", x=64.1, y=4.4, mobs={}, notes="Found on warlock type enemies" },
  },
  ["tome-shadow-hazard"] = {
    { zone="kalimdor", placeName="Pretty much everywhere", x=83.3, y=5.1, mobs={}, notes="This tomes is extremely common. Usually very cheap on the AH\nWarlock" },
    { zone="eastern-kingdoms", placeName="Elwynn Forest - north of Goldshire; also Stranglethorn Vale - Booty Bay (north bandit camp) - Elwynn Forest", x=30.9, y=69.5, mobs={"Defias Cutpurse", "Bloodsail Raider"}, notes="Open World" },
  },
  ["tome-mana-infusion"] = {
    { zone="northrend", placeName="Zul'Drak - Drak Sotra Fields", x=68, y=48.7, mobs={"Crazed Water Spirit"}, notes="" },
    { zone="kalimdor", placeName="Unknown location", x=72.3, y=7.9, mobs={}, notes="Found on water elemental type enemies" },
  },
  ["tome-storm-hazard"] = {
    { zone="eastern-kingdoms", placeName="Stranglethorn Vale - Mosh'ogg ogred mound", x=41.3, y=85.8, mobs={"Mosh'Ogg Shaman"}, notes="" },
    { zone="kalimdor", placeName="Unknown location", x=80.5, y=4.9, mobs={}, notes="Drop on shaman type mobs" },
  },
  ["tome-archmage-mark"] = {
    { zone="eastern-kingdoms", placeName="Tyr''s Hand - Eastern Plaguelands", x=86.4, y=16.1, mobs={"Scarlet Archmage"}, notes="" },
  },
  ["tome-contagion"] = {
    { zone="northrend", placeName="Malykriss - Icecrown", x=44.9, y=37.6, mobs={"Undead mobs on boost spots, idk which ones for now"}, notes="" },
    { zone="eastern-kingdoms", placeName="Pestilent Scar - Eastern Plaguelands", x=82.1, y=13.4, mobs={"Living Decay", "Rotting Sludge"}, notes="" },
    { zone="eastern-kingdoms", placeName="The Hinterlands - Skulk Rock - The Hinterlands", x=70, y=22, mobs={"Jade Ooze"}, notes="Open World" },
  },
  ["tome-pandemic"] = {
    { zone="northrend", placeName="Malykriss - Icecrown", x=45.2, y=37.1, mobs={"Undead mobs on boost spots, idk which ones for now"}, notes="" },
    { zone="eastern-kingdoms", placeName="Western Plaguelands", x=50, y=16.8, mobs={"Skeletons"}, notes="Near cauldrons" },
    { zone="eastern-kingdoms", placeName="Pestilent Scar - Eastern Plaguelands", x=82.4, y=13.4, mobs={"Living Decay", "Rotting Sludge"}, notes="" },
    { zone="eastern-kingdoms", placeName="Western Plaguelands - Dalson's Tears - Western Plaguelands", x=47.1, y=15, mobs={"Rotting Cadaver", "Blighted Zombie"}, notes="Open World" },
  },
  ["tome-undead-slayer"] = {
    { zone="northrend", placeName="Malykriss - Icecrown", x=45.3, y=37.7, mobs={"Undead mobs on boost spots, idk which ones for now"}, notes="" },
    { zone="eastern-kingdoms", placeName="Western Plaguelands - Sorrow Hill - Western Plaguelands", x=49.1, y=18.5, mobs={"Slavering Ghoul"}, notes="Open World" },
  },
  ["tome-undead-bane"] = {
    { zone="northrend", placeName="Malykriss - Icecrown", x=45.6, y=37.3, mobs={"Undead mobs on boost spots, idk which ones for now"}, notes="" },
    { zone="eastern-kingdoms", placeName="Western Plaguelands - Sorrow Hill - Western Plaguelands", x=49.1, y=18.5, mobs={"Slavering Ghoul"}, notes="Open World" },
  },
  ["tome-elemental-bane"] = {
    { zone="northrend", placeName="Wintergrasp", x=39.7, y=51.6, mobs={"Wind Elementals (confirmed)"}, notes="Poentitally on other elementals as well" },
    { zone="northrend", placeName="Crystalsong Forest - Forlorn Woods", x=51.3, y=42.5, mobs={"Grove Walker"}, notes="" },
  },
  ["tome-elemental-slayer"] = {
    { zone="northrend", placeName="Wintergrasp", x=39.3, y=51.6, mobs={"Elementals, To be tested for which ones specifically"}, notes="" },
    { zone="northrend", placeName="Crystalsong Forest - Forlorn Woods", x=51, y=42.3, mobs={"Grove Walker"}, notes="" },
    { zone="kalimdor", placeName="Unknown location", x=59.1, y=6.6, mobs={}, notes="Found on elemental type enemies" },
  },
  ["tome-insulated-soul"] = {
    { zone="kalimdor", placeName="Dustwallow Marsh - Outside Ony raid", x=62.5, y=70.9, mobs={"Dragonkins"}, notes="to be confirmed" },
    { zone="eastern-kingdoms", placeName="Eastern Plaguelands - Stratholme - The Hoard", x=65.4, y=6.6, mobs={"Crimson Defender"}, notes="Dungeon" },
  },
  ["tome-dragon-slayer"] = {
    { zone="kalimdor", placeName="Dustwallow Marsh - Outside Ony raid", x=62.7, y=70.9, mobs={"Dragonkins"}, notes="to be confirmed" },
    { zone="northrend", placeName="Crystalsong Forest", x=47.9, y=46.1, mobs={"Azure Spellweaver"}, notes="" },
    { zone="kalimdor", placeName="Unknown location", x=63.9, y=2.6, mobs={}, notes="Found on dragon type enemies" },
  },
  ["tome-dragonkin-bane"] = {
    { zone="kalimdor", placeName="Dustwallow Marsh - Outside Ony raid", x=62.3, y=70.9, mobs={"Dragonkins"}, notes="to be confirmed" },
    { zone="northrend", placeName="Crystalsong Forest", x=48.2, y=45.9, mobs={"Azure Spellweaver"}, notes="" },
    { zone="kalimdor", placeName="Unknown location", x=62, y=7, mobs={}, notes="Found on dragon type enemies" },
  },
  ["tome-ambidexterity"] = {
    { zone="eastern-kingdoms", placeName="outside BB", x=26.2, y=94.1, mobs={"Bloodsail Raiders"}, notes="to be confirmed" },
  },
  ["tome-quickened-tempo"] = {
    { zone="eastern-kingdoms", placeName="Westfall", x=22.6, y=78.7, mobs={"Riverpaw Taskmaster"}, notes="" },
    { zone="outland", placeName="Hellfire Citadel", x=57.8, y=52.8, mobs={"Orcs outside the citadel, probably casters/warlock"}, notes="" },
    { zone="outland", placeName="Terokkar Forest - Bonechewer Ruins - Terokkar Forest", x=52.7, y=79, mobs={"Bonechewer Backbreaker"}, notes="Open World" },
  },
  ["tome-accelerated-decay"] = {
    { zone="northrend", placeName="Crystalsong Forest - Forlorn Woods", x=50.9, y=42.7, mobs={"Either Stags, Wolves or Grove Walkers"}, notes="" },
  },
  ["tome-beast-bane"] = {
    { zone="northrend", placeName="Crystalsong Forest - Forlorn Woods", x=51.3, y=42.9, mobs={"Sinewy Wolf"}, notes="" },
  },
  ["tome-beast-slayer"] = {
    { zone="northrend", placeName="Crystalsong Forest - Forlorn Woods", x=51.5, y=42.7, mobs={"Sinewy Wolf"}, notes="" },
    { zone="kalimdor", placeName="Unknown location", x=59.3, y=5.5, mobs={}, notes="Found on beast type enemies" },
  },
  ["tome-armor-mastery"] = {
    { zone="eastern-kingdoms", placeName="Pyrewood Village - Silverpine Forest", x=16.2, y=25.7, mobs={"Moonrage Armorer"}, notes="" },
    { zone="eastern-kingdoms", placeName="The Grinding Quarry - Blackrock Mountain", x=42.6, y=61.8, mobs={"Anvilrage Enforcer"}, notes="" },
  },
  ["tome-titan-s-grip"] = {
    { zone="eastern-kingdoms", placeName="Scarlet Monastery - Scarlet Armory", x=39.8, y=10, mobs={"Herod"}, notes="" },
  },
  ["tome-essence-tap"] = {
    { zone="outland", placeName="Hellfire Citadel", x=57.7, y=52.8, mobs={"Orcs outside the citadel, probably casters/warlock"}, notes="" },
    { zone="kalimdor", placeName="Unknown location", x=64.3, y=6.4, mobs={}, notes="" },
  },
  ["tome-echoing-tides"] = {
    { zone="outland", placeName="Hellfire Citadel", x=57.6, y=52.8, mobs={"Orcs outside the citadel, probably casters/warlock"}, notes="" },
    { zone="northrend", placeName="Crystalsong Forest - Forlorn Woods - Crystalsong Forest", x=51.1, y=42.7, mobs={"Grove Walker"}, notes="Open World" },
  },
  ["tome-ember-ward"] = {
    { zone="northrend", placeName="Wintergrasp - Fire zone", x=40.6, y=52.4, mobs={"Flame Revenant"}, notes="" },
  },
  ["tome-sanguine-bulwark"] = {
    { zone="outland", placeName="Black Temple", x=74.3, y=81, mobs={"Gurtogg Bloodboil"}, notes="" },
  },
  ["tome-frost-bite"] = {
    { zone="northrend", placeName="Icecrown", x=45.6, y=34.9, mobs={"Skeletal Archmage"}, notes="" },
    { zone="eastern-kingdoms", placeName="Western Plaguelands - The Writhing Haunt - Western Plaguelands", x=50, y=16.9, mobs={"Freezing Ghoul"}, notes="Open World" },
  },
  ["tome-stoneskin-threads"] = {
    { zone="northrend", placeName="Crystalsong Forest", x=48.6, y=45.2, mobs={"Azure Manashaper"}, notes="" },
    { zone="kalimdor", placeName="Unknown location", x=80.1, y=2.7, mobs={}, notes="Drops on mobs that cast Frostbolt / Slow" },
  },
  ["tome-steady-casting"] = {
    { zone="northrend", placeName="Crystalsong Forest", x=48.5, y=44.8, mobs={"Azure Manashaper"}, notes="" },
    { zone="eastern-kingdoms", placeName="Stranglethorn Vale - Booty Bay (north bandit camp) - Stranglethorn Vale", x=26.5, y=94.1, mobs={"Bloodsail Raider"}, notes="Open World" },
  },
  ["tome-verdant-ward"] = {
    { zone="northrend", placeName="Wintergrasp", x=38, y=52.9, mobs={"Whispering Wind"}, notes="" },
  },
  ["tome-shielded-steps"] = {
    { zone="eastern-kingdoms", placeName="Scarlet Monastery - Armory", x=39.7, y=10, mobs={"Scarlet Protector", "Scarlet Defender"}, notes="" },
    { zone="kalimdor", placeName="Unknown location", x=79.7, y=7.5, mobs={}, notes="" },
  },
  ["tome-stored-momentum"] = {
    { zone="northrend", placeName="Crystalsong Forest", x=47.3, y=45.6, mobs={"Azure Spellweaver"}, notes="" },
    { zone="kalimdor", placeName="Unknown location", x=80, y=3.8, mobs={}, notes="" },
  },
  ["tome-broodmother-s-fury"] = {
    { zone="kalimdor", placeName="Onyxia's Lair", x=64.8, y=71.5, mobs={"Onyxia"}, notes="Raid" },
  },
  ["tome-champion-s-rally"] = {
    { zone="northrend", placeName="Trial of the Crusader", x=45.3, y=19.7, mobs={"Champions"}, notes="Raid" },
  },
  ["tome-curse-of-the-plaguebringer"] = {
    { zone="northrend", placeName="Naxxramas", x=58.1, y=58.3, mobs={"Noth The Plaguebringer"}, notes="Raid" },
  },
  ["tome-demonic-awakening"] = {
    { zone="outland", placeName="Throne of Kil'Jaeden - Hellfire Peninsula", x=61.7, y=42, mobs={"Doom Lord Kazzak"}, notes="" },
  },
  ["tome-harpoon-barrage"] = {
    { zone="northrend", placeName="Ulduar", x=57.9, y=11.8, mobs={"Razorscale"}, notes="Raid" },
  },
  ["tome-impaler-s-tribute"] = {
    { zone="kalimdor", placeName="Unknown location", x=53.5, y=7, mobs={}, notes="" },
  },
  ["tome-inspiring-mending"] = {
    { zone="kalimdor", placeName="Unknown location", x=53.4, y=6, mobs={}, notes="" },
  },
  ["tome-leeching-swarm"] = {
    { zone="northrend", placeName="Icecrown - Trial of the Crusader", x=45.2, y=19.7, mobs={"Anub'arak"}, notes="Raid" },
  },
  ["tome-lingering-inspiration"] = {
    { zone="kalimdor", placeName="Unknown location", x=54, y=5.1, mobs={}, notes="" },
  },
  ["tome-nether-lord-s-command"] = {
    { zone="northrend", placeName="Trial of the Crusader", x=45.3, y=19.6, mobs={"Lord Jaraxxus"}, notes="Raid" },
  },
  ["tome-overwhelming-restoration"] = {
    { zone="kalimdor", placeName="Unknown location", x=55.2, y=6.5, mobs={}, notes="" },
  },
  ["tome-rage-of-the-colossus"] = {
    { zone="northrend", placeName="Icecrown - Trial of the Crusader", x=45.2, y=19.6, mobs={"Icehowl"}, notes="Raid" },
  },
  ["tome-slimebound-husk"] = {
    { zone="northrend", placeName="Icecrown - Trial of the Crusader", x=45.2, y=19.5, mobs={"Icehowl"}, notes="Raid" },
  },
  ["tome-stitched-fury"] = {
    { zone="northrend", placeName="Ulduar", x=58.1, y=58.5, mobs={"Patchwerk"}, notes="Raid" },
  },
  ["tome-stone-shatter"] = {
    { zone="northrend", placeName="Ulduar", x=57.9, y=11.5, mobs={"Kologarn"}, notes="Raid" },
  },
  ["tome-temporal-pressure"] = {
    { zone="kalimdor", placeName="Caverns of Time - The Culling of Stratholme", x=71.8, y=86.4, mobs={"Chrono-Lord Epoch"}, notes="Dungeon" },
  },
  ["tome-twilight-equilibrium"] = {
    { zone="northrend", placeName="Icecrown - Trial of the Crusader", x=45.3, y=19.5, mobs={"Fjola Lightbane"}, notes="Raid" },
  },
  ["tome-arcane-hazard"] = {
    { zone="kalimdor", placeName="Unknown location", x=65.6, y=7.5, mobs={}, notes="Found on enemies that use the abilities listed in the description" },
  },
  ["tome-arcane-ward"] = {
    { zone="kalimdor", placeName="Unknown location", x=63.7, y=5.3, mobs={}, notes="Found on arcane type enemies" },
  },
  ["tome-battlefield-hazard"] = {
    { zone="kalimdor", placeName="Unknown location", x=65.2, y=5.1, mobs={}, notes="Found on enemies that use warrior abilities" },
  },
  ["tome-blighted-hazard"] = {
    { zone="kalimdor", placeName="Unknown location", x=62.2, y=4.2, mobs={}, notes="Found on enemies that use death knight type spells" },
  },
  ["tome-demon-bane"] = {
    { zone="kalimdor", placeName="Unknown location", x=57.2, y=4.6, mobs={}, notes="Found on demon type enemies" },
  },
  ["tome-demon-slayer"] = {
    { zone="kalimdor", placeName="Unknown location", x=61.2, y=3.1, mobs={}, notes="Found on demon type enemies" },
  },
  ["tome-earthen-snap"] = {
    { zone="kalimdor", placeName="Unknown location", x=61.7, y=5.5, mobs={}, notes="Found on Entangling Roots type caster enemies" },
  },
  ["tome-earthen-spike"] = {
    { zone="kalimdor", placeName="Unknown location", x=60.1, y=4.4, mobs={}, notes="Found on earth elemental type enemies" },
  },
  ["tome-frost-ward"] = {
    { zone="kalimdor", placeName="Unknown location", x=66.9, y=3.4, mobs={}, notes="Found on frost elemental type enemies" },
  },
  ["tome-giant-bane"] = {
    { zone="kalimdor", placeName="Unknown location", x=67.4, y=5.7, mobs={}, notes="Found on giant type enemies" },
  },
  ["tome-giant-slayer"] = {
    { zone="kalimdor", placeName="Unknown location", x=70.4, y=6.9, mobs={}, notes="Fond on giant type enemies" },
  },
  ["tome-holy-hazard"] = {
    { zone="kalimdor", placeName="Unknown location", x=68.3, y=7.4, mobs={}, notes="Found on enemies that use priest type spells" },
  },
  ["tome-machine-slayer"] = {
    { zone="kalimdor", placeName="Unknown location", x=69.8, y=2.7, mobs={}, notes="Found on mechanical type enemies" },
  },
  ["tome-mechanical-bane"] = {
    { zone="kalimdor", placeName="Unknown location", x=73, y=5.9, mobs={}, notes="Found on mechanical type enemies" },
  },
  ["tome-provoking-presence"] = {
    { zone="kalimdor", placeName="Unknown location", x=73.5, y=2.6, mobs={}, notes="Found on tank type enemies" },
  },
  ["tome-rootbreaker"] = {
    { zone="kalimdor", placeName="Unknown location", x=76.4, y=6.9, mobs={}, notes="Found on mobs that cast Entangling Roots" },
  },
  ["tome-runic-momentum"] = {
    { zone="kalimdor", placeName="Unknown location", x=76.8, y=5.2, mobs={}, notes="Found on death knight type enemies" },
  },
  ["tome-sanctified-hazard"] = {
    { zone="kalimdor", placeName="Unknown location", x=75.9, y=3.5, mobs={}, notes="Found on mobs that use paladin type spells" },
  },
  ["tome-shadow-ward"] = {
    { zone="northrend", placeName="Wintergrasp - west side, near blackened area - Wintergrasp", x=34, y=49, mobs={"Wandering Shadow"}, notes="Open World" },
  },
  ["tome-steady-grip"] = {
    { zone="eastern-kingdoms", placeName="Stranglethorn Vale - Booty Bay (north bandit camp) - Stranglethorn Vale", x=26.2, y=94, mobs={"Bloodsail Raider"}, notes="Open World" },
  },
  ["tome-sundered-will"] = {
    { zone="kalimdor", placeName="Unknown location", x=79.9, y=5.9, mobs={}, notes="Found on enemies that cast fear / psychic scream" },
  },
  ["tome-wild-hazard"] = {
    { zone="kalimdor", placeName="Unknown location", x=82.5, y=6.6, mobs={}, notes="Found on druid type enemies" },
  },
}
