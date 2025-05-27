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

"Team"       { printf("%d KEYWORD \"Team\"\n", ++TokenCont); return TEAM; }
"Formation"  { printf("%d KEYWORD \"Formation\"\n", ++TokenCont); return FORMATION; }
"Player"     { printf("%d KEYWORD \"Player\"\n", ++TokenCont); return PLAYER; }
"Position" 	 { printf("%d KEYWORD \"Position\"\n", ++TokenCont); return POSITION; }
"Captain" 	 { printf("%d KEYWORD \"Captain\"\n", ++TokenCont); return CAPTAIN; }
"Strategy" 	 { printf("%d KEYWORD \"Strategy\"\n", ++TokenCont); return STRATEGY; }
"Match" { printf("%d KEYWORD \"Match\"\n", ++TokenCont); return MATCH; }
"Date" { printf("%d KEYWORD \"Date\"\n", ++TokenCont); return DATE; }
"Result" { printf("%d KEYWORD \"Result\"\n", ++TokenCont); return RESULT; }
"Scorers" { printf("%d KEYWORD \"Scorers\"\n", ++TokenCont); return SCORERS; }
"HomeTeam" { printf("%d KEYWORD \"HomeTeam\"\n", ++TokenCont); return HOMETEAM; }
"AwayTeam" { printf("%d KEYWORD \"AwayTeam\"\n", ++TokenCont); return AWAYTEAM; }

	//symbol 

"{"                    { printf("%d SYMBOL {\n", ++TokenCont); return LBRACE; }
"}"                    { printf("%d SYMBOL }\n", ++TokenCont); return RBRACE; }
"="                    { printf("%d SYMBOL =\n", ++TokenCont); return EQUAL; }
"-"                    { printf("%d SYMBOL -\n", ++TokenCont); return HYPHEN; }
";"                    { printf("%d SYMBOL ;\n", ++TokenCont); return SEMICOLON; }
","          		   { printf("%d COMMA ,\n", ++TokenCont); return COMMA; }
"["                    { printf("%d SYMBOL [\n", ++TokenCont); return LSQUARE; }
"]"                    { printf("%d SYMBOL ]\n", ++TokenCont); return RSQUARE; }

	//id e position val


[A-Z]{2} { printf("%d POSITIONVAL %s\n", ++TokenCont, yytext); return POSITIONVAL; }
{id}   { printf("%d VAR \"%s\" Length = %zu\n", ++TokenCont, yytext, yyleng); return VAR; }

	//number, date, string

[0-9]+       { printf("%d NUMBER %s\n", ++TokenCont, yytext); return NUMBER; }
\"[0-9]{4}-[0-9]{2}-[0-9]{2}\" { printf("%d DATE %s\n", ++TokenCont, yytext); return DATESTR; }
\"[^\"]*\"   { printf("%d STRING %s\n", ++TokenCont, yytext); return STRING; }

	//all the other char are wrong
. { printf("Unknown character: %s\n", yytext); }

%%

int main()
{
yylex();
return 0;
}
