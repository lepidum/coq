(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2012     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

open Loc
open Pp
open Names
open Term
open Libnames
open Globnames
open Glob_term
open Genredexpr
open Pattern
open Constrexpr
open Term
open Evd
open Misctypes

val loc_of_or_by_notation : ('a -> Loc.t) -> 'a or_by_notation -> Loc.t

(** In globalize tactics, we need to keep the initial [constr_expr] to recompute
   in the environment by the effective calls to Intro, Inversion, etc 
   The [constr_expr] field is [None] in TacDef though *)
type glob_constr_and_expr = glob_constr * constr_expr option

type open_constr_expr = unit * constr_expr
type open_glob_constr = unit * glob_constr_and_expr

type glob_constr_pattern_and_expr = glob_constr_and_expr * constr_pattern

(** The route of a generic argument, from parsing to evaluation.
In the following diagram, "object" can be tactic_expr, constr, tactic_arg, etc.

{% \begin{%}verbatim{% }%}
             parsing          in_raw                            out_raw
   char stream ---> raw_object ---> raw_object generic_argument -------+
                          encapsulation                          decaps|
                                                                       |
                                                                       V
                                                                   raw_object
                                                                       |
                                                         globalization |
                                                                       V
                                                                   glob_object
                                                                       |
                                                                encaps |
                                                               in_glob |
                                                                       V
                                                           glob_object generic_argument
                                                                       |
          out                          in                     out_glob |
  object <--- object generic_argument <--- object <--- glob_object <---+
    |   decaps                       encaps      interp           decaps
    |
    V
effective use
{% \end{%}verbatim{% }%}

To distinguish between the uninterpreted (raw), globalized and
interpreted worlds, we annotate the type [generic_argument] by a
phantom argument which is either [constr_expr], [glob_constr] or
[constr].

Transformation for each type :
{% \begin{%}verbatim{% }%}
tag                            raw open type            cooked closed type

BoolArgType                    bool                      bool
IntArgType                     int                       int
IntOrVarArgType                int or_var                int
StringArgType                  string (parsed w/ "")     string
PreIdentArgType                string (parsed w/o "")    (vernac only)
IdentArgType true              identifier                identifier
IdentArgType false             identifier (pattern_ident) identifier
IntroPatternArgType            intro_pattern_expr        intro_pattern_expr
VarArgType                     identifier located        identifier
RefArgType                     reference                 global_reference
QuantHypArgType                quantified_hypothesis     quantified_hypothesis
ConstrArgType                  constr_expr               constr
ConstrMayEvalArgType           constr_expr may_eval      constr
OpenConstrArgType              open_constr_expr          open_constr
ConstrWithBindingsArgType      constr_expr with_bindings constr with_bindings
BindingsArgType                constr_expr bindings      constr bindings
List0ArgType of argument_type
List1ArgType of argument_type
OptArgType of argument_type
ExtraArgType of string         '_a                      '_b
{% \end{%}verbatim{% }%}
*)

(** All of [rlevel], [glevel] and [tlevel] must be non convertible
   to ensure the injectivity of the type inference from type
   ['co generic_argument] to [('a,'co) abstract_argument_type];
   this guarantees that, for 'co fixed, the type of
   out_gen is monomorphic over 'a, hence type-safe
*)

type rlevel
type glevel
type tlevel

type ('a,'co) abstract_argument_type

val rawwit_bool : (bool,rlevel) abstract_argument_type
val globwit_bool : (bool,glevel) abstract_argument_type
val wit_bool : (bool,tlevel) abstract_argument_type

val rawwit_int : (int,rlevel) abstract_argument_type
val globwit_int : (int,glevel) abstract_argument_type
val wit_int : (int,tlevel) abstract_argument_type

val rawwit_int_or_var : (int or_var,rlevel) abstract_argument_type
val globwit_int_or_var : (int or_var,glevel) abstract_argument_type
val wit_int_or_var : (int or_var,tlevel) abstract_argument_type

val rawwit_string : (string,rlevel) abstract_argument_type
val globwit_string : (string,glevel) abstract_argument_type

val wit_string : (string,tlevel) abstract_argument_type

val rawwit_pre_ident : (string,rlevel) abstract_argument_type
val globwit_pre_ident : (string,glevel) abstract_argument_type
val wit_pre_ident : (string,tlevel) abstract_argument_type

val rawwit_intro_pattern : (intro_pattern_expr located,rlevel) abstract_argument_type
val globwit_intro_pattern : (intro_pattern_expr located,glevel) abstract_argument_type
val wit_intro_pattern : (intro_pattern_expr located,tlevel) abstract_argument_type

val rawwit_ident : (identifier,rlevel) abstract_argument_type
val globwit_ident : (identifier,glevel) abstract_argument_type
val wit_ident : (identifier,tlevel) abstract_argument_type

val rawwit_pattern_ident : (identifier,rlevel) abstract_argument_type
val globwit_pattern_ident : (identifier,glevel) abstract_argument_type
val wit_pattern_ident : (identifier,tlevel) abstract_argument_type

val rawwit_ident_gen : bool -> (identifier,rlevel) abstract_argument_type
val globwit_ident_gen : bool -> (identifier,glevel) abstract_argument_type
val wit_ident_gen : bool -> (identifier,tlevel) abstract_argument_type

val rawwit_var : (identifier located,rlevel) abstract_argument_type
val globwit_var : (identifier located,glevel) abstract_argument_type
val wit_var : (identifier,tlevel) abstract_argument_type

val rawwit_ref : (reference,rlevel) abstract_argument_type
val globwit_ref : (global_reference located or_var,glevel) abstract_argument_type
val wit_ref : (global_reference,tlevel) abstract_argument_type

val rawwit_quant_hyp : (quantified_hypothesis,rlevel) abstract_argument_type
val globwit_quant_hyp : (quantified_hypothesis,glevel) abstract_argument_type
val wit_quant_hyp : (quantified_hypothesis,tlevel) abstract_argument_type

val rawwit_sort : (glob_sort,rlevel) abstract_argument_type
val globwit_sort : (glob_sort,glevel) abstract_argument_type
val wit_sort : (sorts,tlevel) abstract_argument_type

val rawwit_constr : (constr_expr,rlevel) abstract_argument_type
val globwit_constr : (glob_constr_and_expr,glevel) abstract_argument_type
val wit_constr : (constr,tlevel) abstract_argument_type

val rawwit_constr_may_eval : ((constr_expr,reference or_by_notation,constr_expr) may_eval,rlevel) abstract_argument_type
val globwit_constr_may_eval : ((glob_constr_and_expr,evaluable_global_reference and_short_name or_var,glob_constr_pattern_and_expr) may_eval,glevel) abstract_argument_type
val wit_constr_may_eval : (constr,tlevel) abstract_argument_type

val rawwit_open_constr_gen : bool -> (open_constr_expr,rlevel) abstract_argument_type
val globwit_open_constr_gen : bool -> (open_glob_constr,glevel) abstract_argument_type
val wit_open_constr_gen : bool -> (open_constr,tlevel) abstract_argument_type

val rawwit_open_constr : (open_constr_expr,rlevel) abstract_argument_type
val globwit_open_constr : (open_glob_constr,glevel) abstract_argument_type
val wit_open_constr : (open_constr,tlevel) abstract_argument_type

val rawwit_casted_open_constr : (open_constr_expr,rlevel) abstract_argument_type
val globwit_casted_open_constr : (open_glob_constr,glevel) abstract_argument_type
val wit_casted_open_constr : (open_constr,tlevel) abstract_argument_type

val rawwit_constr_with_bindings : (constr_expr with_bindings,rlevel) abstract_argument_type
val globwit_constr_with_bindings : (glob_constr_and_expr with_bindings,glevel) abstract_argument_type
val wit_constr_with_bindings : (constr with_bindings sigma,tlevel) abstract_argument_type

val rawwit_bindings : (constr_expr bindings,rlevel) abstract_argument_type
val globwit_bindings : (glob_constr_and_expr bindings,glevel) abstract_argument_type
val wit_bindings : (constr bindings sigma,tlevel) abstract_argument_type

val rawwit_red_expr : ((constr_expr,reference or_by_notation,constr_expr) red_expr_gen,rlevel) abstract_argument_type
val globwit_red_expr : ((glob_constr_and_expr,evaluable_global_reference and_short_name or_var,glob_constr_pattern_and_expr) red_expr_gen,glevel) abstract_argument_type
val wit_red_expr : ((constr,evaluable_global_reference,constr_pattern) red_expr_gen,tlevel) abstract_argument_type

val wit_list0 :
  ('a,'co) abstract_argument_type -> ('a list,'co) abstract_argument_type

val wit_list1 :
  ('a,'co) abstract_argument_type -> ('a list,'co) abstract_argument_type

val wit_opt :
  ('a,'co) abstract_argument_type -> ('a option,'co) abstract_argument_type

val wit_pair :
  ('a,'co) abstract_argument_type ->
  ('b,'co) abstract_argument_type ->
      ('a * 'b,'co) abstract_argument_type

(** ['a generic_argument] = (Sigma t:type. t[[constr/'a]]) *)
type 'a generic_argument

val fold_list0 :
 ('a generic_argument -> 'c -> 'c) -> 'a generic_argument -> 'c -> 'c

val fold_list1 :
 ('a generic_argument -> 'c -> 'c) -> 'a generic_argument -> 'c -> 'c

val fold_opt :
 ('a generic_argument -> 'c) -> 'c -> 'a generic_argument -> 'c

val fold_pair :
 ('a generic_argument -> 'a generic_argument -> 'c) ->
      'a generic_argument -> 'c

(** [app_list0] fails if applied to an argument not of tag [List0 t]
    for some [t]; it's the responsability of the caller to ensure it *)

val app_list0 : ('a generic_argument -> 'b generic_argument) ->
'a generic_argument -> 'b generic_argument

val app_list1 : ('a generic_argument -> 'b generic_argument) ->
'a generic_argument -> 'b generic_argument

val app_opt : ('a generic_argument -> 'b generic_argument) ->
'a generic_argument -> 'b generic_argument

val app_pair :
  ('a generic_argument -> 'b generic_argument) ->
      ('a generic_argument -> 'b generic_argument)
   -> 'a generic_argument -> 'b generic_argument

(** create a new generic type of argument: force to associate
   unique ML types at each of the three levels *)
val create_arg : 'rawa option ->
    string ->
      ('a,tlevel) abstract_argument_type
      * ('globa,glevel) abstract_argument_type
      * ('rawa,rlevel) abstract_argument_type

val exists_argtype : string -> bool

type argument_type =
  (** Basic types *)
  | BoolArgType
  | IntArgType
  | IntOrVarArgType
  | StringArgType
  | PreIdentArgType
  | IntroPatternArgType
  | IdentArgType of bool
  | VarArgType
  | RefArgType
  (** Specific types *)
  | SortArgType
  | ConstrArgType
  | ConstrMayEvalArgType
  | QuantHypArgType
  | OpenConstrArgType of bool
  | ConstrWithBindingsArgType
  | BindingsArgType
  | RedExprArgType
  | List0ArgType of argument_type
  | List1ArgType of argument_type
  | OptArgType of argument_type
  | PairArgType of argument_type * argument_type
  | ExtraArgType of string

val genarg_tag : 'a generic_argument -> argument_type

val unquote : ('a,'co) abstract_argument_type -> argument_type

val in_gen :
  ('a,'co) abstract_argument_type -> 'a -> 'co generic_argument
val out_gen :
  ('a,'co) abstract_argument_type -> 'co generic_argument -> 'a

(** [in_generic] is used in combination with camlp4 [Gramext.action] magic

   [in_generic: !l:type, !a:argument_type -> |a|_l -> 'l generic_argument]

   where |a|_l is the interpretation of a at level l

   [in_generic] is not typable; we replace the second argument by an absurd
   type (with no introduction rule)
*)
type an_arg_of_this_type

val in_generic :
  argument_type -> an_arg_of_this_type -> 'co generic_argument

val default_empty_value : ('a,rlevel) abstract_argument_type -> 'a option
