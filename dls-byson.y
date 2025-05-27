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
%token TEAM FORMATION PLAYER POSITION CAPTAIN TEAM FORMATION PLAYER POSITION CAPTAIN
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
team_attribute: FORMATION



