%{
#define _GNU_SOURCE
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>


typedef struct {
    char* name;
    char* type;
} SymbolEntry;


SymbolEntry symbolTable[100]; // Assuming a maximum of 100 variables
int symbolCount = 0;


void yyerror(const char *s);
extern int yylex();
%}

%union {
  int ival;
  float rval;
  char *sval;
}

%token <sval> ID
%token <ival> INTEGER
%token <rval> REAL
%token INTEGER_TYPE REAL_TYPE
%token COLON COMMA SEMICOLON
%token ASSIGN_OP
%token ASSIGN_INT
%token ASSIGN_REAL
%token LPAREN RPAREN
%type <sval> expression
%type <sval> variable_declaration id_list type


%left ADD SUB
%left MUL DIV
%right EXP
%nonassoc UMINUS

%%

program:
    | program statement SEMICOLON
    ;

statement:
      variable_declaration
    |  assignment_statement

    ;

variable_declaration:
      id_list COLON type {  // Add entries to the symbol table for each declared variable
        char* varType = $3;
        char* token = strtok($1, ",");
        while (token != NULL) {
            symbolTable[symbolCount].name = strdup(token);
            symbolTable[symbolCount].type = strdup(varType);
            symbolCount++;
            token = strtok(NULL, ",");
        } }
    ;

id_list:
      ID                 { $$ = strdup($1); 
      }

    | id_list COMMA ID   {
        $$ = malloc(strlen($1) + strlen($3) + 3);
        sprintf($$, "%s, %s", $1, $3);
        free($1);
      }
    ;
assignment_statement:
        ID ASSIGN_OP expression {
        // Check if the variable exists in the symbol table and retrieve its type
        char* varType = NULL;
        int i;
        for (i = 0; i < symbolCount; i++) {
            if (strcmp(symbolTable[i].name, $1) == 0) {
                varType = symbolTable[i].type;
                break;
            }
        }
        if (i == symbolCount) {
            fprintf(stderr, "Error: Variable %s not declared\n", $1);
            exit(EXIT_FAILURE);
        }

        // Check if the expression is a variable and retrieve its type if so
        char* exprType = NULL;
        for (i = 0; i < symbolCount; i++) {
            if (strcmp(symbolTable[i].name, $3) == 0) {
                exprType = symbolTable[i].type;
                break;
            }
        }

        // If the expression is a variable and its type does not match the assigned variable's type
        if (exprType && strcmp(varType, exprType) != 0) {
            fprintf(stderr, "Error: Type mismatch for variable %s (expected %s)\n", $1, varType);
            exit(EXIT_FAILURE);
        }

        // If the expression is not a variable, fall back to the original type checking
        if (!exprType) {
            if (strcmp(varType, "integer") == 0 && strchr($3, '.') != NULL) {
                fprintf(stderr, "Error: Type mismatch for variable %s (expected integer)\n", $1);
                exit(EXIT_FAILURE);
            }
            else if (strcmp(varType, "real") == 0 && strchr($3, '.') == NULL) {
                fprintf(stderr, "Error: Type mismatch for variable %s (expected real)\n", $1);
                exit(EXIT_FAILURE);
            }
        }

        printf("%s := %s\n", $1, $3);
    }
    ;

expression:
     ID        { $$ = strdup($1); }
    | INTEGER   { asprintf(&$$, "%d", $1); }
    | REAL      { asprintf(&$$, "%f", $1); }
  
    
    | expression ADD expression {
                                asprintf(&$$, "(%s + %s)", $1, $3);
                                free($1); free($3);
                            }
    | expression SUB expression {
                                asprintf(&$$, "(%s - %s)", $1, $3);
                                free($1); free($3);
                            }
    | SUB expression %prec UMINUS {
                                asprintf(&$$, "-(%s)", $2);
                                free($2);
                            }
    | expression MUL expression {
                                asprintf(&$$, "(%s * %s)", $1, $3);
                                free($1); free($3);
                            }
    | expression DIV expression {
                                asprintf(&$$, "(%s / %s)", $1, $3);
                                free($1); free($3);
                            }                        
    | expression EXP expression {
                                asprintf(&$$, "(%s ^ %s)", $1, $3);
                                free($1); free($3);
                            }                       
    | LPAREN expression RPAREN  {
                                asprintf(&$$, "(%s)", $2);
                                free($2);
                            }
    ;
type:
      INTEGER_TYPE { $$ = "integer"; }
    | REAL_TYPE    { $$ = "real"; }
    ;

%%

int main(void) {
        printf("Enter your code:\n");
    if (yyparse() == 0) {
        printf("Syntax accepted.\n");
    } else {
        printf("Syntax error.\n");
    }
    return 0;
}

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}