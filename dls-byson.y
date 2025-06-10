%{
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include "progetto.h"

void yyerror(const char *s) {
    fprintf(stderr, "%s\n", s);
    exit(1);
}

int yylex(void);
SymbolTable symbol_table;
// --- used for the function, to know which team to change---
const char* current_team_name = NULL;
const char* current_match_name = NULL;
%}
%define parse.error verbose
%union {
    char* str;
    int num;
}
// --- tokens from l---
%token TEAM MATCH PLAYER FORMATION POSITION CAPTAIN VICECAPTAIN COACH STRATEGY
%token STADIUM HOMETEAM AWAYTEAM DATE TIME WEATHER RESULT SCORERS REFEREE
%token LBRACE RBRACE EQUAL HYPHEN SEMICOLON COMMA LSQUARE RSQUARE LPAREN RPAREN
%token <str> STRING DATESTR
%token <num> NUMBER

%token SETCAPTAIN SETCOACH SETVICECAPTAIN SETSTRATEGY SETFORMATION
%token SETSTADIUM SETHOMETEAM SETAWAYTEAM SETMATCHDATE SETMATCHTIME SETWEATHER SETREFEREE SETRESULT

%token HASPLAYER HASCAPTAIN HASFORMATION HASCOACH HASVICECAPTAIN HASSTRATEGY
%token HASSTADIUM HASDATE HASTIME HASWEATHER HASRESULT HASREFEREE HASSCORER

%%

// --- the programm is composed by blocks, they can be teamdeclaration, matchdeclaraction or operationdeclaration, more we have an erorr so that if it encounter some unexpected  carachter it goes in erorr ---

program : blocks;

blocks :
      block blocks
    | block
    | error { yyerror("Errore di sintassi generico."); YYABORT; }
    ;

block :
      team_declaration
    | match_declaration
    | operation_declaration
    ;
// --- we create the team, end before closing it we set the attrbites of the various elements, we then do the checks for the semantic (es no more 11 player), and for each we have a specific erorr message ---
team_declaration:
    TEAM STRING LBRACE {
        current_team_name = $2;
        start_team(&symbol_table, $2);
    } team_body RBRACE {
        end_team(&symbol_table, $2);
        char error_detail[256];
        Team *team = get_team_by_name(&symbol_table, $2);
        if (!team) {
            yyerror("Internal error, team not found in the creation!");
            YYABORT;
        }
        TeamValidationError err = validate_team(team, error_detail);
        switch (err) {
            case TEAM_OK: break;
            default: yyerror(error_detail); YYABORT;
        }
    }
    ;
// --- same thing from team ---
match_declaration:
    MATCH STRING LBRACE {
        current_match_name = $2;
        start_match(&symbol_table, $2);
     } match_body RBRACE {
        end_match(&symbol_table, $2);
        char error_detail[256];
        Match *match = get_match_by_name(&symbol_table, $2);
        if (!match) {
            yyerror("Errore interno: match non trovato dopo la creazione!");
            YYABORT;
        }
        MatchValidationError err = validate_match(match, &symbol_table, error_detail);
        switch (err) {
            case MATCH_OK: break;
            default: yyerror(error_detail); YYABORT;
        }
    }
    ;

team_body:
      team_attribute team_body
    | team_attribute
    ;
