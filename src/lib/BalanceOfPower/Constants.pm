package BalanceOfPower::Constants;

use strict;

use base 'Exporter';

#Random init parameters 
use constant MIN_EXPORT_QUOTE => 30;
use constant MAX_EXPORT_QUOTE => 60;
use constant MIN_STARTING_TRADEROUTES => 1;
use constant MAX_STARTING_TRADEROUTES => 3;
use constant MIN_STARTING_PRODUCTION => 20;
use constant MAX_STARTING_PRODUCTION => 40;
use constant MIN_GOVERNMENT_STRENGTH => 50;
use constant MAX_GOVERNMENT_STRENGTH => 100;
use constant STARTING_ALLIANCES => 7;

#Random parameters 
use constant MIN_DELTA_PRODUCTION => -10;
use constant MAX_DELTA_PRODUCTION => 10;
use constant MAX_PRODUCTION => 50;
use constant MIN_ADDED_DISORDER => -2;
use constant MAX_ADDED_DISORDER => 2;
use constant CRISIS_GENERATION_TRIES => 5;
use constant CRISIS_GENERATOR_NOACTION_TOKENS => 6;

#export costs
use constant ADDING_TRADEROUTE_COST => 30;
use constant TRADEROUTE_COST => 10;
use constant TRADING_QUOTE => 15;
use constant AID_INSURGENTS_COST => 25;
use constant ECONOMIC_AID_COST => 40;

#domestic costs
use constant RESOURCES_FOR_DISORDER => 20;
use constant ARMY_COST => 20;

#IA Thresholds
use constant WORRYING_LIMIT => 30;
use constant DOMESTIC_BUDGET => 50;
use constant MINIMUM_ARMY_LIMIT => 5;
use constant MEDIUM_ARMY_LIMIT => 10;
use constant MEDIUM_ARMY_BUDGET => 40;
use constant MAX_ARMY_BUDGET => 60;
use constant MIN_ARMY_FOR_WAR => 5;
use constant MIN_INFERIOR_ARMY_RATIO_FOR_WAR => 1.2;
use constant MIN_ARMY_TO_EXPORT => 12;
use constant ARMY_TO_RECALL_SUPPORT => 3;
use constant ALLY_CONFLICT_LEVEL_FOR_INVOLVEMENT => 2;

#Civil war
use constant STARTING_REBEL_PROVINCES => [1, 1, 2];
use constant CIVIL_WAR_WIN => 3;
use constant AFTER_CIVIL_WAR_INTERNAL_DISORDER => 35;
use constant ARMY_UNIT_FOR_CIVIL_WAR => 2;
use constant ARMY_HELP_FOR_CIVIL_WAR => 10;
use constant DICTATORSHIP_BONUS_FOR_CIVIL_WAR => 10;
use constant REBEL_ARMY_FOR_SUPPORT => 4;
use constant SUPPORT_HELP_FOR_CIVIL_WAR => 7; 
use constant REBEL_SUPPORT_HELP_FOR_CIVIL_WAR => 7; 
use constant DIPLOMACY_MALUS_FOR_CROSSED_CIVIL_WAR_SUPPORT => 3;

#War & domination
use constant ARMY_FOR_BATTLE => 3;
use constant WAR_WEALTH_MALUS => 20;
use constant ATTACK_FAILED_PRODUCTION_MALUS => 10;
use constant AFTER_CONQUERED_INTERNAL_DISORDER => 30;
use constant OCCUPATION_LOOT_BY_TYPE => 20;
use constant DOMINATION_LOOT_BY_TYPE => 20;
use constant CONTROL_LOOT_BY_TYPE => 0;
use constant DOMINATION_CLOCK_LIMIT => 5;
use constant OCCUPATION_CLOCK_LIMIT => 1;
use constant DIPLOMACY_MALUS_FOR_SUPPORT => 2;

