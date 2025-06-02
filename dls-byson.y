%{
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <stdio.h>

void yyerror(const char *s) {
    fprintf(stderr, "%s\n", s);
    exit(1);
}

int yylex(void);
%}
%union {
    char* str;		//identifier
    double value;	//value of an identifier of type NUM
	}

%token TEAM MATCH PLAYER FORMATION POSITION CAPTAIN VICECAPTAIN COACH STRATEGY
%token STADIUM HOMETEAM AWAYTEAM DATE TIME WEATHER RESULT SCORERS REFEREE
%token LBRACE RBRACE EQUAL HYPHEN SEMICOLON COMMA LSQUARE RSQUARE
%token <str> STRING VAR DATESTR TIMESTR POSITIONVAL STRATEGYVAL
%token <num> NUMBER
%%

program : blocks;

blocks : block blocks
       | block;

block : team_declaration
      | match_declaration;

team_declaration:
    TEAM STRING LBRACE team_body RBRACE {
        start_team($2);
        end_team();
        char error_detail[256];
        Team *team = get_team_by_name($2);
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
    MATCH STRING LBRACE match_body RBRACE {
        start_match($2);
        end_match();
        char error_detail[256];
        Match *match = get_match_by_name($2); // implementa questa funzione come per get_team_by_name!
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
  | team_attribute;

match_body:
    match_attribute match_body
  | match_attribute;

team_attribute:
    FORMATION formation_attribute SEMICOLON {
      set_formation(current_team_name, $1, $3, $5);
   }
  | COACH EQUAL VAR SEMICOLON {
        if (!is_string($3))
            yyerror("Coach must be a string");
        set_coach($3);
    }
  | CAPTAIN EQUAL VAR SEMICOLON {
        if (!is_player_in_team(current_team_name, $3))
            yyerror("Captain must be a declared player");
        set_captain($3);
    }
  | VICECAPTAIN EQUAL VAR SEMICOLON {
        if (!is_player_in_team(current_team_name, $3))
            yyerror("Vice-captain must be a declared player");
        set_vicecaptain($3);
    }
  | STRATEGY EQUAL VAR SEMICOLON {
        if (!is_string($3))
            yyerror("Strategy must be a string");
        set_strategy($3);
    }
  | PLAYER VAR POSITION POSITIONVAL SEMICOLON {
        if (!is_non_empty_name($2))
            yyerror("Player name cannot be empty");
        if (!is_valid_position($4))
            yyerror("Player position must be a valid two-letter code (e.g. GK, CB, ST)");
        add_player_to_team(current_team_name, $2, $4);
    };

match_attribute:
    STADIUM EQUAL STRING SEMICOLON {
        set_stadium($3);
    }
  | HOMETEAM EQUAL STRING SEMICOLON {
        if (!lookup_symbol(&symbol_table, $3, "TEAM"))
            yyerror("Home team must be a declared team");
        set_home_team($3);
    }
  | AWAYTEAM EQUAL STRING SEMICOLON {
        if (!lookup_symbol(&symbol_table, $3, "TEAM"))
            yyerror("Away team must be a declared team");
        set_away_team($3);
    }
  | DATE EQUAL DATESTR SEMICOLON {
        if (!is_valid_date($3))
            yyerror("Date must be in the format YYYY-MM-DD and must be a real date");
        set_match_date($3);
    }
  | TIME EQUAL TIMESTR SEMICOLON {
        set_match_time($3);
    }
  | WEATHER EQUAL STRING SEMICOLON {
        set_weather($3);
    }
  | REFEREE EQUAL STRING SEMICOLON {
        set_referee($3);
    }
  | RESULT EQUAL NUMBER HYPHEN NUMBER SEMICOLON {
         char buf[20];
        snprintf(buf, sizeof(buf), "%d-%d", (int)$3, (int)$5);
        if (!is_valid_result(buf))
            yyerror("Result must be in the format X-Y with both X and Y >= 0");
        set_result($3, $5);
    }
  | SCORERS EQUAL LSQUARE scorer_list RSQUARE {
        end_scorer_list();
    };

formation_attribute:
    NUMBER HYPHEN NUMBER HYPHEN NUMBER {
        set_formation($1, $3, $5);
    };

scorer_list:
    scorer_list COMMA VAR {
        add_scorer($3);
    }
  | VAR {
        start_scorer_list();
        add_scorer($1);
    }
  | /* empty */ {
        start_scorer_list();
    };
%%

int main() {
    init_symbol_table();
    yyparse();
    return 0;
}