// --- set the attribute of the team and then of the match---
team_attribute:
    FORMATION NUMBER HYPHEN NUMBER HYPHEN NUMBER SEMICOLON {
        set_formation(&symbol_table, current_team_name, $2, $4, $6);
    }
  | COACH EQUAL STRING SEMICOLON {
        if (!is_string($3))
            yyerror("Coach must be a string");
        set_coach(&symbol_table, current_team_name, $3);
    }
  | CAPTAIN EQUAL STRING SEMICOLON {
        Team* team = get_team_by_name(&symbol_table, current_team_name);
        if (!is_player_in_team(team, $3))
            yyerror("Captain must be a declared player");
        set_captain(&symbol_table, current_team_name, $3);
    }
  | VICECAPTAIN EQUAL STRING SEMICOLON {
        Team* team = get_team_by_name(&symbol_table, current_team_name);
        if (!is_player_in_team(team, $3))
            yyerror("Vice-captain must be a declared player");
        set_vicecaptain(&symbol_table, current_team_name, $3);
    }
  | STRATEGY EQUAL STRING SEMICOLON {
        if (!is_string($3))
            yyerror("Strategy must be a string");
        set_strategy(&symbol_table, current_team_name, $3);
    }
  | PLAYER STRING POSITION STRING SEMICOLON {
        if (!is_non_empty_name($2))
            yyerror("Player name cannot be empty");
        if (!is_valid_position($4))
            yyerror("Player position must be a valid two-letter code (e.g. GK, CB, ST)");
        add_player_to_team(&symbol_table, current_team_name, $2, $4);
    }
  ;

match_body:
      match_attribute match_body
    | match_attribute
    ;

match_attribute:
    STADIUM EQUAL STRING SEMICOLON {
        set_stadium(&symbol_table, current_match_name, $3);
    }
  | HOMETEAM EQUAL STRING SEMICOLON {
        if (!lookup_symbol(&symbol_table, $3, "TEAM"))
            yyerror("Home team must be a declared team");
        set_home_team(&symbol_table, current_match_name, $3);
    }
  | AWAYTEAM EQUAL STRING SEMICOLON {
        if (!lookup_symbol(&symbol_table, $3, "TEAM"))
            yyerror("Away team must be a declared team");
        set_away_team(&symbol_table, current_match_name, $3);
    }
  | DATE EQUAL DATESTR SEMICOLON {
        if (!is_valid_date($3))
            yyerror("Date must be in the format YYYY-MM-DD and must be a real date");
        set_match_date(&symbol_table, current_match_name, $3);
    }
  | TIME EQUAL STRING SEMICOLON {
        set_match_time(&symbol_table, current_match_name, $3);
    }
  | WEATHER EQUAL STRING SEMICOLON {
        set_weather(&symbol_table, current_match_name, $3);
    }
  | REFEREE EQUAL STRING SEMICOLON {
        set_referee(&symbol_table, current_match_name, $3);
    }
  | RESULT EQUAL NUMBER HYPHEN NUMBER SEMICOLON {
        char buf[20];
        snprintf(buf, sizeof(buf), "%d-%d", (int)$3, (int)$5);
        if (!is_valid_result(buf))
            yyerror("Result must be in the format X-Y with both X and Y >= 0");
        set_result(&symbol_table, current_match_name, buf);
    }
  | SCORERS EQUAL LSQUARE scorer_list RSQUARE SEMICOLON {
        end_scorer_list(&symbol_table, current_match_name);
    }
  ;

scorer_list:
      scorer_list COMMA STRING {
        add_scorer(&symbol_table, current_match_name, $3);
    }
    | STRING {
        start_scorer_list(&symbol_table, current_match_name);
        add_scorer(&symbol_table, current_match_name, $1);
    }
    | /* empty */ {
        start_scorer_list(&symbol_table, current_match_name);
    }
    ;

// ----- OPERATIONS: SET and HAS -----

operation_declaration :
      set_captain_fun
    | set_coach_fun
    | set_vicecaptain_fun
    | set_strategy_fun
    | set_formation_fun
    | set_stadium_fun
    | set_hometeam_fun
    | set_awayteam_fun
    | set_matchdate_fun
    | set_matchtime_fun
    | set_weather_fun
    | set_referee_fun
    | set_result_fun
    | has_player_fun
    | has_captain_fun
    | has_formation_fun
    | has_coach_fun
    | has_vicecaptain_fun
    | has_strategy_fun
    | has_stadium_fun
    | has_date_fun
    | has_time_fun
    | has_weather_fun
    | has_result_fun
    | has_referee_fun
    | has_scorer_fun
    ;

