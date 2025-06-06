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
const char* current_team_name = NULL;
const char* current_match_name = NULL;
%}
%define parse.error verbose
%union {
    char* str;
    int num;
}

%token TEAM MATCH PLAYER FORMATION POSITION CAPTAIN VICECAPTAIN COACH STRATEGY
%token STADIUM HOMETEAM AWAYTEAM DATE TIME WEATHER RESULT SCORERS REFEREE
%token LBRACE RBRACE EQUAL HYPHEN SEMICOLON COMMA LSQUARE RSQUARE 
%token <str> STRING DATESTR
%token <num> NUMBER

%%

program : blocks;

blocks : block blocks
       | block
       | error { yyerror("Errore di sintassi generico."); YYABORT; };

block : team_declaration
      | match_declaration;

team_declaration:
    TEAM STRING LBRACE {
        current_team_name = $2;
        start_team(&symbol_table, $2);
    } team_body RBRACE {
        end_team(&symbol_table, $2);
        char error_detail[256];
        Team *team = get_team_by_name(&symbol_table, $2);
        if (!team) {
            yyerror("Errore interno: team non trovato dopo la creazione!");
            YYABORT;
        }
        TeamValidationError err = validate_team(team, error_detail);
        switch (err) {
            case TEAM_OK: break;
            default: yyerror(error_detail); YYABORT;
        }
    };

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
    };

team_body:
    team_attribute team_body
  | team_attribute
  ;

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
%%

int main() {
    initialize_symbol_table(&symbol_table);
    yyparse();
    printf("Input accettato.\n");
    return 0;
}

int yywrap() { return 1; }
