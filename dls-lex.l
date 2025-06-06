%option noyywrap
%option caseless

%{
#include <stdio.h>
#include "dls-byson.tab.h"
int TokenCont=0;
%}

digit    [0-9]
letter   [a-zA-Z]
digits   {digit}+
id       {letter}({letter}|{digit})*

%%

[ \t\r\n]+               { /* ignora spazi e newline */ }

"Team"                  return TEAM;
"Coach"                 return COACH;
"Formation"             return FORMATION; 
"Player"                return PLAYER; 
"Position"              return POSITION;
"Captain"               return CAPTAIN; 
"Vicecaptain"           return VICECAPTAIN;
"Strategy"              return STRATEGY; 
"Match"                 return MATCH; 
"Date"                  return DATE;
"Time"                  return TIME;
"Result"                return RESULT; 
"Scorers"               return SCORERS; 
"HomeTeam"              return HOMETEAM; 
"AwayTeam"              return AWAYTEAM; 
"Stadium"               return STADIUM;
"Weather"               return WEATHER;
"Referee"               return REFEREE;

"{"                     return LBRACE; 
"}"                     return RBRACE; 
"="                     return EQUAL; 
"-"                     return HYPHEN; 
";"                     return SEMICOLON; 
","                     return COMMA;
"["                   	return LSQUARE; 
"]"                     return RSQUARE; 
"("      				return LPAREN;
")"      				return RPAREN;

setCaptain       return SETCAPTAIN;
setCoach         return SETCOACH;
setViceCaptain   return SETVICECAPTAIN;
setStrategy      return SETSTRATEGY;
setFormation     return SETFORMATION;

setStadium       return SETSTADIUM;
setHomeTeam      return SETHOMETEAM;
setAwayTeam      return SETAWAYTEAM;
setMatchDate     return SETMATCHDATE;
setMatchTime     return SETMATCHTIME;
setWeather       return SETWEATHER;
setReferee       return SETREFEREE;
setResult        return SETRESULT;

hasPlayer        return HASPLAYER;
hasCaptain       return HASCAPTAIN;
hasFormation     return HASFORMATION;
hasCoach         return HASCOACH;
hasViceCaptain   return HASVICECAPTAIN;
hasStrategy      return HASSTRATEGY;

hasStadium       return HASSTADIUM;
hasDate          return HASDATE;
hasTime          return HASTIME;
hasWeather       return HASWEATHER;
hasResult        return HASRESULT;
hasReferee       return HASREFEREE;
hasScorer        return HASSCORER;

[0-9]{4}-[0-9]{2}-[0-9]{2} {
    int len = yyleng;
    char* tmp = (char*)malloc(len + 1);
    strncpy(tmp, yytext, len);
    tmp[len] = '\0';
    yylval.str = tmp;
    return DATESTR;
}
\"[^\"]*\" {
    int len = yyleng - 2;
    char* tmp = (char*)malloc(len + 1);
    strncpy(tmp, yytext + 1, len);
    tmp[len] = '\0';
    yylval.str = tmp;
    return STRING;
}

[0-9]+    { yylval.num = atoi(yytext); return NUMBER; }

.                       { 
    printf("Errore lessicale: carattere sconosciuto '%s'\n", yytext); 
    return -1;
}

%%