set_captain_fun : SETCAPTAIN LPAREN STRING COMMA STRING RPAREN SEMICOLON {
    set_captain(&symbol_table, $3, $5);
    printf("setCaptain(%s, %s)\n", $3, $5);
    free($3); free($5);
};
set_coach_fun : SETCOACH LPAREN STRING COMMA STRING RPAREN SEMICOLON {
    set_coach(&symbol_table, $3, $5);
    printf("setCoach(%s, %s)\n", $3, $5);
    free($3); free($5);
};
set_vicecaptain_fun : SETVICECAPTAIN LPAREN STRING COMMA STRING RPAREN SEMICOLON {
    set_vicecaptain(&symbol_table, $3, $5);
    printf("setViceCaptain(%s, %s)\n", $3, $5);
    free($3); free($5);
};
set_strategy_fun : SETSTRATEGY LPAREN STRING COMMA STRING RPAREN SEMICOLON {
    set_strategy(&symbol_table, $3, $5);
    printf("setStrategy(%s, %s)\n", $3, $5);
    free($3); free($5);
};
set_formation_fun : SETFORMATION LPAREN STRING COMMA NUMBER COMMA NUMBER COMMA NUMBER RPAREN SEMICOLON {
    set_formation(&symbol_table, $3, $5, $7, $9);
    printf("setFormation(%s, %d, %d, %d)\n", $3, $5, $7, $9);
    free($3);
};

set_stadium_fun : SETSTADIUM LPAREN STRING COMMA STRING RPAREN SEMICOLON {
    set_stadium(&symbol_table, $3, $5);
    printf("setStadium(%s, %s)\n", $3, $5);
    free($3); free($5);
};
set_hometeam_fun : SETHOMETEAM LPAREN STRING COMMA STRING RPAREN SEMICOLON {
    set_home_team(&symbol_table, $3, $5);
    printf("setHomeTeam(%s, %s)\n", $3, $5);
    free($3); free($5);
};
set_awayteam_fun : SETAWAYTEAM LPAREN STRING COMMA STRING RPAREN SEMICOLON {
    set_away_team(&symbol_table, $3, $5);
    printf("setAwayTeam(%s, %s)\n", $3, $5);
    free($3); free($5);
};
set_matchdate_fun : SETMATCHDATE LPAREN STRING COMMA DATESTR RPAREN SEMICOLON {
    set_match_date(&symbol_table, $3, $5);
    printf("setMatchDate(%s, %s)\n", $3, $5);
    free($3); free($5);
};
set_matchtime_fun : SETMATCHTIME LPAREN STRING COMMA STRING RPAREN SEMICOLON {
    set_match_time(&symbol_table, $3, $5);
    printf("setMatchTime(%s, %s)\n", $3, $5);
    free($3); free($5);
};
set_weather_fun : SETWEATHER LPAREN STRING COMMA STRING RPAREN SEMICOLON {
    set_weather(&symbol_table, $3, $5);
    printf("setWeather(%s, %s)\n", $3, $5);
    free($3); free($5);
};
set_referee_fun : SETREFEREE LPAREN STRING COMMA STRING RPAREN SEMICOLON {
    set_referee(&symbol_table, $3, $5);
    printf("setReferee(%s, %s)\n", $3, $5);
    free($3); free($5);
};
set_result_fun : SETRESULT LPAREN STRING COMMA STRING RPAREN SEMICOLON {
    set_result(&symbol_table, $3, $5);
    printf("setResult(%s, %s)\n", $3, $5);
    free($3); free($5);
};