#Others
use constant TRADEROUTE_SIZE_BONUS => .5;
use constant PRODUCTION_UNITS => [ 2, 3, 4 ];
use constant INTERNAL_PRODUCTION_GAIN => 1;
use constant INTERNAL_DISORDER_TERRORISM_LIMIT => 10;
use constant INTERNAL_DISORDER_INSURGENCE_LIMIT => 40;
use constant INTERNAL_DISORDER_CIVIL_WAR_LIMIT => 80;
use constant DISORDER_REDUCTION => 10;
use constant DEBT_ALLOWED => 0;
use constant DEBT_TO_RAISE_LIMIT => 50;
use constant PRODUCTION_THROUGH_DEBT => 40;
use constant MAX_DEBT => 3;
use constant TURNS_FOR_YEAR => 4;
use constant HATE_LIMIT => 30;
use constant LOVE_LIMIT => 70;
use constant MAX_ARMY_FOR_SIZE => [ 9, 12, 15];
use constant ARMY_UNIT => 1;
use constant TRADEROUTE_DIPLOMACY_FACTOR => 6;
use constant CRISIS_MAX_FACTOR => 3;
use constant ALLIANCE_FRIENDSHIP_FACTOR => 200;
use constant EMERGENCY_PRODUCTION_LIMIT => 55;
use constant BOOST_PRODUCTION_QUOTE => 5;
use constant ARMY_TO_ACCEPT_MILITARY_SUPPORT => 10;
use constant ARMY_FOR_SUPPORT => 4;
use constant DIPLOMACY_FACTOR_BREAKING_SUPPORT => 12;
use constant DIPLOMACY_FACTOR_STARTING_SUPPORT => 10;
use constant DIPLOMACY_FACTOR_STARTING_REBEL_SUPPORT => -10;
use constant DICTATORSHIP_PRODUCTION_MALUS => 15;
use constant DICTATORSHIP_BONUS_FOR_ARMY_CONSTRUCTION => 5;
use constant INSURGENTS_AID => 15;
use constant INFLUENCE_PRESTIGE_BONUS => 3;
use constant BEST_WEALTH_FOR_PRESTIGE => 5;
use constant BEST_WEALTH_FOR_PRESTIGE_BONUS => 5;
use constant WAR_PRESTIGE_BONUS => 10;
use constant TREATY_PRESTIGE_COST => 7;
use constant TREATY_TRADE_FACTOR => .5;
use constant ECONOMIC_AID_QUOTE => 7;
use constant ECONOMIC_AID_DIPLOMACY_FACTOR => 9;

