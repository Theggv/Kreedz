#if defined _map_manager_consts_included
  #endinput
#endif
#define _map_manager_consts_included

const MAPNAME_LENGTH = 32;

enum _:MapStruct {
    Map[MAPNAME_LENGTH],
    MinPlayers,
    MaxPlayers
};

enum _:NomStruct {
    NomMap[MAPNAME_LENGTH],
    NomPlayer
};

// used as return value in forward "mapm_can_be_in_votelist"
enum {
    MAP_ALLOWED,
    MAP_BLOCKED
};

enum (<<=1) {
    CHECK_NOT_IGNORED = 0,
    CHECK_IGNORE_MAP_ALLOWED = 1 << 0,
    CHECK_IGNORE_VALID_MAP
};

// used as return value in native "mapm_push_map_to_votelist"
enum {
    PUSH_BLOCKED = -1,
    PUSH_CANCELED,
    PUSH_SUCCESS
};

// used for type param in native "mapm_push_map_to_votelist"
enum {
    PUSH_BY_CORE,
    PUSH_BY_NATIVE,
    PUSH_BY_SECOND_VOTE,
    PUSH_BY_NOMINATION,
    PUSH_BY_ONLINE_SORTER
};

enum {
    VOTE_BY_CMD,
    VOTE_BY_RTV,
    VOTE_BY_SCHEDULER,
    VOTE_BY_SCHEDULER_SECOND
};

// used as return value in forward "mapm_analysis_of_results"
enum {
    ALLOW_VOTE,
    ABORT_VOTE,
    ABORT_VOTE_WITH_FORWARD
};

// used for cvar "mapm_extended_type"
enum {
    EXTEND_MINUTES,
    EXTEND_ROUNDS
};

// used as return value in forward "mapm_can_be_extended"
enum {
    EXTEND_ALLOWED,
    EXTEND_BLOCKED
};

const INVALID_MAP_INDEX = -1;

// used for type param in forward "mapm_countdown"
enum {
    COUNTDOWN_UNKNOWN = -1,
    COUNTDOWN_PREPARE,
    COUNTDOWN_VOTETIME
}

// used for cvar "mapm_show_result_type"
enum {
    SHOW_DISABLED,
    SHOW_MENU,
    SHOW_HUD
};

// used for cvar "mapm_show_percent"
enum {
    PERCENT_DISABLED,
    PERCENT_ALWAYS,
    PERCENT_AFTER_VOTE
};

// used for forward "mapm_can_be_nominated"
enum {
    NOMINATION_ALLOWED,
    NOMINATION_BLOCKED
};
