%{
  module A = Ast.Absyn
  module S = Ast.Symbol

%}


%token EOF
%token <string> ID
%token <int> INT
%token <string> STRING
%token COMMA COLON SEMICOLON LPAREN RPAREN LBRACK RBRACK
%token LBRACE RBRACE DOT
%token PLUS MINUS TIMES DIVIDE EQ NEQ LT LE GT GE
%token AND OR ASSIGN
%token ARRAY IF THEN ELSE WHILE FOR TO DO LET IN END OF 
%token BREAK NIL
%token FUNCTION VAR TYPE 

%left OR
%left AND
%nonassoc EQ NEQ LT LE GT GE
%left PLUS MINUS
%left TIMES DIVIDE
%left UMINUS

%start <Ast.Absyn.exp option> program
%%

program	:
 | v = exp; EOF {Some v}
 | EOF { None }


// variables and expressions
exp_basic:
  | v = lvalue { A.VarExp v }
  | NIL { A.NilExp }
  | i = INT { A.IntExp i }
  | str = STRING { A.StringExp (str, $startpos) }
  | MINUS; e = exp_basic 
      { A.OpExp {
          left= IntExp 0;
          oper= MinusOp;
          right= e;
          pos= $startpos
      } } %prec UMINUS
  | e1 = exp_basic ; PLUS ; e2 = exp_basic
      { A.OpExp {
          left= e1;
          oper= PlusOp;
          right= e2;
          pos= $startpos
      } }
  | e1 = exp_basic ; MINUS ; e2 = exp_basic
      { A.OpExp {
          left= e1;
          oper= MinusOp;
          right= e2;
          pos= $startpos
      } }
  | e1 = exp_basic ; TIMES ; e2 = exp_basic
      { A.OpExp {
          left= e1;
          oper= TimesOp;
          right= e2;
          pos= $startpos
      } }
  | e1 = exp_basic ; DIVIDE ; e2 = exp_basic
      { A.OpExp {
          left= e1;
          oper= DivideOp;
          right= e2;
          pos= $startpos
      } }
  | e1 = exp_basic ; EQ ; e2 = exp_basic
      { A.OpExp {
          left= e1;
          oper= EqOp;
          right= e2;
          pos= $startpos
      } }
  | e1 = exp_basic ; NEQ ; e2 = exp_basic
      { A.OpExp {
          left= e1;
          oper= NeqOp;
          right= e2;
          pos= $startpos
      } }
  | e1 = exp_basic ; LT ; e2 = exp_basic
      { A.OpExp {
          left= e1;
          oper= LtOp;
          right= e2;
          pos= $startpos
      } }
  | e1 = exp_basic ; GT ; e2 = exp_basic
      { A.OpExp {
          left= e1;
          oper= GtOp;
          right= e2;
          pos= $startpos
      } }
  | e1 = exp_basic ; LE ; e2 = exp_basic
      { A.OpExp {
          left= e1;
          oper= LeOp;
          right= e2;
          pos= $startpos
      } }
  | e1 = exp_basic ; GE ; e2 = exp_basic
      { A.OpExp {
          left= e1;
          oper= GeOp;
          right= e2;
          pos= $startpos
      } }
  | e1 = exp_basic ; OR ; e2 = exp_basic
      { A.IfExp {
          test= e1;
          then'= IntExp 1;
          else'= Some e2;
          pos= $startpos
      } }
  | e1 = exp_basic ; AND ; e2 = exp_basic
      { A.IfExp {
          test= e1;
          then'= e2;
          else'= Some (IntExp 0);
          pos= $startpos
      } }
  | fun_id = ID; LPAREN; exps = separated_list(COMMA, exp);RPAREN 
      {
        A.CallExp {
          func= S.symbol fun_id;
          args= exps;
          pos= $startpos
        }
      }

exp:
  | e1 = exp_basic { e1 }
  | v = lvalue; ASSIGN; e = exp
      {
        A.AssignExp {
          var= v;
          exp= e;
          pos= $startpos
        }
      }
  | LPAREN ; elis = expseq ; RPAREN
      { elis }
  | LPAREN ; RPAREN
      { A.SeqExp [] }
  | IF; e1 = exp; THEN; e2 = exp; ELSE; e3 = exp
      {
        A.IfExp {
          test= e1;
          then'= e2;
          else'= Some e3;
          pos= $startpos
        }
      }
  | IF; e1 = exp; THEN; e2 = exp
      {
        A.IfExp {
          test= e1;
          then'= e2;
          else'= None;
          pos= $startpos
        }
      }
  | WHILE; e1 = exp; DO; e2 = exp
      {
        A.WhileExp {
          test= e1;
          body= e2;
          pos= $startpos
        }
      }
  | FOR; iter_id = ID; ASSIGN; e1 = exp; TO; e2 = exp; DO; e3 = exp
      {
        A.ForExp {
          var= S.symbol iter_id;
          escape= true;
          lo= e1;
          hi= e2;
          body= e3;
          pos= $startpos
        }
      }
  | BREAK {(A.BreakExp ($startpos))}
  | LET; dec_lis = decs; IN; exps = expseq; END
      {
        A.LetExp {
          decs= dec_lis;
          body= exps;
          pos= $startpos
        }
      }
  | type_id = ID ; LBRACK; exp1 = exp; RBRACK; OF; exp2 = exp
      {
        A.ArrayExp { 
          typ= (S.symbol type_id); 
          size= exp1; 
          init= exp2; 
          pos= $startpos }
      }
  | type_id = ID ; LBRACE; rec_fields = separated_list(COMMA, exp_field);  RBRACE
      {
        A.RecordExp {
          fields= rec_fields;
          typ= S.symbol type_id;
          pos= $startpos
        }
      }