our @EXPORT_OK = ('MIN_EXPORT_QUOTE', 
                  'MAX_EXPORT_QUOTE',
                  'MIN_STARTING_TRADEROUTES',
                  'MAX_STARTING_TRADEROUTES',
                  'ADDING_TRADEROUTE_COST',
                  'MIN_DELTA_PRODUCTION',
                  'MAX_DELTA_PRODUCTION',
                  'MAX_PRODUCTION',
                  'MIN_STARTING_PRODUCTION',
                  'MAX_STARTING_PRODUCTION',
                  'PRODUCTION_UNITS',
                  'INTERNAL_PRODUCTION_GAIN',
                  'TRADING_QUOTE',
                  'TRADEROUTE_COST',
                  'INTERNAL_DISORDER_TERRORISM_LIMIT',
                  'INTERNAL_DISORDER_INSURGENCE_LIMIT',
                  'INTERNAL_DISORDER_CIVIL_WAR_LIMIT',
                  'MIN_ADDED_DISORDER',
                  'MAX_ADDED_DISORDER',
                  'WORRYING_LIMIT',
                  'DOMESTIC_BUDGET',
                  'RESOURCES_FOR_DISORDER',
                  'DISORDER_REDUCTION',
                  'MIN_GOVERNMENT_STRENGTH',
                  'MAX_GOVERNMENT_STRENGTH',
                  'DEBT_TO_RAISE_LIMIT',
                  'PRODUCTION_THROUGH_DEBT',
                  'MAX_DEBT',
                  'DEBT_ALLOWED',
                  'CIVIL_WAR_WIN',
                  'STARTING_REBEL_PROVINCES',
                  'AFTER_CIVIL_WAR_INTERNAL_DISORDER',
                  'TURNS_FOR_YEAR',
                  'HATE_LIMIT',
                  'LOVE_LIMIT',
                  'MINIMUM_ARMY_LIMIT',
                  'MEDIUM_ARMY_LIMIT',
                  'MAX_ARMY_FOR_SIZE',
                  'MEDIUM_ARMY_BUDGET',
                  'MAX_ARMY_BUDGET',
                  'ARMY_COST',
                  'ARMY_UNIT',
                  'ARMY_FOR_BATTLE',
                  'TRADEROUTE_DIPLOMACY_FACTOR',
                  'ARMY_UNIT_FOR_CIVIL_WAR',
                  'ARMY_HELP_FOR_CIVIL_WAR',
                  'CRISIS_GENERATOR_NOACTION_TOKENS',
                  'CRISIS_GENERATION_TRIES',
                  'CRISIS_MAX_FACTOR',
                  'MIN_ARMY_FOR_WAR',
                  'MIN_INFERIOR_ARMY_RATIO_FOR_WAR',
                  'WAR_WEALTH_MALUS',
                  'ATTACK_FAILED_PRODUCTION_MALUS',
                  'AFTER_CONQUERED_INTERNAL_DISORDER',
                  'OCCUPATION_LOOT_BY_TYPE',
                  'DOMINATION_LOOT_BY_TYPE',
                  'CONTROL_LOOT_BY_TYPE',
                  'OCCUPATION_CLOCK_LIMIT',
                  'DOMINATION_CLOCK_LIMIT',
                  'ALLIANCE_FRIENDSHIP_FACTOR',
                  'ALLY_CONFLICT_LEVEL_FOR_INVOLVEMENT',
                  'STARTING_ALLIANCES',
                  'EMERGENCY_PRODUCTION_LIMIT',
                  'BOOST_PRODUCTION_QUOTE',
                  'MIN_ARMY_TO_EXPORT',
                  'ARMY_TO_ACCEPT_MILITARY_SUPPORT',
                  'ARMY_FOR_SUPPORT',
                  'DIPLOMACY_FACTOR_BREAKING_SUPPORT',
                  'DIPLOMACY_FACTOR_STARTING_SUPPORT',
                  'DIPLOMACY_MALUS_FOR_SUPPORT',
                  'ARMY_TO_RECALL_SUPPORT',
                  'TRADEROUTE_SIZE_BONUS',
                  'DICTATORSHIP_PRODUCTION_MALUS',
                  'DICTATORSHIP_BONUS_FOR_CIVIL_WAR',
                  'DICTATORSHIP_BONUS_FOR_ARMY_CONSTRUCTION',
                  'AID_INSURGENTS_COST',
                  'INSURGENTS_AID',
                  'INFLUENCE_PRESTIGE_BONUS',
                  'BEST_WEALTH_FOR_PRESTIGE',
                  'BEST_WEALTH_FOR_PRESTIGE_BONUS',
                  'WAR_PRESTIGE_BONUS',
                  'TREATY_PRESTIGE_COST',
                  'TREATY_TRADE_FACTOR',
                  'ECONOMIC_AID_COST',
                  'ECONOMIC_AID_QUOTE',
                  'ECONOMIC_AID_DIPLOMACY_FACTOR',
                  'REBEL_ARMY_FOR_SUPPORT',
                  'DIPLOMACY_FACTOR_STARTING_REBEL_SUPPORT',
                  'SUPPORT_HELP_FOR_CIVIL_WAR', 
                  'REBEL_SUPPORT_HELP_FOR_CIVIL_WAR',
                  'DIPLOMACY_MALUS_FOR_CROSSED_CIVIL_WAR_SUPPORT', 
                );
our %EXPORT_TAGS = ( all => \@EXPORT_OK );
