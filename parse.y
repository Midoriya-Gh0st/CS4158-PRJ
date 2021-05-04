%{
#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<math.h>
#define MAX_NUM_VARIABLES 256
#define TYPE_I 0
#define TYPE_D 1

extern int yylex();
extern int yyparse();
extern char* yytext;
extern int yylineno;
void yyerror(const char *s);

typedef struct {
   char* name;
   int size_i;
   int size_d;
   int type; //0=int, 1=double;
} Var;

Var Identifiers[MAX_NUM_VARIABLES];
int Var_Count = 0; 
int CurSize_I = 0;
int CurSize_D = 0;
char* CurId;

int varDefined(char* id);
void checkVar(char* id);
void storeVar(char* id, int type, int size_i, int size_d);
void moveIntToVar(char* numStr, char* id);
void moveDoubleToVar(char* numStr, char* id);
void moveVarToVar(char* idOne, char* idTwo); // from -> to
void getNumSize(char* numStr);
void getSizeX(char* sizeStr);
void resetGlobal();
void printVarsTable();
void idUppercase1(char* id);

%}

%union {
    char*   i_val;
    char*   d_val;
    char*   i_size;
    char*   d_size;
    char*   str;
};

/*corresponds to the content of union*/
%token <i_val> ival
%token <d_val> dval
%token <i_size> isize
%token <d_size> dsize
%token <str> id
%token <str> text
%token sem comma start end t_main move add to etv et t_input t_print
%start PRGM

%%
/*start*/
PRGM:   HEAD    BODY    TAIL    {;}
;
HEAD:   start   sem     DECLS   {;}
;
DECLS:  DECLS   DECL    {;}
|       {;}
;
DECL:   isize   id      sem     { printf("Int-> %s\n", $2); getSizeX($1); idUppercase1($2); storeVar(CurId, TYPE_I, CurSize_I, -1);}
|       dsize   id      sem     { printf("Double-> %s\n", $2); getSizeX($1); idUppercase1($2); storeVar(CurId, TYPE_D, CurSize_I, CurSize_D);}
;

/*main body*/
BODY:   t_main    sem     OPS   {;}
;
OPS:    OPS OP    {;}
|       {;}
;
OP:     EQUAL | ADD | INPUT | PRINT {;}
;
EQUAL:  id      et      id      sem     {moveVarToVar($3, $1);}
|       id      etv     dval    sem     {moveDoubleToVar($3, $1);}
|       id      etv     ival    sem     {moveIntToVar($3, $1);}
;
ADD:    add     id      to      id   sem   {moveVarToVar($2, $4);}
|       add     ival    to      id   sem   {moveIntToVar($2, $4);}
|       add     dval    to      id   sem   {moveDoubleToVar($2, $4);}
;

/*IO-Stream*/
INPUT:  t_input INPUT_ARGS  {printf("Input.\n");}
;
INPUT_ARGS: id  comma   INPUT_ARGS  {checkVar($1);}  
|           id  sem     {checkVar($1);}
;
PRINT:  t_print PRINT_ARGS  {printf("Print.\n");}
;
PRINT_ARGS: text    comma   PRINT_ARGS {}
|           id      comma   PRINT_ARGS {checkVar($1);}
|           text    sem     {}
|           id      sem     {checkVar($1);}
;

/*End*/
TAIL:       end     sem     {printVarsTable();}
;


%%

void yyerror(const char *s) {
    fprintf(stderr, "[Error] Line %d: %s\n", yylineno, s);
}

int main() {
    return yyparse();
}

