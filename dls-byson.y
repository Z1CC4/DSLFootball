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
       char* lexeme;			//identifier
       double value;			//value of an identifier of type NUM
       }
%token TEAM FORMATION PLAYER POSITION CAPTAIN
%token MATCH DATE RESULT SCORERS HOMETEAM AWAYTEAM
%token LBRACE RBRACE EQUAL HYPHEN SEMICOLON COMMA LSQUARE RSQUARE
%token <str> STRING
%token <str> VAR
%token <str> DATESTR
%token <str> POSITIONVAL
%token <num> NUMBER
%%

program : blocks;
blocks : block blocks | block;
block : team_declaration | match_declaration;
team_declaration: TEAM STRING LBRACE team_body RBRACE;
match_declaration: MATCH STRING LBRACE match_body RBRACE;
team_body: team_attribute team_body | team_attribute;
match_body: match_attribute match_body | match_attribute;
team_attribute: FORMATION formation_attribute SEMICOLON| 
		COACH EQUAL VAR SEMICOLON|
		CAPTAIN EQUAL VAR SEMICOLON|
		VICECAPTAIN EQUAL VAR SEMICOLON|
		STRATEGY EQUAL VAR SEMICOLON|
		PLAYER VAR POSITION POSITIONVAL SEMICOLON;
match_attribute: HOMETEAM EQUAL STRING SEMICOLON |
		 AWAYTEAM EQUAL STRING SEMICOLON|
		 DATE EQUAL DATESTR SEMICOLON|
		 RESULT EQUAL NUMBER HYPHEN NUMBER SEMICOLON|
		 SCORERS EQUAL LSQUARE scorer_list RSQUARE SEMICOLON;
formation_attribute: FORMATION NUMBER HYPHEN NUMBER HYPHEN NUMBER SEMICOLON;
scorer_list: scorer_list COMMA VAR|VAR|
%%

int main() {
    yyparse();
    return 0;
}