has_player_fun : HASPLAYER LPAREN STRING COMMA STRING RPAREN SEMICOLON {
    Team* t = get_team_by_name(&symbol_table, $3);
    int found = hasPlayer(t, $5);
    printf("hasPlayer(%s, %s) = %d\n", $3, $5, found);
    free($3); free($5);
};
has_captain_fun : HASCAPTAIN LPAREN STRING COMMA STRING RPAREN SEMICOLON {
    Team* t = get_team_by_name(&symbol_table, $3);
    int found = hasCaptain(t, $5);
    printf("hasCaptain(%s, %s) = %d\n", $3, $5, found);
    free($3); free($5);
};
has_formation_fun : HASFORMATION LPAREN STRING COMMA NUMBER COMMA NUMBER COMMA NUMBER RPAREN SEMICOLON {
    Team* t = get_team_by_name(&symbol_table, $3);
    Formation f = {.defence=$5, .midfield=$7, .attack=$9};
    int found = hasFormation(t, f);
    printf("hasFormation(%s, %d-%d-%d) = %d\n", $3, $5, $7, $9, found);
    free($3);
};
has_coach_fun : HASCOACH LPAREN STRING COMMA STRING RPAREN SEMICOLON {
    Team* t = get_team_by_name(&symbol_table, $3);
    int found = hasCoach(t, $5);
    printf("hasCoach(%s, %s) = %d\n", $3, $5, found);
    free($3); free($5);
};
has_vicecaptain_fun : HASVICECAPTAIN LPAREN STRING COMMA STRING RPAREN SEMICOLON {
    Team* t = get_team_by_name(&symbol_table, $3);
    int found = hasViceCaptain(t, $5);
    printf("hasViceCaptain(%s, %s) = %d\n", $3, $5, found);
    free($3); free($5);
};
has_strategy_fun : HASSTRATEGY LPAREN STRING COMMA STRING RPAREN SEMICOLON {
    Team* t = get_team_by_name(&symbol_table, $3);
    int found = hasStrategy(t, $5);
    printf("hasStrategy(%s, %s) = %d\n", $3, $5, found);
    free($3); free($5);
};

has_stadium_fun : HASSTADIUM LPAREN STRING COMMA STRING RPAREN SEMICOLON {
    Match* m = get_match_by_name(&symbol_table, $3);
    int found = hasStadium(m, $5);
    printf("hasStadium(%s, %s) = %d\n", $3, $5, found);
    free($3); free($5);
};
has_date_fun : HASDATE LPAREN STRING COMMA DATESTR RPAREN SEMICOLON {
    Match* m = get_match_by_name(&symbol_table, $3);
    int found = hasDate(m, $5);
    printf("hasDate(%s, %s) = %d\n", $3, $5, found);
    free($3); free($5);
};
has_time_fun : HASTIME LPAREN STRING COMMA STRING RPAREN SEMICOLON {
    Match* m = get_match_by_name(&symbol_table, $3);
    int found = hasTime(m, $5);
    printf("hasTime(%s, %s) = %d\n", $3, $5, found);
    free($3); free($5);
};
has_weather_fun : HASWEATHER LPAREN STRING COMMA STRING RPAREN SEMICOLON {
    Match* m = get_match_by_name(&symbol_table, $3);
    int found = hasWeather(m, $5);
    printf("hasWeather(%s, %s) = %d\n", $3, $5, found);
    free($3); free($5);
};
has_result_fun : HASRESULT LPAREN STRING COMMA STRING RPAREN SEMICOLON {
    Match* m = get_match_by_name(&symbol_table, $3);
    int found = hasResult(m, $5);
    printf("hasResult(%s, %s) = %d\n", $3, $5, found);
    free($3); free($5);
};
has_referee_fun : HASREFEREE LPAREN STRING COMMA STRING RPAREN SEMICOLON {
    Match* m = get_match_by_name(&symbol_table, $3);
    int found = hasReferee(m, $5);
    printf("hasReferee(%s, %s) = %d\n", $3, $5, found);
    free($3); free($5);
};
has_scorer_fun : HASSCORER LPAREN STRING COMMA STRING RPAREN SEMICOLON {
    Match* m = get_match_by_name(&symbol_table, $3);
    int found = hasScorer(m, $5);
    printf("hasScorer(%s, %s) = %d\n", $3, $5, found);
    free($3); free($5);
};

%%
// --- in the main we create the symbol table (so that we dont need global variable) and after being parsed if there are no error we let out a positive message---
int main() {
    initialize_symbol_table(&symbol_table);
    yyparse();
    printf("Input accettato.\n");
    write_json_summary_to_file(&symbol_table, "output.json");
    return 0;
}

int yywrap() { return 1; }
