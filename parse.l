%option yylineno

%{
	/*
	 *  Yaoting Wang - 19107668 
	 */
void yyerror(char*);
#include "parse.tab.h"
char* temp;
char* CurId;
void idUppercase(char* a);
%}

whitespace	[\t\n ]+
doubleVar	([0-9]+)(\.)([0-9]+)
intVar		[0-9]+
d_size		^[Xx]+(-[Xx]+)
i_size		^[Xx]+
dash 		-
id_1		[A-Za-z]
id_2		[A-Za-z][A-Za-z0-9]{0,5}[A-Za-z]
id			[A-Za-z0-9]
text		([\"](\\.|[^"\\])*\")

%%
{whitespace}			{/* ignore whitespace */}
(?i:start)      		{/*printf("start\t");*/ return start;}
(?i:main)				{/*printf("main\t");*/ return t_main;}
(?i:end)				{/*printf("end\t");*/ return end;}
(?i:add)				{/*printf("[add]\t");*/ return add;}
(?i:move)				{/*printf("move\t");*/ return move;}
(?i:equals-to) 			{/*printf("[et]\t");*/ return et;}
(?i:equals-to-value)	{/*printf("[etv]\t");*/ return etv;}
(?i:to)					{/*printf("[to]\t")*/; return to;}
(?i:print)				{/*printf("print\t");*/ return t_print;}
(?i:input)				{/*printf("input\t");*/ return t_input;}
;						{/*printf(";\n");*/ return sem;} 
,						{/*printf(",\t");*/ return comma;}

{d_size}				{/*printf("[d_size]\t")*/; temp = (char*) calloc(strlen(yytext)+1, sizeof(char)); strcpy(temp, yytext); yylval.d_size=temp; return dsize;}
{i_size}				{/*printf("[i_size]\t")*/; temp = (char*) calloc(strlen(yytext)+1, sizeof(char)); strcpy(temp, yytext); yylval.i_size=temp; return isize;}

[xX]*					{temp = (char*) calloc(strlen(yytext)+1, sizeof(char)); strcpy(temp, yytext); yylval.str = temp; 
						fprintf(stderr, "[Error] Line %d: [Invalid]\tinvalid declaration statement\n", yylineno); return id;} //process continuous XXX id
{id_1}                  |
{id_2}					{idUppercase(yytext); temp = (char*) calloc(strlen(CurId)+1, sizeof(char)); strcpy(temp, CurId); yylval.str = temp; return id;}
[-0-9]*[-A-Za-z]+		{temp = (char*) calloc(strlen(yytext)+1, sizeof(char)); strcpy(temp, yytext); yylval.str = temp;
						fprintf(stderr, "[Error] Line %d: [Invalid]\tinvalid identifier '%s'\n", yylineno, yytext); return id;}

{doubleVar}				{temp = (char*) calloc(strlen(yytext)+1, sizeof(char)); strcpy(temp, yytext); yylval.d_val = temp; return dval;}
{intVar}				{temp = (char*) calloc(strlen(yytext)+1, sizeof(char)); strcpy(temp, yytext); yylval.i_val = temp; return ival;}
{text}                  {temp = (char*) calloc(strlen(yytext)+1, sizeof(char)); strcpy(temp, yytext); yylval.str = temp; return text;}

.						{fprintf(stderr, "[Error] Line %d: [Unknown]\tunknown Token '%s'\n", yylineno, yytext);}
%%

int yywrap(void) {
    return 1;
}

void idUppercase(char* id) {
    CurId = (char*) calloc(strlen(id), sizeof(char)); 
    strcpy(CurId, id);

    char* p = id;
    for(int i = 0; i < strlen(CurId); i++) {
        char ch = *p;
        if(*p >= 'a' && *p <= 'z')
            ch = *p - 32;
        CurId[i] = ch;
        p++;
    }
}