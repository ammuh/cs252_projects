
/*
 * CS-252
 * shell.y: parser for shell
 *
 * This parser compiles the following grammar:
 *
 *	cmd [arg]* [> filename]
 *
 * you must extend it to understand the complete shell grammar
 *
 */

%code requires 
{
#include <string>
  #include <string.h>

#if __cplusplus > 199711L
#define register      // Deprecated in C++11 so remove the keyword
#endif
}

%union
{
  char        *string_val;
  // Example of using a c++ type in yacc
  std::string *cpp_string;
}

%token <string_val> WORD
%token NOTOKEN GREAT NEWLINE PIPE AMPERSAND GREATGREAT LESS GREATAMPERSAND GREATGREATAMPERSAND TWOGREAT

%{
//#define yylex yylex
#include <cstdio>
#include "command.hh"

void yyerror(const char * s);
int yylex();

%}

%%

goal:
  commands
  ;

commands:
  command
  | commands command
  ;

command: 
  command_and_args pipe_list iomodifiers background_opt NEWLINE {
    //printf("   Yacc: Execute command.\n");
    Command::_currentCommand.execute();
  }
  | NEWLINE 
  | error NEWLINE { yyerrok; }
  ;

background_opt:
  AMPERSAND {
    Command::_currentCommand._background = 1;
  }
  |
  ;

pipe_list:
  PIPE command_and_args pipe_list
  |
  ;

command_and_args:
  command_word argument_list {
    Command::_currentCommand.
    insertSimpleCommand( Command::_currentSimpleCommand );
  }
  ;

argument_list:
  argument_list argument
  |
  ;

argument:
  WORD {
    //printf("   Yacc: insert argument \"%s\"\n", $1);
    Command::_currentSimpleCommand->insertArgument( $1 );
  }
  ;

command_word:
  WORD {
    //printf("   Yacc: insert command \"%s\"\n", $1);
    Command::_currentSimpleCommand = new SimpleCommand();
    Command::_currentSimpleCommand->insertArgument( $1 );
  }
  ;

iomodifiers:
  iomodifier iomodifiers
  |
  ;

iomodifier:
  GREAT WORD {
    
    if(Command::_currentCommand._outFile || Command::_currentCommand._errFile){
      yyerror("Ambiguous output redirect");
    }else{
      //printf("   Yacc: insert stdout \"%s\"\n", $2);
      Command::_currentCommand._outFile = $2;
    }
    
  }
  | TWOGREAT WORD {
    
    if(Command::_currentCommand._outFile || Command::_currentCommand._errFile){
      yyerror("Ambiguous output redirect");
    }else{
      //printf("   Yacc: insert stderr \"%s\"\n", $2);
      Command::_currentCommand._errFile = $2;
    }
    
  }
  | GREATGREAT WORD {
    
    if(Command::_currentCommand._outFile || Command::_currentCommand._errFile){
      yyerror("Ambiguous output redirect");
    }else{
      //printf("   Yacc: append stdout \"%s\"\n", $2);
      Command::_currentCommand._outFile = $2;
      Command::_currentCommand._append = 1;
    }
  }
  | GREATAMPERSAND WORD {
    
    if(Command::_currentCommand._outFile || Command::_currentCommand._errFile){
      yyerror("Ambiguous output redirect");
    }else{
      //printf("   Yacc: insert stdout and stderr \"%s\"\n", $2);
      Command::_currentCommand._outFile = $2;
      Command::_currentCommand._errFile = $2;
    }
  }
  | GREATGREATAMPERSAND WORD {
    
    if(Command::_currentCommand._outFile || Command::_currentCommand._errFile){
      yyerror("Ambiguous output redirect");
    }else{
      //printf("   Yacc: append stdout and stderr \"%s\"\n", $2);
      Command::_currentCommand._outFile = $2;
      Command::_currentCommand._errFile = $2;
      Command::_currentCommand._append = 1;
    }
  }
  | LESS WORD {
    //printf("   Yacc: stdin \"%s\"\n", $2);
    Command::_currentCommand._inFile = $2;
  }
  ;

%%

void
yyerror(const char * s)
{
  fprintf(stderr,"%s", s);
}

#if 0
main()
{
  yyparse();
}
#endif