// transfer all letters to uppercase form
void idUppercase1(char* id) {
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

void getSizeX(char* sizeStr) {
    resetGlobal();
    int crossFlag = 0;
    int len = strlen(sizeStr);
    int sizeX_i = 0;
    int sizeX_d = 0;

    for(int i=0; i<len; i++) {
        if(sizeStr[i] == '-')
            // check whether the cross '-' is met in "xx-xxx";
            crossFlag = 1;
        else {
            if(crossFlag == 0)
                sizeX_i++;
            else if (crossFlag == 1)
                sizeX_d++;
        }
    }

    CurSize_I = sizeX_i;
    CurSize_D = sizeX_d;
}

void getNumSize(char* numStr) {
    resetGlobal();
    int pointFlag = 0;
    int len = strlen(numStr);
    int size_i = 0;
    int size_d = 0;

    // size calculation
    for(int i=0; i<len; i++) {
        if(numStr[i] == '-') {
            ;
        } else if(numStr[i] == '.') {
            // check whether the point '.' is met in 'N.NN';
            pointFlag = 1;
        } else {
            if(pointFlag == 0)
                size_i++;
            else if (pointFlag == 1)
                size_d++;
        }
    }

    CurSize_I = size_i;
    CurSize_D = size_d;
}

// store the var into Id Array
void storeVar(char* id, int type, int size_i, int size_d) {
    if(varDefined(id) != -1) {
        fprintf(stderr, "[Error] Line %d: [Existed]\tvariable %s already exists\n", yylineno, id);
        return;
    }

    Var_Count++;

    Var var;
    var.name = id;
    var.size_i = size_i;
    var.size_d = size_d;
    var.type = type;
    Identifiers[Var_Count-1] = var;
}

// check whether the var is defined
int varDefined(char* id) {
    for(int i = 0; i < Var_Count; i++){
        if(Identifiers[i].name != NULL){
            if(strcmp(Identifiers[i].name, id) == 0){
                //printf("\n[Var is defined already.]");
                return i;
            }
        }
    }
    // printf("\n[None Var.]");
    return -1;
}

void resetGlobal() {
    CurSize_I = 0;
    CurSize_D = 0;
}

// check final variables
void printVarsTable() {
    fprintf(stderr, "\n------------------\n"); 
    fprintf(stderr, "[Variables Table]\n");    
    fprintf(stderr, "ID\t\t\tType\tSize_I\tSize_D\n");   

    for(int i = 0; i < Var_Count; i++){
        fprintf(stderr, "%d: %s,\t\t\t%d,\t%d,\t%d\n", i,  Identifiers[i].name, Identifiers[i].type, Identifiers[i].size_i, Identifiers[i].size_d);
    }
    fprintf(stderr, "[Note-1: -1 means none decimal size for Integers].\n");
    fprintf(stderr, "[Note-2: some vars are invalid but listed here just for a better understanding].\n\n\n");
}

void checkVar(char* id) {
    if(varDefined(id) == -1){
        fprintf(stderr, "[Error] Line %d: [Undeclared]\tvariable %s was not declared\n", yylineno, id);
    } 
}

// assign: the size must be exactly matched
// int->var
void moveIntToVar(char* numStr, char* id) {
    int varIndex = varDefined(id);
    if(varIndex == -1) { 
        // Check if the variable exists
        fprintf(stderr, "[Error] Line %d: [Undeclared]\tvariable %s was not declared\n", yylineno, id);
    } else if(Identifiers[varIndex].type != TYPE_I) {
        // Check whether the variable type is Int
        fprintf(stderr, "[Error] Line %d: [WrongType]\tvariable %s was not an Int value\n", yylineno, id);
    } else {
        int maxSize_i = Identifiers[varIndex].size_i;
        getNumSize(numStr);
        //fprintf(stderr, "[Max_size_i: %d]; [Cur_size_i: %d]; [Cur_size_d: %d]\n", maxSize_i, CurSize_I, CurSize_D);
        if(CurSize_I != maxSize_i) {
            fprintf(stderr, "[Error] Line %d: [WrongSize]\tvalue '%s' was not of same size for variable '%s' of size %d\n", yylineno, numStr, id, maxSize_i);
        
        }
    }
}

// double->var
void moveDoubleToVar(char* numStr, char* id) { 
    int varIndex = varDefined(id);
    if(varIndex == -1) { 
        // Check if the variable exists
        fprintf(stderr, "[Error] Line %d: [Undeclared]\tvariable '%s' was not declared\n", yylineno, id);
    } else if(Identifiers[varIndex].type != TYPE_D) { 
        // Check whether the variable type is Double
        fprintf(stderr, "[Error] Line %d: [WrongType]\tvariable '%s' was not a Double value\n", yylineno, id);
    } else {
        // Check whether the variable size matches
        int size_i = Identifiers[varIndex].size_i;
        int size_d = Identifiers[varIndex].size_d;
        getNumSize(numStr);
        //fprintf(stderr, "[Max_size_i: %d]; [Max_size_d: %d]; [Cur_size_i: %d]; [Cur_size_d: %d]\n", maxSize_i, maxSize_d, CurSize_I, CurSize_D);
        if(CurSize_I != size_i || CurSize_D != size_d) {
            fprintf(stderr, "[Error] Line %d: [WrongSize]\tvalue '%s' was not of same size for variable '%s' with size %d.%d\n", yylineno, numStr, id, size_i, size_d);
        }
    }
}

// var->var
void moveVarToVar(char* id_from, char* id_to) {
    int varIndexFrom = varDefined(id_from);
    int varIndexTo= varDefined(id_to);

    if(varIndexFrom == -1 || varIndexTo == -1) {
        // Check if the variable exists
        fprintf(stderr, "[Error] Line %d: [Undeclared]\tvariable '%s' or '%s' was not declared\n", yylineno, id_from, id_to);
    } else if(Identifiers[varIndexFrom].type != Identifiers[varIndexTo].type) { 
        // Check whether the variable types are the same
        fprintf(stderr, "[Error] Line %d: [WrongType]\tvariables '%s' and '%s' were not of same value type\n", yylineno, id_from, id_to);
    } else {
        // Check whether the variable size matches
        int maxSizeFrom_i = Identifiers[varIndexFrom].size_i;
        int maxSizeFrom_d = Identifiers[varIndexFrom].size_d;
        int maxSizeTo_i = Identifiers[varIndexTo].size_i;
        int maxSizeTo_d = Identifiers[varIndexTo].size_d;

        //fprintf(stderr, "[Max_sizef_i: %d]; [Max_sizef_d: %d]; [max_sizet_i: %d]; [max_sizet_d: %d]\n", maxSizeFrom_i, maxSizeFrom_d, maxSizeTo_i, maxSizeTo_d);
        if(maxSizeFrom_i != maxSizeTo_i || maxSizeFrom_d != maxSizeTo_d) {
            fprintf(stderr, "[Error] Line %d: [WrongSize]\tvariable '%s' and '%s' were not of same size.\n", yylineno, id_from, id_to);
        }
    }
}