%inline exp_field:
| field_id = ID; EQ; exp1 = exp
  {
    (S.symbol field_id, exp1, $startpos )
  }

lvalue:
  | i = ID           
      { A.SimpleVar (S.symbol i, $startpos) }
  | i = lvalue_t
      { i }

lvalue_t: // <--- How shift/reduce conflict mentioned on Page 82 is resolved 
  | v = ID ; LBRACK; e = exp; RBRACK
      { A.SubscriptVar (A.SimpleVar (S.symbol v, $startpos),
                        e, $startpos)}
  | v = lvalue_t ; LBRACK; e = exp; RBRACK
      { A.SubscriptVar (v, e, $startpos)}
  | v = ID ; DOT; i = ID
      { (A.FieldVar (A.SimpleVar (S.symbol v, $startpos),
                     S.symbol i, $startpos)) }
  | v = lvalue_t ; DOT; i = ID
      { (A.FieldVar (v, S.symbol i, $startpos)) }

expseq:
  | e = exp
    { A.SeqExp [(e, $startpos)] }
  | e1 = exp SEMICOLON exps = expseq 
    { match exps with
      | A.SeqExp es -> A.SeqExp ((e1,$startpos)::es)
      | _ -> assert false (* impossible expseq *)
    }
  // | exps = separated_list(SEMICOLON, exp) {}


// declarations
decs:
  | (* empty *)    { [] }
  | ty_dec = tydec; decs_tl = decs 
    { match decs_tl with
      | [] -> [ A.TypeDec [ty_dec] ]
      | hd :: tl -> match hd with
                    | A.TypeDec ty_dec' -> (A.TypeDec (ty_dec::ty_dec')) :: tl
                    | _ -> (A.TypeDec [ty_dec]) :: hd :: tl }
  | vdec = vardec; decs_tl = decs 
    { vdec::decs_tl }
  | fun_dec = fundec; decs_tl = decs 
    { match decs_tl with
      | [] -> [ A.FunctionDec [fun_dec] ]
      | hd :: tl -> match hd with
                    | A.FunctionDec fun_dec' -> A.FunctionDec (fun_dec::fun_dec') :: tl
                    | _ -> A.FunctionDec [fun_dec] :: hd :: tl  }

// type declarations
tydec:
  | TYPE ; type_id = ID ; EQ ; type_def = ty
      { 
        {
          name= S.symbol type_id;
          ty= type_def;
          pos= $startpos;
        }
      }

ty:
  | type_id = ID
      { A.NameTy (S.symbol type_id, $startpos ) }
  | LBRACE; type_fields = separated_list(COMMA, tyfield) ;RBRACE
      { A.RecordTy (type_fields) }
  | ARRAY; OF; type_id = ID
      { A.ArrayTy (S.symbol type_id, $startpos )}

tyfield:
  | field_id = ID; COLON ; type_id = ID
      {
        ({
          name= S.symbol field_id;
          escape= true;
          typ= S.symbol type_id;
          pos= $startpos
        })
      }

// variable declarations
vardec:
  | VAR ; var_id = ID; COLON; type_id = ID; ASSIGN; e = exp
    {
      A.VarDec {
        name= S.symbol var_id;
        escape= true;
        typ= Some (S.symbol type_id, $startpos);
        init= e;
        pos= $startpos;
      }
    }
  | VAR ; var_id = ID; ASSIGN ; e = exp
    {
      A.VarDec {
        name= S.symbol var_id;
        escape= true;
        typ= None;
        init= e;
        pos= $startpos
      }
    }

// function declarations
fundec:
  | FUNCTION ; fun_id = ID ; LPAREN; type_fields = separated_list(COMMA, tyfield); RPAREN ; EQ ; e = exp
    {
      {
        name= S.symbol fun_id;
        params= (type_fields);
        result= None;
        body= e;
        pos= $startpos
      }
    }
  | FUNCTION ; fun_id = ID ; LPAREN; type_fields = separated_list(COMMA, tyfield); RPAREN ; COLON ; type_id = ID ; EQ ; e = exp
    {
      {
        name= S.symbol fun_id;
        params= (type_fields);
        result= Some (S.symbol type_id, $startpos);
        body= e;
        pos= $startpos
      }
    }