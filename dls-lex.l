%option noyywrap
%{
#include <stdio.h>
int TokenCont=0;
%}

digit  [0-9]
letter [a-zA-Z]
digits {digit}+
id     {letter}({letter}|{digit})*
%%

	//keywords

[ \t\n] {}

"Team"       return TEAM; 
"Formation"  return FORMATION; 
"Player"     return PLAYER; 
"Position"   return POSITION;
"Captain"    return CAPTAIN; 
"Strategy"   return STRATEGY; 
"Match"      return MATCH; 
"Date" 	     return DATE; 
"Result"     return RESULT; 
"Scorers"    return SCORERS; 
"HomeTeam"   return HOMETEAM; 
"AwayTeam"   return AWAYTEAM; 

	//symbol 

"{"                    return LBRACE; 
"}"                    return RBRACE; 
"="                    return EQUAL; 
"-"                    return HYPHEN; 
";"                    return SEMICOLON; 
","          	       return COMMA; 
"["                    return LSQUARE; 
"]"                    return RSQUARE; 

	//id e position val


[A-Z]{2} return POSITIONVAL; 
{id}     return VAR; 

	//number, date, string

[0-9]+       return NUMBER; 
\"[0-9]{4}-[0-9]{2}-[0-9]{2}\" return DATESTR; 
\"[^\"]*\"   return STRING; 

	//all the other char are wrong
. { printf("Unknown character: %s\n", yytext); }

%%

int main()
{
yylex();
return 0;
}
