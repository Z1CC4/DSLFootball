%{
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <stdio.h>
void yyerror(const char *s)
{
    fprintf(stderr, "%s\n", s);
    exit(1);
}

int yylex(void);
%}
%union {
       char* str;			//identifier
       double value;			//value of an identifier of type NUM
       }
%token TEAM FORMATION PLAYER POSITION CAPTAIN
%token MATCH DATE RESULT SCORERS HOMETEAM AWAYTEAM
%token LBRACE RBRACE EQUAL HYPHEN SEMICOLON COMMA LSQUARE RSQUARE
%token <str> STRING VAR DATESTR POSITIONVAL
%token <num> NUMBER
%%

program : blocks;
blocks : block blocks | block;
block : team_declaration | match_declaration;
team_declaration: TEAM STRING LBRACE team_body RBRACE{
	start_team($2);
    end_team();
};
match_declaration: MATCH STRING LBRACE match_body RBRACE{
	start_match($2);
    end_match();
};
team_body: team_attribute team_body | team_attribute;
match_body: match_attribute match_body | match_attribute;
team_attribute: FORMATION formation_attribute SEMICOLON| 
		COACH EQUAL VAR SEMICOLON{
        set_coach($3);
    	}|
		CAPTAIN EQUAL VAR SEMICOLON{
        set_captain($3);
    	}|
		VICECAPTAIN EQUAL VAR SEMICOLON{
        set_vicecaptain($3);
    	}|
		STRATEGY EQUAL VAR SEMICOLON{
        set_strategy($3);
    	}|
		PLAYER VAR POSITION POSITIONVAL SEMICOLON{
        add_player($2, $4);
    	};
match_attribute:
    HOMETEAM EQUAL STRING SEMICOLON {
        set_home_team($3);
    }|
    AWAYTEAM EQUAL STRING SEMICOLON {
        set_away_team($3);
    }|
    DATE EQUAL DATESTR SEMICOLON {
        set_match_date($3);
    }|
    RESULT EQUAL NUMBER HYPHEN NUMBER SEMICOLON {
        set_result($3, $5);
    }|
    SCORERS EQUAL LSQUARE scorer_list RSQUARE {
        end_scorer_list();
    };

formation_attribute: NUMBER HYPHEN NUMBER HYPHEN NUMBER {
    set_formation($1, $3, $5);
};

scorer_list:
      scorer_list COMMA VAR {
        add_scorer($3);
    }|
    VAR {
        start_scorer_list();
        add_scorer($1);
    }|
    /* empty */ {
        start_scorer_list();
    };
%%

int main() {
    init_symbol_table();
    yyparse();
    return 0;
}
